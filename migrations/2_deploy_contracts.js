var Crowdsale = artifacts.require("./Crowdsale.sol");

module.exports = function(deployer, network, accounts) {
  const startTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 1 // one second in the future
  const endTime = startTime + (86400 * 20) // 20 days
  const rate = new web3.BigNumber(1000)
  const merchant = accounts[0]
  const auditor = accounts[1]
  const auditorFee = 50
  const tokenName = "testToken"
  const tokenSymbol = "tT"
  const initialTokenAmount = 100000
  const tokensForPresale = 100000

  deployer.deploy(Crowdsale, startTime, endTime, merchant, auditor, auditorFee, tokenName, tokenSymbol, initialTokenAmount, tokensForPresale)

};
