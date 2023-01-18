// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../FilUtils.sol";
import "../EVMUtils.sol";

contract Lifecycle {

    // Record of codesize and codehash values
    uint selfCodesize;
    uint extCodesize;
    bytes32 selfCodehash;
    bytes32 extCodehash;

    // Record of call context
    struct Ctx {
        address self;
        address origin;
        address sender;
        uint callValue;
        uint balance;
        uint selfBalance;
    }

    Ctx ctx;    

    constructor() payable {
        updateCodeVals();
        updateCallCtxVals();
    }

    function getRecordedCodeVals() external view returns (uint, uint, bytes32, bytes32) {
        return (selfCodesize, extCodesize, selfCodehash, extCodehash);
    }

    function getRecordedCallCtxVals() external view returns (Ctx memory) {
        return ctx;
    }

    function updateCodeVals() public returns (uint, uint, bytes32, bytes32) {
        selfCodesize = EVMUtils.selfCodesize();
        extCodesize = EVMUtils.extCodesize(address(this));
        selfCodehash = EVMUtils.selfCodehash();
        extCodehash = EVMUtils.extCodehash(address(this));
        return (selfCodesize, extCodesize, selfCodehash, extCodehash);
    }

    function updateCallCtxVals() public payable returns (Ctx memory) {
        ctx.self = address(this);
        ctx.origin = tx.origin;
        ctx.sender = msg.sender;
        ctx.callValue = msg.value;
        uint bal;
        uint selfBal;
        assembly {
            bal := balance(address())
            selfBal := selfbalance()
        }
        ctx.balance = bal;
        ctx.selfBalance = selfBal;
        return ctx;
    }
}