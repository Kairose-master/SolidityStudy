// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721Receiver} from "@openzeppelin/contracts@5.4.0/token/ERC721/IERC721Receiver.sol";
import {AuditArenaMini} from "../src/AuditArenaMini.sol";
import {DemoGameToken, DemoHeroNFT} from "../src/DemoTokens.sol";

interface Vm {
    function startPrank(address sender) external;
    function stopPrank() external;
    function prank(address sender) external;
    function expectRevert() external;
}

contract ReenteringHeroReceiver is IERC721Receiver {
    AuditArenaMini public immutable arena;
    uint256 public immutable matchId;
    bool public reentryBlocked;

    constructor(AuditArenaMini arena_, uint256 matchId_) {
        arena = arena_;
        matchId = matchId_;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        (bool success, bytes memory data) =
            address(arena).call(abi.encodeCall(arena.claimHero, (matchId, address(this))));
        bytes4 reason;
        if (!success && data.length >= 4) {
            assembly {
                reason := mload(add(data, 32))
            }
        }
        reentryBlocked = reason == bytes4(keccak256("ReentrancyGuardReentrantCall()"));
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract AuditArenaMiniTest {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    address private constant ALICE = address(0xA11CE);
    address private constant BOB = address(0xB0B);
    uint256 private constant FEE = 10 ether;

    DemoGameToken private token;
    DemoHeroNFT private nft;
    AuditArenaMini private arena;

    function setUp() public {
        token = new DemoGameToken(ALICE, 1_000 ether);
        nft = new DemoHeroNFT();
        nft.mint(ALICE); // hero 1
        nft.mint(BOB); // hero 2
        arena = new AuditArenaMini(token, nft, FEE);

        vm.prank(ALICE);
        token.transfer(BOB, 100 ether);
    }

    function testFullDuelPaysWinnerAndReturnsBothHeroes() public {
        _createAsAlice();
        _joinAsBob();

        AuditArenaMini.MatchData memory game = arena.getMatch(1);
        require(game.status == AuditArenaMini.MatchStatus.Active, "not active");
        require(game.currentTurn == ALICE, "wrong opening turn");
        require(arena.totalEscrowedFees() == 2 * FEE, "fee accounting wrong");

        vm.expectRevert();
        vm.prank(BOB);
        arena.attack(1);

        vm.prank(ALICE);
        arena.attack(1);
        vm.prank(BOB);
        arena.attack(1);
        vm.prank(ALICE);
        arena.attack(1);
        vm.prank(BOB);
        arena.attack(1);
        vm.prank(ALICE);
        arena.attack(1);
        vm.prank(BOB);
        arena.attack(1);
        vm.prank(ALICE);
        arena.attack(1);

        game = arena.getMatch(1);
        require(game.status == AuditArenaMini.MatchStatus.Finished, "not finished");
        require(game.winner == ALICE, "wrong winner");
        require(game.hpTwo == 0 && game.hpOne == 25, "wrong HP");
        require(arena.pendingRewards(ALICE) == 2 * FEE, "wrong prize credit");
        require(arena.totalEscrowedFees() == 0, "fee escrow not cleared");

        uint256 beforeBalance = token.balanceOf(ALICE);
        vm.prank(ALICE);
        arena.claimReward();
        require(token.balanceOf(ALICE) == beforeBalance + 2 * FEE, "prize not paid");
        require(arena.pendingRewards(ALICE) == 0, "prize not cleared");

        vm.prank(ALICE);
        arena.claimHero(1, ALICE);
        vm.prank(BOB);
        arena.claimHero(1, BOB);
        require(nft.ownerOf(1) == ALICE && nft.ownerOf(2) == BOB, "heroes not returned");
    }

    function testCreatorCanCancelAndPullRefundAndHero() public {
        _createAsAlice();

        vm.expectRevert();
        vm.prank(BOB);
        arena.cancelMatch(1);

        vm.prank(ALICE);
        arena.cancelMatch(1);
        require(arena.pendingRewards(ALICE) == FEE, "refund credit wrong");
        require(arena.totalEscrowedFees() == 0, "escrow not cleared");

        vm.prank(ALICE);
        arena.claimReward();
        vm.prank(ALICE);
        arena.claimHero(1, ALICE);
        require(nft.ownerOf(1) == ALICE, "cancelled hero not returned");
    }

    function testJoinRollsBackFeeAndMatchStateWhenNFTApprovalIsMissing() public {
        _createAsAlice();
        vm.prank(BOB);
        token.approve(address(arena), FEE);
        uint256 bobBalance = token.balanceOf(BOB);

        vm.expectRevert();
        vm.prank(BOB);
        arena.joinMatch(1, 2); // Bob deliberately did not approve the NFT.

        require(token.balanceOf(BOB) == bobBalance, "ERC20 fee did not roll back");
        require(nft.ownerOf(2) == BOB, "Bob NFT unexpectedly moved");
        require(arena.totalEscrowedFees() == FEE, "fee ledger changed");
        require(arena.getMatch(1).status == AuditArenaMini.MatchStatus.WaitingForOpponent, "match changed");
    }

    function testRecipientReentryIsBlockedWhileClaimingHero() public {
        _createAsAlice();
        _joinAsBob();
        for (uint256 i = 0; i < 6; i++) {
            vm.prank(i % 2 == 0 ? ALICE : BOB);
            arena.attack(1);
        }
        vm.prank(ALICE);
        arena.attack(1);

        ReenteringHeroReceiver receiver = new ReenteringHeroReceiver(arena, 1);
        vm.prank(ALICE);
        arena.claimHero(1, address(receiver));

        require(receiver.reentryBlocked(), "reentrant call was not blocked");
        require(nft.ownerOf(1) == address(receiver), "hero claim did not complete");
        require(arena.getMatch(1).heroOneClaimed, "claim state missing");
    }

    function _createAsAlice() private {
        vm.startPrank(ALICE);
        token.approve(address(arena), FEE);
        nft.approve(address(arena), 1);
        uint256 id = arena.createMatch(1);
        vm.stopPrank();
        require(id == 1, "unexpected match ID");
        require(nft.ownerOf(1) == address(arena), "Alice hero not escrowed");
        require(arena.activeMatchOf(ALICE) == 1, "Alice match missing");
    }

    function _joinAsBob() private {
        vm.startPrank(BOB);
        token.approve(address(arena), FEE);
        nft.approve(address(arena), 2);
        arena.joinMatch(1, 2);
        vm.stopPrank();
        require(nft.ownerOf(2) == address(arena), "Bob hero not escrowed");
        require(arena.activeMatchOf(BOB) == 1, "Bob match missing");
    }
}
