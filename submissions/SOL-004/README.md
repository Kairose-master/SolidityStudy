# SOL-004 채점 기록

## 결과

통과

## 충족한 요구사항

- `calculateReward`: 매개변수만 사용하는 `pure` 계산
- `quoteEntry`: 상태 변수 `entryFee`를 읽는 `view` 계산
- `depositEntryFee`: `payable`로 이더를 받고 `msg.value` 누적
- `treasuryBalance`: 실제 컨트랙트 잔액 조회

## 정규화

학습자는 `GPL-3.0`, `pragma solidity >=0.8.2 <0.9.0`으로 제출했다. 함수 논리에는 문제가 없으므로 통과 처리하고, 문제 명세와 저장소 기준에 맞춰 저장본은 `MIT`, `^0.8.24`로 통일했다.

최종 제출의 `return totalDeposited = totalDeposited + msg.value;`는 유효하다. 저장본은 상태 변경과 반환을 감사하기 쉽도록 두 문장으로 정규화했다. 채팅의 `\*`와 특수 공백은 복사 흔적으로 보고 무시했다.

## 보안 답변

학습자는 구현 전에 입금 함수가 위험해 보인다고 지적했다. 정확한 참가비 검사가 없으므로 0 ETH, 1 wei, 부족한 금액 또는 과다 금액으로도 호출할 수 있다. 입금자별 기록과 중복 참가 검사도 없으며, 출금 함수가 없어 받은 자금은 잠긴다.

`treasuryBalance`는 읽기 전용이고 온체인 잔액은 원래 공개 정보다. 그러나 `totalDeposited`는 이 함수가 기록한 합계이고 `address(this).balance`는 실제 잔액이므로 두 값이 항상 같다고 가정해서는 안 된다.

## 다음 강화 단계

- `require` 또는 사용자 정의 오류로 정확한 참가비 검사
- `mapping`으로 주소별 참가 및 입금 기록
- 접근 제어와 안전한 출금 구조
- 출금 시 재진입 방어와 Checks-Effects-Interactions 적용
