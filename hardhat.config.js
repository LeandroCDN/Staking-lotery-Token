require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

const ALCHEMY_API_KEY_MUMBAI = process.env.ALCHEMY_API_KEY_MUMBAI;
const MUMBAI_PRIVATE_KEY = process.env.MUMBAI_PRIVATE_KEY;
const MUMBAI_SCAN_KEY = process.env.MUMBAI_SCAN_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {

  solidity: "0.8.17",
  networks: {
    hardhat: {},
    // goerli: {
    //   url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
    //   accounts: [GOERLI_PRIVATE_KEY],
    // },
    
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_API_KEY_MUMBAI}`,
      accounts: [MUMBAI_PRIVATE_KEY],
      gas:300000,
    },
  },
  etherscan: {
    apiKey: MUMBAI_SCAN_KEY, // Your Etherscan API key
  },

};
// RandomGenerator :0x66210e7fAd235a28671b9A97B2828f8c059bC01D
// LOTERY:0x8F4CaED5dc44B4e7e9f3B4Fa0Dd60CDE5234265A  - TODO SetToken
// Reward:0x821B51698C16C7C0c43ab4F4877F12E3f22Bd1C1
// Token:0xA8bA20b4334bAfd0f98656CED92Be9bf6C47504f
// Staking:0x856421492346624fb747261eEC4A5214fB1dCC8e