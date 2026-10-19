// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts@5.4.0/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts@5.4.0/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts@5.4.0/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts@5.4.0/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts@5.4.0/utils/ReentrancyGuard.sol";

/// @notice Runnable teaching implementation of the SOL-019 mini duel.
/// @dev Fixed damage and local demo tokens only; this is not production game code.
contract AuditArenaMini is IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant STARTING_HP = 100;
    uint256 public constant DAMAGE = 25;

    enum MatchStatus {
        None,
        WaitingForOpponent,
        Active,
        Finished,
        Cancelled
    }

    struct MatchData {
        address playerOne;
        address playerTwo;
        uint256 heroOneId;
        uint256 heroTwoId;
        uint256 hpOne;
        uint256 hpTwo;
        address currentTurn;
        address winner;
        MatchStatus status;
        bool heroOneClaimed;
        bool heroTwoClaimed;
    }

    IERC20 public immutable paymentToken;
    IERC721 public immutable heroToken;
    uint256 public immutable entryFee;

    uint256 public nextMatchId = 1;
    uint256 public totalEscrowedFees;
    uint256 public totalPendingRewards;

    mapping(uint256 matchId => MatchData) public matches;
    mapping(address player => uint256 matchId) public activeMatchOf;
    mapping(address player => uint256 amount) public pendingRewards;

    address private expectedDepositor;
    uint256 private expectedTokenId;
    bool private expectingNFT;

    error ZeroAddress();
    error InvalidOwner();
    error PlayerAlreadyInMatch();
    error InvalidMatchState();
    error SamePlayer();
    error NotYourTurn();
    error NotMatchCreator();
    error NotParticipant();
    error NothingToClaim();
    error HeroAlreadyClaimed();
    error InvalidRecipient();
    error UnexpectedNFT();
    error NFTCallbackMissing();

    event MatchCreated(uint256 indexed matchId, address indexed player, uint256 heroId);
    event MatchJoined(uint256 indexed matchId, address indexed player, uint256 heroId);
    event MatchStarted(uint256 indexed matchId, address indexed firstTurn);
    event AttackMade(uint256 indexed matchId, address indexed attacker, address indexed defender, uint256 remainingHp);
    event MatchFinished(uint256 indexed matchId, address indexed winner);
    event MatchCancelled(uint256 indexed matchId, address indexed player);
    event RewardClaimed(address indexed player, uint256 amount);
    event HeroClaimed(uint256 indexed matchId, address indexed player, address recipient, uint256 heroId);

    constructor(IERC20 paymentToken_, IERC721 heroToken_, uint256 entryFee_) {
        if (address(paymentToken_) == address(0) || address(heroToken_) == address(0)) {
            revert ZeroAddress();
        }
        paymentToken = paymentToken_;
        heroToken = heroToken_;
        entryFee = entryFee_;
    }

    function createMatch(uint256 heroId) external nonReentrant returns (uint256 matchId) {
        if (activeMatchOf[msg.sender] != 0) revert PlayerAlreadyInMatch();
        if (heroToken.ownerOf(heroId) != msg.sender) revert InvalidOwner();

        matchId = nextMatchId++;
        MatchData storage game = matches[matchId];
        game.playerOne = msg.sender;
        game.heroOneId = heroId;
        game.hpOne = STARTING_HP;
        game.status = MatchStatus.WaitingForOpponent;
        activeMatchOf[msg.sender] = matchId;
        totalEscrowedFees += entryFee;

        paymentToken.safeTransferFrom(msg.sender, address(this), entryFee);
        _depositHero(msg.sender, heroId);

        emit MatchCreated(matchId, msg.sender, heroId);
    }

    function joinMatch(uint256 matchId, uint256 heroId) external nonReentrant {
        MatchData storage game = matches[matchId];
        if (game.status != MatchStatus.WaitingForOpponent) revert InvalidMatchState();
        if (msg.sender == game.playerOne) revert SamePlayer();
        if (activeMatchOf[msg.sender] != 0) revert PlayerAlreadyInMatch();
        if (heroToken.ownerOf(heroId) != msg.sender) revert InvalidOwner();

        game.playerTwo = msg.sender;
        game.heroTwoId = heroId;
        game.hpTwo = STARTING_HP;
        game.currentTurn = game.playerOne;
        game.status = MatchStatus.Active;
        activeMatchOf[msg.sender] = matchId;
        totalEscrowedFees += entryFee;

        paymentToken.safeTransferFrom(msg.sender, address(this), entryFee);
        _depositHero(msg.sender, heroId);

        emit MatchJoined(matchId, msg.sender, heroId);
        emit MatchStarted(matchId, game.currentTurn);
    }

    function attack(uint256 matchId) external {
        MatchData storage game = matches[matchId];
        if (game.status != MatchStatus.Active) revert InvalidMatchState();
        if (game.currentTurn != msg.sender) revert NotYourTurn();

        address defender;
        uint256 remainingHp;
        if (msg.sender == game.playerOne) {
            defender = game.playerTwo;
            game.hpTwo -= DAMAGE;
            remainingHp = game.hpTwo;
        } else {
            defender = game.playerOne;
            game.hpOne -= DAMAGE;
            remainingHp = game.hpOne;
        }

        emit AttackMade(matchId, msg.sender, defender, remainingHp);

        if (remainingHp == 0) {
            game.status = MatchStatus.Finished;
            game.winner = msg.sender;
            game.currentTurn = address(0);
            activeMatchOf[game.playerOne] = 0;
            activeMatchOf[game.playerTwo] = 0;

            uint256 prize = entryFee * 2;
            totalEscrowedFees -= prize;
            pendingRewards[msg.sender] += prize;
            totalPendingRewards += prize;
            emit MatchFinished(matchId, msg.sender);
        } else {
            game.currentTurn = defender;
        }
    }

    function cancelMatch(uint256 matchId) external {
        MatchData storage game = matches[matchId];
        if (game.status != MatchStatus.WaitingForOpponent) revert InvalidMatchState();
        if (game.playerOne != msg.sender) revert NotMatchCreator();

        game.status = MatchStatus.Cancelled;
        activeMatchOf[msg.sender] = 0;
        totalEscrowedFees -= entryFee;
        pendingRewards[msg.sender] += entryFee;
        totalPendingRewards += entryFee;

        emit MatchCancelled(matchId, msg.sender);
    }

    function claimReward() external nonReentrant {
        uint256 amount = pendingRewards[msg.sender];
        if (amount == 0) revert NothingToClaim();

        pendingRewards[msg.sender] = 0;
        totalPendingRewards -= amount;
        paymentToken.safeTransfer(msg.sender, amount);

        emit RewardClaimed(msg.sender, amount);
    }

    function claimHero(uint256 matchId, address recipient) external nonReentrant {
        if (recipient == address(0) || recipient == address(this)) revert InvalidRecipient();
        MatchData storage game = matches[matchId];
        if (game.status != MatchStatus.Finished && game.status != MatchStatus.Cancelled) {
            revert InvalidMatchState();
        }

        uint256 heroId;
        if (msg.sender == game.playerOne) {
            if (game.heroOneClaimed) revert HeroAlreadyClaimed();
            game.heroOneClaimed = true;
            heroId = game.heroOneId;
        } else if (game.status == MatchStatus.Finished && msg.sender == game.playerTwo) {
            if (game.heroTwoClaimed) revert HeroAlreadyClaimed();
            game.heroTwoClaimed = true;
            heroId = game.heroTwoId;
        } else {
            revert NotParticipant();
        }

        heroToken.safeTransferFrom(address(this), recipient, heroId);
        emit HeroClaimed(matchId, msg.sender, recipient, heroId);
    }

    function getMatch(uint256 matchId) external view returns (MatchData memory) {
        return matches[matchId];
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata)
        external
        returns (bytes4)
    {
        if (
            msg.sender != address(heroToken) || operator != address(this) || !expectingNFT || from != expectedDepositor
                || tokenId != expectedTokenId
        ) {
            revert UnexpectedNFT();
        }

        expectingNFT = false;
        return IERC721Receiver.onERC721Received.selector;
    }

    function _depositHero(address depositor, uint256 heroId) private {
        expectedDepositor = depositor;
        expectedTokenId = heroId;
        expectingNFT = true;

        heroToken.safeTransferFrom(depositor, address(this), heroId);
        if (expectingNFT) revert NFTCallbackMissing();

        delete expectedDepositor;
        delete expectedTokenId;
    }
}
