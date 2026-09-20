# 9강: 구조체와 열거형

## 학습 목표

- `struct`로 관련 데이터를 하나의 사용자 정의 자료형으로 묶는다.
- 구조체를 필드 이름 방식으로 생성한다.
- 구조체의 storage 참조와 memory 복사본을 구분한다.
- `enum`으로 허용된 상태 집합을 표현한다.
- enum의 기본값을 이용해 존재하지 않는 데이터와 생성된 데이터를 구분한다.
- 명시적인 상태 전이로 게임 흐름을 제한한다.

## struct

구조체는 서로 관련된 값을 하나의 자료형으로 묶는다.

```solidity
struct Player {
    uint256 hp;
    uint256 wins;
    bool registered;
}

mapping(address => Player) public players;
```

필드에 직접 접근할 수 있다.

```solidity
players[msg.sender].hp = 100;
players[msg.sender].registered = true;
```

구조체를 생성할 때는 필드 이름을 지정하면 값의 의미와 순서가 명확하다.

```solidity
players[msg.sender] = Player({
    hp: 100,
    wins: 0,
    registered: true
});
```

## 구조체와 데이터 위치

```solidity
Player storage player = players[msg.sender];
player.hp = 80;
```

지역 storage 변수는 원본 상태를 가리키므로 변경하면 영구 상태가 바뀐다.

```solidity
Player memory copied = players[msg.sender];
copied.hp = 80;
```

memory 변수는 임시 복사본이므로 변경해도 원본 상태는 바뀌지 않는다.

## enum

enum은 가능한 상태를 제한한다.

```solidity
enum DuelState {
    None,
    Open,
    Active,
    Finished
}
```

사용 방법:

```solidity
DuelState public state;

state = DuelState.Open;
require(state == DuelState.Open, "Not open");
```

enum의 첫 항목은 내부적으로 0이며 기본값이다. mapping의 존재하지 않는 키도 기본값을 반환하므로 첫 상태를 `None`으로 두면 생성되지 않은 데이터와 실제 데이터를 구분하기 쉽다.

## 구조체 안의 enum과 상태 전이

```solidity
struct Duel {
    address creator;
    address opponent;
    uint256 creatorHp;
    uint256 opponentHp;
    DuelState state;
}
```

결투 상태는 다음 순서로만 전이되어야 한다.

```text
None → Open → Active → Finished
```

각 함수가 현재 상태를 검사하면 존재하지 않는 경기 참가, 종료된 경기 공격과 중복 종료를 막을 수 있다.

## SOL-009: 미니 결투 상태 머신

### enum과 struct

```solidity
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
```

### 상태 변수

```solidity
uint256 public nextDuelId;
mapping(uint256 => Duel) public duels;
```

### 이벤트

```solidity
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
```

### createDuel()

```solidity
function createDuel() public returns (uint256)
```

1. 현재 `nextDuelId`를 지역 변수 `duelId`에 저장한다.
2. `nextDuelId`를 1 증가시킨다.
3. `duels[duelId]`에 필드 이름 방식으로 구조체를 저장한다.
4. 초기값은 생성자 `msg.sender`, 상대 `address(0)`, 생성자 체력 100, 상대 체력 0, 상태 `DuelState.Open`이다.
5. `DuelCreated`를 발생시키고 `duelId`를 반환한다.

### joinDuel(uint256 duelId)

1. `Duel storage duel = duels[duelId]`로 상태를 참조한다.
2. 상태가 `DuelState.Open`인지 검사한다.
3. 생성자가 자신의 경기에 참가하지 못하게 검사한다.
4. 상대를 `msg.sender`, 상대 체력을 100, 상태를 `DuelState.Active`로 설정한다.
5. `DuelJoined`를 발생시킨다.

존재하지 않는 결투의 상태는 `None`이므로 Open 검사에서 실패해야 한다.

### attack(uint256 duelId, uint256 damage)

```solidity
function attack(uint256 duelId, uint256 damage)
    public
    returns (uint256)
```

1. 결투의 지역 storage 참조를 만든다.
2. 상태가 `Active`인지 검사한다.
3. 피해량이 1 이상 30 이하인지 검사한다.
4. 호출자가 생성자 또는 상대인지 검사한다.
5. 생성자가 공격하면 상대 체력, 상대가 공격하면 생성자 체력을 감소시킨다.
6. 피해가 현재 체력 이상이면 체력을 0으로 설정하고 상태를 `Finished`로 변경한다.
7. 그렇지 않으면 체력에서 피해량을 뺀다.
8. `AttackResolved`를 발생시키고 공격받은 플레이어의 남은 체력을 반환한다.

언더플로를 막기 위해 피해량과 현재 체력을 먼저 비교해야 한다.

### 제한 사항

생성자, 관리자, 상속, 외부 컨트랙트 호출과 이더 전송은 사용하지 않는다. 공격 턴은 아직 구현하지 않는다.

### 보안 질문

1. `DuelState`의 첫 항목을 `None`으로 두는 이유는 무엇인가?
2. `Duel memory copied = duels[duelId]`의 `copied.state`를 변경하면 실제 상태도 변경되는가?
3. 참가자만 `attack`을 호출할 수 있어도 현재 게임이 공정하지 않은 이유는 무엇인가?

## 감사 포인트

- 생성되지 않은 mapping 값의 enum은 첫 항목을 반환한다.
- 현재 상태를 검사하지 않으면 유효하지 않은 상태 전이가 가능하다.
- storage 구조체 참조의 필드 변경은 원본 상태를 변경한다.
- 턴 제한이 없으면 한 참가자가 연속 공격해 승리할 수 있다.
- 종료 시 체력을 0으로 고정하지 않으면 Solidity 0.8의 언더플로 검사로 호출이 실패할 수 있다.
