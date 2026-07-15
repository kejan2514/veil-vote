// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {VeilVote} from "../src/VeilVote.sol";

contract DeployVeilVote is Script {
    function run() external returns (VeilVote deployed) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256 start = block.timestamp + 10 minutes;
        uint256 end = start + 7 days;

        vm.startBroadcast(deployerKey);
        deployed = new VeilVote("Should the DAO fund public goods?", start, end);
        vm.stopBroadcast();
    }
}

