# ABI Encoder Demo
 
A Solidity project demonstrating `abi.encodePacked` and `keccak256` patterns commonly used across DeFi protocols — deterministic ID generation, order encoding, and cross-chain message packing. Built and tested with [Foundry](https://book.getfoundry.sh/).
 
## Overview
 
`ABIEncoderDemo.sol` is a single contract with a set of `pure`/`view` functions, each showing a different real-world use case for packed encoding:
 
| Function | Purpose |
|---|---|
| `encodeYieldStrategy` | Encodes a named strategy with its pools and weights, returns a deterministic `strategyId` |
| `createPoolIdentifier` | Generates a unique pool ID from two tokens + fee tier; sorts tokens so `(A,B)` and `(B,A)` produce the same ID |
| `encodeTradingPosition` | Encodes a swap position (in/out tokens, amounts) plus `block.timestamp` into a `positionId` |
| `encodeSwapData` | Packs a multi-hop swap path, amounts, and deadline into routing data |
| `encodeLimitOrder` | Encodes a maker/taker limit order with a replay-protection nonce |
| `encodeYieldPosition` | Encodes a yield-farming deposit (user, pool, amount, start time) |
| `encodeFlashLoanData` | Packs flash loan parameters plus arbitrary callback data |
| `encodeStakingPoolConfig` | Encodes staking pool setup parameters (rate, lock period, max stakers) |
| `createUserMultiPoolPosition` | Hashes a user's participation across an arbitrary number of pools |
| `encodeCrossChainBridgedData` | Packs bridging instructions (source/target chain, token, amount, recipient) |
| `encodeStopLossOrder` | Encodes a stop-loss order (trigger price, stop price) |
| `encodeTakeProfitOrder` | Encodes a take-profit order |
| `encodeTradingStopOrder` | Encodes a trailing-stop order (percent + activation price) |
| `createDeFiTransactionId` | Generates a generic transaction ID for any typed DeFi action |
 
All functions revert with a custom `NotSameLengthArray` error where mismatched array inputs would otherwise produce silently malformed packed data.
 
## Project Structure
 
```
.
├── src/
│   └── ABIEncoderDemo.sol       # Main contract
├── test/
│   └── ABIEncoderDemo.t.sol     # Foundry test suite
├── lib/                         # Dependencies (forge-std)
├── foundry.toml                 # Foundry configuration
└── foundry.lock
```
 
## Requirements
 
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, cast, anvil)
## Usage
 
### Build
 
```shell
forge build
```
 
### Test
 
```shell
forge test
```
 
### Test with verbose output
 
```shell
forge test -vvv
```
 
### Coverage
 
```shell
forge coverage
```
 
The test suite covers every encoding function with both example-based assertions (comparing the contract's output against an independently rebuilt `abi.encodePacked(...)` value) and edge cases — empty-array inputs for the looped functions (`encodeSwapData`, `createUserMultiPoolPosition`) and revert paths for the length-mismatch guards.
 
### Format
 
```shell
forge fmt
```
 
## Notes on Design
 
- **`createPoolIdentifier`** sorts the two token addresses before packing, so the pool ID is the same regardless of the order tokens are passed in — mirroring how Uniswap-style pool addressing works.
- Most functions append a short string suffix (e.g. `"Limit_OrderV1"`, `"STOP_LOSS_ORDER"`) to the packed data before hashing. This namespaces the hash to that specific encoding scheme, reducing the chance of hash collisions between different data structures that might otherwise pack to the same bytes.
- `encodeTradingPosition` incorporates `block.timestamp`, making each position ID naturally unique per block even for otherwise identical trade parameters.
## License
 
MIT
 
