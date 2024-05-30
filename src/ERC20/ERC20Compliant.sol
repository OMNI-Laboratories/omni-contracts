// // SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity ^0.8.25;

// import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
// import {ERC20Base, ERC20Upgradeable} from "./ERC20Base.sol";
// import {ERC20Recoverable, IERC20} from "./utils/ERC20Recoverable.sol";
// import {Blacklist} from "../utils/access/Blacklist.sol";

// /**
//  * @title ERC20Compliant
//  * @author Amir Shirif
//  * @notice An ERC20 token that integrates pause functionality, permit support, and blacklist checks,
//  * extending ERC20Base with additional compliance features.
//  * @dev This contract inherits from ERC20Base, PausableUpgradeable, and Blacklist to provide a comprehensive
//  * ERC20 token implementation with enhanced security and usability features.
//  */
// contract ERC20Compliant is
//     ERC20Base,
//     AccessControlUpgradeable,
//     PausableUpgradeable,
//     ERC20Recoverable,
//     Blacklist
// {
//     bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
//     bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT_ROLE");
//     bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

//     /************************************************
//      *   initializer
//      ************************************************/

//     /**
//      * @notice Initializes the ERC20Base contract with necessary parameters.
//      * @param name The name of the ERC20 token.
//      * @param symbol The symbol of the ERC20 token.
//      * @param decimal The number of decimal places for the ERC20 token.
//      * @param initialMint The amount of tokens to mint upon initialization, scaled by the token's decimals.
//      */
//     function erc20Compliant_init(
//         string memory name,
//         string memory symbol,
//         uint8 decimal,
//         uint256 initialMint
//     ) external initializer {
//         _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
//         __ERC20Base_init(name, symbol, decimal, initialMint);
//     }

//     /************************************************
//      *   blacklist
//      ************************************************/

//     /**
//      * @notice Adds an address to the blacklist, preventing it from participating in token transactions.
//      * This action can only be performed by accounts with the BLACKLISTER_ROLE.
//      * @dev Calls internal function `_addBlacklist` to update the blacklist mapping and emits
//      * an event. It also transfers any tokens held by the blacklistee to the caller to ensure
//      * that blacklisted addresses cannot use or hold tokens.
//      * @param blacklistee The address to be added to the blacklist.
//      */
//     function addBlacklist(
//         address blacklistee
//     ) public virtual onlyRole(BLACKLISTER_ROLE) {
//         _onceBlacklisted(blacklistee);
//         _addBlacklist(blacklistee);
//     }

//     /**
//      * @notice Removes an address from the blacklist, allowing it to participate in token transactions again.
//      * This action can only be performed by accounts with the BLACKLISTER_ROLE.
//      * @dev Calls internal function `_removeBlacklist` to update the blacklist mapping and emits
//      * an event indicating the address has been removed from the blacklist.
//      * @param delistee The address to be removed from the blacklist.
//      */
//     function removeBlacklist(
//         address delistee
//     ) public virtual onlyRole(BLACKLISTER_ROLE) {
//         _removeBlacklist(delistee);
//     }

//     /************************************************
//      *   internal
//      ************************************************/

//     /**
//      * @dev Overrides the _update function to enforce loyalty checks on token transfers, in addition to pausability.
//      * Transactions from or to addresses blacklisted are prevented.
//      * @param from The address sending the tokens.
//      * @param to The address receiving the tokens.
//      * @param value The amount of tokens to transfer.
//      */
//     function _update(
//         address from,
//         address to,
//         uint256 value
//     )
//         internal
//         virtual
//         override
//         whenNotPaused
//         notBlacklisted(from)
//         notBlacklisted(to)
//     {
//         ERC20Upgradeable._update(from, to, value);
//     }

//     /**
//      * @dev Transfers all tokens held by a newly blacklisted address to the caller, typically the blacklister.
//      * This ensures that blacklisted addresses cannot hold or use tokens post-blacklisting. This function
//      * is intended to be called internally, specifically as part of the `addBlacklist` process.
//      * @param blacklistee The address being blacklisted and from which tokens will be transferred away.
//      */
//     function _onceBlacklisted(address blacklistee) internal virtual override {
//         _transfer(blacklistee, _msgSender(), balanceOf(blacklistee));
//     }

//     /************************************************
//      *   support
//      ************************************************/

//     /**
//      * @notice Allows recovery of ERC20 tokens sent to this contract by mistake.
//      * @param token The ERC20 token contract of the tokens to recover.
//      * @param destination The address to which the recovered tokens will be sent.
//      * @param amount The amount of tokens to recover and send to the destination.
//      */
//     function ERC20Recover(
//         IERC20 token,
//         address destination,
//         uint256 amount
//     ) external onlyRole(SUPPORT_ROLE) {
//         _recover(token, destination, amount);
//     }

//     /************************************************
//      *   pause
//      ************************************************/

//     /// @notice Pauses all token transfers.
//     function pause() public onlyRole(PAUSER_ROLE) whenNotPaused {
//         _pause();
//     }

//     /// @notice Unpauses all token transfers.
//     function unpause() public onlyRole(PAUSER_ROLE) whenPaused {
//         _unpause();
//     }
// }
