### Functions to Test

#### 1. Minting (`mint`)
- **Purpose**: Ensure only accounts with the `MINTER_ROLE` can mint new tokens and that the minting process correctly increases the total supply and the recipient's balance.
- **Test Approach**: Attempt minting from accounts both with and without the `MINTER_ROLE`. Verify the total supply and recipient balance before and after minting.

#### 2. Burning (`burn`)
- **Purpose**: Verify that token holders can burn their tokens, reducing the total supply appropriately.
- **Test Approach**: Burn a specific amount of tokens from a holder's balance and check the total supply and holder's balance for the expected decrease.

#### 3. Delegating Voting Power (`delegate`)
- **Purpose**: Ensure that a token holder can delegate their voting power to another account.
- **Test Approach**: Delegate voting power and verify that the delegatee's voting power increases accordingly.

#### 4. Signature-Based Delegation (`delegateBySig`)
- **Purpose**: Validate that voting power can be delegated through an off-chain signature, allowing for gasless delegation.
- **Test Approach**: Generate a valid signature for delegation and use it to delegate voting power, then verify the delegatee’s increased voting power.

#### 5. Role Management (`grantRole`, `revokeRole`, `renounceRole`)
- **Purpose**: Ensure that role management functions behave as expected, with roles being grantable, revocable, and renounceable under the right conditions.
- **Test Approach**: Test granting and revoking of roles by authorized accounts, and ensure accounts can renounce roles they possess.

### How to Test Using Hardhat and TypeScript

1. **Setup Hardhat Project**: Ensure your Hardhat environment is set up to compile Solidity contracts and run TypeScript tests. This includes installing `typescript`, `ts-node`, `@types/node`, `@types/mocha`, and `@types/chai`.

2. **Write Test Scripts**:
   - Create a new TypeScript test file in the `test` directory.
   - Use `ethers` provided by Hardhat to interact with the deployed contract instances in your tests.
   - Utilize `chai` for assertions.

3. **Running Tests**:
   - Compile your contracts with `npx hardhat compile`.
   - Run your TypeScript tests using `npx hardhat test`.