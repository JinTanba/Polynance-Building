// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VaultStorage} from "../libs/VaultStorage.sol";
import {VaultEE} from "../interfaces/SuperInterface.sol";
import {AaveLibrary} from "../libs/AaveLibs.sol";

/**
 * @title VaultLib
 * @dev Library for user collateral operations and strategy hooks, using Quote structs and Aave for collateral.
 */
library VaultLogic {
    using SafeERC20 for IERC20;

    /// @notice Deposit collateral and supply to Aave
    function depositCollateral(uint256 amount) internal {
        VaultStorage.$ storage v = VaultStorage.$$();
        
        v.collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        // supply to Aave via library
        AaveLibrary.supply(address(v.collateralToken), amount, address(this));
        v.supplyOf[msg.sender] += amount;
        emit VaultEE.CollateralFlow(bytes32(0), VaultEE.Flow.IN_USER, amount);
    }

    /// @notice Withdraw collateral by redeeming from Aave
    function withdrawCollateral(uint256 amount) internal {
        VaultStorage.$ storage v = VaultStorage.$$();
        
        uint256 userBal = v.supplyOf[msg.sender];
        if (userBal < amount) revert VaultEE.CollateralShortfall(bytes32(0), amount, userBal);
        v.supplyOf[msg.sender] = userBal - amount;
        // withdraw underlying via library
        AaveLibrary.withdraw(address(v.collateralToken), amount, msg.sender);
        emit VaultEE.CollateralFlow(bytes32(0), VaultEE.Flow.OUT_USER, amount);
    }

    /// @notice strategy a quote by moving user supply into quote collateral
    function funding(uint256 qid, uint256 amount) internal {
        VaultStorage.$ storage v = VaultStorage.$$();
        
        uint256 userBal = v.supplyOf[msg.sender];
        if (userBal < amount) revert VaultEE.CollateralShortfall(bytes32(qid), amount, userBal);
        v.supplyOf[msg.sender] = userBal - amount;
        VaultStorage.Quote storage quote = v.quote[qid];
        quote.collateral += uint128(amount);
        emit VaultEE.CollateralFlow(bytes32(qid), VaultEE.Flow.IN_AFTER_TRADE, amount);
    }

    /// @notice strategy hook: withdraw collateral from Aave for a given quote
    function lockCollateral(uint256 qid, uint256 amount) internal {
        VaultStorage.$ storage v = VaultStorage.$$();
        
        VaultStorage.Quote storage quote = v.quote[qid];
        uint128 col = quote.collateral;
        if (col < amount) revert VaultEE.CollateralShortfall(bytes32(qid), amount, col);
        quote.collateral = col - uint128(amount);
        // withdraw underlying via library
        AaveLibrary.withdraw(address(v.collateralToken), amount, address(this));
        emit VaultEE.CollateralFlow(bytes32(qid), VaultEE.Flow.IN_AFTER_TRADE, amount);
    }

    /// @notice strategy hook: supply collateral back to Aave for a given quote
    function unlockCollateral(uint256 qid, uint256 amount) internal {
        VaultStorage.$ storage v = VaultStorage.$$();
        
        // supply underlying via library
        AaveLibrary.supply(address(v.collateralToken), amount, address(this));
        VaultStorage.Quote storage quote = v.quote[qid];
        quote.collateral += uint128(amount);
    }
}
