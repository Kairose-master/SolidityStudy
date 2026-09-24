# 13강: 시간 제한과 타임아웃

새 개념은 작은 예제 실행 → 결과 관찰 → 원리 설명 → 통합 예제 순서로 학습한다. 첫 실습은 DeadlineLab.sol이며 아직 학습자 실행 확인 전이다.

## 첫 예제

DeadlineLab은 배포 블록 시각에서 120초 뒤를 deadline으로 저장한다. 그 전에는 주소별 한 번 입장할 수 있고, 그 시각부터는 누구나 close를 호출해 closed를 true로 기록할 수 있다. 자산이나 관리자 권한이 없는 연습 예제다.

- block.timestamp: 현재 실행에서 참조하는 블록의 Unix timestamp(초).
- 2 minutes: 숫자 120과 같다. 기다리거나 자동 실행하는 명령이 아니다.
- 입장은 timestamp < deadline, 마감 기록은 timestamp >= deadline으로 경계를 나눈다.
- 시간이 지나도 closed가 저절로 변경되지는 않는다. close 트랜잭션이 실행되어야 한다.
- closed가 false여도 기한이 지나면 enter는 실패한다. 기한 검사를 직접 하기 때문이다.

## 실험

1. 배포 후 deadline과 currentTime을 조회한다.
2. 기한 전에 enter는 성공하고 close는 Too early로 실패한다.
3. 기한 이후의 블록에서 다른 계정의 enter도 Too late로 실패한다.
4. close를 실행하기 전 closed는 false이며 close 성공 후 true가 된다.
5. close를 다시 실행하면 Already closed로 실패한다.

로컬 VM에서는 벽시계로 기다리는 것만으로 조회 블록 시각이 갱신되지 않을 수 있다. currentTime과 deadline을 비교해 판단하며, 필요하면 다른 연습 컨트랙트의 상태 변경 트랜잭션으로 새 블록을 만든 뒤 확인한다. 정확한 기한 경계는 추후 테스트에서 블록 시각을 제어해 검증한다.

## 다음 예제로 연결

commit-reveal에는 commit 기한과 reveal 기한 모두 필요하다. 미제출이나 미공개로 정상 종료되지 않아도, 기한 이후 호출할 수 있는 종료 경로를 마련한다. 한 명만 공개했을 때, 아무도 공개하지 않았을 때, 양쪽 공개가 끝났을 때의 결과를 각각 정해야 한다. 시간 제한만으로 공개를 강제하거나 자동 실행을 보장하지는 않는다.

## SOL-013 예정 연습: 기한이 있는 선택 공개

통합 예제 학습 뒤 진행한다. 배포 시 commitDeadline, revealDeadline을 고정하고 commit은 첫 기한 전, reveal은 첫 기한 이상 두 번째 기한 미만에 허용한다. 두 참가자의 commitment가 있어야 공개할 수 있다. 두 번째 기한 이후 누구나 expire를 호출해 미완료 게임을 종료할 수 있게 한다. 양쪽 공개 완료로 정상 종료된 게임은 다시 만료 처리하지 않는다. 자산·보상·승패는 이번 연습에서 제외한다.

[Solidity 공식 문서: 시간 단위와 블록 변수](https://docs.soliditylang.org/en/latest/units-and-global-variables.html)
