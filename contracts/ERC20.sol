//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "hardhat/console.sol";

contract ERC20 {
    string public symbol;
    string public name;
    //1 FULL Token = 1*10^18 = 1000000000000000000  gewi
    uint8 public immutable decimals = 18;
    uint256 public totalSupply;
    address public feeReceivingAccount = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    uint256 feePersentage = 1;
    bytes public data;

    mapping(address => uint256) public balanceOf;
    // owner account is the  account used as from account in transferFrom functions
    /* the Owner account is approving  some allowance of tokens to another 
    account that account can transfer from the owner accounts Funds*/
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

      function _mint(address to, uint256 value) internal {
        balanceOf[to] += value;
        totalSupply += value;
        //Not an ERC-20 Standard to emit an Event when burning or minting tokens
        emit Transfer(address(0), to, value);
    }
   
    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(address(0), from, value);
    }

    function minNewToken(address to, uint256 value) external  {
        _mint(to, value);
    }

   
    function burnTokens(address from, uint256 value) external {
       
        _burn(from, value);
    }
    function deposit() external payable {
        console.log("msg.value ",msg.value," wei");
        _mint(msg.sender, msg.value);
    }

    /// @dev dummy function to get tokens
    function giveMe1Token() external {
        balanceOf[msg.sender] += 1 * 10**18;
       /*  console.log(address(this));
        console.log(block.difficulty); */
    }

    //transfer to the address from the address who calling the function
    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    // THE ADDRESS CALLING THE *transferFrom* Function is using the Funds From the *from* address
    function transferFrom(
        address from,
        address recipient,
        uint256 amount
    ) external  returns (bool) {
        /* msg.sender of this functon is the spender of approve function() 
           from is the Owner account that is approving the allowance of tokens
        */
        console.log("msg.sender in transferFrom() ", msg.sender);
        require(
            allowance[from][msg.sender] >= amount,
            "ERC20: INSUFFICIENT ALLOWANCE BALANCE"
        );

        allowance[from][msg.sender] = allowance[from][msg.sender] - amount;
        emit Approval(from, msg.sender, allowance[from][msg.sender]);
        //decrease token value from "from" account and credit to recipient
        return _transfer(from, recipient, amount);
    }
    
    function redeem(uint amount) external {
        //STEP -1 trasfer amount to Smart Contract
        require(balanceOf[msg.sender]>amount,"ERC20: INSUFFCIENT SENDER BALANCE");
        //check that the smart contract has allowance
        require(
            allowance[msg.sender][address(this)] >= amount,
            "ERC20: INSUFFCIENT ALLOWANCE BALANCE"
        );

        allowance[msg.sender][address(this)] -= amount;
        require(  _transfer(msg.sender, address(this), amount),  "Transaction failed" );
        
        //STEP -2 burn the tokens from SMART CONTARCT
        _burn(address(this), amount);
        // Calculate Ether value to be sent back to the sender
        uint256 ethValue = amount / (10e18); 
        
        //STEP -3 Send Ether back to the sender
        (bool success,bytes memory returndata) = msg.sender.call{value:ethValue}("");
        console.log("ether sent back- ",success);
        data = returndata;
        require(success, "Failed to send Ether back to user");
    }

    function _transfer(
        address from,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {  //changed from private to internal for exercise
     console.log("running transfer() of ERC20_TOKEN");
        uint256 feeAmount = (amount * feePersentage) / 100;

        require(
            balanceOf[from] > amount + feeAmount,
            "ERC20: INSUFFCIENT SENDER BALANCE"
        );

        balanceOf[feeReceivingAccount] += feeAmount;
        balanceOf[from] = balanceOf[from] - amount - feeAmount;

        balanceOf[recipient] = balanceOf[recipient] + amount;
        emit Transfer(from, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        //msg.sender is the ownerAccount in mapping
        //omly owner account can set the spending allowance
      
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
