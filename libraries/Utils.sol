// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Utils {

    bytes32 constant FIL_NATIVE_CODEHASH = bytes32(0xbcc90f2d6dada5b18e155c17a1c0a55920aae94f39857d39d0d8ed07ae8f228b);

    // bytes20 constant NULL = 0x0000000000000000000000000000000000000000;

    // FIL BUILTIN ACTORS
    address constant SYSTEM_ACTOR = 0xfF00000000000000000000000000000000000000;
    address constant INIT_ACTOR = 0xff00000000000000000000000000000000000001;
    address constant REWARD_ACTOR = 0xff00000000000000000000000000000000000002;
    address constant CRON_ACTOR = 0xFF00000000000000000000000000000000000003;
    address constant POWER_ACTOR = 0xFf00000000000000000000000000000000000004;
    address constant MARKET_ACTOR = 0xff00000000000000000000000000000000000005;
    address constant VERIFIED_REGISTRY_ACTOR = 0xFF00000000000000000000000000000000000006;
    address constant DATACAP_TOKEN_ACTOR = 0xfF00000000000000000000000000000000000007;
    address constant EAM_ACTOR = 0xfF0000000000000000000000000000000000000a;
    // address constant CHAOS_ACTOR = 0xFF00000000000000000000000000000000000000; // 98
    // address constant BURNT_FUNDS_ACTOR = 0xFF00000000000000000000000000000000000000; // 99

    // FIL PRECOMPILES
    address constant RESOLVE_ADDR = 0xFE00000000000000000000000000000000000001;
    address constant LOOKUP_DELEGATED_ADDR = 0xfE00000000000000000000000000000000000002;
    address constant CALL_ACTOR = 0xfe00000000000000000000000000000000000003;
    address constant GET_ACTOR_TYPE = 0xFe00000000000000000000000000000000000004;
    address constant CALL_ACTOR_BY_ID = 0xfe00000000000000000000000000000000000005;

    enum AddressType {
        NONE,
        ID,
        SECPK,
        ACTOR,
        BLS,
        DELEGATED
    }

    enum ActorType {
        NONE,
        PRECOMPILE,
        EVM,
        FIL_BUILTIN,
        ACCOUNT,
        NOT_FOUND
    }

    enum NativeType {
        NONEXISTENT,
        SYSTEM,
        PLACEHOLDER,
        ACCOUNT,
        STORAGE_PROVIDER,
        EVM_CONTRACT,
        OTHER
    }

    /**
     * Checks whether a given address is an ID address. If it is, the ID is returned.
     * An ID address is defined as:
     * [0xFF] [bytes11(0)] [uint64(id)]
     */
    function isIDAddress(address _a) internal pure returns (bool isID, uint64 id) {
        uint64 ID_MASK = type(uint64).max;
        address system = SYSTEM_ACTOR;
        assembly {
            let id_temp := and(_a, ID_MASK) // Last 8 bytes of _a are the ID
            let a_mask := and(_a, not(id_temp)) // Zero out the last 8 bytes of _a
            // _a is an ID address if we zero out the last 8 bytes and it's equal to the SYSTEM_ACTOR addr
            if eq(a_mask, system) {
                isID := true
                id := id_temp
            }
        }
    }

    /**
     * Given an Actor ID, converts it to an EVM-compatible ID address. See
     * above for ID address definition.
     */
    function toIDAddress(uint64 _id) internal pure returns (address addr) {
        assembly {

        }
    }

    /**
     * Given an f4-encoded address, parses the address and returns the underlying
     * Eth address. If _addr does not contain a normal 20-byte Eth address, returns (false, 0)
     */
    function fromF4Address(bytes memory _addr) internal view returns (bool valid, address eth) {
        if (_addr.length != 22) {
            return (false, address(0));
        }

        assembly {
            // We want to zero out the length to do an mload, so keep it
            // here to set it back later
            let temp := mload(_addr)
            mstore(_addr, 0)
            eth := mload(add(_addr, 32))

            mstore(_addr, temp)
        }
    }

    /**
     * Given an Actor id, queries LOOKUP_DELEGATED_ADDRESS precompile to try to convert
     * it to an Eth address. If the id does not have an associated Eth address, this
     * returns (false, 0x00)
     * 
     */
    function getEthAddress(uint64 _id) internal view returns (bool success, address eth) {
        bytes memory data = abi.encodePacked(_id);
        (success, data) = LOOKUP_DELEGATED_ADDR.staticcall(data);
        
        // If we reverted the ID does not have a corresponding Eth address.
        if (!success) {
            return (false, address(0));
        }

        (success, eth) = fromF4Address(data);
    }

    /**
     * Given an Eth address, queries RESOLVE_ADDR precompile to look up the corresponding
     * ID address. If there is no corresponding ID address, this returns (false, 0)
     */
    function getActorID(address _eth) internal view returns (bool success, uint64 id) {
        assembly {
            // Convert EVM address to f4-encoded format:
            // 22 bytes, prepended with:
            // * protocol  (0x04) - "f4" address
            // * namespace (0x0A) - "10" for the EAM actor
            _eth := or(
                shl(240, 0x040A),
                shl(80, _eth)
            )
            // Set up calldata, call, and read return value
            mstore(0, _eth)
            success := staticcall(gas(), RESOLVE_ADDR, 0, 22, 0, 0x20)
            id := mload(0)
            // If we got empty return data or the call reverted, return (false, 0)
            if or(
                iszero(returndatasize()),
                iszero(success)
            ) {
                success := false
                id := 0
            }
        }
        require(returnSize() != 0);
    }

    // function resolveAddress(address _a) internal view returns (bool success, uint64 id) {
    //     address target = RESOLVE_ADDR;
    //     assembly {
    //         mstore(0, 22)
    //         _a := or(
    //             shl(240, 0x040A),
    //             shl(80, _a)
    //         )
    //         mstore(0x20, _a)
    //         success := staticcall(gas(), target, 0, 0x36, 0, 0x20)
    //         if success {
    //             id := mload(0)
    //             // RESOLVE_ADDR returns nothing if the address encoding is invalid
    //             if iszero(returndatasize()) {
    //                 // success := 0
    //                 id := 0
    //             }
    //         }
    //     }
    //     // uint rds;
    //     // assembly { rds := returndatasize() }
    //     // require(rds != 0);
    // }

    /**
     * Attempts to convert an actor ID to an EVM address. If the conversion could not
     * be performed, returns (false, 0x00)
     * TODO: Returndatasize isn't necessarily 32 bytes, and right now this method
     * is returning the full encoded address, rather than a left-padded EthAddress.
     */
    // function toEVMAddress(uint _id) internal view returns (bool success, bytes32 evmAddr) {
    //     address target = LOOKUP_DELEGATED_ADDR;
    //     assembly {
    //         mstore(mload(0x40), _id)
    //         success := staticcall(gas(), target, mload(0x40), 0x20, 0, 0x20)
    //         if success {
    //             // LOOKUP_DELEGATED_ADDR returns nothing if the EVM address wasn't found
    //             evmAddr := mload(0)
    //             if or(
    //                 iszero(evmAddr),
    //                 iszero(returndatasize())
    //             ) {
    //                 success := 0
    //             }
    //         }
    //     }
    // }

    /**
     * Calls the fil precompile GET_ACTOR_TYPE to resolve the type of an address
     * Returns whether the call succeeded, and the NativeType returned by the system if so
     */
    function getActorType(uint64 _id) internal view returns (bool success, NativeType aType) {
        address target = GET_ACTOR_TYPE;
        assembly {
            mstore(0, _id)
            success := staticcall(gas(), target, 0, 0x20, 0, 0x20)
            if success {
                aType := mload(0)
                // Sanity check output - 
                // NativeType is an enum with range [0:6]
                // ... and GET_ACTOR_TYPE returns with no data if input was > u64 max
                if or(
                    gt(aType, 6), 
                    iszero(returndatasize())
                ) {
                    success := 0
                    aType := 0
                }
            }
        }
    }

    function returnSize() private pure returns (uint size) {
        assembly { size := returndatasize() }
    }
}