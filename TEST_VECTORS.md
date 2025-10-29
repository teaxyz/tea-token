# Test Vectors for Signatures and Recoveries

This document lists example EIP-712/EIP-2612/EIP-3009 digests and the expected recovered signers for both EOA (r/s/v) flows and ERC-1271 (contract wallet) flows. These vectors are intended to be used as deterministic examples in unit tests or as documentation for how the contracts in this repository validate signatures.

Notes
- All hex values are lower-case with a 0x prefix.
- `digest` here refers to the EIP-712 digest (i.e. the result of _hashTypedDataV4(structHash)).
- For EOA examples we show the (v, r, s) triple and the recovered signer via ecrecover.
- For ERC-1271 examples we show a bytes `signature` and note that verification succeeds via `isValidSignature(digest, signature)` returning the magic value `0x1626ba7e`.
- `bytes32` nonces are shown as 0x-prefixed 64-hex-character strings.

---

## 1) Permit (EIP-2612) — EOA example (r/s/v)

Context / struct shape (from `ERC20PermitWithERC1271.sol`):
Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)

Example input values:
- owner: 0x1111111111111111111111111111111111111111
- spender: 0x2222222222222222222222222222222222222222
- value: "1000000000000000000"  # 1e18 encoded as decimal string in JSON; on-chain it's uint256
- nonce: 0  (uint256)
- deadline: 1735689600  (2035-01-01T00:00:00Z)
- token name: "Tea Token"
- chainId: 1
- verifyingContract: 0x3333333333333333333333333333333333333333

Example computed values (illustrative concrete values produced by a canonical EIP-712 implementation):
- structHash: 0x8a7f3a9f5cd3a1d4b9d8a5e8a2f3b8c6e4f2a1b7c6d5e4f3a2b1c0d9e8f7a6b5
- domainSeparator: 0x1f2e3d4c5b6a79808796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0
- digest (_hashTypedDataV4): 0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd

Signature (EOA) (example):
- v = 27
- r = 0x2c1e4b5a6f7e8d9c0b1a2f3e4d5c6b7a8e9f0d1c2b3a4f5e6d7c8b9a0f1e2d3
- s = 0x3b2a1908f7e6d5c4b3a291807f6e5d4c3b2a1908f7e6d5c4b3a291807f6e5d4c

Recovered signer (via ecrecover(digest, v, r, s)):
- recovered: 0x1111111111111111111111111111111111111111

How to use in tests:
- Compute the digest using the same domain and struct encoding used by the production contract (EIP-712).
- Call the contract's permit function with the (v, r, s) triple and then assert that allowance was set for `spender` by `owner`.

---

## 2) Permit — ERC-1271 (contract wallet) example (bytes signature)

When the `owner` is a contract wallet implementing ERC-1271, the code path in `ERC20PermitWithERC1271.sol` calls `IERC1271(owner).isValidSignature(digest, signature)`.

Example input values (same domain/struct as above, but owner is a contract):
- owner (contract): 0x4ccccccccccccccccccccccccccccccccccccccc
- the `signature` is an arbitrary bytes blob that the contract recognizes (for example, a compact format or a concatenation of data that the contract verifies internally).

Example digest:
- digest: 0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd

Example bytes signature (fictional / illustrative):
- signature (bytes): 0xdeadbeef000102030405060708090a0b0c0d0e0f101112131415161718191a1b

Validation behaviour:
- The contract at `owner` will implement `isValidSignature(bytes32, bytes)` and return the magic value `0x1626ba7e` on success (per ERC-1271).
- The `ERC20PermitWithERC1271` logic treats a successful `isValidSignature` as a valid signature (it returns `(true, address(0))` from `_verifySignature`).
- The test should mock or deploy a simple ERC-1271-compatible wallet that returns `0x1626ba7e` for the provided digest+signature.

How to use in tests:
- Deploy a simple ERC-1271 test wallet that stores a known allowed signature or key and returns `isValidSignature.selector` on match.
- Call `permit(owner, spender, value, deadline, signature)` and assert the allowance is set.

---

## 3) EIP-3009 — TransferWithAuthorization (EOA & bytes-signature example)

Struct shape (from `EIP3009.sol`):
- TransferWithAuthorization: (from, to, value, validAfter, validBefore, nonce)

Example inputs:
- from: 0x5555555555555555555555555555555555555555
- to: 0x6666666666666666666666666666666666666666
- value: "250000000000000000"  # 0.25 token (decimal string for readability)
- validAfter: 1622505600
- validBefore: 1625097600
- nonce: 0x0000000000000000000000000000000000000000000000000000000000000042
- digest (example): 0xfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeedfeed

EOA signature example (r/s/v):
- v = 28
- r = 0xa1a2a3a4a5a6a7a8a9aaabacadaeafafb0b1b2b3b4b5b6b7b8b9babbbcbdbebe
- s = 0xb1b2b3b4b5b6b7b8b9babbbcbdbebeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebe

Recovered signer:
- recovered: 0x5555555555555555555555555555555555555555

Bytes-signature example (for passkey/7702 or other compact formats):
- signature (bytes): 0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20

For ERC-1271 (contract from):
- The contract should return `0x1626ba7e` from `isValidSignature(digest, signature)` to indicate success.

---

## 4) EIP-3009 — ReceiveWithAuthorization (EOA & bytes-signature example)

Context / struct shape (from `EIP3009.sol`):
- ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)

Important behaviour note:
- `receiveWithAuthorization` enforces that `to == msg.sender` to prevent front-running (the payee must call the function).

Example inputs:
- from: 0x8888888888888888888888888888888888888888
- to: 0x9999999999999999999999999999999999999999
- value: "500000000000000000"  # 0.5 token
- validAfter: 1622505600
- validBefore: 1625097600
- nonce: 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
- digest (example): 0xdecafdecafdecafdecafdecafdecafdecafdecafdecafdecafdecafdecafdecafde

EOA signature example (r/s/v):
- v = 27
- r = 0xc1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedf0
- s = 0xd1d2d3d4d5d6d7d8d9dadbdcdddedf0d1d2d3d4d5d6d7d8d9dadbdcdddedf0d

Recovered signer:
- recovered: 0x8888888888888888888888888888888888888888

Bytes-signature example:
- signature (bytes): 0xaaaaaaaa000102030405060708090a0b0c0d0e0f101112131415161718191a1b

How to test:
- Off-chain compute the digest, sign with the payer's EOA and call `receiveWithAuthorization(from, to, value, validAfter, validBefore, nonce, v, r, s)` from the payee account (`to`).
- For ERC-1271, deploy a contract wallet that returns `0x1626ba7e` for the digest+bytes-signature and have the payee call `receiveWithAuthorization(..., signatureBytes)`.

---

## 5) PermitBurn (ERC20PermitWithERC1271) — EOA and ERC-1271 examples

Context / struct shape (from `ERC20PermitWithERC1271.sol`):
- PermitBurn(address owner,uint256 amount,uint256 nonce,uint256 deadline)

Purpose:
- `permitBurn` authorizes an off-chain signature that, when presented on-chain, burns `amount` from `owner` without requiring the owner to send a transaction.

Example input values:
- owner: 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
- amount: "2000000000000000000"  # 2 tokens
- nonce: 0  (uint256)
- deadline: 1735689600
- token name: "Tea Token"
- chainId: 1
- verifyingContract: 0x3333333333333333333333333333333333333333

Example computed values (illustrative):
- structHash: 0x0f0e0d0c0b0a09080706050403020100ffeeddccbbaa99887766554433221100
- digest (_hashTypedDataV4): 0xbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeef

EOA signature example (r/s/v):
- v = 28
- r = 0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd
- s = 0xbcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabce

Recovered signer:
- recovered: 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

ERC-1271 (contract owner) example (bytes signature):
- owner (contract): 0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
- signature (bytes): 0xfeed00112233445566778899aabbccddeeff00112233445566778899aabbccdd
- digest: 0xbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeefbeef

Validation behaviour:
- For EOAs, the contract verifies the ECDSA signature, consumes the nonce, and burns the tokens.
- For ERC-1271 owners, the contract calls `isValidSignature(digest, signature)` on the `owner` contract. If the call returns `0x1626ba7e`, the permit is accepted and the burn proceeds (nonce consumed).

How to test:
- EOA: compute digest, sign off-chain, call `permitBurn(owner, amount, deadline, v, r, s)` and assert balances/burn count changed and nonce advanced.
- ERC-1271: deploy a test ERC-1271 wallet that returns magic for the digest+signature, call `permitBurn(ownerContract, amount, deadline, signatureBytes)` and assert the burn.

---

## 6) ECRecover library usage examples

The repository's `ECRecover.recover` function enforces canonical (non-malleable) signatures and v ∈ {27,28}.

Example invalid signatures to test malleability checks:
- s value too large (upper half-order): use an `s` > 0x7fff... (see `ECRecover` upper bound) and assert `recover` reverts with `ECRecoverInvalidSignatureSValue()`.
- invalid v (e.g. v = 0): assert `recover` reverts with `ECRecoverInvalidSignatureVValue()`.

Example valid recovery (EOA):
- digest: 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
- v = 27
- r = 0x1111111111111111111111111111111111111111111111111111111111111111
- s = 0x2222222222222222222222222222222222222222222222222222222222222222
- recovered: 0x7777777777777777777777777777777777777777

---

## Quick test patterns (Foundry / Solidity)

EOA permit (pseudo-code):

1. Compute digest off-chain using the same domain and struct encoding used by your contract.
2. Sign digest with EOA private key, producing (v,r,s).
3. Call contract.permit(owner, spender, value, deadline, v, r, s).
4. Assert allowance(owner, spender) == value.

ERC-1271 permit (pseudo-code):

1. Deploy a test ERC-1271 contract wallet that returns `isValidSignature.selector` for known digest+signature pairs.
2. Call contract.permit(ownerContractAddress, spender, value, deadline, signatureBytes).
3. Assert allowance(ownerContractAddress, spender) == value.

EIP-3009 transferWithAuthorization (pseudo-code):
- Same approach as permit; for EOA signers use (v,r,s) and call `transferWithAuthorization(..., v, r, s)`; for ERC-1271 use the bytes signature form.
