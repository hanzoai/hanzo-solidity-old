import ether from 'zeppelin-solidity/test/helpers/ether'
import {advanceBlock} from 'zeppelin-solidity/test/helpers/advanceToBlock'
import {increaseTimeTo, duration} from 'zeppelin-solidity/test/helpers/increaseTime'
import latestTime from 'zeppelin-solidity/test/helpers/latestTime'
import EVMThrow from 'zeppelin-solidity/test/helpers/EVMThrow'

var Crowdsale = artifacts.require('Crowdsale')
const BigNumber = web3.BigNumber

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('Crowdsale', function(accounts) {
  const rate = new BigNumber(1000)
  const value = ether(42)
  const auditorFee = new Number(50)
  const tokenName = "TestToken"
  const tokenSymbol = "tT"
  const initialTokenAmount = new BigNumber(100000)
  const tokensForPresale = new BigNumber(100000)

  before(async function() {
    //Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
    await advanceBlock()
  })

  beforeEach(async function() {
    this.startTime = latestTime() + duration.weeks(1);
    this.endTime =   this.startTime + duration.weeks(1);
    this.afterEndTime = this.endTime + duration.seconds(1)
    this.crowdsale = await Crowdsale.new(this.startTime, this.endTime, accounts[0], accounts[1], auditorFee, tokenName, tokenSymbol, initialTokenAmount, tokensForPresale)
  })

  it('should log presale correctly', async function() {
    var contribution = new BigNumber(Math.floor(Math.random() * 100000))
    const {logs} = await this.crowdsale.logOffChainPresale(accounts[3], contribution, {from: accounts[1]})
    const event = logs.find(e => e.event === 'PresalePurchase')
    should.exist(event)
    event.args.beneficiary.should.equal(accounts[3])
    event.args.amount.should.be.bignumber.equal(contribution)
  })

  it('should return rate', async function() {
    let ret = await this.crowdsale.getRate()
    console.log('getRate', ret)
    ret.toNumber().should.equal(0)
  })

})
