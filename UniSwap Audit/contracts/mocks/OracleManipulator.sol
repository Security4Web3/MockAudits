// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/UniswapV3InterfacesCompat.sol";

/**
 * @title OracleManipulator
 * @dev Contract that attempts to manipulate Uniswap V3 price oracles
 * This contract is used for testing purposes to verify Uniswap's oracle manipulation resistance
 */
contract OracleManipulator {
    IUniswapV3PoolCompat public pool;
    
    constructor(address _pool) {
        pool = IUniswapV3PoolCompat(_pool);
    }
    
    /**
     * @dev Attempts to manipulate the price in the pool through a large swap
     * @param amount The amount of tokens to swap
     * @param upward Whether to manipulate the price upward (true) or downward (false)
     */
    function manipulatePrice(uint256 amount, bool upward) external {
        // Determine which token to swap based on direction
        bool zeroForOne = upward ? false : true;
        
        // Approve tokens for the pool
        IERC20(zeroForOne ? pool.token0() : pool.token1()).approve(address(pool), amount);
        
        // Execute a large swap to manipulate the price
        pool.swap(
            address(this),
            zeroForOne,
            int256(amount),
            upward ? type(uint160).max - 1 : 1, // Price limit
            abi.encode(amount)
        );
    }
    
    /**
     * @dev Executes a flash loan to attempt price manipulation
     * @param amount0 The amount of token0 to borrow
     * @param amount1 The amount of token1 to borrow
     */
    function executeFlashLoan(uint256 amount0, uint256 amount1) external {
        pool.flash(address(this), amount0, amount1, abi.encode(amount0, amount1));
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
    
    /**
     * @dev Callback for the flash function
     */
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        require(msg.sender == address(pool), "Not authorized");
        
        // Decode the flash loan parameters
        (uint256 amount0, uint256 amount1) = abi.decode(data, (uint256, uint256));
        
        // Execute a large swap to manipulate the price
        if (amount0 > 0) {
            IERC20(pool.token0()).approve(address(pool), amount0);
            pool.swap(
                address(this),
                true, // zeroForOne
                int256(amount0),
                1, // sqrtPriceLimitX96
                abi.encode(amount0)
            );
        }
        
        // Repay the flash loan
        address token0 = pool.token0();
        address token1 = pool.token1();
        
        if (fee0 > 0) {
            IERC20(token0).transfer(address(pool), amount0 + fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).transfer(address(pool), amount1 + fee1);
        }
    }
}
