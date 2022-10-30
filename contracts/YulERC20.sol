// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract YulERC20 {
    error InsufficientBalance();

    error InsufficientAllowance();

    error AddressZero();

    bytes32 constant internal _MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // keccak256("Transfer(address,address,uint256)")
    bytes32 constant internal _TRANSFER_HASH =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // keccak256("Approval(address,address,uint256)")
    bytes32 constant internal _APPROVAL_HASH =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;
    
    // first 3 bytes of keccak256("InsufficientBalance()")
    bytes32 constant internal _INSUFFICIENT_BALANCE_SELECTOR =
        0xf4d6780000000000000000000000000000000000000000000000000000000000;

    // first 3 bytes of keccak256("InsufficientAllowance()")
    bytes32 constant internal _INSUFFICIENT_ALLOWANCE_SELECTOR =
        0x13be250000000000000000000000000000000000000000000000000000000000;
    
    // first 3 bytes of keccak256("AddressZero()")
    bytes32 constant internal _ADDRESS_ZERO_SELECTOR =
        0x9fabe10000000000000000000000000000000000000000000000000000000000;
    
    bytes32 constant internal _NAME =
        0x6162630000000000000000000000000000000000000000000000000000000000; // "abc"
    
    bytes32 constant internal _SYMBOL =
        0x4142430000000000000000000000000000000000000000000000000000000000; // "ABC"

    // solhint-disable-next-line const-name-snakecase
    uint256 constant public totalSupply = 0xd3c21bcecceda1000000; // 1 million

    constructor() {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, 0x00)
            sstore(keccak256(0x00, 0x40), totalSupply)

            mstore(0x00, totalSupply)
            log3(0x00, 0x20, _TRANSFER_HASH, 0x00, caller())
        }
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        assembly {
            if or(iszero(caller()), iszero(dst)) {
                mstore(0x00, _ADDRESS_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }
            mstore(0x00, caller())
            mstore(0x20, 0x00)
            let srcSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcSlot)
            if lt(srcBalance, amount) {
                mstore(0x00, _INSUFFICIENT_BALANCE_SELECTOR)
                revert(0x00, 0x04)
            }
            sstore(srcSlot, sub(srcBalance, amount))
            mstore(0x00, dst)
            let dstSlot := keccak256(0x00, 0x40)
            sstore(dstSlot, add(sload(dstSlot), amount))

            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, caller(), dst)

            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    // solhint-disable-next-line function-max-lines
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        assembly {
            if or(iszero(src), iszero(dst)) {
                mstore(0x00, _ADDRESS_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }
            mstore(0x00, src)
            mstore(0x20, 0x01)
            let innerHash := keccak256(0x00, 0x40)
            mstore(0x00, caller())
            mstore(0x20, innerHash)
            let allowanceSlot := keccak256(0x00, 0x40)
            let allowance := sload(allowanceSlot)

            if lt(allowance, _MAX) {
                if lt(allowance, amount) {
                    mstore(0x00, _INSUFFICIENT_ALLOWANCE_SELECTOR)
                    revert(0x00, 0x04)
                }
                let newAllowance := sub(allowance, amount)
                sstore(allowanceSlot, newAllowance)

                mstore(0x00, newAllowance)
                log3(0x00, 0x20, _APPROVAL_HASH, src, caller())
            }

            mstore(0x00, src)
            mstore(0x20, 0x00)
            let srcSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcSlot)
            if lt(srcBalance, amount) {
                mstore(0x00, _INSUFFICIENT_BALANCE_SELECTOR)
                revert(0x00, 0x04)
            }
            sstore(srcSlot, sub(srcBalance, amount))
            mstore(0x00, dst)
            let dstSlot := keccak256(0x00, 0x40)
            sstore(dstSlot, add(sload(dstSlot), amount))

            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, src, dst)

            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, 0x01)
            let innerHash := keccak256(0x00, 0x40)
            mstore(0x00, spender)
            mstore(0x20, innerHash)
            sstore(keccak256(0x00, 0x40), amount)

            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_HASH, caller(), spender)

            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, 0x01)
            let innerHash := keccak256(0x00, 0x40)
            mstore(0x00, spender)
            mstore(0x20, innerHash)

            mstore(0x00, sload(keccak256(0x00,0x40)))
            return(0x00, 0x20)
        }
    }

    function balanceOf(address owner) external view returns (uint256) {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, 0x00)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    function decimals() external pure returns (uint8) {
        assembly {
            mstore(0x00, 0x12)
            return(0x00, 0x20)
        }
    }

    function name() external pure returns (string memory) {
        assembly {
            mstore(0x00, 0x20)
            mstore(0x20, 0x03)
            mstore(0x40, _NAME)
            return(0x00, 0x60)
        }
    }

    function symbol() external pure returns (string memory) {
        assembly {
            mstore(0x00, 0x20)
            mstore(0x20, 0x03)
            mstore(0x40, _SYMBOL)
            return(0x00, 0x60)
        }
    }
}
