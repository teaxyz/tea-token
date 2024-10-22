// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Tea } from "../../src/TeaToken/Tea.sol";
import { BaseScript } from "../Base.s.sol";
import { console2 } from "lib/forge-std/src/console2.sol";

contract SendTokensScript is BaseScript {
    function run() public broadcaster {
        Tea tea = Tea(0x87C51CD469A0E1E2aF0e0e597fD88D9Ae4BaA967);

        console2.log(tea.totalMinted());
    }
}
