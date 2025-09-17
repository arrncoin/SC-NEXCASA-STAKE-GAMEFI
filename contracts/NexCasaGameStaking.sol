// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INexCasaNFT.sol";

contract NexCasaGameStaking is Ownable, Pausable, ReentrancyGuard {
    
    address public constant NATIVE_TOKEN = address(0);
    uint8 public constant MAX_TIER = 9; 

    // Brankas untuk menampung fee
    mapping(address => uint256) public collectedFees;
    // Fee tetap saat klaim NFT
    uint256 public claimNftFee;

    struct StakePosition {
        address owner;
        uint256 lockupEnd;
        uint8 tier; 
        mapping(address => uint256) stakedAmounts;
    }

    uint256 public nextStakeId = 1;
    mapping(uint256 => StakePosition) public stakePositions;
    INexCasaNFT public nftContract;
    mapping(address => bool) public whitelistedTokens;
    mapping(uint8 => mapping(address => uint256)) public tierRequirements;
    mapping(uint8 => uint256) public tierRequiredLockupDays;
    mapping(uint8 => address[]) public tierCheckTokens;
    mapping(uint256 => mapping(uint8 => bool)) public hasClaimedNft;

    event PositionCreated(address indexed user, uint256 indexed stakeId, uint256 lockupEnd);
    event FundsAdded(uint256 indexed stakeId, address indexed token, uint256 amount);
    event WithdrawnToken(uint256 indexed stakeId, address indexed token, uint256 amount);
    event TierUpgraded(uint256 indexed stakeId, uint8 newTier, uint256 newLockupEnd);
    event NftClaimed(uint256 indexed stakeId, uint8 indexed tierId);
    event LockupReset(uint256 indexed stakeId);
    event TierRequirementSet(uint8 indexed tier, address indexed token, uint256 amount);
    event TierLockupSet(uint8 indexed tier, uint256 _days);

    constructor() Ownable(msg.sender) {
        whitelistedTokens[NATIVE_TOKEN] = true;
    }

    // ===================================
    //        Fungsi Admin (Owner)
    // ===================================
    function setNftContract(address _nftAddress) external onlyOwner {
        require(_nftAddress != address(0), "Staking: Cannot set to zero address");
        nftContract = INexCasaNFT(_nftAddress);
    }
    
    function setWhitelistToken(address _token, bool _isWhitelisted) external onlyOwner {
        whitelistedTokens[_token] = _isWhitelisted;
    }

    function setTierRequirement(uint8 _tier, address _token, uint256 _amount) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "Staking: Tier must be between 1 and MAX_TIER");
        require(whitelistedTokens[_token], "Staking: Token is not whitelisted");
        tierRequirements[_tier][_token] = _amount;
        emit TierRequirementSet(_tier, _token, _amount); 
    }

    function setTierLockup(uint8 _tier, uint256 _days) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "Staking: Tier must be between 1 and MAX_TIER");
        require(_days <= 30, "Staking: Lockup cannot exceed 30 days");
        tierRequiredLockupDays[_tier] = _days;
        emit TierLockupSet(_tier, _days); 
    }
    
    function addTokenToTierCheckList(uint8 _tier, address _token) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "Staking: Tier invalid");
        require(whitelistedTokens[_token], "Staking: Token not whitelisted");
        tierCheckTokens[_tier].push(_token);
    }

    function setClaimNftFee(uint256 _fee) external onlyOwner {
        claimNftFee = _fee;
    }

    function withdrawFees(address _token) external onlyOwner {
        uint256 amount = collectedFees[_token];
        require(amount > 0, "Staking: No fees to withdraw");

        collectedFees[_token] = 0; 

        if (_token == NATIVE_TOKEN) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(_token).transfer(owner(), amount);
        }
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ===================================
    //           Fungsi Pengguna
    // ===================================
    function createStakePosition() external whenNotPaused nonReentrant returns (uint256) {
        uint256 stakeId = nextStakeId;
        StakePosition storage newPosition = stakePositions[stakeId];
        newPosition.owner = msg.sender;
        newPosition.tier = 0;
        newPosition.lockupEnd = block.timestamp;
        nextStakeId++;
        emit PositionCreated(msg.sender, stakeId, newPosition.lockupEnd);
        return stakeId;
    }

    function addToStake(uint256 _stakeId, address _token, uint256 _amount) external payable whenNotPaused nonReentrant {
        StakePosition storage position = stakePositions[_stakeId];
        require(position.owner == msg.sender, "Staking: Not your stake position");
        require(block.timestamp >= position.lockupEnd, "Staking: Position is currently locked");
        require(whitelistedTokens[_token], "Staking: Token not whitelisted");
        require(_amount > 0, "Staking: Amount must be > 0");

        uint256 feeAmount = (_amount * 100) / 10000;
        uint256 amountToStake = _amount - feeAmount;

        if (feeAmount > 0) {
            collectedFees[_token] += feeAmount;
        }

        position.stakedAmounts[_token] += amountToStake;

        if (_token == NATIVE_TOKEN) {
            require(msg.value == _amount, "Staking: Native value mismatch");
        } else {
            require(msg.value == 0, "Staking: Do not send native token");
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        }
        
        emit FundsAdded(_stakeId, _token, amountToStake);
        _updateTier(_stakeId);
    }
    
    function claimNft(uint256 _stakeId) external payable whenNotPaused nonReentrant {
        if (claimNftFee > 0) {
            require(msg.value == claimNftFee, "Staking: Incorrect fee for claiming NFT");
            collectedFees[NATIVE_TOKEN] += msg.value;
        }

        StakePosition storage position = stakePositions[_stakeId];
        uint8 tierToClaim = position.tier;
        require(position.owner == msg.sender, "Staking: Not your stake position");
        require(tierToClaim > 0, "Staking: No tier achieved");
        require(block.timestamp >= position.lockupEnd, "Staking: Lockup period has not ended yet");
        require(address(nftContract) != address(0), "Staking: NFT contract not set");
        require(!hasClaimedNft[_stakeId][tierToClaim], "Staking: NFT for this tier already claimed");

        hasClaimedNft[_stakeId][tierToClaim] = true;
        position.lockupEnd = block.timestamp;
        emit LockupReset(_stakeId);
        
        nftContract.mintForTier(msg.sender, tierToClaim);
        emit NftClaimed(_stakeId, tierToClaim);
    }

    function withdrawToken(uint256 _stakeId, address _token) external whenNotPaused nonReentrant {
        StakePosition storage position = stakePositions[_stakeId];
        require(position.owner == msg.sender, "Staking: Not your stake position");
        require(block.timestamp >= position.lockupEnd, "Staking: Position is not locked");

        uint256 amount = position.stakedAmounts[_token];
        require(amount > 0, "Staking: No amount of this token staked");
        
        position.stakedAmounts[_token] = 0;
        
        if (_token == NATIVE_TOKEN) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(_token).transfer(msg.sender, amount);
        }
        emit WithdrawnToken(_stakeId, _token, amount);
    }

    // ===================================
    //        Fungsi Internal & View
    // ===================================
    function _updateTier(uint256 _stakeId) internal {
        StakePosition storage position = stakePositions[_stakeId];
        uint8 nextTier = position.tier + 1;
        if (nextTier > MAX_TIER) return; 
        
        if (_isTierAchieved(_stakeId, nextTier)) {
            position.tier = nextTier;
            uint256 newLockupEnd = block.timestamp + (tierRequiredLockupDays[nextTier] * 1 days);
            position.lockupEnd = newLockupEnd;
            emit TierUpgraded(_stakeId, nextTier, newLockupEnd);
        }
    }

    function _isTierAchieved(uint256 _stakeId, uint8 _tier) internal view returns (bool) {
        StakePosition storage position = stakePositions[_stakeId];
        address[] memory tokensToCheck = tierCheckTokens[_tier];
        if (tokensToCheck.length == 0) return false;
        
        for(uint i = 0; i < tokensToCheck.length; i++) {
            address token = tokensToCheck[i];
            uint256 requiredAmount = tierRequirements[_tier][token];
            if (position.stakedAmounts[token] < requiredAmount) {
                return false;
            }
        }
        return true;
    }

    function getStakedAmount(uint256 _stakeId, address _token) external view returns (uint256) {
        return stakePositions[_stakeId].stakedAmounts[_token];
    }
}