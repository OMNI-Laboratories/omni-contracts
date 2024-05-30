// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {MockOwnable} from "../../../src/utils/test/MockOwnable.sol";
import {StorageLocation} from "../../helpers/StorageLocation.sol";

contract OwnableTest is Test, MockOwnable {
    uint256 private constant PRIVATE_KEY = uint256(keccak256("PRIVATE_KEY"));
    uint256 private constant NEW_OWNER = uint256(keccak256("NEW_OWNER"));
    MockOwnable private ownable;

    function setUp() public {
        ownable = new MockOwnable();
        ownable.initialize(vm.addr(PRIVATE_KEY));
    }

    function test_StorageLocation() public {
        console2.log("Storage Location:");
        console2.logBytes32(
            (new StorageLocation()).getERC7201StorageLocation(
                "omni.storage.Ownable"
            )
        );
    }

    function test_initialize() public view {
        assertEq(ownable.owner(), vm.addr(PRIVATE_KEY));
    }

    function test_initializeWithZero() public {
        ownable = new MockOwnable();
        vm.expectRevert(InvalidOwner.selector);
        ownable.initialize(address(0));
    }

    function test_OnlyOwner() public {
        vm.expectRevert(UnauthorizedAccess.selector);
        ownable.transferOwnership("0x", address(101));
    }

    function test_Nominated() public {
        vm.expectRevert(UnauthorizedAccess.selector);
        ownable.acceptOwnership("0x");
    }

    function test_TransferAcceptOwnership() public {
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(vm.addr(PRIVATE_KEY), vm.addr(NEW_OWNER));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            PRIVATE_KEY,
            keccak256(
                abi.encode(this.transferOwnership.selector, vm.addr(NEW_OWNER))
            )
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        ownable.transferOwnership(signature, vm.addr(NEW_OWNER));
        assertEq(ownable.pendingOwner(), vm.addr(NEW_OWNER));
        assert(!ownable.transferOwnership(signature, vm.addr(NEW_OWNER)));

        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(vm.addr(PRIVATE_KEY), vm.addr(NEW_OWNER));
        (v, r, s) = vm.sign(
            NEW_OWNER,
            keccak256(abi.encode(this.acceptOwnership.selector))
        );
        signature = abi.encodePacked(r, s, v);
        ownable.acceptOwnership(signature);
        assertEq(ownable.owner(), vm.addr(NEW_OWNER));
    }
}
