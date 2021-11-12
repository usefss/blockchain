const AuctionManager = artifacts.require("AuctionManager");

module.exports = function (deployer) {
  deployer.deploy(AuctionManager);
};
