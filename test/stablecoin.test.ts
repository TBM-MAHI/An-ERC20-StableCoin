import { expect } from "chai";
import { ethers } from "hardhat";
import { bgBlue, bgCyan, green,red } from "colors";
import { DepositorCoin } from "../typechain-types";
import { StableCoin } from "../typechain-types";

describe(bgCyan("StableCoin Deploy"), function () {
  let ethUsdPrice: number, feeRatePercentage: number;
  let Stablecoin: StableCoin;

  beforeEach(async () => {
    feeRatePercentage = 2;
    ethUsdPrice = 4000;
    // deploy Oracle first
    let oracleFactory = await ethers.getContractFactory("Oracle");
    const oracleContract = await oracleFactory.deploy();
    await oracleContract.setPrice(ethUsdPrice);

    let stableCoinFactory = await ethers.getContractFactory("StableCoin");
    Stablecoin = await stableCoinFactory.deploy(
      "MAHIO StableCoin",
      "MUSD",
      25,
      2,
      0,
      oracleContract.getAddress()
    );
    await Stablecoin.waitForDeployment();
  });

  it(green("Should set fee rate percentage"), async () => {
    expect(await Stablecoin.feePercentage()).to.equal(feeRatePercentage);
  });

  it(green("Should allow minting"), async function () {
    const ethAmount = 1;
    const expectedMintAmount = ethAmount * ethUsdPrice;
    let ethAmountGwei = ethers.parseEther(ethAmount.toString());
    console.log(ethAmountGwei);
    await Stablecoin.mint({
      value: ethAmountGwei,
    });

    expect(await Stablecoin.totalSupply()).to.equal(
      ethers.parseEther(expectedMintAmount.toString())
    );
    console.log("StableCoin Total Supply ", await Stablecoin.totalSupply());
  });

  describe( bgCyan("With minted tokens Testing"), function () {
    let mint_Amount: number;

    beforeEach(async () => {
      const ethAmount = 1;
      mint_Amount = ethAmount * ethUsdPrice;
      //minitng 4000e18 MUSD coin
      await Stablecoin.mint({
        value: ethers.parseEther(ethAmount.toString()), //msg.value
      });
    });

    it( red("Should allow burning"), async function () {
      //remaining after burning the stablecoins
      const remainingStablecoinAmount = 100;
      await Stablecoin.burn(
        ethers.parseEther((mint_Amount - remainingStablecoinAmount).toString())
      );
      // total ( StableCoin 4000 ) - (3900)burned = 100 MUSD remaining
      expect(await Stablecoin.totalSupply()).to.equal(
        ethers.parseEther(remainingStablecoinAmount.toString())
      );
    });
    
    it(red("Should prevent/revert depositing collateral buffer below minimum"), async function () {
      /* 
      required_minimum_surplus_In_USD = 0.25*4000 (Total supply) = 1000E18 USD
       required_minimum_surplus_In_ETH = 1000E18/4000E18 = 0.25 =  25E16 eth
       uint added_surplus = msg.value (0.24 ETH ) - 0 (deficit_ETH) = 0.24 ETH;

       */
      const stablecoinCollateralBuffer = 0.24; // less than minimum (0.25)

      await expect(
        Stablecoin.depositCollateralBuffer({
          value: ethers.parseEther(stablecoinCollateralBuffer.toString()),
        })
      ).to.be.revertedWithCustomError(
        Stablecoin,
        "InitialCollateralRatioError"
      );
    });

    it(green("Should allow depositing collateral buffer"), async function () {
      const stablecoinCollateralBuffer = 0.5;
      await Stablecoin.depositCollateralBuffer({
        value: ethers.parseEther(stablecoinCollateralBuffer.toString()),
      });

      const DepositorCoinFactory = await ethers.getContractFactory(
        "DepositorCoin"
      );
      
      let Depositorcoin: DepositorCoin = await DepositorCoinFactory.attach(
        await Stablecoin.depositorCoin()
       );
      const newInitialSurplusInUsd = stablecoinCollateralBuffer * ethUsdPrice;
      expect(await Depositorcoin.totalSupply()).to.equal(
        ethers.parseEther(newInitialSurplusInUsd.toString())
      );
    });
  });

   describe( bgCyan( "With deposited collateral buffer"), function () {
     let stablecoinCollateralBuffer: number;
     let Depositorcoin: DepositorCoin;

     this.beforeEach(async () => {
       // DEPOSIT COLLATERAL 
       stablecoinCollateralBuffer = 0.5;
       await Stablecoin.depositCollateralBuffer({
         value: ethers.parseEther(stablecoinCollateralBuffer.toString()),
       });

       const DepositorCoinFactory = await ethers.getContractFactory(
         "DepositorCoin"
       );
       Depositorcoin = await DepositorCoinFactory.attach(
         await Stablecoin.depositorCoin()
       );
     });

     it("Should allow withdrawing collateral buffer", async function () {
       const newDepositorTotalSupply = stablecoinCollateralBuffer * ethUsdPrice;
       const stablecoinCollateralBurnAmount = newDepositorTotalSupply * 0.2;

       await Stablecoin.withdrawCollateralBuffer(
         ethers.parseEther(stablecoinCollateralBurnAmount.toString())
       );

       expect(await Depositorcoin.totalSupply()).to.equal(
         ethers.parseEther(
           (newDepositorTotalSupply - stablecoinCollateralBurnAmount).toString()
         )
       );
     });
   });
});
