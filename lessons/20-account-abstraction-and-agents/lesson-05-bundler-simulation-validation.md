# 확장 트랙 5강: Bundler 시뮬레이션과 검증 단계의 DoS 방어

**학습 목표:** Bundler가 UserOperation을 반복 검증하는 이유를 설명하고, validation 로직과 실제 execution 로직을 구분한다.

2026-10-23 공식 ERC-4337 명세와 ERC-7562 검증 범위 규칙을 확인했다. ERC-4337의 Account·Factory·Paymaster 검증은 EVM 상태에 의존할 수 있으므로, 일반 EOA 트랜잭션보다 Bundler가 떠안는 실패 위험이 크다.

## 핵심 개념

### 1. Bundler는 UserOperation을 한 번만 확인하지 않는다

공식 명세의 기본 흐름은 다음과 같다.

```text
UserOperation 수신
  → 1차: mempool에 넣기 전 개별 검증
  → 2차: bundle 후보를 고를 때 다시 개별 검증
  → 3차: 온체인 제출 직전 전체 bundle 검증
  → EntryPoint.handleOps 트랜잭션 제출
```

각 단계 사이에 블록과 상태가 바뀔 수 있다. 처음 검증할 때 유효했던 nonce가 다른 요청으로 소비되거나, Paymaster deposit이 줄거나, 유효 시간이 지나면 나중 검증에서는 실패할 수 있다. 따라서 “RPC가 처음 받아줬다”는 사실은 최종 온체인 성공 보장이 아니다.

### 2. validation과 execution은 목적이 다르다

| 구간 | 질문 | 대표 작업 |
|---|---|---|
| validation | 이 요청을 승인하고 비용을 지불할 수 있는가? | 계정 생성, nonce·서명·유효 시간, Paymaster 승인 |
| execution | 승인된 요청이 실제로 무엇을 실행하는가? | 토큰 전송, 게임 공격, NFT 예치 |

Bundler의 시뮬레이션은 우선 Account의 `validateUserOp`, 필요하면 Factory 배포와 Paymaster의 `validatePaymasterUserOp`을 검사한다. 실행 대상 게임 함수가 성공할지는 별개의 문제이며, 검증에 통과한 뒤 본 실행이 revert할 수도 있다.

### 3. 검증 코드에는 별도 제한이 필요하다

공격자가 수많은 UserOperation을 보내 Bundler에게 비싼 검증을 시킨 뒤, 실제 제출 직전에만 실패하게 만들 수 있다. Bundler는 검증 비용을 선불로 받지 못하므로 이것이 DoS가 된다.

ERC-7562는 이런 공격을 줄이기 위해 validation 단계가 사용할 수 있는 opcode와 storage 접근 범위를 제한한다. 핵심 목표는 검증 결과가 다른 사용자의 임의 행동이나 쉽게 변하는 전역 상태에 과도하게 의존하지 않도록 만드는 것이다.

## 짧은 예시

다음 검증은 게임의 변하기 쉬운 전역 상태에 직접 의존한다.

```solidity
// 교육용 나쁜 예시
function _validateUserOp(
    PackedUserOperation calldata userOp,
    bytes32 userOpHash
) internal view returns (uint256) {
    require(game.currentRound() == 7, "round changed");
    return verifyOwner(userOpHash, userOp.signature);
}
```

mempool에 들어갈 때는 7라운드였더라도 다른 플레이어가 먼저 행동해 8라운드가 되면 bundle 검증이 실패한다. 많은 요청이 이 패턴을 사용하면 Bundler가 반복해서 묶음을 다시 만들어야 한다.

보통 계정 validation은 계정 권한에 집중한다.

```text
validation:
  trusted EntryPoint인가?
  nonce가 유효한가?
  owner/session key 서명이 맞는가?
  서명된 유효 시간이 남았는가?
  비용을 지불할 수 있는가?

execution:
  게임의 현재 라운드·턴·HP 조건을 확인하고 attack() 실행
```

게임 조건을 execution에서 검사한다고 실패 가스가 없어지는 것은 아니다. 대신 계정 권한 검증과 게임 규칙을 분리해 Bundler 검증을 더 예측 가능하게 만든다.

## 실패 책임 추적

전체 bundle 시뮬레이션이 revert하면 Bundler는 trace를 이용해 어느 주체가 문제를 일으켰는지 찾는다.

- `AA1x`: sender 생성 또는 Factory 경로
- `AA2x`: Account의 `validateUserOp`
- `AA3x`: Paymaster 검증 경로

문제를 일으킨 UserOperation은 bundle과 mempool에서 제거된다. Factory나 Paymaster가 반복적으로 문제를 일으키면 평판 시스템에서 제한될 수 있다.

## 실무에서 주의할 점

- `eth_sendUserOperation` 성공 응답을 게임 행동의 최종 성공으로 취급하지 않는다. UserOperation receipt나 온체인 이벤트로 결과를 확인한다.
- validation에서 외부 프로토콜 가격, 게임의 공용 라운드처럼 다른 사용자가 쉽게 바꿀 수 있는 상태에 의존하지 않는다.
- `validUntil`을 너무 촉박하게 설정하면 다음 블록 전에 만료될 가능성이 있어 Bundler가 거절할 수 있다.
- gas limit을 과도하게 잡는 것도 안전하지 않다. 번들 공간을 예약하고 사용하지 않는 행위에는 명세상 페널티가 적용될 수 있다.
- Bundler마다 지원하는 EntryPoint 버전과 mempool 정책이 다를 수 있으므로 “한 Bundler가 수락하면 모두 수락한다”고 가정하지 않는다.
- 검증 실패와 실행 실패를 로그·UI에서 구분한다. 전자는 요청이 실행 단계에 진입하지 못한 것이고, 후자는 승인 뒤 대상 호출이 revert한 것이다.

## 이해 확인 질문

UserOperation이 처음 Bundler의 mempool 검증에는 통과했는데 블록 제출 직전 제거될 수 있는 이유를 하나 들고, 그 문제를 줄이기 위해 validation과 execution을 어떻게 나눠야 할까?

## 공식 참고자료

- [ERC-4337 공식 명세 — Bundler와 Simulation](https://eips.ethereum.org/EIPS/eip-4337)
- [ERC-7562 검증 범위 규칙](https://eips.ethereum.org/EIPS/eip-7562)
