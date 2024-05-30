// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {AssistedSelfCustody} from "./abstract/AssistedSelfCustody.sol";
import {ERC1271} from "../utils/authorization/ERC1271.sol";

abstract contract MultiSigWallet is
    AssistedSelfCustody,
    EIP712Upgradeable,
    NoncesUpgradeable,
    UUPSUpgradeable,
    ERC1271
{
    using Address for address;

    bytes4 public constant HASH_VALIDATION =
        bytes4(keccak256("_hashValidation(bytes32,bool)"));
    bytes4 public constant REPLACE_GATEKEEPER =
        bytes4(keccak256("_replaceGatekeeper(address,address)"));
    bytes4 public constant REPLACE_OWNER =
        bytes4(keccak256("_replaceOwner(address,address)"));

    mapping(bytes4 => address) private hold;

    /**
     * @dev Calls are executed by the wallet, or functionality is delegated out
     */
    enum CallType {
        select,
        self,
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
    error invalidTimestamp(uint256 timestamp);

    /**
     * @dev The signer does not have permissions
     */
    error InvalidSigner(address signer);

    function initialize(
        address gatekeeperA,
        address gatekeeperB
    ) external initializer {
        __AssistedSelfCustody_init(gatekeeperA, gatekeeperB);
    }

    modifier verifySignatures(
        bytes memory payload,
        bytes memory signature1,
        bytes memory signature2
    ) {
        bytes32 digest = _hashTypedDataV4(keccak256(payload));
        address signer1 = ECDSA.recover(digest, signature1);
        address signer2 = ECDSA.recover(digest, signature2);

        require(
            signer1 != signer2,
            "MultiSigWallet: signers cannot be the same"
        );

        if (!hasRole(GATEKEEPER_ROLE, signer1)) revert InvalidSigner(signer1);
        if (!hasRole(GATEKEEPER_ROLE, signer2) && !hasRole(OWNER_ROLE, signer2))
            revert InvalidSigner(signer2);

        _;
    }

    function execute(
        bytes memory payload,
        bytes memory signature1,
        bytes memory signature2
    ) external verifySignatures(payload, signature1, signature2) {
        (
            CallType[] memory callTypes,
            address[] memory addresses,
            uint256[] memory values,
            bytes[] memory data
        ) = _verifyState(payload);

        for (uint i; i < callTypes.length; i++) {
            if (callTypes[i] == CallType.select) {
                hold[bytes4(SafeCast.toUint32(uint160(addresses[i])))]
                    .functionCallWithValue(data[i], values[i]);
            } else if (callTypes[i] == CallType.call) {
                addresses[i].functionCallWithValue(data[i], values[i]);
            } else if (callTypes[i] == CallType.delegate) {
                addresses[i].functionDelegateCall(data[i]);
            } else if (callTypes[i] == CallType.self) {
                functionInternalCall(
                    bytes4(SafeCast.toUint32(uint160(addresses[i]))),
                    data[i]
                );
            } else revert invalidCallType();
        }
    }

    function _verifyState(
        bytes memory payload
    )
        private
        view
        returns (
            CallType[] memory,
            address[] memory,
            uint256[] memory,
            bytes[] memory
        )
    {
        (
            uint256 nonce,
            uint256 timestamp,
            CallType[] memory callTypes,
            address[] memory addresses,
            uint256[] memory values,
            bytes[] memory data
        ) = _decodeData(payload);

        if (block.timestamp > timestamp) revert invalidTimestamp(timestamp);
        //nonce

        return (callTypes, addresses, values, data);
    }

    function _decodeData(
        bytes memory encodedData
    )
        private
        pure
        returns (
            uint256 nonce,
            uint256 timestamp,
            CallType[] memory callTypes,
            address[] memory addresses,
            uint256[] memory values,
            bytes[] memory data
        )
    {
        (nonce, timestamp, callTypes, addresses, values, data) = abi.decode(
            encodedData,
            (uint256, uint256, CallType[], address[], uint256[], bytes[])
        );

        if (
            callTypes.length != addresses.length ||
            addresses.length != values.length ||
            values.length != data.length
        ) revert invalidPayload();
    }

    /**
     * TODO repace internal calls with facet pattern
     */
    function functionInternalCall(bytes4 selector, bytes memory data) internal {
        if (selector == HASH_VALIDATION) {
            (bytes32 signedHash, bool validity) = abi.decode(
                data,
                (bytes32, bool)
            );
            _hashValidation(signedHash, validity);
        } else if (selector == REPLACE_GATEKEEPER) {
            (address newGatekeeper, address oldGatekeeper) = abi.decode(
                data,
                (address, address)
            );
            _replaceGatekeeper(newGatekeeper, oldGatekeeper);
        } else if (selector == REPLACE_OWNER) {
            (address newOwner, address oldOwner) = abi.decode(
                data,
                (address, address)
            );
            _replaceOwner(newOwner, oldOwner);
        } else revert invalidCallType();
    }

    /************************************************
     *   exposed functions
     ************************************************/

    function _authorizeUpgrade(address newImplementation) internal override {}

    receive() external payable {}
}
