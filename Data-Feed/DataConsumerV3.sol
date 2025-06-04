// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DataConsumerV3 {
    AggregatorV3Interface internal dataFeed;

    /**
     * Network:  Arbitrum Sepolia
     * Aggregator: ETH/USD
     * Address: 0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165
     */
    constructor() {
        dataFeed = AggregatorV3Interface(
            0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165
        );
    }

    /**
     * 获取价格，取最后一个值
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // 这里我们只取一个返回的参数
        (
            ,
            /* uint80 roundId */ int256 answer /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = dataFeed.latestRoundData();
        return answer;
    }

    // 获取价格的小数位数
    function getDecimals() public view returns (uint8) {
        return dataFeed.decimals();
    }
}
