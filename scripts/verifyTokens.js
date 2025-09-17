// scripts/verifyTokens.js
const { run } = require("hardhat");

async function main() {
  const deployer = "0x11Cde369597203f385BC164E64E34e1F520E1983";

  // Masukkan alamat hasil deploy di sini
  const ADDRESSES = {
    NEXCASA: "0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB",
    ncBTC: "0xA1A5987Cc7da36f4606A2a9F00DEb66A4e37734F",
    ncETH: "0x7ceC127e4c5793BaeA2C5da5e8b6086f0D3A23f5",
    ncUSDT: "0x7729Cbf0F8745fc5698adbD5B2D27b8C3C1ab23f",
    ncUSDC: "0x1381ceB65a8e6769658e84291CF28782bE4C2668",
  };

  console.log("🔎 Starting verification...");

  // Verify NEXCASA
  await run("verify:verify", {
    address: ADDRESSES.NEXCASA,
    constructorArguments: [
      "250000000000000000000000000", // initialSupply
    ],
  });
  console.log("✅ Verified NEXCASA");

  // Verify ncBTC
  await run("verify:verify", {
    address: ADDRESSES.ncBTC,
    constructorArguments: [
      "Nexcasa BTC",
      "ncBTC",
      18,
      "21000000000000000000000000",
      deployer,
    ],
  });
  console.log("✅ Verified ncBTC");

  // Verify ncETH
  await run("verify:verify", {
    address: ADDRESSES.ncETH,
    constructorArguments: [
      "Nexcasa ETH",
      "ncETH",
      18,
      "120000000000000000000000000",
      deployer,
    ],
  });
  console.log("✅ Verified ncETH");

  // Verify ncUSDT
  await run("verify:verify", {
    address: ADDRESSES.ncUSDT,
    constructorArguments: [
      "Nexcasa USDT",
      "ncUSDT",
      18,
      "100000000000000000000000000000",
      deployer,
    ],
  });
  console.log("✅ Verified ncUSDT");

  // Verify ncUSDC
  await run("verify:verify", {
    address: ADDRESSES.ncUSDC,
    constructorArguments: [
      "Nexcasa USDC",
      "ncUSDC",
      18,
      "100000000000000000000000000000",
      deployer,
    ],
  });
  console.log("✅ Verified ncUSDC");

  console.log("\n🎉 All tokens verified successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
