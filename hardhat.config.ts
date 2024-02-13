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
      url: "https://sepolia-rollup.arbitrum.io/rpc", // Replace with your RPC URL
      accounts: privateKey, // Use the private key from the environment variables, filtering out undefined or empty
      chainId: 421614, // Arbitrum Arbitrum Sepolia chain ID
    },
    optimismSepolia: {
      url: "https://sepolia.optimism.io", // Verify this RPC URL
      accounts: privateKey,
      chainId: 11155420, // Verify this chain ID
    },
  },
};

export default config;
