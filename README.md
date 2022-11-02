# Yul ERC20

**NOT MEANT FOR PRODUCTION - UNAUDITED - USE AT OWN RISK**

ERC20 implementation using only inline assembly YUL. Basically, it is a hyper gas optimized ERC20 base implementation for solidity developers. It improves on gas consupmtion in **every** `public` & `external` method over the leading ERC20.sol implementations (OpenZeppelin, Solmate). Optimizing view/pure calls can matter too, as many ERC20 view methods get used inside of state changing methods. See below for full gas comparison.

Mostly this is useful as a reference implementation to learn the basics of inline assembly if you are already familiar with canonical solidity ERC20 implementations

## Usage

install with

```
npm install yulerc20
```

then you could import this as your base ERC20 contract implementation:

```
import {ERC20} from "yulerc20/contracts/ERC20.sol";
```

## Test

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

### mint

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 51317     |
| SolmateERC20      | 51194     |
| YulERC20          | **51079** |

### burn

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 28900     |
| SolmateERC20      | 28768     |
| YulERC20          | **28646** |

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

### decimals

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 21308     |
| SolmateERC20      | 21313     |
| YulERC20          | **21240** |

### symbol

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24327     |
| SolmateERC20      | 24319     |
| YulERC20          | **21309** |

### name

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24284     |
| SolmateERC20      | 24276     |
| YulERC20          | **21288** |
