# 3강: 함수 기초와 상태 변경

## 학습 목표

- 함수의 매개변수와 반환값을 선언한다.
- `public`, `external`, `internal`, `private`의 호출 범위를 구분한다.
- `pure`, `view`, 일반 상태 변경 함수의 차이를 설명한다.
- 다른 컨트랙트를 인터페이스로 호출할 때의 `msg.sender` 변화를 이해한다.
- 상태 변수와 이름이 같은 지역 변수로 인한 섀도잉을 피한다.

## 핵심 내용

함수는 아래 요소로 구성된다.

```solidity
function name(uint256 value) public pure returns (uint256) {
    return value * 2;
}
```

- 매개변수: 호출자가 함수에 전달하는 값
- 가시성: 누가 함수를 호출할 수 있는지 지정
- 상태 변경성: 블록체인 상태를 읽거나 변경하는지 지정
- 반환형: 호출 결과의 자료형

### 상태 변경성

- `pure`: 상태 변수를 읽지도 변경하지도 않는다.
- `view`: 상태 변수를 읽을 수 있지만 변경할 수 없다.
- 지정 없음: 상태 변수를 변경할 수 있다.
- `payable`: 이더를 함께 받을 수 있다.

### 내부 호출과 외부 호출

같은 컨트랙트의 `internal` 함수는 이름으로 직접 호출한다.

```solidity
uint256 result = _multiply(value, multiplier);
```

다른 컨트랙트는 인터페이스나 컨트랙트 타입과 대상 주소를 사용해 호출한다.

```solidity
ICounter(target).increase();
```

이때 호출받은 컨트랙트에서 `msg.sender`는 최초 사용자가 아니라 호출을 보낸 컨트랙트 주소다. 외부 호출은 실패, 재진입, 가스 소모를 고려해야 하며 상태 변경 후 외부 호출 순서인 Checks-Effects-Interactions 패턴을 우선 검토한다.

## SOL-003: 전투 피해 계산기

`BattleCalculator` 컨트랙트를 작성한다.

### 요구사항

1. `uint256 public totalDamage`의 초깃값은 `0`이다.
2. `_multiply`는 `internal pure`이며 두 수의 곱을 반환한다.
3. `previewAttack`은 `public pure`이고 일반 피해와 치명타 피해를 반환한다.
4. 치명타 피해 계산에는 반드시 `_multiply`를 호출한다.
5. `recordDamage`는 전달받은 피해를 `totalDamage`에 더하고 갱신값을 반환한다.
6. 생성자, 상속, `this`, 외부 호출과 저수준 호출은 사용하지 않는다.

### 보안 질문

접근 제어가 없는 `public recordDamage`가 게임의 권위 있는 기록 함수라면 어떤 문제가 발생하는가?

## 감사 포인트

- 누구나 호출할 수 있는 상태 변경 함수인지 확인한다.
- 상태 변수와 반환 변수의 이름이 충돌해 섀도잉이 발생하지 않는지 확인한다.
- 반환값만 바뀌고 실제 상태가 그대로인 구현을 테스트한다.
- 신뢰해야 하는 피해량을 호출자가 임의로 제출하도록 설계하지 않는다.
