// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.4;

/// @notice ERC20 with max inline assembly. Comments in assembly blocks are solidity translations
/// @author kassandra.eth
/// @dev Do not manually set _balances without updating _supply. If modifying this source, do not
/// prepend state variables without adjusting hardcoded storage slots across implementation.
/// Custom errors for efficient but useful reverts.
/// Solidity translation comments assume same 0.8+ solidity version.

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

    // first 4 bytes of keccak256("InsufficientBalance()") right padded with 0s
    bytes32 internal constant _INSUFFICIENT_BALANCE_SELECTOR =
        0xf4d678b800000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("InsufficientAllowance()") right padded with 0s
    bytes32 internal constant _INSUFFICIENT_ALLOWANCE_SELECTOR =
        0x13be252b00000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("AddressZero()") right padded with 0s
    bytes32 internal constant _ADDRESS_ZERO_SELECTOR =
        0x9fabe1c100000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("Overflow()") right padded with 0s
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
    uint256 internal _supply;

    // token name string, storage slot 0x03 - enforce short string in constructor
    string internal _name;

    // token symbol string, storage slot 0x04 - enforce short string in constructor
    string internal _symbol;

    constructor(string memory name_, string memory symbol_) {
        // require strings are short
        require(bytes(name_).length < 32 && bytes(symbol_).length < 32);
        _name = name_;
        _symbol = symbol_;
    }

    function transfer(address dst, uint256 amount)
        external
        virtual
        returns (bool)
    {
        assembly {
            // require(dst != address(0), "Address Zero");
            if iszero(dst) {
                mstore(0x00, _ADDRESS_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }

            // _balances[src] -= amount;
            mstore(0x00, caller())
            mstore(0x20, 0x00)
            let srcSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcSlot)

            if lt(srcBalance, amount) {
                mstore(0x00, _INSUFFICIENT_BALANCE_SELECTOR)
                revert(0x00, 0x04)
            }

            sstore(srcSlot, sub(srcBalance, amount))

            // unchecked { _balances[dst] += amount; }
            mstore(0x00, dst)
            let dstSlot := keccak256(0x00, 0x40)
            sstore(dstSlot, add(sload(dstSlot), amount))

            // emit Transfer(src, dst, amount);
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, caller(), dst)

            // return true;
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
            // require(dst != address(0), "Address Zero");
            if iszero(dst) {
                mstore(0x00, _ADDRESS_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }

            // uint256 allowance = _allowances[msg.sender][dst];
            mstore(0x00, src)
            mstore(0x20, 0x01)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x00, 0x40)
            let allowanceVal := sload(allowanceSlot)

            // if (allowanceVal != _MAX) _allowances[msg.sender][dst] = allowanceVal - amount;
            if lt(allowanceVal, _MAX) {
                if lt(allowanceVal, amount) {
                    mstore(0x00, _INSUFFICIENT_ALLOWANCE_SELECTOR)
                    revert(0x00, 0x04)
                }

                sstore(allowanceSlot, sub(allowanceVal, amount))

                /// @dev NOTE not logging Approval event here, OZ impl does
            }

            // _balances[src] -= amount;
            mstore(0x00, src)
            mstore(0x20, 0x00)
            let srcSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcSlot)

            if lt(srcBalance, amount) {
                mstore(0x00, _INSUFFICIENT_BALANCE_SELECTOR)
                revert(0x00, 0x04)
            }

            sstore(srcSlot, sub(srcBalance, amount))

            // unchecked { _balances[dst] += amount; }
            mstore(0x00, dst)
            let dstSlot := keccak256(0x00, 0x40)
            sstore(dstSlot, add(sload(dstSlot), amount))

            // emit Transfer(src, dst, amount);
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, src, dst)

            // return true;
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
            // _allowances[msg.sender][dst] = amount;
            mstore(0x00, caller())
            mstore(0x20, 0x01)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, dst)
            sstore(keccak256(0x00, 0x40), amount)

            // emit Approval(msg.sender, dst, amount);
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_HASH, caller(), dst)

            // return true;
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
            // return _allowances[src][dst];
            mstore(0x00, src)
            mstore(0x20, 0x01)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, dst)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    function balanceOf(address src) public view virtual returns (uint256) {
        assembly {
            // return _balances[src];
            mstore(0x00, src)
            mstore(0x20, 0x00)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    function totalSupply() public view virtual returns (uint256) {
        assembly {
            // return _supply;
            mstore(0x00, sload(0x02))
            return(0x00, 0x20)
        }
    }

    function name() public view virtual returns (string memory) {
        assembly {
            // return _name;
            /// @dev NOTE below only works if _name string is guaranteed to be < 32 bytes
            let nameData := sload(0x03)
            let nameLenByte := and(nameData, 0xff)
            mstore(0x00, 0x20)
            mstore(0x20, div(nameLenByte, 0x02))
            mstore(0x40, sub(nameData, nameLenByte))
            return(0x00, 0x60)
        }
    }

    function symbol() public view virtual returns (string memory) {
        assembly {
            // return _symbol;
            /// @dev NOTE below only works if _symbol string is guaranteed to <32 bytes
            let symbolData := sload(0x04)
            let symbolLenByte := and(symbolData, 0xff)
            mstore(0x00, 0x20)
            mstore(0x20, div(symbolLenByte, 0x02))
            mstore(0x40, sub(symbolData, symbolLenByte))
            return(0x00, 0x60)
        }
    }

    function decimals() public pure virtual returns (uint8) {
        assembly {
            // return 18;
            mstore(0x00, 0x12)
            return(0x00, 0x20)
        }
    }

    function _mint(address dst, uint256 amount) internal virtual {
        assembly {
            // _supply += amount;
            let newSupply := add(amount, sload(0x02))

            if lt(newSupply, amount) {
                mstore(0x00, _OVERFLOW_SELECTOR)
                revert(0x00, 0x04)
            }

            sstore(0x02, newSupply)

            // unchecked { _balances[dst] += amount; }
            mstore(0x00, dst)
            mstore(0x20, 0x00)
            let dstSlot := keccak256(0x00, 0x40)
            sstore(dstSlot, add(sload(dstSlot), amount))

            // emit Transfer(address(0), dst, amount);
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, 0x00, dst)
        }
    }

    function _burn(address src, uint256 amount) internal virtual {
        assembly {
            // _balances[src] -= amount;
            mstore(0x00, src)
            mstore(0x20, 0x00)
            let srcSlot := keccak256(0x00, 0x40)
            let srcBalance := sload(srcSlot)

            if lt(srcBalance, amount) {
                mstore(0x00, _INSUFFICIENT_BALANCE_SELECTOR)
                revert(0x00, 0x04)
            }

            sstore(srcSlot, sub(srcBalance, amount))

            // unchecked { _supply -= amount; }
            sstore(0x02, sub(sload(0x02), amount))

            // emit Transfer(src, address(0), amount);
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_HASH, src, 0x00)
        }
    }
}
