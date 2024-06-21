// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

/**
 * @title AssistedCustody
 * @author Amir Shirif
 * @notice This abstract contract provides role-based access control with multiple gatekeepers.
 */
abstract contract AssistedCustody is AccessControlEnumerableUpgradeable {
    /**
     * @dev Error thrown when an invalid admin is provided.
     * @param admin The invalid admin address.
     */
    error InvalidAdmin(address admin);

    bytes32 public constant GATEKEEPER_ROLE = keccak256("GATEKEEPER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /************************************************
     *   Initializer functions
     ************************************************/

    /**
     * @notice Initializes the contract with two gatekeepers.
     * @dev Ensures the gatekeepers are unique and not zero addresses.
     * @param gatekeeperA The address of the first gatekeeper.
     * @param gatekeeperB The address of the second gatekeeper.
     */
    function __AssistedCustody_init(
        address gatekeeperA,
        address gatekeeperB
    ) internal onlyInitializing {
        __AssistedCustody_init_unchained(gatekeeperA, gatekeeperB);
    }

    function __AssistedCustody_init_unchained(
        address gatekeeperA,
        address gatekeeperB
    ) internal onlyInitializing {
        require(
            gatekeeperA != address(0) && gatekeeperB != address(0),
            "AssistedCustody: gatekeepers cannot be zero address"
        );

        require(
            gatekeeperA != gatekeeperB,
            "AssistedCustody: gatekeepers and owner must be unique"
        );

        _grantRole(GATEKEEPER_ROLE, gatekeeperA);
        _grantRole(GATEKEEPER_ROLE, gatekeeperB);
    }

    /************************************************
     *   modifier
     ************************************************/

    /// @dev Modifier to restrict function access to owner's signature
    modifier onlyAuth(
        bytes32 hash,
        bytes memory signatureA,
        bytes memory signatureB
    ) {
        _onlyAuth(hash, signatureA, signatureB);
        _;
    }

    /************************************************
     *   Authorization functions
     ************************************************/

    /**
     * @dev restricts actions to only the owner
     * @param hash The hash that was signed
     * @param signatureA Signature being verified
     * @param signatureB Signature being verified
     */
    function _onlyAuth(
        bytes32 hash,
        bytes memory signatureA,
        bytes memory signatureB
    ) internal view {
        address signerA = _checkSignature(hash, signatureA);
        address signerB = _checkSignature(hash, signatureB);

        require(
            signerA != signerB &&
                ((hasRole(GATEKEEPER_ROLE, signerA) &&
                    hasRole(GATEKEEPER_ROLE, signerB)) ||
                    (hasRole(GATEKEEPER_ROLE, signerA) &&
                        hasRole(OWNER_ROLE, signerB)) ||
                    (hasRole(OWNER_ROLE, signerA) &&
                        hasRole(GATEKEEPER_ROLE, signerB))),
            "AssistedCustody: Invalid signature"
        );
    }

    /**
     * @dev Verifies the signer's address against the provided hash and signature.
     * @param hash The hash of the payload.
     * @param signature The signature to validate.
     * @return bool True if the signature is valid, false otherwise.
     */
    function _checkSignature(
        bytes32 hash,
        bytes memory signature
    ) internal view virtual returns (address) {
        (address recovered, , ) = ECDSA.tryRecover(hash, signature);

        return recovered;
    }

    /************************************************
     *   Gatekeeper functions
     ************************************************/

    /**
     * @notice Replaces an existing gatekeeper with a new one.
     * @dev Ensures the new gatekeeper is not a zero address or the owner, and that there are exactly two gatekeepers.
     * @param newGatekeeper The address of the new gatekeeper.
     * @param oldGatekeeper The address of the gatekeeper to be replaced.
     */
    function _replaceGatekeeper(
        address newGatekeeper,
        address oldGatekeeper
    ) internal {
        require(
            newGatekeeper != address(0),
            "AssistedCustody: gatekeeper cannot be zero address"
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

    /************************************************
     *   Owner functions
     ************************************************/

    /**
     * @notice Replaces the current owner with a new owner.
     * @param owner The address of the new owner.
     */
    function _updateOwner(address owner) internal {
        if (hasRole(GATEKEEPER_ROLE, owner)) revert InvalidAdmin(owner);
        if (!_grantRole(OWNER_ROLE, owner)) _revokeRole(OWNER_ROLE, owner);
    }
}
