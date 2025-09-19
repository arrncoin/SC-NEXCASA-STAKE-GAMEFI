// scripts/configureNexCasaNFT.js
const { ethers } = require("hardhat");

async function main() {
  // === Alamat Kontrak ===
  const NFT_ADDRESS = "0x9C8EFe16f1C7Db0522fA886227bf6f2723a93564"; 
  const GAME_STAKING_ADDRESS = "0x8E04B4DF3deb5A34DA4daF69C9c83a8F36073777";
  const NEXCASA_TOKEN = "0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB";

  // === Ambil instance kontrak ===
  const nft = await ethers.getContractAt("NexCasaNFT", NFT_ADDRESS);

  // Minimal ERC20 ABI
  const ERC20_ABI = [
    "function transfer(address to, uint256 amount) external returns (bool)"
  ];
  const [deployer] = await ethers.getSigners();
  const nexCasaToken = new ethers.Contract(NEXCASA_TOKEN, ERC20_ABI, deployer);

  // === 1. Set staking contract ===
  console.log("Setting staking contract...");
  const tx = await nft.setStakingContract(GAME_STAKING_ADDRESS);
  await tx.wait();
  console.log(`✅ Staking contract set to ${GAME_STAKING_ADDRESS}`);

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
      ethers.parseUnits(REWARDS[tier].toString(), 18) // 18 desimal
    );
    await tx2.wait();
    console.log(`✅ Redemption set for Tier ${tier}: ${REWARDS[tier]} NEXCASA`);
  }

  // === 3. Kirim saldo 5M NEXCASA ke kontrak NFT ===
  const amount = "5000000";
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
