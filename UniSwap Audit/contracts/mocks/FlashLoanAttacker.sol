// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV3Pool.sol";

/**
 * @title FlashLoanAttacker
 * @dev Contract that attempts to exploit flash loans to drain pool reserves
 * This contract is used for testing purposes to verify Uniswap's flash loan security
 */
contract FlashLoanAttacker {
    IUniswapV3Pool public pool;
    
    constructor(address _pool) {
        pool = IUniswapV3Pool(_pool);
    }
    
    /**
     * @dev Attempts to attack pool reserves using flash loans
     * @param amount0 The amount of token0 to borrow
     * @param amount1 The amount of token1 to borrow
     */
    function attackPoolReserves(uint256 amount0, uint256 amount1) external {
        pool.flash(address(this), amount0, amount1, abi.encode(amount0, amount1));
    }
    
    /**
     * @dev Callback for the flash function
     * This function attempts to exploit the flash loan by not repaying the full amount
     * or by manipulating the pool in some way
     */
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        require(msg.sender == address(pool), "Not authorized");
        
        // Decode the flash loan parameters
        (uint256 amount0, uint256 amount1) = abi.decode(data, (uint256, uint256));
        
        address token0 = pool.token0();
        address token1 = pool.token1();
        
        // Attempt to manipulate the pool or avoid repayment
        // For testing purposes, we'll try to repay less than required
        if (amount0 > 0) {
            // Try to repay less than the required amount
            IERC20(token0).transfer(address(pool), amount0 + fee0 - 1);
        }
        if (amount1 > 0) {
            // Try to repay less than the required amount
            IERC20(token1).transfer(address(pool), amount1 + fee1 - 1);
        }
        
        // This should cause the transaction to revert in a secure implementation
    }
}
