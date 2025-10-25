// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC1271} from "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

// Assuming a simplified contract with one owner for testing purposes.
contract ERC1271Wallet is IERC1271 {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev See {IERC1271-isValidSignature}.
     * This implementation checks if the signature is a valid ECDSA signature
     * from the contract's owner for the given hash.
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4)
    {
        address signer = ECDSA.recover(_hash, _signature);
        if (signer == owner) {
            return IERC1271.isValidSignature.selector; // Return magic value on success
        } else {
            return bytes4(0); // Return a non-magic value on failure
        }
    }
}