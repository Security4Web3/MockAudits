// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV3Pool.sol";

/**
 * @title FrontRunningAttacker
 * @dev Contract that attempts to front-run transactions in Uniswap V3
 * This contract is used for testing purposes to verify Uniswap's resistance to front-running
 */
contract FrontRunningAttacker {
    IUniswapV3Pool public pool;
    
    constructor(address _pool) {
        pool = IUniswapV3Pool(_pool);
    }
    
    /**
     * @dev Executes a front-running attack
     * @param zeroForOne Direction of the swap
     * @param amount The amount to swap
     * @param sqrtPriceLimitX96 The price limit for the swap
     */
    function executeFrontRun(bool zeroForOne, uint256 amount, uint160 sqrtPriceLimitX96) external {
        // Approve tokens for the pool
        IERC20(zeroForOne ? pool.token0() : pool.token1()).approve(address(pool), amount);
        
        // Execute the front-running swap
        pool.swap(
            address(this),
            zeroForOne,
            int256(amount),
            sqrtPriceLimitX96,
            abi.encode(amount)
        );
    }
    
    /**
     * @dev Callback for the swap function
     */
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        require(msg.sender == address(pool), "Not authorized");
        
        // Pay for the swap
        if (amount0Delta > 0) {
            IERC20(pool.token0()).transfer(address(pool), uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20(pool.token1()).transfer(address(pool), uint256(amount1Delta));
        }
    }
}
