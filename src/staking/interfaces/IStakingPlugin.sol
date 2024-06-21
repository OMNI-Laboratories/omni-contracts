// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title IStakingPlugin
 * @author Amir Shirif
 * @notice An OMNI Laboratories Contract
 * @dev Interface for staking plugins that handle rewards for staking contracts.
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
     * @notice Returns the reward token used by the staking plugin.
     * @return The reward token.
     */
    function rewardToken() external view returns (IERC20);

    /**
     * @notice Returns the amount of claimable rewards for a specified account.
     * @param account The address of the account whose claimable rewards are being queried.
     * @return amount The total amount of rewards that the specified account can claim.
     */
    function claimable(address account) external view returns (uint256);

    /**
     * @notice Claims accrued rewards, transferring them to a specified address.
     * @param account The account address whose rewards are being claimed.
     * @param to The recipient address where the claimed rewards will be sent.
     * @return The total amount of rewards that the specified account can claim.
     */
    function claim(address account, address to) external returns (uint256);

    /**
     * @notice Increases the claimable reward amount for a specified account.
     * @param benefactor The address from which the reward tokens are sourced.
     * @param account The account whose claimable reward amount is being increased.
     * @param amount The additional amount to be added to the claimable rewards.
     */
    function increaseClaimable(
        address benefactor,
        address account,
        uint256 amount
    ) external;
}
