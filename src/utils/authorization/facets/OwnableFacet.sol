// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "../Ownable.sol";

/**
 * @title OwnableFacet
 * @author Amir Shirif
 * @notice Exposes external functions for delegate call.
 */
contract OwnableFacet is Ownable {
    /**
     * @dev This is the intermidary step and needs to be confirmed by the new owner.
     * @param signature Signature of owner confirming new ownership.
     * @param newOwner The address of the new owner.
     *
     * Emits a {OwnershipTransferStarted} event.
     */
    function transferOwnership(
        bytes memory signature,
        address newOwner
    )
        public
        onlyOwner(
            keccak256(abi.encode(this.transferOwnership.selector, newOwner)),
            signature
        )
        returns (bool)
    {
        if (pendingOwner() == newOwner) return false;
        _transferOwnership(newOwner);
        return true;
    }

    /**
     * @dev Accepts the ownership transfer by the new owner.
     * @param signature Signature of new owner confirming ownership.
     *
     * Emits a {OwnershipTransferred} event.
     */
    function acceptOwnership(bytes memory signature) public {
        if (
            !_checkSignature(
                pendingOwner(),
                keccak256(abi.encode(this.acceptOwnership.selector)),
                signature
            )
        ) revert UnauthorizedAccess();
        _acceptOwnership();
    }
}
