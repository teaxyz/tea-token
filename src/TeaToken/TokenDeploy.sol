// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import { Tea } from "./Tea.sol";
import { MintManager } from "./MintManager.sol";
import { Create2 } from "@openzeppelin/utils/Create2.sol";

/*                                      _@@                                       
 _@                @_              _@@@@@                                       
 @@   @@@@@    _@@ #@\           @@@@@@@@@@      @@@--@@@         @@@@--@@@_    
/@% @@@   @@@@@@@   @@   @@       @@@@@@@     @@@@#    @@@@     @@@@@    @@@@@  
@@                  @@   @@       @@@@@@@    @@@@@     @@@@@    @@@@~    @@@@@@ 
@@                  @@            @@@@@@@   @@@@@@@@@@@@@@@@@           @@@@@@@ 
t@@                 @@   @@       @@@@@@@   @@@@@@                  @@@@#@@@@@@ 
 @@                @@@  @@@       @@@@@@@   @@@@@@@             @@@@@+   @@@@@@ 
 t@@              j@@   @@        @@@@@@@   #@@@@@@@          _@@@@@     @@@@@@ 
  \@@            @@@    @         @@@@@@@    @@@@@@@@_        @@@@@@@   _@@@@@@ 
    @%  @@@@@@@  @                 @@@@@@@@    @@@@@@@@@@@@   +@@@@@@@@@#@@@@@@ 
         t@@@/                      t@@@@+       t@@@@@@        @@@@@@+    t@@@@
*/

contract TokenDeploy {
    error Unauthorized();
    error AlreadyDeployed();
    error AddressMismatch();

    address public immutable INITIAL_GOVERNOR;
    address public tea;
    address public mintManager;

    constructor(address initialGovernor_) {
        INITIAL_GOVERNOR = initialGovernor_;
    }

    function deploy(bytes32 salt, bytes32 salt2) public {
        // One time use.
        if (msg.sender != INITIAL_GOVERNOR) revert Unauthorized();
        if (tea != address(0)) revert AlreadyDeployed();

        // Deploy tea.
        tea = address(new Tea{ salt: salt }(address(this)));

        // Compute and transfer ownership.
        bytes32 codeHash =
            keccak256(abi.encodePacked(type(MintManager).creationCode, abi.encode(INITIAL_GOVERNOR, tea)));
        address _mintManager = Create2.computeAddress(salt2, codeHash, address(this));
        Tea(tea).transferOwnership(_mintManager);
        Tea(tea).transfer(INITIAL_GOVERNOR, Tea(tea).totalSupply());

        // Record address.
        if (_mintManager != address(new MintManager{ salt: salt2 }(INITIAL_GOVERNOR, tea))) revert AddressMismatch();
        mintManager = _mintManager;
    }
}
