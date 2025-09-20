// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NexCasaNFT
 * @dev ERC721 NFT yang bisa ditukar (redeem) dengan token ERC20.
 * Minting hanya bisa dilakukan oleh kontrak game staking atau langsung oleh owner.
 * Transfer staking hanya bisa dilakukan oleh kontrak NFT staking (dengan isApprovedForAll).
 */
contract NexCasaNFT is ERC721, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // ✅ pisahkan minter dan staking contract
    address public minterContract;
    address public stakingContract;

    uint8 public constant MAX_TIER = 9;

    string private _baseTokenURI;

    mapping(uint256 => uint8) public nftTier;
    mapping(uint8 => address) public redemptionToken;
    mapping(uint8 => uint256) public redemptionAmount;

    uint256 private _nextTokenId = 1;

    event MinterContractUpdated(address indexed newContract);
    event StakingContractUpdated(address indexed newContract);
    event RedemptionDataUpdated(uint8 indexed tier, address token, uint256 amount);
    event NFTMinted(address indexed to, uint256 indexed tokenId, uint8 tier);
    event NFTRedeemed(address indexed owner, uint256 indexed tokenId, address token, uint256 amount);

    constructor(string memory baseTokenURI_) 
        ERC721("NexCasa Tier NFT", "NCNFT")
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI_;
    }

    /** ================================
     *            ADMIN FUNCTIONS
     *  ================================ */
    function setMinterContract(address _minter) external onlyOwner {
        require(_minter != address(0), "NexCasaNFT: Cannot set zero address");
        minterContract = _minter;
        emit MinterContractUpdated(_minter);
    }

    function setStakingContract(address _staking) external onlyOwner {
        require(_staking != address(0), "NexCasaNFT: Cannot set zero address");
        stakingContract = _staking;
        emit StakingContractUpdated(_staking);
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
        require(msg.sender == minterContract, "NexCasaNFT: Only minter contract can mint");
        require(tier > 0 && tier <= MAX_TIER, "NexCasaNFT: Invalid tier");

        uint256 newTokenId = _nextTokenId;
        _safeMint(to, newTokenId);
        nftTier[newTokenId] = tier;

        _nextTokenId++;
        emit NFTMinted(to, newTokenId, tier);

        return newTokenId;
    }

    function ownerMint(address to, uint8 tier) external onlyOwner returns (uint256) {
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
        ownerOf(tokenId); // revert kalau token tidak ada
        uint8 tier = nftTier[tokenId];
        return string(
            abi.encodePacked(
                _baseTokenURI,
                "/tier",
                uint256(tier).toString(),
                ".json"
            )
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /** ================================
     *   ALLOW STAKING CONTRACT AS OPERATOR
     *  ================================ */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        if (operator == stakingContract) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /** ================================
     *         INTERFACE SUPPORT
     *  ================================ */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
