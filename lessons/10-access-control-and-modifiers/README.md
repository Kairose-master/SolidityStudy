# 10강: 접근 제어와 함수 modifier

## 학습 목표

- 생성자에서 최초 관리자 주소를 설정한다.
- `modifier`로 반복되는 실행 조건을 재사용한다.
- `_;`가 실제 함수 본문의 실행 위치임을 이해한다.
- 관리자와 운영자의 권한을 구분한다.
- 여러 modifier의 적용 순서를 이해한다.
- `private`가 접근 제어나 온체인 비밀을 보장하지 않음을 설명한다.
- 권한 검사에 `tx.origin` 대신 `msg.sender`를 사용한다.

## 생성자와 관리자

생성자는 컨트랙트 배포 시 한 번 실행된다.

```solidity
address public owner;

constructor() {
    owner = msg.sender;
}
```

직접 배포했다면 배포자 주소가 owner가 된다. 다른 컨트랙트가 배포했다면 해당 컨트랙트 주소가 owner가 될 수 있다.

## modifier와 _;

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}
```

`_;` 위치에 modifier가 적용된 함수 본문이 들어간다.

```solidity
function setPaused(bool value) public onlyOwner {
    paused = value;
}
```

실행 순서는 권한 검사 후 함수 본문이다. 일반적인 접근 제어 modifier는 검사 뒤에 `_;`를 배치한다.

## 인자를 받는 modifier

```solidity
mapping(address => bool) public banned;

modifier notBanned(address player) {
    require(!banned[player], "Banned player");
    _;
}
```

```solidity
function enterArena()
    public
    notBanned(msg.sender)
{
}
```

여러 modifier는 함수 선언에 적힌 순서대로 적용된다.

## 역할 분리

```solidity
mapping(address => bool) public moderators;

modifier onlyModerator() {
    require(
        msg.sender == owner || moderators[msg.sender],
        "Not moderator"
    );
    _;
}
```

관리자는 운영자 지정과 긴급 정지를 담당하고 운영자는 사용자 차단처럼 제한된 기능만 담당하도록 역할을 나눌 수 있다.

## private와 권한

상태 변수를 `private`로 선언해도 블록체인의 저장 데이터는 외부에서 분석할 수 있다. 함수에 권한 검사가 없다면 상태 변수의 가시성과 관계없이 누구나 public 함수를 호출할 수 있다.

## msg.sender와 tx.origin

권한 검사에는 직접 호출자인 `msg.sender`를 사용한다. `tx.origin`은 트랜잭션을 최초로 시작한 주소이므로 관리자가 악성 중간 컨트랙트를 호출하도록 속았을 때 권한 검사를 우회하는 피싱 공격에 이용될 수 있다.

## 관리자 위험

접근 제어 코드가 정확해도 관리자 키가 탈취되면 공격자는 관리자 권한 전체를 사용한다. 권한은 필요한 범위로 최소화하고 변경 이벤트, 다중 서명과 시간 지연 같은 방어 수단을 검토해야 한다.

## SOL-010: 아레나 운영 권한

### 상태 변수

```solidity
address public owner;
bool public paused;

mapping(address => bool) public moderators;
mapping(address => bool) public banned;
mapping(address => bool) public entered;
```

### 이벤트

```solidity
event ModeratorUpdated(
    address indexed account,
    bool allowed
);

event PauseUpdated(bool paused);

event BanUpdated(
    address indexed player,
    bool banned
);

event ArenaEntered(address indexed player);
```

### 생성자와 modifier

1. 생성자에서 배포자를 `owner`로 저장한다.
2. `onlyOwner`는 호출자가 owner인지 검사한다.
3. `onlyModerator`는 호출자가 owner이거나 등록된 moderator인지 검사한다.
4. `whenNotPaused`는 paused가 false인지 검사한다.
5. `notBanned(address player)`는 인자로 받은 주소가 차단되지 않았는지 검사한다.
6. 모든 modifier는 검사 후 함수 본문을 실행한다.

### setModerator

```solidity
function setModerator(address account, bool allowed)
    public
    onlyOwner
```

- account가 `address(0)`이 아닌지 검사한다.
- moderator 상태를 변경하고 `ModeratorUpdated`를 발생시킨다.

### setPaused

```solidity
function setPaused(bool value)
    public
    onlyOwner
```

- paused를 변경하고 `PauseUpdated`를 발생시킨다.

### setBanned

```solidity
function setBanned(address player, bool value)
    public
    onlyModerator
```

- player가 `address(0)`이 아닌지 검사한다.
- 차단 상태를 변경하고 `BanUpdated`를 발생시킨다.

### enterArena

```solidity
function enterArena()
    public
    whenNotPaused
    notBanned(msg.sender)
    returns (bool)
```

- 중복 입장을 검사한다.
- 호출자의 entered를 true로 변경한다.
- `ArenaEntered`를 발생시키고 true를 반환한다.

### 제한 사항

- `tx.origin`을 사용하지 않는다.
- 함수 안에서 관리자 검사를 반복하지 않고 지정된 modifier를 사용한다.
- 상속, 외부 호출, 이더 전송과 소유권 이전은 사용하지 않는다.

### 보안 질문

1. owner를 private로 선언하면 관리자 주소가 온체인에서 비밀이 되는가?
2. 권한 검사에 tx.origin을 사용하면 어떤 공격이 가능한가?
3. 관리자 키가 탈취되면 공격자가 수행할 수 있는 행동은 무엇인가?

## 감사 포인트

- `_;`가 검사보다 앞에 있지 않은지 확인한다.
- owner 전용 기능과 moderator 기능을 구분한다.
- 0 주소를 역할에 등록하지 못하게 한다.
- 이벤트가 권한 검사 자체를 대신하지 않는지 확인한다.
- tx.origin을 권한 검사에 사용하지 않는다.
- 관리자 권한의 범위와 키 탈취 영향을 문서화한다.
