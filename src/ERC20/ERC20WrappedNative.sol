// // SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity ^0.8.25;

// import {ERC20Compliant, ERC20Base} from "./ERC20Compliant.sol";

// /**
//  * @title WrappedNative
//  * @dev This contract implements a wrapped version of the native blockchain currency (e.g., ETH on Ethereum),
//  * allowing it to be used as an ERC20 token. This enables the native currency to interact with decentralized
//  * applications (DApps) and contracts expecting ERC20 tokens. Inherits functionalities from ERC20Compliant
//  * for compliance and additional features such as pausing, blacklisting, and ERC20 token recovery.
//  */
// contract WrappedNative is ERC20Compliant {
//     /************************************************
//      *   initializer
//      ************************************************/

//     /**
//      * @notice Initializes the wrapped token with a name, symbol, and sets decimals to 18.
//      * This function is callable only once due to the initializer modifier.
//      * @param name The name of the wrapped token.
//      * @param symbol The symbol of the wrapped token.
//      */
//     function initialize(
//         string memory name,
//         string memory symbol
//     ) external initializer {
//         __ERC20Base_init(name, symbol, 18, 0);
//     }

//     /************************************************
//      *   total supply
//      ************************************************/

//     /**
//      * @notice Deposits native currency into the contract in exchange for an equivalent amount
//      * of wrapped tokens, minted to the caller's address.
//      */
//     function deposit() public payable {
//         _mint(_msgSender(), msg.value);
//     }

//     /**
//      * @notice Allows the deposit of native currency to a specific recipient address, minting
//      * and transferring the equivalent amount of wrapped tokens to that address.
//      * @param recipient The address to receive the minted wrapped tokens.
//      */
//     function depositTo(address recipient) public payable {
//         _mint(recipient, msg.value);
//     }

//     /**
//      * @notice Withdraws a specified amount of native currency by burning the equivalent amount
//      * of wrapped tokens from the caller's balance. Reverts if the native currency transfer fails.
//      * @param amount The amount of wrapped tokens to burn in exchange for native currency.
//      */
//     function withdraw(uint256 amount) public {
//         _burn(_msgSender(), amount);
//         (bool sent, ) = payable(_msgSender()).call{value: amount}("");
//         require(sent, "WrappedNative: Native send failure");
//     }

//     /**
//      * @notice Withdraws native currency to a specified recipient by burning the equivalent amount
//      * of wrapped tokens from the caller's balance. Checks that the recipient is not blacklisted
//      * before proceeding. Reverts if the native currency transfer fails.
//      * @param recipient The address to receive the native currency.
//      * @param amount The amount of wrapped tokens to burn in exchange for native currency.
//      */
//     function withdrawTo(
//         address recipient,
//         uint256 amount
//     ) public notBlacklisted(recipient) {
//         _burn(_msgSender(), amount);
//         (bool sent, ) = payable(recipient).call{value: amount}("");
//         require(sent, "WrappedNative: Native send failure");
//     }

//     /************************************************
//      *   fallback
//      ************************************************/

//     ///@dev Allows the contract to receive native currency directly and triggers the deposit function.
//     receive() external payable {
//         deposit();
//     }
// }
