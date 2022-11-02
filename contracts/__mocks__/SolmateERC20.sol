// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract SolmateERC20 is ERC20 {
    address public immutable owner;

    constructor() ERC20("abc", "ABC", 18) {
        _mint(msg.sender, 1000000e18);
        owner = msg.sender;
    }

    function mint(address receiver, uint256 amount) external {
        require(msg.sender == owner, "only owner");
        _mint(receiver, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
