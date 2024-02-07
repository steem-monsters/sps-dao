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
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // Mapping to store voting checkpoints for each account.
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
    // Mapping to store the number of checkpoints for each account.
    mapping(address => uint256) public numCheckpoints;
    // Mapping to store the delegatee for each account.
    mapping(address => address) public delegates;
    // Mapping to store nonces for each account, used for delegateBySig function.
    mapping(address => uint256) public nonces;

    // Struct to represent vote checkpoints.
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    // Events for logging changes in delegation and vote balances.
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes EIP-712 domain separator.
     * All two of these values are immutable: they can only be set once during construction.
     */
    constructor() ERC20("Splintershards", "SPS") EIP712("Splintershards", "1") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Assigning the deployer as the default admin.
        _setupRole(ADMIN_ROLE, msg.sender); // Also assigning admin role explicitly to the deployer.
    }

    /**
     * @dev Mints `amount` tokens to address `to`, requires the caller to have MINTER_ROLE.
     * Emits a {Transfer} event.
     * @param to The address of the beneficiary that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) nonReentrant {
        _mint(to, amount);
        _moveDelegates(address(0), delegates[to], amount);
    }

    /**
     * @dev Delegates voting power of the caller to the delegatee `delegatee`.
     * @param delegatee The address to which the caller's voting power will be delegated.
     */
    function delegate(address delegatee) public nonReentrant {
        _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegates voting power to `delegatee` using an off-chain signature.
     * @param delegatee The address to which the voting power will be delegated.
     * @param nonce The contract state required to match the signature.
     * @param expiry The time at which to expire the signature.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signatory = ECDSA.recover(digest, v, r, s);
        require(nonce == nonces[signatory]++, "SPS::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "SPS::delegateBySig: signature expired");
        _delegate(signatory, delegatee);
    }

    /**
     * @dev Internal function to delegate a user's voting power to a delegatee.
     * Updates the delegate mappings and emits a {DelegateChanged} event.
     * @param delegator The address delegating its voting power.
     * @param delegatee The address receiving the voting power.
     */
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
     * @dev Internal function to move delegates between addresses when tokens are transferred.
     * Ensures that vote balances are updated in accordance with token transfers.
     * @param srcRep The source address from which the votes are being moved.
     * @param dstRep The destination address to which the votes are being moved.
     * @param amount The amount of tokens being transferred.
     */
    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = uint32(numCheckpoints[srcRep]);
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld + amount;

                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
                emit DelegateVotesChanged(srcRep, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = uint32(numCheckpoints[dstRep]);
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld + amount;

                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
                emit DelegateVotesChanged(dstRep, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * @dev Internal function to write a checkpoint for an address's vote count.
     * @param delegatee The address whose vote count is being checkpointed.
     * @param nCheckpoints The number of checkpoints the address currently has.
     * @param oldVotes The previous number of votes the address had.
     * @param newVotes The new number of votes the address will have.
     */
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(uint32(block.number), newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
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