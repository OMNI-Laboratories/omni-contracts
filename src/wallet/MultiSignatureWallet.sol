// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Wallet} from "./abstract/Wallet.sol";
import {AssistedCustody} from "../utils/authorization/AssistedCustody.sol";
import {ERC1271} from "../utils/authorization/ERC1271.sol";

/**
 * @title MultiSignatureWallet
 * @author Amir Shirif
 * @notice A multi-signature wallet contract combining functionalities from Wallet, AssistedCustody, and ERC1271.
 */
contract MultiSignatureWallet is Wallet, AssistedCustody, ERC1271 {
    /************************************************
     *   initializer
     ************************************************/

    /**
     * @notice Initializes the MultiSignatureWallet contract.
     * @dev Initializes the Wallet and AssistedCustody with the provided gatekeepers, name, and version.
     * @param gatekeeperA The address of the first gatekeeper.
     * @param gatekeeperB The address of the second gatekeeper.
     * @param name The name for the EIP712 domain.
     * @param version The version for the EIP712 domain.
     */
    function initialize(
        address gatekeeperA,
        address gatekeeperB,
        string memory name,
        string memory version
    ) external initializer {
        __Wallet_init(name, version);
        __AssistedCustody_init(gatekeeperA, gatekeeperB);
    }

    /************************************************
     *   main function
     ************************************************/

    /**
     * @notice Executes a transaction after verifying signatures from authorized signers.
     * @dev Uses `_execute` function from Wallet contract to process the transaction.
     * @param payloads The encoded data for the transaction.
     * @param hash The hash of the transaction.
     * @param timestamp The timestamp for the transaction.
     * @param signatureA The signature from the first authorized signer.
     * @param signatureB The signature from the second authorized signer.
     */
    function execute(
        bytes memory payloads,
        bytes32 hash,
        uint256 timestamp,
        bytes memory signatureA,
        bytes memory signatureB
    ) external onlyAuth(hash, signatureA, signatureB) {
        _execute(payloads, hash, timestamp);
    }
}
