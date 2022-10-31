# Yul ERC20

ERC20 implementation using only inline assembly yul. Basically, it is a hyper gas optimized ERC20.

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

| Contract            | Gas Cost  |
| ------------------- | --------- |
| OpenZeppelinERC20   | 46231     |
| SolmateERC20        | 46153     |
| YulERC20            | **45985** |

### transfer

| Contract            | Gas Cost  |
| ------------------- | --------- |
| OpenZeppelinERC20   | 51474     |
| SolmateERC20        | 51229     |
| YulERC20            | **51073** |

### transferFrom

| Contract            | Gas Cost  |
| ------------------- | --------- |
| OpenZeppelinERC20   | 33714     |
| SolmateERC20        | 31995     |
| YulERC20            | **31724** |
