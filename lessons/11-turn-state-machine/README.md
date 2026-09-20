# 11강: 턴 기반 상태 머신과 게임 불변식

## 학습 목표

- 게임 상태와 현재 턴을 별개의 실행 조건으로 관리한다.
- 공격 성공 후 턴을 교대하거나 게임을 종료한다.
- 종료 시 승자와 턴 상태를 일관되게 고정한다.
- 상태별 불변식을 정의하고 `assert`로 내부 모순을 찾는다.
- modifier로 상태와 턴 조건을 재사용한다.
- 온체인 턴제 게임의 중단 및 선행 정보 문제를 이해한다.

## 상태와 턴

게임이 Active인지 확인하는 것만으로는 같은 사용자의 연속 공격을 막을 수 없다.

```solidity
require(game.state == GameState.Active, "Game not active");
require(msg.sender == game.currentTurn, "Not your turn");
```

state는 게임 전체 단계이고 currentTurn은 현재 행동 가능한 주소다.

## 게임 구조체

```solidity
enum GameState {
    None,
    Waiting,
    Active,
    Finished
}

struct Game {
    address playerOne;
    address playerTwo;
    uint256 playerOneHp;
    uint256 playerTwoHp;
    address currentTurn;
    address winner;
    GameState state;
}
```

## 턴 교대와 종료

공격 후 상대가 살아 있으면 턴을 수비자에게 넘긴다.

```solidity
game.currentTurn = defender;
```

체력이 0이 되면 상태, 승자와 턴을 함께 갱신한다.

```solidity
game.state = GameState.Finished;
game.winner = msg.sender;
game.currentTurn = address(0);
```

종료 후 currentTurn을 남겨두면 외부에서 읽는 데이터끼리 모순이 생긴다.

## 상태별 불변식

| 상태 | 내부 규칙 |
|---|---|
| Waiting | playerTwo, currentTurn, winner가 0 주소 |
| Active | 두 플레이어와 양수 체력이 존재하며 currentTurn은 참가자 중 한 명 |
| Finished | winner는 참가자 중 한 명이고 currentTurn은 0 주소이며 패자 체력은 0 |

사용자의 잘못된 행동은 `require`로 막고, 올바른 구현에서 깨져서는 안 되는 내부 규칙은 `assert`로 검사한다.

## modifier

```solidity
modifier atState(uint256 gameId, GameState expected) {
    require(games[gameId].state == expected, "Wrong state");
    _;
}

modifier onlyTurn(uint256 gameId) {
    require(
        games[gameId].currentTurn == msg.sender,
        "Not your turn"
    );
    _;
}
```

여러 modifier는 선언된 순서대로 적용한다.

## 상태 전이 표

| 함수 | 실행 전 상태 | 실행 권한 | 실행 후 상태 |
|---|---|---|---|
| createGame | 없음 | 누구나 | Waiting |
| joinGame | Waiting | 생성자가 아닌 주소 | Active |
| attack | Active | 현재 턴 플레이어 | Active 또는 Finished |

표에 없는 전이는 허용하지 않는다.

## 온체인 턴제 게임의 한계

- 현재 공격자는 이전 행동을 이미 알고 있다.
- 제출된 트랜잭션은 블록 포함 전에 공개될 수 있다.
- 사용자가 자기 턴에 행동하지 않으면 게임이 멈출 수 있다.
- 블록 생성자가 트랜잭션 순서에 영향을 줄 수 있다.

시간 제한, 몰수와 commit-reveal 같은 추가 설계가 필요하다.

## SOL-011: 교대 결투

### enum과 struct

```solidity
enum GameState {
    None,
    Waiting,
    Active,
    Finished
}

struct Game {
    address playerOne;
    address playerTwo;
    uint256 playerOneHp;
    uint256 playerTwoHp;
    address currentTurn;
    address winner;
    GameState state;
}
```

### 상태 변수

```solidity
uint256 public nextGameId;
mapping(uint256 => Game) public games;
```

### 이벤트

```solidity
event GameCreated(
    uint256 indexed gameId,
    address indexed playerOne
);

event GameJoined(
    uint256 indexed gameId,
    address indexed playerTwo
);

event AttackPerformed(
    uint256 indexed gameId,
    address indexed attacker,
    address indexed defender,
    uint256 damage,
    uint256 remainingHp
);

event GameFinished(
    uint256 indexed gameId,
    address indexed winner,
    address indexed loser
);
```

### modifier

- `atState(gameId, expected)`는 게임 상태가 expected인지 검사한다.
- `onlyTurn(gameId)`은 currentTurn이 msg.sender인지 검사한다.
- 두 modifier 모두 검사 후 함수 본문을 실행한다.

### createGame

```solidity
function createGame() public returns (uint256)
```

현재 nextGameId로 구조체를 생성한 뒤 ID를 증가시킨다. playerOne은 호출자, playerOneHp는 100이며 playerTwo, currentTurn과 winner는 0 주소다. playerTwoHp는 0이고 상태는 Waiting이다. 이벤트를 발생시키고 생성된 ID를 반환한다.

### joinGame

```solidity
function joinGame(uint256 gameId)
    public
    atState(gameId, GameState.Waiting)
```

생성자의 자기 참가를 막고 playerTwo와 체력 100을 설정한다. 첫 턴을 playerOne으로 지정하고 상태를 Active로 변경한다. currentTurn과 winner 불변식을 assert한 뒤 이벤트를 발생시킨다.

### attack

```solidity
function attack(uint256 gameId, uint256 damage)
    public
    atState(gameId, GameState.Active)
    onlyTurn(gameId)
    returns (uint256)
```

1. 피해량이 1 이상 30 이하인지 검사한다.
2. 지역 storage 참조를 만든다.
3. 호출자에 따라 공격자, 수비자와 감소시킬 체력을 결정한다.
4. 피해가 현재 체력 이상이면 체력을 0으로 만든다.
5. 종료 시 상태를 Finished, winner를 호출자, currentTurn을 0 주소로 설정한다.
6. 생존 시 체력을 줄이고 currentTurn을 수비자로 변경한다.
7. `AttackPerformed`와 필요한 경우 `GameFinished`를 발생시킨다.
8. 종료 또는 진행 상태의 불변식을 assert한다.
9. 수비자의 남은 체력을 반환한다.

### 제한 사항

- 이더, 외부 컨트랙트 호출, 관리자와 난수는 사용하지 않는다.
- currentTurn을 함수 인자로 받지 않는다.
- 종료된 게임을 다시 활성화하지 않는다.
- 공격 성공 후 반드시 턴을 교대하거나 게임을 종료한다.

### 보안 질문

1. Active 상태 검사만 있고 currentTurn 검사가 없으면 어떤 공격이 가능한가?
2. 종료 후 currentTurn을 0 주소로 초기화하는 이유는 무엇인가?
3. 플레이어가 자기 턴에 행동하지 않으면 어떤 문제가 생기는가?
4. 공격을 트랜잭션으로 바로 공개하면 상대방이나 블록 생성자가 어떤 정보를 미리 알 수 있는가?

## 감사 포인트

- 상태와 턴 검사를 모두 수행한다.
- 공격 성공 후 턴이 정확히 상대에게 넘어간다.
- Finished 상태에서 winner와 currentTurn이 일관된다.
- 패자 체력을 0으로 고정해 언더플로를 막는다.
- 종료 이벤트가 중복 발생하지 않는다.
- 행동하지 않는 참가자가 게임을 무기한 중단할 수 있음을 고려한다.
