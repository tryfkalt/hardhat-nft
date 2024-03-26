const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log("----------------------------------------------------");
  const chainId = await network.provider.request({
    method: "eth_chainId",
  });

  const args = [];
  const basicNFT = await deploy("BasicNFT", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API) {
    loga("Verifying contract on Etherscan...");
    await verify(basicNFT.address, args);
    log("----------------------------------------------------");
  }
};

module.exports.tags = ["all", "basicnft"];
