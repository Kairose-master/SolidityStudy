# 5강: mapping과 주소별 상태

## 학습 목표

- 키와 값으로 구성된 `mapping`을 선언하고 읽고 쓴다.
- 존재하지 않는 키가 자료형의 기본값을 반환한다는 점을 이해한다.
- 중첩 mapping으로 주소 간 관계를 표현한다.
- `public` mapping의 자동 getter를 사용한다.
- mapping을 직접 열거하거나 순회할 수 없는 이유를 설명한다.
- `msg.sender`가 신원을 제공하지만 권한과 값의 정당성까지 보장하지는 않음을 이해한다.

## 기본 문법

```solidity
mapping(KeyType => ValueType) visibility name;
```

```solidity
mapping(address => uint256) public gold;
mapping(address => bool) public registered;
```

내부에서는 대괄호로 접근한다.

```solidity
gold[msg.sender] = 100;
gold[msg.sender] += 50;
uint256 amount = gold[msg.sender];
```

`public` mapping에는 키를 인자로 받는 getter가 자동으로 생성된다. 외부에서는 `gold(player)`처럼 호출한다.

## 기본값과 존재 여부

모든 가능한 키가 존재하는 것처럼 동작하며, 쓰지 않은 키는 값 타입의 기본값을 반환한다.

```solidity
gold[unknown]       // 0
registered[unknown] // false
```

따라서 `gold == 0`만으로 미등록 사용자와 잔액이 0인 사용자를 구분할 수 없다. 별도의 `registered` mapping처럼 존재 상태를 기록해야 한다.

## 중첩 mapping

```solidity
mapping(address => mapping(address => bool)) public duelPermission;
```

```solidity
duelPermission[msg.sender][opponent] = true;
```

관계는 방향성이 있으므로 A가 B를 허용했다고 B가 A를 허용한 것은 아니다. 상호 동의는 두 방향을 모두 검사한다.

```solidity
return duelPermission[a][b] && duelPermission[b][a];
```

## 저장 위치와 순회 제한

mapping은 `storage`에만 존재할 수 있다. mapping 자체를 `public` 또는 `external` 함수의 입력이나 반환값으로 사용할 수 없고, 길이나 키 목록이 없어 직접 순회할 수도 없다.

키를 열거해야 한다면 별도 배열을 관리해야 하지만, 무제한 배열 전체 순회는 가스 한도에 따른 DoS 위험을 만든다.

## 삭제

```solidity
delete gold[msg.sender];
```

현재 값을 기본값으로 되돌릴 뿐 과거 온체인 기록을 지우지 않는다. 중첩 mapping의 모든 내부 키를 자동으로 찾아 삭제할 수도 없다.

## SOL-005: 플레이어 레지스트리

### 상태 변수

```solidity
mapping(address => bool) public registered;
mapping(address => uint256) public gold;
mapping(address => mapping(address => bool)) public duelPermission;
```

### 요구사항

1. `register()`는 호출자를 등록하고 골드를 100으로 설정한다.
2. `addGold(amount)`는 호출자 골드에 값을 누적하고 갱신값을 반환한다.
3. `setDuelPermission(opponent, allowed)`는 호출자의 결투 의사를 저장한다.
4. `canDuel(playerOne, playerTwo)`는 양방향 동의가 모두 참일 때만 참을 반환한다.
5. `removeMyProfile()`은 호출자의 등록 상태와 골드만 `delete`한다.
6. `require`, 배열, 구조체, 반복문과 외부 호출은 사용하지 않는다.

## 감사 포인트

- `msg.sender`를 키로 쓰면 타인의 값을 직접 변경하는 것은 막지만, 사용자가 값 자체를 정당하게 얻었는지는 보장하지 않는다.
- `addGold`의 호출자가 금액을 정하고 무제한 호출할 수 있으면 자기 골드를 위조할 수 있다.
- 등록 여부를 검사하지 않으면 미등록 사용자도 골드를 생성할 수 있다.
- 프로필 삭제 시 중첩된 결투 허용값은 그대로 남아 재등록 후 다시 활성화될 수 있다.
- `private` mapping도 온체인 비밀 저장소가 아니다.
