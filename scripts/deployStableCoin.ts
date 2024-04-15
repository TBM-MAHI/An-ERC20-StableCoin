import { ethers } from "hardhat";
import { yellow, blue, red, bgBlue, green, bold } from "colors";

async function main() {
  const StableCoin_Instance = await ethers.getContractFactory("StableCoin");
  const ERC20Token = await StableCoin_Instance.deploy(
    "MAHIO StableCoin",
    "MUSD",
    25,
    2,
    0,
    oracleContract.getAddress()
  );
  console.log(
    bold( green("CONTRACT DEPLOYED TO Address")),
    await ERC20Token.getAddress()
  );
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
