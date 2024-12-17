// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinDeploy is Script {
    DecentralizedStableCoin private stableCoin;
    address private owner;
    function run() public {
        owner = vm.parseAddress(vm.envString("OWNER_ADDRESS"));
        vm.startBroadcast();
        stableCoin = new DecentralizedStableCoin(owner);
        vm.stopBroadcast();
    }
}