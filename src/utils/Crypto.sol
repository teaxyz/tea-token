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

import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/interfaces/IERC1271.sol";

library Crypto {
    /**
     * @notice Internal signature verification with ERC-1271 support
     * @param signer        Expected signer address
     * @param digest        EIP-712 digest to verify
     * @param signature     Signature bytes
     * @return valid        True if signature is valid
     * @return recovered    Recovered address (if ECDSA) or zero address (if ERC-1271)
     */
    function verifySignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view returns (bool valid, address recovered) {
        // Try ECDSA recovery for EOAs
        ECDSA.RecoverError err;
        (recovered, err,) = ECDSA.tryRecover(digest, signature);
        if (err == ECDSA.RecoverError.NoError && recovered == signer) {
            return (true, recovered);
        }
        
        // Try ERC-1271 for smart contract wallets
        if (signer.code.length > 0) {
            try IERC1271(signer).isValidSignature(digest, signature) returns (bytes4 magicValue) {
                if (magicValue == IERC1271.isValidSignature.selector) {
                    return (true, address(0));
                } else {
                    return (false, address(0));
                }
            } catch {
                return (false, recovered);
            }
        }
        
        return (false, recovered);
    }

    /**
     * @notice Internal signature verification (bool-only return for internal use)
     */
    function verifySig(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view returns (bool) {
        (bool valid,) = verifySignature(signer, digest, signature);
        return valid;
    }

    /**
     * @notice Internal helper to convert r,s,v to 65-byte signature
     */
    function rsvToSig(bytes32 _a, bytes32 _b, uint8 _c) internal pure returns (bytes memory) {
        bytes memory bytesArray = new bytes(65);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _a[i];
        }
        for (uint256 i = 32; i < 64; i++) {
            bytesArray[i] = _b[i-32];
        }
        bytesArray[64] = bytes1(_c);
        return bytesArray;
    } 
}