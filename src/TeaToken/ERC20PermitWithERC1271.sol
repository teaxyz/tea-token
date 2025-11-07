// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.20;

import {IERC20Permit} from "@openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {EIP712} from "@openzeppelin/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin/utils/Nonces.sol";
import {Crypto} from "../utils/Crypto.sol";

/**
 * @dev Implementation of the ERC-20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[ERC-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC-20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract ERC20PermitWithERC1271 is ERC20, IERC20Permit, EIP712, Nonces {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // PermitBurn typehash: owner authorizes burning `amount` with a nonce and deadline
    bytes32 public constant PERMIT_BURN_TYPEHASH =
        keccak256("PermitBurn(address owner,uint256 amount,uint256 nonce,uint256 deadline)");

    /**
     * @dev Permit deadline has expired.
     */
    error ERC2612ExpiredSignature(uint256 deadline);

    /**
     * @dev Mismatched signature.
     */
    error ERC2612InvalidSigner(address signer, address owner);

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC-20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        bytes memory signature = Crypto.rsvToSig(r, s, v);
        permit(owner, spender, value, deadline, signature);
    }

    /**
     * @notice Permit with bytes signature (for 7702/passkey/ERC-1271 compatibility)
     * @param owner         Token owner's address
     * @param spender       Spender's address
     * @param value         Amount to approve
     * @param deadline      Signature expiry timestamp
     * @param signature     Signature bytes (can be 65-byte ECDSA or arbitrary ERC-1271)
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes memory signature
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        // SECURITY: Read nonce WITHOUT consuming it yet (prevent griefing attack)
        // If we consume nonce before verification, attacker can grief by submitting invalid signatures
        uint256 currentNonce = nonces(owner);
        
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentNonce, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        
        // Verify signature BEFORE consuming nonce
        (bool valid, address recovered) = Crypto.verifySignature(owner, digest, signature);
        if (!valid) {
            revert ERC2612InvalidSigner(recovered, owner);
        }

        // ONLY consume nonce after successful verification
        _useNonce(owner);

        _approve(owner, spender, value);
    }

    /**
     * @notice Permit-based burn using v,r,s
     * @dev Mirrors the permit flow but burns `amount` from `owner` after signature verification
     */
    function permitBurn(
        address owner,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        bytes memory signature = Crypto.rsvToSig(r, s, v);
        permitBurn(owner, amount, deadline, signature);
    }

    /**
     * @notice Permit-based burn using bytes signature (supports ERC-1271 and passkey formats)
     */
    function permitBurn(
        address owner,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        uint256 currentNonce = nonces(owner);

        bytes32 structHash = keccak256(abi.encode(PERMIT_BURN_TYPEHASH, owner, amount, currentNonce, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);

        (bool valid, address recovered) = Crypto.verifySignature(owner, digest, signature);
        if (!valid) {
            revert ERC2612InvalidSigner(recovered, owner);
        }

        // Consume nonce only after successful verification
        _useNonce(owner);

        // Perform the burn
        _burn(owner, amount);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}
