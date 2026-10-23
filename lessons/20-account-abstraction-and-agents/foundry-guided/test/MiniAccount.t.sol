// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {EntryPoint} from "@account-abstraction/core/EntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/interfaces/PackedUserOperation.sol";
import {MiniAccount} from "../src/MiniAccount.sol";
import {MiniAccountFactory} from "../src/MiniAccountFactory.sol";

interface Vm {
    function addr(uint256 privateKey) external returns (address);
    function deal(address account, uint256 newBalance) external;
    function sign(
        uint256 privateKey,
        bytes32 digest
    ) external returns (uint8 v, bytes32 r, bytes32 s);
    function txGasPrice(uint256 gasPrice) external;
}

contract Counter {
    uint256 public count;

    function increment() external {
        count += 1;
    }
}

contract MiniAccountTest {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint256 private constant OWNER_KEY = 0xA11CE;
    uint256 private constant WRONG_KEY = 0xB0B;
    uint256 private constant SALT = 77;
    uint128 private constant VERIFICATION_GAS = 500_000;
    uint128 private constant CALL_GAS = 300_000;
    uint128 private constant PRIORITY_FEE = 1 gwei;
    uint128 private constant MAX_FEE = 2 gwei;

    EntryPoint private entryPoint;
    MiniAccountFactory private factory;
    Counter private counter;
    address private owner;

    receive() external payable {}

    function setUp() public {
        vm.txGasPrice(1 gwei);

        entryPoint = new EntryPoint();
        factory = new MiniAccountFactory(entryPoint);
        counter = new Counter();
        owner = vm.addr(OWNER_KEY);
    }

    function test_firstUserOpDeploysAccountAndCallsGame() public {
        PackedUserOperation memory op = _makeOperation();
        op.signature = _sign(op, OWNER_KEY);

        address predicted = op.sender;
        // 미배포 주소에도 ETH를 보낼 수 있다. 여기서는 첫 실행 가스비를 미리 채운다.
        vm.deal(predicted, 1 ether);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        entryPoint.handleOps(ops, payable(address(this)));

        require(predicted.code.length != 0, "account not deployed");
        require(MiniAccount(predicted).owner() == owner, "wrong owner");
        require(counter.count() == 1, "game call did not run");
    }

    function test_wrongSignerRevertsDeploymentAndExecution() public {
        PackedUserOperation memory op = _makeOperation();
        op.signature = _sign(op, WRONG_KEY);

        address predicted = op.sender;
        vm.deal(predicted, 1 ether);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;

        (bool ok,) = address(entryPoint).call(
            abi.encodeCall(
                EntryPoint.handleOps,
                (ops, payable(address(this)))
            )
        );

        require(!ok, "invalid signature unexpectedly accepted");
        // 배포·검증·호출이 한 트랜잭션이므로 실패 시 상태가 모두 롤백된다.
        require(predicted.code.length == 0, "failed op left account deployed");
        require(counter.count() == 0, "failed op changed game state");
    }

    function _makeOperation()
        private
        view
        returns (PackedUserOperation memory op)
    {
        address predicted = factory.getAddress(owner, SALT);

        op.sender = predicted;
        op.nonce = entryPoint.getNonce(predicted, 0);
        op.initCode = abi.encodePacked(
            address(factory),
            abi.encodeCall(factory.createAccount, (owner, SALT))
        );
        op.callData = abi.encodeCall(
            MiniAccount.execute,
            (
                address(counter),
                0,
                abi.encodeCall(Counter.increment, ())
            )
        );
        op.accountGasLimits = bytes32(
            (uint256(VERIFICATION_GAS) << 128) | uint256(CALL_GAS)
        );
        op.preVerificationGas = 50_000;
        op.gasFees = bytes32(
            (uint256(PRIORITY_FEE) << 128) | uint256(MAX_FEE)
        );
        op.paymasterAndData = "";
        op.signature = "";
    }

    function _sign(
        PackedUserOperation memory op,
        uint256 privateKey
    ) private returns (bytes memory signature) {
        bytes32 userOpHash = entryPoint.getUserOpHash(op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, userOpHash);
        signature = abi.encodePacked(r, s, v);
    }
}
