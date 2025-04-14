// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV3Pool.sol";

/**
 * @title ReentrancyAttacker
 * @dev Contract that attempts to exploit reentrancy vulnerabilities in Uniswap V3 Pool's flash function
 * This contract is used for testing purposes only to verify that Uniswap's reentrancy guards are working
 */
contract ReentrancyAttacker {
    IUniswapV3Pool public pool;
    bool public attackMode;
    
    constructor(address _pool) {
        pool = IUniswapV3Pool(_pool);
    }
    
    function attack(uint256 amount0, uint256 amount1) external {
        // Start the attack by calling flash
        attackMode = true;
        pool.flash(address(this), amount0, amount1, abi.encode(amount0, amount1));
    }
    
    // This function is called by Uniswap's flash function
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        require(msg.sender == address(pool), "Not authorized");
        
        if (attackMode) {
            // Attempt reentrancy attack by calling flash again
            attackMode = false;
            (uint256 amount0, uint256 amount1) = abi.decode(data, (uint256, uint256));
            pool.flash(address(this), amount0, amount1, data);
        }
        
        // Repay the flash loan
        address token0 = pool.token0();
        address token1 = pool.token1();
        
        if (fee0 > 0) {
            IERC20(token0).transfer(address(pool), fee0);
        }
        if (fee1 > 0) {
            IERC20(token1).transfer(address(pool), fee1);
        }
    }
}
