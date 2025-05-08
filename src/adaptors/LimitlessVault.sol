// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IFpmm } from "../interfaces/Fpmm.sol";
import { IAdaptor } from "../interfaces/IAdaptor.sol";
//TODO: old
contract LimitlessAdaptor {

    struct TradeParams {
        address trader;
        address exchange;
        address tokenAddress;
        uint tokenId;
        uint amount;
        bool isBuy;
        bytes data;
    }
        

    // IFpmmのアドレスは各TradeParams.exchangeで渡される前提

    // Fpmmのアウトプットトークン量取得
    function getOutpuTokenAmount(address exchange, address, uint tokenId) external view  returns (uint256) {
        // IFpmmのgetOutcomeTokenCountなど、適切な関数を呼び出す
        return IFpmm(exchange).calcSellAmount(tokenId, tokenId);
    }

    // Fpmmの価格取得
    function getPrice(address exchange, address, uint tokenId) external view  returns (uint256) {
        // IFpmmのprice系関数を呼び出す
        return IFpmm(exchange).calcBuyAmount(tokenId, tokenId);
    }

    function getOppositePosition(address, uint256 tokenId) external  pure returns(address oppositeTokenAddress, uint256 oppositeTokenId) {
        oppositeTokenAddress = address(0);
        oppositeTokenId = tokenId == 1 ? 0 : 1;
    }

    // 資金追加のpayload生成
    function addfunding(TradeParams calldata params) external pure  returns (bytes memory payload) {
        // 例: IFpmm(address).addstrategying(address[] memory _collateralTokens, uint[] memory _amounts)
        // params.dataに必要な引数情報を詰めておく想定
        return abi.encodeWithSelector(IFpmm.addstrategying.selector, params.data);
    }

    function buildBuy(TradeParams calldata params) external pure  returns (bytes memory payload) {
        return abi.encodeWithSelector(IFpmm.buy.selector, params.data);
    }

    // Sell用payload生成
    function buildSell(TradeParams calldata params) external pure  returns (bytes memory payload) {
        // 例: IFpmm(address).sell(uint outcomeIndex, uint amount, uint minProfit)
        // params.dataに outcomeIndex, minProfit などを詰めておく想定
        return abi.encodeWithSelector(IFpmm.sell.selector, params.data);
    }
}