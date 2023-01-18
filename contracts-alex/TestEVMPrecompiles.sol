// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/TestLib.sol";
import "../libraries/ErrLib.sol";
import "../libraries/Utils.sol";
import "../libraries/Dummy.sol";
import "../libraries/EVMUtils.sol";

contract TestEVMPrecompiles {

    using Utils for *;
    using TestLib for *;

    address creator = msg.sender;

    constructor() payable { }

    function run() public returns (bool[] memory results, string[] memory failures) {
        TestLib.TestRunner storage tr = TestLib.getRunner();

        // Could do all this setup in the constructor, but compiler warnings abound
        tr
          .addV(this.testIdentity.named("testIdentity"))
        ;

        (results, failures) = tr.run();
    }

    
    // Test identity precompile
    function testIdentity() external view {
        // Empty data
        bytes memory empty = new bytes(0);
        (bool success, bytes memory copy) = EVMUtils.copyData(empty);
        require(success, "identity failed or returned invalid data");
        require(hash(empty) == hash(copy), "identity returned different data");

        // One byte
        bytes memory single = abi.encodePacked(uint8(42));
        (success, copy) = EVMUtils.copyData(single);
        require(success, "identity failed or returned invalid data");
        require(hash(single) == hash(copy), "identity returned different data");

        // Lotsa bytes
        bytes memory multi = abi.encodePacked(creator, msg.sender, block.timestamp, tx.origin);
        (success, copy) = EVMUtils.copyData(multi);
        require(success, "identity failed or returned invalid data");
        require(hash(multi) == hash(copy), "identity returned different data");
    }

    function hash(bytes memory b) internal pure returns (bytes32) {
        return keccak256(b);
    }
}