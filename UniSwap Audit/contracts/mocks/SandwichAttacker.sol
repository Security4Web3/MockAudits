// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/UniswapV3InterfacesCompat.sol";

/**
 * @title SandwichAttacker
 * @dev Contract that attempts to perform sandwich attacks on Uniswap V3
 * This contract is used for testing purposes to verify Uniswap's resistance to sandwich attacks
 */
contract SandwichAttacker {
    IUniswapV3PoolCompat public pool;
    uint256 public initialBalance0;
    uint256 public initialBalance1;
    
    constructor(address _pool) {
        pool = IUniswapV3PoolCompat(_pool);
        // Record initial balances
        initialBalance0 = IERC20(pool.token0()).balanceOf(address(this));
        initialBalance1 = IERC20(pool.token1()).balanceOf(address(this));
    }
    
    /**
     * @dev Executes a sandwich attack
     * @param zeroForOne Direction of the swap
     * @param victimAmount The amount the victim is swapping
     * @param frontRunAmount The amount to use for front-running
     */
    function executeSandwich(bool zeroForOne, uint256 victimAmount, uint256 frontRunAmount) external {
        // Step 1: Front-run the victim's transaction
        // Approve tokens for the pool
        IERC20(zeroForOne ? pool.token0() : pool.token1()).approve(address(pool), frontRunAmount);
        
        // Execute front-running swap
        pool.swap(
            address(this),
            zeroForOne,
            int256(frontRunAmount),
            zeroForOne ? 1 : type(uint160).max - 1, // Price limit
            abi.encode(frontRunAmount)
        );
        
        // Step 2: Simulate victim's transaction
        // In a real scenario, this would be a pending transaction in the mempool
        // For testing, we simulate it here
        address token = zeroForOne ? pool.token0() : pool.token1();
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        
        IERC20(token).approve(address(pool), victimAmount);
        pool.swap(
            address(this),
            zeroForOne,
            int256(victimAmount),
            zeroForOne ? 1 : type(uint160).max - 1, // Price limit
            abi.encode(victimAmount)
        );
        
        // Step 3: Back-run the victim's transaction
        // Execute back-running swap in the opposite direction
        token = zeroForOne ? pool.token1() : pool.token0();
        uint256 receivedAmount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        
        IERC20(token).approve(address(pool), receivedAmount);
        pool.swap(
            address(this),
            !zeroForOne, // Opposite direction
            int256(receivedAmount),
            !zeroForOne ? 1 : type(uint160).max - 1, // Price limit
            abi.encode(receivedAmount)
        );
    }
    
    /**
     * @dev Calculates the profit from the sandwich attack
     * @return The profit amount in token0 equivalent
     */
    function getProfit() external view returns (uint256) {
        uint256 currentBalance0 = IERC20(pool.token0()).balanceOf(address(this));
        uint256 currentBalance1 = IERC20(pool.token1()).balanceOf(address(this));
        
        // Calculate profit in token0 (simplified)
        if (currentBalance0 > initialBalance0) {
            return currentBalance0 - initialBalance0;
        } else {
            // Convert token1 profit to token0 equivalent using current pool price
            // This is a simplified calculation
            return 0; // In a real implementation, we would convert using the pool price
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
