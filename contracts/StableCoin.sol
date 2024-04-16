//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";
import {ERC20} from "./ERC20.sol";
import "hardhat/console.sol";
import {
    FixedPoint,
    formFraction, 
    multiplyWithFixedPoint,
    divFixedPoint
    } from "./Fixedpoint.sol";

contract StableCoin is ERC20 {
        //Stablecoin is the Owner of the Depositor Coin
        //depositor coin contract only becomes useful when people starts deposit extra ETH (leveraged trading)
        DepositorCoin public depositorCoin;
        Oracle public oracle;
        uint public feePercentage;
        uint public initial_Collateral_Ratio_Percentage;
        uint public Depositor_Coin_LockTime;

    error InitialCollateralRatioError (string eMessage, uint minAmount);
    
    constructor 
     ( 
        string memory _name,
        string memory _symbol,
        uint _initial_Collateral_Ratio_Percentage,
        uint _feePercentage,
        uint _locktime,
        Oracle oracle_contractAddress  // address of the contract
     ) ERC20(_name,_symbol)
     {
        initial_Collateral_Ratio_Percentage = _initial_Collateral_Ratio_Percentage;
        feePercentage = _feePercentage;
        Depositor_Coin_LockTime = _locktime;
        oracle = oracle_contractAddress;
     }

    function mint() external payable{
        /// @dev calculate the eth USD price
        uint feeAmount = calculateFee(msg.value);
        uint stableCoinAmount = (msg.value - feeAmount)*oracle.getPrice();
        _mint(msg.sender, stableCoinAmount);
    }

    function burn(uint burnAmount) external {
        //REFUNDING DEPOSITED ETH
        uint refund_ETH = burnAmount/oracle.getPrice();
        /*example:
            1 deposited 1.3 eth = 1300 stablecoin 
            now refund_ETH = 1300000000000000000*1000/1000
            burn 1300 stable token and give back 1300000000000000000 wei/ 1.3eth
         */
        _burn(msg.sender, burnAmount);
        uint feeAmount = calculateFee(refund_ETH);
        (bool success, ) = msg.sender.call{ value:refund_ETH - feeAmount }("");
        require(success); //      require(success==true);
    }

    function calculateFee(uint amount) private view returns(uint){
        return amount*(feePersentage/100);
    }

    /// @dev // the function where extra ETH are deposited by leveraged traders
    function depositCollateralBuffer() payable external{
       
        int deficit_or_surplus  = get_Surplus__OR__DeficitInUSD();
        /// @dev initial the surplus amount is 0; so in the first deposit we can set the deposited 
        /// @dev eth (converted to USD) As the initial/starting surplus amount
        if( deficit_or_surplus <= 0){
            console.log("deficit_or_surplus");
            console.logInt(deficit_or_surplus);

             /* in Our Example :
            1 ETH = 1000 $USD
            Total Depositor Coin  : 250 DPC
            Total Stable Coin  : 1000STB ~ 1000$
            Total Dollar amount in depositor pool/SURPLUS : 0$
            price of 1 depositor Coin In USD/1DPC = total supply/ total DPC amount
                                                = 250/500 = 0.5$
         */
            ///@notice deploy the DepositorCoin in 2 Criteria 
                    /// 1. initially when the surplus amount is Zero/empty
                    /// 2. When the pool is underwater or negative surplus 
            ///DEPLOYING WILL RESET THE TOTAL SUPPLY TO 0
             /* 
             Safety Margin : 25% of total Stable Coin supply --> ( 25/100 * 1000) = 250 USD is the Safety Margin  
             */
            uint required_minimum_surplus_In_USD = ( initial_Collateral_Ratio_Percentage * totalSupply) /100;
             console.log(
                " Total supply ",totalSupply
            );
            console.log(
                "required_minimum_surplus_In_USD -> ",required_minimum_surplus_In_USD
            );
           
            uint required_minimum_surplus_In_ETH= required_minimum_surplus_In_USD / oracle.getPrice();
              console.log(
                "required_minimum_surplus_In_ETH -> ",required_minimum_surplus_In_ETH
            );
            
            uint deficit_USD = uint(deficit_or_surplus * -1);
             console.log(
                "deficit_USD -> ",deficit_USD
            );
            uint deficit_ETH = deficit_USD / oracle.getPrice();     
            uint added_surplus = msg.value - deficit_ETH; //adjusting the surplus by subtracting deficit
            console.log(
                "added_surplus -> ",added_surplus);
            uint minDepositAmount = deficit_USD + required_minimum_surplus_In_ETH;

            if ( added_surplus < required_minimum_surplus_In_ETH) {
                revert InitialCollateralRatioError("STC : Initial Collateral ratio Not Met. Minimum is", minDepositAmount); 
            } 
           uint256 initial_DepositorCoinAmount_USD = added_surplus * oracle.getPrice() ;
            
            depositorCoin = new DepositorCoin(
                    "Depositor Coin", 
                    "DPC", 
                    Depositor_Coin_LockTime,
                    msg.sender,
                    initial_DepositorCoinAmount_USD
                );
            return;
        } 
        
        uint surplus = uint(deficit_or_surplus);
            //  price of 1 depositor Coin In USD/1DPC =  2e18 USD 
        FixedPoint DPC_InUSD_price = formFraction(depositorCoin.totalSupply(), surplus);
            
        uint added_new_surplus = msg.value;
        /* 
            mintDepositorCoinAmount = 1e18 * 1000 * 0.5E18 = 0.5 e36*/
        uint256 mintDepositorCoinAmount = multiplyWithFixedPoint ( added_new_surplus *  oracle.getPrice() , DPC_InUSD_price );
        /* 
            SOMEONE deposits 1 eth as collateral; 
            added new Surplus Eth : 1 ETH
            So first ETH is converted to USD
            and then that amount of usd is converted into depositor coin,
            basically calculating how much of that deposited eth is worth in USD
         */   
          /// @dev deposit 1 eth --> 1e18 * 1000 * 0.5e18/1e18 --> GET 1000e18 DPC 
        depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
    }


    function withdrawCollateralBuffer( uint256 burn_depositorCoinAmount) external{
        
        depositorCoin.burn(msg.sender, burn_depositorCoinAmount);
       
        int deficit_or_surplus  = get_Surplus__OR__DeficitInUSD();
        require(deficit_or_surplus > 0, "STC: Not Enough Surplus to Withdraw");
        /// As surplus is > 0 ; so there is DPC in the pool; so extra ether depositors can withdraw
        uint surplus = uint(deficit_or_surplus);
        
        //  price of 1 depositor Coin In USD/1DPC = 0.5e18 USD 
        FixedPoint DPC_InUSD_price = formFraction( depositorCoin.totalSupply(), surplus ); 

       
        // then the amount of depositor Coin to be burned (ex-125 PDC) is converted to USD
        // 125E18*e18 / 0.5E18 = 250E18 USD
        uint refundAmountInUSD = divFixedPoint( burn_depositorCoinAmount, DPC_InUSD_price );
        //250E18/1000 = 0.25ETH
        uint refundAmountInETH = refundAmountInUSD / oracle.getPrice();

        (bool success,) = msg.sender.call{value:refundAmountInETH}("");

        require(success,"STC : Withdraw collateral Coin transaction failed");
    }

    function get_Surplus__OR__DeficitInUSD() private view returns(int){
        uint ethContractTotalBalanceInUSD = (address(this).balance - msg.value) * oracle.getPrice();
        //the total amount of stableCoin Tokens when Deployed
         uint totalStableCoinBalanceInUSD = totalSupply;

         /* now calculate the surplus or Deficit amount ( Deficit-->when the pool is underwater) by subtracting total stable coin supply/amount 
          from the Total Contract Balance */ 

         
         /// @notice Example of deficit :::::
         /// Deficit amount:  pool total balance(STB+DPC)(1500$) - Stable coin balance(2000 Stable Coin-2000$) = -500$
         
        int deficit_or_surplus = int( ethContractTotalBalanceInUSD )-int( totalStableCoinBalanceInUSD );
        return deficit_or_surplus;
    }

} 