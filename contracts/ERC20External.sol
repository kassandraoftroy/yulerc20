// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.4;

/// @notice ERC20 (including EIP-2612 Permit) using max inline assembly.
/// NOTE ERC20External.sol enhances gas savings from ERC20.sol, trade-off is methods marked external
/// @author kassandra.eth
/// NOTE Inspiration taken from Solmate and OpenZeppelin ERC20 implementations
/// Solmate repo: https://github.com/transmissions11/solmate
/// OZ repo: https://github.com/OpenZeppelin/openzeppelin-contracts
/// @dev name_ and symbol_ string contructor args must be 32 bytes or smaller
/// Do not manually set _balances without updating _supply (could cause math problems)
/// Do not adjust state layout here without fixing hardcoded sload/sstore slots across logic
/// We use custom errors for efficient but useful reverts
/// Inline assembly blocks have solidity translation comments! (Assume same 0.8+ solidity version)
/// NOTE Many methods here marked as external (even though EIP-20 spec has them public)
/// This is because they end execution and are thus not suitable for internal use as a subroutine
/// For accessor methods internal state can be accessed directly (e.g. _balances[a] vs balanceOf(a))
/// If your ERC20 requires INTERNAL access to transfer, transferFrom, or approve etc. use ERC20.sol

// solhint-disable-next-line max-states-count
abstract contract ERC20External {
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

    // first 4 bytes of keccak256("InvalidRecipientZero()") right padded with 0s
    bytes32 internal constant _RECIPIENT_ZERO_SELECTOR =
        0x4c131ee600000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("InvalidSignature()") right padded with 0s
    bytes32 internal constant _INVALID_SIG_SELECTOR =
        0x8baa579f00000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("Expired()") right padded with 0s
    bytes32 internal constant _EXPIRED_SELECTOR =
        0x203d82d800000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("StringTooLong()") right padded with 0s
    bytes32 internal constant _STRING_TOO_LONG_SELECTOR =
        0xb11b2ad800000000000000000000000000000000000000000000000000000000;

    // first 4 bytes of keccak256("Overflow()") right padded with 0s
    bytes32 internal constant _OVERFLOW_SELECTOR =
        0x35278d1200000000000000000000000000000000000000000000000000000000;

    // solhint-disable-next-line max-line-length
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant _EIP712_DOMAIN_PREFIX_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // solhint-disable-next-line max-line-length
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 internal constant _PERMIT_HASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // keccak256("1")
    bytes32 internal constant _VERSION_1_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // max 256-bit integer, i.e. 2**256-1
    bytes32 internal constant _MAX =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // token name, stored in an immutable bytes32 (constructor arg must be <=32 byte string)
    bytes32 internal immutable _name;

    // token symbol, stored in an immutable bytes32 (constructor arg must be <=32 byte string)
    bytes32 internal immutable _symbol;

    // token name string length
    uint256 internal immutable _nameLen;

    // token symbol string length
    uint256 internal immutable _symbolLen;

    // initial block.chainid, only changes in a future hardfork scenario
    uint256 internal immutable _initialChainId;

    // initial domain separator, only changes in a future hardfork scenario
    bytes32 internal immutable _initialDomainSeparator;

    // token balances mapping, storage slot 0x00
    mapping(address => uint256) internal _balances;

    // token allowances mapping (owner=>spender=>amount), storage slot 0x01
    mapping(address => mapping(address => uint256)) internal _allowances;

    // token total supply, storage slot 0x02
    uint256 internal _supply;

    // permit nonces, storage slot 0x03
    mapping(address => uint256) internal _nonces;

    event Transfer(address indexed src, address indexed dst, uint256 amount);

    event Approval(address indexed src, address indexed dst, uint256 amount);

    constructor(string memory name_, string memory symbol_) {
        /// @dev constructor in solidity bc cannot handle immutables with inline assembly
        /// also, constructor gas optimization not really important (one time cost)

        // get string lengths
        bytes memory nameB = bytes(name_);
        bytes memory symbolB = bytes(symbol_);
        uint256 nameLen = nameB.length;
        uint256 symbolLen = symbolB.length;

        // check strings are <=32 bytes
        assembly {
            if or(lt(0x20, nameLen), lt(0x20, symbolLen)) {
                mstore(0x00, _STRING_TOO_LONG_SELECTOR)
                revert(0x00, 0x04)
            }
        }

        // compute domain separator
        bytes32 initialDomainSeparator = _computeDomainSeparator(
            keccak256(nameB)
        );

        // set immutables
        _name = bytes32(nameB);
        _symbol = bytes32(symbolB);
        _nameLen = nameLen;
        _symbolLen = symbolLen;
        _initialChainId = block.chainid;
        _initialDomainSeparator = initialDomainSeparator;
    }

    function transfer(address dst, uint256 amount)
        external
        virtual
        returns (bool)
    {
        assembly {
            // require(dst != address(0), "Address Zero");
            if iszero(dst) {
                mstore(0x00, _RECIPIENT_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }

            // _balances[msg.sender] -= amount;
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

            // emit Transfer(msg.sender, dst, amount);
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
                mstore(0x00, _RECIPIENT_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }

            // uint256 allowanceVal = _allowances[msg.sender][dst];
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
        external
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

    function balanceOf(address src) external view virtual returns (uint256) {
        assembly {
            // return _balances[src];
            mstore(0x00, src)
            mstore(0x20, 0x00)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    function nonces(address src) external view virtual returns (uint256) {
        assembly {
            // return nonces[src];
            mstore(0x00, src)
            mstore(0x20, 0x03)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    function totalSupply() external view virtual returns (uint256) {
        assembly {
            // return _supply;
            mstore(0x00, sload(0x02))
            return(0x00, 0x20)
        }
    }

    function name() external view virtual returns (string memory) {
        bytes32 myName = _name;
        uint256 myNameLen = _nameLen;
        assembly {
            // return string(bytes(_name));
            mstore(0x00, 0x20)
            mstore(0x20, myNameLen)
            mstore(0x40, myName)
            return(0x00, 0x60)
        }
    }

    function symbol() external view virtual returns (string memory) {
        bytes32 mySymbol = _symbol;
        uint256 mySymbolLen = _symbolLen;
        assembly {
            // return string(bytes(_symbol));
            mstore(0x00, 0x20)
            mstore(0x20, mySymbolLen)
            mstore(0x40, mySymbol)
            return(0x00, 0x60)
        }
    }

    function decimals() external pure virtual returns (uint8) {
        assembly {
            // return 18;
            mstore(0x00, 0x12)
            return(0x00, 0x20)
        }
    }

    // solhint-disable-next-line function-max-lines
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        assembly {
            // require(deadline >= block.timestamp, "Expired");
            if gt(timestamp(), deadline) {
                mstore(0x00, _EXPIRED_SELECTOR)
                revert(0x00, 0x04)
            }
        }

        bytes32 separator = DOMAIN_SEPARATOR();

        assembly {
            // uint256 nonce = _nonces[owner];
            mstore(0x00, owner)
            mstore(0x20, 0x03)
            let nonceSlot := keccak256(0x00, 0x40)
            let nonce := sload(nonceSlot)

            // bytes32 innerHash =
            //     keccak256(abi.encode(_PERMIT_HASH, owner, spender, value, nonce, deadline))
            let memptr := mload(0x40)
            mstore(memptr, _PERMIT_HASH)
            mstore(add(memptr, 0x20), owner)
            mstore(add(memptr, 0x40), spender)
            mstore(add(memptr, 0x60), value)
            mstore(add(memptr, 0x80), nonce)
            mstore(add(memptr, 0xA0), deadline)
            mstore(add(memptr, 0x22), keccak256(memptr, 0xC0))

            // bytes32 hash = keccak256(abi.encodePacked("\x19\x01", separator, innerHash))
            mstore8(memptr, 0x19)
            mstore8(add(memptr, 0x01), 0x01)
            mstore(add(memptr, 0x02), separator)
            mstore(memptr, keccak256(memptr, 0x42))

            // address recovered = ecrecover(hash, v, r, s)
            mstore(add(memptr, 0x20), v)
            mstore(add(memptr, 0x40), r)
            mstore(add(memptr, 0x60), s)

            if iszero(staticcall(not(0x00), 0x01, memptr, 0x80, memptr, 0x20)) {
                revert(0x00, 0x00)
            }

            let size := returndatasize()
            returndatacopy(memptr, 0, size)
            let recovered := mload(memptr)

            // require(recovered != address(0) && recovered == owner, "Invalid Signature");
            if or(iszero(recovered), iszero(eq(recovered, owner))) {
                mstore(0x00, _INVALID_SIG_SELECTOR)
                revert(0x00, 0x04)
            }

            // unchecked { _nonces[owner] += 1 }
            sstore(nonceSlot, add(nonce, 0x01))

            // _allowances[recovered][spender] = value;
            mstore(0x00, recovered)
            mstore(0x20, 0x01)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender)
            sstore(keccak256(0x00, 0x40), value)

            // emit Approval
            mstore(0x00, value)
            log3(0x00, 0x20, _APPROVAL_HASH, recovered, spender)
        }
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == _initialChainId
                ? _initialDomainSeparator
                : _computeDomainSeparator(keccak256(abi.encode(_name)));
    }

    function _mint(address dst, uint256 amount) internal virtual {
        assembly {
            // require(dst != address(0), "Address Zero");
            if iszero(dst) {
                mstore(0x00, _RECIPIENT_ZERO_SELECTOR)
                revert(0x00, 0x04)
            }

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

    function _computeDomainSeparator(bytes32 nameHash)
        internal
        view
        virtual
        returns (bytes32 domainSeparator)
    {
        assembly {
            let memptr := mload(0x40)
            mstore(memptr, _EIP712_DOMAIN_PREFIX_HASH)
            mstore(add(memptr, 0x20), nameHash)
            mstore(add(memptr, 0x40), _VERSION_1_HASH)
            mstore(add(memptr, 0x60), chainid())
            mstore(add(memptr, 0x80), address())
            domainSeparator := keccak256(memptr, 0x100)
        }
    }
}
