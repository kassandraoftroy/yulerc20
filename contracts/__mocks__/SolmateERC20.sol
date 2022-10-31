// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract SolmateERC20 is ERC20 {
    constructor() ERC20("abc", "ABC", 18) {
        _mint(msg.sender, 1000000e18);
    }
}
