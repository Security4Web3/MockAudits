// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV3Pool.sol";

/**
 * @title MEVAttacker
 * @dev Contract that attempts to extract Miner Extractable Value (MEV) from Uniswap V3
 * This contract is used for testing purposes to verify Uniswap's resistance to MEV extraction
 */
contract MEVAttacker {
    IUniswapV3Pool public pool;
    
    constructor(address _pool) {
        pool = IUniswapV3Pool(_pool);
    }
    
    /**
     * @dev Attempts to extract MEV through a series of trades
     * @param amount The amount to use for MEV extraction
     * @param numTrades The number of trades to execute
     */
    function extractMEV(uint256 amount, uint8 numTrades) external {
        // Approve tokens for the pool
        IERC20(pool.token0()).approve(address(pool), amount * numTrades);
        IERC20(pool.token1()).approve(address(pool), amount * numTrades);
        
        // Execute a series of trades to attempt to extract MEV
        bool zeroForOne = true;
        
        for (uint8 i = 0; i < numTrades; i++) {
            // Alternate trade direction to attempt to profit from price movements
            zeroForOne = !zeroForOne;
            
            // Execute the swap
            pool.swap(
                address(this),
                zeroForOne,
                int256(amount),
                zeroForOne ? 1 : type(uint160).max - 1, // Price limit
                abi.encode(amount)
            );
        }
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
