// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice The tiny game contract called by MiniAccount through EntryPoint.
contract DemoCounter {
    uint256 public count;

    event Incremented(address indexed caller, uint256 newCount);

    function increment() external {
        count += 1;
        emit Incremented(msg.sender, count);
    }
}
