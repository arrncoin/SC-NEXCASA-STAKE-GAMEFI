// scripts/1_deployTokens.js

const { ethers } = require("hardhat");

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("PHASE 1: Deploying all ERC20 tokens with the account:", deployer.address);

  // Definisi Pasokan Unik (sudah termasuk desimal)
  const NEXCASA_SUPPLY = ethers.parseUnits("250000000", 18);
  const NC_BTC_SUPPLY = ethers.parseUnits("21000000", 18);
  const NC_ETH_SUPPLY = ethers.parseUnits("120000000", 18);
  const STABLECOIN_SUPPLY = ethers.parseUnits("100000000000", 18);

  // Deploy NexcasaToken
  const NexcasaToken = await ethers.getContractFactory("NexcasaToken");
  const nexcasaToken = await NexcasaToken.deploy(NEXCASA_SUPPLY);
  await nexcasaToken.waitForDeployment();
  console.log(`- NexcasaToken ($NEXCASA) deployed to: ${await nexcasaToken.getAddress()}`);

  console.log("Waiting 3 seconds...");
  await wait(3000);

  // Deploy CustomERC20 (Mock Tokens)
  const CustomERC20 = await ethers.getContractFactory("CustomERC20");

  const ncBTC = await CustomERC20.deploy("Nexcasa BTC", "ncBTC", 18, NC_BTC_SUPPLY, deployer.address);
  await ncBTC.waitForDeployment();
  console.log(`- CustomERC20 (ncBTC) deployed to: ${await ncBTC.getAddress()}`);

  console.log("Waiting 3 seconds...");
  await wait(3000);

  const ncETH = await CustomERC20.deploy("Nexcasa ETH", "ncETH", 18, NC_ETH_SUPPLY, deployer.address);
  await ncETH.waitForDeployment();
  console.log(`- CustomERC20 (ncETH) deployed to: ${await ncETH.getAddress()}`);

  console.log("Waiting 3 seconds...");
  await wait(3000);

  const ncUSDT = await CustomERC20.deploy("Nexcasa USDT", "ncUSDT", 18, STABLECOIN_SUPPLY, deployer.address);
  await ncUSDT.waitForDeployment();
  console.log(`- CustomERC20 (ncUSDT) deployed to: ${await ncUSDT.getAddress()}`);

  console.log("Waiting 3 seconds...");
  await wait(3000);

  const ncUSDC = await CustomERC20.deploy("Nexcasa USDC", "ncUSDC", 18, STABLECOIN_SUPPLY, deployer.address);
  await ncUSDC.waitForDeployment();
  console.log(`- CustomERC20 (ncUSDC) deployed to: ${await ncUSDC.getAddress()}`);
  
  console.log("\n✅ PHASE 1 COMPLETE: All tokens have been deployed.");
  console.log("➡️ ACTION: Please save all token addresses for the next steps.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });