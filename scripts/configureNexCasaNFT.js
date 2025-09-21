// scripts/configureNexCasaNFT.js
const { ethers } = require("hardhat");

// === Helper delay ===
function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  // === Alamat Kontrak ===
  const NFT_ADDRESS = "0x62a647527683824615fc2493059683E44E0A6b1f"; 
  const GAME_STAKING_ADDRESS = "0xF0C30aA46e3214D639DedBdAb69b6737fEDb47ba";
  const NEXCASA_TOKEN = "0x9049aab30D49bA7036dA27FA3FC18375b6341b45";

  const nft = await ethers.getContractAt("NexCasaNFT", NFT_ADDRESS);
  const [deployer] = await ethers.getSigners();

  // Minimal ERC20 ABI
  const ERC20_ABI = [
    "function transfer(address to, uint256 amount) external returns (bool)"
  ];
  const nexCasaToken = new ethers.Contract(NEXCASA_TOKEN, ERC20_ABI, deployer);

  // === 1. Set staking contract ===
  console.log("Setting staking contract...");
  const tx = await nft.setStakingContract(GAME_STAKING_ADDRESS);
  await tx.wait();
  console.log(`✅ Staking contract set to ${GAME_STAKING_ADDRESS}`);
  await delay(1000); // jeda 1 detik

  // === 2. Set reward per tier (redemption) ===
  const REWARDS = {
    1: 1,
    2: 5,
    3: 10,
    4: 20,
    5: 30,
    6: 40,
    7: 50,
    8: 70,
    9: 100,
  };

  for (let tier = 1; tier <= 9; tier++) {
    console.log(`Setting redemption for Tier ${tier}...`);
    const tx2 = await nft.setRedemptionData(
      tier,
      NEXCASA_TOKEN,
      ethers.parseUnits(REWARDS[tier].toString(), 18)
    );
    await tx2.wait();
    console.log(`✅ Redemption set for Tier ${tier}: ${REWARDS[tier]} NEXCASA`);
    await delay(1000); // jeda 1 detik antar transaksi
  }

  // === 3. Kirim saldo 500k NEXCASA ke kontrak NFT ===
  const amount = "500000";
  console.log(`Transferring ${amount} NEXCASA to NFT contract...`);

  const tx3 = await nexCasaToken.transfer(
    NFT_ADDRESS,
    ethers.parseUnits(amount, 18)
  );
  await tx3.wait();
  console.log(`✅ Sent ${amount} NEXCASA to ${NFT_ADDRESS}`);

  console.log("🎉 NexCasaNFT configuration completed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
