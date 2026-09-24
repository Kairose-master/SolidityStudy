// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRewardReceiver {
    function onReward(uint256 amount) external;
}

interface IRewardStation { function claim() external; }

contract RewardStation {
    mapping(address => bool) public claimed;
    mapping(address => uint256) public points;
    bool private locked;

    event RewardGranted(address indexed receiver, uint256 amount);
    event RewardFailed(address indexed receiver);

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function claim() external nonReentrant {
        require(!claimed[msg.sender], "Already claimed");
        require(msg.sender.code.length > 0, "Not a contract");
        uint256 previousPoints = points[msg.sender];
        claimed[msg.sender] = true;
        points[msg.sender] = previousPoints + 10;

        try IRewardReceiver(msg.sender).onReward(10) {
            emit RewardGranted(msg.sender, 10);
        } catch {
            claimed[msg.sender] = false;
            points[msg.sender] = previousPoints;
            emit RewardFailed(msg.sender);
        }
    }
}

contract TestReceiver {
    enum Mode { Accept, Reject, Reenter }
    IRewardStation public station;
    Mode public mode;

    constructor(address stationAddress) {
        require(stationAddress.code.length > 0, "Not a contract");
        station = IRewardStation(stationAddress);
    }

    // 실험용 모드 설정
    function setMode(Mode value) external { mode = value; }

    function requestReward() external { station.claim(); }

    function onReward(uint256 amount) external {
        require(msg.sender == address(station), "Not station");
        require(amount == 10, "Unexpected amount");
        if (mode == Mode.Reject) { revert("Rejected"); }
        if (mode == Mode.Reenter) { station.claim(); }
    }
}
