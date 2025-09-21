// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INexCasaNFT.sol";

contract NexCasaGame is Ownable, Pausable, ReentrancyGuard {
    address public constant NATIVE_TOKEN = address(0);
    uint8 public constant MAX_TIER = 9;

    // Brankas untuk menampung fee per token
    mapping(address => uint256) public collectedFees;

    // Fee tetap saat klaim NFT (native)
    uint256 public claimNftFee;

    // Struktur stake position (mapping dalam struct diperbolehkan)
    struct StakePosition {
        address owner;
        uint256 lockupEnd; // timestamp
        uint8 tier;
        mapping(address => uint256) stakedAmounts;
    }

    uint256 public nextStakeId = 1;
    mapping(uint256 => StakePosition) private stakePositions;

    // Simpan daftar stakeId per pemilik agar UI dapat enumerate
    mapping(address => uint256[]) private ownerStakes;

    INexCasaNFT public nftContract;
    mapping(address => bool) public whitelistedTokens;

    // requirement: tier => token => amount
    mapping(uint8 => mapping(address => uint256)) public tierRequirements;

    // tier => lockup minutes
    mapping(uint8 => uint256) public tierRequiredLockupMinutes;

    // tier => tokens to check (order penting untuk view)
    mapping(uint8 => address[]) public tierCheckTokens;

    // tracking apakah telah claim NFT untuk stakeId/tier
    mapping(uint256 => mapping(uint8 => bool)) public hasClaimedNft;

    // Events
    event PositionCreated(address indexed user, uint256 indexed stakeId, uint256 lockupEnd);
    event FundsAdded(uint256 indexed stakeId, address indexed token, uint256 amount);
    event WithdrawnToken(uint256 indexed stakeId, address indexed token, uint256 amount);
    event TierUpgraded(uint256 indexed stakeId, uint8 newTier, uint256 newLockupEnd);
    event NftClaimed(uint256 indexed stakeId, uint8 indexed tierId);
    event LockupReset(uint256 indexed stakeId);
    event TierRequirementSet(uint8 indexed tier, address indexed token, uint256 amount);
    event TierLockupSet(uint8 indexed tier, uint256 lockupMinutes);
    event PositionDeleted(uint256 indexed stakeId);
    event TokenWhitelisted(address indexed token, bool enabled);
    event ClaimNftFeeSet(uint256 fee);

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
        emit TokenWhitelisted(_token, _isWhitelisted);
    }

    function setTierRequirement(uint8 _tier, address _token, uint256 _amount) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "Staking: Tier must be 1..MAX_TIER");
        require(whitelistedTokens[_token], "Staking: Token not whitelisted");
        tierRequirements[_tier][_token] = _amount;
        emit TierRequirementSet(_tier, _token, _amount);
    }

    function setTierLockup(uint8 _tier, uint256 _minutes) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "Staking: Tier must be 1..MAX_TIER");
        tierRequiredLockupMinutes[_tier] = _minutes;
        emit TierLockupSet(_tier, _minutes);
    }

    function addTokenToTierCheckList(uint8 _tier, address _token) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "Staking: Tier invalid");
        require(whitelistedTokens[_token], "Staking: Token not whitelisted");
        tierCheckTokens[_tier].push(_token);
    }

    function clearTierCheckList(uint8 _tier) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "Staking: Tier invalid");
        delete tierCheckTokens[_tier];
    }

    function setClaimNftFee(uint256 _fee) external onlyOwner {
        claimNftFee = _fee;
        emit ClaimNftFeeSet(_fee);
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

        // track owner stakes
        ownerStakes[msg.sender].push(stakeId);

        emit PositionCreated(msg.sender, stakeId, newPosition.lockupEnd);
        return stakeId;
    }

    /// @notice Add token/native to stake position. For native use NATIVE_TOKEN (address(0)) and send msg.value == _amount.
    function addToStake(uint256 _stakeId, address _token, uint256 _amount) external payable whenNotPaused nonReentrant {
        StakePosition storage position = stakePositions[_stakeId];
        require(position.owner == msg.sender, "Staking: Not your stake");
        require(block.timestamp >= position.lockupEnd, "Staking: Locked");
        require(whitelistedTokens[_token], "Staking: Token not whitelisted");
        require(_amount > 0, "Staking: Amount must > 0");

        // contoh fee 1% (100 / 10000). Ubah aturan fee sesuai kebutuhan.
        uint256 feeAmount = (_amount * 100) / 10000;
        uint256 amountToStake = _amount - feeAmount;

        if (feeAmount > 0) {
            collectedFees[_token] += feeAmount;
        }

        position.stakedAmounts[_token] += amountToStake;

        if (_token == NATIVE_TOKEN) {
            require(msg.value == _amount, "Staking: Native mismatch");
            // nilai native sudah berada di kontrak melalui msg.value
        } else {
            require(msg.value == 0, "Staking: Do not send native");
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        }

        emit FundsAdded(_stakeId, _token, amountToStake);
        _updateTier(_stakeId);
    }

    function claimNft(uint256 _stakeId) external payable whenNotPaused nonReentrant {
        if (claimNftFee > 0) {
            require(msg.value == claimNftFee, "Staking: Incorrect fee");
            collectedFees[NATIVE_TOKEN] += msg.value;
        }

        StakePosition storage position = stakePositions[_stakeId];
        uint8 tierToClaim = position.tier;
        require(position.owner == msg.sender, "Staking: Not owner");
        require(tierToClaim > 0, "Staking: No tier");
        require(block.timestamp >= position.lockupEnd, "Staking: Lockup not ended");
        require(address(nftContract) != address(0), "Staking: NFT not set");
        require(!hasClaimedNft[_stakeId][tierToClaim], "Staking: NFT already claimed");

        hasClaimedNft[_stakeId][tierToClaim] = true;
        position.lockupEnd = block.timestamp;
        emit LockupReset(_stakeId);

        nftContract.mintForTier(msg.sender, tierToClaim);
        emit NftClaimed(_stakeId, tierToClaim);
    }

    function withdrawToken(uint256 _stakeId, address _token) external whenNotPaused nonReentrant {
        StakePosition storage position = stakePositions[_stakeId];
        require(position.owner == msg.sender, "Staking: Not owner");
        require(block.timestamp >= position.lockupEnd, "Staking: Locked");

        uint256 amount = position.stakedAmounts[_token];
        require(amount > 0, "Staking: No staked amount");

        position.stakedAmounts[_token] = 0;

        if (_token == NATIVE_TOKEN) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(_token).transfer(msg.sender, amount);
        }
        emit WithdrawnToken(_stakeId, _token, amount);
    }

    // ===================================
    //        Fungsi Hapus Posisi Stake
    // ===================================
    function deleteStakePosition(uint256 _stakeId) external whenNotPaused nonReentrant {
        StakePosition storage position = stakePositions[_stakeId];
        require(position.owner == msg.sender, "Staking: Not owner");

        // Tarik semua token yang di stake berdasarkan tierCheckTokens (agar konsisten)
        address[] memory tokensToReturn = tierCheckTokens[position.tier];
        for (uint i = 0; i < tokensToReturn.length; i++) {
            address token = tokensToReturn[i];
            uint256 amount = position.stakedAmounts[token];
            if (amount > 0) {
                position.stakedAmounts[token] = 0;
                if (token == NATIVE_TOKEN) {
                    payable(msg.sender).transfer(amount);
                } else {
                    IERC20(token).transfer(msg.sender, amount);
                }
                emit WithdrawnToken(_stakeId, token, amount);
            }
        }

        // Hapus stakeId dari ownerStakes (swap & pop)
        _removeStakeIdFromOwner(position.owner, _stakeId);

        // Hapus posisi stake
        delete stakePositions[_stakeId];
        emit PositionDeleted(_stakeId);
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
            uint256 newLockupEnd = block.timestamp + (tierRequiredLockupMinutes[nextTier] * 1 minutes);
            position.lockupEnd = newLockupEnd;
            emit TierUpgraded(_stakeId, nextTier, newLockupEnd);
        }
    }

    function _isTierAchieved(uint256 _stakeId, uint8 _tier) internal view returns (bool) {
        StakePosition storage position = stakePositions[_stakeId];
        address[] memory tokensToCheck = tierCheckTokens[_tier];
        if (tokensToCheck.length == 0) return false;

        for (uint i = 0; i < tokensToCheck.length; i++) {
            address token = tokensToCheck[i];
            uint256 requiredAmount = tierRequirements[_tier][token];
            if (position.stakedAmounts[token] < requiredAmount) {
                return false;
            }
        }
        return true;
    }

    // Helper private: hapus stakeId dari ownerStakes dengan swap & pop
    function _removeStakeIdFromOwner(address owner, uint256 stakeId) private {
        uint256[] storage arr = ownerStakes[owner];
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == stakeId) {
                // swap & pop
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }

    // =======================
    //  Fungsi View Helper UI
    // =======================

    /// @notice Dapatkan informasi stake lengkap untuk UI (owner, tier, lockup, tokens & amounts (menggunakan tierCheckTokens[tier]))
    function getStakeInfo(uint256 _stakeId) external view returns (
        address owner,
        uint8 tier,
        uint256 lockupEnd,
        address[] memory tokens,
        uint256[] memory amounts
    ) {
        StakePosition storage position = stakePositions[_stakeId];
        owner = position.owner;
        tier = position.tier;
        lockupEnd = position.lockupEnd;

        address[] memory tokensToCheck = tierCheckTokens[tier];
        tokens = new address[](tokensToCheck.length);
        amounts = new uint256[](tokensToCheck.length);

        for (uint i = 0; i < tokensToCheck.length; i++) {
            tokens[i] = tokensToCheck[i];
            amounts[i] = position.stakedAmounts[tokens[i]];
        }
    }

    /// @notice Dapatkan semua requirement sebuah tier (tokens, amounts, lockupMinutes)
    function getTierRequirements(uint8 _tier) external view returns (
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 lockupMinutes
    ) {
        address[] memory tokensToCheck = tierCheckTokens[_tier];
        tokens = new address[](tokensToCheck.length);
        amounts = new uint256[](tokensToCheck.length);

        for (uint i = 0; i < tokensToCheck.length; i++) {
            tokens[i] = tokensToCheck[i];
            amounts[i] = tierRequirements[_tier][tokens[i]];
        }

        lockupMinutes = tierRequiredLockupMinutes[_tier];
    }

    /// @notice Cek apakah stakeId saat ini dapat klaim NFT (frontend toggle)
    function canClaimNft(uint256 _stakeId) external view returns (bool) {
        StakePosition storage position = stakePositions[_stakeId];
        if (position.owner == address(0)) return false;
        uint8 currentTier = position.tier;
        if (currentTier == 0) return false;
        if (block.timestamp < position.lockupEnd) return false;
        if (hasClaimedNft[_stakeId][currentTier]) return false;
        if (address(nftContract) == address(0)) return false;
        return true;
    }

    /// @notice Ambil semua stakeId milik owner
    function getOwnerStakeIds(address _owner) external view returns (uint256[] memory) {
        return ownerStakes[_owner];
    }

    function getTierCheckTokens(uint8 _tier) external view returns (address[] memory) {
        return tierCheckTokens[_tier];
    }

    function getTierLockupMinutes(uint8 _tier) external view returns (uint256) {
        return tierRequiredLockupMinutes[_tier];
    }

    function isTokenWhitelisted(address _token) external view returns (bool) {
        return whitelistedTokens[_token];
    }

    function getCollectedFee(address _token) external view returns (uint256) {
        return collectedFees[_token];
    }

    // Ambil jumlah stake untuk token tertentu pada stakeId
    function getStakedAmount(uint256 _stakeId, address _token) external view returns (uint256) {
        return stakePositions[_stakeId].stakedAmounts[_token];
    }
}
