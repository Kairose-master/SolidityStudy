# 중간 과제: 실패하면 재시도할 수 있는 보상 지급기

## 진행 상태

과제 출제 후 사용자 요청으로 튜터 예시 답안 RewardStation.sol을 제공했다. 학습자의 독립 구현이나 실행 결과는 아직 제출되지 않았으며 과제 통과로 처리하지 않는다.

## 요구사항

- RewardStation은 claimed, points mapping과 nonReentrant 잠금을 사용한다.
- claim은 이미 받은 주소와 코드가 없는 호출자를 거부한다.
- 외부 콜백 전에 claimed=true와 10점 증가를 기록한다.
- 호출자의 onReward(10)이 성공하면 RewardGranted를 발생시킨다.
- 실패하면 지급 전 상태로 복구하고 RewardFailed를 발생시켜 재시도를 허용한다.
- TestReceiver는 Accept, Reject, Reenter 모드와 requestReward를 제공한다.
- onReward는 지급기만 호출할 수 있다. Reenter에서는 다시 claim을 호출하며 실패를 잡지 않는다.
- setMode는 테스트 편의를 위해 누구나 호출 가능하다. 이더는 사용하지 않는다.

## 실행 순서와 예상 결과

RewardStation 배포 → 그 주소로 TestReceiver 배포. mapping 키는 TestReceiver 주소다.

| 순서 | 모드와 실행 | 예상 |
|---|---|---|
| 1 | setMode(1), requestReward | 실패 이벤트, false, 0점 |
| 2 | setMode(2), requestReward | 실패 이벤트, false, 0점 |
| 3 | setMode(0), requestReward | 성공 이벤트, true, 10점 |
| 4 | requestReward 재실행 | Already claimed로 최상위 호출 실패 |

## 질문과 예시 답변

재진입이 실패해도 최초 requestReward 트랜잭션은 왜 성공할 수 있는가?

중첩 claim의 잠금 검사에서 revert → TestReceiver.onReward도 실패 → 최초 RewardStation.claim의 catch가 콜백 실패를 처리 → 상태 복구와 실패 이벤트 → 잠금 해제 → 정상 반환 순서다. 콜백 실패를 잡아도 콜백 전에 바꾼 지급기 상태는 자동 복구되지 않으므로 직접 복구한다. 정상 종료한 트랜잭션에 실패 이벤트가 남는다.
