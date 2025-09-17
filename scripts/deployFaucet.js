// scripts/deployFaucet.js

const { ethers } = require("hardhat");

// !!! PASTE 5 ALAMAT TOKEN DARI FASE 1 DI SINI !!!
// const NEXCASA_ADDRESS = "0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB";
const NC_BTC_ADDRESS  = "0xA1A5987Cc7da36f4606A2a9F00DEb66A4e37734F";
const NC_ETH_ADDRESS  = "0x7ceC127e4c5793BaeA2C5da5e8b6086f0D3A23f5";
const NC_USDT_ADDRESS = "0x7729Cbf0F8745fc5698adbD5B2D27b8C3C1ab23f";
const NC_USDC_ADDRESS = "0x1381ceB65a8e6769658e84291CF28782bE4C2668";
// !!! --------------------------------------------- !!!

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("PHASE 3: Deploying updated Faucet with account:", deployer.address);

  // 1. Deploy Faucet dengan constructor baru
  console.log("\nDeploying Faucet...");
  const TokenFaucet = await ethers.getContractFactory("TokenFaucet");
  // Kirim alamat deployer sebagai initialOwner
  const faucet = await TokenFaucet.deploy(deployer.address);
  await faucet.waitForDeployment();
  const faucetAddress = await faucet.getAddress();
  console.log(`- TokenFaucet deployed to: ${faucetAddress}`);

  // 2. Dapatkan instance dari kontrak token yang sudah ada
  console.log("\nAttaching to existing token contracts...");
  // const nexcasaToken = await ethers.getContractAt("NexcasaToken", NEXCASA_ADDRESS);
  const ncBTC = await ethers.getContractAt("CustomERC20", NC_BTC_ADDRESS);
  const ncETH = await ethers.getContractAt("CustomERC20", NC_ETH_ADDRESS);
  const ncUSDT = await ethers.getContractAt("CustomERC20", NC_USDT_ADDRESS);
  const ncUSDC = await ethers.getContractAt("CustomERC20", NC_USDC_ADDRESS);
  console.log("- Token instances attached.");

  // 3. Mendanai Faucet
  console.log("\nFunding the Faucet with tokens...");
  // await (await nexcasaToken.transfer(faucetAddress, ethers.parseUnits("10000000", 18))).wait();
  await (await ncBTC.transfer(faucetAddress, ethers.parseUnits("1000", 18))).wait();
  await (await ncETH.transfer(faucetAddress, ethers.parseUnits("10000", 18))).wait();
  await (await ncUSDT.transfer(faucetAddress, ethers.parseUnits("1000000", 18))).wait();
  await (await ncUSDC.transfer(faucetAddress, ethers.parseUnits("1000000", 18))).wait();
  console.log("- Faucet has been funded.");

  // 4. Konfigurasi setiap token menggunakan setTokenConfig
  console.log("\nConfiguring Faucet for each token...");
  const cooldown24h = 86400; // 24 jam dalam detik

  // Konfigurasi NEXCASA
  /* let dripAmount = ethers.parseUnits("1000", 18);
  await (await faucet.setTokenConfig(NEXCASA_ADDRESS, dripAmount, cooldown24h, true)).wait();
  console.log("- $NEXCASA configured."); */

  // Konfigurasi ncBTC
  dripAmount = ethers.parseUnits("0.01", 8);
  await (await faucet.setTokenConfig(NC_BTC_ADDRESS, dripAmount, cooldown24h, true)).wait();
  console.log("- ncBTC configured.");

  // Konfigurasi ncETH
  dripAmount = ethers.parseUnits("0.1", 18);
  await (await faucet.setTokenConfig(NC_ETH_ADDRESS, dripAmount, cooldown24h, true)).wait();
  console.log("- ncETH configured.");

  // Konfigurasi ncUSDT
  dripAmount = ethers.parseUnits("1000", 6);
  await (await faucet.setTokenConfig(NC_USDT_ADDRESS, dripAmount, cooldown24h, true)).wait();
  console.log("- ncUSDT configured.");
  
  // Konfigurasi ncUSDC
  dripAmount = ethers.parseUnits("1000", 6);
  await (await faucet.setTokenConfig(NC_USDC_ADDRESS, dripAmount, cooldown24h, true)).wait();
  console.log("- ncUSDC configured.");

  console.log("\n✅ PHASE 3 COMPLETE: The new Faucet is deployed, funded, and fully configured.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});