// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title A simple raffle contract
 * @author Aggrey
 * @notice Creating a sample raffle contract
 * @dev Implements Chainlink VRF
 */
///Insufficient funds sent
error Raffle__NotEnoughEthSent();

contract Raffle {
    uint256 private immutable i_entraceFee;

    constructor(uint256 _entranceFee) {
        i_entraceFee = _entranceFee;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entraceFee) {
            revert Raffle__NotEnoughEthSent();
        }
    }

    function pickWinner() public {}

    /** Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entraceFee;
    }
}
