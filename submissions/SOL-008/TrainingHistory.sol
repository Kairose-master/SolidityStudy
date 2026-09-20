// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TrainingHistory {
    mapping(address => bool) public registered;
    mapping(address => uint256[]) public scores;

    event ScoresAdded(
        address indexed player,
        uint256 addedCount,
        uint256 totalCount
    );

    function register() public {
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
    }

    function addScores(uint256[] calldata newScores)
        external
        returns (uint256)
    {
        require(registered[msg.sender], "Not registered");
        require(
            newScores.length >= 1 && newScores.length <= 5,
            "Invalid batch size"
        );

        uint256[] storage myScores = scores[msg.sender];

        require(
            myScores.length + newScores.length <= 10,
            "Too many scores"
        );

        for (uint256 i = 0; i < newScores.length; i++) {
            require(
                newScores[i] >= 1 && newScores[i] <= 100,
                "Invalid score"
            );
        }

        for (uint256 i = 0; i < newScores.length; i++) {
            myScores.push(newScores[i]);
        }

        emit ScoresAdded(
            msg.sender,
            newScores.length,
            myScores.length
        );

        return myScores.length;
    }

    function removeLastScore() public returns (uint256) {
        require(registered[msg.sender], "Not registered");
        require(scores[msg.sender].length >= 1, "No score exists");

        scores[msg.sender].pop();
        return scores[msg.sender].length;
    }

    function previewDoubled(uint256[] calldata values)
        external
        pure
        returns (uint256[] memory)
    {
        require(
            values.length >= 1 && values.length <= 5,
            "Invalid batch size"
        );

        uint256[] memory doubled = new uint256[](values.length);

        for (uint256 i = 0; i < values.length; i++) {
            require(
                values[i] >= 1 && values[i] <= 50,
                "Invalid value"
            );
            doubled[i] = values[i] * 2;
        }

        return doubled;
    }
}
