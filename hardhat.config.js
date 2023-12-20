/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require('@nomiclabs/hardhat-ethers');
require('@nomicfoundation/hardhat-verify');

const { ALCHEMY_API_URL, METAMASK_PRIVATE_KEY } = process.env;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

module.exports = {
  solidity: "0.8.22",
  defaultNetwork: "sepolia",
  networks: {
    hardhat: {},
    sepolia: {
        url: ALCHEMY_API_URL,
        accounts: [`0x${METAMASK_PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  }
};
