// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library TestLib {

    struct TestRunner {
        Test[] tests;
    }

    struct Test {
        string name;
        bool isView;
        function() external test;
    }

    bytes32 constant STORAGE_SLOT = keccak256(bytes("test-storage-location"));

    function getRunner() internal pure returns (TestRunner storage t) {
        bytes32 slot = STORAGE_SLOT;
        assembly { t.slot := slot }
    }

    function run(TestRunner storage tr) internal returns (bool[] memory results, string[] memory failures) {
        results = new bool[](tr.tests.length);
        failures = new string[](tr.tests.length);

        uint failCount;
        for (uint i = 0; i < tr.tests.length; i++) {
            Test storage t = tr.tests[i];
            function() external fn = t.test;

            // Run test. If the test is in a "view" function,
            // We cast to function() external view to force STATICCALL
            if (t.isView) {
                function() external view viewFn = toView(fn);
                try viewFn() {
                    results[i] = true;
                    continue;
                } catch Error(string memory reason) {
                    failures[failCount] = string.concat(t.name, " failed with: ", reason);
                } catch (bytes memory data) {
                    string memory reason;
                    assembly { reason := data }
                    failures[failCount] = string.concat(t.name, " failed with: ", reason);
                }
            } else {
                try fn() {
                    results[i] = true;
                    continue;
                } catch Error(string memory reason) {
                    failures[failCount] = string.concat(t.name, " failed with: ", reason);
                } catch (bytes memory data) {
                    string memory reason;
                    assembly { reason := data }
                    failures[failCount] = string.concat(t.name, " failed with: ", reason);
                }
            }

            failCount++;
            results[i] = false;
        }

        // Manually update the length of failures
        assembly { mstore(failures, failCount) }
    }

    /**
     * This supports the syntax: testRunner.add(test)
     * 
     * Unfortunately, a bug in solc means we can't overload a function
     * accepts function types with different mutability requirements.
     * So while I'd like to refactor these to be called "add" and accept
     * a raw function type, we'll have to make do with "addV" and "addM" 
     * for view and non-view functions, respectively. Sorry.
     * 
     * https://github.com/ethereum/solidity/issues/13879
     */

    function addV(TestRunner storage tr, Test memory t) internal returns (TestRunner storage) {
        t.isView = true;
        tr.tests.push(t);
        return tr;
    }

    function addM(TestRunner storage tr, Test memory t) internal returns (TestRunner storage) {
        t.isView = false;
        tr.tests.push(t);
        return tr;
    }

    /**
     * These methods support the syntax: testFn.named("TestName")
     */

    function named(function() external fn, string memory name) internal pure returns (Test memory t) {
        t.name = name;
        t.test = fn;
    }

    /**
     * Conversions between function types with different mutability requirements
     */
    
    function toView(function() external fn) internal pure returns (function() external view viewFn) {
        assembly {
            viewFn.address := fn.address
            viewFn.selector := fn.selector
        }
    }

    function toMut(function() external view viewFn) internal pure returns (function() external fn) {
        assembly {
            fn.address := viewFn.address
            fn.selector := viewFn.selector
        }
    }
}