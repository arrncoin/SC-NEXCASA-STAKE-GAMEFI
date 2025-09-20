// scripts/configureNftStaking.js

const { ethers } = require("hardhat");

async function main() {
  // === Alamat Kontrak ===
  const STAKING_ADDRESS = "0x60Edf6DF345cCE085839AC42c66DAa8c26e019FB"; // NexCasaNFTStaking
  const NFT_ADDRESS = "0x9C8EFe16f1C7Db0522fA886227bf6f2723a93564"; // NexCasaNFT
  const REWARD_TOKEN = "0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB"; // NEXCASA ERC20

  // === Helper: hitung reward per hari ke per detik ===
  function rewardPerDay(amountPerDay) {
    // konversi jumlah token per hari -> wei, lalu bagi jumlah detik (86400)
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

  // === Set reward per tier ===
  for (let tier = 1; tier <= 9; tier++) {
    console.log(`🔧 Setting reward rate for Tier ${tier}...`);
    tx = await staking.setTierRewardRate(tier, REWARDS[tier]);
    await tx.wait();
    console.log(
      `✅ Tier ${tier} set: ${REWARDS[tier].toString()} wei/sec`
    );
  }

  // === Opsional: Kirim token reward ke staking contract ===
  const rewardToken = await ethers.getContractAt("IERC20", REWARD_TOKEN);
  const amount = ethers.parseUnits("5000000", 18); // 5M NEXCASA
  console.log(`🔧 Transferring ${amount} NEXCASA to staking contract...`);
  tx = await rewardToken.transfer(STAKING_ADDRESS, amount);
  await tx.wait();
  console.log("✅ Reward tokens funded!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
