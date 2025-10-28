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
import { IERC721 } from "@openzeppelin/interfaces/IERC721.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
/* solhint-enable no-unused-import */
import { Ownable2Step } from "@openzeppelin/access/Ownable2Step.sol";
import { ERC20Permit } from "./ERC20PermitWithERC1271.sol";
import { EIP3009 } from "./EIP3009.sol";
import { ERC20Burnable } from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";

contract Tea is Ownable2Step, EIP3009, ERC20Burnable, ReentrancyGuard {
    bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    bytes4 constant ERC1271_INVALID_SIGNATURE = 0xffffffff;

    address public timelock;
    address constant TREASURY_SAFE = 0xcDb68686290310dD8623371E1db53157dB6b8cA1;

    /* -------------------------------- Constants ------------------------------- */

    uint256 public constant INITIAL_SUPPLY = 100_000_000_000 ether;

    /**
     * @dev Invalid signature for authorization.
     */
    error CannotRecoverOwnTokens();

    /**
     * @dev Invalid owner for timelock transactions
     */
    error CallerIsNotTimelock();

    event RecoveredToken(address indexed token, address indexed to, uint256 amount);
    event RecoveredNFT(address indexed token, address indexed to, uint256 tokenId);
    event RecoveredEth(address indexed to, uint256 amount);

    /* --------------------------------- Globals -------------------------------- */

    /// @notice Total number of tokens minted, including burned tokens
    uint256 public totalMinted;

    /* ------------------------------- Constructor ------------------------------ */

    constructor(address initialGovernor_, address timelock_)
        ERC20("Tea Token", "TEA")
        ERC20Permit("Tea Token")
        Ownable(initialGovernor_)
    {
        timelock = timelock_;
        totalMinted = INITIAL_SUPPLY;

        _mint(initialGovernor_, INITIAL_SUPPLY);
    }

    /* ------------------------------- Mint / Burn ------------------------------ */

    /// @notice Mints new tokens to `account` (only callable by the owner).
    /// @dev Increments `totalMinted`.
    /// @param account The address to receive minted tokens.
    /// @param value   The amount of tokens to be minted.
    function mintTo(address account, uint256 value) external onlyOwner {
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

    modifier onlyTimelock() {
        require(msg.sender == timelock, CallerIsNotTimelock());
        _;
    }

    /**
     * @dev transfers timelocked functions to a different timelock
     * @param newTimelock The address of the new timelock
     */
    function transferTimelock(address newTimelock) onlyTimelock public virtual {
        timelock = newTimelock;
    }

    /**
     * @dev Allows the contract owner to recover any ERC-20 tokens
     * that were accidentally sent to this contract.
     * @param tokenAddress The address of the ERC-20 token to recover.
     */
    function recoverToken(address tokenAddress) public virtual onlyTimelock nonReentrant {
        // Require that the token address is not the contract's own token.
        require(tokenAddress != address(this), CannotRecoverOwnTokens());

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        // Transfer the tokens from this contract to the specified address.
        token.transfer(TREASURY_SAFE, balance);
        
        emit RecoveredToken(tokenAddress, TREASURY_SAFE, balance);
    }
    
    /**
     * @dev Allows the contract owner to recover any ERC-20 tokens
     * that were accidentally sent to this contract.
     * @param tokenAddress The address of the ERC-20 token to recover.
     * @param tokenId The address to which the recoverd tokens will be sent.
     */
    function recoverNFT(
        address tokenAddress,
        uint256 tokenId
    ) public virtual onlyTimelock nonReentrant {
        // Use the IERC721 interface to safely transfer the NFT from this contract
        IERC721 nft = IERC721(tokenAddress);
        
        // This line attempts the safe transfer of the NFT
        nft.safeTransferFrom(address(this), TREASURY_SAFE, tokenId);

        emit RecoveredNFT(tokenAddress, TREASURY_SAFE, tokenId);
    }

    /**
     * @dev Allows the contract owner to recover any ETH
     * that was accidentally sent to this contract.
     */
    function recoverEth() public virtual onlyTimelock nonReentrant {
        uint256 balance = address(this).balance;

        payable(TREASURY_SAFE).transfer(balance);

        emit RecoveredEth(TREASURY_SAFE, balance);
    }
}
