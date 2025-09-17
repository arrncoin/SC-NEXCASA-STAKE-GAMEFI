// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // <-- UPDATE: Ditambahkan

/**
 * @title NexCasaNFT
 * @dev Kontrak NFT Soulbound (non-transferable) yang bisa ditukar (redeem)
 * dengan token ERC20.
 * Minting hanya bisa dilakukan oleh kontrak staking.
 */
contract NexCasaNFT is ERC721, Ownable {
    using SafeERC20 for IERC20; // <-- UPDATE: Ditambahkan

    address public stakingContract;
    uint8 public constant MAX_TIER = 9; // <-- UPDATE: Ditambahkan

    // Mapping untuk data tier setiap NFT
    mapping(uint256 => uint8) public nftTier;
    // Mapping untuk reward redeem: tier => token ERC20
    mapping(uint8 => address) public redemptionToken;
    mapping(uint8 => uint256) public redemptionAmount;

    uint256 private _nextTokenId = 1;

    constructor() ERC721("NexCasa Tier NFT", "NCNFT") Ownable(msg.sender) {}

    // ===================================
    //           Fungsi Admin
    // ===================================
    function setStakingContract(address _stakingContract) external onlyOwner {
        // <-- UPDATE: Ditambahkan pengecekan alamat nol
        require(_stakingContract != address(0), "NexCasaNFT: Cannot set to zero address");
        stakingContract = _stakingContract;
    }

    function setRedemption(uint8 _tier, address _token, uint256 _amount) external onlyOwner {
        // <-- UPDATE: Menggunakan MAX_TIER
        require(_tier > 0 && _tier <= MAX_TIER, "NexCasaNFT: Tier must be between 1 and MAX_TIER");
        redemptionToken[_tier] = _token;
        redemptionAmount[_tier] = _amount;
    }

    // ===================================
    //            Fungsi Inti
    // ===================================
    function mintForTier(address to, uint8 tierId) external {
        require(msg.sender == stakingContract, "NexCasaNFT: Only staking contract can mint");
        uint256 tokenId = _nextTokenId;
        nftTier[tokenId] = tierId;
        _safeMint(to, tokenId);
        _nextTokenId++;
    }

    /**
     * @dev Menukar NFT yang dimiliki dengan token ERC20 yang telah ditentukan.
     */
    function redeem(uint256 tokenId) external {
        require(_ownerOf(tokenId) == _msgSender(), "NexCasaNFT: You are not the owner of this NFT");
        
        uint8 tier = nftTier[tokenId];
        require(tier > 0, "NexCasaNFT: Tier data not found for this NFT");
        
        address tokenAddress = redemptionToken[tier];
        uint256 tokenAmount = redemptionAmount[tier];

        require(tokenAddress != address(0) && tokenAmount > 0, "NexCasaNFT: Redemption is not set for this tier");
        
        // 1. Bakar NFT untuk menghapusnya dari peredaran
        _burn(tokenId);
        
        // 2. Kirim token ERC20 sebagai gantinya
        // <-- UPDATE: Menggunakan safeTransfer untuk keamanan
        IERC20(tokenAddress).safeTransfer(_msgSender(), tokenAmount);
    }
    
    /**
     * @dev Membuat NFT menjadi non-transferable (soulbound) dengan memblokir semua transfer
     * kecuali minting (di mana `from` adalah address(0)).
     */
    function _update(address to, uint256 tokenId, address auth)
    internal
    virtual
    override
    returns (address)
    {
        address from = _ownerOf(tokenId);
        // Memastikan transfer hanya diizinkan saat minting (ketika 'from' adalah alamat nol)
        require(from == address(0), "NexCasaNFT: This NFT is soulbound and cannot be transferred");
        return super._update(to, tokenId, auth);
    }
}