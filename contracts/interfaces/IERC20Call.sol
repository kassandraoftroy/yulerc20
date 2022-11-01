// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20Call {
    function balanceOf(address) external returns (uint256);

    function allowance(address, address) external returns (uint256);

    function totalSupply() external returns (uint256);
}
