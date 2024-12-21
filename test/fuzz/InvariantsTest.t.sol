// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DecentralizedStableCoinDeploy} from "../../script/DecentralizedStableCoinDeploy.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test} from "../../lib/forge-std/src/Test.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/lib/erc4626-tests/ERC4626.prop.sol";
import { console } from "forge-std/console.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DecentralizedStableCoinDeploy private deployer;
    DecentralizedStableCoin private stableCoin;
    DSCEngine private dscEngine;
    HelperConfig private helperConfig;
    address private weth;
    address private wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DecentralizedStableCoinDeploy();
        (stableCoin, dscEngine, helperConfig) = deployer.run();
        (,,weth,wbtc,) = helperConfig.activeNetworkConfig();

        handler = new Handler(dscEngine,stableCoin);
        targetContract(address(handler));
    }

    function invariant_protocolShouldHaveMoreValueThenTotalSupply() public view  {
        uint256 totalSupply = stableCoin.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(this));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(this));

        uint256 usdValueOfWethDeposited = dscEngine.getUsdValueOfCollateral(weth,totalWethDeposited);
        uint256 usdValueOfWbtcDeposited = dscEngine.getUsdValueOfCollateral(wbtc,totalWbtcDeposited);

        assert(usdValueOfWethDeposited + usdValueOfWbtcDeposited >= totalSupply);
    }
}