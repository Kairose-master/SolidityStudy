# 7강: 이벤트와 로그

## 학습 목표

- `event`를 선언하고 `emit`으로 로그를 발생시킨다.
- 상태 변수와 이벤트 로그의 역할을 구분한다.
- `indexed` 매개변수로 외부 검색에 필요한 토픽을 설계한다.
- 성공한 호출에서만 이벤트가 남는 원자성을 이해한다.
- 이벤트가 접근 제어나 온체인 상태를 대신할 수 없는 이유를 설명한다.
- 상태 변경 후 갱신된 값으로 이벤트를 발생시킨다.

## 이벤트 선언과 발생

이벤트는 컨트랙트 내부, 함수 바깥에 선언한다.

```solidity
event PlayerRegistered(address indexed player, uint256 startingWins);
```

함수에서는 `emit`으로 발생시킨다.

```solidity
registered[msg.sender] = true;
emit PlayerRegistered(msg.sender, 0);
```

이벤트 선언은 로그의 형식을 정하고 `emit`은 실제 트랜잭션 로그를 만든다.

## 상태와 로그

상태 변수는 컨트랙트가 이후 호출에서 읽고 계산에 사용할 수 있다. 이벤트는 외부 애플리케이션, 서버와 블록 탐색기가 상태 변경을 추적하도록 돕는 로그다.

컨트랙트는 과거 이벤트를 일반 상태처럼 직접 읽을 수 없다. 이벤트만 발생시켜도 상태는 변경되지 않으며, 상태를 변경해도 자동으로 이벤트가 발생하지 않는다. 따라서 이벤트는 온체인 회계, 접근 제어 또는 상태 저장을 대체할 수 없다.

## indexed

```solidity
event MatchRecorded(
    address indexed winner,
    address indexed loser,
    uint256 winnerTotalWins
);
```

`indexed` 매개변수는 로그의 토픽에 들어가므로 특정 승자나 패자가 포함된 로그를 효율적으로 필터링할 수 있다. 일반적인 비익명 이벤트는 최대 세 개의 인자를 인덱싱할 수 있다.

`address`와 `uint256` 같은 고정 길이 값은 토픽에서 값을 직접 검색할 수 있다. `string`, 동적 배열과 같은 가변 길이 값을 인덱싱하면 실제 값 대신 해시가 토픽에 저장된다.

## 상태 변경과 이벤트 순서

```solidity
wins[msg.sender] += 1;
emit MatchRecorded(msg.sender, loser, wins[msg.sender]);
```

상태를 먼저 변경한 다음 이벤트를 발생시키면 이벤트에 갱신된 값이 기록된다. 이벤트를 먼저 발생시키면 성공한 호출에서도 이전 값을 기록할 수 있다.

호출이 뒤에서 실패하면 앞에서 발생시킨 이벤트도 상태 변경과 함께 되돌아가므로 최종 로그에 남지 않는다.

## 보안 관점

이벤트는 함수가 성공했다는 사실을 기록하지만 입력이나 행동이 정당했다는 사실을 스스로 증명하지 않는다. 누구나 승리를 기록할 수 있는 함수는 그럴듯한 이벤트를 남기면서도 거짓 승수를 만들 수 있다.

이벤트 데이터도 공개되므로 비밀번호, 복호화 키와 같은 비밀값을 기록해서는 안 된다.

## SOL-007: 아레나 경기 기록소

### 상태 변수

```solidity
mapping(address => bool) public registered;
mapping(address => uint256) public wins;
```

### 이벤트

```solidity
event PlayerRegistered(
    address indexed player,
    uint256 startingWins
);

event MatchRecorded(
    address indexed winner,
    address indexed loser,
    uint256 winnerTotalWins
);
```

### 요구사항

1. `register()`는 중복 등록을 막고 호출자를 등록한 뒤 승수를 0으로 설정한다.
2. 등록 상태 변경 후 `PlayerRegistered(msg.sender, 0)`을 발생시킨다.
3. `recordWin(loser)`는 승자와 패자가 모두 등록됐는지 검사한다.
4. 승자와 패자가 서로 다른 주소인지 검사한다.
5. 호출자의 승수를 1 증가시킨다.
6. 상태 변경 후 갱신된 승수를 담아 `MatchRecorded`를 발생시킨다.
7. 호출자의 갱신된 승수를 반환한다.
8. 생성자, 관리자, 배열, 구조체, 반복문과 외부 호출은 사용하지 않는다.

## 감사 포인트

- 실제 경기 결과나 기록 권한을 검증하지 않으면 등록된 사용자가 자신의 승수를 임의로 증가시킬 수 있다.
- 패자의 등록 여부를 검사하지 않으면 임의 주소를 패자로 기록할 수 있다.
- 실패한 호출에서 발생한 이벤트는 최종 로그에 남지 않는다.
- `winner`와 `loser`를 인덱싱하면 주소별 경기 로그 검색에 유리하다.
- 인덱싱하지 않은 `winnerTotalWins`도 로그에서 읽을 수 있지만 해당 값으로 토픽 필터링할 수는 없다.
