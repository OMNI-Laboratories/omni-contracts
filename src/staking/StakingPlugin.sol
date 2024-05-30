// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStakingPlugin, IERC165} from "./interfaces/IStakingPlugin.sol";
import {ERC20Recoverable} from "../ERC20/utils/ERC20Recoverable.sol";

/**
 * @title StakingPlugin
 * @author Amir Shirif
 * @notice An OMNI Laboratories Contract
 *
 * @notice Handles rewards for staking contracts by implementing the IStakingPlugin interface.
 */
contract StakingPlugin is AccessManaged, ERC20Recoverable, IStakingPlugin {
    using SafeERC20 for IERC20;

    // token to be recieved and distributed
    IERC20 public immutable rewardToken;

    // mapping of users to rewards
    mapping(address => uint256) public rewards;

    /// @param token The ERC20 token to be used as rewards.
    constructor(
        address initialAuthority,
        IERC20 token
    ) AccessManaged(initialAuthority) {
        rewardToken = token;
    }

    /************************************************
     *   view functions
     ************************************************/

    /**
     * @notice Returns the amount of claimable rewards for a specified account.
     * @param account The address of the account whose claimable rewards are being queried.
     * @return The total amount of rewards that the specified account can claim.
     */

    function claimable(address account) public view returns (uint256) {
        return rewards[account];
    }

    /************************************************
     *   core functions
     ************************************************/

    /**
     * @notice Claims accrued rewards for a specified account, transferring them to a designated recipient.
     * @dev restricted only
     * @param account The account address whose rewards are to be claimed.
     * @param to The recipient address where the rewards will be sent.
     *
     * Emits a {Claimed} event.
     */
    function claim(address account, address to) external override restricted {
        uint256 amount = rewards[account];
        if (amount == 0) return;

        rewards[account] = 0;
        rewardToken.safeTransfer(to, amount);
        emit Claimed(account, amount);
    }

    /**
     * @notice Increases the claimable rewards for a specified account.
     * @dev restricted only
     * @param benofactory The address from which reward tokens are transferred.
     * @param account The account whose reward balance is to be increased.
     * @param amount The amount of tokens to be added to the claimable rewards.
     *
     * Emits a {ClaimableIncreased} event.
     */
    function increaseClaimable(
        address benofactory,
        address account,
        uint256 amount
    ) external restricted {
        if (amount == 0) return;

        rewardToken.safeTransferFrom(benofactory, address(this), amount);
        rewards[account] += amount;
        emit ClaimableIncreased(account, amount);
    }

    /************************************************
     *   pure functions
     ************************************************/

    /**
     * @notice Checks if the contract implements an interface as per ERC165 standard.
     * @param interfaceId The identifier of the interface to check.
     * @return True if the contract implements the specified interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return interfaceId == type(IStakingPlugin).interfaceId;
    }

    /************************************************
     *   support functions
     ************************************************/

    /**
     * @notice Allows the recovery of ERC20 tokens mistakenly sent to this contract.
     * @dev restricted only
     * @param token The ERC20 token to recover.
     * @param to The recipient address where the recovered tokens will be sent.
     * @param amount The amount of tokens to be recovered and transferred.
     */
    function rescueTokens(
        IERC20 token,
        address to,
        uint256 amount
    ) external restricted {
        _recover(token, to, amount);
    }
}
