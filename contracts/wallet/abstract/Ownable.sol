// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Ownable
 * @author Amir Shirif
 * @dev Contract module which provides a basic access control mechanism.
 *      There is an owner account that can be granted exclusive access to specific functions.
 * @notice The initial owner is set to the deployer address and can be transferred.
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
    error OwnableUnauthorizedAccount();

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

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
     * @notice Initializes the contract with the deployer as the initial owner.
     * @dev Sets the initial owner of the contract to the provided address.
     * @param initialOwner The address to be set as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(
        address initialOwner
    ) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }

        _acceptOwnership(initialOwner);
    }

    /************************************************
     *   modifier
     ************************************************/

    /**
     * @notice Ensures that a function is called only by the owner.
     * @dev Modifier that throws `OwnableUnauthorizedAccount` if called by any account other than the owner.
     * @param hash The hash of the payload.
     * @param signature The signature proving the owner's consent.
     */
    modifier onlyOwner(bytes32 hash, bytes memory signature) {
        if (!checkSignature(owner(), hash, signature))
            revert OwnableUnauthorizedAccount();
        _;
    }

    /************************************************
     *   external functions
     ************************************************/

    /**
     * @notice Transfers ownership of the contract to a new account.
     * @dev This is the intermidary step and needs to be confirmed by the new owner.
     * @param newOwner The address of the new owner.
     * @param hash The hash of the payload.
     * @param signature The signature proving the current owner's consent.
     *
     * Emits a {OwnershipTransferStarted} event.
     */
    function transferOwnership(
        address newOwner,
        bytes32 hash,
        bytes memory signature
    ) external virtual {
        if (!checkSignature(owner(), hash, signature))
            revert OwnableUnauthorizedAccount();
        emit OwnershipTransferStarted(owner(), pendingOwner());
        _transferOwnership(newOwner);
    }

    /**
     * @notice Finalizes the ownership transfer.
     * @dev Accepts the ownership transfer by the new owner.
     * @param hash The hash of the payload.
     * @param signature The signature proving the new owner's consent.
     *
     * Emits a {OwnershipTransferred} event.
     */
    function acceptOwnership(
        bytes32 hash,
        bytes memory signature
    ) external virtual {
        if (!checkSignature(pendingOwner(), hash, signature))
            revert OwnableUnauthorizedAccount();
        emit OwnershipTransferred(owner(), pendingOwner());
        _acceptOwnership(pendingOwner());
    }

    /************************************************
     *   view functions
     ************************************************/

    /**
     * @notice Returns the address of the current owner.
     * @dev Reads the owner's address from the Ownable storage.
     * @return address The address of the current owner.
     */
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @notice Returns the address of the pending owner.
     * @dev Reads the pending owner's address from the Ownable storage.
     * @return address The address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._pendingOwner;
    }

    /************************************************
     *   internal functions
     ************************************************/

    /**
     * @notice Checks if the provided signature is valid and signed by the expected signer.
     * @dev Verifies the signer's address against the provided hash and signature.
     * @param signer The address of the expected signer.
     * @param hash The hash of the payload.
     * @param signature The signature to validate.
     * @return bool True if the signature is valid, false otherwise.
     */
    function checkSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view virtual returns (bool) {
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }

    /************************************************
     *   private functions
     ************************************************/

    /**
     * @notice Retrieves the storage location of the Ownable contract.
     * @dev Uses assembly to set the storage slot for Ownable data.
     * @return $ OwnableStorage storage pointer to the Ownable storage structure.
     */
    function _getOwnableStorage()
        private
        pure
        returns (OwnableStorage storage $)
    {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @notice Begins the process of transferring ownership to a new account.
     * @dev Sets the pending owner to the new owner address.
     * @param newOwner The address of the potential new owner.
     */
    function _transferOwnership(address newOwner) private {
        OwnableStorage storage $ = _getOwnableStorage();
        $._pendingOwner = newOwner;
    }

    /**
     * @notice Completes the transfer of ownership.
     * @dev Sets the new owner and clears any pending ownership transfer.
     * @param newOwner The address of the new owner.
     */
    function _acceptOwnership(address newOwner) private {
        OwnableStorage storage $ = _getOwnableStorage();
        $._owner = newOwner;
        delete $._pendingOwner;
    }
}
