// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {SignatureWallet} from "./abstract/SignatureWallet.sol";

/**
 * @title Wallet
 * @author Amir M. Shirif
 * @notice A smart contract wallet that is compliant with multiple ERC standards
 */
contract Wallet is SignatureWallet, IERC1271 {
    /// @custom:storage-location erc7201:omni.storage.Wallet
    struct WalletStorage {
        mapping(bytes32 => bool) hashes;
    }

    // keccak256(abi.encode(uint256(keccak256("omni.storage.Wallet")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant WalletStorageLocation =
        0xc5154be49610f74b2fe84782b25a4f474e03ba35aae9505cc0f884bc76bcf900;

    // MAGIC_VALUE is a constant used to indicate a valid signature as per ERC-1271 standards.
    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;

    /**
     * @dev Provides state of signed hash
     */
    event UpdateSignatureValidation(bytes32 signedHash, bool validity);

    /************************************************
     *   initializer
     ************************************************/

    /**
     * @notice Initializes the VanityWallet with owner and other details.
     * @dev Calls the initialization of SignatureWallet.
     * @param owner The owner of the wallet.
     * @param identifier A unique identifier for the wallet.
     * @param name The name for the EIP712 domain.
     * @param version The version for the EIP712 domain.
     */
    function initialize(
        address owner,
        uint256 identifier,
        string memory name,
        string memory version
    ) external initializer {
        __SignatureWallet_init(owner, identifier, name, version);
    }

    /************************************************
     *   signature functions
     ************************************************/

    /**
     * @notice Validates a given signature according to ERC-1271.
     * @dev Returns MAGIC_VALUE if the signature is valid, otherwise returns 0xffffffff.
     * @param hash The hash of the data signed.
     * @param signature The signature to validate.
     * @return bytes4 MAGIC_VALUE if the signature is valid, otherwise returns 0xffffffff.
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4) {
        if (checkSignature(owner(), hash, signature)) {
            return MAGIC_VALUE;
        }

        return 0xffffffff;
    }

    /**
     * @notice Allows the owner to validate or invalidate a hash.
     * @dev Updates the `hashes` mapping to reflect the validity of a hash.
     * @param hash The hash of the data signed.
     * @param signature The signature to authorize this operation.
     * @param signedHash The hash to validate or invalidate.
     * @param validity Boolean representing the validity of the hash.
     *
     * Emits a {UpdateSignatureValidation} event.
     */
    function hashValidation(
        bytes32 hash,
        bytes memory signature,
        bytes32 signedHash,
        bool validity
    ) external onlyOwner(hash, signature) {
        _updateValidation(signedHash, validity);
        emit UpdateSignatureValidation(signedHash, validity);
    }

    /************************************************
     *   private functions
     ************************************************/

    /**
     * @notice Retrieves the storage slot for the WalletStorage struct.
     * @dev This function uses inline assembly to directly set the storage slot of the WalletStorage struct.
     * This is a private function as it's critical for internal workings of the contract and should not be exposed externally.
     * @return $ A reference to the WalletStorage struct located at the predefined storage slot.
     */
    function _getWalletStorage()
        private
        pure
        returns (WalletStorage storage $)
    {
        assembly {
            $.slot := WalletStorageLocation
        }
    }

    /**
     * @notice Updates the validation state of a given hash in the wallet's storage.
     * @dev This function modifies the `hashes` mapping within the WalletStorage struct to reflect the new validity state of a hash.
     * This is a key operation for managing hash validations, particularly for operations that depend on the validity of a hash.
     * @param signedHash The hash whose validity status is being updated.
     * @param validity A boolean indicating the new validity status of the hash (true for valid, false for invalid).
     */
    function _updateValidation(bytes32 signedHash, bool validity) private {
        WalletStorage storage $ = _getWalletStorage();
        $.hashes[signedHash] = validity;
    }

    receive() external payable {}
}
