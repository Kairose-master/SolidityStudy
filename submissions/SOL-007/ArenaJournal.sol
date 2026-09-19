// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ArenaJournal {
    mapping(address => bool) public registered;
    mapping(address => uint256) public wins;

    event PlayerRegistered(
        address indexed player,
        uint256 startingWins
    );

    event MatchRecorded(
        address indexed winner,
        address indexed loser,
        uint256 winnerTotalWins
    );

    function register() public {
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
        wins[msg.sender] = 0;

        emit PlayerRegistered(msg.sender, 0);
    }

    function recordWin(address loser) public returns (uint256) {
        require(registered[msg.sender], "Winner not registered");
        require(registered[loser], "Loser not registered");
        require(msg.sender != loser, "Same address");

        wins[msg.sender] += 1;

        emit MatchRecorded(msg.sender, loser, wins[msg.sender]);
        return wins[msg.sender];
    }
}
