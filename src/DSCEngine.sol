// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/lib/erc4626-tests/ERC4626.prop.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__FailedToMint();
    error DSCEngine__InsufficientCollateralToRedeem(address tokenCollateralAddress, uint256 amount);
    error DSCEngine__InsufficientDSCToBurn(uint256 mintedCoins, uint256 coinsToBurn);
    error DSCEngine__HealthFactorOk();

    mapping(address token => address priceFeed) private s_tokenToPriceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_totalAmountMinted;
    address[] private s_collateralTokens;
    DecentralizedStableCoin private immutable i_dsc;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    event CollateralDeposited(address user, address tokenAddress, uint256 amount);
    event CollateralRedeemed(address user,address to, address tokenAddress, uint256 amount);
    event DSCEngine__DSCBurned(address user, uint256 amountToBurn);

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
            s_collateralTokens.push(tokenCollateralAddresses[index]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    // External
    function liquidate(address user,address tokenCollateralAddress, uint256 debtToCover) external  {
        uint256 startingHealthFactor = _healthFactor(user);
        if (startingHealthFactor > MIN_HEALTH_FACTOR){
            revert DSCEngine__HealthFactorOk();
        }
        uint256 collateralValueInUsd = getCollateralValueOfUsd(tokenCollateralAddress, debtToCover);
        uint256 liquidatorBonus = ( collateralValueInUsd * LIQUIDATION_BONUS ) / LIQUIDATION_PRECISION ;
        uint256 totalCollateralValueToRedeem = collateralValueInUsd + liquidatorBonus;
        _redeemCollateral(user,msg.sender,tokenCollateralAddress,totalCollateralValueToRedeem);
        _burnDsc(user,msg.sender,debtToCover);
        uint256 endingHealthFactor = _healthFactor(user);
        if (endingHealthFactor <= startingHealthFactor) {
            revert DSCEngine__HealthFactorOk();
        }
        _revertHealthFactorIsBroken(msg.sender);
    }

    function depositCollateralAndMintDSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountToMint) external {
        depositCollateral(tokenCollateralAddress,amountCollateral);
        mintDSC(amountToMint);
    }

    function BurnDscAndRedeemCollateral(address tokenCollateralAddress, uint256 amountCollateral,uint256 amountToBurn) external {
        burnDsc(amountToBurn);
        redeemCollateral(tokenCollateralAddress,amountCollateral);
    }

    // Public
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) isValidCollateral(tokenCollateralAddress){
        s_collateralDeposited[msg.sender][tokenCollateralAddress] = amountCollateral;
        emit CollateralDeposited(msg.sender,tokenCollateralAddress,amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender,address(this),amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed(msg.sender,address(this),amountCollateral);
        }
    }

    function mintDSC(uint256 amountToMint) public moreThanZero(amountToMint) nonReentrant {
        s_totalAmountMinted[msg.sender] += amountToMint;
        _revertHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender,amountToMint);
        if (!minted){
            revert DSCEngine__FailedToMint();
        }
    }

    function burnDsc(uint256 amountToBurn) public moreThanZero(amountToBurn) {
        if ( s_totalAmountMinted[msg.sender] < amountToBurn){
            revert DSCEngine__InsufficientDSCToBurn(s_totalAmountMinted[msg.sender],amountToBurn);
        }
        _burnDsc(msg.sender,msg.sender,amountToBurn);
        _revertHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountToRedeem) public {
        if (s_collateralDeposited[msg.sender][tokenCollateralAddress] < amountToRedeem){
            revert DSCEngine__InsufficientCollateralToRedeem(tokenCollateralAddress,amountToRedeem);
        }
        _redeemCollateral(msg.sender,msg.sender,tokenCollateralAddress,amountToRedeem);
        _revertHealthFactorIsBroken(msg.sender);
    }

    function getUsdValueOfCollateral(address token, uint256 CollateralAmount) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_tokenToPriceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return ( (uint256(price) * ADDITIONAL_FEED_PRECISION * CollateralAmount ) / PRECISION );
    }

    function getCollateralValueOfUsd(address tokenCollateralAddress, uint256 usdAmount) public view returns(uint256)  {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenCollateralAddress);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return ((usdAmount * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION));
    }

    function getAccountCollateralValueIsUsd(address user) public view returns(uint256){
        uint256 totalCollateralValueInUsd = 0;
        for(uint256 index;index <= s_collateralTokens.length;index++){
            address token = s_collateralTokens[index];
        uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValueOfCollateral(token,amount);
        }
        return totalCollateralValueInUsd;
    }


    // Internal
    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountToRedeem) internal {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountToRedeem;
        emit CollateralRedeemed(from,to,tokenCollateralAddress,amountToRedeem);

        bool success = IERC20(tokenCollateralAddress).transfer(to,amountToRedeem);
        if(!success) {
            revert DSCEngine__TransferFailed(address(this),msg.sender,amountToRedeem);
        }
    }

    function _burnDsc(address onBehalf, address by, uint256 amountToBurn) internal  {
        s_totalAmountMinted[onBehalf] -= amountToBurn;
        emit DSCEngine__DSCBurned(msg.sender,amountToBurn);
        bool success = i_dsc.transferFrom(by,address(this),amountToBurn);
        if (!success) {
            revert DSCEngine__TransferFailed(by,address(this),amountToBurn);
        }
        i_dsc.burn(amountToBurn);
    }

    function _healthFactor(address user) internal view returns(uint256){
        (uint256 totalAmountMinted , uint256 totalCollateralValueInUsd) = _getAccountInformation(user);
        if (totalAmountMinted == 0) {
            return type(uint256).max;
        }

        uint256 collateralAdjustedForThreshold = totalCollateralValueInUsd * LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISION;
        return ( collateralAdjustedForThreshold * PRECISION ) / totalAmountMinted;
    }

    function _revertHealthFactorIsBroken(address user) internal view {
        uint256 healthFactor = _healthFactor(user);
        if ( healthFactor < MIN_HEALTH_FACTOR){
            revert DSCEngine__BreaksHealthFactor(healthFactor);
        }
    }

    function _getAccountInformation(address user) internal view returns(uint256,uint256){
        uint256 totalAmountMinted = s_totalAmountMinted[user];
        uint256 totalCollateralValue = getAccountCollateralValueIsUsd(user);
        return (totalAmountMinted,totalCollateralValue);
    }

    // View / Pure
    function getTokenCollateralAddresses() public view returns(address [] memory tokenCollateralAddresses){
        return s_collateralTokens;
    }
}
