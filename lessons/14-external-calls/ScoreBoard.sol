// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ScoreBoard {
    address public owner;
    address public game;
    mapping(address => uint256) public scores;

    constructor() { owner = msg.sender; }

    function setGame(address account) external {
        require(msg.sender == owner, "Not owner");
        require(account.code.length > 0, "Not a contract");
        game = account;
    }

    function addScore(address player, uint256 amount) external {
        require(msg.sender == game, "Not game");
        require(player != address(0), "Invalid player");
        require(amount >= 1 && amount <= 10, "Invalid amount");
        scores[player] += amount;
    }
}
