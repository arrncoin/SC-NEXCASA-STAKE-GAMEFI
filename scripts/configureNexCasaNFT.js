// scripts/configureNexCasaNFT.js
const { ethers } = require("hardhat");

// === Helper delay ===
function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  // === Alamat Kontrak ===
  const NFT_ADDRESS = "0xF380E156723f8D97278f8D0317FBDceEB01d34b5"; 
  const GAME_STAKING_ADDRESS = "0x3eaed605e43dB976818831bEFfee6b10904fb747";
  const NEXCASA_TOKEN = "0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB";

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
