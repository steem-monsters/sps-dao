import { ethers, waffle } from "hardhat";
import { expect } from "chai";
import { SPS } from "../typechain"; // Adjust the import path based on your Hardhat setup

describe("SPS Contract", function () {
  let sps: SPS;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let recipient: SignerWithAddress;
  let accounts: SignerWithAddress[];

  const initialSupply = ethers.utils.parseUnits("1000", 18);

  /**
   * The beforeEach hook is used to perform setup actions before each test case in this suite runs. 
   * It asynchronously prepares the testing environment for the SPS contract by performing several key actions:
   * 
   * 1. It fetches a list of signers from the Ethereum provider, which represent different accounts in the test environment. 
   *    These signers include the `owner`, `minter`, `recipient`, and other accounts, which are used to simulate interactions 
   *    with the SPS contract from different perspectives.
   * 
   * 2. It deploys a new instance of the SPS contract to the test blockchain. This involves first getting the contract factory 
   *    associated with the SPS contract, using the `owner` account as the deployer, and then calling the `deploy` method. 
   *    This step ensures that a fresh instance of the contract is used for each test, preventing state leakage between tests.
   * 
   * 3. It assigns the `MINTER_ROLE` to the `minter` account, enabling it to mint new tokens. This is crucial for testing 
   *    the contract's minting functionality under controlled permissions.
   * 
   * By doing these steps, the hook sets up a common starting point for each test, ensuring that tests are isolated 
   * and have access to a correctly configured instance of the SPS contract and relevant Ethereum accounts.
   */

  beforeEach(async function () {
    // Get signers
    [owner, minter, recipient, ...accounts] = await ethers.getSigners();

    // Deploy the contract
    const SPSFactory = await ethers.getContractFactory("SPS", owner);
    sps = (await SPSFactory.deploy()) as SPS;
    await sps.deployed();

    // Setup roles
    const MINTER_ROLE = await sps.MINTER_ROLE();
    await sps.grantRole(MINTER_ROLE, minter.address);
  });

  /**
 * This test suite focuses on the token minting functionality of the SPS contract. It aims to verify that the contract 
 * behaves correctly under various conditions when minting tokens. The suite contains two test cases:
 * 
 * 1. The first test ensures that tokens can be minted successfully when the sender has the `MINTER_ROLE`. It checks 
 *    that the `mint` function call emits a `Transfer` event with the correct arguments, indicating that the mint operation 
 *    has successfully credited tokens to the recipient's account. It also verifies that the recipient's balance is updated 
 *    accordingly, matching the minted amount.
 * 
 * 2. The second test verifies that an attempt to mint tokens by an account without the `MINTER_ROLE` fails as expected. 
 *    This test is important for ensuring that the contract enforces its role-based permissions correctly, preventing unauthorized 
 *    minting of tokens.
 * 
 * Together, these tests validate the minting feature of the SPS contract, ensuring it operates correctly both in terms 
 * of functionality and access control.
 */
  describe("Minting tokens", function () {
    it("Should mint tokens only if sender has MINTER_ROLE", async function () {
      const mintAmount = ethers.utils.parseUnits("50", 18);
      await expect(sps.connect(minter).mint(recipient.address, mintAmount))
        .to.emit(sps, "Transfer")
        .withArgs(ethers.constants.AddressZero, recipient.address, mintAmount);

      expect(await sps.balanceOf(recipient.address)).to.equal(mintAmount);
    });

    it("Should fail to mint tokens if sender does not have MINTER_ROLE", async function () {
      const mintAmount = ethers.utils.parseUnits("50", 18);
      await expect(sps.connect(accounts[0]).mint(recipient.address, mintAmount)).to.be.revertedWith("missing role");
    });
  });

  /**
 * This test suite evaluates the token burning functionality of the SPS contract. It contains a single test case that 
 * verifies the ability of token holders to burn their tokens. This functionality is critical for token management and 
 * supply regulation within the ecosystem. The test follows these steps:
 * 
 * 1. Mint tokens to the recipient's account to ensure there are tokens available for burning.
 * 
 * 2. Execute the `burn` function from the recipient's account with a specific burn amount, and confirm that the `Transfer` 
 *    event is emitted with expected arguments, indicating the tokens were successfully burned (transferred to the zero address).
 * 
 * 3. Check that the recipient's token balance is updated to reflect the burned tokens, ensuring the burn operation 
 *    effectively reduces the recipient's balance.
 * 
 * This test ensures that the contract's burn mechanism works as intended, allowing users to reduce the total token 
 * supply by burning tokens they own.
 */

  describe("Burning tokens", function () {
    it("Allows a token holder to burn their tokens", async function () {
      const burnAmount = ethers.utils.parseUnits("10", 18);
      // First, mint some tokens to the recipient
      await sps.connect(minter).mint(recipient.address, burnAmount);

      // Now, burn them
      await expect(sps.connect(recipient).burn(burnAmount))
        .to.emit(sps, "Transfer")
        .withArgs(recipient.address, ethers.constants.AddressZero, burnAmount);

      expect(await sps.balanceOf(recipient.address)).to.equal(0);
    });
  });

  /**
 * This test suite is focused on the delegation of voting power functionality provided by the SPS contract. It specifically 
 * tests the ability of token holders to delegate their voting power to another account through a signature-based mechanism, 
 * adhering to the EIP-712 standard for typed message signing. The key steps and verifications in this test include:
 * 
 * 1. Constructing the EIP-712 domain separator and defining the message types, ensuring the contract and delegation 
 *    details are correctly formatted for secure and verifiable signing.
 * 
 * 2. Preparing the delegation message containing the delegatee's address, nonce, and expiry time, and then signing this 
 *    message with the recipient's private key to generate a verifiable signature.
 * 
 * 3. Calling the `delegateBySig` function with the signature and message details to execute the delegation, and verifying 
 *    that the `DelegateChanged` event is emitted with the correct parameters, indicating successful delegation.
 * 
 * 4. Finally, checking the updated voting powers of the involved accounts to confirm that the delegation effect is correctly 
 *    applied according to the contract's logic.
 * 
 * This suite ensures that the voting power delegation feature works as intended, allowing users to securely delegate 
 * their voting rights to others in a transparent and verifiable manner.
 */

  describe("Delegating Voting Power", function () {
    it("Should delegate voting power via signature correctly", async function () {
      // Construct the EIP-712 domain separator
      const domain = {
        name: "Splintershards",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: sps.address,
      };

      // Define the EIP-712 types for delegation
      const types = {
        Delegation: [
          { name: "delegatee", type: "address" },
          { name: "nonce", type: "uint256" },
          { name: "expiry", type: "uint256" },
        ],
      };

      // Construct the value to be signed
      const value = {
        delegatee: minter.address,
        nonce: (await sps.nonces(recipient.address)).toString(),
        expiry: Math.floor(Date.now() / 1000) + 3600, // 1 hour from now
      };

      // Sign the delegation request using the recipient's signer
      const signature = await recipient._signTypedData(domain, types, value);
      const { v, r, s } = ethers.utils.splitSignature(signature);

      // Execute delegateBySig with the obtained signature
      const delegateBySigTx = await sps.delegateBySig(
        value.delegatee,
        value.nonce,
        value.expiry,
        v,
        r,
        s
      );

      // Wait for the transaction to be mined
      await delegateBySigTx.wait();

      // Verify the DelegateChanged event was emitted with correct parameters
      await expect(delegateBySigTx)
        .to.emit(sps, "DelegateChanged")
        .withArgs(recipient.address, ethers.constants.AddressZero, minter.address);

      // Verify the delegation effect on voting power
      // Assuming `getCurrentVotes` reflects the delegated voting power
      const votingPowerRecipient = await sps.getCurrentVotes(recipient.address);
      const votingPowerMinter = await sps.getCurrentVotes(minter.address);

      // Check that the minter's voting power increased to match the recipient's balance if the logic implies transfer of voting power
      // Adjust assertions based on your contract's delegation logic
      expect(votingPowerMinter).to.be.above(0);
    });

  });

  /**
 * The "Role Management" test suite examines the access control features of the SPS contract, particularly focusing on 
 * the management of the `MINTER_ROLE`. It consists of two critical tests that ensure the security and proper management 
 * of roles within the contract:
 * 
 * 1. The first test verifies that only administrators (e.g., the contract owner) have the authority to revoke `MINTER_ROLE` 
 *    from an account. It demonstrates this by first granting the role to a new account, then revoking it, and finally 
 *    asserting that the revoked account cannot perform minting operations. This ensures that role management is securely 
 *    enforced, allowing only authorized users to modify critical permissions.
 * 
 * 2. The second test ensures that non-administrative accounts cannot grant `MINTER_ROLE` to others. This is crucial for 
 *    preventing unauthorized expansion of access within the contract, maintaining strict control over who can mint tokens. 
 *    The test attempts to grant a role from a non-admin account and expects the operation to fail, reinforcing the contract's 
 *    access control mechanisms.
 * 
 * Together, these tests validate the contract's role management functionality, ensuring that only designated administrators 
 * can modify roles, thus securing the contract against unauthorized access.
 */

  describe("Role Management", function () {
    it("Should allow admins to revoke MINTER_ROLE", async function () {
      const newAccount = accounts[1];
      await sps.connect(owner).grantRole(MINTER_ROLE, newAccount.address);
      await expect(sps.connect(owner).revokeRole(MINTER_ROLE, newAccount.address))
        .to.emit(sps, "RoleRevoked")
        .withArgs(MINTER_ROLE, newAccount.address, owner.address);

      // Attempt to mint tokens by the revoked account should fail
      const mintAmount = ethers.utils.parseUnits("1", 18);
      await expect(sps.connect(newAccount).mint(recipient.address, mintAmount))
        .to.be.revertedWith("missing role");
    });

    it("Should prevent non-admins from granting MINTER_ROLE", async function () {
      const newAccount = accounts[1];
      await expect(sps.connect(newAccount).grantRole(MINTER_ROLE, accounts[2].address))
        .to.be.revertedWith("AccessControl:");
    });
  });

  /**
   * The "Edge Cases" test suite explores specific scenarios that could potentially disrupt the normal operation of the SPS 
   * contract. It includes a test that ensures the delegation functionality does not permit assigning voting power to the 
   * zero address, a critical validation for maintaining the integrity of the voting process. This test attempts to delegate 
   * to the zero address and expects the operation to be reverted with an appropriate error message. By handling such edge 
   * cases, the contract ensures that delegation operations adhere to logical and security standards, preventing misuse or 
   * unintended consequences in the delegation system.
   */
  describe("Edge Cases", function () {
    it("Should not allow delegating to the zero address", async function () {
      await expect(sps.connect(recipient).delegate(ethers.constants.AddressZero))
        .to.be.revertedWith("SPS::delegate: invalid delegatee address");
    });
  });

  /**
 * This test suite addresses potential edge cases in the token minting process of the SPS contract. Specifically, it includes 
 * a test designed to ensure that the contract's minting function can handle extremely large numbers without causing integer 
 * overflow errors. This is verified by attempting to mint the maximum uint256 value to a recipient's account and checking 
 * for the successful emission of a `Transfer` event with the expected arguments. Successfully handling such large numbers 
 * without overflow is crucial for maintaining the contract's integrity and ensuring that the token supply remains accurate 
 * and secure against overflow exploits.
 */

  describe("Minting tokens edge cases", function () {
    it("Should not overflow when minting a large number of tokens", async function () {
      const largeAmount = ethers.constants.MaxUint256;
      await expect(sps.connect(minter).mint(recipient.address, largeAmount))
        .to.emit(sps, "Transfer")
        .withArgs(ethers.constants.AddressZero, recipient.address, largeAmount);

      expect(await sps.balanceOf(recipient.address)).to.equal(largeAmount);
    });
  });

  /**
 * The "Burning tokens edge cases" test suite focuses on scenarios where attempts to burn tokens could lead to errors or 
 * unexpected behavior. It includes a test that ensures the contract prevents users from burning more tokens than they own, 
 * a basic but crucial safeguard for token integrity and user balance protection. This is tested by attempting to burn an 
 * amount greater than the account's balance, which should be reverted with a specific error message indicating that the 
 * burn amount exceeds the available balance. This test verifies the contract's adherence to the principle of conservation 
 * of value and its ability to prevent destructive actions.
 */

  describe("Burning tokens edge cases", function () {
    it("Should revert when trying to burn more tokens than an account holds", async function () {
      const mintAmount = ethers.utils.parseUnits("10", 18);
      const burnAmount = ethers.utils.parseUnits("20", 18); // Attempt to burn more than the minted amount
      await sps.connect(minter).mint(recipient.address, mintAmount);

      await expect(sps.connect(recipient).burn(burnAmount))
        .to.be.revertedWith("ERC20: burn amount exceeds balance"); // Adjust the revert message based on your contract
    });
  });

  /**
 * The "Handling invalid inputs" test suite evaluates the SPS contract's responses to non-standard or potentially harmful 
 * inputs. It includes tests for scenarios such as attempting to mint tokens with a zero value and burning zero tokens. 
 * 
 * 1. The first test ensures that minting operations cannot be initiated with a zero value, which would otherwise be a 
 *    no-op or potentially exploit vector. The contract is expected to revert such transactions, maintaining the integrity 
 *    of token minting operations.
 * 
 * 2. The second test assesses the contract's behavior when a burn operation is attempted with zero tokens. Assuming the 
 *    contract treats burning zero tokens as a no-op, this test verifies that such an operation does not cause a revert, 
 *    thereby allowing harmless actions while preventing waste of gas for pointless transactions.
 * 
 * Together, these tests ensure the contract robustly handles edge cases and invalid inputs, preventing errors and enforcing 
 * logical constraints on token operations.
 */

  describe("Handling invalid inputs", function () {
    it("Should revert minting with a zero value", async function () {
      const zeroAmount = ethers.constants.Zero;
      await expect(sps.connect(minter).mint(recipient.address, zeroAmount))
        .to.be.revertedWith("SPS::mint: mint amount cannot be zero"); // Use the specific revert message your contract provides
    });

    it("Allows burning zero tokens without reverting", async function () {
      // Assuming burning zero tokens is a no-op and should not revert
      await expect(sps.connect(recipient).burn(ethers.constants.Zero))
        .to.emit(sps, "Transfer")
        .withArgs(recipient.address, ethers.constants.AddressZero, ethers.constants.Zero);
    });
  });

});
