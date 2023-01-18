// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Utils.sol";

library EVMUtils {
    // EVM Precompiles
    address constant ECRECOVER = 0x0000000000000000000000000000000000000001;
    address constant SHA2 = 0x0000000000000000000000000000000000000002;
    address constant RIPEMD = 0x0000000000000000000000000000000000000003;
    address constant IDENTITY = 0x0000000000000000000000000000000000000004;
    address constant MODEXP = 0x0000000000000000000000000000000000000005;
    address constant ECADD = 0x0000000000000000000000000000000000000006;
    address constant ECMUL = 0x0000000000000000000000000000000000000007;
    address constant ECPAIRING = 0x0000000000000000000000000000000000000008;
    address constant BLAKE2F = 0x0000000000000000000000000000000000000009;

    function copyData(bytes memory data) internal view returns (bool success, bytes memory copy) {
        // alloc copy
        copy = new bytes(data.length);
        assembly {
            success := staticcall(gas(), IDENTITY, add(32, data), mload(data), add(32, copy), mload(copy))
        }
        if (!success || Utils.returnSize() != data.length) {
            return (false, bytes(""));
        }
    }
}