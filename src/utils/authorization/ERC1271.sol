// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

abstract contract ERC1271 is IERC1271 {
    /// @custom:storage-location erc7201:omni.storage.ERC1271
    struct ERC1271Storage {
        mapping(bytes32 => bool) hashes;
    }

    // keccak256(abi.encode(uint256(keccak256("omni.storage.ERC1271")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC1271StorageLocation =
        0xe707adfcc93f718b722316240cb30b7436d0b441ed0e359a59c7cacc0cf98d00;

    // MAGIC_VALUE is a constant used to indicate a valid signature as per ERC-1271 standards.
    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;

    /**
     * @dev Provides state of signed hash
     */
    event UpdateSignatureValidation(bytes32 signedHash, bool validity);

    /**
     * @notice Validates a given signature according to ERC-1271.
     * @param hash The hash of the data signed.
     * @return bytes4 MAGIC_VALUE if the signature is valid, otherwise returns 0xffffffff.
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory
    ) external view virtual override returns (bytes4) {
        if (_validSignature(hash)) return MAGIC_VALUE;

        return 0xffffffff;
    }

    /**
     * @notice Allows the ability to validate or invalidate a hash.
     * @dev Updates the `hashes` mapping to reflect the validity of a hash.
     * @param signedHash The hash to validate or invalidate.
     * @param validity Boolean representing the validity of the hash.
     *
     * Emits a {UpdateSignatureValidation} event.
     */
    function _hashValidation(bytes32 signedHash, bool validity) internal {
        _updateValidation(signedHash, validity);
        emit UpdateSignatureValidation(signedHash, validity);
    }

    /************************************************
     *   private functions
     ************************************************/

    /**
     * @notice Retrieves the storage slot for the ERC1271Storage struct.
     * @dev This function uses inline assembly to directly set the storage slot of the ERC1271Storage struct.
     * This is a private function as it's critical for internal workings of the contract and should not be exposed externally.
     * @return $ A reference to the ERC1271Storage struct located at the predefined storage slot.
     */
    function _getERC1271Storage()
        private
        pure
        returns (ERC1271Storage storage $)
    {
        assembly {
            $.slot := ERC1271StorageLocation
        }
    }

    function _validSignature(bytes32 hash) private view returns (bool) {
        ERC1271Storage storage $ = _getERC1271Storage();
        return $.hashes[hash];
    }

    /**
     * @notice Updates the validation state of a given hash in the ERC1271's storage.
     * @dev This function modifies the `hashes` mapping within the ERC1271Storage struct to reflect the new validity state of a hash.
     * This is a key operation for managing hash validations, particularly for operations that depend on the validity of a hash.
     * @param signedHash The hash whose validity status is being updated.
     * @param validity A boolean indicating the new validity status of the hash (true for valid, false for invalid).
     */
    function _updateValidation(bytes32 signedHash, bool validity) private {
        ERC1271Storage storage $ = _getERC1271Storage();
        $.hashes[signedHash] = validity;
    }
}
