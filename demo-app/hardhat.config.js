require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()
console.log(process.env.PRIV_KEY)
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    edgechain: {
      url: "http://localhost:10002/",
      accounts: [process.env.PRIV_KEY],
    },
  },
};