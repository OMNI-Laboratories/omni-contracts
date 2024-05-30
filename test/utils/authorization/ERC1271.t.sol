// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ERC1271Facet} from "../../../src/utils/authorization/facets/ERC1271Facet.sol";
import {StorageLocation} from "../../helpers/StorageLocation.sol";

contract ERC1271Test is Test, ERC1271Facet {
    bytes32 private constant MESSAGE_HASH = keccak256("MESSAGE_HASH");
    bytes32 private constant INVALID_HASH = keccak256("INVALID_HASH");
    bytes4 private constant FAIL_VALUE = 0xffffffff;
    bytes private constant SIGNATURE = "0x";

    ERC1271Facet private erc1271;

    function setUp() public {
        erc1271 = new ERC1271Facet();
    }

    function test_StorageLocation() public {
        console2.log("Storage Location:");
        console2.logBytes32(
            (new StorageLocation()).getERC7201StorageLocation(
                "omni.storage.ERC1271"
            )
        );
    }

    function test_HashValidation() public {
        vm.expectEmit(true, true, false, false);
        emit UpdateSignatureValidation(MESSAGE_HASH, true);
        erc1271.hashValidation(MESSAGE_HASH, true);
        assertEq(
            erc1271.isValidSignature(MESSAGE_HASH, SIGNATURE),
            MAGIC_VALUE
        );

        erc1271.hashValidation(MESSAGE_HASH, true);
        assertEq(erc1271.isValidSignature(INVALID_HASH, SIGNATURE), FAIL_VALUE);
    }
}
