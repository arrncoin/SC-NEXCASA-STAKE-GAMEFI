const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Minting tokens with deployer:", deployer.address);

  // Alamat kontrak token dan faucet
  const tokens = {
    BTC: "0xb22D3576a9Ac7D7cE0857d55E1398Cc83d355bd8",
    ETH: "0x9598BEf95623578B00FA75f3E1501CcFB245663b",
    USDT: "0xD8DC1E7bad9aa61f40De50918eBF08523b1d8f2f",
    USDC: "0x58AB76fA3A0da7116C17b5e5a5c0f69Bd1049BB1"
  };

  const faucetAddress = "0xB869a63edd8e32EA93236eF352D728Dc0693Ce0B";

  // Jumlah mint: 10_000_000 * 10^18
  const mintAmount = ethers.parseUnits("10000000", 18);

  const CustomERC20 = await ethers.getContractFactory("CustomERC20");

  for (const [name, addr] of Object.entries(tokens)) {
    const token = CustomERC20.attach(addr);
    console.log(`Minting ${mintAmount} ${name} to Faucet...`);
    const tx = await token.mint(faucetAddress, mintAmount);
    await tx.wait();
    console.log(`${name} minted to Faucet!`);
  }

  console.log("✅ All tokens minted and transferred to Faucet successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
