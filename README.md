# Yul ERC20

**NOT MEANT FOR PRODUCTION - UNAUDITED - USE AT OWN RISK**

ERC20.sol implementation using only inline assembly YUL. Basically, it is a hyper gas optimized ERC20 base implementation for solidity developers. It improves on gas consupmtion for every `public` / `external` method over the leading ERC20.sol implementations (OpenZeppelin, Solmate). Optimizing view/pure calls can matter too, as many ERC20 view methods get used inside of state changing methods. See below for full gas comparison.

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

or

```
import {ERC20External} from "yulerc20/contracts/ERC20External.sol";
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
| OpenZeppelinERC20 | 46232     |
| SolmateERC20      | 46153     |
| YulERC20          | 46080     |
| YulERC20Ext       | **46008** |

### permit

| Contract     | Gas Cost  |
| ------------ | --------- |
| SolmateERC20 | 74172     |
| YulERC20     | 73785     |
| YulERC20Ext  | **73773** |

### transfer

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 51496     |
| SolmateERC20      | 51251     |
| YulERC20          | 51167     |
| YulERC20Ext       | **51073** |

### transferFrom

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 33697     |
| SolmateERC20      | 31995     |
| YulERC20          | 31748     |
| YulERC20Ext       | **31688** |

### allowance

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24578     |
| SolmateERC20      | 24557     |
| YulERC20          | 24557     |
| YulERC20Ext       | **24503** |

### balanceOf

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 23993     |
| SolmateERC20      | 23984     |
| YulERC20          | 23987     |
| YulERC20Ext       | **23939** |

### burn

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 28900     |
| SolmateERC20      | 28768     |
| YulERC20          | **28646** |
| YulERC20Ext       | **28646** |

### decimals

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 21286     |
| SolmateERC20      | 21313     |
| YulERC20          | 21286     |
| YulERC20Ext       | **21262** |

### mint

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 51317     |
| SolmateERC20      | 51194     |
| YulERC20          | **51118** |
| YulERC20Ext       | **51118** |

### name

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24284     |
| SolmateERC20      | 24276     |
| YulERC20          | 21571     |
| YulERC20Ext       | **21281** |

### symbol

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 24282     |
| SolmateERC20      | 24274     |
| YulERC20          | 21580     |
| YulERC20Ext       | **21279** |

### totalSupply

| Contract          | Gas Cost  |
| ----------------- | --------- |
| OpenZeppelinERC20 | 23413     |
| SolmateERC20      | 23427     |
| YulERC20          | **23413** |
| YulERC20Ext       | **23385** |
