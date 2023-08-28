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

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

///Insufficient funds sent
error Raffle__NotEnoughEthSent();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded(
    uint256 balance,
    uint256 playersLength,
    uint256 raffleState
);

contract Raffle is VRFConsumerBaseV2 {
    /** Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING_WINNER
    }

    /** State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entraceFee;
    //@dev The duration of the raffle in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed _player);
    event WinnerPicked(address indexed _winner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entraceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entraceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev Function that Chainlink automation nodes call
     * to see if its time to perform an upkeep
     * The following should be true for this to return true:
     * 1. The raffle is open
     * 2. The contract has ETH(aka, players have entered)
     * 3. The time interval has passed
     * 4. (implicit) The contract has enough LINK to pay for the upkeep
     */
    function checkUpkeep(
        bytes memory /** checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /** performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timeHasPassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    //1. Get a random number
    //2. Pick a winner using the random number
    //3. Be automatically called
    function performUpkeep(bytes calldata /** performData */) external {
        //Check to see if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING_WINNER;
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 index = randomWords[0] % s_players.length;
        address payable winner = s_players[index];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entraceFee;
    }
}
