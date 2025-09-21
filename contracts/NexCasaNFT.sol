// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NexCasaNFT
 * @dev ERC721 NFT tiered yang bisa diredeem ke token ERC20.
 * - Minting: hanya minterContract atau owner.
 * - Staking: stakingContract otomatis di-approve.
 * - UI/UX: menyediakan helper untuk frontend ambil data sekali call.
 */
contract NexCasaNFT is ERC721, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // =============================================================
    // =============== Core State & Constants ======================
    // =============================================================

    address public minterContract;
    address public stakingContract;

    uint8 public constant MAX_TIER = 9;
    uint256 private _nextTokenId = 1;

    string private _baseTokenURI;

    mapping(uint256 => uint8) public nftTier;
    mapping(uint8 => address) public redemptionToken;
    mapping(uint8 => uint256) public redemptionAmount;

    // =============================================================
    // ========================= Events ============================
    // =============================================================

    event MinterContractUpdated(address indexed newContract);
    event StakingContractUpdated(address indexed newContract);
    event RedemptionDataUpdated(uint8 indexed tier, address token, uint256 amount);
    event NFTMinted(address indexed to, uint256 indexed tokenId, uint8 tier);
    event NFTRedeemed(address indexed owner, uint256 indexed tokenId, address token, uint256 amount);

    // =============================================================
    // ======================== Constructor ========================
    // =============================================================

    constructor(string memory baseTokenURI_)
        ERC721("NexCasa Tier NFT", "NCNFT")
        Ownable(msg.sender) // ✅ OZ v5 perlu initialOwner
    {
        _baseTokenURI = baseTokenURI_;
    }

    // =============================================================
    // ======================== Admin Ops ==========================
    // =============================================================

    function setMinterContract(address _minter) external onlyOwner {
        require(_minter != address(0), "NexCasaNFT: zero address");
        minterContract = _minter;
        emit MinterContractUpdated(_minter);
    }

    function setStakingContract(address _staking) external onlyOwner {
        require(_staking != address(0), "NexCasaNFT: zero address");
        stakingContract = _staking;
        emit StakingContractUpdated(_staking);
    }

    function setRedemptionData(
        uint8 _tier,
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        require(_tier > 0 && _tier <= MAX_TIER, "NexCasaNFT: invalid tier");
        require(_tokenAddress != address(0), "NexCasaNFT: zero token");

        redemptionToken[_tier] = _tokenAddress;
        redemptionAmount[_tier] = _amount;
        emit RedemptionDataUpdated(_tier, _tokenAddress, _amount);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    // =============================================================
    // ===================== Minting Ops ===========================
    // =============================================================

    function mintForTier(address to, uint8 tier) external returns (uint256) {
        require(msg.sender == minterContract, "NexCasaNFT: only minter");
        return _mintInternal(to, tier);
    }

    function ownerMint(address to, uint8 tier) external onlyOwner returns (uint256) {
        return _mintInternal(to, tier);
    }

    function _mintInternal(address to, uint8 tier) internal returns (uint256) {
        require(tier > 0 && tier <= MAX_TIER, "NexCasaNFT: invalid tier");

        uint256 newTokenId = _nextTokenId;
        _safeMint(to, newTokenId);
        nftTier[newTokenId] = tier;

        _nextTokenId++;
        emit NFTMinted(to, newTokenId, tier);

        return newTokenId;
    }

    // =============================================================
    // ===================== Redeem Ops ============================
    // =============================================================

    function redeem(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "NexCasaNFT: not owner");

        uint8 tier = nftTier[tokenId];
        require(tier > 0, "NexCasaNFT: no tier");

        address tokenAddress = redemptionToken[tier];
        uint256 tokenAmount = redemptionAmount[tier];
        require(tokenAddress != address(0) && tokenAmount > 0, "NexCasaNFT: no redemption");

        _burn(tokenId);
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);

        emit NFTRedeemed(msg.sender, tokenId, tokenAddress, tokenAmount);
    }

    // =============================================================
    // ===================== Metadata Ops ==========================
    // =============================================================

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "NexCasaNFT: nonexistent");
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

    // =============================================================
    // ================== Staking Allowance ========================
    // =============================================================

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (operator == stakingContract) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    // =============================================================
    // ================== Extra UI/UX Helpers ======================
    // =============================================================

    /// @notice Ambil semua tokenId yang dimiliki oleh `owner`
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        uint256 counter = 0;

        for (uint256 tokenId = 1; tokenId < _nextTokenId; tokenId++) {
            if (_ownerOf(tokenId) == owner) {
                tokens[counter] = tokenId;
                counter++;
                if (counter == balance) break;
            }
        }
        return tokens;
    }

    /// @notice Ambil data lengkap NFT user: id, tier, URI, redemption info
    function detailedTokensOfOwner(address owner)
        external
        view
        returns (
            uint256[] memory ids,
            uint8[] memory tiers,
            string[] memory uris,
            address[] memory redeemTokens,
            uint256[] memory redeemAmounts
        )
    {
        uint256 balance = balanceOf(owner);
        ids = new uint256[](balance);
        tiers = new uint8[](balance);
        uris = new string[](balance);
        redeemTokens = new address[](balance);
        redeemAmounts = new uint256[](balance);

        uint256 counter = 0;
        for (uint256 tokenId = 1; tokenId < _nextTokenId; tokenId++) {
            if (_ownerOf(tokenId) == owner) {
                ids[counter] = tokenId;
                tiers[counter] = nftTier[tokenId];
                uris[counter] = tokenURI(tokenId);
                redeemTokens[counter] = redemptionToken[tiers[counter]];
                redeemAmounts[counter] = redemptionAmount[tiers[counter]];
                counter++;
                if (counter == balance) break;
            }
        }
    }
}
