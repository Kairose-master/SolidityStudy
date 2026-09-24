// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRewardReceiver { function onReward() external; }
interface IRewardTarget { function claim() external; }

// 의도적으로 취약한 학습 예제
contract VulnerableRewardLab {
    mapping(address => bool) public claimed;
    mapping(address => uint256) public points;

    function claim() external {
        require(!claimed[msg.sender], "Already claimed");
        points[msg.sender] += 10;
        IRewardReceiver(msg.sender).onReward();
        claimed[msg.sender] = true;
    }
}

contract CEIRewardLab {
    mapping(address => bool) public claimed;
    mapping(address => uint256) public points;

    function claim() external {
        require(!claimed[msg.sender], "Already claimed");
        claimed[msg.sender] = true;
        points[msg.sender] += 10;
        IRewardReceiver(msg.sender).onReward();
    }
}

contract ReenterLab {
    IRewardTarget public target;
    bool private reentered;

    constructor(address targetAddress) {
        target = IRewardTarget(targetAddress);
    }

    function attack() external { target.claim(); }

    function onReward() external {
        require(msg.sender == address(target), "Not target");
        if (!reentered) {
            reentered = true;
            target.claim();
        }
    }
}
