// scripts/configureCore.js

const hre = require("hardhat");

async function main() {
  const { ethers } = hre;
  const [deployer] = await ethers.getSigners();
  console.log("PHASE 4: Configuring core contracts with account:", deployer.address);

  // --- Alamat dari Fase 1 (Tokens) ---
  const NEXCASA_ADDRESS = "0x9049aab30D49bA7036dA27FA3FC18375b6341b45";
  const NC_BTC_ADDRESS  = "0x447335Aa2D62bB917082b3833e56b416e78Ba43c";
  const NC_ETH_ADDRESS  = "0x3eC1E7ab0328606Bbb0AeDa392979072c830963f";
  const NC_USDT_ADDRESS = "0x1DDDc56ccd817A0001352A6474255fF9B3DA1713";
  const NC_USDC_ADDRESS = "0x9E7DD26455cc34Aa538e6C8F970df854f14e3B35";

  // --- Alamat dari Fase 2 (Core Contracts) ---
  const NFT_ADDRESS            = "0x62a647527683824615fc2493059683E44E0A6b1f";
  const GAME_STAKING_ADDRESS   = "0xF0C30aA46e3214D639DedBdAb69b6737fEDb47ba";
  const NFT_STAKING_ADDRESS    = "0x532b0D6B16A6B7352924DEfA999D901bD0Aa86Af";

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
