# 4강: 함수 상태 변경성과 제어문

## 학습 목표

- `view`, `pure`, `payable`의 차이를 구분한다.
- `msg.value`와 `address(this).balance`가 wei 단위 정수임을 이해한다.
- 산술·비교·논리 연산자를 사용한다.
- `if`, `else`, 삼항 연산자로 분기한다.
- `for`, `while`, `do while`, `break`, `continue`를 이해한다.
- 무제한 반복문과 검증 없는 입금의 보안 위험을 찾는다.

## 함수 상태 변경성

| 키워드 | 상태 읽기 | 상태 변경 | 이더 수신 |
|---|---:|---:|---:|
| `pure` | 불가 | 불가 | 불가 |
| `view` | 가능 | 불가 | 불가 |
| 지정 없음 | 가능 | 가능 | 불가 |
| `payable` | 가능 | 가능 | 가능 |

`view`는 상태를 읽을 수 있지만 변경할 수 없고, `pure`는 상태를 읽거나 변경할 수 없다. `payable`은 이더 수신을 허용할 뿐 금액이나 호출 권한을 검증하지 않는다.

```solidity
function calculate(uint256 a, uint256 b) public pure returns (uint256) {
    return a * b;
}

function balance() public view returns (uint256) {
    return address(this).balance;
}

function deposit() public payable {
}
```

`0.01 ether`는 소수 자료형이 아니다. 컴파일 시 `10_000_000_000_000_000 wei`라는 정수로 변환된다. `msg.value`와 컨트랙트 잔액도 wei 단위 `uint256`이다.

## 연산자

- 산술: `+`, `-`, `*`, `/`, `%`, `**`
- 비교: `==`, `!=`, `<`, `>`, `<=`, `>=`
- 논리: `&&`, `||`, `!`
- 축약 대입: `+=`, `-=`, `*=`, `/=`, `%=`
- 증감: `++`, `--`
- 삼항: `condition ? trueValue : falseValue`

정수 나눗셈은 소수점 이하를 버린다. Solidity 0.8 이상은 산술 오버플로와 언더플로 시 기본적으로 되돌리지만, `unchecked` 블록에서는 값이 순환하므로 명확한 증명 없이 사용하지 않는다.

## 조건문

조건식은 반드시 `bool`이어야 한다.

```solidity
if (score >= 1000) {
    rank = 3;
} else if (score >= 500) {
    rank = 2;
} else {
    rank = 1;
}
```

큰 범위나 구체적인 조건부터 검사한다. `&&`와 `||`는 단축 평가하므로 앞 조건만으로 결과가 정해지면 뒤 표현식을 실행하지 않는다.

## 반복문

```solidity
for (uint256 i = 0; i < rounds; i++) {
    total += damagePerRound;
}
```

`while`은 조건이 참인 동안 반복하고, `do while`은 본문을 최소 한 번 실행한다. `break`는 반복문 전체를 종료하고 `continue`는 현재 회차만 건너뛴다.

온체인 반복문은 가스를 소비한다. 저장 데이터의 크기에 따라 반복 횟수가 무제한으로 증가하면 블록 가스 한도를 넘어 기능이 영구적으로 실행 불가능해질 수 있다. 반복 횟수 상한, 종료 조건, 외부 호출 포함 여부와 `i < length` 경계를 감사한다.

## SOL-004: 아레나 금고

### 상태 변수

```solidity
uint256 public entryFee = 0.01 ether;
uint256 public totalDeposited = 0;
```

### 요구사항

1. `calculateReward(wins, rewardPerWin)`은 `public pure`이며 두 값을 곱한다.
2. `quoteEntry(players)`는 `public view`이며 상태 변수 `entryFee`와 인원수를 곱한다.
3. `depositEntryFee()`는 `public payable`이며 `msg.value`를 누적하고 갱신값을 반환한다.
4. `treasuryBalance()`는 `public view`이며 `address(this).balance`를 반환한다.
5. 생성자, 상속, `mapping`, 외부 호출과 출금 기능은 사용하지 않는다.

### 보안 질문

참가비가 정확히 `0.01 ether`인지 검사하지 않는다면 어떤 잘못된 입금이 가능한가?

## 감사 포인트

- `payable`은 금액 검사나 접근 제어가 아니다.
- 0 ETH, 1 wei, 부족한 금액과 과다 금액도 별도 검사가 없으면 수신한다.
- 입금자를 기록하지 않으면 입금과 참가 자격을 연결할 수 없다.
- `totalDeposited`와 `address(this).balance`가 언제나 같다고 가정하면 안 된다.
- 출금 경로가 없다면 받은 자금은 잠긴다.
