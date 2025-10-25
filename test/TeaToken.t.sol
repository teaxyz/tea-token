// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import { VmSafe } from "@prb/test/Vm.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { IERC20Errors } from "@openzeppelin/interfaces/draft-IERC6093.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { Tea } from "../src/TeaToken/Tea.sol";
import { ERC1271Wallet } from "./helpers/ERC1271Wallet.sol";
import { TokenDeploy } from "../src/TeaToken/TokenDeploy.sol";
import { MintManager } from "../src/TeaToken/MintManager.sol";
import { DeterministicDeployer } from "../src/utils/DeterministicDeployer.sol";
import { ERC20Permit } from "../src/TeaToken/ERC20PermitWithERC1271.sol";

/* solhint-disable max-states-count */
contract TeaTokenTest is PRBTest, StdCheats {
    Tea internal tea;
    TokenDeploy internal tokenDeploy;
    MintManager internal mintManager;
    ERC1271Wallet internal smartWallet;

    VmSafe.Wallet internal initialGovernor = vm.createWallet("Initial Gov Account");
    VmSafe.Wallet internal alice = vm.createWallet("Alice Account");
    VmSafe.Wallet internal bob = vm.createWallet("Bob Account");
    VmSafe.Wallet internal smartWalletOwner = vm.createWallet("SmartWallet Account");

    error OwnableUnauthorizedAccount(address account);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    function setUp() public virtual {
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 20_456_340 });
        bytes32 salt = keccak256(abi.encode(0x00, "tea"));
        tokenDeploy = TokenDeploy(
            DeterministicDeployer._deploy(salt, type(TokenDeploy).creationCode, abi.encode(initialGovernor.addr))
        );

        vm.prank(initialGovernor.addr);
        tokenDeploy.deploy(keccak256(abi.encode(0x01, salt)), keccak256(abi.encode(0x02, salt)));

        tea = Tea(tokenDeploy.tea());
        mintManager = MintManager(tokenDeploy.mintManager());

        smartWallet = ERC1271Wallet(
            DeterministicDeployer._deploy(salt, type(ERC1271Wallet).creationCode, abi.encode(smartWalletOwner.addr))
        );
    }

    function test_owner() public {
        assertEq(tea.owner(), address(mintManager));
    }

    function test_mint_fail() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(this)));
        tea.mintTo(alice.addr, 1);

        vm.startPrank(initialGovernor.addr);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, initialGovernor.addr));
        tea.mintTo(alice.addr, 1);
        vm.stopPrank();
    }

    function test_mint_succeed() public {
        vm.warp(block.timestamp + 365 days);

        vm.prank(initialGovernor.addr);
        mintManager.mintTo(alice.addr, 1);

        assertEq(tea.totalSupply(), tea.INITIAL_SUPPLY() + 1);
        assertEq(tea.totalMinted(), tea.INITIAL_SUPPLY() + 1);
        assertEq(tea.balanceOf(alice.addr), 1);
    }

    function test_burn_fail() public {
        vm.warp(block.timestamp + 365 days);

        vm.prank(initialGovernor.addr);
        mintManager.mintTo(alice.addr, 1);

        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, address(this), 0, 1));
        tea.burnFrom(alice.addr, 1);
    }

    function test_transfer_functionality() public {
        vm.warp(block.timestamp + 365 days);

        // Mint some tokens to alice
        vm.prank(initialGovernor.addr);
        mintManager.mintTo(alice.addr, 100);

        // Test transfer
        vm.prank(alice.addr);
        tea.transfer(bob.addr, 50);

        assertEq(tea.balanceOf(alice.addr), 50);
        assertEq(tea.balanceOf(bob.addr), 50);
    }

    function test_approve_and_transferFrom() public {
        vm.warp(block.timestamp + 365 days);

        // Mint some tokens to alice
        vm.prank(initialGovernor.addr);
        mintManager.mintTo(alice.addr, 100);

        // Alice approves Bob to spend 30 tokens
        vm.prank(alice.addr);
        tea.approve(bob.addr, 30);

        // Bob transfers 20 tokens from Alice to himself
        vm.prank(bob.addr);
        tea.transferFrom(alice.addr, bob.addr, 20);

        assertEq(tea.balanceOf(alice.addr), 80);
        assertEq(tea.balanceOf(bob.addr), 20);
        assertEq(tea.allowance(alice.addr, bob.addr), 10);
    }

    function test_burn_succeed() public {
        vm.warp(block.timestamp + 365 days);

        vm.prank(initialGovernor.addr);
        mintManager.mintTo(alice.addr, 1);

        vm.prank(alice.addr);
        tea.approve(address(this), 1);

        tea.burnFrom(alice.addr, 1);

        assertEq(tea.totalSupply(), tea.INITIAL_SUPPLY());
        assertEq(tea.totalMinted(), tea.INITIAL_SUPPLY() + 1);
        assertEq(tea.balanceOf(alice.addr), 0);
    }

    function test_zero_address_transfers() public {
        vm.warp(block.timestamp + 365 days);

        vm.prank(initialGovernor.addr);
        mintManager.mintTo(alice.addr, 100);

        vm.prank(alice.addr);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        tea.transfer(address(0), 50);
    }

    function test_mint_toZeroAddress_reverts() external {
        vm.warp(block.timestamp + 365 days);
        vm.prank(initialGovernor.addr);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        mintManager.mintTo(address(0), 100);
    }

    function test_ERC1271_permit_standard_success() public {
        // Create Hash
        bytes32 messageHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
                smartWalletOwner.addr, 
                alice.addr, 1, 
                tea.nonces(smartWalletOwner.addr), 
                block.timestamp + 10000
            ));

        bytes32 hash =  MessageHashUtils.toTypedDataHash(tea.DOMAIN_SEPARATOR(), messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(smartWalletOwner, hash);

        vm.prank(smartWalletOwner.addr);
        tea.permit(
            smartWalletOwner.addr,
            alice.addr,
            1,
            block.timestamp + 10000,
            v,
            r,
            s
        );

        assertEq(tea.allowance(smartWalletOwner.addr, alice.addr), 1, "Permit should succeed");
    }

    function test_ERC1271_permit_standard_reuse_fail() public {
        // Create Hash
        bytes32 messageHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
                smartWalletOwner.addr, 
                alice.addr, 1, 
                tea.nonces(smartWalletOwner.addr), 
                block.timestamp + 10000
            ));

        bytes32 hash =  MessageHashUtils.toTypedDataHash(tea.DOMAIN_SEPARATOR(), messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(smartWalletOwner, hash);

        vm.prank(smartWalletOwner.addr);
        tea.permit(
            smartWalletOwner.addr,
            alice.addr,
            1,
            block.timestamp + 10000,
            v,
            r,
            s
        );

        assertEq(tea.allowance(smartWalletOwner.addr, alice.addr), 1, "Permit should succeed");
        vm.expectRevert();
        vm.prank(smartWalletOwner.addr);
        tea.permit(
            smartWalletOwner.addr,
            alice.addr,
            1,
            block.timestamp + 10000,
            v,
            r,
            s
        );

        assertEq(tea.allowance(smartWalletOwner.addr, alice.addr), 1, "Permit should Fail");
    }

    function test_ERC1271_permit_erc1271_success() public {
        // Create Hash
        bytes32 messageHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
                address(smartWallet), 
                alice.addr, 1, 
                tea.nonces(address(smartWallet)), 
                block.timestamp + 10000
            ));

        bytes32 hash =  MessageHashUtils.toTypedDataHash(tea.DOMAIN_SEPARATOR(), messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(smartWalletOwner, hash);

        bytes memory signature = tea.rsvToSig(r,s,v);
        bytes4 result = smartWallet.isValidSignature(hash, signature);       

        // Assert its valid
        assertEq(result, IERC1271.isValidSignature.selector, "Valid signature should return the magic value");

        vm.prank(smartWalletOwner.addr);
        tea.permit(
            address(smartWallet),
            alice.addr,
            1,
            block.timestamp + 10000,
            v,
            r,
            s
        );

        assertEq(tea.allowance(address(smartWallet), alice.addr), 1, "Permit should succeed");
    }   

    function test_ERC1271_permit_erc1271_reuse_fail() public {
        // Create Hash
        bytes32 messageHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
                address(smartWallet), 
                alice.addr, 1, 
                tea.nonces(address(smartWallet)), 
                block.timestamp + 10000
            ));

        bytes32 hash =  MessageHashUtils.toTypedDataHash(tea.DOMAIN_SEPARATOR(), messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(smartWalletOwner, hash);

        bytes memory signature = tea.rsvToSig(r,s,v);
        bytes4 result = smartWallet.isValidSignature(hash, signature);       

        // Assert its valid
        assertEq(result, IERC1271.isValidSignature.selector, "Valid signature should return the magic value");

        vm.prank(smartWalletOwner.addr);
        tea.permit(
            address(smartWallet),
            alice.addr,
            1,
            block.timestamp + 10000,
            v,
            r,
            s
        );

        assertEq(tea.allowance(address(smartWallet), alice.addr), 1, "Permit should succeed");

        vm.prank(smartWalletOwner.addr);
        vm.expectRevert();
        tea.permit(
            address(smartWallet),
            alice.addr,
            1,
            block.timestamp + 10000,
            v,
            r,
            s
        );

        assertEq(tea.allowance(address(smartWallet), alice.addr), 1, "Permit should fail");
    }

    function test_ERC1271_permit_erc1271_contract_does_not_exist() public {
        // Create Hash
        bytes32 messageHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
                bob.addr, 
                alice.addr, 1, 
                tea.nonces(smartWalletOwner.addr), 
                block.timestamp + 10000
            ));

        bytes32 hash =  MessageHashUtils.toTypedDataHash(tea.DOMAIN_SEPARATOR(), messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(smartWalletOwner, hash);

        vm.prank(smartWalletOwner.addr);
        vm.expectRevert();
        tea.permit(
            smartWalletOwner.addr,
            alice.addr,
            1,
            block.timestamp + 10000,
            v,
            r,
            s
        );

        assertEq(tea.allowance(smartWalletOwner.addr, alice.addr), 0, "Permit should fail");
    }

    function test_ERC1271_permit_erc1271_attacker() public {
        // Create Hash
        bytes32 messageHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
                address(smartWallet), 
                alice.addr, 1, 
                tea.nonces(smartWalletOwner.addr), 
                block.timestamp + 10000
            ));

        bytes32 hash =  MessageHashUtils.toTypedDataHash(tea.DOMAIN_SEPARATOR(), messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bob, hash);

        vm.prank(smartWalletOwner.addr);
        vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612InvalidSigner.selector, bob.addr, address(smartWallet)));
        tea.permit(
            address(smartWallet),
            alice.addr,
            1,
            block.timestamp + 10000,
            v,
            r,
            s
        );

        assertEq(tea.allowance(address(smartWallet), alice.addr), 0, "Permit should fail");
    }
}
