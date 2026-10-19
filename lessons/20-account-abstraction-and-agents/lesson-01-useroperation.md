# 확장 트랙 1강: ERC-4337의 UserOperation과 실행 흐름

**학습 목표:** 일반 EOA 트랜잭션과 ERC-4337의 UserOperation 흐름을 구분하고, Account·Bundler·EntryPoint 역할을 설명한다.

2026-10-19 공식 명세를 확인했다. ERC-4337은 최종 표준 트랙 문서다. 이 수업은 기본 흐름만 다루며, UserOperation의 구체적인 wire 형식은 구현 버전에 따라 달라질 수 있다.

## 핵심 개념

일반 EOA는 개인키로 서명한 Ethereum 트랜잭션을 네트워크에 보낸다. 유효성 규칙은 프로토콜이 정한다. ERC-4337에서는 사용자가 원하는 행동을 **UserOperation**이라는 별도의 요청 객체로 만든다. 이 객체 자체는 Ethereum의 일반 트랜잭션이 아니다.

스마트 계정은 컨트랙트이므로, 계정마다 서명·다중서명·세션키 등 권한 확인 규칙을 프로그래밍할 수 있다. UserOperation을 받은 **Bundler**는 작업을 시뮬레이션하고 여러 작업을 묶은 일반 Ethereum 트랜잭션을 만들어 **EntryPoint**의 handleOps를 호출한다. EntryPoint는 계정의 validateUserOp로 권한을 확인한 뒤 계정이 요청한 작업을 실행하게 한다.

| 구성요소 | 역할 |
|---|---|
| Smart Contract Account | UserOperation의 권한·서명 규칙을 검증하고 요청된 호출을 수행 |
| Bundler | UserOperation을 받아 검증을 시뮬레이션하고 묶음 트랜잭션을 제출 |
| EntryPoint | 온체인에서 UserOperation 묶음의 검증·수수료 정산·실행을 조정 |
| Paymaster | 정책에 동의하는 경우 사용자 대신 가스비를 부담 |

### 실행 흐름

    사용자가 앱에서 게임 행동 요청
      → 지갑이 스마트 계정용 UserOperation 구성 및 서명
      → Bundler에 eth_sendUserOperation으로 제출
      → Bundler가 오프체인 시뮬레이션
      → Bundler가 일반 트랜잭션으로 EntryPoint.handleOps 호출
      → EntryPoint가 Account.validateUserOp로 권한 확인
      → 유효하면 Account가 callData의 게임 행동 실행
      → 비용은 계정 예치금 또는 승인된 Paymaster에서 정산

정식 요청에는 발신 계정, nonce, 실행할 callData, 가스 한도·수수료, 서명 등이 들어간다. 첫 배포를 위한 factory 데이터와 paymaster 데이터도 포함될 수 있다. EntryPoint에 전달될 때는 PackedUserOperation 형태를 쓴다. 세부 인코딩은 사용하는 ERC-4337 버전과 구현에 맞춰야 한다.

## 짧은 예시

Alice가 게임에서 영웅을 방어 태세로 바꾸려 한다고 하자.

1. 앱은 setDefense(true) 호출 데이터를 만든다.
2. 지갑은 이 호출을 스마트 계정에서 실행하도록 UserOperation을 만들고 서명한다.
3. Bundler는 서명·nonce·가스 지불 가능성 등을 검사해 묶음으로 제출한다.
4. EntryPoint는 스마트 계정에 작업 권한이 있는지 확인하고, 계정이 게임 컨트랙트의 setDefense(true)를 호출하게 한다.
5. Alice의 계정 잔액에서 비용을 내거나, 앱이 Paymaster를 제공했다면 Paymaster가 조건에 따라 비용을 부담한다.

사용자는 게임 컨트랙트를 직접 바꾸지 않아도 되고, 스마트 계정의 권한 로직과 EntryPoint 흐름을 통해 호출이 전달된다.

## 실무에서 주의할 점

- UserOperation을 일반 Ethereum 트랜잭션이라고 부르지 않는다. 온체인에는 Bundler가 제출한 트랜잭션이 기록되고, UserOperation은 별도 mempool/RPC 흐름으로 전달된다.
- 가스가 없어지는 것은 아니다. 비용을 누가 부담하는지 계정 예치금과 Paymaster 정책으로 바꾸는 것이다.
- Bundler나 프런트엔드의 검증 결과만 믿지 않는다. 스마트 계정은 신뢰할 EntryPoint 호출인지 확인하고, 서명·nonce 등 권한을 직접 검증해야 한다.
- 서명 해시는 chain ID와 EntryPoint 주소에 묶어 재생 공격을 막아야 한다.
- ERC-4337의 필드 구조와 배포 EntryPoint 버전이 항상 같다고 가정하지 않는다. 특히 최신 명세에는 EIP-7702 지원 경로도 있으므로 실습 시 선택한 라이브러리·네트워크 버전을 확인한다.

## 이해 확인 질문

앱에서 서명한 UserOperation이 있는데도, 실제 Ethereum 블록에 들어가기 전에 Bundler와 EntryPoint가 각각 필요한 이유는 무엇일까?

## 공식 참고자료

- [ERC-4337 공식 명세](https://eips.ethereum.org/EIPS/eip-4337)
- [ERC-7769 UserOperation JSON-RPC 명세](https://eips.ethereum.org/EIPS/eip-7769)
