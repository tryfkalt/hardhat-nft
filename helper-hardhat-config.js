const { ethers } = require("hardhat");

const networkConfig = {
  11155111: {
    name: "sepolia",
    vrfCoordinatorV2: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
    raffleEntranceFee: ethers.utils.parseEther("0.01"),
    gasLane: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
    subscriptionId: "10186",
    callbackGasLimit: "500000",
    keepersUpdateInterval: "30",
    mintFee: "10000000000000000", // 0.01 ETH
    ethUsdPriceFeed: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
  },
  31337: {
    name: "hardhat",
    raffleEntranceFee: ethers.utils.parseEther("0.01"),
    gasLane: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
    callbackGasLimit: "500000",
    keepersUpdateInterval: "30",
    mintFee: "10000000000000000", // 0.01 ETH
  },
};
const DECIMALS = "18";
const INITIAL_PRICE = "200000000000000000000";
const developmentChains = ["hardhat", "localhost"];

module.exports = { developmentChains, networkConfig, DECIMALS, INITIAL_PRICE };
