// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Counter {
    uint256 public count;
    address public lastCaller;

    function increment() external {
        count += 1;
        lastCaller = msg.sender;
    }
}

interface ICounter {
    function increment() external;
    function count() external view returns (uint256);
}

contract CounterCaller {
    ICounter public counter;

    constructor(address counterAddress) {
        require(counterAddress.code.length > 0, "Not a contract");
        counter = ICounter(counterAddress);
    }

    function callIncrement() external {
        counter.increment();
    }

    function readCount() external view returns (uint256) {
        return counter.count();
    }
}
