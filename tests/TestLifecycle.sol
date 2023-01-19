// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/Test.sol";
import "../libraries/ErrLib.sol";
import "../libraries/FilUtils.sol";
import "../libraries/deployable/Dummy.sol";
import "../libraries/deployable/Lifecycle.sol";
import "../libraries/deployable/Nested.sol";

contract TestLifecycle {

    using FilUtils for *;
    using Test for *;
    using ErrLib for *;

    address creator = msg.sender;

    constructor() payable { }

    function run() public returns (string[] memory results) {
        return Test.getRunner()
            .addM(this.test__Create_Codesize.named("test__Create_Codesize"))
            .addP(this.test__Create_Ctx.named("test__Create_Ctx"))
            .run();
    }

    // Test expected codesize and codehash values
    function test__Create_Codesize() external {
        Lifecycle l = new Lifecycle();

        // Lifecycle recorded various codesize/hash values during construction:
        (uint selfCodesize, uint extCodesize, bytes32 selfCodehash, bytes32 extCodehash) = l.getRecordedCodeVals();
        Test.expect("self codesize should be nonzero during constructor").neq(selfCodesize, 0);
        Test.expect("extcodesize should be zero during constructor").iszero(extCodesize);
        Test.expect("self codehash should not match empty account").neq(selfCodehash, FilUtils.EVM_EMPTY_CODEHASH);
        Test.expect("extcodehash should match empty account during constructor").eq(extCodehash, FilUtils.EVM_EMPTY_CODEHASH);

        // Compare against values we can calculate here:
        uint calcedSize = type(Lifecycle).creationCode.length;
        bytes32 calcedHash = keccak256(type(Lifecycle).creationCode);
        Test.expect("self codesize should match creation code length").eq(selfCodesize, calcedSize);
        Test.expect("self codehash should match creation code hash").eq(calcedHash, selfCodehash);
        
        // Now update the values and check against prev:
        (uint newSelfCS, uint newExtCS, bytes32 newSelfCH, bytes32 newExtCH) = l.updateCodeVals();
        Test.expect("self codesize and extcodesize should match after construction").eq(newSelfCS, newExtCS);
        Test.expect("self codehash and extcodehash should match after construction").eq(newSelfCH, newExtCH);

        // Compare against values we can calculate here:
        calcedSize = type(Lifecycle).runtimeCode.length;
        calcedHash = keccak256(type(Lifecycle).runtimeCode);
        Test.expect("codesize should match runtime code length").eq(newSelfCS, calcedSize);
        Test.expect("codehash should match runtime code hash").eq(newSelfCH, calcedHash);
    }

    // Test properties of various call-context-related params
    function test__Create_Ctx() external payable {
        Lifecycle l = new Lifecycle();

        // Lifecycle recorded various call context values during construction:
        Lifecycle.Ctx memory ctx = l.getRecordedCallCtxVals();
        Test.expect("should know own address").eq(ctx.self, address(l));
        Test.expect("should agree on tx origin").eq(ctx.origin, tx.origin);
        Test.expect("sender should be this contract").eq(ctx.sender, address(this));
        Test.expect("should not have been sent value").iszero(ctx.callValue);
        Test.expect("balance should be zero").iszero(ctx.balance);
        Test.expect("selfbalance should be zero").iszero(ctx.selfBalance);

        // Update recorded values now that constructor is complete. They should all be the same:
        Lifecycle.Ctx memory newCtx = l.updateCallCtxVals();
        Test.expect("addresses should match").eq(ctx.self, newCtx.self);
        Test.expect("origins should match").eq(ctx.origin, newCtx.origin);
        Test.expect("callers should match").eq(ctx.sender, newCtx.sender);
        Test.expect("callvalues should match").eq(ctx.callValue, newCtx.callValue);
        Test.expect("balances should match").eq(ctx.balance, newCtx.balance);
        Test.expect("selfbalances should match").eq(ctx.selfBalance, newCtx.selfBalance);
   
        // Now try the same thing, but with value sent to constructor:
        uint toSend = msg.value;
        Test.expect("we should have some funds to send").neq(toSend, 0);
        uint prevBalance = address(this).balance;

        l = new Lifecycle{ value: toSend }();
        ctx = l.getRecordedCallCtxVals();
        Test.expect("should know own address").eq(ctx.self, address(l));
        Test.expect("should agree on tx origin").eq(ctx.origin, tx.origin);
        Test.expect("sender should be this contract").eq(ctx.sender, address(this));
        Test.expect("should have been sent value").neq(ctx.callValue, 0);
        Test.expect("balance should be equal to value sent").eq(ctx.balance, toSend);
        Test.expect("selfbalance be equal to value sent").eq(ctx.selfBalance, toSend);
        Test.expect("our balance should decrease by sent amount").eq(address(this).balance, prevBalance - toSend);
    }
}