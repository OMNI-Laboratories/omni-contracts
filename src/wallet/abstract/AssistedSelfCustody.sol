// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

abstract contract AssistedSelfCustody is AccessControlEnumerableUpgradeable {
    error InvalidAdmin(address gateKeeper);

    bytes32 public constant GATEKEEPER_ROLE = keccak256("GATEKEEPER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    function __AssistedSelfCustody_init(
        address gatekeeperA,
        address gatekeeperB
    ) internal onlyInitializing {
        __AssistedSelfCustody_init_unchained(gatekeeperA, gatekeeperB);
    }

    function __AssistedSelfCustody_init_unchained(
        address gatekeeperA,
        address gatekeeperB
    ) internal onlyInitializing {
        require(
            gatekeeperA != address(0) && gatekeeperB != address(0),
            "AssistedSelfCustody: gatekeepers cannot be zero address"
        );

        require(
            gatekeeperA != gatekeeperB,
            "AssistedSelfCustody: gatekeepers and owner must be unique"
        );

        _grantRole(GATEKEEPER_ROLE, gatekeeperA);
        _grantRole(GATEKEEPER_ROLE, gatekeeperB);
    }

    function _replaceGatekeeper(
        address newGatekeeper,
        address oldGatekeeper
    ) internal {
        require(
            newGatekeeper != address(0),
            "AssistedSelfCustody: gatekeeper cannot be zero address"
        );

        if (hasRole(OWNER_ROLE, newGatekeeper))
            revert InvalidAdmin(newGatekeeper);
        // will revert if the oldGatekeeper is not an existing gateKeeper
        if (!_revokeRole(GATEKEEPER_ROLE, oldGatekeeper))
            revert InvalidAdmin(oldGatekeeper);

        // will revert if the newGatekeeper is the same as the other existing gateKeeper
        if (!_grantRole(GATEKEEPER_ROLE, newGatekeeper))
            revert InvalidAdmin(newGatekeeper);

        assert(getRoleMemberCount(GATEKEEPER_ROLE) == 2);
    }

    function _replaceOwner(address newOwner, address oldOwner) internal {
        if (hasRole(GATEKEEPER_ROLE, newOwner)) revert InvalidAdmin(newOwner);
        if (oldOwner != address(0)) _revokeRole(OWNER_ROLE, oldOwner);
        if (newOwner != address(0)) _grantRole(OWNER_ROLE, oldOwner);

        assert(getRoleMemberCount(OWNER_ROLE) > 0);
    }
}
