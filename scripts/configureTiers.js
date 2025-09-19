const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Configuring tiers with account:", deployer.address);

  // Alamat kontrak staking
  const STAKING_ADDRESS = "0x8E04B4DF3deb5A34DA4daF69C9c83a8F36073777";

  // Token addresses
  const TOKENS = {
    NEX: ethers.ZeroAddress, // native token
    ncBTC: "0xA1A5987Cc7da36f4606A2a9F00DEb66A4e37734F",
    ncETH: "0x7ceC127e4c5793BaeA2C5da5e8b6086f0D3A23f5",
    ncUSDT: "0x7729Cbf0F8745fc5698adbD5B2D27b8C3C1ab23f",
    ncUSDC: "0x1381ceB65a8e6769658e84291CF28782bE4C2668",
  };

  // Requirement tiap tier (1–9)
  const REQUIREMENTS = {
    1: { NEX: 1, ncBTC: 1, ncETH: 10, ncUSDT: 100, ncUSDC: 100, days: 1 },
    2: { NEX: 50, ncBTC: 2, ncETH: 20, ncUSDT: 200, ncUSDC: 200, days: 5 },
    3: { NEX: 100, ncBTC: 3, ncETH: 30, ncUSDT: 300, ncUSDC: 300, days: 7 },
    4: { NEX: 200, ncBTC: 4, ncETH: 40, ncUSDT: 500, ncUSDC: 500, days: 10 },
    5: { NEX: 400, ncBTC: 5, ncETH: 50, ncUSDT: 1000, ncUSDC: 1000, days: 12 },
    6: { NEX: 600, ncBTC: 6, ncETH: 60, ncUSDT: 2000, ncUSDC: 2000, days: 15 },
    7: { NEX: 800, ncBTC: 7, ncETH: 70, ncUSDT: 4000, ncUSDC: 4000, days: 20 },
    8: { NEX: 1000, ncBTC: 8, ncETH: 80, ncUSDT: 6000, ncUSDC: 6000, days: 25 },
    9: { NEX: 1500, ncBTC: 10, ncETH: 100, ncUSDT: 10000, ncUSDC: 10000, days: 30 },
  };

  const staking = await ethers.getContractAt("NexCasaGameStaking", STAKING_ADDRESS);

  // 1. Whitelist all tokens
  for (const token of Object.values(TOKENS)) {
    let tx = await staking.setWhitelistToken(token, true);
    await tx.wait();
    console.log(`Whitelisted token: ${token}`);
  }

  // 2. Set requirements tier by tier
  for (let tier = 1; tier <= 9; tier++) {
    const req = REQUIREMENTS[tier];

    for (const [tokenName, amount] of Object.entries(req)) {
      if (tokenName === "days") continue;
      const tokenAddr = TOKENS[tokenName];

      // Add to tier check list
      let tx1 = await staking.addTokenToTierCheckList(tier, tokenAddr);
      await tx1.wait();

      // Set requirement
      let tx2 = await staking.setTierRequirement(tier, tokenAddr, ethers.parseUnits(amount.toString(), 18));
      await tx2.wait();

      console.log(`Tier ${tier} requirement set: ${amount} ${tokenName}`);
    }

    // Set lockup days
    let tx3 = await staking.setTierLockup(tier, req.days);
    await tx3.wait();
    console.log(`Tier ${tier} lockup set: ${req.days} days`);
  }

  console.log("✅ All tiers configured successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
