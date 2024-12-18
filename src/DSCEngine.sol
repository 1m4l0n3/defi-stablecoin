// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/*
 * @title DSCEngine
 * @author Joe
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */


contract DSCEngine {
    error DSCEngine__NotaValidToken(address tokenCollateralAddress);
    error DSCEngine__AmountShouldBePositive(uint256 amount);

    mapping(address => address) private s_tokenToPriceFeeds;

    modifier moreThanZero(uint256 amount) {
        if(amount <= 0){
            revert DSCEngine__AmountShouldBePositive(amount);
        }
        _;
    }
    modifier isValidCollateral(address tokenCollateralAddress) {
        if (s_tokenToPriceFeeds[tokenCollateralAddress] == address(0)){
            revert DSCEngine__NotaValidToken(tokenCollateralAddress);
        }
        _;
    }

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external moreThanZero(amountCollateral) isValidCollateral(tokenCollateralAddress){
        
    }
}
