// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Tea } from "../../src/TeaToken/Tea.sol";
import { BaseScript } from "../Base.s.sol";

contract SendTokensScript is BaseScript {
    Tea internal tea;

    function run() public broadcaster {
        string memory deployments = vm.readFile("script/system_staged_deploy/data/Tea.json");
        tea = Tea(abi.decode(vm.parseJson(deployments, ".teaAddress"), (address)));

        string memory seed = vm.readFile("script/system_staged_deploy/data/seed.json");
        address opsDeployer0 = abi.decode(vm.parseJson(seed, ".opsDeployer0"), (address));
        address distributor = abi.decode(vm.parseJson(seed, ".distributorOwner"), (address));

        tea.transfer(opsDeployer0, 100_000_000 ether);
        tea.transfer(distributor, 100_000_000 ether);
    }
}
