// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PlayerRegistry {
    mapping(address => bool) public registered;
    mapping(address => uint256) public gold;
    mapping(address => mapping(address => bool)) public duelPermission;

    function register() public returns (bool, uint256) {
        registered[msg.sender] = true;
        gold[msg.sender] = 100;
        return (registered[msg.sender], gold[msg.sender]);
    }

    function addGold(uint256 amount) public returns (uint256) {
        gold[msg.sender] = gold[msg.sender] + amount;
        return gold[msg.sender];
    }

    function setDuelPermission(address opponent, bool allowed) public {
        duelPermission[msg.sender][opponent] = allowed;
    }

    function canDuel(address playerOne, address playerTwo)
        public
        view
        returns (bool)
    {
        return
            duelPermission[playerOne][playerTwo] &&
            duelPermission[playerTwo][playerOne];
    }

    function removeMyProfile() public {
        delete gold[msg.sender];
        delete registered[msg.sender];
    }
}
