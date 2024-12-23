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

    error OwnableUnauthorizedAccount(address account);
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
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(this)));
        tea.mintTo(alice.addr, 1);
    }

    function test_mint_succeed() public {
        vm.prank(initialGovernor.addr);
        tea.mintTo(alice.addr, 1);

        assertEq(tea.totalSupply(), tea.INITIAL_SUPPLY() + 1);
        assertEq(tea.totalMinted(), tea.INITIAL_SUPPLY() + 1);
        assertEq(tea.balanceOf(alice.addr), 1);
    }

    function test_burn_fail() public {
        vm.prank(initialGovernor.addr);
        tea.mintTo(alice.addr, 1);

        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, address(this), 0, 1));
        tea.burnFrom(alice.addr, 1);
    }
}
