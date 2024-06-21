// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {SignatureWallet} from "../../src/wallet/SignatureWallet.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";
import {TestToken} from "../../src/test/TestToken.sol";
import {OwnableFacet} from "../../src/utils/authorization/facets/OwnableFacet.sol";

contract SignatureWalletTest is Test, SignatureWallet {
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

    function test_Execute() public {
        bytes32 hash = keccak256(
            abi.encode(
                wallet.domainSeparator(),
                wallet.getNonce(),
                block.timestamp,
                payloads
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        wallet.execute(payloads, hash, block.timestamp, signature);
        assertEq(token.balanceOf(address(1)), 100);
    }

    function test_UpdateStorage() public {
        uint256 NEW_OWNER = uint256(keccak256("NEW_OWNER"));
        OwnableFacet facet = new OwnableFacet();
        wallet = new SignatureWallet();
        wallet.initialize(vm.addr(PRIVATE_KEY), "Wallet", "1");
        token = new TestToken();
        token.mint(address(wallet), 100);
        assertEq(wallet.owner(), vm.addr(PRIVATE_KEY));

        CallType[] memory callTypes = new CallType[](2);
        address[] memory addresses = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory data = new bytes[](2);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            PRIVATE_KEY,
            keccak256(
                abi.encode(facet.transferOwnership.selector, vm.addr(NEW_OWNER))
            )
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        callTypes[0] = CallType.delegate;
        addresses[0] = address(facet);
        values[0] = 0;
        data[0] = abi.encodeWithSelector(
            facet.transferOwnership.selector,
            signature,
            vm.addr(NEW_OWNER)
        );

        (v, r, s) = vm.sign(
            NEW_OWNER,
            keccak256(abi.encode(facet.acceptOwnership.selector))
        );
        signature = abi.encodePacked(r, s, v);

        callTypes[1] = CallType.delegate;
        addresses[1] = address(facet);
        values[1] = 0;
        data[1] = abi.encodeWithSelector(
            facet.acceptOwnership.selector,
            signature
        );

        payloads = abi.encode(callTypes, addresses, values, data);

        bytes32 hash = keccak256(
            abi.encode(
                wallet.domainSeparator(),
                wallet.getNonce(),
                block.timestamp,
                payloads
            )
        );

        (v, r, s) = vm.sign(PRIVATE_KEY, hash);
        signature = abi.encodePacked(r, s, v);
        wallet.execute(payloads, hash, block.timestamp, signature);
        assertEq(wallet.owner(), vm.addr(NEW_OWNER));
    }

    function test_ExecuteWithUnauthorizedAccess() public {
        bytes32 hash = keccak256(
            abi.encode(
                wallet.domainSeparator(),
                wallet.getNonce(),
                block.timestamp,
                payloads
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(1), hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(UnauthorizedAccess.selector);
        wallet.execute(payloads, hash, block.timestamp, signature);
    }
}
