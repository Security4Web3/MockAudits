# Uniswap Security Audit Test Execution Instructions

This document provides detailed instructions for running the Uniswap security audit tests. These tests are designed to identify potential vulnerabilities in the Uniswap V3 protocol by simulating various attack vectors.

## Prerequisites

Before running the tests, ensure you have the following installed:
- Node.js (v16 or later)
- npm (v7 or later)
- Git

## Environment Setup

Follow these steps to set up the testing environment:

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/uniswap-audit.git
cd uniswap-audit/test-environment
```

### 2. Install Dependencies

Install the required dependencies with the compatible versions:

```bash
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox ethers@5.7.2 @openzeppelin/contracts @nomiclabs/hardhat-ethers --legacy-peer-deps
```

Note: We use `ethers@5.7.2` specifically because newer versions of ethers.js (v6+) are incompatible with the Hardhat plugins we're using. The `--legacy-peer-deps` flag helps resolve dependency conflicts.

### 3. Configure Environment Variables

Create a `.env` file in the root directory with the following content:

```
ALCHEMY_API_KEY=your_alchemy_api_key
PRIVATE_KEY=your_private_key_for_testing
```

Replace `your_alchemy_api_key` with your Alchemy API key for mainnet access. This is required for forking the Ethereum mainnet.

### 4. Update Hardhat Configuration (if needed)

The `hardhat.config.js` file is already configured for testing, but you may need to update the Alchemy API URL with your key:

```javascript
require('dotenv').config();
// ...
networks: {
  hardhat: {
    forking: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      blockNumber: 18000000
    },
    chainId: 1337
  },
  // ...
}
```

## Running the Tests

The security audit includes multiple test files, each focusing on a specific vulnerability type. You can run all tests or individual test files.

### Running All Tests

To run all security tests:

```bash
npx hardhat test
```

This will execute all test files in the `test/security` directory.

### Running Individual Test Files

To run specific test files:

```bash
# Test for reentrancy vulnerabilities
npx hardhat test test/security/ReentrancyTest.js

# Test for oracle manipulation vulnerabilities
npx hardhat test test/security/OracleManipulationTest.js

# Test for flash loan vulnerabilities
npx hardhat test test/security/FlashLoanTest.js

# Test for front-running vulnerabilities
npx hardhat test test/security/FrontRunningTest.js
```

## Understanding the Test Results

The test output will show which tests passed and which failed. Here's how to interpret the results:

- **Passing tests**: Indicate that the Uniswap protocol correctly handles the attempted exploit and is secure against that particular attack vector.
- **Failing tests**: May indicate a potential vulnerability that requires further investigation.

Example output for a secure implementation:

```
Uniswap V3 Reentrancy Security Test
  ✓ Should test for reentrancy vulnerabilities in flash function (1234ms)
  ✓ Should test for reentrancy vulnerabilities in swap function (5678ms)
  ✓ Should test for reentrancy vulnerabilities in mint function (9012ms)

3 passing (15s)
```

## Test Coverage

To generate a test coverage report:

```bash
npx hardhat coverage
```

This will create a coverage report in the `coverage` directory, which you can open in your browser to see which parts of the contracts are covered by the tests.

## Troubleshooting Common Issues

### Gas Estimation Errors

If you encounter gas estimation errors, try increasing the gas limit in the test:

```javascript
await contract.function({ gasLimit: 3000000 });
```

### Network Forking Issues

If you have issues with the mainnet fork, try:

1. Updating to a more recent block number in `hardhat.config.js`
2. Ensuring your Alchemy API key has sufficient quota
3. Using a different RPC provider (like Infura)

### Dependency Conflicts

If you encounter dependency conflicts despite using `--legacy-peer-deps`, try:

```bash
rm -rf node_modules
rm package-lock.json
npm install --legacy-peer-deps
```

## Extending the Tests

To add new security tests:

1. Create a new test file in the `test/security` directory
2. Create any required mock contracts in the `contracts/mocks` directory
3. Follow the pattern of existing tests, focusing on a specific vulnerability
4. Run the new test to verify it works correctly

## Security Considerations

These tests simulate attacks on the Uniswap protocol. When running them:

1. Use a dedicated testing environment, never production
2. Do not use real private keys with significant funds
3. Be aware that some tests may consume significant resources due to mainnet forking

## Conclusion

By running these security tests, you can identify potential vulnerabilities in the Uniswap V3 protocol implementation. The tests cover various attack vectors including reentrancy, oracle manipulation, flash loan attacks, and front-running.

Remember that passing all tests does not guarantee absolute security, but it significantly reduces the risk of common vulnerabilities being exploited.
