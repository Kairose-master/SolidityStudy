# 확장 트랙: ERC-4337 스마트 계정과 ERC-8004 에이전트 신뢰

2026-10-19 기준으로 학습 요청을 기록했다. 최신 명세는 [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337)과 [ERC-8004](https://eips.ethereum.org/EIPS/eip-8004)를 기준으로 매 수업 전에 확인한다. ERC-8004는 현재 초안(Draft Standards Track)이므로 사양·구현이 바뀔 수 있다.

## 큰 그림

- **ERC-4337**은 컨트랙트 계정이 서명 검증·실행 규칙을 갖고 UserOperation을 보내는 계정 추상화 흐름이다. Bundler가 작업을 모아 EntryPoint에 전달하고, Paymaster는 조건에 따라 사용자의 가스비를 대신 부담한다.
- **ERC-8004**는 에이전트를 찾고 신뢰 판단 자료를 교환하기 위한 레지스트리 규격이다. Identity Registry는 ERC-721 기반 식별과 등록 파일을 연결하고, Reputation Registry는 피드백 신호를, Validation Registry는 검증 요청과 응답을 기록한다.
- 두 표준의 연결 예: ERC-4337 스마트 계정으로 에이전트가 온체인 행동을 승인·실행하고, ERC-8004로 그 에이전트의 정체성과 평판·검증 기록을 조회한다. 하나가 다른 하나를 대체하지 않는다.

## 학습 순서

### A. ERC-4337

1. EOA 트랜잭션과 Smart Contract Account 비교
2. UserOperation이 일반 트랜잭션과 다른 이유
3. Account, EntryPoint, Bundler가 맡는 검증·실행 흐름
4. validateUserOp, 서명 해시, nonce와 replay 방지
5. Factory와 첫 사용 시 계정 배포
6. Paymaster를 통한 가스 후원, deposit/stake 및 실패 경로
7. Bundler 시뮬레이션, 검증 제한과 보안 위협
8. Foundry 예제로 최소 스마트 계정 호출 테스트

### B. ERC-8004

1. Agent ID와 전역 식별자 agentRegistry + agentId
2. Identity Registry의 ERC-721 등록 토큰과 Agent URI/등록 파일
3. Reputation Registry: 피드백 기록, 조회, 평점 해석의 한계
4. Validation Registry: 검증 요청·검증자 응답·증거 해시
5. Sybil, 스팸 피드백, 잘못된 능력 주장과 검증자 신뢰 모델
6. Foundry 예제로 에이전트 등록, 피드백, 검증 흐름 확인

### C. 통합 미니 프로젝트

로컬 ERC-4337 스마트 계정이 게임 행동을 실행하고, 별도 ERC-8004 레지스트리에 게임 에이전트 프로필을 등록한다. 경기 결과로 피드백을 남기고, 검증자는 결과 증거를 확인해 검증 응답을 기록한다. 지급이나 결제는 이 표준들이 자동으로 제공한다고 가정하지 않고 별도 설계한다.

## 첫 시간에 답할 질문

1. 일반 EOA가 서명한 트랜잭션과 UserOperation은 네트워크에 전달되는 경로가 어떻게 다른가?
2. ERC-8004에 에이전트 능력이 등록돼 있어도 그 능력이 실제로 작동한다고 보장되지 않는 이유는?
3. ERC-4337 지갑 주소와 ERC-8004 agentId는 왜 동일한 개념이 아닌가?
