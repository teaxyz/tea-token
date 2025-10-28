// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import { VmSafe } from "@prb/test/Vm.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { Tea } from "../src/TeaToken/Tea.sol";
import { TokenDeploy } from "../src/TeaToken/TokenDeploy.sol";
import { MintManager } from "../src/TeaToken/MintManager.sol";
import { DeterministicDeployer } from "../src/utils/DeterministicDeployer.sol";
import { Token_ERC20, Token_ERC721 } from "./helpers/Mocks.t.sol";

/* solhint-disable max-states-count */
contract TokenDeployTest is PRBTest, StdCheats {
    TokenDeploy internal tokenDeploy;

    VmSafe.Wallet internal initialGovernor = vm.createWallet("Initial Gov Account");
    VmSafe.Wallet internal alice = vm.createWallet("Alice Account");
    VmSafe.Wallet internal bob = vm.createWallet("Bob Account");

    error Unauthorized();
    error AlreadyDeployed();

    function setUp() public virtual {
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 20_456_340 });
        bytes32 salt = keccak256(abi.encode(0x00, "tea"));
        tokenDeploy = TokenDeploy(
            DeterministicDeployer._deploy(salt, type(TokenDeploy).creationCode, abi.encode(initialGovernor.addr))
        );
    }

    function test_deploy_fail() public {
        bytes32 salt = keccak256(abi.encode(0x00, "tea"));
        vm.expectRevert(Unauthorized.selector);
        tokenDeploy.deploy(keccak256(abi.encode(0x01, salt)), keccak256(abi.encode(0x02, salt)), keccak256(abi.encode(0x03, salt)));
    }

    function test_repeat_deploy_fail() public {
        bytes32 salt = keccak256(abi.encode(0x00, "tea"));

        vm.prank(initialGovernor.addr);
        tokenDeploy.deploy(keccak256(abi.encode(0x01, salt)), keccak256(abi.encode(0x02, salt)), keccak256(abi.encode(0x03, salt)));

        vm.prank(initialGovernor.addr);
        vm.expectRevert(AlreadyDeployed.selector);
        tokenDeploy.deploy(keccak256(abi.encode(0x01, salt)), keccak256(abi.encode(0x02, salt)), keccak256(abi.encode(0x03, salt)));
    }

    function test_deploy_succeed() public {
        bytes32 salt = keccak256(abi.encode(0x00, "tea"));

        vm.prank(initialGovernor.addr);
        tokenDeploy.deploy(keccak256(abi.encode(0x01, salt)), keccak256(abi.encode(0x02, salt)), keccak256(abi.encode(0x03, salt)));

        address _tea = tokenDeploy.tea();
        address _mintManager = tokenDeploy.mintManager();
        address _timelockController = tokenDeploy.timelockController();

        assertNotEq(_tea, address(0));
        assertNotEq(_mintManager, address(0));
        assertNotEq(_timelockController, address(0));
        assertEq(Tea(_tea).owner(), _mintManager);
        assertEq(Tea(_tea).totalSupply(), Tea(_tea).INITIAL_SUPPLY());
        assertEq(Tea(_tea).totalMinted(), Tea(_tea).INITIAL_SUPPLY());
        assertEq(Tea(_tea).balanceOf(initialGovernor.addr), Tea(_tea).INITIAL_SUPPLY());
    }

    function test_timelock_controller_can_call_recover_functions() public {
        bytes32 salt = keccak256(abi.encode(0x00, "tea"));

        // Deploy the system
        vm.prank(initialGovernor.addr);
        tokenDeploy.deploy(keccak256(abi.encode(0x01, salt)), keccak256(abi.encode(0x02, salt)), keccak256(abi.encode(0x03, salt)));

        Tea _tea = Tea(tokenDeploy.tea());

        // Send ETH to the tea contract
        vm.deal(address(_tea), 1 ether);

        // Non-timelock cannot recover ETH
        vm.prank(initialGovernor.addr);
        vm.expectRevert();
        _tea.recoverEth();

        // Timelock can recover ETH
        vm.prank(tokenDeploy.timelockController());
        _tea.recoverEth();

        assertEq(address(_tea).balance, 0);

        // Test recoverToken
        Token_ERC20 token = new Token_ERC20();
        token.mint(address(_tea), 5 ether);

        uint256 bal = token.balanceOf(address(_tea));

        vm.prank(initialGovernor.addr);
        vm.expectRevert();
        _tea.recoverToken(address(token));

        vm.prank(tokenDeploy.timelockController());
        _tea.recoverToken(address(token));

        assertEq(token.balanceOf(address(_tea)), 0);
        assertEq(token.balanceOf(_tea.TREASURY_SAFE()), bal);

        // Test recoverNFT
        Token_ERC721 nft = new Token_ERC721();
        nft.mint(address(_tea), 9001);

        vm.prank(initialGovernor.addr);
        vm.expectRevert();
        _tea.recoverNFT(address(nft), 9001);

        vm.prank(tokenDeploy.timelockController());
        _tea.recoverNFT(address(nft), 9001);

        assertEq(nft.ownerOf(9001), _tea.TREASURY_SAFE());
    }
}
