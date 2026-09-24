# 14강: 컨트랙트 간 호출과 interface

## 예제 실행

CallLab.sol을 컴파일하고 Counter를 먼저 배포한다. Counter 주소를 생성자 인자로 넣어 CounterCaller를 배포한다.

| 실행 | Counter에서 관찰 |
|---|---|
| 계정 A가 Counter.increment 직접 호출 | count = 1, lastCaller = A |
| A가 CounterCaller.callIncrement 호출 | count = 2, lastCaller = CounterCaller 주소 |
| CounterCaller.readCount 조회 | Counter의 count인 2 반환 |

새 배포 직후 위 순서로 실행한 예상값이다. 학습자의 실행 확인은 아직 받지 않았다.

## 개념

- interface는 외부 함수를 호출하기 위한 함수 선언 목록이며 이 예제에서는 별도로 배포하지 않는다.
- ICounter(counterAddress)는 주소를 해당 인터페이스 타입으로 다루는 형변환이다. 새 컨트랙트를 배포하지 않는다.
- 형변환이 해당 주소의 함수 구현이나 안전성을 검증해주지는 않는다. code.length 검사도 코드 존재만 확인한다.
- Counter의 public count에는 자동 getter가 생성된다. 다른 컨트랙트는 counter.count()로 함수를 호출해 읽는다.
- 일반 외부 호출 A → CounterCaller → Counter에서 Counter의 msg.sender는 CounterCaller다.
- CounterCaller 내부 address(this)는 CounterCaller, Counter 내부 address(this)는 Counter다.
- 이 호출 체인은 하나의 트랜잭션 안에서 실행된다. 일반 고수준 외부 호출의 revert를 잡지 않으면 호출자에게 전파된다.

## 다음 실험

Counter.increment에 owner 전용 제한을 넣으면 owner 계정의 직접 호출과 CounterCaller를 통한 호출은 결과가 달라진다. 외부 호출 시 권한이 자동 전달되지 않음을 확인한다. 이를 tx.origin 검사로 우회하지 않고, 허용할 호출 컨트랙트와 권한 범위를 명시적으로 설계한다.

## SOL-014 예정 과제

예제 학습 뒤 운영자가 승인한 게임 컨트랙트만 점수를 기록할 수 있는 ScoreBoard와 인터페이스 기반 호출 컨트랙트를 설계한다. 아직 상세 과제를 출제하거나 제출받지 않았다.

[Solidity 공식 문서: 외부 함수 호출](https://docs.soliditylang.org/en/latest/control-structures.html#external-function-calls)
