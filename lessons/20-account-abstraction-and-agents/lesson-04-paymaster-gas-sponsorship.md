# 확장 트랙 4강: ERC-4337 Paymaster와 가스 후원

**학습 목표:** Paymaster의 승인·정산 흐름을 설명하고, 가스 비용을 내는 deposit과 DoS 방어를 위한 stake를 구분한다.

2026-10-22 공식 ERC-4337 명세와 공식 BasePaymaster 참조 구현을 확인했다. Paymaster는 사용자의 가스를 없애는 기능이 아니라, 정책에 동의한 UserOperation의 네이티브 가스 비용을 대신 부담하는 컨트랙트다.

## 핵심 개념

### 1. Paymaster는 조건부 가스 후원자다

UserOperation에 Paymaster 정보가 없다면 스마트 계정의 EntryPoint 예치금으로 비용을 낸다. Paymaster가 지정되면 EntryPoint는 다음을 확인한다.

1. Paymaster가 컨트랙트인지 확인한다.
2. Paymaster의 EntryPoint deposit이 최대 예상 비용을 감당할 수 있는지 확인한다.
3. `validatePaymasterUserOp`를 호출해 Paymaster가 이 요청을 후원할 의사가 있는지 확인한다.
4. 승인되면 계정의 행동을 실행한다.
5. 필요한 경우 `postOp`를 호출해 성공·실패 결과와 실제 가스 비용을 전달한다.
6. 실제 비용을 Paymaster의 deposit에서 차감한다.

Paymaster를 사용하는 요청에서는 계정의 `validateUserOp`에 전달되는 `missingAccountFunds`가 0이다. 이번 요청의 가스비를 계정 예치금이 아닌 Paymaster가 부담하기 때문이다.

### 2. deposit과 stake는 목적이 다르다

| 구분 | 목적 | 사용 방식 |
|---|---|---|
| deposit | UserOperation의 실제 가스비 지급 | EntryPoint가 실행 비용을 차감 |
| stake | 검증 과정의 DoS·평판 위험 완화 | 일정 기간 잠기며 일반 가스비로 차감되는 잔액이 아님 |

deposit이 충분하지 않으면 후원 요청은 검증을 통과할 수 없다. stake가 필요한지는 Paymaster가 검증 중 어떤 상태를 접근하는지와 Bundler 정책에 영향을 받는다. 큰 stake가 있다고 가스비 deposit을 대신할 수는 없다.

## 짧은 코드 예시

다음은 승인 흐름만 보여 주는 축약 예시다. 실제 구현에서는 공식 인터페이스와 선택한 EntryPoint 버전의 인코딩을 사용해야 한다.

```solidity
mapping(address => bool) public sponsoredPlayers;

function _validatePaymasterUserOp(
    PackedUserOperation calldata userOp,
    bytes32,
    uint256 maxCost
)
    internal
    view
    returns (bytes memory context, uint256 validationData)
{
    require(sponsoredPlayers[userOp.sender], "not sponsored");
    require(maxCost <= 0.005 ether, "cost too high");

    // postOp에서 어떤 계정의 비용인지 알기 위한 데이터
    context = abi.encode(userOp.sender);
    validationData = 0; // 이 예시에서는 시간 범위 제한 없이 승인
}
```

Paymaster가 비어 있지 않은 `context`를 반환하면 실행 뒤 `postOp`가 호출된다.

```text
validatePaymasterUserOp 승인
        ↓
게임 호출 실행
        ↓
성공: postOp(opSucceeded, context, actualGasCost, ...)
실패: postOp(opReverted,  context, actualGasCost, ...)
        ↓
두 경우 모두 Paymaster deposit에서 사용된 가스비 지급
```

게임 호출이 revert됐다고 검증과 시뮬레이션에 이미 사용된 가스까지 사라지는 것은 아니다. Paymaster는 실행 결과가 실패여도 실제 소비된 가스비를 부담한다.

## 게임에 적용한 예

게임사가 신규 플레이어의 첫 경기만 후원한다고 하자.

- 서버 또는 온체인 정책이 “첫 경기인지” 확인한다.
- Paymaster가 해당 UserOperation만 승인한다.
- 플레이어는 네이티브 토큰이 없어도 첫 경기 행동을 보낼 수 있다.
- 두 번째 경기부터는 Paymaster가 거절하거나, 별도의 토큰 결제 정책을 적용할 수 있다.

이 구조에서 게임 컨트랙트의 참가비와 네트워크 가스비는 별개다. Paymaster가 가스를 후원해도 게임 컨트랙트가 요구하는 ERC-20 참가비까지 자동으로 대신 내는 것은 아니다.

## 실무에서 주의할 점

- `validatePaymasterUserOp`와 `postOp`는 신뢰하는 EntryPoint만 호출할 수 있게 검사해야 한다.
- “누구나 무료” 정책은 봇이 deposit을 고갈시키는 공격으로 이어질 수 있다. sender, 함수 selector, 최대 비용, 사용 횟수, 유효 기간 등을 제한한다.
- 실행이 실패해도 Paymaster는 사용된 가스비를 낸다. 실패를 반복하는 요청과 과도한 gas limit을 정책에서 차단한다.
- `postOp` 자체가 실패하면 번들 처리와 Paymaster 평판에 악영향을 줄 수 있다. 최소한의 로직만 수행하고 외부 호출을 신중히 다룬다.
- ERC-20으로 가스비를 받는 Paymaster라면 가격 변동, allowance, 소수점, 수수료 계산과 토큰 전송 실패까지 별도로 설계해야 한다.
- deposit과 stake를 혼동하지 않는다. 운영 모니터링에서는 두 잔액과 unlock 대기 상태를 따로 확인한다.

## 이해 확인 질문

후원받은 게임 호출이 실행 도중 revert됐을 때도 Paymaster가 가스비를 부담하는 이유는 무엇이며, 그 비용은 stake와 deposit 중 어디에서 차감될까?

## 공식 참고자료

- [ERC-4337 공식 명세 — Paymaster 확장](https://eips.ethereum.org/EIPS/eip-4337)
- [공식 BasePaymaster 참조 구현](https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/core/BasePaymaster.sol)
