const FlashloanMoneyLego = artifacts.require('FlashloanMoneyLego.sol')

module.exports = function(_deployer) {
  _deployer.deploy(FlashloanMoneyLego)
};
