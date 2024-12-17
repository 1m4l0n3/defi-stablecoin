// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoinDeploy} from "../script/DecentralizedStableCoinDeploy.s.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoinDeploy private deployer;
    DecentralizedStableCoin private stableCoin;

    function setUp() public {
        deployer = new DecentralizedStableCoinDeploy();
        stableCoin = deployer.run();
    }

    function testInitialSetupValues() view external {
        string memory coinName = "DecentralizedStableCoin";
        string memory coinSymbol = "DSC";

        string memory actualCoinName = stableCoin.name();
        string memory actualCoinSymbol = stableCoin.symbol();

        assertEq(coinName,actualCoinName);
        assertEq(coinSymbol,actualCoinSymbol);
    }
}