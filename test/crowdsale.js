import ether from 'zeppelin-solidity/test/helpers/ether'
import {advanceBlock} from 'zeppelin-solidity/test/helpers/advanceToBlock'
import {increaseTimeTo, duration} from 'zeppelin-solidity/test/helpers/increaseTime'
import latestTime from 'zeppelin-solidity/test/helpers/latestTime'
import EVMThrow from 'zeppelin-solidity/test/helpers/EVMThrow'

console.log('ding dongus')
var Crowdsale = artifacts.require('Crowdsale')
const BigNumber = web3.BigNumber
const NamedMintableToken = artifacts.require('NamedMintableToken')
console.log('dong dingus')

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('Crowdsale', function(accounts) {
  console.log('shamma lamma')
  const rate = new BigNumber(1000)
  const value = ether(42)
  const auditorFee = new Number(50)
  const tokenName = "TestToken"
  const tokenSymbol = "tT"
  const tokensForPresale = new BigNumber(Math.floor(Math.random() * 1000000) + 100000)
  const isCapped = Math.random() >= 0.5
  const initialTokenAmount = isCapped ? new BigNumber(Math.floor(Math.random() * 1000000) + tokensForPresale) : tokensForPresale

  before(async function() {
    console.log("fuuunngus")
    //Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
    //await advanceBlock()
    console.log(initialTokenAmount)
    console.log(isCapped)
    console.log(tokensForPresale)
  })

  beforeEach(async function() {
    console.log("dongus")
    this.startTime = latestTime() + duration.weeks(1)
    this.endTime =   this.startTime + duration.weeks(1)
    this.afterEndTime = this.endTime + duration.seconds(1)
    this.crowdsale = await Crowdsale.new(this.startTime, this.endTime, accounts[0], accounts[1], auditorFee, tokenName, tokenSymbol, initialTokenAmount, tokensForPresale, {from: accounts[1]})
    this.token = NamedMintableToken.at(await this.crowdsale.token())
  })

  it('should log presale correctly', async function() {
    var contribution = new BigNumber(Math.floor(Math.random() * 10000))
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
    var contribution1 = new BigNumber(Math.floor(Math.random() * 10000))
    var contribution2 = new BigNumber(Math.floor(Math.random() * 10000))
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

  it('should be ended only after end', async function () {
    let ended = await this.crowdsale.hasEnded()
    ended.should.equal(false)
    await increaseTimeTo(this.afterEndTime)
    ended = await this.crowdsale.hasEnded()
    ended.should.equal(true)
  })

  it('should reject payments before start', async function () {
    var contribution = new BigNumber(Math.floor(Math.random() * 100000))
    await this.crowdsale.send(contribution).should.be.rejectedWith(EVMThrow)
    await this.crowdsale.buyTokens(accounts[4], {from: accounts[5], value: contribution}).should.be.rejectedWith(EVMThrow)
  })

  it('should accept payments after start', async function () {
    var presale1 = new BigNumber(Math.floor(Math.random() * 10000))
    var presale2 = new BigNumber(Math.floor(Math.random() * 10000))
    await this.crowdsale.logOffChainPresale(accounts[3], presale1, {from: accounts[1]})
    await this.crowdsale.logOffChainPresale(accounts[4], presale2, {from: accounts[1]})
    let post = await this.crowdsale.totalRaised()
    await this.crowdsale.setRate({from: accounts[1]})
    var contribution = new BigNumber(Math.floor(Math.random() * 100000))
    let ret = await this.crowdsale.getRate()
    await increaseTimeTo(this.startTime)
    await this.crowdsale.sendTransaction({value: contribution, from: accounts[5]}).should.be.fulfilled
  })

  it('should reject payments after end', async function () {
    var contribution = new BigNumber(Math.floor(Math.random() * 100000))
    await increaseTimeTo(this.afterEndTime)
    await this.crowdsale.send(contribution).should.be.rejectedWith(EVMThrow)
    await this.crowdsale.buyTokens(accounts[4], {value: contribution, from: accounts[5]}).should.be.rejectedWith(EVMThrow)
  })

})

