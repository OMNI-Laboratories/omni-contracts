// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Wallet} from "./abstract/Wallet.sol";
import {Ownable} from "../utils/authorization/Ownable.sol";
import {ERC1271} from "../utils/authorization/ERC1271.sol";

/**
 * @title SignatureWallet
 * @author Amir M. Shirif
 * @notice A smart contract wallet that is compliant with multiple ERC standards
 */
contract SignatureWallet is Wallet, Ownable, ERC1271 {
    /******************************‡******************
     *   initializer
     ************************************************/

    /**
     * @notice Initializes the VanityWallet with owner and other details.
     * @dev Calls the initialization of SignatureWallet.
     * @param owner The owner of the wallet.
     * @param name The name for the EIP712 domain.
     * @param version The version for the EIP712 domain.
     */
    function initialize(
        address owner,
        string memory name,
        string memory version
    ) external initializer {
        __Wallet_init(name, version);
        __Ownable_init(owner);
    }

    /**
     * @notice Executes a transaction using a signature for authorization.
     * @dev Processes calls or delegate calls based on decoded payload.
     * @param payloads The encoded data for the transaction.
     * @param hash The hash of the transaction.
     * @param timestamp The timestamp for the transaction.
     */
    function execute(
        bytes memory payloads,
        bytes32 hash,
        uint256 timestamp,
        bytes memory signature
    ) external onlyOwner(hash, signature) {
        _execute(payloads, hash, timestamp);
    }

    /// recieve native currency
    receive() external payable {}
}
