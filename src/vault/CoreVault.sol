// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VaultStorage} from "../libs/VaultStorage.sol";
import {NonfungiblePredictionManager} from "./NonfungiblePredictionManager.sol";
import {VaultEE} from "../libs/VaultEE.sol";
import {AaveLibrary} from "../libs/AaveLibs.sol";
import {VaultLogic} from "../libs/VaultLogic.sol";

contract Polyaave is ReentrancyGuard {
    using SafeERC20 for IERC20;

    modifier onlyQuoteOwner(uint256 qid) {
        if(VaultStorage.$$().npm.ownerOf(qid) != msg.sender) revert VaultEE.NotOwner();
        _;
    }

    // modifier onlyStrategy() {
    //     if(!VaultStorage.$$().approvedstrategy[msg.sender]) revert VaultEE.NotStrategy();
    //     _;
    // }

    constructor(address usdc) {
        VaultStorage.$ storage $ = VaultStorage.$$();
        $.collateralToken = IERC20(usdc);
        $.aToken = IERC20(AaveLibrary.getATokenAddress(usdc));
        $.oparators[msg.sender] = true;
        IERC20(usdc).approve(address(AaveLibrary.POOL), type(uint256).max);
        $.npm = new NonfungiblePredictionManager(address(this));
    }

    function depositCollateral(uint256 amount) external nonReentrant {
        VaultLogic.depositCollateral(amount);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant {
        VaultLogic.withdrawCollateral(amount);
    }

    function funding(uint256 qid, uint256 amount) external nonReentrant {
        VaultLogic.funding(qid, amount);
    }

    function lockCollateral(uint256 qid, uint256 amount) external nonReentrant {
        VaultLogic.lockCollateral(qid, amount);
    }

    function unlockCollateral(uint256 qid, uint256 amount) external nonReentrant {
        VaultLogic.unlockCollateral(qid, amount);
    }

    function setOperator(address op, bool approved) external {
        VaultStorage.$ storage v = VaultStorage.$$();
        v.oparators[op] = approved;
    }

    function setStrategyApproval(address strat, bool approved) external {
        VaultStorage.$ storage v = VaultStorage.$$();
        v.approvedstrategy[strat] = approved;
    }

    function userBalance(address user) external view returns (uint256) {
        return VaultStorage.$$().supplyOf[user];
    }

    function quoteCollateral(uint256 qid) external view returns (uint256) {
        return VaultStorage.$$().quote[qid].collateral;
    }

    function totalCollateral() external view returns (uint256) {
        return VaultStorage.$$().aToken.balanceOf(address(this));
    }
}
