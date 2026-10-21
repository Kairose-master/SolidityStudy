# SolidityStudy 학습 세션 인계

마지막 갱신: 2026-10-21

## 최종 목표

보안 감사에서 치명적인 취약점이 발견되지 않는 Solidity 게임을 직접 구현한다.

- 튜터는 강의, 과제 설계, 위협 모델, 채점과 감사를 담당한다.
- 학습자는 과제와 최종 게임 코드를 AI의 구현 대행 없이 직접 작성한다.
- 최종 게임 설계는 튜터가 제공하되 실제 구현은 학습자가 수행한다.

## 진행 방식

- GitBook의 Solidity 목차를 순서대로 학습한다.
- 매 강의마다 독자적인 백준식 문제를 하나 낸다.
- 새로운 개념은 사용자 요청에 따라 작은 실행 예제 → 결과 관찰 → 통합 코드 순서로 가르친 뒤 과제로 이어간다. 일반 학습 예제의 완성 코드 제공은 허용되며 최종 게임의 독립 구현 원칙과 구분한다.
- 제출은 문법, 구조, 동작과 보안 답변을 기준으로 채점한다.
- 채팅과 Markdown 복사 과정의 특수 공백, `\_`, `\*`, 코드 울타리 흔적은 실제 논리가 명확하면 감점하지 않는다.
- 실제 식별자, 반환형, 상태 변경, 접근 제어 오류는 수정해야 한다.
- 강의 진행·과제 채점·예시 답안 제공 뒤 기록과 파일을 GitHub `main`에 커밋하고 푸시한다. 사용자가 진행 기록 누락을 지적했으므로 채팅에만 남기지 않는다.

## 완료한 강의

| 강의 | 주제 | 문제 | 상태 |
|---|---|---|---|
| 1강 | 컨트랙트 선언과 `pragma` | SOL-001 두 번의 인사 | 통과 |
| 2강 | 변수와 자료형, 가시성 | SOL-002 안전한 게임 설정 | 통과 |
| 3강 | 함수, 반환값, 내부·외부 호출 | SOL-003 전투 피해 계산기 | 통과 |
| 4강 | `view`, `pure`, `payable`, 연산자와 제어문 | SOL-004 아레나 금고 | 통과 |
| 5강 | `mapping`, 중첩 mapping, 기본값과 삭제 | SOL-005 플레이어 레지스트리 | 통과 |
| 6강 | `require`, `revert`, `assert`, 원자성과 불변식 | SOL-006 안전한 훈련소 | 통과 |
| 7강 | `event`, `emit`, `indexed`와 로그 | SOL-007 아레나 경기 기록소 | 통과 |
| 8강 | 배열, `storage`, `memory`, `calldata` | SOL-008 훈련 점수 기록부 | 통과 |
| 9강 | 구조체와 열거형 | SOL-009 미니 결투 상태 머신 | 통과 |
| 10강 | 접근 제어와 modifier | SOL-010 아레나 운영 권한 | 수정 후 통과 |
| 13강 | 시간 제한과 타임아웃 | SOL-013 기한이 있는 선택 공개 | 클리어 (개념 확인, 코드 제출 생략) |
| 14강 | 컨트랙트 간 호출과 interface | SOL-014 승인된 게임의 점수판 | 수정 후 통과 |

## 핵심 학습 기록

- `msg.sender`는 호출자의 신원을 제공하지만 행동 권한이나 입력값의 정당성을 보장하지 않는다.
- `private` 상태도 온체인에서는 비밀이 아니다.
- 이름 있는 반환 변수가 상태 변수와 같으면 섀도잉이 발생할 수 있다.
- `payable`은 이더 수신을 허용할 뿐 정확한 금액이나 참가 자격을 검사하지 않는다.
- `0.01 ether`는 소수가 아니라 컴파일 시 wei 단위 정수로 변환된다.
- mapping에서 쓰지 않은 키는 기본값을 반환하므로 존재 여부를 별도로 기록해야 한다.
- mapping은 키 목록과 길이가 없어 직접 순회하거나 내부 키 전체를 자동 삭제할 수 없다.
- `msg.sender`를 mapping 키로 사용하면 다른 사용자의 상태 조작은 막을 수 있지만 자기 보상을 무제한 생성하는 문제는 별도 권한 검사가 필요하다.
- 실패한 호출에서는 그 호출이 수행한 상태 변경이 원자적으로 되돌아간다.
- `require`는 외부 입력과 실행 전제조건, `assert`는 내부 불변식 검사에 사용한다.
- 사용자 정의 오류는 실패에 구체적인 값을 담을 수 있고 오류 문자열보다 가스를 줄일 수 있다.
- Checks-Effects-Interactions 순서에서 입력과 권한 검사를 상태 변경보다 먼저 수행한다.
- 이벤트는 외부에서 상태 변경을 추적하는 로그이며 컨트랙트가 읽는 상태나 접근 제어를 대신하지 않는다.
- `indexed` 매개변수는 주소와 같은 값으로 이벤트를 필터링하기 위한 토픽을 만든다.
- 실패한 호출에서 발생한 이벤트도 상태 변경과 함께 되돌아가 최종 로그에 남지 않는다.
- 실제 결과 검증이 없다면 올바른 형식의 이벤트도 거짓 행동을 기록할 수 있다.
- 동적 storage 배열은 `push`와 `pop`으로 길이를 변경하며 `delete`는 원소를 기본값으로 바꿀 뿐 길이를 줄이지 않는다.
- 지역 storage 참조를 변경하면 원본 상태가 바뀌지만 memory 복사본 변경은 원본 상태에 영향을 주지 않는다.
- calldata는 외부 호출의 읽기 전용 입력이며 수정할 필요가 없는 배열 인자에 적합하다.
- 온체인 반복문의 길이는 가스 기반 DoS를 막기 위해 명확한 상한을 두어야 한다.

## 최근 제출: SOL-014

학습자의 TrainingGame 제출은 scores 인터페이스에 view가 빠져 있었다. 이를 추가한 수정본 기준으로 통과했다. 코드와 실수·보안 답변은 `submissions/SOL-014/`에 저장했다. 학습자의 Remix 실행 완료 보고는 받지 않았다.

보안 답변: 직접 호출자는 TrainingGame이라는 답은 정답. address(this) 수령자는 튜터가 보완했다. 'require는 원자적'이라는 표현은 처리하지 않은 revert가 전파되어 트랜잭션의 변경이 되돌아간다는 설명으로 정정했다.

## 현재 강의

15~17강 예제 설명 후 중간 과제 예시 답안까지 제공한 상태다.

- 15강: try/catch로 외부 실패를 처리하면 호출 전 상태가 남으므로 실패 경로에서 복구해야 한다. `lessons/15-try-catch/`.
- 16강: 콜백 재진입으로 20점 중복 지급을 유발하는 예제와 CEI 수정본. `lessons/16-reentrancy/`.
- 17강: nonReentrant 잠금, modifier의 본문 뒤 실행, revert에 의한 잠금 상태 복구. `lessons/17-reentrancy-guard/`.
- 중간 과제: RewardStation과 Accept/Reject/Reenter 모드 TestReceiver. 사용자 요청으로 완성 예시 답안 제공. `exercises/reward-station/`.
- 15~17강 및 중간 과제의 학습자 실행 완료·독립 구현 제출은 확인하지 않았다. 예시 답안을 학습자 제출로 간주하지 않는다.
- 18강: ERC-20 approve/transferFrom 입장료, ERC-721 approve/safeTransferFrom 에스크로, mapping 키와 기본값을 복습하고 MiniArena 예제를 제공했다. Solidity의 `contract is Interface`는 인터페이스 함수를 구현한다는 뜻이며 구현 함수에 `override`가 필요하다는 점도 정리했다. MiniArena의 IGameToken/IHeroNFT는 로컬 ABI 선언일 뿐 실제 OpenZeppelin 토큰 구현을 import하거나 배포하지 않는다. 실행에는 별도 배포된 표준 토큰 주소가 필요함을 설명하고 과제 전제에 기록했다. 예치 중 실제 NFT 소유자는 아레나이고 mapping은 예치 플레이어를 기록한다. 예제와 과제는 `lessons/18-erc20-erc721-arena/` 및 `exercises/mini-arena/`에 있다.
- MiniArena 과제의 독립 구현과 실행 결과는 받지 않았다. 튜터 예제는 학습자 제출 또는 통과로 세지 않는다.
- 2026-10-19 종합과제 SOL-019 Audit Arena 미니 결투 명세를 `exercises/SOL-019-audit-arena-mini/README.md`에 추가했다. ERC-20 참가비와 ERC-721 영웅 에스크로, 두 명의 턴제 경기, 상금/환불 크레딧, pull 출금, 영웅 개별 수령, 상태 머신·불변식·공격/실패 테스트를 통합한다. 사용자 요청으로 함수 시그니처 힌트를 추가했다.
- 사용자가 따라 만들며 학습하는 방식을 선택해 별도 실행 프로젝트 `lessons/19-audit-arena-mini-guided/`를 구현했다. OpenZeppelin 5.4.0 토큰/NFT, `AuditArenaMini.sol`, Foundry 테스트와 Remix/Foundry 실행 안내가 포함된다. 구현 범위는 고정 피해 턴제 결투, 취소, pull 방식 환불/상금, 개인별 NFT 수령이다. Solidity 0.8.24 컴파일 및 Foundry 테스트 4개 통과: 정상 결투/보상/NFT 반환, 취소/환불, NFT 승인 누락에 따른 원자적 롤백, NFT 수령 콜백 재진입 차단.
- 따라 만들기 예제는 튜터의 학습용 참고 프로젝트이며 SOL-019 독립 구현 제출/통과로 세지 않는다. 학습자가 원하면 이후 핵심 흐름을 파일/함수 단위로 설명하며 함께 읽는다. 독립 구현은 별도로 제출받아 리뷰한다.
- OpenZeppelin 5.4.0 기반 DemoGameToken/DemoHeroNFT와 Foundry 프로젝트를 `lessons/18-erc20-erc721-arena/`에 추가했다. `npm install && npm test`로 Solidity 0.8.24 컴파일 및 통합 테스트 3개 통과를 확인했다. 테스트는 입장·퇴장, NFT 승인 누락 시 ERC-20/상태 롤백, 중복 입장 거부를 검증한다. 같은 README에 Remix VM 수동 배포·호출 흐름도 기록했다.
- 사용자는 SOL-019를 코드 따라 만들기 방식으로 학습하기로 했다. 실행 예제를 작은 단위로 함께 읽고 테스트를 관찰한다. 이후 독립 구현 제출 시 과제 요구사항과 보안 기준으로 리뷰한다.

13강은 사용자 요청에 따라 개념 확인으로 클리어했다. SOL-013 코드 제출은 생략했으며 구현 검증을 수행한 것은 아니다. 쉬운 반복 과제는 강요하지 않고 새로운 개념으로 진행한다.

12강은 해시, salt, 주소별 commitment, reveal과 두 참가자 통합 예제를 설명했다. 학습자는 해시·salt·주소별 제출 실험을 완료했다고 확인했다. 통합 예제의 실행 완료나 SOL-012 제출은 아직 확인되지 않았으므로 과제 통과로 처리하지 않는다. constructor, address(this), 해시에 묶는 값, salt가 추가 비밀 인자라는 의미를 설명했다.

## 신규 학습 목표: ERC-4337과 ERC-8004

- 사용자가 ERC-4337 Account Abstraction과 ERC-8004 Trustless Agents를 배우고 싶다고 요청했다.
- 현재 로드맵은 `lessons/20-account-abstraction-and-agents/README.md`에 있다.
- 순서: 4337의 UserOperation/EntryPoint/Bundler → Account 검증/nonce/Factory/Paymaster → 8004 Identity/Reputation/Validation → 두 표준을 연결한 Foundry 미니 프로젝트.
- 2026-10-19 공식 EIP 명세를 확인했다. ERC-4337은 Final Standards Track이고 ERC-8004는 Draft Standards Track이므로 수업마다 최신 상태를 확인한다.
- 2026-10-19 1강: ERC-4337 UserOperation 개념, EOA 대비, Account/Bundler/EntryPoint/Paymaster 실행 흐름. 노트: `lessons/20-account-abstraction-and-agents/lesson-01-useroperation.md`. 이해 확인 질문 답변 대기.
- 2026-10-20 2강: 192-bit key + 64-bit sequence nonce, 중복 실행 방지, `userOpHash` 서명과 chain ID/EntryPoint 결합. 노트: `lessons/20-account-abstraction-and-agents/lesson-02-nonce-replay.md`. 이해 확인 질문 답변 대기.
- 2026-10-21 3강: CREATE2 기반 counterfactual address, Factory/factoryData와 packed initCode, 첫 UserOperation의 배포 → 검증 → 실행 흐름. 노트: `lessons/20-account-abstraction-and-agents/lesson-03-factory-first-deployment.md`. 이해 확인 질문 답변 대기.

## 대기 중인 과제

### SOL-019: Audit Arena 미니 결투 (신규 종합과제)

- 과제 명세: `exercises/SOL-019-audit-arena-mini/README.md`.
- ERC-20 참가비, ERC-721 에스크로, 경기 생성/참가/턴제 공격/취소, 상태 머신, 승자 크레딧 출금, NFT pull 수령을 구현한다.
- Foundry 테스트로 승인 누락, 상태 전이, 턴 검증, 종료 후 행위 차단, 중복 출금/수령, 악성 수신자 재진입을 확인한다.
- 따라 만들기용 참고 프로젝트는 `lessons/19-audit-arena-mini-guided/`에 있으며 테스트 4개 통과.
- 독립 구현 및 테스트 제출은 대기 중. 튜터 참고 구현을 학습자 제출이나 통과로 세지 않는다.


### SOL-011: 교대 결투

- 상태와 currentTurn을 함께 검사한다.
- 공격 성공 후 상대에게 턴을 넘기거나 게임을 종료한다.
- 종료 시 winner를 기록하고 currentTurn을 0 주소로 초기화한다.
- 상태별 불변식을 assert로 검사한다.
- 행동하지 않는 참가자의 게임 중단 위험을 설명한다.
- 사용자 요청으로 나중에 제출한다. 12강 진행을 막지 않는다.

### SOL-012: 비밀 선택 보관소

- 두 참가자의 commitment를 먼저 고정한 뒤 선택과 salt를 공개한다.
- 주소와 게임 ID를 해시에 결합하고 중복 제출·공개를 막는다.
- 아직 제출되지 않았다. 완성 구현은 학습자가 작성한다.

## 최종 게임 방향

가칭 `Audit Arena`:

- 1대1 턴제 전투
- 명시적인 상태 머신
- 플레이어별 자산과 전투 상태 회계
- commit-reveal 방식의 선택 또는 난수 설계
- 중복 보상, 프런트러닝, 접근 제어, 재진입, DoS와 회계 불일치 방어
- 비상 정지와 안전한 출금 구조
- Foundry 단위·퍼즈·불변식 테스트

외부 호출, 이더와 토큰이 없는 학습용 미니게임은 기초 문법만으로 만들 수 있다. 그러나 최종 보안 게임에는 구조체·열거형, 접근 제어, 상태 머신, 외부 호출, 재진입 방어와 테스트가 추가로 필요하다.

## 다른 기기에서 이어가기

새 채팅에서는 이 파일과 저장소의 최신 강의·제출 파일을 읽고 다음처럼 요청한다.

> SolidityStudy의 SESSION_HANDOFF.md를 읽고 이어가줘. SOL-014는 수정 후 통과했고 15~17강 예제 설명과 RewardStation 중간 과제 예시 답안까지 제공받았어. SOL-011은 보류, SOL-012는 미제출, SOL-013은 개념 확인으로 클리어야. 새 개념은 예제 중심으로 설명하고 진행 기록을 커밋·푸시해줘. 최종 게임은 내가 직접 구현해.
