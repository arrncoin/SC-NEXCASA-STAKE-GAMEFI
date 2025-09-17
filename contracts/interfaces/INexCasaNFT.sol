// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title INexCasaNFT
 * @dev Interface ini menggabungkan fungsi standar IERC721 dengan fungsi kustom NexCasaNFT.
 */
interface INexCasaNFT is IERC721 {
    /**
     * @dev Fungsi kustom untuk minting NFT berdasarkan tier.
     */
    function mintForTier(address to, uint8 tierId) external;

    /**
     * @dev Fungsi kustom untuk melihat tier dari sebuah NFT.
     */
    function nftTier(uint256 tokenId) external view returns (uint8);
}