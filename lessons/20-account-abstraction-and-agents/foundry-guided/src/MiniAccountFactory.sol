// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEntryPoint} from "@account-abstraction/interfaces/IEntryPoint.sol";
import {ISenderCreator} from "@account-abstraction/interfaces/ISenderCreator.sol";
import {MiniAccount} from "./MiniAccount.sol";

/**
 * @notice CREATE2 Factory for the learning account.
 */
contract MiniAccountFactory {
    IEntryPoint public immutable entryPoint;
    ISenderCreator public immutable senderCreator;

    error OnlySenderCreator();

    constructor(IEntryPoint entryPoint_) {
        entryPoint = entryPoint_;
        senderCreator = entryPoint_.senderCreator();
    }

    function getAddress(
        address owner,
        uint256 salt
    ) public view returns (address predicted) {
        bytes32 initCodeHash = keccak256(
            abi.encodePacked(
                type(MiniAccount).creationCode,
                abi.encode(owner, entryPoint)
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                bytes32(salt),
                initCodeHash
            )
        );
        predicted = address(uint160(uint256(digest)));
    }

    /**
     * EntryPoint calls SenderCreator, which calls this function.
     * Direct calls from users are intentionally rejected.
     */
    function createAccount(
        address owner,
        uint256 salt
    ) external returns (MiniAccount account) {
        if (msg.sender != address(senderCreator)) revert OnlySenderCreator();

        address predicted = getAddress(owner, salt);
        if (predicted.code.length != 0) {
            return MiniAccount(payable(predicted));
        }

        account = new MiniAccount{salt: bytes32(salt)}(owner, entryPoint);
        require(address(account) == predicted, "unexpected account address");
    }
}
