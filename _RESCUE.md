Below is a markdown-formatted document, `RESCUE.md`, aimed at providing comprehensive guidance on using the rescue functions implemented in the Splintershards (SPS) Token Contract. These functions are designed to allow the contract's admin to recover ETH or ERC20 tokens that have been sent to the contract accidentally.

---

# Rescue Functionality in Splintershards (SPS) Token Contract

The Splintershards (SPS) Token Contract includes crucial functionalities for rescuing ETH and ERC20 tokens: `rescueETH` and `rescueERC20`. These functions are designed to address the common problem of tokens or Ether being mistakenly sent to smart contracts. This document details the purpose, usage, and security considerations associated with these rescue functions.

## Overview

Smart contracts often hold or manage assets, making them potential recipients of mistaken transfers. The rescue functions provide a mechanism for the contract's administrators to recover and return these assets, ensuring they are not permanently lost.

## Functions

### `rescueETH`

#### Purpose

Allows the contract's admin to transfer Ether (ETH) mistakenly sent to the contract to a specified address.

#### Usage

```solidity
function rescueETH(address payable to) external onlyRole(ADMIN_ROLE);
```

- `to`: The address to which the rescued ETH should be sent.

#### Security Features

- **Admin-Only Access**: Restricted to the contract's admin, preventing unauthorized use.
- **Non-Zero Target Address**: Ensures that the ETH is not sent to the zero address.

### Steps to Rescue ETH

1. **Verify Balance**: Ensure that the contract indeed has ETH to be rescued.
2. **Identify Recipient**: Determine the correct address to receive the rescued ETH.
3. **Execute Rescue**: Call `rescueETH`, passing in the recipient's address.

### `rescueERC20`

#### Purpose

Enables the contract's admin to recover ERC20 tokens that were sent to the contract by mistake and send them to a specified address.

#### Usage

```solidity
function rescueERC20(address tokenAddress, address to, uint256 amount) external onlyRole(ADMIN_ROLE);
```

- `tokenAddress`: The contract address of the ERC20 token to be rescued.
- `to`: The address to receive the rescued tokens.
- `amount`: The amount of tokens to be rescued.

#### Security Features

- **Admin-Only Access**: Limits function access to the contract's admin.
- **Validations**: Checks for non-zero target address, positive amount, and sufficient token balance before proceeding.

### Steps to Rescue ERC20 Tokens

1. **Confirm Token and Amount**: Verify the contract address of the ERC20 tokens and the amount mistakenly sent to the contract.
2. **Determine Recipient**: Choose the correct address to which the tokens should be returned.
3. **Perform Rescue**: Execute the `rescueERC20` function with the token's contract address, recipient's address, and the amount to be rescued.

## Security Considerations

- **Admin Role Management**: Ensure that the `ADMIN_ROLE` is securely managed and assigned to trustworthy entities.
- **Transaction Review**: Double-check addresses and amounts before executing rescue operations to prevent errors.
- **Transparency**: Communicate rescue operations to stakeholders, maintaining transparency regarding asset management.

## Conclusion

The `rescueETH` and `rescueERC20` functions in the SPS Token Contract are essential tools for managing the contract's assets responsibly. They provide a safety net for recovering assets sent to the contract in error, reflecting a commitment to asset security and user protection.

---