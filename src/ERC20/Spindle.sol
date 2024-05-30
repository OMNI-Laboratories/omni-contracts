// // SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity ^0.8.25;

// import {ERC20WrapperUpgradeable, ERC20Upgradeable, IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
// import {ERC20Compliant, ERC20Base} from "../ERC20/ERC20Compliant.sol";

// /**
//  * @title Spindle
//  * @author Amir Shirif
//  * @notice TODO
//  */
// contract Spindle is ERC20WrapperUpgradeable, ERC20Compliant {
//     /************************************************
//      *   initializer
//      ************************************************/

//     /**
//      * @notice Initializes the Spindle contract with an underlying token and sets its name and symbol.
//      * The decimals are inherited from the underlying token.
//      * This function is callable only once due to the initializer modifier.
//      *
//      * @param underlyingToken The ERC20 token that Spindle will wrap.
//      * @param name The name of the Spindle token.
//      * @param symbol The symbol of the Spindle token.
//      */
//     function initialize(
//         IERC20 underlyingToken,
//         string memory name,
//         string memory symbol
//     ) external initializer {
//         _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
//         __ERC20Wrapper_init(underlyingToken);
//         __ERC20Base_init(name, symbol, decimals(), 0);
//     }

//     /************************************************
//      *   ERC20
//      ************************************************/

//     function decimals()
//         public
//         view
//         override(ERC20Base, ERC20WrapperUpgradeable)
//         returns (uint8)
//     {
//         return ERC20WrapperUpgradeable.decimals();
//     }

//     /************************************************
//      *   internal
//      ************************************************/

//     /**
//      * @dev Overrides the internal token transfer update logic from both ERC20Compliant and ERC20Upgradeable
//      * to enforce compliance checks and integrate with the token wrapping functionality.
//      * This ensures that all transfers adhere to the compliance rules (e.g., blacklist checks) and the token's
//      * wrapped nature.
//      *
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
//         override(ERC20Compliant, ERC20Upgradeable)
//         whenNotPaused
//         notBlacklisted(from)
//         notBlacklisted(to)
//     {
//         ERC20Compliant._update(from, to, value);
//     }
// }
