
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/* ─────────────────────  0. PositionKey  ───────────────────── */
library PositionKeyLib {

    function positionCountKey(
        address exchange,
        bytes32 assetHash
    ) internal pure returns(bytes32) {
        //how mant position in vault
        return keccak256(abi.encodePacked(exchange, assetHash));
    }

    /// @notice Unique key for {exchange, hash, owner}
    function poskey(
        address exchange,
        bytes32 assetHash,
        uint256 idx
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(exchange, assetHash, idx));
    }
}
