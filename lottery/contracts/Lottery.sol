// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2, Ownable {
    address payable[] public players;
    uint256 public usdEntyFee;
    AggregatorV3Interface internal ehtUsdPriceFeed;
    VRFCoordinatorV2Interface COORDINATOR;

    address payable public recentWinner;
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint64 public subId;
    uint16 public minimumRequestConfirmations = 3;
    uint32 public callbackGasLimit = 10000;
    uint32 public numWords = 2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    //these states are represented by numbers 0 1 and 2

    LOTTERY_STATE public lottery_state;

    constructor(
        address _priceFeedAddress,
        uint64 _subId
    )  VRFConsumerBaseV2(vrfCoordinator){
        usdEntyFee = 50 * (10**18);
        ehtUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subId = _subId;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not Enough ETH");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 answer, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = ehtUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(answer) * 10**10; //make it 18 decimals
        uint256 costToEnter = (usdEntyFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // uint256(
        //     keccack256(
        //         abi.encodePacked(
        //             nonce, //is predictable
        //             msg.sender, //is predictable
        //             block.difficulty, //can be manipulated by miners
        //             block.timestamp //is predictable
        //         )
        //     )
        // ) % players.length;

        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            minimumRequestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory _randomWords)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet"
        );
        require(_randomWords.length > 0, "Random not found");
        s_randomWords = _randomWords;
        uint256 random = s_randomWords[0];
        uint256 indexOfWinner = random % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        //Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }
}
