// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {ERC1271} from "../ERC1271.sol";

/**
 * @title ERC1271Facet
 * @author Amir Shirif
 * @notice Exposes external functions for delegate call.
 */
contract ERC1271Facet is ERC1271 {
    /**
     * @notice Allows the ability to validate or invalidate a hash.
     * @dev Updates the `hashes` mapping to reflect the validity of a hash.
     * @param signedHash The hash to validate or invalidate.
     * @param validity Boolean representing the validity of the hash.
     */
    function hashValidation(bytes32 signedHash, bool validity) external {
        _hashValidation(signedHash, validity);
    }
}
