// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoinDeploy} from "../script/DecentralizedStableCoinDeploy.s.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoinDeploy private deployer;
    DecentralizedStableCoin private stableCoin;
    DSCEngine private dscEngine;
    HelperConfig private helperConfig;
    address private owner;
    address private alice;
    address private weth;
    address private ethUsdPriceFeed;
    uint256 private constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DecentralizedStableCoinDeploy();
        (stableCoin, dscEngine, helperConfig) = deployer.run();
        (ethUsdPriceFeed,,weth,,) = helperConfig.activeNetworkConfig();
        owner = address(dscEngine);
        alice = makeAddr("alice");
        ERC20Mock(weth).mint(alice,STARTING_ERC20_BALANCE);
    }

    /////////////////
    // stableCoin //
    ////////////////
    function testInitialSetupValues() view external {
        string memory coinName = "DecentralizedStableCoin";
        string memory coinSymbol = "DSC";

        string memory actualCoinName = stableCoin.name();
        string memory actualCoinSymbol = stableCoin.symbol();

        assertEq(coinName,actualCoinName);
        assertEq(coinSymbol,actualCoinSymbol);
    }

    // Tests for Burn function
    function testOnlyOwnerShouldBurn() external {
        uint256 amount = 1;

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector,alice));
        stableCoin.burn(amount);
    }

    function testShouldRevertWhenBurstingLessThanZero() external {
        uint256 amount = 0;

        vm.prank(owner);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBurnMoreThanZero.selector);
        stableCoin.burn(amount);
    }

    // Tests for Mint function
    function testShouldRevertMintCallWithoutOwner() external {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector( Ownable.OwnableUnauthorizedAccount.selector,alice));
        stableCoin.mint(alice,1);
    }

    function testShouldNotMintToZeroAddress() external {
        vm.prank(owner);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__CantMintToZeroAddress.selector);
        stableCoin.mint(address(0),1);
    }

    function testShouldRevertMintingWithLessThanZeroAmount() external {
        vm.prank(owner);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__CantMintWithZeroAmount.selector);
        stableCoin.mint(alice,0);
    }

    /////////////////
    //  DscEngine //
    ////////////////

    function testEthToUsdConversion() external view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscEngine.getUsdValueOfCollateral(weth,ethAmount);
        assertEq(expectedUsd,actualUsd);
    }

    function testDepositShouldRevertIfCollateralIsZero() external {
        vm.prank(alice);
        uint256 amount = 0;

        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__AmountShouldBePositive.selector,amount));
        dscEngine.depositCollateral(weth,amount);
        vm.stopPrank();
    }
}