// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Blacklist} from "../Blacklist.sol";

/**
 * @title BlacklistFacet
 * @author Amir Shirif
 * @notice Exposes external functions for delegate call.
 */
contract BlacklistFacet is Blacklist {
    /**
     * @dev Changes address status to blacklisted
     * @param blacklistee Address that will have status updated
     *
     * Emits a {AddBlacklist} event.
     */
    function addBlacklist(
        address blacklistee
    ) public notBlacklisted(blacklistee) {
        _updateBlacklist(blacklistee, true);
        _onceBlacklisted(blacklistee);
    }

    /**
     * @dev Changes address status to not blacklisted
     * @param blacklistee Address that will have status updated
     *
     * Emits a {Blacklisted} event.
     */
    function removeBlacklist(address blacklistee) public virtual {
        _updateBlacklist(blacklistee, false);
    }

    function _onceBlacklisted(address blacklistee) internal virtual override {}
}
