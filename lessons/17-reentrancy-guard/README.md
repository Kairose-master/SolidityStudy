# 17강: nonReentrant 잠금

학습 상태: 원리와 예제 제공. 학습자의 실행 완료 보고는 없음.

modifier는 잠금을 검사하고 설정한 뒤 _;에서 본문을 실행하며 정상 종료 후 해제한다. 본문 실패가 전파되면 잠금 해제 줄까지 실행되는 것이 아니라 잠금 설정 자체가 revert로 되돌아간다.

claimed는 보상을 받은 상태를 유지하고 locked는 실행 중에만 유지된다. 같은 잠금을 사용하는 modifier가 붙은 함수들에만 보호가 적용된다. 보호된 함수끼리 중첩 호출해도 잠금에 걸린다. 잠금이 CEI나 다른 접근 제어를 대체하지는 않는다.

16강 ReenterLab을 GuardedRewardLab 주소로 새로 배포하여 attack을 실행하면 Reentrant call로 실패하고 전체 트랜잭션이 되돌아간다. 포인트는 0, claimed는 false다.

원리 학습 후 실사용 시 참고: [OpenZeppelin ReentrancyGuard](https://docs.openzeppelin.com/contracts/5.x/api/utils#ReentrancyGuard).

다음 중간 과제는 `../../exercises/reward-station/README.md`에 기록했다. 예시 답안 제공까지 진행했으며 독립 제출로 채점하지 않는다.
