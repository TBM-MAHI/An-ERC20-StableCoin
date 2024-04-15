import { expect } from "chai";
import { ethers } from "hardhat";
import { bgBlue, bgCyan, green,red } from "colors";
import { DepositorCoin } from "../typechain-types";
import { StableCoin } from "../typechain-types";

describe(bgBlue("StableCoin Deploy & Mint"), function () {
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

  describe("With minted tokens", function () {
    let mint_Amount: number;

    beforeEach(async () => {
      const ethAmount = 1;
      mint_Amount = ethAmount * ethUsdPrice;
      //minitng 4000e18 MUSD coin
      await Stablecoin.mint({
        value: ethers.parseEther(ethAmount.toString()),
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
  });
});
