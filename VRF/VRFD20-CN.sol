// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.4.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.4.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// 使用随机数模拟掷20面骰子的Chainlink VRF消费者合约
contract VRFD20 is VRFConsumerBaseV2Plus {
    // 表示骰子正在掷的状态
    uint256 private constant ROLL_IN_PROGRESS = 42;

    // 你的订阅ID
    uint256 public s_subscriptionId;

    ///arbitrum-sepolia 网络的 VRF 协调者地址
    address public vrfCoordinator = 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61;

    // 使用的gas通道，指定最大gas价格
    bytes32 public s_keyHash =
        0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be;

    // 回调函数的gas限制，存储每个随机数约需20000 gas
    uint32 public callbackGasLimit = 40000;

    // 请求确认数，默认为3
    uint16 public requestConfirmations = 3;

    // 请求的随机数数量，最大不超过 VRFCoordinatorV2_5.MAX_NUM_WORDS
    uint32 public numWords = 1;

    // 映射：请求ID到掷骰者地址
    mapping(uint256 => address) private s_rollers;
    // 映射：掷骰者地址到VRF结果
    mapping(address => uint256) private s_results;

    // 事件：骰子已掷出
    event DiceRolled(uint256 indexed requestId, address indexed roller);
    // 事件：骰子结果已返回
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);

    // 构造函数，继承VRFConsumerBaseV2Plus
    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
    }

    // 请求随机数，模拟掷骰子
    function rollDice(
        address roller
    ) public onlyOwner returns (uint256 requestId) {
        // 确保未掷过骰子
        require(s_results[roller] == 0, "Already rolled");
        // 请求随机数
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_rollers[requestId] = roller;
        s_results[roller] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, roller);
    }

    // VRF协调者回调函数，返回随机数
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // 计算20面骰子结果
        uint256 d20Value = (randomWords[0] % 20) + 1;
        s_results[s_rollers[requestId]] = d20Value;
        emit DiceLanded(requestId, d20Value);
    }

    // 获取玩家的家族名称
    function house(address player) public view returns (string memory) {
        // 确保已掷骰子
        require(s_results[player] != 0, "Dice not rolled");
        // 确保掷骰完成
        require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");
        return _getHouseName(s_results[player]);
    }

    // 根据ID获取家族名称
    function _getHouseName(uint256 id) private pure returns (string memory) {
        string[20] memory houseNames = [
            "Targaryen",
            "Lannister",
            "Stark",
            "Tyrell",
            "Baratheon",
            "Martell",
            "Tully",
            "Bolton",
            "Greyjoy",
            "Arryn",
            "Frey",
            "Mormont",
            "Tarley",
            "Dayne",
            "Umber",
            "Valeryon",
            "Manderly",
            "Clegane",
            "Glover",
            "Karstark"
        ];
        return houseNames[id - 1];
    }
}
