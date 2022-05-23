require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
// require("@openzeppelin/hardhat-upgrades");

const PRIVATE_KEY = process.env.PRIVATE_KEY;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.3",
    settings: {
      // evmVersion: 'istanbul',
      optimizer: {
        enabled: true,
        runs: 999999,
      },
    },
  },
  networks: {
    baobab: {
      url: "https://kaikas.baobab.klaytn.net:8651/",
      gasPrice: 750000000000,
      accounts: [PRIVATE_KEY],
      chainId: 1001,
    },
    cypress: {
      url: "https://public-node-api.klaytnapi.com/v1/cypress",
      chainId: 8217, //Klaytn mainnet's network id
      accounts: [PRIVATE_KEY],
      gas: 8500000,
      timeout: 3000000,
      gasPrice: 750000000000,
    },
  },
};
