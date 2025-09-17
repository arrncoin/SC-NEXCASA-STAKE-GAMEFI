// scripts/deployCore.js

const { ethers } = require("hardhat");

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("PHASE 2: Deploying core game contracts with the account:", deployer.address);
    
    // 1. Deploy NexCasaNFT
    console.log("\nDeploying NexCasaNFT...");
    const NexCasaNFT = await ethers.getContractFactory("NexCasaNFT");
    const nft = await NexCasaNFT.deploy();
    await nft.waitForDeployment();
    console.log(`- NexCasaNFT deployed to: ${await nft.getAddress()}`);

    console.log("Waiting 3 seconds...");
    await wait(3000);

    // 2. Deploy NexCasaGameStaking
    console.log("\nDeploying NexCasaGameStaking...");
    const NexCasaGameStaking = await ethers.getContractFactory("NexCasaGameStaking");
    const gameStaking = await NexCasaGameStaking.deploy();
    await gameStaking.waitForDeployment();
    console.log(`- NexCasaGameStaking deployed to: ${await gameStaking.getAddress()}`);

    console.log("Waiting 3 seconds...");
    await wait(3000);

    // 3. Deploy NexCasaNFTStaking
    console.log("\nDeploying NexCasaNFTStaking...");
    const NexCasaNFTStaking = await ethers.getContractFactory("NexCasaNFTStaking");
    const nftStaking = await NexCasaNFTStaking.deploy();
    await nftStaking.waitForDeployment();
    console.log(`- NexCasaNFTStaking deployed to: ${await nftStaking.getAddress()}`);

    console.log("\n✅ PHASE 2 COMPLETE: All core contracts have been deployed.");
    console.log("➡️ ACTION: Please save these 3 addresses. They are needed for configuration.");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});