import ether from 'zeppelin-solidity/test/helpers/ether'
import {advanceBlock} from 'zeppelin-solidity/test/helpers/advanceToBlock'
import {increaseTimeTo, duration} from 'zeppelin-solidity/test/helpers/increaseTime'
import latestTime from 'zeppelin-solidity/test/helpers/latestTime'
import EVMThrow from 'zeppelin-solidity/test/helpers/EVMThrow'

var Crowdsale = artifacts.require('Crowdsale')
const BigNumber = web3.BigNumber
const NamedMintableToken = artifacts.require('NamedMintableToken')

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
    this.token = NamedMintableToken.at(await this.crowdsale.token())
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
    ret.toNumber().should.equal(0)
  })

  it('should return remaining presales appropriately', async function() {
    let pre = await this.crowdsale.remainingPresales()
    pre.toNumber().should.equal(0)
    var contribution = new BigNumber(Math.floor(Math.random() * 100000))
    const {logs} = await this.crowdsale.logOffChainPresale(accounts[4], contribution, {from: accounts[1]})
    let post = await this.crowdsale.remainingPresales()
    post.toNumber().should.equal(1)
  })

  it('should track presale contribution totals appropriately', async function() {
    let pre = await this.crowdsale.totalRaised()
    pre.should.be.bignumber.equal(0)
    var contribution1 = new BigNumber(Math.floor(Math.random() * 1000000000))
    var contribution2 = new BigNumber(Math.floor(Math.random() * 1000000000))
    const {logs} = await this.crowdsale.logOffChainPresale(accounts[3], contribution1, {from: accounts[1]})
    let mid = await this.crowdsale.totalRaised()
    mid.should.be.bignumber.equal(contribution1)
    const {logs2} = await this.crowdsale.logOffChainPresale(accounts[3], contribution2, {from: accounts[1]})
    let post = await this.crowdsale.totalRaised()
    post.should.be.bignumber.equal(contribution1.plus(contribution2))
  })

  it('should be token owner', async function () {
    const owner = await this.token.owner()
    owner.should.equal(accounts[0])
  })
})

