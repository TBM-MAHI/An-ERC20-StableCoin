//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";

contract Oracle  {
    uint private price;
    address private owner;

    constructor(){
        owner = msg.sender;
    }
    function setPrice(uint _newprice) external {
        require( owner == msg.sender,"EthUSDPrice: Only Owner can set Price" );
        price = _newprice;
    }

    function getPrice() external view returns(uint){
            return price;
    }
}
