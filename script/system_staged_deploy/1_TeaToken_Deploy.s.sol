// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { BaseScript } from "../Base.s.sol";
import { DeterministicDeployer } from "../../src/utils/DeterministicDeployer.sol";

contract TeaTokenDeployScript is BaseScript {
    function run() public broadcaster {
        string memory seed = vm.readFile("script/system_staged_deploy/data/seed.json");

        bytes32 salt = abi.decode(vm.parseJson(seed, ".teaSalt"), (bytes32));
        address teaTreasuryMultisig = abi.decode(vm.parseJson(seed, ".teaTreasuryMultisig"), (address));

        address tea = DeterministicDeployer._deployTea(salt, teaTreasuryMultisig);

        string memory deployments = "deployments";
        deployments = vm.serializeAddress(deployments, "teaAddress", tea);

        vm.writeJson(deployments, string.concat("script/system_staged_deploy/data/Tea.json"));
    }
}
