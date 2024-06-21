// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {AssistedCustody} from "../AssistedCustody.sol";

contract AssistedCustodyFacet is AssistedCustody {
    function replaceGatekeeper(
        bytes memory signatureA,
        bytes memory signatureB,
        address newGatekeeper,
        address oldGatekeeper
    )
        public
        onlyAuth(
            keccak256(
                abi.encode(
                    this.replaceGatekeeper.selector,
                    newGatekeeper,
                    oldGatekeeper
                )
            ),
            signatureA,
            signatureB
        )
    {
        _replaceGatekeeper(newGatekeeper, oldGatekeeper);
    }

    function updateOwner(
        bytes memory signatureA,
        bytes memory signatureB,
        address owner
    )
        public
        onlyAuth(
            keccak256(abi.encode(this.updateOwner.selector, owner)),
            signatureA,
            signatureB
        )
    {
        _updateOwner(owner);
    }
}
