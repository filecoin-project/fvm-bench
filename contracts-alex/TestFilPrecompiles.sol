// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/Test.sol";
import "../libraries/ErrLib.sol";
import "../libraries/FilUtils.sol";
import "../libraries/deployable/Dummy.sol";

contract TestFilPrecompiles {

    using FilUtils for *;
    using Test for *;
    using ErrLib for *;

    address creator = msg.sender;

    constructor() payable { }

    function run() public returns (string[] memory failures) {
        return Test.getRunner()
            .addV(this.test__ResolveRoundtrip.named("test__ResolveRoundtrip"))
            .addM(this.test__ResolveNewActors.named("test__ResolveNewActors"))
            .addM(this.test__ActorType.named("test__ActorType"))
            .run();
    }

    // Test resolve_address -> lookup_delegated_address roundtrip
    function test__ResolveRoundtrip() external view {
        (bool success, uint64 id) = address(this).getActorID();
        Test.expect("resolve_address reverted or returned empty").success(success);
        Test.expect("resolved actor id should be valid").gte(id, 100);

        address ethAddress;
        (success, ethAddress) = id.getEthAddress();
        Test.expect("lookup_delegated_address reverted or returned empty").success(success);
        Test.expect("did not roundtrip").eq(ethAddress, address(this));
    }

    // Test resolve_address on fresh actors
    function test__ResolveNewActors() external {
        address a = DummyLib.newDummy();
        (bool success, uint64 curId) = a.getActorID();
        Test.expect("resolve_address reverted or returned empty").success(success);
        Test.expect("resolved actor id should be valid").gte(curId, 100);

        // Deploy contract in a loop and check that the ID we retrieve
        // is incremented each time
        uint64 nextId;
        for (uint i = 0; i < 5; i++) {
            a = DummyLib.newDummy();
            
            (success, nextId) = a.getActorID();
            Test.expect("resolve_address reverted or returned empty").success(success);
            Test.expect("actor id should increment").eq(nextId, curId + 1);

            curId = nextId;
        }
    }

    // Test getting the actor type for various actors:
    function test__ActorType() external {
        // Get our own ID
        (bool success, uint64 id) = address(this).getActorID();
        Test.expect("resolve_address reverted or returned empty").success(success);
        Test.expect("resolved actor id should be valid").gte(id, 100);

        // We should be an EVM actor
        FilUtils.NativeType nt;
        (success, nt) = id.getActorType();
        Test.expect("get_actor_type reverted or returned empty").success(success);
        Test.expect("we should be an EVM contract").eq(nt, FilUtils.NativeType.EVM_CONTRACT);

        // Get ID of contract deployer
        (success, id) = creator.getActorID();
        Test.expect("resolve_address reverted or returned empty").success(success);
        Test.expect("resolved actor id should be valid").gte(id, 100);

        // Creator should be an Account type
        (success, nt) = id.getActorType();
        Test.expect("get_actor_type reverted or returned empty").success(success);
        Test.expect("msg.sender should be account type").eq(nt, FilUtils.NativeType.ACCOUNT);

        // Check actor types for builtin actors 0 - 7
        // TODO - actors [2:7] are NONEXISTENT for some reason. fvm-bench?
        for (uint64 i = 0; i < 5; i++) {
            (success, nt) = i.getActorType();
            Test.expect("get_actor_type reverted or returned empty").success(success);
            Test.expect("builtin singleton should be system type").eq(nt, FilUtils.NativeType.SYSTEM);
        }
        
        // Check actor type for EAM
        (success, nt) = uint64(10).getActorType();
        Test.expect("get_actor_type reverted or returned empty").success(success);
        Test.expect("EAM should be system type").eq(nt, FilUtils.NativeType.SYSTEM);

        // Check actor type for nonexistent address
        (success, nt) = uint64(10000).getActorType();
        Test.expect("get_actor_type reverted or returned empty").success(success);
        Test.expect("ActorID(10000) should be nonexistent type").eq(nt, FilUtils.NativeType.NONEXISTENT);

        // Check actor type for freshly-deployed contract
        address a = DummyLib.newDummy();
        (, id) = a.getActorID();
        (success, nt) = id.getActorType();
        Test.expect("get_actor_type reverted or returned empty").success(success);
        Test.expect("new contract should have EVM contract type").eq(nt, FilUtils.NativeType.EVM_CONTRACT);
    }

    function test__CallActor() external {
        revert("Failed for no reason at all! lol");
    }
}