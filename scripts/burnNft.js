const { ethers } = require("ethers");
require("dotenv").config();

const RPC_URL = process.env.RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const DEAD = "0x000000000000000000000000000000000000dEaD";

if (!RPC_URL || !PRIVATE_KEY) {
  console.error("❌ ERROR: set RPC_URL and PRIVATE_KEY in .env");
  process.exit(1);
}

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// ERC-721 minimal ABI
const ERC721_ABI = [
  "function balanceOf(address owner) view returns (uint256)",
  "function tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)",
  "function transferFrom(address from, address to, uint256 tokenId) external"
];

// Daftar kontrak NFT yang mau dibakar
const NFT_CONTRACTS = [
  "0x3Cb83A54Ef1b04F3520D6EA96c4BE41D1b0E1cC9",
  "0x5a20ADc70AaB7BfBcD04629210a885d6b79B4811",
  "0x9C8EFe16f1C7Db0522fA886227bf6f2723a93564",
  "0xBaF3a4713E4655e13850bc47948A5D04DC4d3304",
  "0xD316A5F89dcF51305dEdc5a80f07F9917D569fC9"
];

async function burnAllNfts(contractAddr) {
  const nft = new ethers.Contract(contractAddr, ERC721_ABI, wallet);
  const balance = await nft.balanceOf(wallet.address);

  if (balance === 0n) {
    console.log(`⚠️  No NFT found in contract ${contractAddr}`);
    return;
  }

  console.log(`🔥 Found ${balance} NFTs in ${contractAddr}`);

  for (let i = 0; i < Number(balance); i++) {
    const tokenId = await nft.tokenOfOwnerByIndex(wallet.address, i);
    console.log(`Burning tokenId ${tokenId} from ${contractAddr}...`);

    const tx = await nft.transferFrom(wallet.address, DEAD, tokenId);
    console.log(` -> tx sent: ${tx.hash}`);
    await tx.wait();
    console.log(` -> confirmed burn of tokenId ${tokenId}`);
  }
}

(async () => {
  console.log("Wallet:", wallet.address);

  for (const addr of NFT_CONTRACTS) {
    try {
      await burnAllNfts(addr);
    } catch (err) {
      console.error(`❌ ERROR burning NFTs in ${addr}:`, err.message);
    }
  }

  console.log("✅ Done burning NFTs.");
})();
