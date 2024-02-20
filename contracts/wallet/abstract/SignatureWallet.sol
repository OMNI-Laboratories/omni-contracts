// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {Ownable} from "./Ownable.sol";

/**
 * @title SignatureWallet
 * @author Amir Shirif
 * @dev Abstract contract providing functionality for wallet operations via signatures.
 * @notice This contract allows executing transactions securely using EIP712 signatures.
 */
abstract contract SignatureWallet is
    Ownable,
    EIP712Upgradeable,
    NoncesUpgradeable
{
    using Address for address;

    /// @custom:storage-location erc7201:omni.storage.SignatureWallet
    struct SignatureWalletStorage {
        uint256 _identifier;
    }

    // keccak256(abi.encode(uint256(keccak256("omni.storage.SignatureWallet")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SignatureWalletStorageLocation =
        0xb24f6261f805c5c2d81ba207a356e04f3c4354fc52c47d7f6e2646e66fb0b400;

    /**
     * @dev Calls are executed by the wallet, or functionality is delegated out
     */
    enum CallType {
        call,
        delegate
    }

    /**
     * @dev The payload arrays are not equal length
     */
    error invalidPayload();

    /**
     * @dev The type is not `call` or `delegatecall`
     */
    error invalidCallType();

    /**
     * @dev The timestamp has expired
     */
    error invalidTimestamp();

    bytes public reach;

    /************************************************
     *   initializer
     ************************************************/

    /**
     * @notice Initializes the SignatureWallet contract.
     * @dev Sets up EIP712 domain and initializes the ownable contract with the given owner.
     * @param owner The address of the initial owner.
     * @param identifier Unique identifier for the wallet.
     * @param name Name for the EIP712 domain.
     * @param version Version for the EIP712 domain.
     */
    function __SignatureWallet_init(
        address owner,
        uint256 identifier,
        string memory name,
        string memory version
    ) internal onlyInitializing {
        __EIP712_init(name, version);
        __Ownable_init(owner);
        __SignatureWallet_init_unchained(identifier);
    }

    function __SignatureWallet_init_unchained(
        uint256 identifier
    ) internal onlyInitializing {
        SignatureWalletStorage storage $ = _getSignatureWalletStorage();
        $._identifier = identifier;
    }

    /************************************************
     *   main function
     ************************************************/

    /**
     * @notice Executes a transaction using a signature for authorization.
     * @dev Processes calls or delegate calls based on decoded payload.
     * @param timestamp The timestamp for the transaction.
     * @param hash The hash of the transaction.
     * @param signature The signature authorizing the transaction.
     * @param payloads The encoded data for the transaction.
     */
    function execute(
        uint256 timestamp,
        bytes32 hash,
        bytes memory signature,
        bytes memory payloads
    ) external onlyOwner(hash, signature) {
        _updateState(hash, payloads, timestamp);

        (
            CallType[] memory callTypes,
            address[] memory addresses,
            uint256[] memory values,
            bytes[] memory data
        ) = _decodeData(payloads);

        for (uint i; i < callTypes.length; i++) {
            if (callTypes[i] == CallType.call) {
                bytes memory returndata = addresses[i].functionCallWithValue(
                    data[i],
                    values[i]
                );
                if (returndata.length != 0) reach = returndata;
            } else if (callTypes[i] == CallType.delegate) {
                bytes memory returndata = addresses[i].functionDelegateCall(
                    data[i]
                );
                if (returndata.length != 0) reach = returndata;
            } else {
                revert invalidCallType();
            }
        }

        if (reach.length != 0) reach = "";
    }

    /************************************************
     *   view functions
     ************************************************/

    /**
     * @notice Retrieves the current nonce for the wallet.
     * @dev The nonce is used to prevent replay attacks by ensuring each transaction is unique.
     * This function is a public view function, allowing external entities to determine the next valid nonce value.
     * @return uint256 The current nonce value for the wallet.
     */
    function getNonce() public view virtual returns (uint256) {
        return nonces(address(this));
    }

    /**
     * @notice Retrieves the unique identifier for the wallet.
     * @dev This identifier is used to distinguish this wallet within the ecosystem and may be used in constructing unique transaction hashes.
     * This function is a public view function, allowing external entities to access the wallet's identifier.
     * @return uint256 The unique identifier of the wallet.
     */
    function getIdentifier() public view virtual returns (uint256) {
        return _getIdentifier();
    }

    /************************************************
     *   private functions
     ************************************************/

    /**
     * @dev Internal function to update the wallet's state based on the execution of a transaction.
     * This involves verifying the transaction hash with the provided details and ensuring the transaction's timeliness.
     * It also increments the nonce to prevent replay attacks.
     * @param hash The hash of the transaction details to verify.
     * @param payload The encoded transaction data.
     * @param timestamp The timestamp for the transaction, used to ensure its timeliness.
     */
    function _updateState(
        bytes32 hash,
        bytes memory payload,
        uint256 timestamp
    ) private {
        require(
            keccak256(
                abi.encode(
                    _domainSeparatorV4(),
                    _getIdentifier(),
                    getNonce(),
                    timestamp,
                    payload
                )
            ) == hash,
            "SignatureWallet: provided hash is not valid"
        );

        if (block.timestamp > timestamp) revert invalidTimestamp();

        _useNonce(address(this));
    }

    /**
     * @dev Internal pure function to decode the encoded transaction data.
     * This function decodes the data into its constituent components: call types, addresses, values, and transaction data.
     * It ensures the integrity of the transaction details by checking the lengths of the decoded arrays.
     * @param encodedData The encoded transaction data.
     * @return callTypes An array of `CallType` indicating the type of each transaction.
     * @return addresses An array of addresses involved in the transactions.
     * @return values An array of values (in wei) to be sent with the transactions.
     * @return data An array of data payloads for each transaction.
     */
    function _decodeData(
        bytes memory encodedData
    )
        private
        pure
        returns (
            CallType[] memory callTypes,
            address[] memory addresses,
            uint256[] memory values,
            bytes[] memory data
        )
    {
        (callTypes, addresses, values, data) = abi.decode(
            encodedData,
            (CallType[], address[], uint256[], bytes[])
        );

        if (
            callTypes.length != addresses.length ||
            addresses.length != values.length ||
            values.length != data.length
        ) revert invalidPayload();

        return (callTypes, addresses, values, data);
    }

    /**
     * @dev Retrieves the storage structure for SignatureWallet.
     * @return $ SignatureWalletStorage storage pointer to the SignatureWallet storage structure.
     */
    function _getSignatureWalletStorage()
        private
        pure
        returns (SignatureWalletStorage storage $)
    {
        assembly {
            $.slot := SignatureWalletStorageLocation
        }
    }

    /**
     * @dev Retrieves the unique identifier for the SignatureWallet.
     * This identifier distinguishes this wallet instance for various operations and verifications within the contract.
     * Utilizes the `_getSignatureWalletStorage` internal function to access the wallet's storage location directly.
     * @return uint256 The unique identifier of the SignatureWallet, stored within the SignatureWalletStorage struct.
     */
    function _getIdentifier() private view returns (uint256) {
        SignatureWalletStorage storage $ = _getSignatureWalletStorage();
        return $._identifier;
    }
}
