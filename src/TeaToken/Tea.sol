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

/* solhint-disable no-unused-import */
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";
import { EIP712 } from "@openzeppelin/utils/cryptography/EIP712.sol";
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
/* solhint-enable no-unused-import */
import { Ownable2Step } from "@openzeppelin/access/Ownable2Step.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { EIP3009 } from "./EIP3009.sol";
import { ERC20Burnable } from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
  
contract Tea is Ownable2Step, EIP3009, ERC20Burnable {
  using ECDSA for bytes32;

    /* -------------------------------- Constants ------------------------------- */

    uint256 public constant INITIAL_SUPPLY = 100_000_000_000 ether;

    /* --------------------------------- Globals -------------------------------- */

    /// @notice Total number of tokens minted, including burned tokens
    uint256 public totalMinted;

    /* ------------------------------- Constructor ------------------------------ */

    constructor(address initialGovernor_)
        ERC20("Tea Token", "TEA")
        ERC20Permit("Tea Token")
        Ownable(initialGovernor_)
    {
        totalMinted = INITIAL_SUPPLY;

        _mint(initialGovernor_, INITIAL_SUPPLY);
    }

    /* ------------------------------- Mint / Burn ------------------------------ */

    /// @notice Mints new tokens to `account` (only callable by the owner).
    /// @dev Increments `totalMinted`.
    /// @param account The address to receive minted tokens.
    /// @param value   The amount of tokens to be minted.
    function mintTo(address account, uint256 value) external {
        _checkOwner();

        totalMinted = totalMinted + value;

        _mint(account, value);
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // ERC1271
    /**
     * @notice Verifies that the signer is the owner of the signing contract.
     */
    function isValidSignature(
      bytes32 hash,
      bytes memory signature
    ) external view returns (bytes4) {
        // Validate signatures
        if (hash.recover(signature) == owner()) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }
}
