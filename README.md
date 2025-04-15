# Cross-Chain Communication with Chainlink Functions

## Description
This repository provides an implementation for cross-chain communication between Layer 1 (L1) and Layer 2 (L2) smart contracts using Chainlink Functions for off-chain requests and responses. The contracts allow L2 consumers to send payloads to L1 and receive responses back, facilitating secure and scalable interactions between chains.

## Dependencies
- [Foundry](https://book.getfoundry.sh/): For development, testing, and deployment.
- [Chainlink Contracts](https://github.com/smartcontractkit/chainlink): For integrating Chainlink Functions.
- [T1 Messenger](https://github.com/t1protocol/t1/tree/canary/contracts/src/L1): A cross-chain messaging system used for sending and receiving messages between L1 and L2.

## Installation
1. Clone the repository:
   ```bash
    git clone https://github.com/t0mcr8se/t1-oracle-bridge.git
    cd t1-oracle-bridge
    ```

2. Install dependencies using bun:
   ```bash
   bun install
   ```
> This will install the dependencies of this repo and clone and build the submodules (t1)

3. Build the contracts:
   ```bash
   forge build
   ```

## Contracts Overview

| Contract      | Description |
|---------------|-------------|
| [`L1Consumer`](./src/L1/L1Consumer.sol)  | Implements the L1 consumer that interacts with Chainlink Functions and sends data to L2. |
| [`L2Consumer`](./src/L2/L2Consumer.sol)  | Implements the L2 consumer that sends payloads to L1 and handles responses from L1. |
| [`BaseConsumer`](./src/libraries/BaseConsumer.sol) | A shared base contract providing cross-domain messaging functionality for L1 and L2 consumers. |

## Tests [WIP]
To run the tests for the contracts, use the following command:
```bash
forge test
```
This will run all the test cases defined in the `src/test` directory and provide you with the results.

## Chainlink Subscription Setup
There are 3 steps to creating a Functions subscription on [Chainlink Functions](https://functions.chain.link/sepolia/new):

1)- **Subscription name**: set the subscription name by signing an onchain transaction to initiate the subscription

2)- **Add funds**: use [Chainlink faucet](https://faucets.chain.link/sepolia) to get test LINK tokens to pay for the subscription

3)- **Add a Consumer**: select "I'll do it later" option since the L1Consumer is not deployed yet

Set up your Chainlink account and subscription to Functions, check the [chainlink functions docs](https://docs.chain.link/chainlink-functions) for more info.

## Deployment
run [deploy.sh](./deploy.sh)
```bash
bash deploy.sh
```
**After deployment of L1Consumer is done, we can set the consumer address on our Chainlink subscription to be the L1Consumer address**

## Notice
This implementation is intended for fast finality Layer 2 solutions and is not recommended for production environments without further optimization, security audits, and stress testing.