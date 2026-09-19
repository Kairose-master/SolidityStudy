// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GameConfig {
    string public gameName = "Audit Arena";
    uint8 public maxPlayers = 200;
    uint16 internal startingGold = 10_000;
    int32 private seasonScore = -250;
    bool public paused = false;
    address public admin = msg.sender; // The deployer is captured during initialization.
    bytes32 private rulesetId = "RULESET_V1";
}
