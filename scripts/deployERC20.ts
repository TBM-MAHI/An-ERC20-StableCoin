import { ethers } from "hardhat";
import { yellow, blue, red, bgBlue, green, bold } from "colors";

async function main() {
  const ERC20Token_Instance = await ethers.getContractFactory("ERC20");
  const ERC20Token = await ERC20Token_Instance.deploy("MAHI", "MH");
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
