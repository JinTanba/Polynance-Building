// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


interface ICTFIndexFactory {
    event IndexCreated(
        address indexed index,
        bytes32 indexed bundleHash,
        uint256[] ids,
        bytes metadata,
        string name,
        string symbol
    );

    function createIndex(
        uint256[] calldata ids,
        bytes32[] calldata conditionIds,
        bytes calldata metadata
    ) external returns (address index);

    function predictIndexAddress(
        uint256[] calldata ids,
        bytes32[] calldata conditionIds,
        bytes calldata metadata
    ) external view returns (address predicted);

    /// Validate & dedupe positions by condition
    function validateInput(
        uint256[] calldata ids,
        bytes32[] calldata conditionIds
    ) external view returns (uint256[] memory filteredIds);
}

interface ICTFIndex {
    event Converted(
        uint256 posId,
        uint256 collateralTokenIn,
        address indexed caller
    );
    event MintingFrozen();

    function getIds() external view returns (uint256[] memory);
    function getMetadata() external view returns (bytes memory);
    function isFullySettled() external view returns (bool);
    function previewBurn(
        uint256 bundleAmount
    ) external view returns (
        uint256 collateralTokenOut,
        uint256[] memory ids,
        uint256[] memory posOut
    );

    function mint(uint256 amount) external;
    function burn(uint256 amount) external;

    /// Redeem resolved positions via CTF.redeemPositions
    function convert(
        bytes32[] calldata conditionIds,
        uint256[] calldata indexSets
    ) external;
    function isPaid(uint256 id) external view returns (bool);
}

