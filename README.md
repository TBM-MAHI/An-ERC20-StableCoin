# **An ERC-20 Stable Coin**

The Stable Coin Project is a blockchain-based initiative aimed at providing stability in decentralized finance (DeFi) transactions through the creation of a stablecoin. The project comprises several key components, including the stablecoin smart contract, the Depositor Coin smart contract, an oracle smart contract for price feeds, and a standard ERC20 token contract.


### 1. Stable Coin Smart Contract
---
The Stable Coin smart contract is responsible for managing the stablecoin. It inherits functionalities from the ERC20 token contract. The key features of the Stable Coin contract include:

* **`Constructor:`**

    * Takes various arguments including the stablecoin name, symbol, initial collateral ratio percentage, lock time for DepositorCoin withdrawals, and the address of the Oracle contract.

* **`mint()`:**

  * Allows users to mint new stablecoins by sending Ether to the contract.
  * Calculates the fee based on `feePercentage`.
  * Queries the `Oracle` contract to get the current ETH price.
  * Mints new stablecoins to the user based on the deposited Ether amount minus the fee and the current ETH price.
* **`burn(burnAmount):`**

  * Allows users to burn their stablecoins in exchange for Ether.
  * Calculates the amount of Ether to be refunded based on the burn amount and the current ETH price obtained from the Oracle.
  * Burns the requested amount of stablecoins from the user's balance.
  * Sends the calculated Ether amount back to the user minus the fee.
* **`calculateFee(amount):`**

  * A private helper function that calculates the fee based on a percentage applied to the provided amount.
* **`depositCollateralBuffer():`**

  * Allows users to deposit additional Ether as collateral to maintain the collateral ratio.
  * Checks if a DepositorCoin contract exists (meaning it's the first deposit or the pool is underwater).
  * Calculates the required minimum surplus based on the initial collateral ratio and total stablecoin supply.
  * Calculates the deficit or surplus in USD based on the current contract balance and total stablecoin supply.
  * If it's the first deposit or the pool is underwater, deploys a new DepositorCoin contract and sets the initial DepositorCoin price to 1 USD.
  * Otherwise, calculates the DepositorCoin price per USD based on the total DepositorCoin supply and current surplus.
  * Mints new DepositorCoins to the user based on the deposited Ether amount converted to USD and then to DepositorCoins using the calculated DepositorCoin price.
* **`withdrawCollateralBuffer(burn_depositorCoinAmount):`**

  * Allows users to withdraw their deposited Ether by burning their DepositorCoins.
  * Burns the requested amount of DepositorCoins from the user's balance.
  * Checks if there's enough surplus to allow withdrawal.
  * Calculates the DepositorCoin price per USD based on the total DepositorCoin supply and current surplus.
  * Converts the burned DepositorCoin amount to USD based on the DepositorCoin price.
  * Calculates the equivalent Ether amount based on the converted USD amount and the current ETH price obtained from the Oracle.
  * Sends the calculated Ether amount back to the user.

* **`get_Surplus__OR__DeficitInUSD():`**

  * A private helper function that calculates the current surplus or deficit in USD.
  * Gets the total contract balance in USD by multiplying the current balance minus the function call value (to avoid double counting the deposited Ether) with the current ETH price.
  * Subtracts the total stablecoin supply from the total contract balance in USD to determine the surplus or deficit.
   
### 2. Depositor Coin Smart Contract
---
The Depositor Coin (DPC) smart contract facilitates the deposit and withdrawal of collateral for leveraged trading. Key features of the Depositor Coin contract include:
* **`Constructor:`**

  * Takes arguments for the token name, symbol, and lock time for mint/burn functions.
* **`mint(address to, uint256 value):`** 

  * A function that can only be called by the contract owner `(StableCoin contract)` to mint new DepositorCoins`(DPC)` to a specified address.

* **`burn(address from, uint256 value):`** 

  * A function that can only be called by the contract owner (StableCoin contract) to burn DepositorCoins from a specified address.
* **`isLocked modifier:`** 

  * Ensures that mint and burn functions can only be called after the lock time has passed.

### 3. Oracle
---
This smart contract acts as an oracle to provide the USD price for Ether.

* **`Constructor:`** 

  * Sets the contract owner (presumably an administrator).
  
* **`setPrice(uint _newprice):`** 

  * A function that can only be called by the contract owner to set the new USD price for Ether.
* **` getPrice():`** 

  * A view function that returns the current

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```
