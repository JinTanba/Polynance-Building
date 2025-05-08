// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
library VaultEE {

    enum PositionState {OPEN, CLOSE}
    enum QuoteState {OPEN, CLOSE}
    enum Flow { IN_USER, OUT_STRAT, IN_AFTER_TRADE, OUT_USER }
    event CollateralFlow(bytes32 indexed posKey, Flow t, uint256 amt);
    event PositionStateChange(bytes32 indexed posKey, PositionState to);
    event QuoteStateChanged(uint256 qId, QuoteState qs);
    error NotApprovedStrategy(address strat);
    error CollateralShortfall(bytes32 posKey, uint256 needed, uint256 available);
    error VaultPaused();
    error AdaptorCallFailed(address adaptor);
    error NotOperator();
}
