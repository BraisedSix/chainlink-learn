// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Counter is AutomationCompatibleInterface {
    uint public counter; // 计数器
    uint public immutable interval; // 时间间隔（秒）
    uint public lastTimeStamp; // 上次执行时间

    constructor(uint _interval) {
        interval = _interval;
        lastTimeStamp = block.timestamp;
        counter = 0;
    }

    // 检查是否需要执行 Upkeep
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // 不使用 performData，仅返回空字节, 因为这里用不上
    }

    // 执行 Upkeep，增加计数器
    function performUpkeep(bytes calldata /* performData */) external override {
        // 重新验证时间间隔，确保链上条件一致
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
        }
    }

    // 获取当前计数器值
    function getCounter() public view returns (uint) {
        return counter;
    }
}
