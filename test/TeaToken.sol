// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import { VmSafe } from "@prb/test/Vm.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { Tea } from "../src/TeaToken/Tea.sol";
import { DeterministicDeployer } from "../src/utils/DeterministicDeployer.sol";

/* solhint-disable max-states-count */
contract TeaTokenTest is PRBTest, StdCheats {
    Tea internal tea;

    VmSafe.Wallet internal initialGovernor = vm.createWallet("Initial Gov Account");
    VmSafe.Wallet internal alice = vm.createWallet("Alice Account");
    VmSafe.Wallet internal bob = vm.createWallet("Bob Account");

    error Unauthorized();
    error MaxSupplyReached();
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    function setUp() public virtual {
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 20_456_340 });
        bytes32 salt = keccak256(abi.encode(0x00, "tea"));
        tea = Tea(DeterministicDeployer._deployTea(salt, initialGovernor.addr));
    }

    function test_owner() public {
        assertEq(tea.owner(), initialGovernor.addr);
    }

    function test_mint_fail() public {
        vm.expectRevert(Unauthorized.selector);
        tea.mintTo(alice.addr, 1);
    }

    function test_addMinter_fail() public {
        vm.expectRevert(Unauthorized.selector);
        tea.addMinter(alice.addr);
    }

    function test_addFactory_fail() public {
        vm.expectRevert(Unauthorized.selector);
        tea.addFactory(alice.addr);
    }

    function test_removeMinter_fail() public {
        vm.prank(initialGovernor.addr);
        tea.addFactory(alice.addr);

        vm.prank(alice.addr);
        tea.addMinter(bob.addr);

        vm.expectRevert(Unauthorized.selector);
        tea.removeMinter(bob.addr);
    }

    function test_removeFactory_fail() public {
        vm.prank(initialGovernor.addr);
        tea.addFactory(alice.addr);

        vm.expectRevert(Unauthorized.selector);
        tea.removeFactory(alice.addr);
    }

    function test_mint_succeed() public {
        vm.prank(initialGovernor.addr);
        tea.addFactory(address(this));

        tea.addMinter(bob.addr);

        vm.prank(bob.addr);
        tea.mintTo(alice.addr, 1);

        assertEq(tea.totalSupply(), 1);
        assertEq(tea.totalMinted(), 1);
        assertEq(tea.balanceOf(alice.addr), 1);
    }

    function test_mint_to_cap() public {
        vm.prank(initialGovernor.addr);
        tea.addFactory(address(this));

        tea.addMinter(bob.addr);

        uint256 maxSupply = tea.MAX_SUPPLY();

        vm.prank(bob.addr);
        tea.mintTo(alice.addr, maxSupply);

        assertEq(tea.totalSupply(), maxSupply);
        assertEq(tea.totalMinted(), maxSupply);
        assertEq(tea.balanceOf(alice.addr), maxSupply);
    }

    function test_mint_fail_above_cap() public {
        vm.prank(initialGovernor.addr);
        tea.addFactory(address(this));

        tea.addMinter(bob.addr);

        uint256 maxSupply = tea.MAX_SUPPLY();

        vm.prank(bob.addr);
        tea.mintTo(alice.addr, maxSupply);

        assertEq(tea.totalSupply(), maxSupply);
        assertEq(tea.totalMinted(), maxSupply);
        assertEq(tea.balanceOf(alice.addr), maxSupply);

        vm.prank(alice.addr);
        tea.burnFrom(alice.addr, 1);

        vm.startPrank(bob.addr);
        vm.expectRevert(MaxSupplyReached.selector);
        tea.mintTo(alice.addr, 1);
        vm.stopPrank();

        assertEq(tea.totalSupply(), maxSupply - 1);
        assertEq(tea.totalMinted(), maxSupply);
        assertEq(tea.balanceOf(alice.addr), maxSupply - 1);
    }

    function test_burn_fail() public {
        vm.prank(initialGovernor.addr);
        tea.addFactory(address(this));

        tea.addMinter(bob.addr);

        vm.prank(bob.addr);
        tea.mintTo(alice.addr, 1);

        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, address(this), 0, 1));
        tea.burnFrom(alice.addr, 1);
    }
}
