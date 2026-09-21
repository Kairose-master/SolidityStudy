# SOL-010 채점 기록

## 결과

수정본 기준 통과. 학습자가 작성한 제출 코드에 요청한 오류 수정을 반영했다. 보안 답변 원문과 보완 설명은 아래에 구분해 기록한다.

## 충족한 요구사항

- 생성자에서 배포자를 owner로 저장
- onlyOwner로 운영자 지정과 정지 기능 제한
- onlyModerator로 owner 또는 등록된 운영자의 차단 기능 허용
- 모든 modifier에서 조건 검사 후 `_;`로 함수 본문 실행
- 인자를 받는 notBanned modifier로 호출자의 차단 상태 검사
- 정지, 차단, 중복 입장 검사 후 입장 상태 저장 및 true 반환
- 역할 지정과 차단 시 0 주소 거부
- 상태 변경에 대응하는 네 종류의 이벤트 발생
- 권한 검사에 msg.sender 사용; 상속, 외부 호출, 이더 전송, 소유권 이전 미사용

## 내가 한 실수와 수정

| 초기 제출 | 문제와 영향 | 수정 |
|---|---|---|
| 선언은 `whenNotpaused`, 사용은 `whenNotPaused` | 식별자는 대소문자를 구분하므로 modifier를 찾지 못해 컴파일 실패 | 선언을 `whenNotPaused`로 통일 |
| `entered[msg.sender] == true;` | 비교만 하고 상태를 저장하지 않아 반복 입장 가능 | 대입 연산자로 `entered[msg.sender] = true;` 사용 |
| setModerator에서 이벤트 누락 | 상태는 변경되지만 과제에서 요구한 역할 변경 로그가 남지 않음 | `emit ModeratorUpdated(account, allowed);` 추가 |

`==`는 비교, `=`는 대입이다. SOL-009에서도 같은 상태 변경 실수가 있었으므로 상태를 바꾸는 줄에서 대입 여부를 확인한다. modifier의 인자 선언과 `notBanned(msg.sender)` 호출은 올바르게 작성했다. `paused == false`와 `entered[msg.sender] == false`도 올바른 조건식이며, 수정본에서는 `!paused`와 `!entered[msg.sender]`로 간결하게 표현했다. 채팅의 코드 울타리는 복사 흔적으로 처리했다.

## 보안 질문과 답변

### 1. owner를 private로 선언하면 관리자 주소가 온체인에서 비밀이 되는가?

- 제출 답변: “아니오”
- 판정: 정답.
- 설명: private는 Solidity 코드 수준의 접근 범위를 제한할 뿐이다. 온체인 저장 데이터는 외부에서 분석할 수 있으므로 비밀이 되지 않는다.

### 2. 권한 검사에 tx.origin을 사용하면 어떤 공격이 가능한가?

- 제출 답변: “tx가로챔 공격”
- 판정: 공격 방식 설명 보완 필요.
- 보완 답변: 관리자가 악성 중간 컨트랙트를 호출하도록 속이는 피싱 공격이 가능하다. 호출 흐름이 `owner → 악성 컨트랙트 → Arena`이면 Arena에서 msg.sender는 악성 컨트랙트지만 tx.origin은 owner이다. tx.origin으로 검사하면 악성 컨트랙트의 호출이 관리자 권한 검사를 통과할 수 있다. 트랜잭션 자체를 가로채거나 서명을 위조하는 공격을 뜻하지 않는다.

### 3. 관리자 키가 탈취되면 공격자가 수행할 수 있는 행동은 무엇인가?

- 제출 답변: “onlyOwner의 권한”
- 판정: 일부 맞지만 권한 범위 보완 필요.
- 보완 답변: setModerator로 운영자를 지정·해제하고 setPaused로 입장을 정지·재개할 수 있다. onlyModerator는 owner도 허용하므로 setBanned로 사용자를 차단·해제할 수도 있다. owner라고 해서 enterArena의 정지·차단·중복 입장 검사를 자동으로 건너뛰지는 않는다.

## 검증

- Solidity 0.8.24 컴파일 확인.
