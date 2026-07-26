// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ABIEncoderDemo
 * @dev A comprehensive demonstration of abi.encodePacked and keccak256 for various DeFi use cases.
 */
contract ABIEncoderDemo {

    /// @notice Thrown when two arrays that should match in length do not.
    error NotSameLengthArray();

    /// @notice Emitted when general data is encoded and hashed.
    /// @param hash The generated keccak256 hash.
    /// @param encodedData The raw packed bytes.
    event DataEncoded(bytes32 indexed hash, bytes encodedData);

    /// @notice Emitted when a unique pool identifier is created.
    /// @param poolId The unique hash for the pool.
    /// @param token The address of a token in the pool.
    /// @param rate The rate or fee tier.
    event PoolIdentifierCreated(bytes32 indexed poolId, address token, uint256 rate);

    /// @notice Emitted when a user's trading position is encoded.
    /// @param positionId The unique identifier of the position.
    /// @param user The address of the user.
    /// @param amount The position amount.
    event UserPositionEncoded(bytes32 indexed positionId, address user, uint256 amount);

    /**
     * @notice Encodes a yield strategy's core parameters.
     * @param strategyName The string name of the strategy.
     * @param pools An array of pool addresses involved in the strategy.
     * @param weights An array of numerical weights corresponding to each pool.
     * @return strategyId The unique keccak256 identifier for this strategy.
     * @return encodedData The raw packed bytes of the strategy.
     */
    function encodeYieldStrategy(
        string calldata strategyName,
        address[] calldata pools,
        uint256[] calldata weights
    ) external pure returns(bytes32 strategyId, bytes memory encodedData) {
        if (pools.length != weights.length) revert NotSameLengthArray();
        
        encodedData = abi.encodePacked(strategyName, pools, weights);
        strategyId = keccak256(encodedData);
    }

    /**
     * @notice Encodes pool parameters to generate a unique deterministic identifier.
     * @dev Token order is sorted to ensure consistent IDs regardless of input order.
     * @param tokenA The first pool token address.
     * @param tokenB The second pool token address.
     * @param fee The fee tier for the pool.
     * @return poolId The generated unique identifier for this specific token pair and fee.
     */
    function createPoolIdentifier(
        address tokenA,
        address tokenB, 
        uint24 fee
    ) external pure returns(bytes32 poolId) {
        // We order the tokens alphabetically/numerically
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // Pack and hash
        poolId = keccak256(abi.encodePacked(token0, token1, fee));
    }

    /**
     * @notice Encodes a trading position and generates a position ID.
     * @param user_ The address of the trader.
     * @param tokenIn_ The token being swapped in.
     * @param tokenOut_ The token being swapped out.
     * @param amountIn The amount of tokenIn.
     * @param minAmountOut The minimum acceptable amount out (slippage protection).
     * @return positionId The generated hash representing the position.
     * @return encodedData The raw packed bytes of the trading data.
     */
    function encodeTradingPosition(
        address user_,
        address tokenIn_,
        address tokenOut_, 
        uint256 amountIn, 
        uint256 minAmountOut
    ) external view returns(bytes32 positionId, bytes memory encodedData) {
        encodedData = abi.encodePacked(user_, tokenIn_, tokenOut_, amountIn, minAmountOut, block.timestamp);
        positionId = keccak256(encodedData);
    }

    /**
     * @notice Encodes pathing data for a multi-hop swap.
     * @param path The array of token addresses in the swap path.
     * @param amounts The corresponding amounts at each step.
     * @param deadline The timestamp after which the swap is invalid.
     * @return swapData The raw packed bytes of the routing data.
     */
    function encodeSwapData(
        address[] calldata path, 
        uint256[] calldata amounts, 
        uint256 deadline
    ) external pure returns (bytes memory swapData) {
        if(path.length != amounts.length) revert NotSameLengthArray();

        bytes memory pathData;
        for(uint i = 0; i < path.length; i++){
            pathData = abi.encodePacked(pathData, path[i]);
        }

        bytes memory amountData;
        for(uint i = 0; i < amounts.length; i++){
            amountData = abi.encodePacked(amountData, amounts[i]);
        } 

        swapData = abi.encodePacked(pathData, amountData, deadline);
    }

    /**
     * @notice Encodes a traditional Limit Order.
     * @param maker_ The creator of the order.
     * @param taker_ The fulfiller of the order (can be zero address).
     * @param tokenIn_ The token being sold.
     * @param tokenOut_ The token being bought.
     * @param amountIn_ The amount being sold.
     * @param amountOut_ The minimum amount expected in return.
     * @param nonce A unique number to prevent replay attacks.
     * @return orderHash The hash of the order.
     * @return orderData The raw packed bytes of the order.
     */
    function encodeLimitOrder(
        address maker_, 
        address taker_, 
        address tokenIn_, 
        address tokenOut_, 
        uint256 amountIn_, 
        uint256 amountOut_, 
        uint256 nonce
    ) external pure returns(bytes32 orderHash, bytes memory orderData) {
        orderData = abi.encodePacked(maker_, taker_, tokenIn_, tokenOut_, amountIn_, amountOut_, nonce, "Limit_OrderV1");
        orderHash = keccak256(orderData);
    }

    /**
     * @notice Encodes a yield farming position.
     * @param user_ The address depositing yield.
     * @param poolId_ The target yield pool ID.
     * @param amount_ The amount deposited.
     * @param startTime_ The timestamp the deposit occurred.
     * @return positionId The hash representing this specific yield position.
     */
    function encodeYieldPosition(
        address user_, 
        bytes32 poolId_, 
        uint256 amount_, 
        uint256 startTime_
    ) external pure returns (bytes32 positionId) {
        positionId = keccak256(abi.encodePacked(user_, poolId_, amount_, startTime_, "Yield_PositionV1"));
    }   

    /**
     * @notice Encodes flash loan execution data.
     * @param token The token being flash loaned.
     * @param amount The amount of the loan.
     * @param callbackData Additional data to pass back to the receiver.
     * @return flashLoanData The packed bytes for the flash loan request.
     */
    function encodeFlashLoanData(
        address token, 
        uint256 amount, 
        bytes calldata callbackData
    ) external pure returns(bytes memory flashLoanData) {
        flashLoanData = abi.encodePacked(token, amount, callbackData, "Flash_LoanV1");
    }

    /**
     * @notice Encodes configurations for setting up a new staking pool.
     * @param token The address of the token being staked.
     * @param rewardRate The emission rate of rewards.
     * @param lockPeriod Time required before stakers can withdraw.
     * @param maxStakers The maximum number of allowed stakers.
     * @return stakingPoolConfig The packed configurations.
     */
    function encodeStakingPoolConfig(
        address token, 
        uint256 rewardRate, 
        uint256 lockPeriod, 
        uint256 maxStakers
    ) external pure returns(bytes memory stakingPoolConfig) {
        stakingPoolConfig = abi.encodePacked(token, rewardRate, lockPeriod, maxStakers, "Staking_Pool_ConfigV1");
    }

    /**
     * @notice Encodes multiple pool positions for a single user using an array.
     * @param user_ The target user.
     * @param poolIds_ An array of pool IDs the user is entering.
     * @return userHash The computed hash representing the user's multi-pool state.
     */
    function createUserMultiPoolPosition(
        address user_,
        bytes32[] calldata poolIds_
    ) external pure returns(bytes32 userHash) {
        bytes memory data = abi.encodePacked(user_);

        for (uint i = 0; i < poolIds_.length; i++){
            data = abi.encodePacked(data, poolIds_[i]);
        }

        data = abi.encodePacked(data, "User_Multi_Pool_PositionV1");
        userHash = keccak256(data);
    }

  
    /**
     * @notice Encodes data for bridging assets across different blockchains.
     * @param sourceChain The ID of the originating blockchain.
     * @param targetChain The ID of the destination blockchain.
     * @param token The token address being bridged.
     * @param amount The amount to bridge.
     * @param recipient The address receiving the bridged tokens on the target chain.
     * @return bridgedData The packed byte format of the bridging instructions.
     */
    function encodeCrossChainBridgedData(
        uint256 sourceChain,
        uint256 targetChain,
        address token,
        uint256 amount,
        address recipient
    ) external pure returns (bytes memory bridgedData) {
        bridgedData = abi.encodePacked(
            sourceChain,
            targetChain,
            token,
            amount,
            recipient,
            "CROSS_CHAIN_BRIDGE"
        );
    }

    /**
     * @notice Encodes data for executing a Stop Loss order.
     * @param user The address of the order creator.
     * @param token The asset being monitored.
     * @param amount The position size to close.
     * @param stopPrice The execution price to stop the loss.
     * @param triggerPrice The exact price at which the order activates.
     * @return stopLossData The packed byte format of the stop loss order.
     */
    function encodeStopLossOrder(
        address user,
        address token,
        uint256 amount,
        uint256 stopPrice,
        uint256 triggerPrice
    ) external pure returns (bytes memory stopLossData) {
        stopLossData = abi.encodePacked(
            user,
            token,
            amount,
            stopPrice,
            triggerPrice,
            "STOP_LOSS_ORDER"
        );
    }

    /**
     * @notice Encodes data for executing a Take Profit order.
     * @param user The address of the order creator.
     * @param token The asset being monitored.
     * @param amount The position size to close.
     * @param takeProfitPrice The price target to secure profit.
     * @return takeProfitData The packed byte format of the take profit order.
     */
    function encodeTakeProfitOrder(
        address user,
        address token,
        uint256 amount,
        uint256 takeProfitPrice
    ) external pure returns (bytes memory takeProfitData) {
        takeProfitData = abi.encodePacked(
            user,
            token,
            amount,
            takeProfitPrice,
            "TAKE_PROFIT_ORDER"
        );
    }

    /**
     * @notice Encodes data for a Trailing Stop Loss order.
     * @param user The address of the order creator.
     * @param token The asset being monitored.
     * @param amount The position size.
     * @param trailingPercent The percentage distance behind the peak price.
     * @param activationPrice The minimum price threshold for the trail to begin.
     * @return trailingStopData The packed byte format of the trailing order.
     */
    function encodeTradingStopOrder(
        address user,
        address token,
        uint256 amount,
        uint256 trailingPercent,
        uint256 activationPrice
    ) external pure returns (bytes memory trailingStopData) {
        trailingStopData = abi.encodePacked(
            user,
            token,
            amount,
            trailingPercent,
            activationPrice,
            "TRAILING_STOP_ORDER"
        );
    }

    /**
     * @notice Generates a unique transaction identifier for general DeFi operations.
     * @param txType A string descriptor of the transaction type.
     * @param user The user initiating the transaction.
     * @param timestamp Time of the execution.
     * @param nonce A unique number to protect against replay vulnerabilities.
     * @return txId The keccak256 hash representing this specific transaction.
     */
    function createDeFiTransactionId(
        string calldata txType,
        address user,
        uint256 timestamp,
        uint256 nonce
    ) external pure returns (bytes32 txId) {
        txId = keccak256(
            abi.encodePacked(
                txType,
                user,
                timestamp,
                nonce,
                "DEFI_TX"
            )
        );
    }
}