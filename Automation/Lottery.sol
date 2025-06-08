// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Lottery is AutomationCompatibleInterface {
    // 抽奖状态
    enum LotteryState {
        OPEN,
        CLOSED
    }

    // 抽奖结构体
    struct LotteryRound {
        uint256 roundId; // 轮次 ID
        uint256 startTime; // 开始时间
        uint256 minParticipants; // 最小参与人数
        uint256 entryFee; // 参与费用
        address[] participants; // 参与者列表
        address winner; // 获胜者
        LotteryState state; // 轮次状态
    }

    // 抽奖轮次列表
    LotteryRound[] public rounds;

    // 当前轮次
    uint256 public currentRoundId;

    // 抽奖间隔（秒）
    uint256 public immutable interval;

    // 事件
    event RoundStarted(
        uint256 indexed roundId,
        uint256 startTime,
        uint256 minParticipants,
        uint256 entryFee
    );
    event Participated(uint256 indexed roundId, address participant);
    event RoundEnded(uint256 indexed roundId, address winner, uint256 prize);

    constructor(
        uint256 _interval,
        uint256 _minParticipants,
        uint256 _entryFee
    ) {
        interval = _interval;
        currentRoundId = 0;

        // 创建第一轮抽奖
        rounds.push(
            LotteryRound({
                roundId: currentRoundId,
                startTime: block.timestamp,
                minParticipants: _minParticipants,
                entryFee: _entryFee,
                participants: new address[](0),
                winner: address(0),
                state: LotteryState.OPEN
            })
        );

        emit RoundStarted(
            currentRoundId,
            block.timestamp,
            _minParticipants,
            _entryFee
        );
    }

    // 用户参与抽奖
    function participate() external payable {
        LotteryRound storage round = rounds[currentRoundId];
        require(round.state == LotteryState.OPEN, "Lottery round is closed");
        require(msg.value == round.entryFee, "Incorrect entry fee");

        round.participants.push(msg.sender);
        emit Participated(currentRoundId, msg.sender);
    }

    // 检查是否需要结束当前轮次并触发抽奖
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        LotteryRound memory round = rounds[currentRoundId];
        if (round.state == LotteryState.OPEN) {
            // 检查是否满足时间间隔或最小参与人数
            bool timeElapsed = (block.timestamp - round.startTime) >= interval;
            bool enoughParticipants = round.participants.length >=
                round.minParticipants;
            upkeepNeeded = timeElapsed || enoughParticipants;
            if (upkeepNeeded) {
                performData = abi.encode(currentRoundId);
            }
        }
        return (upkeepNeeded, performData);
    }

    // 执行抽奖并结束当前轮次
    function performUpkeep(bytes calldata performData) external override {
        uint256 roundId = abi.decode(performData, (uint256));
        LotteryRound storage round = rounds[roundId];
        require(
            round.state == LotteryState.OPEN,
            "Lottery round already closed"
        );

        // 验证触发条件
        bool timeElapsed = (block.timestamp - round.startTime) >= interval;
        bool enoughParticipants = round.participants.length >=
            round.minParticipants;
        require(timeElapsed || enoughParticipants, "Conditions not met");

        // 关闭当前轮次
        round.state = LotteryState.CLOSED;

        // 如果有参与者，选择获胜者
        if (round.participants.length > 0) {
            // 使用区块哈希和时间戳生成伪随机数
            uint256 random = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp
                    )
                )
            );
            uint256 winnerIndex = random % round.participants.length;
            round.winner = round.participants[winnerIndex];

            // 发放奖金（奖池为所有参与者的费用）
            uint256 prize = round.entryFee * round.participants.length;
            (bool success, ) = round.winner.call{value: prize}("");
            require(success, "Prize transfer failed");

            emit RoundEnded(roundId, round.winner, prize);
        }

        // 开启新轮次
        currentRoundId++;
        rounds.push(
            LotteryRound({
                roundId: currentRoundId,
                startTime: block.timestamp,
                minParticipants: round.minParticipants,
                entryFee: round.entryFee,
                participants: new address[](0),
                winner: address(0),
                state: LotteryState.OPEN
            })
        );

        emit RoundStarted(
            currentRoundId,
            block.timestamp,
            round.minParticipants,
            round.entryFee
        );
    }

    // 获取当前轮次信息
    function getCurrentRound() public view returns (LotteryRound memory) {
        return rounds[currentRoundId];
    }

    // 获取指定轮次信息
    function getRound(
        uint256 _roundId
    ) public view returns (LotteryRound memory) {
        return rounds[_roundId];
    }
}
