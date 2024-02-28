import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@typechain/hardhat";
import * as dotenv from 'dotenv';

dotenv.config();
const privateKey = process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [];

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
      },
      {
        version: "0.8.20",
      }
    ],
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v6",
  },
  networks: {
    arbitrumSepolia: {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      accounts: privateKey,
      chainId: 421614,
    },
    optimismSepolia: {
      url: "https://sepolia.optimism.io",
      accounts: privateKey,
      chainId: 11155420,
    },
    polygonGoerli: {
      url: "https://matic-testnet-archive-rpc.bwarelabs.com", // This is an example; please use an up-to-date RPC URL
      accounts: privateKey,
      chainId: 80001, // Chain ID for Polygon Mumbai (Goerli) Testnet
    },
    avalancheFuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc", // This is an example; please use an up-to-date RPC URL
      accounts: privateKey,
      chainId: 43113, // Chain ID for Avalanche Fuji Testnet
    },
    bnbTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545", // This is an example; please use an up-to-date RPC URL
      accounts: privateKey,
      chainId: 97, // Chain ID for BNB Chain Testnet
    },
    goerli: {
      url: "https://goerli.infura.io/v3/yourInfuraProjectId", // Replace with your Infura Project ID
      accounts: privateKey,
      chainId: 5, // Chain ID for Ethereum Goerli Testnet
    },
  },
};

export default config;
