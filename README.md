# Yul ERC20

ERC20 implementation using only inline assembly YUL. Basically, it is a hyper gas optimized ERC20.

**NOT MEANT FOR PRODUCTION - UNAUDITED - USE AT OWN RISK**

Mostly this is useful as a reference implementation to learn the basics of inline assembly if you are already familiar with canonical solidity ERC20 implementations

## Usage

fill in ALCHEMY_ID in a `.env` (see `.env.example` for all environment vars)

yarn

yarn compile

yarn test

## Gas Comparison

- Solc version: `0.8.13`
- Optimizer enabled: `true`
- Runs: `999999`

### approve

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 46231     |
| SolmateERC20      | 46153     |
| YulERC20          | **45985** |

### transfer

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 51474     |
| SolmateERC20      | 51229     |
| YulERC20          | **51073** |

### transferFrom

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 33714     |
| SolmateERC20      | 31995     |
| YulERC20          | **31724** |

### allowance

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24556     |
| SolmateERC20      | 24535     |
| YulERC20          | **24481** |

### balanceOf

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 23993     |
| SolmateERC20      | 23962     |
| YulERC20          | **23939** |

### totalSupply

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 23368     |
| SolmateERC20      | 23427     |
| YulERC20          | **23362** |
