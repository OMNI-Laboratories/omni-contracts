// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ERC20Recoverable
 * @author Amir Shirif
 * @notice An OMNI Laboratories Contract
 *
 * @notice This abstract contract provides a mechanism for recovering ERC20 tokens that have been sent
 * to a contract by mistake. It leverages the SafeERC20 library from OpenZeppelin to safely interact
 * with ERC20 tokens.
 */
abstract contract ERC20Recoverable {
    using SafeERC20 for IERC20;

    /**
     * @dev Internal function to transfer mistakenly sent ERC20 tokens from this contract to a specified address.
     * This function should be called by a public or external function with appropriate access control mechanisms
     * to ensure only authorized entities can initiate the token recovery process.
     *
     * @param token The ERC20 token contract address of the tokens to be recovered.
     * @param destination The address where the recovered tokens should be sent.
     * @param amount The amount of tokens to recover and send to the destination address.
     */
    function _recover(
        IERC20 token,
        address destination,
        uint256 amount
    ) internal virtual {
        token.safeTransfer(destination, amount);
    }
}
