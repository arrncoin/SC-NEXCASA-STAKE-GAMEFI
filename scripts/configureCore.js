// scripts/configureCore.js

const hre = require("hardhat");

async function main() {
  const { ethers } = hre;
  const [deployer] = await ethers.getSigners();
  console.log("PHASE 4: Configuring core contracts with account:", deployer.address);

  // --- Alamat dari Fase 1 (Tokens) ---
  const NEXCASA_ADDRESS = "0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB";
  const NC_BTC_ADDRESS  = "0xA1A5987Cc7da36f4606A2a9F00DEb66A4e37734F";
  const NC_ETH_ADDRESS  = "0x7ceC127e4c5793BaeA2C5da5e8b6086f0D3A23f5";
  const NC_USDT_ADDRESS = "0x7729Cbf0F8745fc5698adbD5B2D27b8C3C1ab23f";
  const NC_USDC_ADDRESS = "0x1381ceB65a8e6769658e84291CF28782bE4C2668";

  // --- Alamat dari Fase 2 (Core Contracts) ---
  const NFT_ADDRESS            = "0xF380E156723f8D97278f8D0317FBDceEB01d34b5";
  const GAME_STAKING_ADDRESS   = "0x3eaed605e43dB976818831bEFfee6b10904fb747";
  const NFT_STAKING_ADDRESS    = "0x7052d9B3e2B152E93510c31D1C9f445818fc0e72";

  // 1. Attach contract instances
  console.log("\nAttaching to existing core contracts...");
  const gameStaking = await ethers.getContractAt("NexCasaGameStaking", GAME_STAKING_ADDRESS, deployer);
  const nft = await ethers.getContractAt("NexCasaNFT", NFT_ADDRESS, deployer);
  const nftStaking = await ethers.getContractAt("NexCasaNFTStaking", NFT_STAKING_ADDRESS, deployer);
  console.log("- Core contract instances attached.");

  // 2. Link GameStaking <--> NFT
  console.log("\nLinking GameStaking <--> NFT contract...");
  let tx = await gameStaking.setNftContract(NFT_ADDRESS);
  await tx.wait();
  tx = await nft.setStakingContract(GAME_STAKING_ADDRESS);
  await tx.wait();
  console.log("- GameStaking and NFT contracts linked.");

  // 3. Link NFTStaking with NFT + reward token
  console.log("\nLinking NFTStaking with its dependencies...");
  tx = await nftStaking.setContracts(NFT_ADDRESS, NEXCASA_ADDRESS);
  await tx.wait();
  console.log("- NFTStaking contract linked.");

  // 4. Whitelist mock tokens
  console.log("\nWhitelisting mock tokens in GameStaking...");
  tx = await gameStaking.setWhitelistToken(NC_BTC_ADDRESS, true); await tx.wait();
  tx = await gameStaking.setWhitelistToken(NC_ETH_ADDRESS, true); await tx.wait();
  tx = await gameStaking.setWhitelistToken(NC_USDT_ADDRESS, true); await tx.wait();
  tx = await gameStaking.setWhitelistToken(NC_USDC_ADDRESS, true); await tx.wait();
  console.log("- All mock tokens have been whitelisted.");

  console.log("\n✅ PHASE 4 COMPLETE: Core contracts are now linked and configured.");
  console.log("➡️ ACTION: The system is now technically live. The final step is to set the game rules.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
