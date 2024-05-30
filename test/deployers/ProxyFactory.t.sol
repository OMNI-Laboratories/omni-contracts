// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {ProxyFactory} from "../../src/deployers/ProxyFactory.sol";
import {ERC20Base} from "../../src/ERC20/ERC20Base.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";

contract ProxyFactoryTest is Test, ProxyFactory {
    uint64 internal constant TESTING_ROLE =
        uint64(uint256(keccak256("TESTING_ROLE")));
    ProxyFactory internal factory;
    ERC20Base internal token;
    AccessManagerUpgradeable internal manager;

    function setUp() public {
        factory = new ProxyFactory();
        token = new ERC20Base();
        manager = new AccessManagerUpgradeable();
        factory.initialize(address(manager), address(token));
        manager.initialize(address(101));

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ProxyFactory.upgradeTo.selector;
        selectors[1] = ProxyFactory.create.selector;

        vm.prank(address(101));
        manager.grantRole(TESTING_ROLE, address(101), 0);

        vm.prank(address(101));
        manager.setTargetFunctionRole(
            address(factory),
            selectors,
            TESTING_ROLE
        );
    }

    function test_StorageLocation() public {
        console2.log("Storage Location:");
        console2.logBytes32(
            (new StorageLocation()).getERC7201StorageLocation(
                "omni.storage.ProxyFactory"
            )
        );
    }

    function test_Initialize() public view {
        assertEq(factory.implementation(), address(token));
    }

    function test_UpgradeTo() public {
        assertEq(factory.implementation(), address(token));
        vm.expectRevert(
            abi.encodeWithSelector(InvalidImplementation.selector, address(0))
        );
        vm.prank(address(101));
        factory.upgradeTo(address(0));

        address newImpl = address(new ERC20Base());
        vm.prank(address(101));
        vm.expectEmit(true, true, false, false);
        emit UpgradedImplementation(newImpl);
        factory.upgradeTo(newImpl);
        assertEq(factory.implementation(), newImpl);
    }

    function test_Create() public {
        vm.prank(address(101));
        vm.expectRevert("ProxyFactory: array length mismatch");
        factory.create(new bytes32[](0), new bytes[](1));

        bytes32[] memory salts = new bytes32[](1);
        salts[0] = keccak256("SALT");

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(
            ERC20Base.erc20Base_init.selector,
            "Test Token",
            "TT",
            18,
            100
        );

        vm.prank(address(101));
        factory.create(salts, data);
    }
}
