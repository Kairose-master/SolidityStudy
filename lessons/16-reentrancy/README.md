# 16강: 재진입과 CEI

학습 상태: 취약 예제와 수정 예제 제공. 학습자의 실행 결과나 과제 제출 확인은 없음.

외부 호출은 상대 컨트랙트에 실행 제어를 넘긴다. 상대가 현재 함수가 끝나기 전에 다시 호출하면 재진입이 발생한다.

VulnerableRewardLab을 배포하고 그 주소로 ReenterLab을 배포해 attack을 실행한다. 첫 claim에서 claimed가 아직 false일 때 콜백이 다시 claim을 호출하므로 공격 컨트랙트에 20점이 기록된다. 포인트를 조회할 키는 사용자 주소가 아니라 ReenterLab 주소다.

CEIRewardLab은 Checks → Effects → Interactions 순서로 claimed를 외부 호출 전에 확정한다. 새로운 ReenterLab을 이 대상 주소로 배포해 같은 공격을 실행하면 Already claimed로 실패한다. 공격 콜백은 오류를 잡지 않으므로 전체 트랜잭션이 되돌아가 포인트는 0이다.

파일에서는 두 버전을 나란히 배포할 수 있도록 이름을 구분했고, 공격 대상은 IRewardTarget 인터페이스로 연결했다. 이더 전송 없이 재진입을 관찰하는 예제다.
