// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {ERC20Compliant} from "../../src/ERC20/ERC20Compliant.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";
import {TestToken} from "../../src/test/TestToken.sol";

contract ERC20CompliantTest is Test {
    uint64 internal constant TESTING_ROLE =
        uint64(uint256(keccak256("TESTING_ROLE")));

    ERC20Compliant internal compliant;
    AccessManagerUpgradeable internal manager;
    TestToken private testToken;

    function setUp() public {
        compliant = new ERC20Compliant();
        manager = new AccessManagerUpgradeable();
        manager.initialize(address(101));

        testToken = new TestToken();

        vm.prank(address(101));
        compliant.erc20Compliant_init(
            address(manager),
            "Test Token",
            "TT",
            18,
            1000000
        );

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = ERC20Compliant.addBlacklist.selector;
        selectors[1] = ERC20Compliant.removeBlacklist.selector;
        selectors[2] = ERC20Compliant.pause.selector;
        selectors[3] = ERC20Compliant.unpause.selector;
        selectors[4] = ERC20Compliant.ERC20Recover.selector;

        vm.prank(address(101));
        manager.grantRole(TESTING_ROLE, address(101), 0);

        vm.prank(address(101));
        manager.setTargetFunctionRole(
            address(compliant),
            selectors,
            TESTING_ROLE
        );
    }

    function test_Blacklist() public {
        vm.prank(address(101));
        compliant.transfer(address(202), 100);
        assertEq(compliant.balanceOf(address(202)), 100);

        vm.prank(address(202));
        compliant.transfer(address(303), 10);
        assertEq(compliant.balanceOf(address(303)), 10);

        vm.prank(address(101));
        compliant.addBlacklist(address(303));
        assert(compliant.isBlacklisted(address(303)));
        assertEq(compliant.balanceOf(address(303)), 0);

        vm.prank(address(202));
        vm.expectRevert();
        compliant.transfer(address(303), 10);
        assertEq(compliant.balanceOf(address(303)), 0);

        vm.prank(address(101));
        compliant.removeBlacklist(address(303));
        assert(!compliant.isBlacklisted(address(303)));

        vm.prank(address(202));
        compliant.transfer(address(303), 10);
        assertEq(compliant.balanceOf(address(303)), 10);
    }

    function test_Pauseable() public {
        assert(!compliant.paused());
        vm.prank(address(101));
        compliant.pause();
        assert(compliant.paused());
        vm.prank(address(101));
        compliant.unpause();
        assert(!compliant.paused());
    }

    function test_Recoverable() public {
        vm.prank(address(101));
        testToken.mint(address(compliant), 123);
        vm.prank(address(101));
        compliant.ERC20Recover(testToken, address(303), 123);
        assert(testToken.balanceOf(address(303)) == 123);
    }
}
