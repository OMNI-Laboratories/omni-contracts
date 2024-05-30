// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ERC20Base} from "../../src/ERC20/ERC20Base.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";

contract ERC20BaseTest is Test {
    ERC20Base internal base;

    function setUp() public {
        base = new ERC20Base();
    }

    function test_StorageLocation() public {
        console2.log("Storage Location:");
        console2.logBytes32(
            (new StorageLocation()).getERC7201StorageLocation(
                "omni.storage.ERC20Base"
            )
        );
    }

    function test_Erc20Base_Init() public {
        base.erc20Base_init("Test Token", "TT", 18, 1000000);
        assertEq(base.name(), "Test Token");
        assertEq(base.symbol(), "TT");
        assertEq(base.decimals(), 18);
        assertEq(base.totalSupply(), 1000000 * (10 ** 18));
    }
}
