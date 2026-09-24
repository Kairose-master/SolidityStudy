// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract DeadlineLab {
    uint256 public deadline;
    bool public closed;
    mapping(address => bool) public entered;

    constructor() {
        deadline = block.timestamp + 2 minutes;
    }

    function enter() public {
        require(block.timestamp < deadline, "Too late");
        require(!entered[msg.sender], "Already entered");
        entered[msg.sender] = true;
    }

    function close() public {
        require(block.timestamp >= deadline, "Too early");
        require(!closed, "Already closed");
        closed = true;
    }

    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }
}
