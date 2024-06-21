// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Treason} from "../utils/access/Treason.sol";
import {ERC20Recoverable, IERC20} from "./utils/ERC20Recoverable.sol";
import {ERC20Base, ERC20Upgradeable} from "./ERC20Base.sol";

/**
 * @title ERC20Bridged
 * @author Amir Shirif
 * @dev ERC20Bridged is an extension of the ERC20Base token that incorporates bridging functionalities,
 * access management, pausability, and treason checks, offering a comprehensive solution for cross-chain
 * token implementations. It supports minting and burning tokens for bridging purposes, enforces access
 * control, allows pausing and unpausing token transfers, and restricts transactions involving addresses
 * deemed as treasonous.
 */
contract ERC20Bridged is
    ERC20Base,
    ERC20Recoverable,
    AccessManagedUpgradeable,
    PausableUpgradeable,
    Treason
{
    /************************************************
     *   initializer
     ************************************************/

    /**
     * @dev Initializes the ERC20Bridged contract by setting up the base token, access management, and
     * initial minting. This function wraps the internal initialization logic.
     * @param initialAuthority The initial authority for access management.
     * @param name The name of the ERC20 token.
     * @param symbol The symbol of the ERC20 token.
     * @param decimal The number of decimal places for the ERC20 token.
     * @param initialMint The amount of tokens to mint initially.
     */
    function erc20Bridged_init(
        address initialAuthority,
        string memory name,
        string memory symbol,
        uint8 decimal,
        uint256 initialMint
    ) external initializer {
        __ERC20Bridged_init(
            initialAuthority,
            name,
            symbol,
            decimal,
            initialMint
        );
    }

    /// @dev Internal function to chain initialization calls for setting up the contract.
    function __ERC20Bridged_init(
        address initialAuthority,
        string memory name,
        string memory symbol,
        uint8 decimal,
        uint256 initialMint
    ) internal onlyInitializing {
        __ERC20Bridged_init_unchained(initialAuthority);
        __ERC20Base_init(name, symbol, decimal, initialMint);
    }

    /// @dev Internal function to chain initialization calls for setting up the contract.
    function __ERC20Bridged_init_unchained(
        address initialAuthority
    ) internal onlyInitializing {
        __AccessManaged_init(initialAuthority);
    }

    /************************************************
     *   total supply
     ************************************************/

    /**
     * @notice Mints tokens to a specified account. Restricted to authorized roles only.
     * @param account The address to receive the minted tokens.
     * @param value The amount of tokens to mint.
     */
    function mintTo(address account, uint256 value) public restricted {
        _mint(account, value);
    }

    /**
     * @notice Allows token holders to burn their tokens, reducing the total supply.
     * @param value The amount of tokens to burn from the caller's balance.
     */
    function withdraw(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @notice Allows an approved spender to burn tokens from another account's balance, with the account's approval.
     * @param account The address from which tokens will be burned.
     * @param value The amount of tokens to burn.
     */
    function withdrawFrom(address account, uint256 value) public {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }

    /************************************************
     *   internal
     ************************************************/

    /**
     * @dev Overrides the _update function to enforce loyalty checks on token transfers, in addition to pausability.
     * Transactions from or to addresses deemed treasonous are prevented.
     * @param from The address sending the tokens.
     * @param to The address receiving the tokens.
     * @param value The amount of tokens to transfer.
     */
    function _update(
        address from,
        address to,
        uint256 value
    )
        internal
        virtual
        override
        whenNotPaused
        loyal(authority(), from)
        loyal(authority(), to)
    {
        ERC20Upgradeable._update(from, to, value);
    }

    /************************************************
     *   support
     ************************************************/

    /**
     * @notice Allows recovery of ERC20 tokens sent to this contract by mistake.
     * @param token The ERC20 token contract of the tokens to recover.
     * @param destination The address to which the recovered tokens will be sent.
     * @param amount The amount of tokens to recover and send to the destination.
     */
    function ERC20Recover(
        IERC20 token,
        address destination,
        uint256 amount
    ) external restricted {
        _recover(token, destination, amount);
    }

    /************************************************
     *   pause
     ************************************************/

    /// @notice Pauses all token transfers.
    function pause() public restricted whenNotPaused {
        _pause();
    }

    /// @notice Unpauses all token transfers.
    function unpause() public restricted whenPaused {
        _unpause();
    }
}
