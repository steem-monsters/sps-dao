// Import ethers from Hardhat package
const { ethers } = require("hardhat");

async function main() {
    // Compile your contract (Hardhat automatically compiles all contracts in the 'contracts' folder)
    console.log("Compiling contracts...");

    // Get the Contract Factory
    const SPSv2 = await ethers.getContractFactory("SPS");

    // Deploy the Contract
    console.log("Deploying SPSv2...");
    const spsV2 = await SPSv2.deploy(); // Add constructor arguments inside deploy() if your contract requires them

    // Wait for the contract to be deployed
    await spsV2.waitForDeployment();

    // Log the newly deployed contract address
    console.log("SPSv2 deployed to:",await spsV2.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
