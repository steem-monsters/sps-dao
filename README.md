# Readme for Splintershards (SPS) Contract

## Introduction

The Splintershards (SPS) contract is an advanced ERC-20 token that incorporates features such as burnability, access control, and anti-reentrancy, alongside a delegation mechanism for voting power. It is built on the Ethereum blockchain utilizing OpenZeppelin's secure and community-audited contracts.

## Features

- **ERC-20 Compliance**: Fully compatible with the ERC-20 token standard, supporting standard token functions such as transfer, approve, and allowance.
- **Burnable Tokens**: Tokens can be burned, reducing the total supply and potentially increasing token value.
- **Role-Based Access Control**: Utilizes OpenZeppelin's AccessControl for flexible and secure permission management, with roles such as `ADMIN_ROLE` and `MINTER_ROLE`.
- **Non-Reentrancy**: Ensures that functions cannot be re-entered while they are still executing, preventing reentrancy attacks.
- **Delegation of Voting Power**: Token holders can delegate their voting power to other addresses, allowing for representative voting without transferring token ownership.
- **EIP-712 Compliance**: Implements EIP-712 for secure, typed structured data hashing and signing, particularly used in the delegateBySig function.

## Functionality

### Minting Tokens

- `mint(address to, uint256 amount)`: Mint new tokens to a specified address. Requires `MINTER_ROLE`.

### Burning Tokens

- Tokens can be burned by any token holder to reduce the total supply.

### Delegating Voting Power

- `delegate(address delegatee)`: Delegates the caller’s voting power to the `delegatee`.
- `delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)`: Delegates voting power via an off-chain signature, facilitating gasless transactions.

### Role Management

- `grantRole(bytes32 role, address account)`: Grants a role to an account. Can only be called by accounts with the admin role for the given role.
- `revokeRole(bytes32 role, address account)`: Revokes a role from an account. Can only be called by accounts with the admin role for the given role.
- `renounceRole(bytes32 role, address account)`: An account can renounce a role it has, removing any permissions associated with it.

## Development and Deployment

### Prerequisites

- Typescript is installed.
- Node.js and npm installed (Node Version 18.16.0).
- An Ethereum wallet with Ether for deploying the contract.
- This project supports Node Version Manager (NVM)

### Setup

1. **Initialize your project**:

```bash
npm init -y
```

2. **Install Hardhat**:

```bash
npm install --save-dev hardhat
```

3. **Set up Hardhat**:

Run the following command and follow the prompts to create a Hardhat project:

```bash
npx hardhat init
```

4. **Install OpenZeppelin Contracts**:

```bash
npm install @openzeppelin/contracts
```

5. **Configure Hardhat**:

Edit your `hardhat.config.js` to include network configurations for deployment, specifying your Ethereum node URL and account private key.

### Writing the Contract

Create a new Solidity file under the `contracts` directory and implement the SPS contract using the provided functionality and imports.

### Compiling the Contract

Compile your contract with Hardhat:

```bash
npx hardhat compile
```

### Deploying the Contract

Create a deployment script under the `scripts` directory, then deploy your contract using Hardhat:

```bash
npx hardhat run scripts/deploy.js --network <networkName>
```

### Verifying the Contract

After deployment, you may want to verify your contract on Etherscan:

1. Install the Hardhat Etherscan plugin:

```bash
npm install --save-dev @nomiclabs/hardhat-etherscan
```

2. Add the plugin to your `hardhat.config.js` and configure your Etherscan API key.

3. Run the verify command:

```bash
npx hardhat verify --network <networkName> <contractAddress> "Constructor argument 1"
```