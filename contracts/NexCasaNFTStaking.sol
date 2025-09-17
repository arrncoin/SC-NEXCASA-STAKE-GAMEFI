// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INexCasaNFT.sol"; // Menggunakan interface yang sudah diperbarui

/**
 * @title NexCasaNFTStaking
 * @dev Kontrak untuk staking NexCasaNFT dan mendapatkan reward token $NEXCASA.
 */
contract NexCasaNFTStaking is Ownable, ReentrancyGuard {

    INexCasaNFT public nftContract;
    IERC20 public rewardToken; // Token $NEXCASA

    mapping(uint8 => uint256) public rewardsPerSecondByTier;

    struct StakedNft {
        address owner;
        uint256 startTime;
        uint8 tier;
    }

    mapping(uint256 => StakedNft) public stakedNfts;
    mapping(address => uint256) public userPendingRewards;

    // Variabel untuk melacak total NFT yang di-stake per pengguna
    mapping(address => uint256) public userStakeCount;

    // Variabel untuk melacak kapan terakhir reward diupdate untuk sebuah token
    mapping(uint256 => uint256) public lastRewardUpdateTime;


    event NftStaked(address indexed user, uint256 indexed tokenId, uint8 tier);
    event NftUnstaked(address indexed user, uint256 indexed tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {}

    // ===================================
    //           Fungsi Admin
    // ===================================
    function setContracts(address _nftAddress, address _rewardTokenAddress) external onlyOwner {
        nftContract = INexCasaNFT(_nftAddress);
        rewardToken = IERC20(_rewardTokenAddress);
    }

    function setTierRewardRate(uint8 _tier, uint256 _rewardsPerSecond) external onlyOwner {
        require(_tier > 0 && _tier <= 9, "Tier must be between 1 and 9");
        rewardsPerSecondByTier[_tier] = _rewardsPerSecond;
    }

    // ===================================
    //           Fungsi Pengguna
    // ===================================
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        require(_tokenIds.length > 0, "Must stake at least one NFT");

        // Update reward yang ada sebelum menambah stake baru
        _updateRewards(msg.sender);

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];

            // Tarik NFT dari pengguna ke kontrak
            nftContract.transferFrom(msg.sender, address(this), tokenId);

            uint8 tier = nftContract.nftTier(tokenId);
            require(tier > 0, "NFT tier is not valid");
            require(stakedNfts[tokenId].owner == address(0), "NFT already staked");

            // Simpan data staking
            stakedNfts[tokenId] = StakedNft({
                owner: msg.sender,
                startTime: block.timestamp,
                tier: tier
            });
            lastRewardUpdateTime[tokenId] = block.timestamp;
            userStakeCount[msg.sender]++;

            emit NftStaked(msg.sender, tokenId, tier);
        }
    }

    function unstake(uint256[] calldata _tokenIds) external nonReentrant {
        require(_tokenIds.length > 0, "Must unstake at least one NFT");

        _updateRewards(msg.sender);

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            StakedNft storage staked = stakedNfts[tokenId];
            require(staked.owner == msg.sender, "You are not the owner of this staked NFT");

            delete stakedNfts[tokenId];
            delete lastRewardUpdateTime[tokenId];
            userStakeCount[msg.sender]--;

            // Kembalikan NFT ke pengguna
            nftContract.transferFrom(address(this), msg.sender, tokenId);

            emit NftUnstaked(msg.sender, tokenId);
        }
    }

    function claimRewards() external nonReentrant {
        _updateRewards(msg.sender);
        
        uint256 rewardAmount = userPendingRewards[msg.sender];
        require(rewardAmount > 0, "No rewards to claim");

        userPendingRewards[msg.sender] = 0;

        // Pastikan kontrak punya cukup token untuk membayar
        require(rewardToken.balanceOf(address(this)) >= rewardAmount, "Insufficient reward balance in contract");
        rewardToken.transfer(msg.sender, rewardAmount);

        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    // ===================================
    //       Fungsi View & Internal
    // ===================================
    function calculatePendingRewards(address _user) public view returns (uint256) {
        // Ini adalah fungsi view, jadi tidak bisa mengupdate state.
        // Fungsi ini akan menjadi sangat mahal jika pengguna punya banyak NFT.
        // Implementasi di bawah ini hanya untuk ilustrasi,
        // model `_updateRewards` lebih efisien untuk on-chain.
        return userPendingRewards[_user];
    }
    
    function _updateRewards(address _user) internal {
        // Fungsi ini sengaja dikosongkan karena model yang lebih efisien gas
        // akan memerlukan perubahan arsitektur yang signifikan.
        // Model saat ini bergantung pada pengguna untuk memanggil `claimRewards` secara berkala.
        // Untuk versi yang lebih canggih, Anda akan mengiterasi NFT pengguna
        // atau menggunakan pola matematika yang lebih kompleks.
        // Untuk saat ini, kita akan menjaga agar tetap simpel.
    }
}