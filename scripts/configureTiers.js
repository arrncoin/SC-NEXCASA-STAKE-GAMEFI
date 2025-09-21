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
    const GAME_ADDRESS = "0xF0C30aA46e3214D639DedBdAb69b6737fEDb47ba";

    // === Token addresses ===
    const TOKENS = {
        NEX: ethers.ZeroAddress, // native token
        ncBTC: "0x447335Aa2D62bB917082b3833e56b416e78Ba43c",
        ncETH: "0x3eC1E7ab0328606Bbb0AeDa392979072c830963f",
        ncUSDT: "0x1DDDc56ccd817A0001352A6474255fF9B3DA1713",
        ncUSDC: "0x9E7DD26455cc34Aa538e6C8F970df854f14e3B35",
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
    const staking = await ethers.getContractAt("NexCasaGame", GAME_ADDRESS);

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

        // Set lockup in minutes
        const lockupMin = LOCKUP_MINUTES[tier - 1];
        const txLock = await staking.setTierLockup(tier, lockupMin);
        await txLock.wait();
        await delay(1000);
        console.log(`Tier ${tier} lockup set: ${lockupMin} menit`);
    }

    // === 3. Transfer reward token to staking contract ===
    const REWARD_TOKEN = "0x9049aab30D49bA7036dA27FA3FC18375b6341b45";
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
