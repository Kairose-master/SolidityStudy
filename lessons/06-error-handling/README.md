# 6강: 예외 처리 `require`, `revert`, `assert`

## 학습 목표

- 실패한 호출의 상태 변경이 되돌아가는 원자성을 이해한다.
- `require`로 외부 입력, 호출자 권한과 실행 전제조건을 검사한다.
- `revert`와 사용자 정의 오류로 복잡한 실패 분기를 표현한다.
- `assert`로 내부 불변식을 검사한다.
- 오류 문자열과 사용자 정의 오류의 가스 특성을 구분한다.
- Checks-Effects-Interactions에서 검사를 상태 변경보다 먼저 수행한다.

## 실패와 원자성

Solidity 실행 중 예외가 발생하면 현재 호출에서 수행한 상태 변경은 되돌아간다.

```solidity
uint256 public count;

function demo() public {
    count = 10;
    require(false, "Always fails");
    count = 20;
}
```

호출은 실패하고 `count = 10`도 취소된다. 이전에 성공한 별도 트랜잭션은 되돌아가지 않으며 실패할 때까지 소비한 가스도 환불되지 않는다.

## require

`require`는 사용자가 충족해야 하는 입력값, 권한과 실행 전제조건을 검사할 때 사용한다.

```solidity
require(!registered[msg.sender], "Already registered");
require(amount > 0 && amount <= 50, "Invalid amount");
require(msg.sender == owner, "Not owner");
```

조건이 거짓이면 호출이 실패하고 현재 호출의 상태 변경이 되돌아간다.

## revert와 사용자 정의 오류

조건이 여러 갈래이거나 오류에 구체적인 값을 담고 싶다면 `revert`를 사용할 수 있다.

```solidity
error InsufficientGold(uint256 available, uint256 requested);

if (amount > gold[msg.sender]) {
    revert InsufficientGold(gold[msg.sender], amount);
}
```

사용자 정의 오류는 긴 문자열보다 배포 및 실패 경로의 가스를 줄일 수 있다. 정확한 차이는 오류 인자와 컴파일 설정에 따라 달라진다.

## assert와 불변식

`assert`는 올바른 내부 로직이라면 절대로 거짓이 되지 않아야 하는 조건을 검사한다.

```solidity
assert(gold[msg.sender] + spent[msg.sender] == 100);
```

외부 사용자가 잘못된 입력으로 쉽게 위반할 수 있는 조건에는 보통 `require` 또는 사용자 정의 오류를 사용한다. `assert` 실패는 내부 회계나 프로그램 로직의 결함을 뜻하며 Solidity 0.8.x에서 Panic 오류를 발생시킨다.

## Checks-Effects-Interactions

상태 변경 함수는 일반적으로 다음 순서를 따른다.

1. Checks: 입력, 권한, 상태와 잔액을 검사한다.
2. Effects: 내부 상태를 변경한다.
3. Interactions: 다른 컨트랙트를 호출하거나 이더를 전송한다.

검사를 먼저 배치하면 실행 조건을 명확히 하고 불필요한 작업을 줄인다. 외부 호출 전에 내부 상태를 갱신하는 구조는 재진입 위험을 줄이는 데도 중요하다.

## SOL-006: 안전한 훈련소

### 상태 변수와 오류

```solidity
mapping(address => bool) public registered;
mapping(address => uint256) public gold;
mapping(address => uint256) public spent;

error InsufficientGold(uint256 available, uint256 requested);
```

### 요구사항

1. `register()`는 중복 등록을 `require`로 막고 최초 골드 100과 소비량 0을 기록한다.
2. `train(amount)`는 등록 여부를 `require`로 검사한다.
3. 훈련량은 1 이상 50 이하이며 범위를 `require`로 검사한다.
4. 골드가 부족하면 `InsufficientGold` 사용자 정의 오류로 실패한다.
5. 성공 시 골드에서 훈련량을 빼고 누적 소비량에 더한다.
6. `gold + spent == 100`을 `assert`로 검사하고 남은 골드를 반환한다.
7. 생성자, 관리자, 골드 추가·프로필 삭제 함수, 외부 호출과 `unchecked`는 사용하지 않는다.

## 감사 포인트

- 중복 등록을 허용하면 소비 후 재등록으로 골드를 100까지 반복 충전할 수 있다.
- `amount == 0`과 `amount == 50` 경계값을 정확히 처리해야 한다.
- 부족한 잔액으로 실패하면 골드와 누적 소비량은 호출 전 값으로 유지되어야 한다.
- 등록 여부는 외부 실행 전제조건이고, 골드와 누적 소비량의 합은 내부 회계 불변식이다.
