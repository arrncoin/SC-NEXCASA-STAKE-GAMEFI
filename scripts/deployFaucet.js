// scripts/deployFaucet.js

const { ethers } = require("hardhat");

// !!! PASTE 5 ALAMAT TOKEN DARI FASE 1 DI SINI !!!
const NC_BTC_ADDRESS  = "0x447335Aa2D62bB917082b3833e56b416e78Ba43c";
const NC_ETH_ADDRESS  = "0x3eC1E7ab0328606Bbb0AeDa392979072c830963f";
const NC_USDT_ADDRESS = "0x1DDDc56ccd817A0001352A6474255fF9B3DA1713";
const NC_USDC_ADDRESS = "0x9E7DD26455cc34Aa538e6C8F970df854f14e3B35";
// !!! --------------------------------------------- !!!

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("PHASE 3: Deploying updated Faucet with account:", deployer.address);

  // 1. Deploy Faucet dengan constructor baru
  console.log("\nDeploying Faucet...");
  const NexCasaFaucet = await ethers.getContractFactory("NexCasaFaucet");
  // Kirim alamat deployer sebagai initialOwner
  const faucet = await NexCasaFaucet.deploy(deployer.address);
  await faucet.waitForDeployment();
  const faucetAddress = await faucet.getAddress();
  console.log(`- NexCasaFaucet deployed to: ${faucetAddress}`);

  // 2. Dapatkan instance dari kontrak token yang sudah ada
  console.log("\nAttaching to existing token contracts...");
  const ncBTC = await ethers.getContractAt("CustomERC20", NC_BTC_ADDRESS);
  const ncETH = await ethers.getContractAt("CustomERC20", NC_ETH_ADDRESS);
  const ncUSDT = await ethers.getContractAt("CustomERC20", NC_USDT_ADDRESS);
  const ncUSDC = await ethers.getContractAt("CustomERC20", NC_USDC_ADDRESS);
  console.log("- Token instances attached.");

  // 3. Mendanai Faucet
  console.log("\nFunding the Faucet with tokens...");
  await (await ncBTC.transfer(faucetAddress, ethers.parseUnits("10000", 18))).wait();
  await (await ncETH.transfer(faucetAddress, ethers.parseUnits("100000", 18))).wait();
  await (await ncUSDT.transfer(faucetAddress, ethers.parseUnits("10000000", 18))).wait();
  await (await ncUSDC.transfer(faucetAddress, ethers.parseUnits("10000000", 18))).wait();
  console.log("- Faucet has been funded.");

  // 4. Konfigurasi setiap token menggunakan setTokenConfig
  console.log("\nConfiguring Faucet for each token...");
  const cooldown24h = 86400; // 24 jam dalam detik

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