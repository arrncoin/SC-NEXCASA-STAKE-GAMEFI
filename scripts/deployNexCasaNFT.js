const hre = require("hardhat");

async function main() {
  const baseTokenURI = "https://red-military-crocodile-811.mypinata.cloud/ipfs/bafybeiamra3vle7uydjth5kqoeostwukmucxaqzah55jkuee5rcooqtbki/";

  const NexCasaNFT = await hre.ethers.getContractFactory("NexCasaNFT");
  
  console.log("Deploying NexCasaNFT...");
  
  const nexCasaNFT = await NexCasaNFT.deploy(baseTokenURI);
  
  // Menggunakan waitForDeployment() sebagai pengganti .deployed()
  await nexCasaNFT.waitForDeployment();
  
  // Mengambil alamat kontrak setelah deployment
  const contractAddress = await nexCasaNFT.getAddress();
  
  console.log("NexCasaNFT deployed to:", contractAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });