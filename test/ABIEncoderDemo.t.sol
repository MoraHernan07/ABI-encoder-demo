//SPDX-License-Identifier:MIT 

pragma solidity ^0.8.24;
import "forge-std/Test.sol";
import "../src/ABIEnconderDemo.sol";


error notSameLengthArray();

/// @title ABIEncoderDemo 



contract ABIEncoderDemoT is Test {
    ABIEncoderDemo private demo;

    function setUp() external {
        demo = new ABIEncoderDemo();

    }


/// @dev Pool

    function testCreatePoolIdentifier_SafeForBothTokenOrders() external view {
        address tokenA =  address(0x100);
        address tokenB = address(0x200);
        uint24 fee = 3000;


        bytes32 idAB = demo.createPoolIdentifier(tokenA, tokenB, fee);
        bytes32 idBA = demo.createPoolIdentifier(tokenB, tokenA, fee);
        assertEq(idAB , idBA, "Pool identifiers should be the same for both token orders");
    }

    function testCreatePoolIdentifier_ShouldRevert_IfDifferentFees() external view {
        address tokenA =  address(0x100);
        address tokenB = address(0x200);
        uint24 fee1= 3000 ;
        uint24 fee2 = 4000;
        bytes32 idLow = demo.createPoolIdentifier(tokenA, tokenB, fee1);
        bytes32 idHigh = demo.createPoolIdentifier(tokenB, tokenA, fee2);

        assertTrue(idLow != idHigh, "Pool identifiers should be different for different fees");
    }


    function test_Encode_TrendingPosition_ReturnExpectedDataAndHas() external {

        address user = vm.addr(1);
        address tokenIn = address(0x100);
        address tokenOut = address(0x200);
        uint256 amountIn = 1 ether;
        uint256 minAmountOut = 2 ether;

        // Freeze block timestap to a known value 
        uint fixedTs = 1_700_000_000;
        vm.warp(fixedTs);
        (bytes32 positionId, bytes memory encodedData) = demo.encodeTradingPosition(user, tokenIn, tokenOut, amountIn, minAmountOut);


        bytes memory expected = abi.encodePacked(user, tokenIn, tokenOut, amountIn, minAmountOut, fixedTs);
        
        assertEq(encodedData,expected, "Encoded traiding position mismatch");
        assertEq(positionId, keccak256(expected) , "Position id must be keccat of encodedData");

    }

    function testEncodeSwappData() external  view {

        address [] memory path = new address[](3);
        path[0] = address (0x1);
        path[1] = address (0x2);
        path[2] = address (0x3);

        uint256[] memory amounts = new uint256[](3);
        amounts[0]= 10;
        amounts[1]= 15;
        amounts[2]= 20;

        uint256 deadline = 999;

        bytes memory pathData;
        for(uint256 i; i< path.length; i++){
            pathData = abi.encodePacked(pathData,path[i]);
        }

        bytes memory amountsData;

        for(uint256 i; i < amounts.length; i++){
            amountsData = abi.encodePacked(amountsData, amounts[i]);
        }
        bytes memory expected = abi.encodePacked(pathData, amountsData, deadline );
        bytes memory actual = demo.encodeSwapData(path, amounts, deadline);

        assertEq(expected , actual, "SwapDatta Code Not Match");
        
    }


    function testEncodeSwappShouldRevertFor_NoMatch () external {
        address [] memory path = new address[](3);
        path[0] = address (0x1);
        path[1] = address (0x2);


        uint256[] memory amounts = new uint256[](2);
        amounts[0]= 10;


        vm.expectRevert(ABIEncoderDemo.NotSameLengthArray.selector);

        demo.encodeSwapData(path, amounts ,123);

    }
    function testEncodeSwappData_EmptyArrays() external view {
        address[] memory path = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        uint256 deadline = 12345;

        bytes memory expected = abi.encodePacked(deadline);
        bytes memory actual = demo.encodeSwapData(path, amounts, deadline);

        assertEq(actual, expected, "Empty swap data mismatch");
    }

    function testCreateUserMultiPoolPosition_EmptyPoolIds() external view {
        address user = vm.addr(1);
        bytes32[] memory poolIds = new bytes32[](0);

        bytes32 userHash = demo.createUserMultiPoolPosition(user, poolIds);

        bytes memory expected = abi.encodePacked(user, "User_Multi_Pool_PositionV1");

        assertEq(userHash, keccak256(expected), "Empty multi pool position hash mismatch");
    }

    /// @dev Yield Strategy

    function testEncodeYieldStrategy() external view {
        string memory strategyName = "MyYieldStrategy";
        address[] memory pools = new address[](2);
        pools[0] = address(0xA1);
        pools[1] = address(0xB2);

        uint256[] memory weights = new uint256[](2);
        weights[0] = 50;
        weights[1] = 50;

        (bytes32 strategyId, bytes memory encodedData) = demo.encodeYieldStrategy(strategyName, pools, weights);

        bytes memory expected = abi.encodePacked(strategyName, pools, weights);

        assertEq(encodedData, expected, "Yield strategy encoding mismatch");
        assertEq(strategyId, keccak256(expected), "Strategy id must be keccak256 of encodedData");
    }

    function testEncodeYieldStrategy_ShouldRevertIfDifferentLength() external {
        address[] memory pools = new address[](2);
        pools[0] = address(0xA1);
        pools[1] = address(0xB2);

        uint256[] memory weights = new uint256[](1);
        weights[0] = 100;

        vm.expectRevert(ABIEncoderDemo.NotSameLengthArray.selector);
        demo.encodeYieldStrategy("BadStrategy", pools, weights);
    }

    /// @dev Limit Order

    function testEncodeLimitOrder() external view {
        address maker = vm.addr(1);
        address taker = vm.addr(2);
        address tokenIn = address(0x100);
        address tokenOut = address(0x200);
        uint256 amountIn = 1 ether;
        uint256 amountOut = 2 ether;
        uint256 nonce = 1;

        (bytes32 orderHash, bytes memory orderData) =
            demo.encodeLimitOrder(maker, taker, tokenIn, tokenOut, amountIn, amountOut, nonce);

        bytes memory expected = abi.encodePacked(
            maker, taker, tokenIn, tokenOut, amountIn, amountOut, nonce, "Limit_OrderV1"
        );

        assertEq(orderData, expected, "Limit order encoding mismatch");
        assertEq(orderHash, keccak256(expected), "Order hash must be keccak256 of orderData");
    }

    /// @dev Yield Position

    function testEncodeYieldPosition() external view {
        address user = vm.addr(1);
        bytes32 poolId = keccak256("pool1");
        uint256 amount = 5 ether;
        uint256 startTime = block.timestamp;

        bytes32 positionId = demo.encodeYieldPosition(user, poolId, amount, startTime);

        bytes memory expected = abi.encodePacked(user, poolId, amount, startTime, "Yield_PositionV1");

        assertEq(positionId, keccak256(expected), "Yield position id mismatch");
    }

    /// @dev Flash Loan

    function testEncodeFlashLoanData() external view {
        address token = address(0x123);
        uint256 amount = 1000 ether;
        bytes memory callbackData = abi.encode("some callback payload");

        bytes memory flashLoanData = demo.encodeFlashLoanData(token, amount, callbackData);

        bytes memory expected = abi.encodePacked(token, amount, callbackData, "Flash_LoanV1");

        assertEq(flashLoanData, expected, "Flash loan data mismatch");
    }

    /// @dev Staking Pool Config

    function testEncodeStakingPoolConfig() external view {
        address token = address(0x123);
        uint256 rewardRate = 10;
        uint256 lockPeriod = 30 days;
        uint256 maxStakers = 100;

        bytes memory stakingPoolConfig = demo.encodeStakingPoolConfig(token, rewardRate, lockPeriod, maxStakers);

        bytes memory expected = abi.encodePacked(
            token, rewardRate, lockPeriod, maxStakers, "Staking_Pool_ConfigV1"
        );

        assertEq(stakingPoolConfig, expected, "Staking pool config mismatch");
    }

    /// @dev Multi Pool Position

    function testCreateUserMultiPoolPosition() external view {
        address user = vm.addr(1);
        bytes32[] memory poolIds = new bytes32[](3);
        poolIds[0] = keccak256("pool1");
        poolIds[1] = keccak256("pool2");
        poolIds[2] = keccak256("pool3");

        bytes32 userHash = demo.createUserMultiPoolPosition(user, poolIds);

        bytes memory data = abi.encodePacked(user);
        for (uint256 i; i < poolIds.length; i++) {
            data = abi.encodePacked(data, poolIds[i]);
        }
        data = abi.encodePacked(data, "User_Multi_Pool_PositionV1");

        assertEq(userHash, keccak256(data), "Multi pool position hash mismatch");
    }

    /// @dev Cross Chain Bridge

    function testEncodeCrossChainBridgedData() external view {
        uint256 sourceChain = 1;
        uint256 targetChain = 137;
        address token = address(0x123);
        uint256 amount = 500 ether;
        address recipient = vm.addr(1);

        bytes memory bridgedData = demo.encodeCrossChainBridgedData(sourceChain, targetChain, token, amount, recipient);

        bytes memory expected = abi.encodePacked(
            sourceChain, targetChain, token, amount, recipient, "CROSS_CHAIN_BRIDGE"
        );

        assertEq(bridgedData, expected, "Cross chain bridge data mismatch");
    }

    /// @dev Stop Loss

    function testEncodeStopLossOrder() external view {
        address user = vm.addr(1);
        address token = address(0x123);
        uint256 amount = 10 ether;
        uint256 stopPrice = 1800;
        uint256 triggerPrice = 1850;

        bytes memory stopLossData = demo.encodeStopLossOrder(user, token, amount, stopPrice, triggerPrice);

        bytes memory expected = abi.encodePacked(
            user, token, amount, stopPrice, triggerPrice, "STOP_LOSS_ORDER"
        );

        assertEq(stopLossData, expected, "Stop loss data mismatch");
    }

    /// @dev Take Profit

    function testEncodeTakeProfitOrder() external view {
        address user = vm.addr(1);
        address token = address(0x123);
        uint256 amount = 10 ether;
        uint256 takeProfitPrice = 2200;

        bytes memory takeProfitData = demo.encodeTakeProfitOrder(user, token, amount, takeProfitPrice);

        bytes memory expected = abi.encodePacked(
            user, token, amount, takeProfitPrice, "TAKE_PROFIT_ORDER"
        );

        assertEq(takeProfitData, expected, "Take profit data mismatch");
    }

    /// @dev Trailing Stop

    function testEncodeTradingStopOrder() external view {
        address user = vm.addr(1);
        address token = address(0x123);
        uint256 amount = 10 ether;
        uint256 trailingPercent = 5;
        uint256 activationPrice = 2000;

        bytes memory trailingStopData =
            demo.encodeTradingStopOrder(user, token, amount, trailingPercent, activationPrice);

        bytes memory expected = abi.encodePacked(
            user, token, amount, trailingPercent, activationPrice, "TRAILING_STOP_ORDER"
        );

        assertEq(trailingStopData, expected, "Trailing stop data mismatch");
    }

    /// @dev DeFi Transaction Id

    function testCreateDeFiTransactionId() external view {
        string memory txType = "SWAP";
        address user = vm.addr(1);
        uint256 timestamp = block.timestamp;
        uint256 nonce = 42;

        bytes32 txId = demo.createDeFiTransactionId(txType, user, timestamp, nonce);

        bytes memory expected = abi.encodePacked(txType, user, timestamp, nonce, "DEFI_TX");

        assertEq(txId, keccak256(expected), "DeFi transaction id mismatch");
    }




}