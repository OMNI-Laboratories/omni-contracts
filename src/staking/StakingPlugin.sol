// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStakingPlugin, IERC165} from "./interfaces/IStakingPlugin.sol";
import {ERC20Recoverable} from "../ERC20/utils/ERC20Recoverable.sol";

/**
 * @title StakingPlugin
 * @author Amir Shirif
 * @notice An OMNI Laboratories Contract
 * @dev Implements the IStakingPlugin interface to handle rewards for staking contracts.
 */
contract StakingPlugin is
    Initializable,
    AccessManagedUpgradeable,
    ERC20Recoverable,
    IStakingPlugin
{
    using SafeERC20 for IERC20;

    // The token to be received and distributed as rewards.
    IERC20 public reward;

    // Mapping of users to their claimable rewards.
    mapping(address => uint256) public rewards;

    /**
     * @notice Initializes the staking plugin contract with the given authority and reward token.
     * @param initialAuthority The initial authority address for access management.
     * @param token The ERC20 reward token.
     */
    function initialize(
        address initialAuthority,
        IERC20 token
    ) external initializer {
        __AccessManaged_init(initialAuthority);
        reward = token;
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

    /**
     * @notice Returns the reward token used by the staking plugin.
     * @return The reward token.
     */
    function rewardToken() public view returns (IERC20) {
        return reward;
    }

    /************************************************
     *   core functions
     ************************************************/

    /**
     * @notice Claims accrued rewards for a specified account, transferring them to a designated recipient.
     * @dev restricted only
     * @param account The account address whose rewards are to be claimed.
     * @param to The recipient address where the rewards will be sent.
     * @return amount The total amount of rewards that the specified account can claim.
     *
     * Emits a {Claimed} event.
     */
    function claim(
        address account,
        address to
    ) external override restricted returns (uint256 amount) {
        amount = rewards[account];
        if (amount == 0) return 0;

        rewards[account] = 0;
        reward.safeTransfer(to, amount);
        emit Claimed(account, amount);
    }

    /**
     * @notice Increases the claimable rewards for a specified account.
     * @dev restricted only
     * @param benefactor The address from which reward tokens are transferred.
     * @param account The account whose reward balance is to be increased.
     * @param amount The amount of tokens to be added to the claimable rewards.
     *
     * Emits a {ClaimableIncreased} event.
     */
    function increaseClaimable(
        address benefactor,
        address account,
        uint256 amount
    ) external restricted {
        if (amount == 0) return;

        reward.safeTransferFrom(benefactor, address(this), amount);
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
