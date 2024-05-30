// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStakingPlugin, IERC165} from "./interfaces/IStakingPlugin.sol";
import {ERC20Recoverable} from "../ERC20/utils/ERC20Recoverable.sol";

/**
 * @title TokenStaking
 * @author Amir Shirif
 * @notice An OMNI Laboratories Contract
 *
 * @dev Contract handles staked and accruing ERC20 token rewards
 */
contract TokenStaking is
    AccessManagedUpgradeable,
    PausableUpgradeable,
    ERC20Recoverable
{
    using SafeERC20 for IERC20;

    error TokenMismatch();

    /// @custom:storage-location erc7201:omni.storage.TokenStaking
    struct TokenStakingStorage {
        IERC20 _stakingToken;
        IERC20 _rewardToken;
        uint256 _totalStaked;
        address[] _plugins;
        mapping(address => uint256) _stakedBalances;
    }

    // keccak256(abi.encode(uint256(keccak256("erc7201.omni.storage.TokenStaking")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TokenStakingStorageLocation =
        0x0ecf9edb3ac66bd178ba600b63ffbfbfd6d702cd5ee275a40b32c96c66642d00;

    event Stake(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event PluginUpdated(address indexed plugin, uint256 index, bool validity);

    address[] public plugins;

    /************************************************
     *   initializer
     ************************************************/

    function initialize(
        IERC20 stakingToken_,
        IERC20 rewardToken_
    ) external initializer {
        TokenStakingStorage storage $ = _getTokenStakingStorage();
        $._stakingToken = stakingToken_;
        $._rewardToken = rewardToken_;
    }

    /************************************************
     *   view functions
     ************************************************/

    /**
     * @notice Computes the total claimable rewards for an account across all plugins.
     * @param account The account to query claimable rewards for.
     * @return total The total claimable rewards.
     */
    function claimableBalance(
        address account
    ) public view returns (uint256 total) {
        for (uint256 i = 0; i < plugins.length; i++) {
            total += IStakingPlugin(plugins[i]).claimable(account);
        }
    }

    /**
     * @notice Returns the total balance (staked + claimable) of an account.
     * @param account The account to query the balance of.
     * @return The total balance of the account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return stakedBalance(account) + claimableBalance(account);
    }

    /************************************************
     *   staking functions
     ************************************************/

    /**
     * @notice Allows users to stake tokens.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external whenNotPaused {
        _stake(_msgSender(), _msgSender(), amount);
    }

    /**
     * @notice Allows migrating staked balances on behalf of users.
     * @param account The account for which to stake tokens.
     * @param source The source from which tokens are transferred.
     * @param amount The amount of tokens to stake.
     */
    function stakeFor(
        address account,
        address source,
        uint256 amount
    ) external whenNotPaused {
        _stake(account, source, amount);
    }

    /**
     * @notice Allows users to restake existing rewards
     */
    function stakeRewards() external whenNotPaused {
        if (stakingToken() != rewardToken()) revert TokenMismatch();

        uint256 claimBalance = claimableBalance(_msgSender());
        _claim(_msgSender(), address(this));
        _stake(_msgSender(), address(0), claimBalance);
    }

    /**
     * @dev Internal function to handle staking logic.
     */
    function _stake(address account, address source, uint256 amount) internal {
        if (amount == 0) return;

        stakingToken().safeTransferFrom(source, address(this), amount);

        updateBalance(account, stakedBalance(account) + amount);
        updateStake(totalStaked() + amount);

        emit Stake(account, amount);
    }

    /************************************************
     *   claim functions
     ************************************************/

    /**
     * @notice Allows users to claim their staking rewards.
     */
    function claim() external {
        _claim(_msgSender(), _msgSender());
    }

    /**
     * @notice Allows migrating rewards balances on behalf of users.
     * @param account The account for which to stake tokens.
     * @param destination The location of token withdrawl
     */
    function claimFor(
        address account,
        address destination
    ) external restricted {
        _claim(account, destination);
    }

    /**
     * @dev Internal function to handle reward claiming logic.
     */
    function _claim(address account, address destination) internal {
        for (uint256 i = 0; i < plugins.length; i++) {
            try
                IStakingPlugin(plugins[i]).claim(account, destination)
            {} catch {}
        }
    }

    /************************************************
     *   withdraw functions
     ************************************************/

    /**
     * @notice Allows users to withdraw their staked tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) external whenNotPaused {
        _withdraw(_msgSender(), _msgSender(), amount);
    }

    /**
     * @notice Allows migrating staked balances on behalf of users.
     * @param account The account for which to stake tokens.
     * @param destination The location of token withdrawl
     * @param amount The amount of token withdrawl
     */
    function withdrawFor(
        address account,
        address destination,
        uint256 amount
    ) external restricted whenNotPaused {
        _withdraw(account, destination, amount);
    }

    /**
     * @dev Internal function to handle withdrawal logic.
     */
    function _withdraw(
        address account,
        address destination,
        uint256 amount
    ) internal {
        require(
            stakedBalance(account) >= amount,
            "TokenStaking: cannot withdraw more than is staked"
        );

        updateBalance(account, stakedBalance(account) - amount);
        updateStake(totalStaked() - amount);

        stakingToken().safeTransfer(destination, amount);

        emit Withdraw(account, amount);
    }

    /**
     * @notice Allows users to exit staking, withdrawing all staked tokens and claiming rewards.
     */
    function exit() external whenNotPaused {
        _claim(_msgSender(), _msgSender());
        _withdraw(_msgSender(), _msgSender(), stakedBalance(_msgSender()));
    }

    /************************************************
     *   plugin functions
     ************************************************/

    /**
     * @notice Adds a new plugin to the staking contract.
     * @dev restricted only
     * @param plugin The address of the plugin to add.
     */
    function addPlugin(address plugin) external restricted {
        require(
            IERC165(plugin).supportsInterface(type(IStakingPlugin).interfaceId),
            "TokenStaking: plugin does not support IStakingPlugin"
        );

        plugins.push(plugin);
        emit PluginUpdated(plugin, plugins.length - 1, true);
    }

    /**
     * @notice Removes a plugin from the staking contract.
     * @dev restricted only
     * @param index The index of the plugin to remove.
     */
    function removePlugin(uint256 index) external restricted {
        require(index < plugins.length, "TokenStaking: Plugin does not exist");

        emit PluginUpdated(plugins[index], index, false);
        plugins[index] = plugins[plugins.length - 1];
        plugins.pop();
        emit PluginUpdated(plugins[index], index, true);
    }

    /************************************************
     *   support functions
     ************************************************/

    /**
     * @notice Pauses the staking contract, disabling staking, withdrawing, and claiming functions.
     */
    function pause() external restricted {
        _pause();
    }

    /**
     * @notice Unpauses the staking contract, re-enabling all functions.
     */
    function unpause() external restricted {
        _unpause();
    }

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

    /************************************************
     *   storage fuctions
     ************************************************/

    /**
     * @dev Retrieves the storage location of contract
     * @return $ TokenStaking storage pointer to the TokenStaking storage structure
     */
    function _getTokenStakingStorage()
        private
        pure
        returns (TokenStakingStorage storage $)
    {
        assembly {
            $.slot := TokenStakingStorageLocation
        }
    }

    function stakingToken() public view returns (IERC20) {
        TokenStakingStorage storage $ = _getTokenStakingStorage();
        return $._stakingToken;
    }

    function rewardToken() public view returns (IERC20) {
        TokenStakingStorage storage $ = _getTokenStakingStorage();
        return $._rewardToken;
    }

    function totalStaked() public view returns (uint256) {
        TokenStakingStorage storage $ = _getTokenStakingStorage();
        return $._totalStaked;
    }

    function updateStake(uint256 amount) private {
        TokenStakingStorage storage $ = _getTokenStakingStorage();
        $._totalStaked = amount;
    }

    function stakedBalance(address account) public view returns (uint256) {
        TokenStakingStorage storage $ = _getTokenStakingStorage();
        return $._stakedBalances[account];
    }

    function updateBalance(address account, uint256 amount) private {
        TokenStakingStorage storage $ = _getTokenStakingStorage();
        $._stakedBalances[account] = amount;
    }
}
