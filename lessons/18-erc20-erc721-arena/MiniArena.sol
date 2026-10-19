// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGameToken {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IHeroNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// 교육용 예제: ERC-20 입장료와 ERC-721 영웅 에스크로를 연결한다.
contract MiniArena is IERC721Receiver {
    IGameToken public immutable gameToken;
    IHeroNFT public immutable heroNFT;

    address public immutable treasury;
    uint256 public immutable entryFee;

    // heroOf는 게임에 입장한 플레이어가 맡긴 영웅 ID를 기록한다.
    mapping(address => uint256) public heroOf;
    // playerOfHero는 영웅을 맡긴 플레이어를 기록한다.
    mapping(uint256 => address) public playerOfHero;
    mapping(address => bool) public isInArena;

    event EnteredArena(address indexed player, uint256 indexed tokenId);
    event LeftArena(address indexed player, uint256 indexed tokenId);

    constructor(
        IGameToken _gameToken,
        IHeroNFT _heroNFT,
        address _treasury,
        uint256 _entryFee
    ) {
        require(address(_gameToken) != address(0), "Invalid game token");
        require(address(_heroNFT) != address(0), "Invalid hero NFT");
        require(_treasury != address(0), "Invalid treasury");

        gameToken = _gameToken;
        heroNFT = _heroNFT;
        treasury = _treasury;
        entryFee = _entryFee;
    }

    function enterArena(uint256 tokenId) external {
        require(!isInArena[msg.sender], "Already in arena");
        require(heroNFT.ownerOf(tokenId) == msg.sender, "Not the hero owner");

        // Effects: 먼저 기록한다. 뒤의 외부 호출이 revert되면 이 변경도 롤백된다.
        isInArena[msg.sender] = true;
        heroOf[msg.sender] = tokenId;
        playerOfHero[tokenId] = msg.sender;

        // Interactions: 토큰 사용 승인과 NFT 전송 승인이 각각 필요하다.
        require(
            gameToken.transferFrom(msg.sender, treasury, entryFee),
            "Entry fee transfer failed"
        );
        heroNFT.safeTransferFrom(msg.sender, address(this), tokenId);

        emit EnteredArena(msg.sender, tokenId);
    }

    function leaveArena() external {
        require(isInArena[msg.sender], "Not in arena");

        uint256 tokenId = heroOf[msg.sender];

        // NFT를 돌려주는 외부 호출 전에 내부 기록부터 정리한다.
        delete isInArena[msg.sender];
        delete heroOf[msg.sender];
        delete playerOfHero[tokenId];

        heroNFT.safeTransferFrom(address(this), msg.sender, tokenId);

        emit LeftArena(msg.sender, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external view returns (bytes4) {
        require(msg.sender == address(heroNFT), "Unsupported NFT");
        require(operator == address(this), "Unexpected operator");
        require(from == playerOfHero[tokenId], "Unexpected depositor");
        return IERC721Receiver.onERC721Received.selector;
    }
}
