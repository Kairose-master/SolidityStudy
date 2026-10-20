# 확장 트랙 2강: ERC-4337 nonce와 서명 해시로 replay 방지하기

**학습 목표:** UserOperation의 nonce가 중복 실행을 막는 원리를 설명하고, 서명 해시에 chain ID와 EntryPoint가 들어가는 이유를 이해한다.

2026-10-20 공식 ERC-4337 명세를 확인했다. UserOperation의 nonce는 anti-replay 값이며, 서명은 chain ID와 EntryPoint에 결합되어야 한다. 아래의 nonce 구성과 규칙은 표준 개념 설명이며, 실제 계정 구현의 세부 정책은 사용하는 EntryPoint 버전과 스마트 계정 구현에서 확인한다.

## 핵심 개념

### 1. nonce는 “이 요청을 이미 썼는가?”를 확인하는 값

nonce는 같은 스마트 계정에서 요청의 순서를 정하고, 이미 처리된 요청이 다시 실행되는 것을 막는다. 예를 들어 Alice의 계정이 nonce 7인 UserOperation을 처리했다면, 공격자가 똑같은 서명과 요청을 다시 제출해도 이미 소비된 nonce라 유효한 다음 요청으로 받아들여지지 않는다.

EOA와 달리 ERC-4337은 하나의 순차 숫자만 강제하지 않는다. 256비트 nonce를 **192비트 key + 64비트 sequence**로 해석할 수 있다. 각 key마다 별도의 sequence 흐름을 두므로, 계정 구현이 지원한다면 일반 행동과 세션 키 행동을 독립적으로 순서 관리할 수 있다.

개념적으로 다음처럼 포장한다.

```text
nonce = (key << 64) | sequence

key = 0, sequence = 7  → 기본 흐름의 7번째 요청
key = 1, sequence = 7  → 별도 흐름의 7번째 요청
```

같은 key 안에서 sequence는 올바른 다음 값이어야 한다. 계정은 EntryPoint의 `getNonce(sender, key)`로 현재 값을 조회할 수 있다. key를 어떻게 권한/세션과 연결할지는 스마트 계정 정책이 결정한다.

### 2. 서명은 요청 내용 전체에 묶여야 한다

계정은 `validateUserOp`에서 UserOperation에 대한 `userOpHash`의 서명을 검사한다. 표준 해시는 UserOperation의 서명 필드 자체를 제외한 요청 데이터, EntryPoint 주소, chain ID를 포함한다.

- 요청 데이터가 바뀌면 서명이 맞지 않는다.
- chain ID가 다르면 다른 체인에서 같은 서명을 재사용할 수 없다.
- EntryPoint 주소가 다르면 다른 EntryPoint에 같은 서명을 가져가 실행시키기 어렵다.
- nonce는 요청에 포함되므로, 이미 사용된 요청의 재실행을 차단하는 데도 기여한다.

### 실행 예시

Alice가 게임에서 `setDefense(true)`를 실행하고 싶다고 하자.

```text
현재 nonce: key 0 / sequence 7
요청: callData = setDefense(true)
지갑: UserOperation(요청, nonce=7)을 만들고 userOpHash에 서명
EntryPoint: 서명과 nonce가 유효한지 검증한 뒤 실행
다음 요청: key 0 / sequence 8
재전송: sequence 7은 이미 소비됐으므로 거부
```

위 예시는 실행 흐름을 설명하는 의사 예시다. Solidity 코드에서 해시를 직접 조립하라는 뜻이 아니다. 정식 해시 계산·서명 형식은 표준과 선택한 계정 SDK/EntryPoint 구현을 따라야 한다.

## 실무에서 주의할 점

- nonce는 인증이 아니다. nonce가 맞더라도 계정은 반드시 신뢰하는 EntryPoint 호출인지 확인하고, `userOpHash` 서명이 유효한지 검사해야 한다.
- chain ID와 EntryPoint를 해시에서 빼면 다른 체인이나 다른 EntryPoint를 향한 replay 위험이 생긴다.
- key/sequence를 분해하는 방식과 다음 sequence 정책은 계정 구현 및 EntryPoint 버전에 맞춰야 한다. 임의로 숫자를 만들지 말고 `getNonce`와 지갑 SDK를 사용한다.
- keyed nonce가 있다고 무제한 병렬 실행이 보장되는 것은 아니다. 계정이 여러 key를 실제로 허용·검증하는지 확인한다.
- ERC-4337 UserOperation 구조는 버전별 차이가 있으므로, 예제 코드의 해시·서명 로직을 다른 버전에 그대로 복사하지 않는다.

## 이해 확인 질문

key 0의 sequence 7 요청이 이미 실행된 뒤 똑같은 UserOperation을 다시 보내면 무엇이 재실행을 막을까? 그리고 서명 해시에 chain ID와 EntryPoint를 묶는 것은 어떤 다른 공격을 막아줄까?

## 공식 참고자료

- [ERC-4337 공식 명세 — UserOperation, userOpHash, nonce](https://eips.ethereum.org/EIPS/eip-4337)
