// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.26;

import { MockERC20 } from "forge-std/mocks/MockERC20.sol";
import { MockERC721 } from "forge-std/mocks/MockERC721.sol";

// Small wrappers over forge-std mocks to expose mint helpers for tests
contract Token_ERC20 is MockERC20 {
    constructor() {
        initialize("MockERC20", "M20", 18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract Token_ERC721 is MockERC721 {
    constructor() {
        initialize("MockERC721", "M721");
    }

    function tokenURI(uint256) public pure override returns (string memory) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
