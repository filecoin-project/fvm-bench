// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/Utils.sol";

contract Tester {

    using Utils for *;

    // function testEntry() public returns (bool resOuter, uint rdsOuter, bytes memory rdata) {
    //     if (msg.sender == address(this)) {
    //         // Anything we execute here should be catchable by the top-level call made below
    //         runTest();
    //     } else {
    //         // Reentrant execution of testEntry, so we can test error catching
    //         bytes memory data = abi.encodeWithSelector(Tester(this).testEntry.selector, "");
    //         assembly {
    //             resOuter := call(div(gas(), 2), address(), 0, add(32, data), mload(data), 0, 0)
    //             rdsOuter := returndatasize()
    //             // gasRem := gas()
    //         }
    //         rdata = new bytes(rdsOuter);
    //         assembly {
    //             returndatacopy(add(32, rdata), 0, rdsOuter)
    //         }
    //     }   
    // }

    function testEntry() public view returns (bool success, uint64 id) {
        return address(this).getActorID();
    }
}