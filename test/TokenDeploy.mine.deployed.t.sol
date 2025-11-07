// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { console2 } from "forge-std/console2.sol";

interface ITokenDeploy {
    function INITIAL_GOVERNOR() external view returns (address);
    function deploy(bytes32 salt, bytes32 salt2, bytes32 salt3, address treasury_safe) external;
    function tea() external view returns (address);
    function mintManager() external view returns (address);
    function timelockController() external view returns (address);
}

/* solhint-disable max-states-count */
contract TokenDeployDeployedMiner is PRBTest, StdCheats {
    ITokenDeploy internal tokenDeploy;
    address internal multiSig = 0xcDb68686290310dD8623371E1db53157dB6b8cA1;

    // DEPLOYED TokenDeploy address on Tea Sepolia
    address internal constant DEPLOYED_TOKEN_DEPLOY = 0x890BA97985b7c9441bb82974E10D4df9472C69E6;

    error Unauthorized();

    function setUp() public virtual {
        // Fork Tea Sepolia to mine against the DEPLOYED contract
        string memory rpcUrl = vm.envOr("TEA_SEPOLIA_RPC_URL", string("https://tea-sepolia.g.alchemy.com/public"));
        vm.createSelectFork(rpcUrl);
        tokenDeploy = ITokenDeploy(DEPLOYED_TOKEN_DEPLOY);

        require(tokenDeploy.INITIAL_GOVERNOR() == multiSig, "Wrong governor");
        console2.log("Mining salts for DEPLOYED TokenDeploy at", DEPLOYED_TOKEN_DEPLOY);
    }

    // STEP 1: Mine recoverer/timelock salt first
    // forge test -vvv --match-test testFuzz_mine_recoverer_salt --fuzz-runs 10000000
    function testFuzz_mine_recoverer_salt(bytes32 recovererSalt) public {
        uint256 snapshot = vm.snapshot();
        vm.prank(multiSig);

        try tokenDeploy.deploy(bytes32(0), bytes32(0), recovererSalt, multiSig) {
            address timelock = tokenDeploy.timelockController();

            if (six_bytes(timelock) == 0x7ea) {
                console2.log("=== FOUND RECOVERER SALT ===");
                console2.log("Recoverer salt:");
                console2.logBytes32(recovererSalt);
                console2.log("  -> Timelock:", timelock);
                revert Unauthorized();
            }
        } catch { }

        vm.revertTo(snapshot);
    }

    // STEP 2: Mine tea salt (use recovered timelock address from step 1)
    // forge test -vvv --match-test testFuzz_mine_tea_salt --fuzz-runs 10000000
    // UPDATE THIS WITH YOUR FOUND RECOVERER SALT:
    bytes32 constant FOUND_RECOVERER_SALT = 0x11c93f5926afc4171194932a352934e9d69e8bbce46c8fc5fa927224612be9c2;

    function testFuzz_mine_tea_salt(bytes32 teaSalt) public {
        uint256 snapshot = vm.snapshot();
        vm.prank(multiSig);

        try tokenDeploy.deploy(teaSalt, bytes32(0), FOUND_RECOVERER_SALT, multiSig) {
            address tea = tokenDeploy.tea();

            if (six_bytes(tea) == 0x7ea) {
                console2.log("=== FOUND TEA SALT ===");
                console2.log("Tea salt:");
                console2.logBytes32(teaSalt);
                console2.log("  -> Tea:", tea);
                console2.log("FOUND_RECOVERER_SALT:");
                console2.logBytes32(FOUND_RECOVERER_SALT);
                console2.log("recover address:", address(tokenDeploy.timelockController()));
                revert Unauthorized();
            }
        } catch { }

        vm.revertTo(snapshot);
    }

    // STEP 3: Mine mintManager salt (use recovered tea address from step 2)
    // forge test -vvv --match-test testFuzz_mine_mintmanager_salt --fuzz-runs 10000000
    // UPDATE THESE WITH YOUR FOUND SALTS:
    bytes32 constant FOUND_TEA_SALT = 0xbc35a72c339058163f3e0d91c7776031bc84a6ee663c78f07f8c48795f58c515;

    function testFuzz_mine_mintmanager_salt(bytes32 mintManagerSalt) public {
        uint256 snapshot = vm.snapshot();
        vm.prank(multiSig);

        try tokenDeploy.deploy(FOUND_TEA_SALT, mintManagerSalt, FOUND_RECOVERER_SALT, multiSig) {
            address mintManager = tokenDeploy.mintManager();

            if (six_bytes(mintManager) == 0x7ea) {
                console2.log("=== FOUND MINTMANAGER SALT ===");
                console2.log("MintManager salt:");
                console2.logBytes32(mintManagerSalt);
                console2.log("  -> MintManager:", mintManager);
                console2.log("tea address:", address(tokenDeploy.tea()));
                console2.log("FOUND_TEA_SALT:");
                console2.logBytes32(FOUND_TEA_SALT);
                console2.log("recover address:", address(tokenDeploy.timelockController()));
                console2.log("FOUND_RECOVERER_SALT:");
                console2.logBytes32(FOUND_RECOVERER_SALT);
                revert Unauthorized();
            }
        } catch { }

        vm.revertTo(snapshot);
    }

    // bytes32 constant FOUND_MINTMANAGER_SALT = 0xd7e2cdfda220a728945b1311239a7e4f24ebd1a47dddd171af68f0c9f8e15385;

    function six_bytes(address _address) public pure returns (uint32) {
        return uint32(uint160(_address) >> 148);
    }
}

// ├─ [323] 0xd736AdFAD4C07c3fEc73993dd2e694db1b31C435::mintManager() [staticcall]
// │   └─ ← [Return] MintManager: [0x7Ea57e212770646254ad91D88AA6bdf9F9754D04]
// ├─ [0] console::log("=== FOUND MINTMANAGER SALT ===") [staticcall]
// │   └─ ← [Stop]
// ├─ [0] console::log("MintManager salt:") [staticcall]
// │   └─ ← [Stop]
// ├─ [0] console::log(0xd7e2cdfda220a728945b1311239a7e4f24ebd1a47dddd171af68f0c9f8e15385) [staticcall]
// │   └─ ← [Stop]
// ├─ [0] console::log("  -> MintManager:", MintManager: [0x7Ea57e212770646254ad91D88AA6bdf9F9754D04]) [staticcall]
// │   └─ ← [Stop]
// ├─ [298] 0xd736AdFAD4C07c3fEc73993dd2e694db1b31C435::tea() [staticcall]
// │   └─ ← [Return] Tea: [0x7Ea27904Af7EEfB5a8c3ce973b2EE4670e2815D3]
// ├─ [0] console::log("tea address:", Tea: [0x7Ea27904Af7EEfB5a8c3ce973b2EE4670e2815D3]) [staticcall]
// │   └─ ← [Stop]
// ├─ [0] console::log("FOUND_TEA_SALT:") [staticcall]
// │   └─ ← [Stop]
// ├─ [0] console::log(0x0000000000000000000000000000000000000000000000000000000006fdde04) [staticcall]
// │   └─ ← [Stop]
// ├─ [362] 0xd736AdFAD4C07c3fEc73993dd2e694db1b31C435::timelockController() [staticcall]
// │   └─ ← [Return] 0x7EAEad8a44ceCE3c274e60c82989300D803fF82A
// ├─ [0] console::log("recover address:", 0x7EAEad8a44ceCE3c274e60c82989300D803fF82A) [staticcall]
// │   └─ ← [Stop]
// ├─ [0] console::log("FOUND_RECOVERER_SALT:") [staticcall]
// │   └─ ← [Stop]
// ├─ [0] console::log(0xb4e1e84db575839505eb4e3a1c239d2c3e915cedaa30ee646f6c7f8b75356ef9) [staticcall]
// │   └─ ← [Stop]
