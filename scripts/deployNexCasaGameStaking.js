// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // === Deploy kontrak NexCasaGameStaking ===
  const Staking = await ethers.getContractFactory("NexCasaGameStaking");
  const staking = await Staking.deploy();
  await staking.waitForDeployment();

  console.log("✅ NexCasaGameStaking deployed at:", staking.target);

  // === Optional: set NFT contract jika sudah ada ===
  const NFT_ADDRESS = "0xF380E156723f8D97278f8D0317FBDceEB01d34b5"; // ganti sesuai NFT kamu
  const tx = await staking.setNftContract(NFT_ADDRESS);
  await tx.wait();
  console.log(`✅ NFT contract set to: ${NFT_ADDRESS}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
