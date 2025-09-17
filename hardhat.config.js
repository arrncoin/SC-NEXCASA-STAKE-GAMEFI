require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

module.exports = {
  solidity: "0.8.22",
  networks: {
    nexus: {
      url: "https://nexus-testnet.g.alchemy.com/public",
      chainId: 3940,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: {
      nexus: ETHERSCAN_API_KEY,
    },
    customChains: [
      {
        network: "nexus",
        chainId: 3940,
        urls: {
          apiURL: "https://testnet3.explorer.nexus.xyz/api",
          browserURL: "https://testnet3.explorer.nexus.xyz",
        },
      },
    ],
  },
};
