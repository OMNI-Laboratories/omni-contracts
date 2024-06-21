// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {MockTreason} from "../../../src/utils/test/MockTreason.sol";
import {StorageLocation} from "../../helpers/StorageLocation.sol";

contract TreasonTest is Test {
    uint64 internal constant TESTING_ROLE =
        uint64(uint256(keccak256("TESTING_ROLE")));

    MockTreason internal treason;
    AccessManagerUpgradeable internal manager;

    function setUp() public {
        manager = new AccessManagerUpgradeable();
        manager.initialize(address(101));
        treason = new MockTreason();

        uint64 id = treason.TREASON_ROLE_ID();

        vm.prank(address(101));
        manager.grantRole(id, address(202), 0);
    }

    function testFail_Loyal() public {
        vm.prank(address(202));
        treason.onlyLoyal(address(manager));
        assert(treason.turncoat(address(manager), address(202)));
    }

    function test_Loyal() public {
        vm.prank(address(101));
        treason.onlyLoyal(address(manager));
        assert(!treason.turncoat(address(manager), address(101)));
    }
}
