// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";

/**
 * @title Treason
 * @author Amir Shirif
 * @dev This abstract contract provides a mechanism to identify and handle addresses marked as nefarious
 * based on a specific role in a centralized access management system. It utilizes OpenZeppelin's access
 * management contracts to check if an address is associated with the "TREASON_ROLE_ID".
 *
 * The main purpose is to offer a unified approach across multiple contracts to determine if an address has been
 * marked as nefarious, allowing for consistent and secure handling of such addresses throughout the ecosystem.
 */
abstract contract Treason {
    /// @dev Role identifier for "treason" permissions, computed as the keccak256 hash of "TREASON_ROLE_ID".
    uint64 public constant TREASON_ROLE_ID =
        uint64(uint256(keccak256("TREASON_ROLE_ID")));

    /// @dev Custom error for flagging traitorous actions or addresses.
    error Traitorous(address traitor);

    /**
     * @dev Modifier to enforce loyalty by checking if the provided address is not marked as nefarious.
     * Reverts with the `Traitorous` error if the check fails.
     * @param auth The address of the AccessManager contract used for role management.
     * @param citizen The address to be checked for the "treason" role.
     */
    modifier loyal(address auth, address citizen) {
        if (turncoat(auth, citizen)) revert Traitorous(citizen);
        _;
    }

    /**
     * @notice Checks if an address is marked as nefarious in the access management system.
     * @param auth The address of the AccessManager contract used for role management.
     * @param citizen The address to check for the "treason" role.
     * @return status True if the address is marked as nefarious, false otherwise.
     */
    function turncoat(
        address auth,
        address citizen
    ) public view virtual returns (bool status) {
        (status, ) = IAccessManager(auth).hasRole(TREASON_ROLE_ID, citizen);
    }
}
