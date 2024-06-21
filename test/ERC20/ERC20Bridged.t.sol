// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {ERC20Bridged} from "../../src/ERC20/ERC20Bridged.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";

contract ERC20BridgedTest is Test {
    uint64 internal constant TESTING_ROLE =
        uint64(uint256(keccak256("TESTING_ROLE")));

    ERC20Bridged internal bridged;
    AccessManagerUpgradeable internal manager;

    function setUp() public {
        bridged = new ERC20Bridged();
        manager = new AccessManagerUpgradeable();
        manager.initialize(address(101));

        vm.prank(address(101));
        bridged.erc20Bridged_init(
            address(manager),
            "Test Token",
            "TT",
            18,
            1000000
        );

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = ERC20Bridged.mintTo.selector;
        selectors[1] = ERC20Bridged.pause.selector;
        selectors[2] = ERC20Bridged.unpause.selector;
        selectors[3] = ERC20Bridged.ERC20Recover.selector;

        vm.prank(address(101));
        manager.grantRole(TESTING_ROLE, address(101), 0);

        vm.prank(address(101));
        manager.setTargetFunctionRole(
            address(bridged),
            selectors,
            TESTING_ROLE
        );
    }

    function test_MintTo() public {
        assertEq(bridged.balanceOf(address(202)), 0);
        vm.prank(address(101));
        bridged.mintTo(address(202), 123);
        assertEq(bridged.balanceOf(address(202)), 123);
    }

    function test_Withdraw() public {
        uint256 initBal = bridged.balanceOf(address(101));
        vm.prank(address(101));
        bridged.withdraw(100);
        uint256 finalBal = bridged.balanceOf(address(101));
        assertEq(initBal - finalBal, 100);
    }

    function test_WithdrawFrom() public {
        uint256 initBal = bridged.balanceOf(address(101));
        vm.prank(address(101));
        bridged.approve(address(202), 100);
        vm.prank(address(202));
        bridged.withdrawFrom(address(101), 100);
        uint256 finalBal = bridged.balanceOf(address(101));
        assertEq(initBal - finalBal, 100);
    }

    function test_Pauseable() public {
        assert(!bridged.paused());
        vm.prank(address(101));
        bridged.pause();
        assert(bridged.paused());
        vm.prank(address(101));
        bridged.unpause();
        assert(!bridged.paused());
    }

    function test_Recoverable() public {
        vm.prank(address(101));
        bridged.mintTo(address(bridged), 123);
        vm.prank(address(101));
        bridged.ERC20Recover(bridged, address(303), 123);
        assert(bridged.balanceOf(address(303)) == 123);
    }
}
