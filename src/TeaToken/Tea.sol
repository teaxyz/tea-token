// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

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

import { ERC20Votes } from "@openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
/* solhint-disable no-unused-import */
import { EIP712 } from "@openzeppelin/utils/cryptography/EIP712.sol";
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
/* solhint-enable no-unused-import */
import { Ownable2Step } from "@openzeppelin/access/Ownable2Step.sol";
import { ERC20Burnable } from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";

contract Tea is Ownable2Step, ERC20Votes, ERC20Burnable {
    /* -------------------------------- Constants ------------------------------- */

    uint256 public constant INITIAL_SUPPLY = 100_000_000_000 ether;

    /* --------------------------------- Globals -------------------------------- */

    uint256 public totalMinted;

    /* ------------------------------- Constructor ------------------------------ */

    constructor(address initialGovernor_)
        ERC20("Tea Token", "TEA")
        EIP712("Tea Token", "1")
        Ownable(initialGovernor_)
    {
        totalMinted = INITIAL_SUPPLY;

        _mint(initialGovernor_, INITIAL_SUPPLY);
    }

    function _update(address from, address to, uint256 value) internal virtual override(ERC20Votes, ERC20) {
        super._update(from, to, value);
    }

    /* ------------------------------- Mint / Burn ------------------------------ */

    function mintTo(address account, uint256 value) public {
        _checkOwner();

        totalMinted = totalMinted + value;

        _mint(account, value);
    }

    function burnFrom(address account, uint256 value) public override {
        if (account != msg.sender) _spendAllowance(account, msg.sender, value);

        _burn(account, value);
    }
}
