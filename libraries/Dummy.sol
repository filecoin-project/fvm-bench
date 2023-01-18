// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Dummy contract used to test out things on freshly-deployed contracts
contract Dummy { }

library DummyLib {
    
    function newDummy() internal returns (address) {
        Dummy d = new Dummy();
        return address(d);
    }
}