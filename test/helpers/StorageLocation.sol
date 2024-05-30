// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract StorageLocation {
    function getERC7201StorageLocation(
        string memory location
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(uint256(keccak256(bytes(location))) - 1)) &
            ~bytes32(uint256(0xff));
    }
}
