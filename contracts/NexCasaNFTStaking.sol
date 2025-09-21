// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/INexCasaNFT.sol";

/// @title NexCasaNFTStaking
/// @notice Stake NexCasa NFT untuk mendapatkan reward $NEXCASA per-tier secara time-based.
/// UI-friendly: helper list per-user, pending realtime, dll.
contract NexCasaNFTStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    INexCasaNFT public nftContract;
    IERC20 public rewardToken;

    // rewards per second per tier (tier => reward/sec)
    mapping(uint8 => uint256) public rewardsPerSecondByTier;

    struct StakedNft {
        address owner;
        uint256 startTime;
        uint8 tier;
    }

    // tokenId => StakedNft
    mapping(uint256 => StakedNft) public stakedNfts;

    // user pending rewards already accumulated (updated by _updateRewards)
    mapping(address => uint256) public userPendingRewards;

    // user => list of staked tokenIds (to iterate quickly per user)
    mapping(address => uint256[]) private userStakedTokens;

    // tokenId => index in owner's userStakedTokens array (+1). zero means not present.
    mapping(uint256 => uint256) private userStakedIndex;

    // tokenId => last timestamp reward was updated for this token
    mapping(uint256 => uint256) public lastRewardUpdateTime;

    // convenience count mapping (mirror length of userStakedTokens)
    mapping(address => uint256) public userStakeCount;

    // Events
    event NftStaked(address indexed user, uint256 indexed tokenId, uint8 tier);
    event NftUnstaked(address indexed user, uint256 indexed tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ContractsSet(address nftContract, address rewardToken);
    event TierRewardRateSet(uint8 tier, uint256 rewardPerSecond);

    constructor() Ownable(msg.sender) {}

    // -------------------------
    // Admin
    // -------------------------
    function setContracts(address _nftAddress, address _rewardTokenAddress) external onlyOwner {
        require(_nftAddress != address(0) && _rewardTokenAddress != address(0), "zero addr");
        nftContract = INexCasaNFT(_nftAddress);
        rewardToken = IERC20(_rewardTokenAddress);
        emit ContractsSet(_nftAddress, _rewardTokenAddress);
    }

    function setTierRewardRate(uint8 _tier, uint256 _rewardsPerSecond) external onlyOwner {
        require(_tier > 0 && _tier <= 255, "invalid tier"); // tier bound flexible; keep <=255
        rewardsPerSecondByTier[_tier] = _rewardsPerSecond;
        emit TierRewardRateSet(_tier, _rewardsPerSecond);
    }

    // -------------------------
    // User: stake / unstake / claim
    // -------------------------
    /// @notice Stake multiple tokenIds. Caller must approve NFT transfers.
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        require(_tokenIds.length > 0, "empty");
        // update pending rewards before modifying stakes
        _updateRewards(msg.sender);

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];

            // transfer NFT to this contract
            nftContract.transferFrom(msg.sender, address(this), tokenId);

            uint8 tier = nftContract.nftTier(tokenId);
            require(tier > 0, "invalid tier");
            require(stakedNfts[tokenId].owner == address(0), "already staked");

            // write staked record
            stakedNfts[tokenId] = StakedNft({
                owner: msg.sender,
                startTime: block.timestamp,
                tier: tier
            });

            // set last update time for this token
            lastRewardUpdateTime[tokenId] = block.timestamp;

            // add token to user's list
            _addTokenToUserEnumeration(msg.sender, tokenId);

            emit NftStaked(msg.sender, tokenId, tier);
        }
    }

    /// @notice Unstake multiple tokenIds previously staked by caller.
    function unstake(uint256[] calldata _tokenIds) external nonReentrant {
        require(_tokenIds.length > 0, "empty");
        // update pending rewards before removing stakes
        _updateRewards(msg.sender);

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            StakedNft storage s = stakedNfts[tokenId];
            require(s.owner == msg.sender, "not owner");

            // remove staked record & bookkeeping
            delete stakedNfts[tokenId];
            delete lastRewardUpdateTime[tokenId];

            // remove from user list
            _removeTokenFromUserEnumeration(msg.sender, tokenId);

            // transfer NFT back to owner
            nftContract.transferFrom(address(this), msg.sender, tokenId);

            emit NftUnstaked(msg.sender, tokenId);
        }
    }

    /// @notice Claim accumulated rewards (updates pending first).
    function claimRewards() external nonReentrant {
        _updateRewards(msg.sender);

        uint256 amount = userPendingRewards[msg.sender];
        require(amount > 0, "no rewards");
        userPendingRewards[msg.sender] = 0;

        // safe transfer
        require(rewardToken.balanceOf(address(this)) >= amount, "insufficient contract balance");
        rewardToken.safeTransfer(msg.sender, amount);

        emit RewardsClaimed(msg.sender, amount);
    }

    // -------------------------
    // Internal reward logic
    // -------------------------
    /// @dev Update userPendingRewards by accumulating rewards from each staked token since lastRewardUpdateTime.
    function _updateRewards(address _user) internal {
        uint256[] storage tokens = userStakedTokens[_user];
        uint256 len = tokens.length;
        if (len == 0) return;

        uint256 acc = 0;
        uint256 nowTs = block.timestamp;

        for (uint i = 0; i < len; i++) {
            uint256 tokenId = tokens[i];
            uint256 last = lastRewardUpdateTime[tokenId];
            if (last == 0) {
                // shouldn't happen for active stakes, but skip defensively
                last = nowTs;
                lastRewardUpdateTime[tokenId] = nowTs;
                continue;
            }
            if (nowTs > last) {
                uint8 tier = stakedNfts[tokenId].tier;
                uint256 rate = rewardsPerSecondByTier[tier];
                if (rate > 0) {
                    uint256 delta = nowTs - last;
                    // delta * rate (watch overflow not an issue with 256)
                    acc += delta * rate;
                }
                lastRewardUpdateTime[tokenId] = nowTs;
            }
        }

        if (acc > 0) {
            userPendingRewards[_user] += acc;
        }
    }

    // -------------------------
    // View helpers (UI-friendly)
    // -------------------------
    /// @notice Realtime pending rewards for an address (does NOT modify state).
    function pendingRewards(address _user) public view returns (uint256) {
        uint256 pending = userPendingRewards[_user];

        uint256[] storage tokens = userStakedTokens[_user];
        uint256 len = tokens.length;
        uint256 nowTs = block.timestamp;

        for (uint i = 0; i < len; i++) {
            uint256 tokenId = tokens[i];
            uint256 last = lastRewardUpdateTime[tokenId];
            if (last == 0 || nowTs <= last) continue;
            uint8 tier = stakedNfts[tokenId].tier;
            uint256 rate = rewardsPerSecondByTier[tier];
            if (rate == 0) continue;
            uint256 delta = nowTs - last;
            pending += delta * rate;
        }
        return pending;
    }

    /// @notice Get array of tokenIds staked by user.
    function getUserStakedTokens(address _user) external view returns (uint256[] memory) {
        return userStakedTokens[_user];
    }

    /// @notice Return staked data for a token
    function getStakedNft(uint256 tokenId) external view returns (StakedNft memory) {
        return stakedNfts[tokenId];
    }

    /// @notice Quick check if token is staked
    function isTokenStaked(uint256 tokenId) external view returns (bool) {
        return stakedNfts[tokenId].owner != address(0);
    }

    // -------------------------
    // Internal bookkeeping for user token lists
    // -------------------------
    function _addTokenToUserEnumeration(address user, uint256 tokenId) internal {
        userStakedIndex[tokenId] = userStakedTokens[user].length; // store index
        userStakedTokens[user].push(tokenId);
        userStakeCount[user] = userStakedTokens[user].length;
    }

    function _removeTokenFromUserEnumeration(address user, uint256 tokenId) internal {
        uint256 index = userStakedIndex[tokenId];
        uint256 lastIndex = userStakedTokens[user].length - 1;
        if (index != lastIndex) {
            uint256 lastTokenId = userStakedTokens[user][lastIndex];
            userStakedTokens[user][index] = lastTokenId;
            userStakedIndex[lastTokenId] = index;
        }
        // pop last
        userStakedTokens[user].pop();
        userStakedIndex[tokenId] = 0; // reset
        userStakeCount[user] = userStakedTokens[user].length;
    }
}
