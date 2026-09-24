# 15강: try/catch와 외부 호출 실패 처리

학습 상태: 설명과 예제 제공 후 다음 강의로 진행. 독립 제출이나 학습자의 실행 결과는 확인되지 않았다.

## 관찰한 문제

train에서 trained를 true로 바꾸고 외부 addScore를 호출한다. 실패를 잡지 않으면 전체 호출로 revert가 전파된다. catch로 잡으면 외부 호출에서 수행한 상태 변경은 되돌아가지만 호출 전 TrainingGame의 trained 변경은 남을 수 있다. 따라서 지급에 실패했는데 재시도할 수 없는 상태가 생긴다.

## 복구 예제

TrainingWithRecovery.sol은 두 catch에서 trained를 false로 복구하고 실패 이벤트를 발생시킨다. catch Error(string memory reason)은 문자열 오류를, 마지막 catch는 나머지 실패를 처리한다. 함수 앞의 require와 성공 처리 블록 자체의 오류를 이 try/catch가 모두 잡는 것은 아니다.

## 실행 순서

14강 ScoreBoard 배포 → 복구 예제 배포 → 승인 전에 train → trained=false와 0점, 실패 이벤트 확인 → owner가 setGame으로 승인 → train 재시도 → trained=true와 10점 확인 → 재시도 거부 확인.

처리한 외부 호출 실패와 최상위 트랜잭션 실패는 다르다. 실패를 catch에서 처리하고 정상 종료하면 실패 이벤트도 남는다.
