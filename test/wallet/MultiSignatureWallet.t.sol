// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {MultiSignatureWallet} from "../../src/wallet/MultiSignatureWallet.sol";
import {StorageLocation} from "../helpers/StorageLocation.sol";
import {TestToken} from "../../src/test/TestToken.sol";
import {AssistedCustodyFacet} from "../../src/utils/authorization/facets/AssistedCustodyFacet.sol";

contract MultiSignatureWalletTest is Test, MultiSignatureWallet {
    uint256 private constant PRIVATE_KEY = uint256(keccak256("PRIVATE_KEY"));
    uint256 private constant GATEKEEPER_KEY_A =
        uint256(keccak256("GATEKEEPER_KEY_A"));
    uint256 private constant GATEKEEPER_KEY_B =
        uint256(keccak256("GATEKEEPER_KEY_B"));
    uint256 private constant OWNER_KEY = uint256(keccak256("OWNER_KEY"));
    uint256 NEW_GATEKEEPER = uint256(keccak256("NEW_GATEKEEPER"));
    uint256 NEW_OWNER = uint256(keccak256("NEW_OWNER"));
    AssistedCustodyFacet facet = new AssistedCustodyFacet();
    MultiSignatureWallet private wallet;
    TestToken private token;
    bytes private payloads;

    enum TempType {
        call,
        delegate,
        wrong
    }

    function setUp() public {
        wallet = new MultiSignatureWallet();
        wallet.initialize(
            vm.addr(GATEKEEPER_KEY_A),
            vm.addr(GATEKEEPER_KEY_B),
            "Wallet",
            "1"
        );
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

    function test_InvalidInit() public {
        wallet = new MultiSignatureWallet();
        vm.expectRevert("AssistedCustody: gatekeepers cannot be zero address");
        wallet.initialize(address(0), vm.addr(GATEKEEPER_KEY_A), "Wallet", "1");
        vm.expectRevert("AssistedCustody: gatekeepers cannot be zero address");
        wallet.initialize(vm.addr(GATEKEEPER_KEY_A), address(0), "Wallet", "1");
        vm.expectRevert(
            "AssistedCustody: gatekeepers and owner must be unique"
        );
        wallet.initialize(
            vm.addr(GATEKEEPER_KEY_A),
            vm.addr(GATEKEEPER_KEY_A),
            "Wallet",
            "1"
        );
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

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(GATEKEEPER_KEY_A, hash);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(GATEKEEPER_KEY_B, hash);
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);
        wallet.execute(payloads, hash, block.timestamp, signature1, signature2);
        assertEq(token.balanceOf(address(1)), 100);
    }

    function test_UpdateGatekeeper() public {
        wallet = new MultiSignatureWallet();
        wallet.initialize(
            vm.addr(GATEKEEPER_KEY_A),
            vm.addr(GATEKEEPER_KEY_B),
            "Wallet",
            "1"
        );

        CallType[] memory callTypes = new CallType[](1);
        address[] memory addresses = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory data = new bytes[](1);

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            GATEKEEPER_KEY_A,
            keccak256(
                abi.encode(
                    facet.replaceGatekeeper.selector,
                    vm.addr(NEW_GATEKEEPER),
                    vm.addr(GATEKEEPER_KEY_A)
                )
            )
        );
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(
            GATEKEEPER_KEY_B,
            keccak256(
                abi.encode(
                    facet.replaceGatekeeper.selector,
                    vm.addr(NEW_GATEKEEPER),
                    vm.addr(GATEKEEPER_KEY_A)
                )
            )
        );
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);

        callTypes[0] = CallType.delegate;
        addresses[0] = address(facet);
        values[0] = 0;
        data[0] = abi.encodeWithSelector(
            facet.replaceGatekeeper.selector,
            signature1,
            signature2,
            vm.addr(NEW_GATEKEEPER),
            vm.addr(GATEKEEPER_KEY_A)
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

        (uint8 vA, bytes32 rA, bytes32 sA) = vm.sign(GATEKEEPER_KEY_A, hash);
        bytes memory signatureA = abi.encodePacked(rA, sA, vA);
        (uint8 vB, bytes32 rB, bytes32 sB) = vm.sign(GATEKEEPER_KEY_B, hash);
        bytes memory signatureB = abi.encodePacked(rB, sB, vB);
        wallet.execute(payloads, hash, block.timestamp, signatureA, signatureB);
        assert(wallet.hasRole(GATEKEEPER_ROLE, vm.addr(NEW_GATEKEEPER)));
        assert(!wallet.hasRole(GATEKEEPER_ROLE, vm.addr(GATEKEEPER_KEY_A)));
    }

    function test_UpdateOwner() public {
        wallet = new MultiSignatureWallet();
        wallet.initialize(
            vm.addr(GATEKEEPER_KEY_A),
            vm.addr(GATEKEEPER_KEY_B),
            "Wallet",
            "1"
        );

        CallType[] memory callTypes = new CallType[](1);
        address[] memory addresses = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory data = new bytes[](1);

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            GATEKEEPER_KEY_A,
            keccak256(
                abi.encode(facet.updateOwner.selector, vm.addr(NEW_OWNER))
            )
        );
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(
            GATEKEEPER_KEY_B,
            keccak256(
                abi.encode(facet.updateOwner.selector, vm.addr(NEW_OWNER))
            )
        );
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);

        callTypes[0] = CallType.delegate;
        addresses[0] = address(facet);
        values[0] = 0;
        data[0] = abi.encodeWithSelector(
            facet.updateOwner.selector,
            signature1,
            signature2,
            vm.addr(NEW_OWNER)
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

        (uint8 vA, bytes32 rA, bytes32 sA) = vm.sign(GATEKEEPER_KEY_A, hash);
        bytes memory signatureA = abi.encodePacked(rA, sA, vA);
        (uint8 vB, bytes32 rB, bytes32 sB) = vm.sign(GATEKEEPER_KEY_B, hash);
        bytes memory signatureB = abi.encodePacked(rB, sB, vB);
        wallet.execute(payloads, hash, block.timestamp, signatureA, signatureB);
        assert(wallet.hasRole(OWNER_ROLE, vm.addr(NEW_OWNER)));
    }
}
