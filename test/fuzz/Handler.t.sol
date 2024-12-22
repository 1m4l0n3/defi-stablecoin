// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import { console } from "forge-std/console.sol";

contract Handler is Test {
    DSCEngine private dscEngine;
    DecentralizedStableCoin private stableCoin;
    address [] private tokenCollateralAddresses;
    uint256 private constant MAX_DEPOSIT_AMOUNT = type(uint96).max;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _stableCoin) {
        dscEngine = _dscEngine;
        stableCoin = _stableCoin;
        tokenCollateralAddresses = dscEngine.getTokenCollateralAddresses();

    }

    // Public
    function depositCollateral(uint256 tokenCollateralAddressSeed, uint256 collateralAmount) public {
        collateralAmount = bound(collateralAmount,1,MAX_DEPOSIT_AMOUNT);
        address  tokenCollateralAddress = _getTokenCollateralAddress(tokenCollateralAddressSeed);
        ERC20Mock collateral = ERC20Mock(tokenCollateralAddress);

        vm.startPrank(msg.sender);

        collateral.mint(msg.sender,collateralAmount);
        collateral.approve(address(dscEngine),collateralAmount);
        dscEngine.depositCollateral(address(collateral),collateralAmount);

        vm.stopPrank();
    }

    function redeemCollateral(uint256 tokenCollateralAddressSeed, uint256 collateralToRedeem) public {
        address tokenCollateralAddress = _getTokenCollateralAddress(tokenCollateralAddressSeed);
        uint256 totalTokenCollateralOfUser = dscEngine.getCollateralValueOfUser(tokenCollateralAddress,msg.sender);
        uint256 totalTokenCollateralOfUserInUsd = dscEngine.getUsdValueOfCollateral(tokenCollateralAddress,totalTokenCollateralOfUser);
        (uint256 totalAmountMinted , uint256 totalCollateralValue) = dscEngine.getAccountInformation(msg.sender);

        uint256 maxAmountToMint = ( ( totalCollateralValue * dscEngine.LIQUIDATION_THRESHOLD() ) / dscEngine.LIQUIDATION_PRECISION() ) - totalAmountMinted;
        uint256 maxAmountToRedeem = maxAmountToMint > totalTokenCollateralOfUserInUsd ? totalTokenCollateralOfUserInUsd : maxAmountToMint;
        uint256 maxCollateralToRedeem = dscEngine.getCollateralValueOfUsd(tokenCollateralAddress,maxAmountToRedeem);
        collateralToRedeem = bound(collateralToRedeem,0,maxCollateralToRedeem);
        if (collateralToRedeem == 0) return;

        vm.prank(msg.sender);
        dscEngine.redeemCollateral(tokenCollateralAddress,collateralToRedeem);
    }

    function mintDSC(uint256 amountToMint) public {
        (uint256 totalAmountMinted , uint256 totalCollateralValue) = dscEngine.getAccountInformation(msg.sender);
        uint256 maxAmountToMint = ( ( totalCollateralValue * dscEngine.LIQUIDATION_THRESHOLD() ) / dscEngine.LIQUIDATION_PRECISION() ) - totalAmountMinted;
        amountToMint = bound(amountToMint,0,maxAmountToMint);
        if (amountToMint == 0) return;
        vm.startPrank(msg.sender);
        dscEngine.mintDSC(amountToMint);
        vm.stopPrank();
    }

    // Internal
    function _getTokenCollateralAddress(uint256 tokenCollateralAddressSeed) internal view returns(address tokenCollateralAddress){
        uint256 index = tokenCollateralAddressSeed % 2;
        return tokenCollateralAddresses[index];
    }
}
