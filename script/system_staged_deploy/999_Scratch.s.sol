// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// import { Tea } from "../../src/TeaToken/Tea.sol";
import { BaseScript } from "../Base.s.sol";
// import { Staking } from "../../src/Staking/Staking.sol";
import { Distributor } from "../../src/Distributions/Distributor.sol";
import { console2 } from "lib/forge-std/src/console2.sol";

contract SendTokensScript is BaseScript {
    function run() public broadcaster {
        // Staking staking = Staking(0x2F45A59AF62329d101b6aAd6ac19EBECc4b3DF3d);
        Distributor distributor = Distributor(0xB0c2AFc640a59e07e2229C010f2cb6e7C0B6eFf7);
        // Tea tea = Tea(0x87C51CD469A0E1E2aF0e0e597fD88D9Ae4BaA967);

        console2.log(distributor.claimedStakeTokens(0x32cC197b9542F35D352aE79f09F2a08dFb23745C));
    }
}
