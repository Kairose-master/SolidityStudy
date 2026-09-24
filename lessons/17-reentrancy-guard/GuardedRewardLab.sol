// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRewardReceiver} from "../16-reentrancy/ReentrancyLab.sol";

contract GuardedRewardLab {
    mapping(address => bool) public claimed;
    mapping(address => uint256) public points;
    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function claim() external nonReentrant {
        require(!claimed[msg.sender], "Already claimed");
        claimed[msg.sender] = true;
        points[msg.sender] += 10;
        IRewardReceiver(msg.sender).onReward();
    }
}
