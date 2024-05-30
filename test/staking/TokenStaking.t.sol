// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {TokenStaking} from "../../src/staking/TokenStaking.sol";
import {StakingPlugin, IStakingPlugin, IERC20} from "../../src/staking/StakingPlugin.sol";
import {TestToken} from "../../src/test/TestToken.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";

contract TokenStakingTest is Test, TokenStaking {
    function setUp() public {
        //
    }

    function test_StorageLocation() public {
        console2.log("Storage Location:");
        console2.logBytes32(
            (new StorageLocation()).getERC7201StorageLocation(
                "omni.storage.TokenStaking"
            )
        );
    }

    function test_Initialization() public {
        //
    }
}
