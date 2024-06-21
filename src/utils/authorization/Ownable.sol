// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title Ownable
 * @author Amir Shirif
 * @notice Contract module which provides a basic access control mechanism.
 *      There is an owner account that can be granted exclusive access to specific functions.
 */
abstract contract Ownable is Initializable {
    /// @custom:storage-location erc7201:omni.storage.Ownable
    struct OwnableStorage {
        address _owner;
        address _pendingOwner;
    }

    // keccak256(abi.encode(uint256(keccak256("omni.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation =
        0x57a2f0551d08e0e9f7027ff2bb4380977cf79773d8d888893950ef640e367300;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error UnauthorizedAccess();

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error InvalidOwner();

    /**
     * @dev The owner is to be swapped out, the pending owner has been updated
     */
    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The owner is swapped out, the pending owner has been upgraded to the new owner
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /************************************************
     *   initializer
     ************************************************/

    /**
     * @dev Sets the value for {initialOwner}
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(
        address initialOwner
    ) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert InvalidOwner();
        }

        _accept(initialOwner);
    }

    /************************************************
     *   modifier
     ************************************************/

    /// @dev Modifier to restrict function access to owner's signature
    modifier onlyOwner(bytes32 hash, bytes memory signature) {
        _onlyOwner(hash, signature);
        _;
    }

    /************************************************
     *   view functions
     ************************************************/

    /**
     * @dev Reads the owner's address from the Ownable storage.
     * @return address The address of the current owner.
     */
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Reads the pending owner's address from the Ownable storage.
     * @return address The address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._pendingOwner;
    }

    /************************************************
     *   verification functions
     ************************************************/

    /**
     * @dev restricts actions to only the owner
     * @param hash The hash that was signed
     * @param signature The signature being verified
     */
    function _onlyOwner(bytes32 hash, bytes memory signature) internal view {
        if (!_checkSignature(owner(), hash, signature))
            revert UnauthorizedAccess();
    }

    /**
     * @dev Verifies the signer's address against the provided hash and signature.
     * @param signer The address of the expected signer.
     * @param hash The hash of the payload.
     * @param signature The signature to validate.
     * @return bool True if the signature is valid, false otherwise.
     */
    function _checkSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view virtual returns (bool) {
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }

    /************************************************
     *   update functions
     ************************************************/

    /**
     * @dev This is the intermidary step and needs to be confirmed by the new owner.
     * @param newOwner The address of the new owner.
     *
     * Emits a {OwnershipTransferStarted} event.
     */
    function _transferOwnership(address newOwner) internal virtual {
        emit OwnershipTransferStarted(owner(), newOwner);
        _transfer(newOwner);
    }

    /**
     * @dev Accepts the ownership transfer by the new owner.
     *
     * Emits a {OwnershipTransferred} event.
     */
    function _acceptOwnership() internal virtual {
        emit OwnershipTransferred(owner(), pendingOwner());
        _accept(pendingOwner());
    }

    /************************************************
     *   storage functions
     ************************************************/

    /**
     * @dev Retrieves the storage location of the Ownable contract
     * @return $ OwnableStorage storage pointer to the Ownable storage structure.
     */
    function _getOwnableStorage()
        private
        pure
        returns (OwnableStorage storage $)
    {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /// @dev private function to set the new pending owner
    function _transfer(address newOwner) private {
        OwnableStorage storage $ = _getOwnableStorage();
        $._pendingOwner = newOwner;
    }

    /// @dev private function to set the new owner
    function _accept(address newOwner) private {
        OwnableStorage storage $ = _getOwnableStorage();
        $._owner = newOwner;
        delete $._pendingOwner;
    }
}
