// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV3Pool.sol";

/**
 * @title MintReentrancyAttacker
 * @dev Contract that attempts to exploit reentrancy vulnerabilities in Uniswap V3 Pool's mint function
 * This contract is used for testing purposes only to verify that Uniswap's reentrancy guards are working
 */
contract MintReentrancyAttacker {
    IUniswapV3Pool public pool;
    bool public attackMode;
    
    constructor(address _pool) {
        pool = IUniswapV3Pool(_pool);
    }
    
    function attack(int24 tickLower, int24 tickUpper, uint128 amount) external {
        // Start the attack by calling mint
        attackMode = true;
        
        // Approve tokens for the pool
        IERC20(pool.token0()).approve(address(pool), type(uint256).max);
        IERC20(pool.token1()).approve(address(pool), type(uint256).max);
        
        // Call mint function
        pool.mint(
            address(this),
            tickLower,
            tickUpper,
            amount,
            abi.encode(tickLower, tickUpper, amount)
        );
    }
    
    // This function is called by Uniswap's mint function
    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external {
        require(msg.sender == address(pool), "Not authorized");
        
        if (attackMode) {
            // Attempt reentrancy attack by calling mint again
            attackMode = false;
            (int24 tickLower, int24 tickUpper, uint128 amount) = abi.decode(data, (int24, int24, uint128));
            
            pool.mint(
                address(this),
                tickLower,
                tickUpper,
                amount / 2, // Use a smaller amount for the second mint
                data
            );
        }
        
        // Pay for the liquidity
        if (amount0Owed > 0) {
            IERC20(pool.token0()).transfer(address(pool), amount0Owed);
        }
        if (amount1Owed > 0) {
            IERC20(pool.token1()).transfer(address(pool), amount1Owed);
        }
    }
}
