// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IStakingPlugin
 * @author Amir Shirif
 * @notice An OMNI Laboratories Contract
 */
interface IStakingPlugin is IERC165 {
    /**
     * @dev Emitted when a user's rewards are being claimed.
     */
    event Claimed(address indexed account, uint256 amount);
    /**
     * @dev Emitted when a user's rewards are being increased.
     */
    event ClaimableIncreased(address indexed account, uint256 amount);

    /**
     * @notice Returns the amount of claimable rewards for a specified account.
     * @param account The address of the account whose claimable rewards are being queried.
     * @return The total amount of rewards that the specified account can claim.
     */

    function claimable(address account) external view returns (uint256);

    /**
     * @notice Claims accrued rewards, transferring them to a specified address.
     * @param account The account address whose rewards are being claimed.
     * @param to The recipient address where the claimed rewards will be sent.
     */
    function claim(address account, address to) external;

    /**
     * @notice Increases the claimable reward amount for a specified account.
     * @param benofactory The address from which the reward tokens are sourced.
     * @param account The account whose claimable reward amount is being increased.
     * @param amount The additional amount to be added to the claimable rewards.
     */
    function increaseClaimable(
        address benofactory,
        address account,
        uint256 amount
    ) external;
}
