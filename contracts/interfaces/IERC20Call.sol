// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice this interface is just for testing gas consumption of view methods
/// conveniently if we cast our ERC20 contracts to this interface we will send transactions
/// and get a gas reading
interface IERC20Call {
    function balanceOf(address) external returns (uint256);

    function allowance(address, address) external returns (uint256);

    function totalSupply() external returns (uint256);

    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);
}
