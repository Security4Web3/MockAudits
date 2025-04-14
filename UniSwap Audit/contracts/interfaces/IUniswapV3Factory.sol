// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IUniswapV3Factory {
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    function setOwner(address _owner) external;

    function owner() external view returns (address);

    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

    function feeAmountTickSpacing(uint24 fee) external view returns (int24);
}
