// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NexCasaNFT
 * @dev Soulbound ERC721 NFT (non-transferable) yang bisa ditukar (redeem) dengan token ERC20.
 * Minting hanya bisa dilakukan oleh kontrak staking.
 */
contract NexCasaNFT is ERC721, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    address public stakingContract;
    uint8 public constant MAX_TIER = 9;

    string private _baseTokenURI;

    mapping(uint256 => uint8) public nftTier;
    mapping(uint8 => address) public redemptionToken;
    mapping(uint8 => uint256) public redemptionAmount;

    uint256 private _nextTokenId = 1;

    event StakingContractUpdated(address indexed newContract);
    event RedemptionDataUpdated(uint8 indexed tier, address token, uint256 amount);
    event NFTMinted(address indexed to, uint256 indexed tokenId, uint8 tier);
    event NFTRedeemed(address indexed owner, uint256 indexed tokenId, address token, uint256 amount);

    constructor(string memory baseTokenURI_) 
        ERC721("NexCasa Tier NFT", "NCNFT") 
        Ownable(msg.sender)   // ✅ Wajib kasih initialOwner di OZ v5.x
    {
        _baseTokenURI = baseTokenURI_;
    }

    /** ================================
     *            ADMIN FUNCTIONS
     *  ================================ */
    function setStakingContract(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "NexCasaNFT: Cannot set zero address");
        stakingContract = _stakingContract;
        emit StakingContractUpdated(_stakingContract);
    }

    function setRedemptionData(uint8 _tier, address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "NexCasaNFT: Invalid tier");
        require(_tokenAddress != address(0), "NexCasaNFT: Zero token address");
        redemptionToken[_tier] = _tokenAddress;
        redemptionAmount[_tier] = _amount;
        emit RedemptionDataUpdated(_tier, _tokenAddress, _amount);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /** ================================
     *            MINT & REDEEM
     *  ================================ */
    function mint(address to, uint8 tier) external returns (uint256) {
        require(msg.sender == stakingContract, "NexCasaNFT: Only staking contract can mint");
        require(tier > 0 && tier <= MAX_TIER, "NexCasaNFT: Invalid tier");

        uint256 newTokenId = _nextTokenId;
        _safeMint(to, newTokenId);
        nftTier[newTokenId] = tier;

        _nextTokenId++;
        emit NFTMinted(to, newTokenId, tier);

        return newTokenId;
    }

    function redeem(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "NexCasaNFT: Not the owner");

        uint8 tier = nftTier[tokenId];
        require(tier > 0, "NexCasaNFT: Tier not found");

        address tokenAddress = redemptionToken[tier];
        uint256 tokenAmount = redemptionAmount[tier];
        require(tokenAddress != address(0) && tokenAmount > 0, "NexCasaNFT: Redemption not set");

        _burn(tokenId);
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);

        emit NFTRedeemed(msg.sender, tokenId, tokenAddress, tokenAmount);
    }

    /** ================================
     *            METADATA
     *  ================================ */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ownerOf(tokenId); // ✅ revert otomatis kalau token belum ada
        uint8 tier = nftTier[tokenId];
        return string(
            abi.encodePacked(
                _baseTokenURI, 
                "/tier", 
                uint256(tier).toString(),  // ✅ cast ke uint256
                ".json"
            )
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /** ================================
     *            SOULBOUND
     *  ================================ */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        // Soulbound: hanya izinkan mint (from=0) dan burn (to=0)
        if (from != address(0) && to != address(0)) {
            revert("NexCasaNFT: Soulbound, non-transferable");
        }

        return super._update(to, tokenId, auth);
    }

    /** ================================
     *         INTERFACE SUPPORT
     *  ================================ */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
