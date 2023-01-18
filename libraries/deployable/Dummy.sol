// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// No frills dummy used to test things on fresh-deployed contracts
contract Dummy { }

library DummyLib {
    
    function newDummy() internal returns (address) {
        Dummy d = new Dummy();
        return address(d);
    }
}