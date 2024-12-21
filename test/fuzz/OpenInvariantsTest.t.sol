//// SPDX-License-Identifier: MIT
//
//pragma solidity ^0.8.18;
//
//import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
//import {DecentralizedStableCoinDeploy} from "../../script/DecentralizedStableCoinDeploy.s.sol";
//import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
//import {DSCEngine} from "../../src/DSCEngine.sol";
//import {HelperConfig} from "../../script/HelperConfig.s.sol";
//import {Test} from "../../lib/forge-std/src/Test.sol";
//import {IERC20} from "../../lib/openzeppelin-contracts/lib/erc4626-tests/ERC4626.prop.sol";
//import { console } from "forge-std/console.sol";
//
//
//contract OpenInvariantsTest is StdInvariant, Test {
//    DecentralizedStableCoinDeploy private deployer;
//    DecentralizedStableCoin private stableCoin;
//    DSCEngine private dscEngine;
//    HelperConfig private helperConfig;
//    address private weth;
//    address private wbtc;
//
//    function setUp() external {
//        deployer = new DecentralizedStableCoinDeploy();
//        (stableCoin, dscEngine, helperConfig) = deployer.run();
//        (,,weth,wbtc,) = helperConfig.activeNetworkConfig();
//        targetContract(address(dscEngine));
//    }
//
//    function invariant_protocolShouldHaveMoreValueThenTotalSupply() public view  {
//        uint256 totalSupply = stableCoin.totalSupply();
//        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(this));
//        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(this));
//
//        uint256 usdValueOfWethDeposited = dscEngine.getUsdValueOfCollateral(weth,totalWbtcDeposited);
//        uint256 usdValueOfWbtcDeposited = dscEngine.getUsdValueOfCollateral(wbtc,totalWbtcDeposited);
//
//        console.log("totalSupply %s",totalSupply);
//        console.log("totalDeposited %s",usdValueOfWethDeposited + usdValueOfWbtcDeposited);
//
//        assert(usdValueOfWethDeposited + usdValueOfWbtcDeposited >= totalSupply);
//    }
//}