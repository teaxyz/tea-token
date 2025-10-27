// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC1271} from "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";

/**
 * @title PasskeyWallet
 * @notice Mock wallet that simulates passkey/WebAuthn signature validation
 * @dev For testing purposes: accepts any signature that starts with a specific prefix
 * This simulates a wallet that validates non-ECDSA signatures (like Ed25519, WebAuthn, etc.)
 */
contract PasskeyWallet is IERC1271 {
    bytes32 public constant MAGIC_PREFIX = keccak256("PASSKEY_SIG");
    address public owner;
    
    // Track which digests this wallet has "approved"
    mapping(bytes32 => bool) public approvedDigests;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @notice Pre-approve a digest for testing (simulates passkey confirmation)
     * @dev In a real passkey wallet, the user would confirm via biometrics/PIN
     */
    function approveDigest(bytes32 digest) external {
        require(msg.sender == owner, "Only owner can approve");
        approvedDigests[digest] = true;
    }

    /**
     * @dev See {IERC1271-isValidSignature}.
     * This implementation accepts any signature with the MAGIC_PREFIX for approved digests
     * Simulates a passkey wallet validating WebAuthn/Ed25519 signatures
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4)
    {
        // Check if digest is approved
        if (!approvedDigests[_hash]) {
            return bytes4(0);
        }
        
        // Check signature format (must start with MAGIC_PREFIX)
        if (_signature.length < 32) {
            return bytes4(0);
        }
        
        bytes32 prefix;
        assembly {
            prefix := mload(add(_signature, 32))
        }
        
        if (prefix == MAGIC_PREFIX) {
            return IERC1271.isValidSignature.selector;
        }
        
        return bytes4(0);
    }
}
