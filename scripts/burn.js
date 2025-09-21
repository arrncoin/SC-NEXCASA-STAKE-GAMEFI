const fs = require('fs/promises');
const { ethers } = require('ethers');
require('dotenv').config();

const RPC_URL = process.env.RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const DEAD = '0x000000000000000000000000000000000000dEaD';
const SEND_NATIVE = (process.env.SEND_NATIVE || 'false').toLowerCase() === 'true';
const NATIVE_GAS_RESERVE = process.env.NATIVE_GAS_RESERVE ? Number(process.env.NATIVE_GAS_RESERVE) : 0.01;

if (!RPC_URL || !PRIVATE_KEY) {
  console.error('ERROR: set RPC_URL and PRIVATE_KEY in .env');
  process.exit(1);
}

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// ERC-20 minimal ABI we need
const ERC20_ABI = [
  'function decimals() view returns (uint8)',
  'function balanceOf(address owner) view returns (uint256)',
  'function symbol() view returns (string)',
  'function name() view returns (string)',
  'function transfer(address to, uint256 amount) returns (bool)'
];

async function loadTokens() {
  try {
    const j = await fs.readFile('./tokens.json', 'utf8');
    const parsed = JSON.parse(j);
    if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    return parsed.tokens || [];
  } catch (e) {
    return [
      '0xA295fa6B4Ea9a3F10dec41fe19f2899a4A5Eed58',
      '0xe9e928D92c92473cfC83F13F4E512ff44da35BA8',
      '0x799ad7aab2B911B0284564C7C5928e1eB3Ea6293',
      '0x7729Cbf0F8745fc5698adbD5B2D27b8C3C1ab23f',
      '0x1381ceB65a8e6769658e84291CF28782bE4C2668',
      '0x9FB8788E20650F1dF3Bf0BdBCfC0E5E7C950Ca2C',
      '0xf7E8cB3378331813A5fAbf52Df66C139a4E059DE',
      '0x447d7A2F91C01b83c952EcBbbC25248931b42fe5',
      '0x9DEcc091848473241d5B54F3750f7FeE79673f16',
      '0x96F24867317C1B26f9cE317EC408Dd0c20dE9231',
      '0x8C08407FF07017b02C768F6D3ff71f564e893cbe',
      '0xE50A38010e523A6a557DBA15Cc1fe0b8ab0cA32c',
      '0xa09B15252831D47cF85c159bC72cfC45F0D1bBEB',
      '0x1c57E6354Da95a29a2fbbea8458F7EE358d14A35',
      '0xAE6c9e00EDf41F5795b6B799Af6319606a824520',
      '0xfbf32141b5b1131ABc316408DEb7e582C32434A6',
      '0xD115121Be188cA6A6d32Df0ACFeDf22d91e9ceE6',
      '0x7ceC127e4c5793BaeA2C5da5e8b6086f0D3A23f5',
      '0x502ae93a5711951c51FcfC3be20c912bf963DC54',
      '0xF65a661Bd74F211C14454A3Ce154390a4c519978',
      '0xF98B042d068F48A60De2B91bDdc77A692f7648b6',
      '0xA1A5987Cc7da36f4606A2a9F00DEb66A4e37734F',
      '0x58AB76fA3A0da7116C17b5e5a5c0f69Bd1049BB1',
      '0xD8DC1E7bad9aa61f40De50918eBF08523b1d8f2f',
      '0x9598BEf95623578B00FA75f3E1501CcFB245663b',
      '0xb22D3576a9Ac7D7cE0857d55E1398Cc83d355bd8',
      '0xC17E95500e6556b8240b5C9528c7BF007c5562Ce',
      '0x029faDB2A93616462d6b2436b9fC59531CA9b116',
      '0x51EC4CA0a1013F2c72763f3dD6048AB5233583f4',
      '0xF30FFbeFBfEdc5a60A50FA31e9A473EB75e3e629',
      '0x1afb2896D6496B4b869B15aC81526d8819d310d3',
      '0x4D6032650dd75B8c3cB04E104CD31f6753989609',
    ];
  }
}

async function sendAllTokenToDead(tokenAddress) {
  try {
    const token = new ethers.Contract(tokenAddress, ERC20_ABI, wallet);
    const [decimals, rawBal, symbol] = await Promise.all([
      token.decimals().catch(() => 18),
      token.balanceOf(wallet.address),
      token.symbol().catch(() => '')
    ]);

    if (rawBal === 0n) {
      console.log(`SKIP ${symbol || tokenAddress} (${tokenAddress}) — balance 0`);
      return;
    }

    const balance = ethers.formatUnits(rawBal, decimals);
    const humanSymbol = symbol || tokenAddress;

    console.log(`SENDING ${balance} ${humanSymbol} (${tokenAddress}) to ${DEAD} ...`);
    const tx = await token.transfer(DEAD, rawBal);
    console.log(` -> tx sent: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(` -> confirmed (${receipt.blockNumber})`);
  } catch (err) {
    console.error(`ERROR for token ${tokenAddress}:`, (err && err.message) || err);
  }
}

async function sendNativeBalanceToDead() {
  try {
    const balanceRaw = await provider.getBalance(wallet.address);
    const balance = Number(ethers.formatEther(balanceRaw));
    if (balance <= NATIVE_GAS_RESERVE) {
      console.log(`SKIP native — balance ${balance} ≤ gas reserve ${NATIVE_GAS_RESERVE}`);
      return;
    }
    const amountToSend = balance - NATIVE_GAS_RESERVE;
    const value = ethers.parseEther(String(amountToSend));
    console.log(`SENDING native ${amountToSend} ETH -> ${DEAD} ...`);
    const tx = await wallet.sendTransaction({ to: DEAD, value });
    console.log(` -> tx sent: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(` -> confirmed (${receipt.blockNumber})`);
  } catch (err) {
    console.error('ERROR sending native:', (err && err.message) || err);
  }
}

(async () => {
  console.log('Address:', wallet.address);
  const tokens = await loadTokens();
  if (!tokens || tokens.length === 0) {
    console.log('No tokens found in tokens.json. Add token addresses to tokens.json (array). Exiting.');
    process.exit(0);
  }

  for (const t of tokens) {
    const tokenAddr = String(t).trim();
    if (!tokenAddr) continue;
    await sendAllTokenToDead(tokenAddr);
  }

  if (SEND_NATIVE) {
    await sendNativeBalanceToDead();
  }

  console.log('Done.');
})();