// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Arena {
    address public owner;
    bool public paused;

    mapping(address => bool) public moderators;
    mapping(address => bool) public banned;
    mapping(address => bool) public entered;

    event ModeratorUpdated(address indexed account, bool allowed);
    event PauseUpdated(bool paused);
    event BanUpdated(address indexed player, bool banned);
    event ArenaEntered(address indexed player);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyModerator() {
        require(msg.sender == owner || moderators[msg.sender], "Not moderator");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Arena is paused");
        _;
    }

    modifier notBanned(address player) {
        require(!banned[player], "Player banned");
        _;
    }

    function setModerator(address account, bool allowed) public onlyOwner {
        require(account != address(0), "address unset");
        moderators[account] = allowed;
        emit ModeratorUpdated(account, allowed);
    }

    function setPaused(bool value) public onlyOwner {
        paused = value;
        emit PauseUpdated(value);
    }

    function setBanned(address player, bool value) public onlyModerator {
        require(player != address(0), "address is unset");
        banned[player] = value;
        emit BanUpdated(player, value);
    }

    function enterArena()
        public
        whenNotPaused
        notBanned(msg.sender)
        returns (bool)
    {
        require(!entered[msg.sender], "already entered");
        entered[msg.sender] = true;
        emit ArenaEntered(msg.sender);
        return true;
    }
}
