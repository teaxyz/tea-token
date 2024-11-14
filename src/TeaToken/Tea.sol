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
/* solhint-enable no-unused-import */
import { OwnableRoles } from "@solady/auth/OwnableRoles.sol";
import { ERC20Burnable } from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";

contract Tea is OwnableRoles, ERC20Votes, ERC20Burnable {
    /* --------------------------------- Errors --------------------------------- */

    error MaxSupplyReached();

    /* -------------------------------- Constants ------------------------------- */

    uint256 public constant MINTER_ROLE = 1 << 0; // 01 bitmap flag
    uint256 public constant FACTORY_ROLE = 1 << 1; // 10 bitmap flag

    uint256 public constant MAX_SUPPLY = 100_000_000_000 ether;

    /* --------------------------------- Globals -------------------------------- */

    uint256 public totalMinted;

    /* ------------------------------- Constructor ------------------------------ */

    constructor(address initialGovernor_) ERC20("Tea Token", "TEA") EIP712("Tea Token", "1") {
        _initializeOwner(initialGovernor_);
    }

    function _update(address from, address to, uint256 value) internal virtual override(ERC20Votes, ERC20) {
        super._update(from, to, value);
    }

    /* ------------------------------- Mint / Burn ------------------------------ */

    function mintTo(address account, uint256 value) public {
        _checkOwnerOrRoles(MINTER_ROLE);

        // Cache.
        uint256 newTotalMinted = totalMinted + value;
        // Enforce cap on total minted.
        if (newTotalMinted > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        _mint(account, value);

        totalMinted = newTotalMinted;
    }

    function burnFrom(address account, uint256 value) public override {
        if (account != msg.sender) _spendAllowance(account, msg.sender, value);
        _burn(account, value);
    }

    /* ------------------------------- Role Admin ------------------------------- */

    function addMinter(address toAdd) external {
        _checkRoles(FACTORY_ROLE);

        _grantRoles(toAdd, MINTER_ROLE);
    }

    function removeMinter(address toRemove) external {
        _checkOwner();

        _removeRoles(toRemove, MINTER_ROLE);
    }

    function addFactory(address toAdd) external {
        _checkOwner();

        _grantRoles(toAdd, FACTORY_ROLE);
    }

    function removeFactory(address toRemove) external {
        _checkOwner();

        _removeRoles(toRemove, FACTORY_ROLE);
    }
}
