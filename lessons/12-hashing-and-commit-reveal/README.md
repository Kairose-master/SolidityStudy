# 12강: 해시와 commit-reveal

11강 과제 SOL-011은 나중에 제출한다. 이번 강의는 11강 구현 없이 진행할 수 있다.

## 핵심 개념

선택을 그대로 트랜잭션에 넣으면 상대가 블록에 포함되기 전에도 내용을 볼 수 있다. 먼저 선택의 해시(commitment)를 제출하고, 양쪽 제출이 끝나면 선택과 비밀값을 공개해 검증한다.

1. Commit: 선택과 salt를 로컬에서 해시하고 해시만 제출한다.
2. Reveal: 두 참가자가 모두 commit한 뒤 선택과 salt를 공개한다.
3. Verify: 같은 입력으로 다시 계산한 해시가 저장된 commitment와 같은지 검사한다.

`bytes32`는 고정 길이 32바이트 값이다. `keccak256`은 바이트 데이터를 받아 bytes32 해시를 반환한다. `abi.encode`는 여러 값을 ABI 규칙에 맞춰 바이트로 인코딩한다. 해시는 복호화하는 암호문이 아니지만, 후보가 적으면 후보별 해시 비교로 원문을 알아낼 수 있다.

```solidity
bytes32 commitment = keccak256(
    abi.encode(address(this), gameId, player, choice, salt)
);
```

입력 타입과 순서를 계산·검증 양쪽에서 동일하게 사용한다. 이번 과제의 타입은 address, uint256, address, uint8, bytes32다.

- choice: 1, 2, 3 중 하나인 선택
- salt: 로컬에서 안전한 난수로 생성하고 공개 전까지 숨기는 bytes32 값
- player: 다른 주소가 같은 commitment를 복사해 자신의 선택처럼 검증받는 것을 방지
- gameId: 다른 게임에서 같은 commitment를 재사용하는 것을 방지
- address(this): 다른 컨트랙트에서 재사용하는 것을 방지; 체인 간 구분까지 필요하면 chain ID도 결합

salt가 없거나 예측 가능하면 선택 세 개를 대입해 맞힐 수 있다. salt를 commit 트랜잭션에 포함하거나 온체인에 저장해서는 안 된다. public 해시 계산 도우미도 트랜잭션으로 호출하면 입력이 공개된다. 실제 비밀은 로컬에서 계산하며 원격 RPC 호출도 제공자에게 입력이 전달된다.

이번 과제에서는 abi.encode를 사용한다. abi.encodePacked는 동적 값 여러 개를 결합할 때 경계가 모호해질 수 있다. 예를 들어 ("a", "bc")와 ("ab", "c")의 packed 결과가 같다. 이는 해시 함수 자체의 충돌을 찾은 것이 아니라 입력 인코딩이 같아지는 문제다.

## 단계 분리가 필요한 이유

첫 번째 참가자가 reveal한 뒤에도 두 번째 참가자가 commit할 수 있으면, 공개된 선택을 보고 유리한 선택을 확정할 수 있다. 반드시 두 commitment를 먼저 고정하고 reveal을 허용한다. commitment는 덮어쓸 수 없어야 한다.

## SOL-012: 비밀 선택 보관소

컨트랙트 이름은 SecretChoiceArena, pragma는 ^0.8.24로 한다. 완성 코드는 학습자가 작성한다. 승패 계산은 이번 과제 범위에 포함하지 않는다.

### 자료 구조

```solidity
struct Game {
    address playerOne;
    address playerTwo;
    uint8 commitCount;
    uint8 revealCount;
    bool finished;
}

uint256 public nextGameId;
mapping(uint256 => Game) public games;
mapping(uint256 => mapping(address => bytes32)) public commitments;
mapping(uint256 => mapping(address => bool)) public revealed;
mapping(uint256 => mapping(address => uint8)) public choices;
```

0 commitment는 미제출을 의미하며 제출 시 거부한다. gameId는 0부터 순서대로 만든다. 생성 시 상대까지 지정하므로 별도 join 함수는 없다.

### 이벤트

```solidity
event GameCreated(uint256 indexed gameId, address indexed playerOne, address indexed playerTwo);
event ChoiceCommitted(uint256 indexed gameId, address indexed player);
event ChoiceRevealed(uint256 indexed gameId, address indexed player, uint8 choice);
event GameFinished(uint256 indexed gameId);
```

### 함수 사양

```solidity
function createGame(address opponent) public returns (uint256)
function commitChoice(uint256 gameId, bytes32 commitment) public
function revealChoice(uint256 gameId, uint8 choice, bytes32 salt) public
```

createGame:

- 0 주소와 자기 자신을 상대방으로 지정하지 못하게 한다.
- 현재 nextGameId에 호출자와 opponent를 저장한다. 카운터는 0, finished는 false다.
- nextGameId를 증가시키고 GameCreated를 발생시킨 뒤 생성한 ID를 반환한다.

commitChoice:

- 실제 생성된 게임이며 호출자가 두 참가자 중 하나인지 검사한다.
- 종료되지 않았고 commitCount가 2 미만인지 검사한다.
- commitment가 0이 아니며 호출자가 아직 제출하지 않았는지 검사한다.
- 호출자 commitment를 저장하고 commitCount를 1 증가시킨다.
- ChoiceCommitted를 발생시킨다. 선택이나 salt를 인자로 받지 않는다.

revealChoice:

- 실제 생성된 게임이며 호출자가 참가자인지 검사한다.
- 종료되지 않았고 commitCount가 정확히 2인지 검사한다.
- 호출자가 아직 공개하지 않았고 choice가 1 이상 3 이하인지 검사한다.
- 위 해시 식에서 player 자리에 msg.sender를 사용해 다시 계산하고 호출자의 commitment와 일치하는지 검사한다.
- revealed를 true로, choices를 공개한 choice로 저장하고 revealCount를 증가시킨다.
- ChoiceRevealed를 발생시킨다.
- revealCount가 2가 되면 finished를 true로 설정하고 GameFinished를 한 번 발생시킨다.

### 제한 및 확인 시나리오

- 이더, 관리자, 외부 호출, 승패 계산, 시간 제한과 난수 생성 코드는 사용하지 않는다.
- 조건 재사용에는 modifier를 사용해도 된다.
- 잘못된 공개는 revert되어야 하며, 이후 올바른 값으로 재시도할 수 있어야 한다.
- 한 명만 commit한 상태의 reveal, 중복 commit, 중복 reveal, 비참가자 호출, 없는 gameId 사용을 거부한다.
- 두 참가자가 각자 다른 salt로 commit하고 reveal하면 선택 두 개가 기록되고 finished가 true가 된다.

### 보안 질문

1. choice만 해시하고 salt를 생략하면 왜 선택을 숨기기 어려운가?
2. 해시에 player와 gameId를 포함하는 이유는 무엇인가?
3. 두 명의 commit 전에 reveal을 허용하면 어떤 문제가 생기는가?
4. 마지막 참가자가 불리한 선택을 보고 reveal하지 않으면 어떻게 되는가?

이번 구현은 미공개 참가자로 인해 무기한 멈출 수 있다. 기한과 몰수·보증금 정책은 후속 주제다. commit-reveal 자체가 공정한 난수나 게임의 완료를 보장하지는 않는다.

## 참고

- [Solidity ABI 명세](https://docs.solidity.org/en/latest/abi-spec.html)
- [Solidity 공식 예제: Blind Auction](https://docs.solidity.org/en/latest/solidity-by-example.html#blind-auction)
