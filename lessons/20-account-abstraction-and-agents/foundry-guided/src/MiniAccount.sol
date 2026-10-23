// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseAccount} from "@account-abstraction/core/BaseAccount.sol";
import {IEntryPoint} from "@account-abstraction/interfaces/IEntryPoint.sol";
import {
    SIG_VALIDATION_FAILED,
    SIG_VALIDATION_SUCCESS
} from "@account-abstraction/core/Helpers.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice 학습용 단일 소유자 ERC-4337 계정.
 * @dev EntryPoint 호출·nonce 확인·prefund 송금은 BaseAccount가 처리한다.
 *      이 계정은 execute 권한을 EntryPoint 호출로만 제한한다.
 */
contract MiniAccount is BaseAccount {
    address public immutable owner;
    IEntryPoint private immutable _entryPoint;

    constructor(address owner_, IEntryPoint entryPoint_) {
        require(owner_ != address(0), "zero owner");
        owner = owner_;
        _entryPoint = entryPoint_;
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view override returns (uint256) {
        address recovered = ECDSA.recover(userOpHash, userOp.signature);
        return recovered == owner
            ? SIG_VALIDATION_SUCCESS
            : SIG_VALIDATION_FAILED;
    }
}
