// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";
import {StakingPlugin, IStakingPlugin, IERC20} from "../../src/staking/StakingPlugin.sol";
import {TestToken} from "../../src/test/TestToken.sol";

contract StakingPluginTest is Test, StakingPlugin {
    uint64 internal constant TESTING_ROLE =
        uint64(uint256(keccak256("TESTING_ROLE")));

    StakingPlugin internal plugin;
    TestToken internal token;
    AccessManager internal manager;

    function setUp() public {
        manager = new AccessManager(address(101));
        token = new TestToken();
        plugin = new StakingPlugin();
        plugin.initialize(address(manager), token);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = StakingPlugin.claim.selector;
        selectors[1] = StakingPlugin.increaseClaimable.selector;
        selectors[2] = StakingPlugin.rescueTokens.selector;

        vm.prank(address(101));
        manager.grantRole(TESTING_ROLE, address(101), 0);

        vm.prank(address(101));
        manager.setTargetFunctionRole(address(plugin), selectors, TESTING_ROLE);
    }

    function test_Initalization() public view {
        // StakingPlugin p = new StakingPlugin(address(manager), token);
        assert(plugin.rewardToken() == token);
    }

    function test_SupportsInterface() public view {
        assert(plugin.supportsInterface(type(IStakingPlugin).interfaceId));
    }

    function test_RescueTokens() public {
        token.mint(address(plugin), 100);
        assertEq(token.balanceOf(address(101)), 0);

        vm.prank(address(101));
        plugin.rescueTokens(token, address(101), 100);
        assertEq(token.balanceOf(address(101)), 100);
    }

    function test_Claim() public {
        token.mint(address(101), 100);
        vm.prank(address(101));
        token.approve(address(plugin), 100);

        vm.prank(address(101));
        vm.expectEmit(true, true, false, false);
        emit ClaimableIncreased(address(202), 30);
        plugin.increaseClaimable(address(101), address(202), 30);
        vm.prank(address(101));
        vm.expectEmit(true, true, false, false);
        emit ClaimableIncreased(address(303), 70);
        plugin.increaseClaimable(address(101), address(303), 70);

        vm.prank(address(101));
        plugin.increaseClaimable(address(101), address(404), 0);

        assertEq(token.balanceOf(address(plugin)), 100);
        assertEq(plugin.claimable(address(202)), 30);
        assertEq(plugin.claimable(address(303)), 70);

        vm.prank(address(101));
        vm.expectEmit(true, true, false, false);
        emit Claimed(address(202), 30);
        plugin.claim(address(202), address(202));

        vm.prank(address(101));
        plugin.claim(address(404), address(404));
    }
}
