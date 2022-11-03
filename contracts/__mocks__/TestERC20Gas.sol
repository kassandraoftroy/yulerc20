// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract TestERC20Gas {
    function test(address token_) external view returns (uint256[6] memory x) {
        IERC20Metadata token = IERC20Metadata(token_);
        uint256 remaining = gasleft();
        token.balanceOf(msg.sender);
        x[0] = remaining - gasleft();
        remaining = gasleft();
        token.allowance(msg.sender, address(1));
        x[1] = remaining - gasleft();
        remaining = gasleft();
        token.name();
        x[2] = remaining - gasleft();
        remaining = gasleft();
        token.symbol();
        x[3] = remaining - gasleft();
        remaining = gasleft();
        token.totalSupply();
        x[4] = remaining - gasleft();
        remaining = gasleft();
        token.decimals();
        x[5] = remaining - gasleft();
        remaining = gasleft();
    }
}
