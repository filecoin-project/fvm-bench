// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/TestLib.sol";
import "../libraries/ErrLib.sol";
import "../libraries/Utils.sol";
import "../libraries/Dummy.sol";

contract TestFilPrecompiles {

    using Utils for *;
    using TestLib for *;

    address creator = msg.sender;

    constructor() payable { }

    function run() public returns (bool[] memory results, string[] memory failures) {
        TestLib.TestRunner storage tr = TestLib.getRunner();

        // Could do all this setup in the constructor, but compiler warnings abound
        tr
          .addV(this.testResolveRoundtrip.named("testResolveRoundtrip"))
          .addM(this.testResolveNewActors.named("testResolveNewActors"))
          .addM(this.testActorType.named("testActorType"))
          .addM(this.testCallActor.named("testCallActor"))
        ;

        (results, failures) = tr.run();
    }

    // Test resolve_address -> lookup_delegated_address roundtrip
    function testResolveRoundtrip() external view {
        (bool success, uint64 id) = address(this).getActorID();
        require(success, "resolve_address reverted or returned empty");
        require(id >= 100, "invalid actor id");

        address ethAddress;
        (success, ethAddress) = id.getEthAddress();
        require(success, "lookup_delegated_address reverted or returned empty");
        require(ethAddress == address(this), "did not roundtrip");
    }

    // Test resolve_address on fresh actors
    function testResolveNewActors() external {
        address a = DummyLib.newDummy();
        (bool success, uint64 curId) = a.getActorID();
        require(success, "resolve_address reverted or returned empty");
        require(curId >= 100, "invalid actor id");

        // Deploy contract in a loop and check that the ID we retrieve
        // is incremented each time
        uint64 nextId;
        for (uint i = 0; i < 5; i++) {
            a = DummyLib.newDummy();
            
            (success, nextId) = a.getActorID();
            require(success, "resolve_address reverted or returned empty");
            require(nextId == curId + 1, "Actor ID did not increment");

            curId = nextId;
        }
    }

    // Test getting the actor type for various actors:
    function testActorType() external {
        // Get our own ID
        (bool success, uint64 id) = address(this).getActorID();
        require(success, "resolve_address reverted or returned empty");
        require(id >= 100, "invalid actor id");

        // We should be an EVM actor
        Utils.NativeType nt;
        (success, nt) = id.getActorType();
        require(success, "get_actor_type reverted or returned empty");
        require(nt == Utils.NativeType.EVM_CONTRACT, "expected EVM contract");

        // Get ID of contract deployer
        (success, id) = creator.getActorID();
        require(success, "resolve_address reverted or returned empty");
        require(id >= 100, "invalid actor id");

        // Creator should be an Account type
        (success, nt) = id.getActorType();
        require(success, "get_actor_type reverted or returned empty");
        require(nt == Utils.NativeType.ACCOUNT, "Expected msg.sender to be account type");

        // Check actor types for builtin actors 0 - 7
        // TODO - actors [2:7] are NONEXISTENT for some reason. fvm-bench?
        for (uint64 i = 0; i < 5; i++) {
            (success, nt) = i.getActorType();
            require(success, "get_actor_type reverted or returned empty");
            require(nt == Utils.NativeType.SYSTEM, "expected system address");
        }
        
        // Check actor type for EAM
        (success, nt) = uint64(10).getActorType();
        require(success, "get_actor_type reverted or returned empty");
        require(nt == Utils.NativeType.SYSTEM, "expected system address");

        // Check actor type for nonexistent address
        (success, nt) = uint64(10000).getActorType();
        require(success, "get_actor_type reverted or returned empty");
        require(nt == Utils.NativeType.NONEXISTENT, "expected nonexistent type");

        // Check actor type for freshly-deployed contract
        address a = DummyLib.newDummy();
        (, id) = a.getActorID();
        (success, nt) = id.getActorType();
        require(success, "get_actor_type reverted or returned empty");
        require(nt == Utils.NativeType.EVM_CONTRACT, "expected EVM contract");
    }

    function testCallActor() external {
        revert("Failed for no reason at all! lol");
    }
}