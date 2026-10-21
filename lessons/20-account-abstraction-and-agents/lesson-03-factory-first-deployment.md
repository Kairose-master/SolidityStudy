# 확장 트랙 3강: ERC-4337 Factory와 스마트 계정의 첫 배포

**학습 목표:** 아직 배포되지 않은 스마트 계정의 주소를 먼저 계산하고, 첫 UserOperation에서 Factory 배포와 계정 실행이 이어지는 과정을 설명한다.

2026-10-21 공식 ERC-4337 명세와 공식 참조 구현을 확인했다. 아래에서는 일반 Factory 경로를 다룬다. EIP-7702의 `factory = 0x7702` 경로는 동작이 다르므로 별도 주제로 구분한다.

## 핵심 개념

### 1. Factory는 스마트 계정을 만들어 주는 컨트랙트다

ERC-4337에서 `sender`는 UserOperation을 실행할 스마트 계정 주소다. 이미 배포된 계정이라면 Factory 정보가 필요 없다. 아직 배포되지 않았다면 UserOperation에 다음 정보를 함께 넣는다.

- `factory`: 계정을 배포할 Factory 주소
- `factoryData`: Factory에서 호출할 계정 생성 함수와 인자
- `sender`: Factory가 실제로 배포해야 하는 스마트 계정 주소

EntryPoint에 전달되는 `PackedUserOperation`에서는 이 둘이 `initCode = factory address || factoryData` 형태로 결합된다.

### 2. 배포 전에도 주소를 알 수 있다

Factory가 `CREATE2`를 사용하면 배포 주소는 다음 값들로 결정된다.

```text
predictedAddress = hash(
    0xff,
    factoryAddress,
    salt,
    hash(accountCreationCode + constructorArguments)
)
```

따라서 실제 계정 코드가 아직 온체인에 없어도 Factory 주소, salt, 생성 코드를 알면 계정 주소를 미리 계산할 수 있다. 이를 흔히 **counterfactual address**라고 부른다.

공식 참조 구현의 `SimpleAccountFactory`도 `getAddress(owner, salt)`로 주소를 먼저 계산하고, 같은 salt와 초기화 데이터로 계정을 배포한다.

## 짧은 코드 예시

다음은 원리만 보여 주는 축약 코드다. 실제 ERC-4337 계정에는 `validateUserOp`, EntryPoint 접근 제어, 실행 함수와 가스 지불 로직 등이 더 필요하다.

```solidity
function getAddress(
    address owner,
    bytes32 salt
) public view returns (address predicted) {
    bytes32 initHash = keccak256(
        abi.encodePacked(
            type(DemoAccount).creationCode,
            abi.encode(owner, entryPoint)
        )
    );

    bytes32 hash = keccak256(
        abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            initHash
        )
    );

    predicted = address(uint160(uint256(hash)));
}

function createAccount(
    address owner,
    bytes32 salt
) external returns (DemoAccount account) {
    address predicted = getAddress(owner, salt);

    if (predicted.code.length != 0) {
        return DemoAccount(predicted);
    }

    account = new DemoAccount{salt: salt}(owner, entryPoint);
    require(address(account) == predicted, "wrong sender");
}
```

같은 Factory, salt, 생성 코드와 생성자 인자를 사용해야 `getAddress`의 결과와 실제 배포 주소가 일치한다.

## 첫 UserOperation 실행 흐름

```text
1. 지갑이 Factory.getAddress(owner, salt)로 계정 주소 계산
2. 그 주소를 UserOperation.sender로 설정
3. factory와 createAccount(owner, salt) 호출 데이터를 포함
4. 소유자가 UserOperation에 서명
5. Bundler가 배포와 검증이 성공하는지 시뮬레이션
6. EntryPoint가 sender에 코드가 없으면 Factory를 통해 계정 배포
7. 배포 주소가 sender와 같은지 확인
8. 새 계정의 validateUserOp로 서명 검증
9. 유효하면 같은 UserOperation의 게임 호출 실행
```

즉, 사용자 입장에서는 첫 행동을 보내면서 계정 배포까지 함께 처리할 수 있다. 그러나 온체인에서는 **배포 → 계정 검증 → 행동 실행** 순서가 분명히 존재한다.

## 실무에서 주의할 점

- Factory가 만든 주소가 `UserOperation.sender`와 다르거나, 그 주소에 코드가 생기지 않으면 UserOperation은 실패한다.
- `owner`, `salt`, 구현 주소, 초기화 데이터 중 하나라도 달라지면 예상 주소가 달라질 수 있다.
- 초기화 함수를 누구나 다시 호출할 수 있으면 계정 소유권을 탈취당할 수 있다. 프록시를 사용한다면 배포와 초기화를 원자적으로 수행하고 재초기화를 막아야 한다.
- 공식 참조 Factory는 배포 권한과 호출 경로를 제한한다. 위 축약 코드를 그대로 운영 환경에 배포하지 않는다.
- 이미 `sender`에 코드가 있는데 일반 `initCode`도 제공하면 현재 명세상 배포 코드는 무시된다. 클라이언트가 “재배포될 것”이라고 가정하면 안 된다.
- Factory와 EntryPoint의 구현 버전을 섞지 않는다. 필드 형식과 계정 생성 경로가 달라질 수 있다.

## 이해 확인 질문

아직 배포되지 않은 스마트 계정의 주소를 UserOperation의 `sender`로 미리 넣을 수 있는 이유는 무엇이고, Factory가 다른 주소에 계정을 배포하면 왜 전체 요청이 실패해야 할까?

## 공식 참고자료

- [ERC-4337 공식 명세](https://eips.ethereum.org/EIPS/eip-4337)
- [공식 SimpleAccountFactory 참조 구현](https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/accounts/SimpleAccountFactory.sol)
