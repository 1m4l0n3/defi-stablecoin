// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

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

    function redeemCollateral(uint256 tokenCollateralAddressSeed, uint256 collateralAmount) public {
        address tokenCollateralAddress = _getTokenCollateralAddress(tokenCollateralAddressSeed);
        uint256 totalUserCollateral = dscEngine.getCollateralValueOfUser(tokenCollateralAddress,msg.sender);
        collateralAmount = bound(collateralAmount,0,totalUserCollateral);
        if (collateralAmount == 0) return;
        vm.prank(msg.sender);
        dscEngine.redeemCollateral(tokenCollateralAddress,collateralAmount);
    }

    // Internal
    function _getTokenCollateralAddress(uint256 tokenCollateralAddressSeed) internal view returns(address tokenCollateralAddress){
        uint256 index = tokenCollateralAddressSeed % 2;
        return tokenCollateralAddresses[index];
    }
}
