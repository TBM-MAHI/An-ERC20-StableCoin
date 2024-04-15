import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        /* 
          By increasing runs, you are telling the optimizer that the functions on the contract are going to be called very often, so the optimizer will try and make functions cheaper to call, even if this means it has to inline/repeat some code… resulting in a larger contract with higher one-time initial deployment gas cost. So what the OP wants to be doing here is the opposite, to lower runs, to encourage the optimizer to save on initial deployment gas — in order to lower this cost, the optimizer will try and make the contract bytecode smaller, which might bring it back below the limit.
        */
      },
    },
  },
  defaultNetwork: "hardhat", // Set the default network to 'hardhat' for local deployments
  networks: {
    hardhat: {
      chainId: 1337, // Custom chain ID for local network
      // Add other configuration options for the Hardhat network if needed,
      // such as gas price or block gas limit
    },
  },
};

export default config;
