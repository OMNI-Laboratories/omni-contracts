// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {OwnableFacet} from "../authorization/facets/OwnableFacet.sol";

contract MockOwnable is OwnableFacet {
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }
}
