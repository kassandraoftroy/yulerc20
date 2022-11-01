// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// solhint-disable-next-line max-states-count
abstract contract ERC20 {
    error InsufficientBalance();

    error InsufficientAllowance();

    error AddressZero();

    error Overflow();

    event Transfer(address indexed src, address indexed dst, uint256 amount);

    event Approval(address indexed src, address indexed dst, uint256 amount);

    // keccak256("Transfer(address,address,uint256)")
    bytes32 internal constant _TRANSFER_HASH =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // keccak256("Approval(address,address,uint256)")
    bytes32 internal constant _APPROVAL_HASH =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    // first 4 bytes of keccak256("InsufficientBalance()")
    bytes32 internal constant _INSUFFICIENT_BALANCE_SELECTOR =
        0xf4d678b800000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("InsufficientAllowance()")
    bytes32 internal constant _INSUFFICIENT_ALLOWANCE_SELECTOR =
        0x13be252b00000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("AddressZero()")
    bytes32 internal constant _ADDRESS_ZERO_SELECTOR =
        0x9fabe1c100000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("Overflow()")
    bytes32 internal constant _OVERFLOW_SELECTOR =
        0x35278d1200000000000000000000000000000000000000000000000000000000;

    // max 256-bit integer, i.e. 2**256-1
    bytes32 internal constant _MAX =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // token balances mapping, storage slot 0x00
    mapping(address => uint256) internal _balances;

    // token allowances nested mapping, storage slot 0x01
    mapping(address => mapping(address => uint256)) internal _allowances;

    // token total supply, storage slot 0x02
    uint256 internal _totalSupply;

    // token name string, storage slot 0x03
    string public name;

    // token symbol string, storage slot 0x04
    string public symbol;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function transfer(address dst, uint256 amount)
        external
        virtual
        returns (bool)
    {
        assembly {
            // require dst != address(0)
            if iszero(dst) {
                mstore(0x00, _ADDRESS_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }

            // get balance of msg.sender
            mstore(0x00, caller())
            mstore(0x20, 0x00)
            let srcSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcSlot)

            // require balance >= amount
            if lt(srcBalance, amount) {
                mstore(0x00, _INSUFFICIENT_BALANCE_SELECTOR)
                revert(0x00, 0x04)
            }

            // decrement by amount and store new msg.sender balance
            sstore(srcSlot, sub(srcBalance, amount))

            // get balance of dst, increment and store new dst balance
            mstore(0x00, dst)
            let dstSlot := keccak256(0x00, 0x40)
            sstore(dstSlot, add(sload(dstSlot), amount))

            // log Transfer event
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, caller(), dst)

            // return true
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    // solhint-disable-next-line function-max-lines
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool) {
        assembly {
            // require dst != address(0)
            if iszero(dst) {
                mstore(0x00, _ADDRESS_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }

            // get msg.sender allowance for src
            mstore(0x00, src)
            mstore(0x20, 0x01)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x00, 0x40)
            let allowanceVal := sload(allowanceSlot)

            // if allowance == type(uint256).max, no need to check or decrement allowance
            if lt(allowanceVal, _MAX) {
                // require allowance >= amount
                if lt(allowanceVal, amount) {
                    mstore(0x00, _INSUFFICIENT_ALLOWANCE_SELECTOR)
                    revert(0x00, 0x04)
                }

                // decrement and store new allowance
                sstore(allowanceSlot, sub(allowanceVal, amount))

                /// @notice: optionally log Approval event, CURRENTLY IGNORED
            }

            // get balance of src
            mstore(0x00, src)
            mstore(0x20, 0x00)
            let srcSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcSlot)

            // require balance >= amount
            if lt(srcBalance, amount) {
                mstore(0x00, _INSUFFICIENT_BALANCE_SELECTOR)
                revert(0x00, 0x04)
            }

            // decrement and store new balance
            sstore(srcSlot, sub(srcBalance, amount))

            // get balance of dst, increment and store new balance
            mstore(0x00, dst)
            let dstSlot := keccak256(0x00, 0x40)
            sstore(dstSlot, add(sload(dstSlot), amount))

            // log Transfer event
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, src, dst)

            // return true
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function approve(address dst, uint256 amount)
        external
        virtual
        returns (bool)
    {
        assembly {
            // store amount as dst allowance
            mstore(0x00, caller())
            mstore(0x20, 0x01)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, dst)
            sstore(keccak256(0x00, 0x40), amount)

            // log Approval event
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_HASH, caller(), dst)

            // return true
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function allowance(address src, address dst)
        public
        view
        virtual
        returns (uint256)
    {
        assembly {
            // prepare nestled mapping storage slot computation
            mstore(0x00, src)
            mstore(0x20, 0x01)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, dst)

            // load and return value at storage slot
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    function balanceOf(address src) public view virtual returns (uint256) {
        assembly {
            // load and return value at owner balance storage slot
            mstore(0x00, src)
            mstore(0x20, 0x00)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    function totalSupply() public view virtual returns (uint256) {
        assembly {
            mstore(0x00, sload(0x02))
            return(0x00, 0x20)
        }
    }

    function decimals() public pure virtual returns (uint8) {
        assembly {
            // return the constant 18 (aka 0x12)
            mstore(0x00, 0x12)
            return(0x00, 0x20)
        }
    }

    function _mint(address dst, uint256 amount) internal virtual {
        assembly {
            // get vaule in totalSupply slot, increment by amount
            let newSupply := add(amount, sload(0x02))

            // require newSupply did not overflow
            if lt(newSupply, amount) {
                mstore(0x00, _OVERFLOW_SELECTOR)
                revert(0x00, 0x04)
            }

            // store newSupply in totalSupply slot
            sstore(0x02, newSupply)

            // get balance of dst, incrememnt and store new balance
            mstore(0x00, dst)
            mstore(0x20, 0x00)
            let dstSlot := keccak256(0x00, 0x40)
            sstore(dstSlot, add(sload(dstSlot), amount))

            // log Transfer event
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, 0x00, dst)
        }
    }

    function _burn(address src, uint256 amount) internal virtual {
        assembly {
            // get src balance
            mstore(0x00, src)
            mstore(0x20, 0x00)
            let srcSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcSlot)

            // require balance >= amount
            if lt(srcBalance, amount) {
                mstore(0x00, _INSUFFICIENT_BALANCE_SELECTOR)
                revert(0x00, 0x04)
            }

            // decrement by amount and store new src balance
            sstore(srcSlot, sub(srcBalance, amount))

            // get value in totalSupply slot, decrement and store new totalSupply
            sstore(0x02, sub(sload(0x02), amount))

            // log Transfer event
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, src, 0x00)
        }
    }
}
