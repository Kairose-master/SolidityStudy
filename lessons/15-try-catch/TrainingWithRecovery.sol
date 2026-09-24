// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IScoreBoard} from "../../submissions/SOL-014/TrainingGame.sol";

contract TrainingWithRecovery {
    IScoreBoard public board;
    mapping(address => bool) public trained;
    event TrainingSucceeded(address indexed player);
    event TrainingFailed(address indexed player, string reason);

    constructor(address boardAddress) {
        require(boardAddress.code.length > 0, "Not a contract");
        board = IScoreBoard(boardAddress);
    }

    function train() external {
        require(!trained[msg.sender], "Already trained");
        trained[msg.sender] = true;
        try board.addScore(msg.sender, 10) {
            emit TrainingSucceeded(msg.sender);
        } catch Error(string memory reason) {
            trained[msg.sender] = false;
            emit TrainingFailed(msg.sender, reason);
        } catch {
            trained[msg.sender] = false;
            emit TrainingFailed(msg.sender, "Unknown error");
        }
    }

    function myScore() external view returns (uint256) {
        return board.scores(msg.sender);
    }
}
