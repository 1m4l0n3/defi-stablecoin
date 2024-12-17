// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoinDeploy} from "../script/DecentralizedStableCoinDeploy.s.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoinDeploy private deployer;
    DecentralizedStableCoin private stableCoin;
    address private owner;
    address private alice;

    function setUp() public {
        deployer = new DecentralizedStableCoinDeploy();
        stableCoin = deployer.run();
        owner = vm.parseAddress(vm.envString("OWNER_ADDRESS"));
        alice = makeAddr("alice");
    }

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
        stableCoin.mint();
    }

}