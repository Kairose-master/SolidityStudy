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

## SOL-014: 승인된 게임의 점수판

튜터가 제공한 ScoreBoard.sol을 배포하고, 학습자는 IScoreBoard와 TrainingGame을 작성했다. 생성자에서 주소에 코드가 있는지 검사하고 인터페이스로 저장한다. train은 주소별 한 번만 허용하며 trained를 먼저 변경하고 점수판에 호출자 10점을 기록한다. myScore는 인터페이스의 scores getter로 현재 호출자의 점수를 반환한다.

점수판 owner는 setGame으로 게임 컨트랙트를 승인한다. 승인 전 train은 실패하며 trained도 되돌아가야 한다. 승인 후 사용자별 첫 훈련은 성공하고 중복 훈련과 사용자의 점수판 직접 호출은 거부되어야 한다.

제출의 scores 인터페이스 선언에 view가 누락되어 수정했다. 수정본 기준 통과했으며 [제출과 채점 기록](../../submissions/SOL-014/README.md)에 원래 실수와 보안 답변을 보존했다.

## 추가 질문에서 정리한 내용

- IScoreBoard public board는 타입·공개 여부·변수 이름으로 구성된 선언이다. IScoreBoard(boardAddress)는 생성자 인자를 인터페이스 타입으로 변환한다.
- 구현 소스가 있으면 Counter 같은 구체적인 컨트랙트 타입도 사용할 수 있다. 인터페이스는 필요한 함수만 선언할 수 있다.
- 소스가 없어도 ABI 또는 알려진 함수 규격으로 호출할 수 있다. 주소만으로 정확한 ABI를 자동 복원할 수는 없다.
- 저수준 call 성공만으로 의도한 함수의 실행을 보장할 수 없다. fallback이 대신 실행될 수도 있다.
- tx.origin 검사 예제에서는 owner → 중간 컨트랙트 → 대상 순서의 호출이 권한 검사를 통과할 수 있음을 설명했다. 권한 검사에는 직접 호출자인 msg.sender를 사용한다.

[Solidity 공식 문서: 외부 함수 호출](https://docs.soliditylang.org/en/latest/control-structures.html#external-function-calls)
