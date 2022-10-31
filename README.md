# Yul ERC20

The ERC20 implementation using only inline assembly yul. Basically a hyper gas optimized ERC20.

**NOT MEANT FOR PRODUCTION - UNAUDITED - USE AT OWN RISK**

Mostly this is useful as a reference implementation to learn the basics of inline assembly if you are already familiar with canonical solidity ERC20 implementations

## Usage

fill in ALCHEMY_ID in a `.env` (see `.env.example` for all environment vars)

yarn

yarn compile

yarn test

## Gas Comparison

Solc version: 0.8.13
Optimizer enabled: true
Runs: 999999

OpenZeppelinERC20 `approve`      46231
SolmateERC20      `approve`      46153
YulERC20          `approve`      45985

OpenZeppelinERC20 `transfer`     51474
SolmateERC20      `transfer`     51229
YulERC20          `transfer`     51073

OpenZeppelinERC20 `transferFrom` 33714
SolmateERC20      `transferFrom` 31995
YulERC20          `transferFrom` 31724
