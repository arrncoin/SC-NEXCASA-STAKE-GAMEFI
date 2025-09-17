const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const [user] = await ethers.getSigners();
  console.log("User address:", user.address);

  const faucetAddress = "0xB869a63edd8e32EA93236eF352D728Dc0693Ce0B";
  const Faucet = await ethers.getContractFactory("TokenFaucet");
  const faucet = Faucet.attach(faucetAddress);

  const tokens = {
    BTC: "0xb22D3576a9Ac7D7cE0857d55E1398Cc83d355bd8",
    ETH: "0x9598BEf95623578B00FA75f3E1501CcFB245663b",
    USDT: "0xD8DC1E7bad9aa61f40De50918eBF08523b1d8f2f",
    USDC: "0x58AB76fA3A0da7116C17b5e5a5c0f69Bd1049BB1"
  };

  const CustomERC20 = await ethers.getContractFactory("CustomERC20");

  for (const [name, addr] of Object.entries(tokens)) {
    console.log(`Claiming ${name}...`);
    const tx = await faucet.connect(user).claim(addr);
    await tx.wait();

    const token = CustomERC20.attach(addr);
    const balance = await token.balanceOf(user.address);
    console.log(`${name} balance after claim:`, ethers.formatUnits(balance, 18));
  }

  console.log("✅ All tokens claimed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
