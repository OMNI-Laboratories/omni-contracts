// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {ERC20PermitUpgradeable, ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

/**
 * @title ERC20Base
 * @author Amir Shirif
 * @notice An OMNI Laboratories Contract
 *
 * @notice Basic ERC20 token meant for proxy implementation.
 */
contract ERC20Base is ERC20PermitUpgradeable {
    /// @custom:storage-location erc7201:omni.storage.ERC20Base
    struct ERC20BaseStorage {
        uint8 _decimals;
    }

    // keccak256(abi.encode(uint256(keccak256("omni.storage.ERC20Base")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20BaseStorageLocation =
        0x09b797f9144cfabab62f3ce877abc640fb745cbe8de9498018c707a0815d7a00;

    /************************************************
     *   initializer
     ************************************************/

    /**
     * @notice Initializes the ERC20Base contract with necessary parameters.
     * @param name The name of the ERC20 token.
     * @param symbol The symbol of the ERC20 token.
     * @param decimal The number of decimal places for the ERC20 token.
     * @param initialMint The amount of tokens to mint upon initialization, scaled by the token's decimals.
     */
    function erc20Base_init(
        string memory name,
        string memory symbol,
        uint8 decimal,
        uint256 initialMint
    ) external initializer {
        __ERC20Base_init(name, symbol, decimal, initialMint);
    }

    /// @dev Internal function to chain initialization calls for setting up the contract.
    function __ERC20Base_init(
        string memory name,
        string memory symbol,
        uint8 decimal,
        uint256 initialMint
    ) internal onlyInitializing {
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        __ERC20Base_init_unchained(decimal);
        _mint(_msgSender(), initialMint * (10 ** uint256(decimals())));
    }

    /// @dev Separate internal function for unchained initializations, specifically for setting decimals.
    function __ERC20Base_init_unchained(
        uint8 decimals_
    ) internal onlyInitializing {
        ERC20BaseStorage storage $ = _getERC20BaseStorage();
        $._decimals = decimals_;
    }

    /************************************************
     *   ERC20 functions
     ************************************************/

    /**
     * @notice Returns the number of decimal places of the token.
     * @return The number of decimal places for this token.
     */
    function decimals() public view virtual override returns (uint8) {
        ERC20BaseStorage storage $ = _getERC20BaseStorage();
        return $._decimals;
    }

    /************************************************
     *   storage fuctions
     ************************************************/

    /**
     * @dev Retrieves the storage location of contract
     * @return $ ERC20Base storage pointer to the ERC20Base storage structure
     */
    function _getERC20BaseStorage()
        private
        pure
        returns (ERC20BaseStorage storage $)
    {
        assembly {
            $.slot := ERC20BaseStorageLocation
        }
    }
}
