// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/**
 * @title ProxyFactory
 * @author Amir Shirif
 * @notice An OMNI Laboratories Contract
 *
 * @notice Allows for the creation of a specific implementaiton all referring to the same beacon.
 *
 */
contract ProxyFactory is AccessManagedUpgradeable, IBeacon {
    /// @custom:storage-location erc7201:omni.storage.ProxyFactory
    struct ProxyFactoryStorage {
        address _implementation;
    }

    // keccak256(abi.encode(uint256(keccak256("omni.storage.ProxyFactory")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ProxyFactoryStorageLocation =
        0x441b1ca449da086a3e80193f0f5a2fa2685ab2aa0650fabf0dca26bc1d17e200;

    /**
     * @dev The `implementation` of the beacon is invalid.
     */
    error InvalidImplementation(address implementation);

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event UpgradedImplementation(address indexed implementation);

    /**
     * @dev Emitted when the proxy is created.
     */
    event Deployed(address indexed proxy, bytes32 indexed salt);

    /************************************************
     *   initializer
     ************************************************/

    function initialize(
        address initialAuthority,
        address implementation_
    ) external initializer {
        __AccessManaged_init(initialAuthority);
        _setImplementation(implementation_);
    }

    /************************************************
     *   beacon functions
     ************************************************/

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual returns (address) {
        return _getImplementation();
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     * @param newImplementation contract for new implementation
     *
     * Emits an {Upgraded} event.
     *
     */
    function upgradeTo(address newImplementation) public restricted {
        if (newImplementation.code.length == 0) {
            revert InvalidImplementation(newImplementation);
        }
        _setImplementation(newImplementation);
        emit UpgradedImplementation(newImplementation);
    }

    /************************************************
     *   factory functions
     ************************************************/

    /**
     * @notice Creates new proxy instances with deterministic addresses using provided salts and initialization data.
     * @param salts An array of `bytes32` salts that are used to generate deterministic addresses for each new proxy.
     * @param data An array of `bytes` data that encodes the initialization parameters for each proxy.
     * @dev This function uses the `Create2.deploy` method to ensure that each proxy's address can be pre-computed
     *      and that proxies are deployed with the correct initialization data. The salts and data arrays must be
     *      of the same length, as each salt corresponds to a set of initialization data in the data array.
     *      The method also emits a `Deployed` event for each new proxy created.
     */
    function create(
        bytes32[] memory salts,
        bytes[] memory data
    ) external restricted {
        require(
            salts.length == data.length,
            "ProxyFactory: array length mismatch"
        );

        for (uint256 i; i < salts.length; i++) {
            address newProxy = Create2.deploy(
                0,
                salts[i],
                abi.encodePacked(
                    type(BeaconProxy).creationCode,
                    abi.encode(address(this), data[i])
                )
            );
            emit Deployed(newProxy, salts[i]);
        }
    }

    /************************************************
     *   private functions
     ************************************************/

    /**
     * @dev Retrieves the storage location of the ProxyFactory contract
     * @return $ ProxyFactoryStorage storage pointer to the ProxyFactory storage structure.
     */
    function _getProxyFactoryStorage()
        private
        pure
        returns (ProxyFactoryStorage storage $)
    {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := ProxyFactoryStorageLocation
        }
    }

    /// @dev private function to set the new implementation
    function _getImplementation() private view returns (address) {
        ProxyFactoryStorage storage $ = _getProxyFactoryStorage();
        return $._implementation;
    }

    /// @dev private function to set the new implementation
    function _setImplementation(address newImplementation) private {
        ProxyFactoryStorage storage $ = _getProxyFactoryStorage();
        $._implementation = newImplementation;
    }
}
