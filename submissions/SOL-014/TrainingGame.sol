// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IScoreBoard {
    function addScore(address player, uint256 amount) external;
    function scores(address player) external view returns (uint256);
}

contract TrainingGame {
    IScoreBoard public board;
    mapping(address => bool) public trained;

    constructor(address boardAddress) {
        require(boardAddress.code.length > 0, "Not a contract");
        board = IScoreBoard(boardAddress);
    }

    function train() external {
        require(!trained[msg.sender]);
        trained[msg.sender] = true;
        board.addScore(msg.sender, 10);
    }

    function myScore() external view returns (uint256) {
        return board.scores(msg.sender);
    }
}
