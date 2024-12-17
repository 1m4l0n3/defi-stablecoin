// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20Burnable,ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/*
 * @title: DecentralizedStableCoin
 * @author: Joe
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This is the contract meant to be governed by DSCEngine. This contract is just the ERC20 implementation of our stablecoin system.
 */



contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__MustBurnMoreThanZero();
    error DecentralizedStableCoin__MustBurnLessThanCurrentBalance();
    error DecentralizedStableCoin__CantMintToZeroAddress();
    error DecentralizedStableCoin__CantMintWithZeroAmount();

    constructor(address initialOwner) Ownable(initialOwner) ERC20("DecentralizedStableCoin","DSC"){

    }

    function burn(uint256 _amount) public override onlyOwner{
        if ( _amount <= 0){
            revert DecentralizedStableCoin__MustBurnMoreThanZero();
        }

        uint256 balance = balanceOf(msg.sender);
        if(balance < _amount){
            revert DecentralizedStableCoin__MustBurnLessThanCurrentBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns(bool){
        if (_to == address(0)) {
            revert DecentralizedStableCoin__CantMintToZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin__CantMintWithZeroAmount();
        }
    }
}