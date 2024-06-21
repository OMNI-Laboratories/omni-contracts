// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Treason} from "../../../src/utils/access/Treason.sol";

contract MockTreason is Treason {
    function onlyLoyal(address auth) public loyal(auth, msg.sender) {}
}
