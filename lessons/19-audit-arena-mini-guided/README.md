# SOL-019 따라 만들기: Audit Arena 미니 결투

이 폴더는 종합과제 SOL-019의 **튜터 실행 예제**다. 과제 폴더의 요구사항을 실제 계약 파일, 토큰/NFT 배포, Foundry 통합 테스트로 연결해 살펴본다. 독립 구현 과제는 `../../exercises/SOL-019-audit-arena-mini/README.md`에 별도로 남겨 둔다.

## 구현된 경기 규칙

- 각 플레이어가 영웅 NFT 한 개와 고정 ERC-20 참가비를 맡기면 경기가 시작된다.
- 영웅은 HP 100으로 시작하고, 자기 턴의 공격은 상대 HP를 25 낮춘다.
- 상대 HP가 0이면 승리한다. 상금은 참가비 두 배를 승자 크레딧에 기록하고, 승자가 `claimReward()`로 따로 출금한다.
- 상대가 참가하기 전이면 생성자가 취소할 수 있다. 참가비는 환불 크레딧으로 기록한다.
- 각 플레이어는 경기가 끝난 뒤 `claimHero(matchId, recipient)`로 NFT를 따로 수령한다.

무작위 피해, timeout, commit-reveal, 관리자 권한은 구현하지 않았다. 로컬에서 원리를 익히기 위한 고정 규칙 예제다.

## 파일

- `src/AuditArenaMini.sol`: 경기 상태 머신, ERC 토큰 연결, 참가비 회계, 승리/취소, 출금과 NFT 수령
- `src/DemoTokens.sol`: OpenZeppelin 5.4.0 ERC-20/ERC-721 로컬 데모
- `test/AuditArenaMini.t.sol`: 생성부터 전투와 출금까지의 통합 테스트
- `foundry.toml`, `package.json`: Solidity 0.8.24 및 Foundry 설정

## 테스트 실행

Node.js와 npm을 설치한 뒤:

```bash
cd lessons/19-audit-arena-mini-guided
npm install
npm test
```

성공하면 Foundry가 로컬 EVM에 토큰, NFT, 게임을 배포하고 테스트 4개를 실행한다.

| 테스트 | 확인 내용 |
|---|---|
| `testFullDuelPaysWinnerAndReturnsBothHeroes` | 양쪽 입장, 턴 검사, 공격, 승리 기록, 상금 출금, 두 NFT 반환 |
| `testCreatorCanCancelAndPullRefundAndHero` | 생성자 취소, 환불 크레딧과 환불/NFT 수령 |
| `testJoinRollsBackFeeAndMatchStateWhenNFTApprovalIsMissing` | NFT 승인 누락 때 참가비와 상태 변경이 함께 롤백됨 |
| `testRecipientReentryIsBlockedWhileClaimingHero` | NFT 수령 콜백에서 재진입을 시도해도 수령 함수 재호출이 차단됨 |

## Remix에서 직접 배포하고 플레이하기

1. Remix에서 `src/DemoTokens.sol`과 `src/AuditArenaMini.sol`을 열고 Solidity 0.8.24로 컴파일한다. OpenZeppelin 버전 import가 설치되도록 Remix의 npm import 해석을 사용한다.
2. `DemoGameToken`을 배포한다. `initialHolder`는 플레이어 Alice, `initialSupply`는 예를 들어 `1000000000000000000000`(18 decimals 기준 1,000 AGT)로 입력한다.
3. `DemoHeroNFT`를 배포하고 Alice 계정에서 `mint(Alice)`를 호출한다. Bob 계정으로도 `mint(Bob)`을 호출한다. 이 예제의 첫 두 token ID는 각각 1과 2다.
4. Alice 계정에서 GameToken의 `transfer(Bob, 100000000000000000000)`를 호출해 Bob에게 100 AGT를 준다.
5. `AuditArenaMini`를 배포한다. 생성자 인자는 GameToken 주소, HeroNFT 주소, 참가비 `10000000000000000000`(10 AGT)다.
6. Alice 계정에서 GameToken `approve(Arena주소, 10 AGT 단위값)`과 HeroNFT `approve(Arena주소, 1)`을 호출한 뒤 아레나 `createMatch(1)`을 호출한다.
7. Bob 계정에서도 각각 GameToken `approve`와 HeroNFT `approve(Arena주소, 2)`를 호출하고, `joinMatch(1, 2)`를 실행한다.
8. Alice와 Bob이 번갈아 `attack(1)`을 호출한다. HP를 100에서 0으로 낮추려면 한 플레이어가 네 번 공격해야 한다.
9. 경기가 끝나면 승자가 `claimReward()`를 호출하고, Alice와 Bob이 각자 `claimHero(1, 자기주소)`를 호출한다. 경기 대기 중에는 생성자가 `cancelMatch(1)`을 호출한 뒤 환불과 NFT를 각각 수령할 수 있다.

Remix에서는 `10 AGT 단위값`을 `10000000000000000000`으로 입력한다. 실제 ERC-20의 `decimals()` 설정에 맞춰야 한다.

## 읽는 순서

1. `MatchStatus`, `MatchData`와 mapping을 보고 상태가 어디에 저장되는지 찾는다.
2. `createMatch`와 `joinMatch`에서 ERC-20 승인이 필요한 이유와 ERC-721 수신 콜백 호출 시점을 추적한다.
3. `attack`의 `currentTurn` 변경과 종료 조건을 따라가 본다.
4. `cancelMatch`와 `claimReward`에서 자산 전송 전에 회계 기록을 바꾸는 이유를 확인한다.
5. `claimHero`에서 수령 여부를 먼저 기록하고 수신 주소의 콜백을 호출하는 이유를 확인한다.
6. 테스트를 한 개씩 실행하거나 조건을 바꿔 실패를 관찰한다.

## 보안과 범위

- 상금과 환불을 `pendingRewards`로 기록한 뒤 별도 출금하는 pull 방식이다. 상금/환불 회계는 `totalEscrowedFees`와 `totalPendingRewards`로 추적한다.
- ERC-20 이동은 OpenZeppelin `SafeERC20`를 사용한다. 게임은 ERC-20/ERC-721 주소가 생성자에서 지정된 표준 컨트랙트라는 가정을 둔다.
- NFT 콜백은 지정된 NFT, 예상 입금자와 token ID, 아레나가 직접 수행한 전송만 받는다.
- NFT 수령 및 보상 출금은 상태를 먼저 갱신하고 외부 호출하며 `ReentrancyGuard`로 재진입을 막는다.
- 테스트는 교육 예제의 기대 동작을 확인할 뿐, 실제 서비스 안전성을 증명하지 않는다. 외부 감사, 랜덤성, timeout, 프런트러닝 대응과 관리자/비상 정책은 범위 밖이다.

## 학습 확인

1. `claimHero`가 NFT를 보내기 전에 `heroOneClaimed`를 바꾸는 이유는?
2. Bob의 NFT 승인이 없어 `joinMatch`가 revert되면, 그보다 먼저 실행된 ERC-20 `transferFrom`도 왜 취소되는가?
3. 경기 도중 컨트랙트가 보유한 참가비와 경기 종료 뒤 `pendingRewards`에 기록된 상금은 어떤 상태 차이가 있는가?

현재 확인: Solidity 0.8.24 컴파일 성공, Foundry 통합 테스트 4개 통과.
