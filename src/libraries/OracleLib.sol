// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.4/interfaces/AggregatorV3Interface.sol";

library OracleLib {
    error OracleLib__StalePrice();
    uint256 private constant TIME_OUT = 3 hours;

    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) public view returns(uint80,int256,uint256,uint256,uint80) {
        (uint80 roundId,int256 price,uint256 startedAt,uint256 updatedAt,uint80 answeredInRound) = priceFeed.latestRoundData();
        if ( (block.timestamp - updatedAt) > TIME_OUT ) {
            revert OracleLib__StalePrice();
        }
        return (roundId,price,startedAt,updatedAt,answeredInRound);
    }
}