// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
 import {HelperConfig} from "./HelperConfig.s.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract DecentralizedStableCoinDeploy is Script {
    DecentralizedStableCoin private stableCoin;
    DSCEngine private dscEngine;
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    address private owner;

    function run() public returns(DecentralizedStableCoin,DSCEngine,HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        tokenAddresses = [weth,wbtc];
        priceFeedAddresses = [wethUsdPriceFeed,wbtcUsdPriceFeed];
        owner = vm.parseAddress(vm.envString("OWNER_ADDRESS"));

        vm.startBroadcast(deployerKey);
        stableCoin = new DecentralizedStableCoin(owner);
        dscEngine = new DSCEngine(tokenAddresses,priceFeedAddresses,address(stableCoin));
        stableCoin.transferOwnership(address(dscEngine));
        vm.stopBroadcast();

        return (stableCoin,dscEngine, helperConfig);
    }
}