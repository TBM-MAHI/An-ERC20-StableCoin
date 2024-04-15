//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "./ERC20.sol";

contract DepositorCoin is ERC20 {
    address public owner;
    uint public unlockTime;
    // if locked time is 2 days then depositors will be able to mint/burn after 
    // contract deployment ( time + 2 Days ) time

    modifier isLocked {
        require(block.timestamp > unlockTime, "DPC: Funds Still Locked");
        _;
    }

    constructor ( 
        string memory _name,
        string memory _symbol,
        uint _locked_time,
        address _initial_owner,
        uint _initialSupply
    ) ERC20(_name,_symbol)
        {
            owner = msg.sender;
            unlockTime = block.timestamp + _locked_time;
            //mint DPC When initializing the Contract is Deployed
            _mint(_initial_owner, _initialSupply);
        }
    
    function mint(address to,uint256 value) external isLocked {
        require(msg.sender == owner,"DPC:only owner can Mint");
        _mint(to, value);
    }

    function burn(address from,uint256 value) external isLocked{
        require(msg.sender == owner,"DPC:only owner can Burn");
        _burn(from, value);
    }
}
    
