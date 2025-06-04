// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract LendingProtocol {
    IERC20 public USDC;
    AggregatorV3Interface internal priceFeed;
    // 用户的 ETH 抵押余额
    mapping(address => uint256) public ethCollateral;
    // 用户的 USDC 借出余额
    mapping(address => uint256) public usdcBorrowed;
    // 贷款价值比 50%
    uint256 public constant LTV_RATIO = 50;
    // 模拟 USDC 的 6 位小数
    uint256 public constant USDC_DECIMALS = 6;
    // ETH 的 18 位小数
    uint256 public constant ETH_DECIMALS = 18;
    // Chainlink 价格的 8 位小数
    uint256 public constant PRICE_DECIMALS = 8;

    constructor(address usdcAddress) {
        // Arbitrum Sepolia  ETH/USD
        priceFeed = AggregatorV3Interface(
            0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165
        );
        // 初始化 USDC 合约
        USDC = IERC20(usdcAddress);
    }

    // 存入 ETH 作为抵押品
    function depositCollateral() external payable {
        require(msg.value > 0, "Must deposit ETH");
        ethCollateral[msg.sender] += msg.value;
    }

    // 获取最新的 ETH/USD 价格
    function getLatestPrice() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

    // 计算用户抵押品价值,算出值多少个U
    function getCollateralValue(address user) public view returns (uint256) {
        uint256 ethAmount = ethCollateral[user];
        uint256 price = getLatestPrice();
        // 计算公式：(ETH 数量 * 价格) / 10^ETH_DECIMALS * 10^USDC_DECIMALS / 10^PRICE_DECIMALS
        return
            (ethAmount * price * 10 ** USDC_DECIMALS) /
            (10 ** ETH_DECIMALS * 10 ** PRICE_DECIMALS);
    }

    // 获取用户最大可借 USDC 金额
    function getMaxBorrowAmount(address user) public view returns (uint256) {
        uint256 collateralValue = getCollateralValue(user);
        // 最大可借 = 抵押品价值 * 50%
        uint256 maxBorrow = (collateralValue * LTV_RATIO) / 100;
        uint256 alreadyBorrowed = usdcBorrowed[user];
        // 剩余可借金额
        if (maxBorrow > alreadyBorrowed) {
            return maxBorrow - alreadyBorrowed;
        }
        return 0;
    }

    // 借出 USDC
    function borrowUSDC(uint256 amount) external {
        require(amount > 0, "Borrow amount must be greater than 0");
        require(
            USDC.balanceOf(address(this)) >= amount,
            "Insufficient USDC in contract"
        );
        uint256 maxBorrow = getMaxBorrowAmount(msg.sender);
        require(amount <= maxBorrow, "Exceeds max borrow amount");
        usdcBorrowed[msg.sender] += amount;
        bool success = USDC.transfer(msg.sender, amount);
        require(success, "USDC transfer failed");
    }

    // 查询用户状态
    function getUserStatus(
        address user
    )
        external
        view
        returns (
            uint256 collateral,
            uint256 collateralValue,
            uint256 borrowed,
            uint256 maxBorrow
        )
    {
        // ETH 余额
        collateral = ethCollateral[user];
        // 抵押品价值
        collateralValue = getCollateralValue(user);
        // 已借 USDC
        borrowed = usdcBorrowed[user];
        // 最大可借 USDC
        maxBorrow = getMaxBorrowAmount(user);
    }
}
