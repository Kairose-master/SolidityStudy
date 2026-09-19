// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TrainingGround {
    mapping(address => bool) public registered;
    mapping(address => uint256) public gold;
    mapping(address => uint256) public spent;

    error InsufficientGold(uint256 available, uint256 requested);

    function register() public {
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
        gold[msg.sender] = 100;
        spent[msg.sender] = 0;
    }

    function train(uint256 amount) public returns (uint256) {
        require(registered[msg.sender], "NOT registered");
        require(amount <= 50 && amount > 0, "Too expensive");

        if (amount > gold[msg.sender]) {
            revert InsufficientGold(gold[msg.sender], amount);
        }

        gold[msg.sender] = gold[msg.sender] - amount;
        spent[msg.sender] = spent[msg.sender] + amount;

        assert(gold[msg.sender] + spent[msg.sender] == 100);
        return gold[msg.sender];
    }
}
