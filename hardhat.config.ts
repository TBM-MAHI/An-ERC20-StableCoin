import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24", // Specify the Solidity version
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
