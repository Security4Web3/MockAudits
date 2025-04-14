// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/UniswapV3InterfacesCompat.sol";

/**
 * @title SwapReentrancyAttacker
 * @dev Contract that attempts to exploit reentrancy vulnerabilities in Uniswap V3 Pool's swap function
 * This contract is used for testing purposes only to verify that Uniswap's reentrancy guards are working
 */
contract SwapReentrancyAttacker {
    IUniswapV3PoolCompat public pool;
    bool public attackMode;
    
    constructor(address _pool) {
        pool = IUniswapV3PoolCompat(_pool);
    }
    
    function attack(bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96) external {
        // Start the attack by calling swap
        attackMode = true;
        
        // Approve tokens for the pool
        IERC20(zeroForOne ? pool.token0() : pool.token1()).approve(address(pool), uint256(amountSpecified > 0 ? amountSpecified : -amountSpecified));
        
        // Call swap function
        pool.swap(
            address(this),
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            abi.encode(zeroForOne, amountSpecified, sqrtPriceLimitX96)
        );
    }
    
    // This function is called by Uniswap's swap function
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        require(msg.sender == address(pool), "Not authorized");
        
        if (attackMode) {
            // Attempt reentrancy attack by calling swap again
            attackMode = false;
            (bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96) = abi.decode(data, (bool, int256, uint160));
            
            pool.swap(
                address(this),
                zeroForOne,
                amountSpecified / 2, // Use a smaller amount for the second swap
                sqrtPriceLimitX96,
                data
            );
        }
        
        // Pay for the swap
        if (amount0Delta > 0) {
            IERC20(pool.token0()).transfer(address(pool), uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20(pool.token1()).transfer(address(pool), uint256(amount1Delta));
        }
    }
}
