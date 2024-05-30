// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

/**
 * @title Blacklist
 * @author Amir Shirif
 * @dev This abstract contract provides functionality to maintain and check against a blacklist of addresses.
 * It allows inheriting contracts to add or remove addresses from the blacklist and includes a modifier to
 * restrict access or functionality to non-blacklisted addresses only. This is particularly useful for
 * implementing compliance and regulatory controls in smart contracts, such as preventing transactions with
 * certain addresses.
 */
abstract contract Blacklist {
    /// @custom:storage-location erc7201:omni.storage.Blacklist
    struct BlacklistStorage {
        mapping(address => bool) blacklist;
    }

    // keccak256(abi.encode(uint256(keccak256("omni.storage.Blacklist")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BlacklistStorageLocation =
        0x52a5532763b6af0962450dcdd19b75352bde1d9558ef2f91ae30933444084100;

    /// @dev Custom error for flagging attempts to interact with or by blacklisted addresses.
    error Blacklisted(address blacklisted);

    /// @dev Emitted when an address is added to the blacklist.
    event AddBlacklist(address blacklistee);

    /// @dev Emitted when an address is removed from the blacklist.
    event RemoveBlacklist(address delistee);

    /// @dev Modifier that blocks blacklisted addresses from accessing certain functions.
    /// @param address_ The address to check against the blacklist.
    modifier notBlacklisted(address address_) {
        if (isBlacklisted(address_)) revert Blacklisted(address_);
        _;
    }

    /**
     * @notice Checks if an address is on the blacklist.
     * @param check The address to verify against the blacklist.
     * @return blacklisted Returns true if the address is blacklisted, false otherwise.
     */
    function isBlacklisted(
        address check
    ) public view virtual returns (bool blacklisted) {
        BlacklistStorage storage $ = _getBlacklistStorage();
        return $.blacklist[check];
    }

    ///@dev functionality for when an address is listed
    function _onceBlacklisted(address blacklistee) internal virtual;

    ///@dev functionality for changing listed
    function _updateBlacklist(address blacklistee, bool add) internal {
        if (add) {
            _addBlacklist(blacklistee);
            emit AddBlacklist(blacklistee);
        } else {
            _removeBlacklist(blacklistee);
            emit RemoveBlacklist(blacklistee);
        }
    }

    /************************************************
     *   memory fuctions
     ************************************************/

    /**
     * @dev Retrieves the storage location of contract
     * @return $ Blacklist storage pointer to the Blacklist storage structure
     */
    function _getBlacklistStorage()
        private
        pure
        returns (BlacklistStorage storage $)
    {
        assembly {
            $.slot := BlacklistStorageLocation
        }
    }

    /**
     * @dev Internal function to add an address to the blacklist
     * Emits `AddBlacklist` event.
     * @param blacklistee The address to add to the blacklist.
     */
    function _addBlacklist(address blacklistee) private {
        BlacklistStorage storage $ = _getBlacklistStorage();
        $.blacklist[blacklistee] = true;
    }

    /**
     * @dev Internal function to remove an address from the blacklist.
     * Emits `RemoveBlacklist` event.
     * @param delistee The address to remove from the blacklist.
     */
    function _removeBlacklist(address delistee) private {
        BlacklistStorage storage $ = _getBlacklistStorage();
        $.blacklist[delistee] = false;
    }
}
