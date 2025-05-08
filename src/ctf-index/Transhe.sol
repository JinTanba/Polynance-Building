// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPolyTrancheFactory {//PT/YT change every thing i guess

    event TrancheCreated(
        bytes32 indexed trancheId,
        address principalToken,
        address yieldToken,
        address indexed underlying,
        uint256 maturity
    );

    function createTranche(address underlying, uint256 maturity)
        external
        returns (address principalToken, address yieldToken);//pt, yt

    function getTrancheTokens(bytes32 trancheId)
        external
        view
        returns (address principalToken, address yieldToken);

    function computeTrancheId(address underlying, uint256 maturity)
        external
        pure
        returns (bytes32 trancheId);
}
