// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Duelmachine {
    enum DuelState {
        None,
        Open,
        Active,
        Finished
    }

    struct Duel {
        address creator;
        address opponent;
        uint256 creatorHp;
        uint256 opponentHp;
        DuelState state;
    }

    uint256 public nextDuelId;
    mapping(uint256 => Duel) public duels;

    event DuelCreated(
        uint256 indexed duelId,
        address indexed creator
    );

    event DuelJoined(
        uint256 indexed duelId,
        address indexed opponent
    );

    event AttackResolved(
        uint256 indexed duelId,
        address indexed attacker,
        uint256 remainingHp,
        DuelState state
    );

    function createDuel() public returns (uint256) {
        uint256 duelId = nextDuelId;
        nextDuelId++;

        duels[duelId] = Duel({
            creator: msg.sender,
            opponent: address(0),
            creatorHp: 100,
            opponentHp: 0,
            state: DuelState.Open
        });

        emit DuelCreated(duelId, msg.sender);
        return duelId;
    }

    function joinDuel(uint256 duelId) public {
        Duel storage duel = duels[duelId];

        require(duel.state == DuelState.Open, "This duel is not open");
        require(duel.creator != msg.sender, "You cannot duel yourself");

        duel.opponent = msg.sender;
        duel.opponentHp = 100;
        duel.state = DuelState.Active;

        emit DuelJoined(duelId, msg.sender);
    }

    function attack(uint256 duelId, uint256 damage)
        public
        returns (uint256)
    {
        Duel storage duel = duels[duelId];

        require(duel.state == DuelState.Active, "This duel is not active");
        require(damage >= 1 && damage <= 30, "Invalid damage");

        uint256 remainingHp;

        if (duel.creator == msg.sender) {
            if (damage >= duel.opponentHp) {
                duel.opponentHp = 0;
                duel.state = DuelState.Finished;
            } else {
                duel.opponentHp -= damage;
            }

            remainingHp = duel.opponentHp;
        } else if (duel.opponent == msg.sender) {
            if (damage >= duel.creatorHp) {
                duel.creatorHp = 0;
                duel.state = DuelState.Finished;
            } else {
                duel.creatorHp -= damage;
            }

            remainingHp = duel.creatorHp;
        } else {
            revert("Invalid attacker");
        }

        emit AttackResolved(duelId, msg.sender, remainingHp, duel.state);
        return remainingHp;
    }
}
