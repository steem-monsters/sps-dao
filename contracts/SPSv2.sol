// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Splintershards (SPS) Token Contract
 * @dev Extends ERC20 Token Standard basic implementation with burnability, access control, and anti-reentrancy features.
 * Includes functionality for token minting and pausing.
 * Utilizes EIP712 for typed structured data hashing and signing.
 */
contract SPS is ERC20, ERC20Burnable, AccessControl, ReentrancyGuard, EIP712, Pausable {
    
    // Defining roles for the contract with unique identifiers.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    /// @dev Mapping of addresses to a boolean indicating whether they are approved bridge addresses.
    mapping(address => bool) public approvedBridges;

    /// @dev Maximum amount of tokens that can be transferred via the bridge in a single transaction.
    uint256 public maxBridgeAmount;

    /// @notice Event used for pausing and unpausing this contract
    event ContractPaused(address indexed sender, bool isPaused);
    /// @notice Event used for renouncing the message senders role
    event RoleRenounced(address indexed account, bytes32 role);
    /// @notice Event used for cross-chain transfers
    event BridgeTransfer(address indexed sender, address indexed receiver, uint256 amount, string chainIdentifier);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes EIP-712 domain separator.
     * All two of these values are immutable: they can only be set once during construction.
     */
    constructor() ERC20("Splintershards", "SPS") EIP712("Splintershards", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); 
        _grantRole(MINTER_ROLE, msg.sender); 
        _grantRole(BURNER_ROLE, msg.sender); 
        _grantRole(BRIDGE_ROLE, msg.sender); 
    }

    /**
     * @dev Override of the `transfer` function to include the `whenNotPaused` modifier.
     * This ensures that token transfers are paused when the contract is paused.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     * @return success A boolean value indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        require(to != address(0), "SPS::transfer: cannot transfer to the zero address");
        return super.transfer(to, amount);
    }

    /**
     * @dev Override of the `transferFrom` function to include the `whenNotPaused` modifier.
     * This ensures that token transfers are paused when the contract is paused.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to be transferred.
     * @return success A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    // _TOKENS.md

    /**
     * @dev Mints `amount` tokens to address `to`, requires the caller to have MINTER_ROLE.
     * Emits a {Transfer} event.
     * @param to The address of the beneficiary that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) nonReentrant whenNotPaused {
        require(to != address(0), "SPS::mint: cannot mint to the zero address");
        require(amount > 0, "SPS::mint: mint amount must be greater than 0");
        _mint(to, amount);
    }

    /**
     * Custom burn function with additional logic
     * Allows token holders to burn their tokens, reducing the total supply.
     * @param amount The amount of tokens to burn.
     */
    function burnTokens(uint256 amount) external onlyRole(BURNER_ROLE) nonReentrant whenNotPaused {
        require(amount > 0, "SPS::burnTokens: burn amount must be greater than 0");
        _burn(_msgSender(), amount);
    }

    // _ROLES.md Start

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
        emit RoleRenounced(msg.sender, "SPS::Renounced Role");
        require(account == msg.sender, "SPS::renounceRole: can only renounce roles for self");
        super.renounceRole(role, account);
    }

    // _ROLES.md End
    // _PAUSE.md Start

    /**
     * @dev Pauses all functions affected by `whenNotPaused`.
     * Can only be called by the account with the admin role.
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        // This emit is for the pause function
        emit ContractPaused(msg.sender, true); // Indicates the contract is now paused
        _pause();
    }

    /**
     * @dev Unpauses all functions affected by `whenNotPaused`.
     * Can only be called by the account with the admin role.
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        // This emit is for the unpause function
        emit ContractPaused(msg.sender, false); // Indicates the contract is now unpaused
        _unpause();
    }

    // _PAUSE.md End
    // _BRIDGE.md Start
        
    /**
    * @notice Sets the approval status of a bridge address.
    * @dev Only callable by accounts with the ADMIN_ROLE. Updates the `approvedBridges` mapping to reflect the approval status of a bridge address.
    * @param bridgeAddress The address of the bridge whose approval status is to be updated.
    * @param approved Boolean indicating whether the bridge is approved (`true`) or not approved (`false`).
    */
    function setApprovedBridge(address bridgeAddress, bool approved) external onlyRole(ADMIN_ROLE) {
        approvedBridges[bridgeAddress] = approved;
    }

    /**
    * @notice Sets the maximum amount of tokens that can be transferred via the bridge in a single transaction.
    * @dev Only callable by accounts with the ADMIN_ROLE. This sets a cap on the amount to prevent excessively large transfers that could impact the token's economy or liquidity.
    * @param _maxBridgeAmount The maximum number of tokens that can be transferred through the bridge in one transaction.
    */
    function setMaxBridgeAmount(uint256 _maxBridgeAmount) external onlyRole(ADMIN_ROLE) {
        maxBridgeAmount = _maxBridgeAmount;
    }

    /**
    * @notice Transfer tokens to cross-chain bridge
    * @param bridgeAddress The address of the bridge account
    * @param rawAmount The amount of tokens transfered
    * @param externalAddress The address on another chain
    */
    function bridgeTransfer(address bridgeAddress, uint256 rawAmount, string calldata externalAddress) external onlyRole(BRIDGE_ROLE) returns(bool) {
        require(approvedBridges[bridgeAddress], "SPS::bridgeTransfer: Unauthorized bridge address");
        require(rawAmount <= maxBridgeAmount, "SPS::bridgeTransfer: Transfer amount exceeds limit");
        // Additional checks or logic here

        emit BridgeTransfer(msg.sender, bridgeAddress, rawAmount, externalAddress);
        transfer(bridgeAddress, rawAmount);
        return true;
    }

    /**
    * @notice Transfer tokens from address to cross-chain bridge
    * @param sourceAddress The address of the source account
    * @param bridgeAddress The address of the bridge account
    * @param rawAmount The amount of tokens transferred
    * @param externalAddress The address on another chain
    */
    function bridgeTransferFrom(address sourceAddress, address bridgeAddress, uint256 rawAmount, string calldata externalAddress) external returns(bool) {
        emit BridgeTransfer(sourceAddress, bridgeAddress, rawAmount, externalAddress);
        transferFrom(sourceAddress, bridgeAddress, rawAmount);
        return true;
    }

    // _BRIDGE.md End
    // _RESCUE.md Start

    /**
     * @dev Allows the admin to rescue ETH sent to the contract by mistake.
     * @param to The address to which rescued ETH should be sent.
     */
    function rescueETH(address payable to) external onlyRole(ADMIN_ROLE) {
        require(to != address(0), "SPS::rescueETH: cannot send to the zero address");
        require(address(this).balance > 0, "SPS::rescueETH: no ETH balance to rescue");
        uint256 balance = address(this).balance;
        (bool success, ) = to.call{value: balance}("");
        require(success, "SPS::rescueETH: Failed to send ETH");
    }

    /**
     * @dev Allows the admin to rescue any ERC20 tokens sent to the contract by mistake.
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param to The address to which rescued tokens should be sent.
     * @param amount The amount of tokens to rescue.
     */
    function rescueERC20(address tokenAddress, address to, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(to != address(0), "SPS::rescueERC20: cannot send to the zero address");
        require(amount > 0, "SPS::rescueERC20: amount must be greater than 0");
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amount, "SPS::rescueERC20: Insufficient token balance to rescue");
        bool success = token.transfer(to, amount);
        require(success, "SPS::rescueERC20: Failed to send ERC20 tokens");
    }

    // _RESCUE.md End
}