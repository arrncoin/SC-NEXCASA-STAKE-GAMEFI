// scripts/configureNftStaking.js
const { ethers } = require("hardhat");

// === Helper delay ===
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Configuring tiers with account:", deployer.address);

    // === Alamat kontrak staking ===
    const STAKING_ADDRESS = "0x3eaed605e43dB976818831bEFfee6b10904fb747";

    // === Token addresses ===
    const TOKENS = {
        NEX: ethers.ZeroAddress, // native token
        ncBTC: "0xA1A5987Cc7da36f4606A2a9F00DEb66A4e37734F",
        ncETH: "0x7ceC127e4c5793BaeA2C5da5e8b6086f0D3A23f5",
        ncUSDT: "0x7729Cbf0F8745fc5698adbD5B2D27b8C3C1ab23f",
        ncUSDC: "0x1381ceB65a8e6769658e84291CF28782bE4C2668",
    };

    // === Requirement tiap tier (token) ===
    const REQUIREMENTS = {
        1: { NEX: 0.01, ncBTC: 1, ncETH: 10, ncUSDT: 100, ncUSDC: 100 },
        2: { NEX: 0.05, ncBTC: 2, ncETH: 20, ncUSDT: 200, ncUSDC: 200 },
        3: { NEX: 0.1, ncBTC: 3, ncETH: 30, ncUSDT: 300, ncUSDC: 300 },
        4: { NEX: 0.2, ncBTC: 4, ncETH: 40, ncUSDT: 500, ncUSDC: 500 },
        5: { NEX: 0.4, ncBTC: 5, ncETH: 50, ncUSDT: 1000, ncUSDC: 1000 },
        6: { NEX: 0.8, ncBTC: 6, ncETH: 60, ncUSDT: 2000, ncUSDC: 2000 },
        7: { NEX: 1.6, ncBTC: 7, ncETH: 70, ncUSDT: 4000, ncUSDC: 4000 },
        8: { NEX: 3.2, ncBTC: 8, ncETH: 80, ncUSDT: 6000, ncUSDC: 6000 },
        9: { NEX: 7, ncBTC: 10, ncETH: 100, ncUSDT: 10000, ncUSDC: 10000 },
    };

    // === Lockup menit tiap tier ===
    const LOCKUP_MINUTES = [5, 10, 20, 40, 80, 160, 320, 640, 1280];

    // Load staking contract
    const staking = await ethers.getContractAt("NexCasaGameStaking", STAKING_ADDRESS);

    // === 1. Whitelist all tokens ===
    for (const token of Object.values(TOKENS)) {
        const tx = await staking.setWhitelistToken(token, true);
        await tx.wait();
        console.log(`Whitelisted token: ${token}`);
        await delay(1000);
    }

    // === 2. Set requirements tier by tier ===
    for (let tier = 1; tier <= 9; tier++) {
        const req = REQUIREMENTS[tier];

        for (const [tokenName, amount] of Object.entries(req)) {
            const tokenAddr = TOKENS[tokenName];

            // Add to tier checklist
            let tx = await staking.addTokenToTierCheckList(tier, tokenAddr);
            await tx.wait();
            await delay(1000);

            // Set requirement amount (uint256)
            tx = await staking.setTierRequirement(
                tier,
                tokenAddr,
                ethers.parseUnits(amount.toString(), 18)
            );
            await tx.wait();
            await delay(1000);

            console.log(`Tier ${tier} requirement set: ${amount} ${tokenName}`);
        }

        // Set lockup in seconds
        const lockupSec = LOCKUP_MINUTES[tier - 1] * 60;
        const txLock = await staking.setTierLockup(tier, lockupSec);
        await txLock.wait();
        await delay(1000);
        console.log(`Tier ${tier} lockup set: ${LOCKUP_MINUTES[tier - 1]} menit`);
    }

    // === 3. Transfer reward token to staking contract ===
    const REWARD_TOKEN = "0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB";
    const rewardToken = await ethers.getContractAt("IERC20", REWARD_TOKEN);
    const rewardAmount = ethers.parseUnits("500000", 18); // 500K NEXCASA
    console.log(`Transferring ${rewardAmount} NEXCASA to staking contract...`);
    const txReward = await rewardToken.transfer(STAKING_ADDRESS, rewardAmount);
    await txReward.wait();
    console.log("✅ Reward tokens funded!");

    console.log("🎉 All tiers configured successfully!");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
