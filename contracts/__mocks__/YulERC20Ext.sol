// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20External} from "../ERC20External.sol";

contract YulERC20Ext is ERC20External {
    address public immutable owner;

    constructor() ERC20External("abc", "ABC") {
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
