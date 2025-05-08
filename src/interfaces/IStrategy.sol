// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IStrategy {
    /// User-facing entry (e.g., open market-long)
    function openPosition(
        address exchange,
        address marketToken,
        uint256 outcomeId,
        uint128 notionalUSDC,
        bytes memory extraParams
    ) external;

    function rebalance(bytes32 posKey, bytes calldata data) external;
    function liquidate(bytes32 posKey) external;
    function settle(bytes32 posKey, bytes calldata oracleProof) external;
}

