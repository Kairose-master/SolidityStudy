# 18강: ERC-20·ERC-721과 MiniArena

학습 상태: 개념 설명과 튜터 예시 제공. 과제 독립 구현과 Remix/Foundry 실행은 아직 확인되지 않았다.

## 핵심 개념

- ERC-20 `approve(arena, amount)`는 아레나가 지정된 수량을 대신 가져가도록 허용한다. 아레나는 `transferFrom(player, treasury, entryFee)`로 입장료를 이동한다.
- ERC-721 `approve(arena, tokenId)` 또는 `setApprovalForAll(arena, true)`는 NFT 이동을 허용한다. `safeTransferFrom`은 수신 컨트랙트에 ERC-721 수신 콜백도 확인한다.
- `mapping(address => uint256)`은 플레이어 주소에서 영웅 ID를 찾는다. `mapping(uint256 => address)`는 영웅 ID에서 맡긴 플레이어를 찾는다. 키 `7`은 배열의 8번째 위치가 아니라 정확히 키가 7인 항목이며, 미설정 값은 기본값을 반환한다.
- NFT가 에스크로에 있는 동안 실제 ERC-721 소유자는 아레나 컨트랙트다. `playerOfHero[tokenId]`는 실제 소유권이 아니라 해당 NFT를 맡긴 플레이어 기록이다. 두 상태가 맞아야 게임 판정이 일관된다.

## 예제 실행 흐름

1. 플레이어가 ERC-20에서 아레나 주소로 입장료를 승인한다.
2. 플레이어가 ERC-721에서 아레나 주소로 영웅 이동을 승인한다.
3. `enterArena(tokenId)`를 호출한다. 수수료는 보물고로 이동하고 NFT는 아레나가 보관한다.
4. 조회하면 `heroOf[player] == tokenId`, `playerOfHero[tokenId] == player`, `isInArena[player] == true`다. ERC-721의 `ownerOf(tokenId)`는 아레나 주소를 반환한다.
5. `leaveArena()`를 호출하면 기록을 지운 다음 NFT를 플레이어에게 돌려준다. 입장료는 환불하지 않는다.

## 실무 주의점

- 상태를 먼저 갱신하고 외부 컨트랙트를 호출한다(CEI). 처리되지 않은 호출 실패는 트랜잭션을 되돌리므로 선행 상태 변경도 함께 롤백된다.
- `safeTransferFrom`을 받으려면 수신 컨트랙트가 `IERC721Receiver`를 구현해야 한다. 콜백에서 컬렉션뿐 아니라 전송자와 operator도 확인해 기록되지 않은 NFT가 임의로 갇히지 않게 한다.
- 이 예제는 교육용으로 표준 ERC-20의 bool 반환과 신뢰할 수 있는 ERC-20/ERC-721 구현을 가정한다. 실제 배포에서는 OpenZeppelin의 SafeERC20 등 검증된 구현, 권한·위협 모델·자동화 테스트를 추가로 검토한다.
- 이 컨트랙트에는 전투 판정과 상금 지급이 없다. Audit Arena 최종 과제의 완성 구현이 아니다.

## 파일

- 예제 코드: [MiniArena.sol](MiniArena.sol)
- 과제와 통과 조건: [MiniArena 과제](../../exercises/mini-arena/README.md)

## 이해 확인

에스크로 중 `ownerOf(tokenId)`가 아레나 주소를 반환하는데, `playerOfHero[tokenId]`에는 플레이어 주소가 남아 있는 이유를 설명해 보자.
