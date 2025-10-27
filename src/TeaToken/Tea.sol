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
import { EIP712 } from "@openzeppelin/utils/cryptography/EIP712.sol";
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
/* solhint-enable no-unused-import */
import { Ownable2Step } from "@openzeppelin/access/Ownable2Step.sol";
import { ERC20Permit } from "./ERC20PermitWithERC1271.sol";
import { EIP3009 } from "./EIP3009.sol";
import { ERC20Burnable } from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";

contract Tea is Ownable2Step, EIP3009, ERC20Burnable {
    bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    bytes4 constant ERC1271_INVALID_SIGNATURE = 0xffffffff;

    /* -------------------------------- Constants ------------------------------- */

    uint256 public constant INITIAL_SUPPLY = 100_000_000_000 ether;

    /**
     * @dev Invalid signature for authorization.
     */
    error CannotRecoverOwnTokens();

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

    /**
     * @dev Allows the contract owner to recover any ERC-20 tokens
     * that were accidentally sent to this contract.
     * @param tokenAddress The address of the ERC-20 token to recover.
     * @param to The address to which the recoverd tokens will be sent.
     * @return the amount transfered
     */
    function recoverToken(address tokenAddress, address to) public virtual onlyOwner returns(uint256) {
        // Require that the token address is not the contract's own token.
        require(tokenAddress != address(this), CannotRecoverOwnTokens());

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        // Transfer the tokens from this contract to the specified address.
        token.transfer(to, balance);
        
        return balance;
    }

    /**
     * @dev Allows the contract owner to recover any ETH
     * that was accidentally sent to this contract.
     * @param to The address to which the recoverd ETH will be sent.
     * @return the amount transfered
     */
    function recoverEth(address to) public virtual onlyOwner returns (uint256) {
        uint256 balance = address(this).balance;

        payable(to).transfer(balance);

        return balance;
    }
}
