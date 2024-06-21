// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {AccessManagerUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagerUpgradeable.sol";
import {ERC20WrappedNative} from "../../src/ERC20/ERC20WrappedNative.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";
import {TestToken} from "../../src/test/TestToken.sol";

contract ERC20WrappedNativeTest is Test {
    uint64 internal constant TESTING_ROLE =
        uint64(uint256(keccak256("TESTING_ROLE")));

    ERC20WrappedNative internal compliant;
    TestToken internal testToken;

    function setUp() public {
        compliant = new ERC20WrappedNative();
        testToken = new TestToken();
        compliant.initialize(
            address(new AccessManagerUpgradeable()),
            "Test Token",
            "TT"
        );
    }

    function test_Deposit() public {
        uint256 initialBalance = address(this).balance;
        uint256 depositAmount = 1 ether;
        compliant.deposit{value: depositAmount}();
        uint256 newBalance = address(this).balance;
        uint256 tokenBalance = compliant.balanceOf(address(this));

        assertEq(
            newBalance,
            initialBalance - depositAmount,
            "Incorrect balance after deposit"
        );
        assertEq(
            tokenBalance,
            depositAmount,
            "Incorrect token balance after deposit"
        );
    }

    function test_DepositTo() public {
        uint256 depositAmount = 1 ether;
        address recipient = address(0x123);

        compliant.depositTo{value: depositAmount}(recipient);
        uint256 tokenBalance = compliant.balanceOf(recipient);
        assertEq(
            tokenBalance,
            depositAmount,
            "Incorrect token balance after deposit to recipient"
        );
    }

    function test_Withdraw() public {
        uint256 depositAmount = 1 ether;
        compliant.deposit{value: depositAmount}();
        uint256 initialBalance = address(this).balance;

        compliant.withdraw(depositAmount);

        uint256 newBalance = address(this).balance;
        uint256 tokenBalance = compliant.balanceOf(address(this));
        assertEq(
            newBalance,
            initialBalance + depositAmount,
            "Incorrect balance after withdrawal"
        );
        assertEq(tokenBalance, 0, "Incorrect token balance after withdrawal");
    }

    function test_WithdrawTo() public {
        uint256 depositAmount = 1 ether;
        compliant.deposit{value: depositAmount}();
        uint256 initialBalance = address(this).balance;
        address recipient = address(0x123);

        vm.expectRevert("WrappedNative: Native send failure");
        compliant.withdrawTo(address(testToken), depositAmount);
        compliant.withdrawTo(recipient, depositAmount);

        uint256 newBalance = address(this).balance;
        uint256 tokenBalance = compliant.balanceOf(address(this));
        uint256 recipientBalance = recipient.balance;
        assertEq(
            newBalance,
            initialBalance,
            "Incorrect balance after withdrawal to recipient"
        );
        assertEq(
            tokenBalance,
            0,
            "Incorrect token balance after withdrawal to recipient"
        );
        assertEq(
            recipientBalance,
            depositAmount,
            "Incorrect recipient balance after withdrawal"
        );
    }

    receive() external payable {}
}
