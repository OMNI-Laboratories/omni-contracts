// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {BlacklistFacet} from "../../../src/utils/access/facets/BlacklistFacet.sol";
import {StorageLocation} from "../../helpers/StorageLocation.sol";

contract BlacklistTest is Test, BlacklistFacet {
    BlacklistFacet internal facet;

    function setUp() public {
        facet = new BlacklistFacet();
    }

    function test_StorageLocation() public {
        console2.log("Storage Location:");
        console2.logBytes32(
            (new StorageLocation()).getERC7201StorageLocation(
                "omni.storage.Blacklist"
            )
        );
    }

    function test_Blacklisting() public {
        assert(!facet.isBlacklisted(address(1)));
        vm.expectEmit(true, true, false, false);
        emit AddBlacklist(address(1));
        facet.addBlacklist(address(1));
        assert(facet.isBlacklisted(address(1)));
        vm.expectEmit(true, true, false, false);
        emit RemoveBlacklist(address(1));
        facet.removeBlacklist(address(1));
        assert(!facet.isBlacklisted(address(1)));
    }

    function test_AlreadyBlacklisted() public {
        facet.addBlacklist(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(Blacklisted.selector, address(1))
        );
        facet.addBlacklist(address(1));
    }
}
