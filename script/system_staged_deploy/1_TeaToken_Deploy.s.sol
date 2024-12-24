// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { BaseScript } from "../Base.s.sol";
import { DeterministicDeployer } from "../../src/utils/DeterministicDeployer.sol";
import { TokenDeploy } from "../../src/TeaToken/TokenDeploy.sol";

contract TeaTokenDeployScript is BaseScript {
    function run() public broadcaster {
        string memory seed = vm.readFile("script/system_staged_deploy/data/seed.json");

        bytes32 salt = abi.decode(vm.parseJson(seed, ".teaSalt"), (bytes32));
        bytes32 salt2 = abi.decode(vm.parseJson(seed, ".mintManagerSalt"), (bytes32));

        string memory deployer = vm.readFile("script/system_staged_deploy/data/TokenDeploy.json");
        address tokenDeployAddress = abi.decode(vm.parseJson(deployer, ".tokenDeployAddress"), (address));

        TokenDeploy tokenDeploy = TokenDeploy(tokenDeployAddress);
        tokenDeploy.deploy(salt, salt2);

        string memory deployments = "deployments";
        vm.serializeAddress(deployments, "mintManagerAddress", tokenDeploy.mintManager());
        deployments = vm.serializeAddress(deployments, "teaAddress", tokenDeploy.tea());

        vm.writeJson(deployments, string.concat("script/system_staged_deploy/data/Tea.json"));
    }
}
