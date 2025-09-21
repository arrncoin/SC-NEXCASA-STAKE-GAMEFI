// scripts/configureNftStaking.js
const { ethers } = require("hardhat");

// === Helper delay ===
function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  // === Alamat Kontrak ===
  const STAKING_ADDRESS = "0x532b0D6B16A6B7352924DEfA999D901bD0Aa86Af"; // NexCasaNFTStaking
  const NFT_ADDRESS = "0x62a647527683824615fc2493059683E44E0A6b1f"; // NexCasaNFT
  const REWARD_TOKEN = "0x9049aab30D49bA7036dA27FA3FC18375b6341b45"; // NEXCASA ERC20

  // === Helper: hitung reward per hari ke per detik ===
  function rewardPerDay(amountPerDay) {
    return ethers.parseUnits(amountPerDay.toString(), 18) / 86400n;
  }

  // === Reward per Tier (token per detik) ===
  const REWARDS = {
    1: rewardPerDay(0.1),
    2: rewardPerDay(0.2),
    3: rewardPerDay(0.5),
    4: rewardPerDay(1),
    5: rewardPerDay(2),
    6: rewardPerDay(3),
    7: rewardPerDay(5),
    8: rewardPerDay(7),
    9: rewardPerDay(10),
  };

  // === Load signer & contract ===
  const [deployer] = await ethers.getSigners();
  console.log("Configuring with deployer:", deployer.address);

  const staking = await ethers.getContractAt("NexCasaNFTStaking", STAKING_ADDRESS);

  // === Set kontrak NFT & Token Reward ===
  console.log("🔧 Setting NFT & RewardToken address...");
  let tx = await staking.setContracts(NFT_ADDRESS, REWARD_TOKEN);
  await tx.wait();
  console.log("✅ Contracts set!");
  await delay(3000); // jeda 3 detik

  // === Set reward per tier ===
  for (let tier = 1; tier <= 9; tier++) {
    console.log(`🔧 Setting reward rate for Tier ${tier}...`);
    tx = await staking.setTierRewardRate(tier, REWARDS[tier]);
    await tx.wait();
    console.log(`✅ Tier ${tier} set: ${REWARDS[tier].toString()} wei/sec`);
    await delay(3000); // jeda 3 detik antar transaksi
  }

  // === Opsional: Kirim token reward ke staking contract ===
  const rewardToken = await ethers.getContractAt("IERC20", REWARD_TOKEN);
  const amount = ethers.parseUnits("500000", 18); // 500K NEXCASA
  console.log(`🔧 Transferring ${amount} NEXCASA to staking contract...`);
  tx = await rewardToken.transfer(STAKING_ADDRESS, amount);
  await tx.wait();
  console.log("✅ Reward tokens funded!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
