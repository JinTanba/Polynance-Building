// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPOOL.sol";
import {IPoolDataProvider} from "aave-v3-core/contracts/interfaces/IPoolDataPROVIDER.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesPROVIDER.sol";



/// @title AaveLibrary
/// @notice Reusable helper library for Aave v3: supply, withdraw, borrow, repay, flash loans, and account stats
library AaveLibrary {
    using SafeERC20 for IERC20;

    uint16 private constant REFERRAL_CODE = 0;
    uint256 private constant MAX_UINT = type(uint256).max;
    uint256 private constant RAY = 1e27;
    IPoolAddressesProvider constant POOL_ADDRESSES_PROVIDER = IPoolAddressesProvider(0xe20fCBdBfFC4Dd138cE8b2E6FBb6CB49777ad64D);
    IPoolDataProvider constant AAVE_PROTOCOL_DATA_PROVIDER = IPoolDataProvider(0xC4Fcf9893072d61Cc2899C0054877Cb752587981);
    IPool constant POOL = IPool(0xA238Dd80C259a72e81d7e4664a9801593F98d1c5);

    /// @notice Supply `amount` of `asset` into Aave
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) internal {
        POOL.supply(asset, amount, onBehalfOf, REFERRAL_CODE);
    }

    /// @notice Withdraw up to `amount` of `asset` from Aave
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        return POOL.withdraw(asset, amount, to);
    }

    /// @notice Borrow `amount` of `asset` from Aave
    /// @param interestRateMode 1 = stable, 2 = variable
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) internal {
        POOL.borrow(asset, amount, interestRateMode, REFERRAL_CODE, onBehalfOf);
    }

    /// @notice Repay `amount` of borrowed `asset` to Aave
    /// @param rateMode must match borrow rate mode
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) internal returns (uint256) {
        return POOL.repay(asset, amount, rateMode, onBehalfOf);
    }

    /// TODO
    function flashLoan(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes memory params
    ) internal {
    }

    /// @notice Fetch the aToken address for a given underlying `asset`
    function getATokenAddress(
        address asset
    ) internal view returns (address) {
        (address aToken,,) = AAVE_PROTOCOL_DATA_PROVIDER.getReserveTokensAddresses(asset);
        return aToken;
    }

    /// @notice Get the raw aToken balance of `account`
    function getATokenBalance(
        address asset,
        address account
    ) internal view returns (uint256) {
        return IERC20(getATokenAddress(asset)).balanceOf(account);
    }

    //TODO
    // /// @notice Compute the underlying balance (including accrued interest) of `account`
    // function getUnderlyingBalance(
    //     IPoolDataProvider
    //     address asset,
    //     address account
    // ) internal view returns (uint256) {
    //     uint256 aBalance = getATokenBalance(provider, asset, account);
    //     uint256 income = AAVE_PROTOCOL_DATA_PROVIDER.getReserveNormalizedIncome(asset);
    //     return (aBalance * income) / RAY;
    // }

    // /// @notice Calculate profit over the `principal` supplied
    // function calculateProfit(
    //     IPoolDataProvider provider,
    //     address asset,
    //     address account,
    //     uint256 principal
    // ) internal view returns (uint256) {
    //     uint256 underlying = getUnderlyingBalance(provider, asset, account);
    //     return underlying > principal ? underlying - principal : 0;
    // }

    /// @notice Get the health factor for `user` (Ray-scaled)
    function getHealthFactor(
        address user
    ) internal view returns (uint256) {
        (, , , , , uint256 hf) = POOL.getUserAccountData(user);
        return hf;
    }

    /// @notice Get the total debt (base currency, Ray-scaled) for `user`
    function getTotalDebtBase(
        address user
    ) internal view returns (uint256) {
        (, uint256 totalDebt, , , , ) = POOL.getUserAccountData(user);
        return totalDebt;
    }
}
