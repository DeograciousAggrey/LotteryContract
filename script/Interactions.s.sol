//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address _vrfCoordinator, , , ) = helperConfig
            .activeNetworkConfig();
        return createSubscription(_vrfCoordinator);
    }

    function createSubscription(
        address _vrfCoordinator
    ) public returns (uint64) {
        console.log("Creating subscription on chainid: %s", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with id: %s", subId);
        console.log("Please update your HelperConfig with this id");
        return subId;
    }

    function run() external returns (uint64) {
        return CreateSubscriptionUsingConfig();
    }
}