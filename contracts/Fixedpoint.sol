// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

//Fixed point under the hood is unsigned integer and also decimal points
type FixedPoint is uint;
// FixedPoint is also called 
// 18 decimals
// wad
// UD60x18 (60 digits before decimal point, 18 digits after decimal point)
// Example 442.938493...(18 decimal places)
uint constant DECIMALS = 1e18;
using {add as +, sub as -, mul as *, div as / } for FixedPoint global;

    function add(FixedPoint a , FixedPoint b) pure returns(FixedPoint){
    // unwrap --> convert from FixedPoint to uint
    // wrap--> convert from uint to FixedPoint
        return  FixedPoint.wrap( FixedPoint.unwrap(a) + FixedPoint.unwrap( b) );
    }

    function sub(FixedPoint a , FixedPoint b) pure returns(FixedPoint){
        return  FixedPoint.wrap( FixedPoint.unwrap(a) - FixedPoint.unwrap( b) );
    }

    function mul(FixedPoint a , FixedPoint b) pure returns(FixedPoint){
        return  FixedPoint.wrap( FixedPoint.unwrap(a) * FixedPoint.unwrap( b)/DECIMALS );
    }

    function div(FixedPoint a , FixedPoint b) pure returns(FixedPoint){
    /* Example : 5/2
        => 5e18*DECIMALS / 2*e18 
        => 5e18*1e18 / 2*e18 
        => 5e36 / 2*e18
        => 2500000000000000000 
        => 18  decimal places is 18 places after .
        => 2.500000000000000000 
        => 2.5e18
        ----------------
         Example : 1/2
        => 1e18*DECIMALS / 2*e18 
        => 1e18*1e18 / 2*e18 
        => 1e36 / 2*e18
        => 500000000000000000 
        => 18  decimal places is 18 places after .
        => 2.500000000000000000 
        => 2.5e18
       */
        return  FixedPoint.wrap( FixedPoint.unwrap(a) * DECIMALS / FixedPoint.unwrap( b) );
    }

    function  formFraction (uint numerator, uint denominator) pure returns(FixedPoint){
        return FixedPoint.wrap(numerator * DECIMALS / denominator);    
    }

    function multiplyWithFixedPoint(uint a, FixedPoint b) pure  returns(uint){
        return a * FixedPoint.unwrap( b) / 1e18 ;
    }

    function divFixedPoint(uint numerator, FixedPoint denominator) pure  returns(uint){
        return numerator*DECIMALS / FixedPoint.unwrap(denominator) ;
    }


    

