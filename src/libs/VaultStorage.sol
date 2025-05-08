// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NonfungiblePredictionManager} from "../vault/NonfungiblePredictionManager.sol";
import {IPoolDataProvider} from "aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPOOL.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesPROVIDER.sol";
import {AaveLibrary} from "../libs/AaveLibs.sol";


/**
 * Shared persistent state for CoreVault and all mix-ins.
 * Access from anywhere via $.$$() once you write
 *
 *   import {VaultStorage as $} from "./VaultStorage.sol";
 *
 * (No “using” needed.)
 */
library VaultStorage {
    /* keccak256("polynance.corevault.storage") - 1 */
    //TODO
    bytes32 internal constant SLOT = 0xccb9ce4c9a3b38bf5d090cdd4a8f94bbf1c0869b3bb0a81f8fc9fb0e9f4b7e61;
    
    enum PositionState { PREVIEWED, OPEN, SETTLING, CLOSED, LIQUIDATED }
    enum QuoteState {OPEN, CLOSE}  // user → share balance

    struct Quote{
        QuoteState status;
        uint128 collateral;
        address owner;
    }

    struct Predict {
        uint256 size;
        bytes32 positionData;
    }

    struct Order {
        bytes32 platform;
        address exchange;
        bytes32 assetHash;
        uint256 amount;
        bool isBuying;
        uint256 minOut;
        bytes data;
    }

    struct $ {
        mapping(uint256 => Quote) quote;
        mapping(uint256 qId=>bytes32[]) positions;
        mapping(address => uint256) supplyOf;
        uint256 quoteCounter;
        uint128 idleCollateral;
        uint128 totalLocked;
        IERC20  collateralToken;
        IERC20 aToken;
        NonfungiblePredictionManager npm;
        bytes32[] platforms;
        mapping(address => bool) approvedstrategy;
        mapping(bytes32=>address) adaptors;
        mapping(address => bool) oparators;
    }

    function $$() internal pure returns ($ storage l) {
        bytes32 slot = SLOT;
        assembly { l.slot := slot }
    }
}
