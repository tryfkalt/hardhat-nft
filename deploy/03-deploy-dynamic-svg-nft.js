const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
const fs = require("fs");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const chainId = network.config.chainId;
  let ethUsdPriceFeedAddress;

  if (developmentChains.includes(network.name)) {
    const EthUsdAggregator = await ethers.getContract("MockV3Aggregator");
    ethUsdPriceFeedAddress = EthUsdAggregator.address;
  } else {
    ethUsdPriceFeedAddress = network.config.ethUsdPriceFeed;
  }

  log("----------------------------------------------------");
  const lowSvg = await fs.readFileSync("./images/dynamicNFT/frown.svg", "utf8");
  const highSvg = await fs.readFileSync("./images/dynamicNFT/happy.svg", "utf8");

  args = [ethUsdPriceFeedAddress, lowSvg, highSvg];

  const dynamicSvgNft = await deploy("DynamicSvgNft", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  if (!developmentChains.includes(network.name)) {
    log("Verifying...");
    await verify(dynamicSvgNft.address, args);
  }
};

module.exports.tags = ["all", "dynamicsvg", "main"];
