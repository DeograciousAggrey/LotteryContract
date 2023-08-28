//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 _entranceFee;
        uint256 _interval;
        address _vrfCoordinator;
        bytes32 _gasLane;
        uint64 _subscriptionId;
        uint32 callbackGasLimit;    
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if(block.chainId == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            _entranceFee: 0.01 ether,
            _interval: 30,
            _vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            _gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            _subscriptionId: 0, //Update this with our subscription id
            callbackGasLimit: 500000
        });

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        if(activeNetworkConfig._vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
    }
            
            

}