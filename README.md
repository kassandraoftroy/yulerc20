# Yul ERC20

**NOT MEANT FOR PRODUCTION - UNAUDITED - USE AT OWN RISK**

ERC20 implementations using only inline assembly YUL. Basically, hyper gas optimized ERC20 base implementations for solidity developers. It improves on gas consupmtion for every `public` / `external` method over the leading ERC20.sol implementations (OpenZeppelin, Solmate). Optimizing view/pure calls can matter too, as many ERC20 view methods get used inside of state changing methods. See below for full gas comparison.

Note that there are two separate slightly differing implementations ERC20.sol and ERC20External.sol in this repository. Use ERC20External.sol for additional gas savings if your ERC20 doesn't need internal (i.e. same contract including inheritors) access to any of these functions: `transfer()`, `transferFrom()`, `approve()`, `allowance()`, `balanceOf()`, `nonces()`, `totalSupply()`, `name()`, `symbol()`, `decimals()`. All the basic getter functions can still be accessed easily via internal state variables and so are not needed, and the remaining functions are usually not needed as an internal subroutine; thus most ERC20s, especially simple ones, should benefit from the ERC20External.sol implementation gas savings. For those that want to utilize any of the listed functions in thier contracts that inherit and extend the base implementation, they can use ERC20.sol instead (gas usage only increases by 0-100 gas in most functions).

This is also useful as a reference implementation to learn the basics of inline assembly if you are already familiar with canonical solidity ERC20 implementations. There are comments with solidity translations for lines in yul.

## Usage

install with

```
npm install yulerc20
```

then you could import this as your base ERC20 contract implementation:

```
import {ERC20} from "yulerc20/contracts/ERC20.sol";
```

or

```
import {ERC20External} from "yulerc20/contracts/ERC20External.sol";
```

**STILL HIGHLY EXPERIMENTAL - NOT YET MEANT FOR PRODUCTION**

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
| OpenZeppelinERC20 | 46232     |
| SolmateERC20      | 46153     |
| YulERC20          | 46080     |
| YulERC20External  | **46008** |

### permit

| Contract         | Gas Cost  |
| ---------------- | --------- |
| SolmateERC20     | 74172     |
| YulERC20         | 73774     |
| YulERC20External | **73762** |

### transfer

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 51496     |
| SolmateERC20      | 51251     |
| YulERC20          | 51167     |
| YulERC20External  | **51073** |

### transferFrom

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 33697     |
| SolmateERC20      | 31995     |
| YulERC20          | 31748     |
| YulERC20External  | **31688** |

### allowance

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24578     |
| SolmateERC20      | 24557     |
| YulERC20          | 24557     |
| YulERC20External  | **24503** |

### balanceOf

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 23993     |
| SolmateERC20      | 23984     |
| YulERC20          | 23987     |
| YulERC20External  | **23939** |

### burn

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 28900     |
| SolmateERC20      | 28768     |
| YulERC20          | **28646** |
| YulERC20External  | **28646** |

### decimals

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 21286     |
| SolmateERC20      | 21313     |
| YulERC20          | 21286     |
| YulERC20External  | **21262** |

### mint

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 51317     |
| SolmateERC20      | 51194     |
| YulERC20          | **51118** |
| YulERC20External  | **51118** |

### name

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24284     |
| SolmateERC20      | 24276     |
| YulERC20          | 21571     |
| YulERC20External  | **21281** |

### symbol

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24282     |
| SolmateERC20      | 24274     |
| YulERC20          | 21580     |
| YulERC20External  | **21279** |

### totalSupply

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 23413     |
| SolmateERC20      | 23427     |
| YulERC20          | 23413     |
| YulERC20External  | **23385** |
