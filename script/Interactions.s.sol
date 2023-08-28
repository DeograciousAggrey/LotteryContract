//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address _vrfCoordinator, , , , ) = helperConfig
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

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address _vrfCoordinator,
            ,
            uint64 _subscriptionId,
            ,
            address link
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(_vrfCoordinator, _subscriptionId, link);
    }

    function fundSubscription(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        address link
    ) public {
        console.log("Funding subscription %s :", _subscriptionId);
        console.log("Using vrfCoordinator %s :", _vrfCoordinator);
        console.log("On ChainId %s :", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(
                _subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                _vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(_subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address _raffle,
        address _vrfCoordinator,
        uint64 _subscriptionId
    ) public {
        console.log("Adding consumer to raffle %s :", _raffle);
        console.log("Using vrfCoordinator %s :", _vrfCoordinator);
        console.log("On ChainId %s :", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(
            _subscriptionId,
            _raffle
        );
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address _raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address _vrfCoordinator,
            ,
            uint64 _subscriptionId,
            ,

        ) = helperConfig.activeNetworkConfig();
        addConsumer(_raffle, _vrfCoordinator, _subscriptionId);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}
