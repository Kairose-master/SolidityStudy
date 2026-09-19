// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ArenaTreasury {
    uint256 public entryFee = 0.01 ether;
    uint256 public totalDeposited = 0;

    function calculateReward(uint256 wins, uint256 rewardPerWin)
        public
        pure
        returns (uint256)
    {
        return wins * rewardPerWin;
    }

    function quoteEntry(uint256 players) public view returns (uint256) {
        return entryFee * players;
    }

    function depositEntryFee() public payable returns (uint256) {
        totalDeposited = totalDeposited + msg.value;
        return totalDeposited;
    }

    function treasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
