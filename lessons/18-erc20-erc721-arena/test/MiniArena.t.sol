// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MiniArena, IGameToken, IHeroNFT} from "../MiniArena.sol";
import {DemoGameToken, DemoHeroNFT} from "../DemoTokens.sol";

interface Vm {
    function startPrank(address sender) external;
    function stopPrank() external;
    function prank(address sender) external;
    function expectRevert() external;
}

contract MiniArenaTest {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    address private constant ALICE = address(0xA11CE);
    address private constant TREASURY = address(0xBEEF);
    uint256 private constant ENTRY_FEE = 10 ether;

    DemoGameToken private gameToken;
    DemoHeroNFT private heroNFT;
    MiniArena private arena;

    function setUp() public {
        gameToken = new DemoGameToken(ALICE, 100 ether);
        heroNFT = new DemoHeroNFT();
        heroNFT.mint(ALICE); // tokenId 1
        arena = new MiniArena(
            IGameToken(address(gameToken)),
            IHeroNFT(address(heroNFT)),
            TREASURY,
            ENTRY_FEE
        );
    }

    function testDepositAndWithdrawRoundTrip() public {
        vm.startPrank(ALICE);
        gameToken.approve(address(arena), ENTRY_FEE);
        heroNFT.approve(address(arena), 1);
        arena.enterArena(1);
        vm.stopPrank();

        require(gameToken.balanceOf(TREASURY) == ENTRY_FEE, "fee not paid");
        require(heroNFT.ownerOf(1) == address(arena), "NFT not escrowed");
        require(arena.heroOf(ALICE) == 1, "player mapping missing");
        require(arena.playerOfHero(1) == ALICE, "hero mapping missing");
        require(arena.isInArena(ALICE), "player not marked in arena");

        vm.prank(ALICE);
        arena.leaveArena();

        require(heroNFT.ownerOf(1) == ALICE, "NFT not returned");
        require(!arena.isInArena(ALICE), "arena status not cleared");
        require(arena.heroOf(ALICE) == 0, "player mapping not cleared");
        require(arena.playerOfHero(1) == address(0), "hero mapping not cleared");
    }

    function testMissingNftApprovalRollsBackEntryFeeAndState() public {
        vm.prank(ALICE);
        gameToken.approve(address(arena), ENTRY_FEE);

        vm.expectRevert();
        vm.prank(ALICE);
        arena.enterArena(1);

        require(gameToken.balanceOf(TREASURY) == 0, "fee transfer was not rolled back");
        require(heroNFT.ownerOf(1) == ALICE, "NFT unexpectedly moved");
        require(!arena.isInArena(ALICE), "arena state was not rolled back");
    }

    function testPlayerCannotDepositSecondHeroAtSameTime() public {
        heroNFT.mint(ALICE); // tokenId 2

        vm.startPrank(ALICE);
        gameToken.approve(address(arena), ENTRY_FEE);
        heroNFT.approve(address(arena), 1);
        arena.enterArena(1);
        heroNFT.approve(address(arena), 2);
        vm.expectRevert();
        arena.enterArena(2);
        vm.stopPrank();

        require(heroNFT.ownerOf(2) == ALICE, "second NFT unexpectedly moved");
    }
}
