# 8강: 배열과 데이터 위치

## 학습 목표

- 고정 길이 배열과 동적 배열을 구분한다.
- `length`, `push`, `pop`, 인덱스 접근과 `delete`의 동작을 이해한다.
- `storage`, `memory`, `calldata`의 수명과 변경 가능성을 구분한다.
- 데이터 위치가 다른 대입에서 복사와 참조의 차이를 이해한다.
- 배열 반복문의 경계와 가스 기반 DoS 위험을 확인한다.

## 배열

고정 길이 배열은 선언할 때 길이를 정한다.

```solidity
address[2] public players;
```

동적 배열은 실행 중 끝에 원소를 추가하거나 마지막 원소를 제거할 수 있다.

```solidity
uint256[] public scores;

scores.push(80);
scores.pop();
```

배열 인덱스는 0부터 시작한다. 길이가 3인 배열의 유효한 인덱스는 0, 1, 2이며 범위를 벗어나면 Panic 오류가 발생한다.

## length, push, pop과 delete

- `length`: 현재 원소 개수
- `push(value)`: 동적 storage 배열 끝에 값 추가
- `pop()`: 마지막 원소 삭제 후 길이 1 감소
- `delete array[index]`: 해당 값을 기본값으로 변경하지만 길이는 유지

`[10, 20, 30]`에서 `delete array[1]`을 실행하면 `[10, 0, 30]`이 된다. `pop()`을 실행하면 마지막 원소가 제거되어 `[10, 20]`이 된다.

`public` 상태 배열의 자동 getter는 인덱스를 받아 한 원소를 반환한다. 배열 전체나 길이를 자동으로 반환하지 않는다.

## 데이터 위치

| 위치 | 수명 | 변경 가능 | 용도 |
|---|---|---:|---|
| `storage` | 컨트랙트가 존재하는 동안 | 가능 | 영구 상태 |
| `memory` | 함수 실행 동안 | 가능 | 임시 데이터 |
| `calldata` | 외부 호출 동안 | 읽기 전용 | 함수 입력 |

### storage 참조

```solidity
uint256[] storage myScores = scores[msg.sender];
myScores.push(100);
```

`myScores`는 복사본이 아니라 실제 상태 배열을 가리키므로 변경하면 `scores[msg.sender]`도 변경된다.

### memory 복사본

```solidity
uint256[] memory copied = scores[msg.sender];
```

storage 배열을 memory에 대입하면 독립적인 복사본이 만들어진다. 복사본을 변경해도 원래 상태 배열은 변경되지 않는다. 동적 memory 배열은 `new uint256[](length)`처럼 길이를 정해 생성하며 이후 `push`와 `pop`을 사용할 수 없다.

### calldata 입력

```solidity
function sum(uint256[] calldata values) external pure returns (uint256) {
    uint256 total;

    for (uint256 i = 0; i < values.length; i++) {
        total += values[i];
    }

    return total;
}
```

calldata는 외부 호출 입력을 복사하지 않고 읽는 영역이다. 값을 변경하거나 `push`, `pop`을 사용할 수 없다.

## 반복문과 가스

배열 길이에 상한이 없다면 반복 횟수와 가스 비용도 계속 증가할 수 있다. 상태 배열 전체를 순회하는 필수 기능은 데이터가 커지면서 블록 가스 한도를 넘어 실행 불가능해질 수 있다.

반복 조건은 `i < array.length`로 작성해야 한다. `i <= array.length`는 마지막에 존재하지 않는 인덱스에 접근한다.

## SOL-008: 훈련 점수 기록부

### 상태 변수와 이벤트

```solidity
mapping(address => bool) public registered;
mapping(address => uint256[]) public scores;

event ScoresAdded(
    address indexed player,
    uint256 addedCount,
    uint256 totalCount
);
```

### 요구사항

1. `register()`는 중복 등록을 막고 호출자를 등록한다.
2. `addScores(uint256[] calldata newScores)`는 등록 여부를 검사한다.
3. 한 번에 1개 이상 5개 이하의 점수만 입력받는다.
4. `uint256[] storage myScores = scores[msg.sender]`로 상태 배열을 참조한다.
5. 기존 점수와 새 점수를 합쳐 최대 10개인지 검사한다.
6. 각 점수가 1 이상 100 이하인지 먼저 검사한다.
7. 검사가 끝난 점수를 storage 배열에 추가하고 이벤트를 발생시킨다.
8. `removeLastScore()`는 마지막 점수를 제거하고 남은 개수를 반환한다.
9. `previewDoubled`는 1개 이상 5개 이하의 calldata 입력을 받아 각 값이 1 이상 50 이하인지 검사한다.
10. 같은 길이의 memory 배열에 두 배 값을 넣어 반환하며 상태는 변경하지 않는다.

## 감사 포인트

- 입력 길이 상한이 없으면 가스 사용량이 무제한으로 증가해 호출 실패와 DoS를 일으킬 수 있다.
- 각 원소를 검사하지 않으면 배열 길이만 올바른 잘못된 점수가 저장될 수 있다.
- `delete`는 배열 길이를 줄이지 않고 빈 값이 있는 자리를 남긴다.
- memory 배열을 변경해도 원본 storage 배열은 변경되지 않는다.
- 인덱스 조건에 `<=`를 사용하면 범위를 벗어나 Panic이 발생한다.
