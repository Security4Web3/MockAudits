const { expect } = require("chai");
const { ethers } = require("hardhat");

/**
 * @title Reentrancy Attack Test for Uniswap V3
 * @dev This test checks for reentrancy vulnerabilities in Uniswap V3 contracts
 * 
 * Reentrancy attacks occur when a function is called repeatedly before the first invocation is complete.
 * In Uniswap, we need to test functions that transfer tokens or ETH to ensure they follow the
 * checks-effects-interactions pattern and have proper reentrancy guards.
 */
describe("Uniswap V3 Reentrancy Security Test", function () {
  let owner, attacker;
  let mockTokenA, mockTokenB;
  let factory, pool, router;
  
  before(async function () {
    // This test requires forking mainnet to access actual Uniswap contracts
    [owner, attacker] = await ethers.getSigners();
    
    // Get Uniswap V3 Factory contract from mainnet
    factory = await ethers.getContractAt(
      "IUniswapV3Factory",
      "0x1F98431c8aD98523631AE4a59f267346ea31F984" // Mainnet Uniswap V3 Factory address
    );
    
    // Deploy mock tokens for testing
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockTokenA = await MockERC20.deploy("Mock Token A", "MTKA", 18);
    mockTokenB = await MockERC20.deploy("Mock Token B", "MTKB", 18);
    
    // Mint tokens to owner and attacker
    await mockTokenA.mint(owner.address, ethers.utils.parseEther("1000000"));
    await mockTokenB.mint(owner.address, ethers.utils.parseEther("1000000"));
    await mockTokenA.mint(attacker.address, ethers.utils.parseEther("1000"));
    await mockTokenB.mint(attacker.address, ethers.utils.parseEther("1000"));
    
    // Create a new pool with 0.3% fee
    await factory.createPool(mockTokenA.address, mockTokenB.address, 3000);
    
    // Get the pool address
    const poolAddress = await factory.getPool(mockTokenA.address, mockTokenB.address, 3000);
    pool = await ethers.getContractAt("IUniswapV3Pool", poolAddress);
    
    // Initialize the pool with a price of 1:1
    await pool.initialize(ethers.utils.parseUnits("1", 96)); // sqrtPriceX96 for 1:1 price
    
    // Get the router contract
    router = await ethers.getContractAt(
      "ISwapRouter",
      "0xE592427A0AEce92De3Edee1F18E0157C05861564" // Mainnet Uniswap V3 Router address
    );
  });

  it("Should test for reentrancy vulnerabilities in flash function", async function () {
    // Deploy a malicious contract that attempts reentrancy
    const ReentrancyAttacker = await ethers.getContractFactory("ReentrancyAttacker");
    const attacker = await ReentrancyAttacker.deploy(pool.address);
    
    // Test if the flash function is vulnerable to reentrancy
    // The attack should fail if proper reentrancy guards are in place
    await expect(
      attacker.attack(
        ethers.utils.parseEther("10"),
        ethers.utils.parseEther("10")
      )
    ).to.be.reverted;
    
    // Verify that the pool state is consistent after the attack attempt
    const slot0 = await pool.slot0();
    expect(slot0.unlocked).to.be.true; // Pool should be unlocked after the transaction
  });

  it("Should test for reentrancy vulnerabilities in swap function", async function () {
    // Deploy a malicious contract that attempts reentrancy during swap
    const SwapReentrancyAttacker = await ethers.getContractFactory("SwapReentrancyAttacker");
    const swapAttacker = await SwapReentrancyAttacker.deploy(pool.address);
    
    // Test if the swap function is vulnerable to reentrancy
    // The attack should fail if proper reentrancy guards are in place
    await expect(
      swapAttacker.attack(
        true, // zeroForOne
        ethers.utils.parseEther("1"),
        ethers.utils.parseUnits("1", 96) // sqrtPriceLimitX96
      )
    ).to.be.reverted;
    
    // Verify that the pool state is consistent after the attack attempt
    const slot0 = await pool.slot0();
    expect(slot0.unlocked).to.be.true; // Pool should be unlocked after the transaction
  });

  it("Should test for reentrancy vulnerabilities in mint function", async function () {
    // Deploy a malicious contract that attempts reentrancy during liquidity provision
    const MintReentrancyAttacker = await ethers.getContractFactory("MintReentrancyAttacker");
    const mintAttacker = await MintReentrancyAttacker.deploy(pool.address);
    
    // Test if the mint function is vulnerable to reentrancy
    // The attack should fail if proper reentrancy guards are in place
    await expect(
      mintAttacker.attack(
        -887220, // tickLower
        887220,  // tickUpper
        ethers.utils.parseEther("1") // amount
      )
    ).to.be.reverted;
    
    // Verify that the pool state is consistent after the attack attempt
    const slot0 = await pool.slot0();
    expect(slot0.unlocked).to.be.true; // Pool should be unlocked after the transaction
  });
});
