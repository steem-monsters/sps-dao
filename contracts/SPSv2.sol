// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Splintershards (SPS) Token Contract
 * @dev Extends ERC20 Token Standard basic implementation with burnability, access control, and anti-reentrancy features.
 * Includes functionality for token minting, delegation of voting power, and signature-based delegation.
 * Utilizes EIP712 for typed structured data hashing and signing.
 */
contract SPS is ERC20, ERC20Burnable, AccessControl, ReentrancyGuard, EIP712 {
    
    // Defining roles for the contract with unique identifiers.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @dev Sets the values for {name} and {symbol}, initializes EIP-712 domain separator.
     * All two of these values are immutable: they can only be set once during construction.
     */
    constructor() ERC20("Splintershards", "SPS") EIP712("Splintershards", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); 
        _grantRole(MINTER_ROLE, msg.sender); 
        _grantRole(BURNER_ROLE, msg.sender); 
    }

    /**
     * @dev Mints `amount` tokens to address `to`, requires the caller to have MINTER_ROLE.
     * Emits a {Transfer} event.
     * @param to The address of the beneficiary that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) nonReentrant {
        require(to != address(0), "SPS::mint: cannot mint to the zero address");
        require(amount > 0, "SPS::customBurn: mint amount must be greater than 0");
        _mint(to, amount);
    }

    /**
     * Custom burn function with additional logic
     * Allows token holders to burn their tokens, reducing the total supply.
     * @param amount The amount of tokens to burn.
     */
    function burnTokens(uint256 amount) external onlyRole(BURNER_ROLE) nonReentrant {
        require(amount > 0, "SPS::burnTokens: burn amount must be greater than 0");
        _burn(_msgSender(), amount);
    }

    /**
     * @notice Grants a specific role to an account.
     * Only accounts with the admin role for the given role can grant it to others.
     * Emits a {RoleGranted} event.
     *
     * @dev Overrides the {AccessControl.grantRole} function to include non-reentrancy guard.
     * @param role The bytes32 role identifier being granted.
     * @param account The address being granted the role.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.grantRole(role, account);
    }

    /**
     * @notice Revokes a specific role from an account.
     * Only accounts with the admin role for the given role can revoke it from others.
     * Emits a {RoleRevoked} event.
     *
     * @dev Overrides the {AccessControl.revokeRole} function to include non-reentrancy guard.
     * @param role The bytes32 role identifier being revoked.
     * @param account The address from which the role is being revoked.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.revokeRole(role, account);
    }

    /**
     * @notice Renounces a specific role from the calling account.
     * Accounts can renounce roles granted to them, leaving them without that role.
     * Emits a {RoleRevoked} event.
     *
     * @dev Overrides the {AccessControl.renounceRole} function to include non-reentrancy guard.
     * @param role The bytes32 role identifier being renounced.
     * @param account The address that is renouncing the role. Must be the transaction sender.
     */
    function renounceRole(bytes32 role, address account) public override nonReentrant {
        require(account == msg.sender, "SPS::renounceRole: can only renounce roles for self");
        super.renounceRole(role, account);
    }
}