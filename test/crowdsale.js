import ether from 'zeppelin-solidity/test/helpers/ether'
import {advanceBlock} from 'zeppelin-solidity/test/helpers/advanceToBlock'
import {increaseTimeTo, duration} from 'zeppelin-solidity/test/helpers/increaseTime'
import latestTime from 'zeppelin-solidity/test/helpers/latestTime'
import EVMThrow from 'zeppelin-solidity/test/helpers/EVMThrow'

var Crowdsale = artifacts.require("Crowdsale")


contract('Crowdsale', function(accounts) {
  const rate = new Number(1000)
  const value = ether(42)
  const auditorFee = new Number(50)
  const tokenName = "TestToken"
  const tokenSymbol = "tT"
  const initialTokenAmount = new Number(100000)
  const tokensForPresale = new Number(100000)

  before(async function() {
    //Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
    await advanceBlock()
  })

  beforeEach(async function () {
    this.startTime = latestTime() + duration.weeks(1);
    this.endTime =   this.startTime + duration.weeks(1);
    this.afterEndTime = this.endTime + duration.seconds(1)

    this.crowdsale = Crowdsale.new(this.startTime, this.endTime, accounts[0], accounts[1], auditorFee, tokenName, tokenSymbol, initialTokenAmount, tokensForPresale)
  })

  it('should log presale correctly', async function() {
    let success = this.crowdsale.logOffChainPresale(accounts[3], rate)
    succes.should.equal(true)
  })
})
