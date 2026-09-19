// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract BattleCalculator {
    uint256 public totalDamage = 0;

    function _multiply(uint256 value, uint256 multiplier)
        internal
        pure
        returns (uint256)
    {
        return value * multiplier;
    }

    function previewAttack(uint256 baseDamage, uint256 multiplier)
        public
        pure
        returns (uint256 normalDamage, uint256 criticalDamage)
    {
        normalDamage = baseDamage;
        criticalDamage = _multiply(baseDamage, multiplier);
    }

    function recordDamage(uint256 damage) public returns (uint256) {
        totalDamage = totalDamage + damage;
        return totalDamage;
    }
}
