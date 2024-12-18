// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/lib/erc4626-tests/ERC4626.prop.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

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


contract DSCEngine is ReentrancyGuard {
    error DSCEngine__NotaValidToken(address tokenCollateralAddress);
    error DSCEngine__AmountShouldBePositive(uint256 amount);
    error DSCEngine__TokenAddressesAndPriceFeedAddressesLengthShouldBeSame();
    error DSCEngine__TransferFailed(address _from, address _to, uint256 _amount);

    mapping(address token => address priceFeed) private s_tokenToPriceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    DecentralizedStableCoin private immutable i_dsc;
    mapping(address user => uint256 amountDscMinted) private s_coinsMinted;

    event CollateralDeposited(address user, address tokenAddress, uint256 amount);

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

    constructor(address[] memory tokenCollateralAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if(tokenCollateralAddresses.length != priceFeedAddresses.length){
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesLengthShouldBeSame();
        }
        for ( uint256 index=0;index < tokenCollateralAddresses.length;index++){
            s_tokenToPriceFeeds[tokenCollateralAddresses[index]] = priceFeedAddresses[index];
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    // External & Public
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external moreThanZero(amountCollateral) isValidCollateral(tokenCollateralAddress){
        s_collateralDeposited[msg.sender][tokenCollateralAddress] = amountCollateral;
        emit CollateralDeposited(msg.sender,tokenCollateralAddress,amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed(msg.sender,address(this),amountCollateral);
        }
    }
    
    // Internal & Private
    function mintDSC(uint256 amountDSCToMint) public moreThanZero(amountDSCToMint) nonReentrant {
        s_coinsMinted[msg.sender] += amountDSCToMint;
    }
}
