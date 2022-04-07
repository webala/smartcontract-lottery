// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    address payable[] public players;
    uint256 public usdEntyFee;
    AggregatorV3Interface internal ehtUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    //these states are represented by numbers 0 1 and 2

    LOTTERY_STATE public lottery_state;

    constructor(address _priceFeedAddress) public {
        usdEntyFee = 50 * (10**18);
        ehtUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not Enough ETH");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/
            ,
            ,

        ) = /*uint80 answeredInRound*/
            ehtUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //make it 18 decimals
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

    function endLottery() public {}
}
