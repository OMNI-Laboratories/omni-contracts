// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {TokenStaking} from "../../src/staking/TokenStaking.sol";
import {StakingPlugin, IStakingPlugin, IERC20} from "../../src/staking/StakingPlugin.sol";
import {TestToken} from "../../src/test/TestToken.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";

contract TokenStakingTest is Test, TokenStaking {
    uint64 internal constant TESTING_ROLE =
        uint64(uint256(keccak256("TESTING_ROLE")));

    AccessManagerUpgradeable internal manager;
    TokenStaking private staking;
    StakingPlugin private plugin;
    TestToken private stakingTestToken;
    TestToken private rewardTestToken;

    function setUp() public {
        manager = new AccessManagerUpgradeable();
        manager.initialize(address(101));

        rewardTestToken = new TestToken();
        stakingTestToken = new TestToken();

        staking = new TokenStaking();
        staking.initialize(address(manager), stakingTestToken, rewardTestToken);
        plugin = new StakingPlugin();
        plugin.initialize(address(manager), rewardTestToken);

        bytes4[] memory stakingSelectors = new bytes4[](7);
        stakingSelectors[0] = TokenStaking.claimFor.selector;
        stakingSelectors[1] = TokenStaking.withdrawFor.selector;
        stakingSelectors[2] = TokenStaking.addPlugin.selector;
        stakingSelectors[3] = TokenStaking.removePlugin.selector;
        stakingSelectors[4] = TokenStaking.pause.selector;
        stakingSelectors[5] = TokenStaking.unpause.selector;
        stakingSelectors[6] = TokenStaking.rescueTokens.selector;

        vm.prank(address(101));
        manager.grantRole(TESTING_ROLE, address(101), 0);

        vm.prank(address(101));
        manager.setTargetFunctionRole(
            address(staking),
            stakingSelectors,
            TESTING_ROLE
        );

        bytes4[] memory pluginSelectors = new bytes4[](3);
        pluginSelectors[0] = StakingPlugin.increaseClaimable.selector;
        pluginSelectors[1] = StakingPlugin.rescueTokens.selector;

        vm.prank(address(101));
        manager.setTargetFunctionRole(
            address(plugin),
            pluginSelectors,
            TESTING_ROLE
        );

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = StakingPlugin.claim.selector;

        vm.prank(address(101));
        manager.grantRole(TESTING_ROLE, address(staking), 0);

        vm.prank(address(101));
        manager.setTargetFunctionRole(address(plugin), selectors, TESTING_ROLE);

        stakingTestToken.mint(address(101), 500);
        vm.prank(address(101));
        stakingTestToken.approve(address(staking), 500);
        vm.prank(address(101));
        rewardTestToken.mint(address(101), 500);
        vm.prank(address(101));
        rewardTestToken.approve(address(plugin), 500);
        stakingTestToken.mint(address(202), 200);
        vm.prank(address(202));
        stakingTestToken.approve(address(staking), 200);
        stakingTestToken.mint(address(303), 300);
        vm.prank(address(303));
        stakingTestToken.approve(address(staking), 300);

        rewardTestToken.mint(address(staking), 1);
    }

    function test_StorageLocation() public {
        console2.log("Storage Location:");
        console2.logBytes32(
            (new StorageLocation()).getERC7201StorageLocation(
                "omni.storage.TokenStaking"
            )
        );
    }

    function test_Initialization() public view {
        assert(address(staking.stakingToken()) == address(stakingTestToken));
        assert(address(staking.rewardToken()) == address(rewardTestToken));
    }

    function test_Pausing() public {
        assert(!staking.paused());
        vm.prank(address(101));
        staking.pause();
        assert(staking.paused());
        vm.prank(address(101));
        staking.unpause();
        assert(!staking.paused());
    }

    function test_Staking() public {
        vm.expectEmit(true, true, false, false);
        emit Stake(address(101), 100);
        vm.prank(address(101));
        staking.stake(100);
        vm.prank(address(101));
        staking.stakeFor(address(404), address(101), 100);
        vm.prank(address(202));
        staking.stake(200);
        vm.prank(address(303));
        staking.stake(300);

        assert(staking.totalStaked() == 700);
        assert(staking.stakedBalance(address(101)) == 100);
        assert(staking.stakedBalance(address(202)) == 200);
        assert(staking.stakedBalance(address(303)) == 300);
        assert(staking.stakedBalance(address(404)) == 100);

        vm.prank(address(101));
        vm.expectRevert();
        staking.addPlugin(address(staking));

        StakingPlugin invalidPlugin = new StakingPlugin();
        invalidPlugin.initialize(address(manager), stakingTestToken);
        vm.prank(address(101));
        vm.expectRevert(
            abi.encodeWithSelector(TokenStaking.TokenMismatch.selector)
        );
        staking.addPlugin(address(invalidPlugin));

        vm.expectEmit(true, true, false, false);
        emit PluginUpdated(address(plugin), 0, true);
        vm.prank(address(101));
        staking.addPlugin(address(plugin));
        assert(staking.getPlugin(0) == address(plugin));
        assert(staking.getPluginCount() == 1);

        vm.prank(address(101));
        plugin.increaseClaimable(address(101), address(202), 22);
        vm.prank(address(101));
        plugin.increaseClaimable(address(101), address(303), 33);
        vm.prank(address(101));
        plugin.increaseClaimable(address(101), address(404), 44);

        assert(staking.claimableBalance(address(303)) == 33);
        assert(staking.balanceOf(address(303)) == 300);

        vm.prank(address(101));
        vm.expectRevert("TokenStaking: cannot withdraw more than is staked");
        staking.withdraw(1000);
        vm.expectEmit(true, true, false, false);
        emit Withdraw(address(101), 100);
        vm.prank(address(101));
        staking.withdraw(100);
        vm.prank(address(202));
        staking.claim();
        vm.prank(address(202));
        staking.withdraw(200);
        vm.prank(address(303));
        staking.exit();
        vm.prank(address(101));
        staking.claimFor(address(404), address(404));
        vm.prank(address(101));
        staking.withdrawFor(address(404), address(101), 100);
        vm.prank(address(101));
        vm.expectRevert();
        staking.stakeRewards();

        assert(staking.totalStaked() == 0);
        assert(staking.stakedBalance(address(101)) == 0);
        assert(staking.stakedBalance(address(202)) == 0);
        assert(staking.stakedBalance(address(303)) == 0);
        assert(staking.stakedBalance(address(404)) == 0);

        vm.prank(address(101));
        vm.expectRevert("TokenStaking: Plugin does not exist");
        staking.removePlugin(1);
        vm.expectEmit(true, true, false, false);
        emit PluginUpdated(address(plugin), 0, false);
        vm.prank(address(101));
        staking.removePlugin(0);
        assert(staking.getPluginCount() == 0);

        vm.prank(address(101));
        staking.rescueTokens(rewardTestToken, address(101), 1);
    }

    function test_StakingIsReward() public {
        stakingTestToken = rewardTestToken;
        staking = new TokenStaking();
        staking.initialize(address(manager), stakingTestToken, rewardTestToken);
        StakingPlugin secondPlugin = new StakingPlugin();
        secondPlugin.initialize(address(manager), rewardTestToken);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = StakingPlugin.claim.selector;
        vm.prank(address(101));
        manager.grantRole(TESTING_ROLE, address(staking), 0);

        vm.prank(address(101));
        manager.setTargetFunctionRole(address(plugin), selectors, TESTING_ROLE);
        vm.prank(address(101));
        manager.setTargetFunctionRole(
            address(secondPlugin),
            selectors,
            TESTING_ROLE
        );

        stakingTestToken.mint(address(101), 500);
        vm.prank(address(101));
        stakingTestToken.approve(address(staking), 500);
        stakingTestToken.mint(address(202), 200);
        vm.prank(address(202));
        stakingTestToken.approve(address(staking), 200);
        stakingTestToken.mint(address(303), 300);
        vm.prank(address(303));
        stakingTestToken.approve(address(staking), 300);

        vm.prank(address(101));
        staking.stake(100);
        vm.prank(address(202));
        staking.stake(200);
        vm.prank(address(303));
        staking.stake(300);

        vm.prank(address(101));
        staking.addPlugin(address(plugin));
        vm.prank(address(101));
        staking.addPlugin(address(secondPlugin));

        vm.prank(address(101));
        plugin.increaseClaimable(address(101), address(202), 22);
        vm.prank(address(101));
        plugin.increaseClaimable(address(101), address(303), 33);
        vm.prank(address(101));
        plugin.increaseClaimable(address(101), address(404), 44);

        assert(staking.balanceOf(address(303)) == 333);

        vm.prank(address(303));
        staking.stakeRewards();
        assert(staking.claimableBalance(address(303)) == 0);
        assert(staking.stakedBalance(address(303)) == 333);
        vm.prank(address(101));
        staking.removePlugin(0);
    }
}
