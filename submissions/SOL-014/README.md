# SOL-014: 게임 컨트랙트만 기록할 수 있는 점수판

## 결과

수정본 기준 통과. 학습자 제출의 인터페이스 scores 선언에 view를 추가했다. 채팅의 코드 울타리는 복사 흔적으로 제외했다. 실제 Remix 실행 완료 보고는 받지 않았다.

## 제출과 수정 기록

- 원문: `function scores(address player) external returns(uint256);`
- 수정: `function scores(address player) external view returns(uint256);`
- myScore는 view이므로 호출하는 외부 함수도 조회 함수로 선언되어야 한다. 실제 대상이 getter여도 호출 측 컴파일러는 인터페이스 선언을 기준으로 판단한다.
- 주소의 코드 존재 확인, 인터페이스 변환, 중복 훈련 방지, 외부 호출 전 상태 변경, 사용자에게 10점 지급은 요구사항을 충족했다.
- code.length 검사는 코드 존재만 확인하며 인터페이스 구현 여부나 안전성을 보증하지 않는다.

## 보안 답변

1. A → TrainingGame → ScoreBoard에서 ScoreBoard의 msg.sender: 학습자 답변 `TrainingGame`, 정답.
2. addScore(address(this), 10)의 수령자: 학습자 답변은 생략됨. 튜터가 TrainingGame 자신에게 점수가 쌓인다고 보완했다.
3. 실패 시 trained가 돌아가는 이유: 학습자 답변 `require는 원자적`. 튜터가 처리하지 않은 revert가 호출자까지 전파되어 해당 트랜잭션의 상태 변경이 되돌아간다고 정정했다.

## 재현

`../../lessons/14-external-calls/ScoreBoard.sol`을 먼저 배포한 뒤 그 주소로 TrainingGame을 배포한다. 승인 전 train은 실패하고 trained는 false다. owner가 setGame(TrainingGame 주소)을 호출한 뒤에는 주소별 첫 train으로 10점이 지급되고 중복 호출과 점수판 직접 호출은 거부된다.
