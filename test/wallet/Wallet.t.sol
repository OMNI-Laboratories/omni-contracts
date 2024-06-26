// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SignatureWallet} from "../../src/wallet/SignatureWallet.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";
import {TestToken} from "../../src/test/TestToken.sol";
import {OwnableFacet} from "../../src/utils/authorization/facets/OwnableFacet.sol";

contract WalletTest is Test, SignatureWallet {
    uint256 private constant PRIVATE_KEY = uint256(keccak256("PRIVATE_KEY"));
    SignatureWallet private wallet;
    TestToken private token;
    bytes private payloads;

    enum TempType {
        call,
        delegate,
        wrong
    }

    function setUp() public {
        wallet = new SignatureWallet();
        wallet.initialize(vm.addr(PRIVATE_KEY), "Wallet", "1");
        token = new TestToken();
        token.mint(address(wallet), 100);

        CallType[] memory callTypes = new CallType[](1);
        address[] memory addresses = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory data = new bytes[](1);

        callTypes[0] = CallType.call;
        addresses[0] = address(token);
        values[0] = 0;
        data[0] = abi.encodeWithSelector(
            token.transfer.selector,
            address(1),
            100
        );

        payloads = abi.encode(callTypes, addresses, values, data);
    }

    function test_StorageLocation() public {
        console2.log("Storage Location:");
        console2.logBytes32(
            (new StorageLocation()).getERC7201StorageLocation(
                "omni.storage.Wallet"
            )
        );
    }

    function test_Nonce() public {
        bytes32 hash = keccak256(
            abi.encode(wallet.domainSeparator(), 1, block.timestamp, payloads)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(InvalidHash.selector);
        wallet.execute(payloads, hash, block.timestamp, signature);
    }

    function test_Timestamp() public {
        bytes32 hash = keccak256(
            abi.encode(
                wallet.domainSeparator(),
                wallet.getNonce(),
                block.timestamp - 1,
                payloads
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(InvalidTimestamp.selector);
        wallet.execute(payloads, hash, block.timestamp - 1, signature);
    }

    function testFail_CallType() public {
        TempType[] memory callTypes = new TempType[](1);
        address[] memory addresses = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory data = new bytes[](1);

        callTypes[0] = TempType.wrong;
        addresses[0] = address(token);
        values[0] = 0;
        data[0] = abi.encodeWithSelector(
            token.transfer.selector,
            address(1),
            100
        );

        bytes memory invalidPayloads = abi.encode(
            callTypes,
            addresses,
            values,
            data
        );

        bytes32 hash = keccak256(
            abi.encode(
                wallet.domainSeparator(),
                wallet.getNonce(),
                block.timestamp,
                invalidPayloads
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        wallet.execute(invalidPayloads, hash, block.timestamp, signature);
    }

    function test_DifferentLengthArray() public {
        CallType[] memory callTypes = new CallType[](2);
        address[] memory addresses = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory data = new bytes[](1);

        callTypes[0] = CallType.call;
        callTypes[1] = CallType.call;
        addresses[0] = address(token);
        values[0] = 0;
        data[0] = abi.encodeWithSelector(
            token.transfer.selector,
            address(1),
            100
        );

        bytes memory invalidPayloads = abi.encode(
            callTypes,
            addresses,
            values,
            data
        );

        bytes32 hash = keccak256(
            abi.encode(
                wallet.domainSeparator(),
                wallet.getNonce(),
                block.timestamp,
                invalidPayloads
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(InvalidPayload.selector);
        wallet.execute(invalidPayloads, hash, block.timestamp, signature);
    }
}
