# ERC-4337 따라 치기: 스마트 계정 첫 UserOperation

이 프로젝트는 ERC-4337의 `EntryPoint`, `Factory`, `MiniAccount`, `UserOperation`이 실제 테스트에서 함께 작동하는 흐름을 연습한다. `EntryPoint`는 공식 eth-infinitism v0.8.0 구현을 사용하고, 계정과 Factory는 핵심 원리를 보이도록 작게 작성했다.

## 준비

Foundry가 설치된 환경에서 이 디렉터리로 이동한 뒤 공식 의존성을 고정 버전으로 설치한다.

```bash
cd lessons/20-account-abstraction-and-agents/foundry-guided
forge install eth-infinitism/account-abstraction@v0.8.0 --no-commit
forge install OpenZeppelin/openzeppelin-contracts@v5.1.0 --no-commit
forge test -vvv
```

실습은 Solidity 0.8.28과 Cancun EVM을 사용한다. ERC-4337 v0.8 EntryPoint는 EIP-1153 transient storage를 쓰므로 Cancun 이상이 필요하다.

## 브라우저에서 직접 실행해 보기

Foundry 테스트는 브라우저 UI 없이 메모리 안의 로컬 EVM에서 실행된다. 화면으로 흐름을 보려면 아래 로컬 데모를 사용한다.

1. 먼저 프로젝트 폴더에서 의존성을 설치하고 artifact를 만든다.

```bash
forge build
```

2. 터미널 창 하나에서 Anvil을 실행한다.

```bash
anvil --host 127.0.0.1 --allow-origin "http://127.0.0.1:8000"
```

Anvil 출력에 나오는 테스트 계정 private key를 복사한다. 이 키는 로컬 연습용이며 실제 지갑 키를 사용하면 안 된다.

3. 다른 터미널 창에서 같은 프로젝트 폴더로 이동해 정적 파일 서버를 켠다.

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

4. 브라우저에서 [http://127.0.0.1:8000/demo/](http://127.0.0.1:8000/demo/)를 연다. Anvil 테스트 키를 입력하고 **Anvil에 연결하고 컨트랙트 배포**를 누른 뒤, **UserOperation 보내기**를 누른다.

화면에서 EntryPoint·Factory·게임 Counter 주소, 예측 계정 주소, 배포 상태, Counter 값을 확인할 수 있다. 성공하면 Counter가 0에서 1로 바뀐다. 이 동작은 로컬 Anvil 체인에만 기록되며 실제 네트워크나 실제 자금에는 영향을 주지 않는다.

## 파일을 읽고 직접 입력하는 순서

1. `src/MiniAccount.sol`: owner 서명을 확인하고, EntryPoint 주소를 고정한다. nonce 확인, 신뢰하는 EntryPoint 검사, 부족한 prefund 전송은 공식 `BaseAccount`가 제공한다.
2. `src/MiniAccountFactory.sol`: `getAddress(owner, salt)`로 CREATE2 주소를 예측하고, EntryPoint의 `SenderCreator`만 `createAccount`를 부를 수 있게 한다.
3. `test/MiniAccount.t.sol`: Foundry가 실제 EntryPoint와 Factory를 배포하고 UserOperation을 서명·전달한다.
4. `demo/index.html`: 브라우저에서 같은 정상 경로를 Anvil 로컬 체인에 실제 트랜잭션으로 보낸다.

직접 입력한 뒤 아래 명령으로 테스트한다.

```bash
forge test --match-test test_firstUserOpDeploysAccountAndCallsGame -vvvv
forge test --match-test test_wrongSignerRevertsDeploymentAndExecution -vvvv
```

## 정상 경로에서 확인할 것

첫 테스트는 아직 코드가 없는 CREATE2 주소를 `sender`로 사용한다. UserOperation의 `initCode`는 Factory 주소와 `createAccount(owner, salt)` calldata를 이어 붙인다. EntryPoint가 Factory를 호출해 계정을 배포하고, 계정 서명을 확인한 뒤 `Counter.increment()`를 실행한다.

테스트는 다음을 확인한다.

- 예측 주소에 계정 코드가 배포됐는가
- 계정 owner가 서명자 주소와 같은가
- 게임 Counter 값이 1 증가했는가

실습은 EntryPoint가 첫 UserOperation 비용을 가져갈 수 있도록 배포 전의 예측 주소에 테스트 ETH를 넣는다. 코드 없는 주소도 ETH 잔액을 가질 수 있기 때문이다. Paymaster 후원으로 첫 비용을 내는 방법은 뒤의 Paymaster 실습에서 추가한다.

## 잘못된 서명 경로에서 확인할 것

두 번째 테스트는 다른 개인키로 UserOperation에 서명한다. EntryPoint는 서명을 거부하고 전체 `handleOps` 트랜잭션이 revert한다. 따라서 같은 트랜잭션에서 이루어진 계정 배포와 게임 상태 변경도 롤백된다.

## 이 예제의 범위

이것은 학습용 단일 소유자 계정이며 보안 감사나 실제 자산 보관을 위한 구현이 아니다. production 계정을 만들 때는 공식 구현, 배포된 EntryPoint 주소와 코드 해시, signer 정책, 가스 추정, Bundler 호환성 및 감사 결과를 확인해야 한다. Foundry 테스트는 로컬 테스트 실행이고, 브라우저 데모는 별도의 로컬 Anvil 체인에서만 실행한다.

## 참고자료

- [eth-infinitism/account-abstraction v0.8.0](https://github.com/eth-infinitism/account-abstraction/tree/v0.8.0)
- [ERC-4337 공식 명세](https://eips.ethereum.org/EIPS/eip-4337)
