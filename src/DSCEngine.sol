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
    constructor(address initialOwner) Ownable(initialOwner) ERC20("DecentralizedStableCoin","DSC"){

    }
}