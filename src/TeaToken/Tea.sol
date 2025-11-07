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
import { ReentrancyGuard } from "@openzeppelin/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
/* solhint-enable no-unused-import */
import { Ownable2Step } from "@openzeppelin/access/Ownable2Step.sol";
import { ERC20PermitWithERC1271 } from "./ERC20PermitWithERC1271.sol";
import { EIP3009WithERC1271 } from "./EIP3009WithERC1271.sol";
import { ERC20Burnable } from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";

contract Tea is Ownable2Step, EIP3009WithERC1271, ERC20PermitWithERC1271, ERC20Burnable, ReentrancyGuard {
    // Add using directive (at contract level)
    using SafeERC20 for IERC20;

    address public recoverer;
    address public treasury_safe;

    /* -------------------------------- Constants ------------------------------- */

    uint256 public constant INITIAL_SUPPLY = 100_000_000_000 ether;

    /**
     * @dev Invalid signature for authorization.
     */
    error CannotRecoverOwnTokens();

    /**
     * @dev Invalid owner for recover transactions
     */
    error CallerIsNotRecoverer();

    /**
     * @dev Recover native failed
     */
    error RecoverNativeFailed(address to, uint256 amount);

    event RecoveredToken(address indexed token, address indexed to, uint256 amount);
    event RecoveredNFT(address indexed token, address indexed to, uint256 tokenId);
    event RecoveredNative(address indexed to, uint256 amount);

    /* --------------------------------- Globals -------------------------------- */

    /// @notice Total number of tokens minted, including burned tokens
    uint256 public totalMinted;

    /* ------------------------------- Constructor ------------------------------ */

    constructor(address initialGovernor_, address recoverer_, address treasury_safe_)
        ERC20("TEA", "TEA")
        ERC20PermitWithERC1271("TEA")
        Ownable(initialGovernor_)
    {
        recoverer = recoverer_;
        totalMinted = INITIAL_SUPPLY;
        treasury_safe = treasury_safe_;

        _mint(initialGovernor_, INITIAL_SUPPLY);
    }

    /* ------------------------------- Mint / Burn ------------------------------ */

    /// @notice Mints new tokens to `account` (only callable by the owner).
    /// @dev Increments `totalMinted`.
    /// @param account The address to receive minted tokens.
    /// @param value   The amount of tokens to be minted.
    function mintInflationTo(address account, uint256 value) external onlyOwner {
        totalMinted = totalMinted + value;

        _mint(account, value);
    }

    modifier onlyRecoverer() {
        require(msg.sender == recoverer, CallerIsNotRecoverer());
        _;
    }

    /**
     * @dev Allows the governance timelockcontroller to recover any ERC-20 tokens
     * that were accidentally sent to this contract.
     * @param tokenAddress The address of the ERC-20 token to recover.
     * @param amount The amount of the ERC-20 token to recover
     */
    function recoverToken(address tokenAddress, uint256 amount) external virtual onlyRecoverer nonReentrant {
        // Require that the token address is not the contract's own token.
        require(tokenAddress != address(this), CannotRecoverOwnTokens());

        IERC20 token = IERC20(tokenAddress);

        // Transfer the tokens from this contract to the specified address.
        token.safeTransfer(treasury_safe, amount);
        
        emit RecoveredToken(tokenAddress, treasury_safe, amount);
    }
    
    /**
     * @dev Allows the governance timelockcontroller to recover any ERC-721 tokens
     * that were accidentally sent to this contract.
     * @param tokenAddress The address of the ERC-721 token to recover.
     * @param tokenId The ID of the token to recover.
     */
    function recoverNFT(
        address tokenAddress,
        uint256 tokenId
    ) external virtual onlyRecoverer nonReentrant {
        // Use the IERC721 interface to safely transfer the NFT from this contract
        IERC721 nft = IERC721(tokenAddress);
        
        // This line attempts the safe transfer of the NFT
        nft.safeTransferFrom(address(this), treasury_safe, tokenId);

        emit RecoveredNFT(tokenAddress, treasury_safe, tokenId);
    }

    /**
     * @dev Allow the contract owner to recover Tea tokens
     * @param amount amount of token to sweep
     */
    function sweepSelf(uint256 amount) external virtual onlyRecoverer nonReentrant {
        _transfer(address(this), treasury_safe, amount);
    }

    /**
     * @dev Allows the governance timelockcontroller to recover any ETH
     * that was accidentally sent to this contract via self destruct.
     */
    function recoverNative(uint256 amount) external virtual onlyRecoverer nonReentrant {
        (bool ok, ) = treasury_safe.call{value: amount}("");
        if (!ok) revert RecoverNativeFailed(treasury_safe, amount);

        emit RecoveredNative(treasury_safe, amount);
    }

    error NativeNotAccepted();
    receive() external payable { revert NativeNotAccepted(); }
    fallback() external payable { revert NativeNotAccepted(); }
}
