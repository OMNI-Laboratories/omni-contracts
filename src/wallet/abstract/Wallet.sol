// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

/**
 * @title Wallet
 * @author Amir Shirif
 * @notice This contract allows executing transactions.
 */
abstract contract Wallet is EIP712Upgradeable, NoncesUpgradeable {
    using Address for address;

    // keccak256(abi.encode(uint256(keccak256("omni.storage.Wallet")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant WalletStorageLocation =
        0xc5154be49610f74b2fe84782b25a4f474e03ba35aae9505cc0f884bc76bcf900;

    /**
     * @dev Calls are executed by the wallet, or functionality is delegated out
     */
    enum CallType {
        call,
        delegate
    }

    /**
     * @dev The signing hash is not correct
     */
    error InvalidHash();

    /**
     * @dev The payload arrays are not equal length
     */
    error InvalidPayload();

    /**
     * @dev The timestamp has expired
     */
    error InvalidTimestamp();

    bytes public reach;

    /************************************************
     *   initializer
     ************************************************/

    /**
     * @notice Initializes the Wallet contract.
     * @dev Sets up EIP712 domain and initializes the ownable contract with the given owner.
     * @param name Name for the EIP712 domain.
     * @param version Version for the EIP712 domain.
     */
    function __Wallet_init(
        string memory name,
        string memory version
    ) internal onlyInitializing {
        __EIP712_init(name, version);
        __Wallet_init_unchained();
    }

    function __Wallet_init_unchained() internal onlyInitializing {}

    /************************************************
     *   main function
     ************************************************/

    /**
     * @notice Executes a transaction.
     * @dev Processes calls or delegate calls based on decoded payload.
     * @param payloads The encoded data for the transaction.
     * @param hash The hash of the transaction.
     * @param timestamp The timestamp for the transaction.
     */
    function _execute(
        bytes memory payloads,
        bytes32 hash,
        uint256 timestamp
    ) internal virtual {
        (
            CallType[] memory callTypes,
            address[] memory addresses,
            uint256[] memory values,
            bytes[] memory data
        ) = _updateState(payloads, hash, timestamp);

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
            }
        }

        if (reach.length != 0) delete reach;
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
     * @dev Returns the domain separator
     * @return bytes32 Returns the domain separator for the current chain.
     */
    function domainSeparator() public view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    /************************************************
     *   private functions
     ************************************************/

    /**
     * @dev Internal function to update the wallet's state based on the execution of a transaction.
     * This involves verifying the transaction hash with the provided details and ensuring the transaction's timeliness.
     * It also increments the nonce to prevent replay attacks.
     * @param payload The encoded transaction data.
     * @param hash The hash of the transaction details to verify.
     * @param timestamp The timestamp for the transaction, used to ensure its timeliness.
     * @return callTypes An array of `CallType` indicating the type of each transaction.
     * @return addresses An array of addresses involved in the transactions.
     * @return values An array of values (in wei) to be sent with the transactions.
     * @return data An array of data payloads for each transaction.
     */
    function _updateState(
        bytes memory payload,
        bytes32 hash,
        uint256 timestamp
    )
        private
        returns (
            CallType[] memory callTypes,
            address[] memory addresses,
            uint256[] memory values,
            bytes[] memory data
        )
    {
        if (
            keccak256(
                abi.encode(_domainSeparatorV4(), getNonce(), timestamp, payload)
            ) != hash
        ) revert InvalidHash();

        if (block.timestamp > timestamp) revert InvalidTimestamp();

        _useNonce(address(this));

        return _decodeData(payload);
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
        ) revert InvalidPayload();
    }

    /// recieve native currency
    receive() external payable {}
}
