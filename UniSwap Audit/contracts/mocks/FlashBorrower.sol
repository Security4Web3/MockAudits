// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV3Pool.sol";

/**
 * @title FlashBorrower
 * @dev Contract that tests flash loan functionality in Uniswap V3
 * This contract is used for testing purposes to verify Uniswap's flash loan mechanism
 */
contract FlashBorrower {
    IUniswapV3Pool public pool;
    bool public shouldRepay;
    
    constructor(address _pool) {
        pool = IUniswapV3Pool(_pool);
    }
    
    /**
     * @dev Executes a flash loan
     * @param amount0 The amount of token0 to borrow
     * @param amount1 The amount of token1 to borrow
     * @param repayProperly Whether to repay the flash loan properly
     */
    function flashBorrow(uint256 amount0, uint256 amount1, bool repayProperly) external {
        shouldRepay = repayProperly;
        pool.flash(address(this), amount0, amount1, abi.encode(amount0, amount1));
    }
    
    /**
     * @dev Callback for the flash function
     */
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        require(msg.sender == address(pool), "Not authorized");
        
        // Decode the flash loan parameters
        (uint256 amount0, uint256 amount1) = abi.decode(data, (uint256, uint256));
        
        // Repay the flash loan if shouldRepay is true
        if (shouldRepay) {
            address token0 = pool.token0();
            address token1 = pool.token1();
            
            if (amount0 > 0) {
                IERC20(token0).transfer(address(pool), amount0 + fee0);
            }
            if (amount1 > 0) {
                IERC20(token1).transfer(address(pool), amount1 + fee1);
            }
        }
        // If shouldRepay is false, the transaction will revert as we don't repay
    }
}
