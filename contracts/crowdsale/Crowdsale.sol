pragma solidity ^ 0.4.13;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import '../NamedMintableToken.sol';
import '../data/ContributorCache.sol';

contract Crowdsale {

    using SafeMath for uint256;

    uint constant private feePrecision = 1000;

    NamedMintableToken public token;

    ContributorCache internal cache;

    // The start and end time that contributions are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // The wallet owned by the person selling the tokens.
    address public merchant;

    // The wallet owned by the third party enforcing ethical behavior.
    address public auditor;

    // The percentage fee the auditor receives for services. Whole numbers
    // expressing a percentage up to feePrecision - so at feePrecision = 1000,
    // 5% would be 50, 5.5% is 55, etc.
    uint private auditorFee;

    // Amount raised in presale (off-blockchain) period
    uint256 public presaleRaised;

    // Amount raised in token sale
    uint256 public tokenSaleRaised;

    // How many token units per wei
    // Due to the way we're calculating wei -> tokens, the absolute minimum
    // token can cost is 1 wei. Partial wei doesn't make any sense.
    uint256 public rate;

    // There is always some initial token amount so we can calculate the rate
    // based upon the response to the presale. However, some crowd sales are
    // capped beyond that. If the initial token amount is greater than the
    // tokens reserved for the presale, the crowdsale is considered to have a
    // universal cap and minting will not happen beyond that. See the function
    // isCappedCrowdsale() for this logic in code.
    uint256 public tokensForPresale;
    uint256 public initialTokenAmount;

    event PresalePurchase(address indexed beneficiary, uint256 amount, bytes32
                          tokenName);

    event TokenSalePurchase(address indexed beneficiary, uint256 amount,
                            bytes32 tokenName);

    function Crowdsale(uint256 _startTime, uint256 _endTime, address _merchant,
                       address _auditor, uint _auditorFee, bytes32 _tokenName,
                      bytes32 _tokenSymbol, uint256
                      _initialTokenAmount, uint256 _tokensForPresale)
    {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_merchant != 0x0);
        require(_auditor != 0x0);
        require(_auditorFee < feePrecision);
        require(_initialTokenAmount > 0);
        require(_tokensForPresale > 0);
        require(_tokensForPresale <= _initialTokenAmount);

        token = createTokenContract(_tokenName, _tokenSymbol);
        startTime = _startTime;
        endTime = _endTime;
        merchant = _merchant;
        auditor = _auditor;
        auditorFee = _auditorFee;
        cache = new ContributorCache();
    }

    function isCappedCrowdsale() public returns (bool isCapped) {
        return tokensForPresale != initialTokenAmount;
    }

    function createTokenContract(bytes32 tokenName, bytes32 tokenSymbol) internal returns (NamedMintableToken) {
        return new NamedMintableToken(tokenName, tokenSymbol);
    }

    // fallback function can be used to buy tokens
    function () payable {
       buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());
        require(rate > 0);
        require(auditorFee < feePrecision);

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiToTokens(weiAmount);

        // update state
        tokenSaleRaised = tokenSaleRaised.add(weiAmount);

        token.mint(beneficiary, tokens);

        TokenSalePurchase(msg.sender, weiAmount, token.name());

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        // Reassert some basics here.
        uint256 funds = msg.value;
        // No floating point math in Solidity
        uint256 auditorShare = funds.mul(auditorFee).div(feePrecision);
        auditor.transfer(auditorShare);
        merchant.transfer(funds - auditorShare);
    }

    // @return true if the transaction can buy tokens
    // The rate here is slightly different from normal
    // crowd sales, where the rate is set arbitrarily.
    // Our crowd sales have rates set by the market during
    // a presale period, and thus nothing is valid if that
    // rate has not been established yet. It is also important that anyone who
    // contributed during the presale itself get their tokens first.
    function validPurchase() internal constant returns (bool isValid) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool isRateInitialized = rate != 0;
        bool isNotOversold = isCappedCrowdsale()==false || initialTokenAmount > (token.totalSupply().add(weiToTokens(msg.value)));
        return withinPeriod &&
            nonZeroPurchase &&
            isRateInitialized &&
            isNotOversold;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool isOver) {
        return now > endTime;
    }

    function totalRaised() public constant returns (uint256 totalWeiRaised) {
        return presaleRaised.add(tokenSaleRaised);
    }

    function logOffChainPresale(address beneficiary, uint256 contribution) public returns (bool success){
        require(msg.sender == auditor);
        // Presume they are a new contributor - but add to their contribution
        // if they are not.
        if(cache.newContributor(beneficiary, contribution) == false){
            cache.addToContribution(beneficiary, contribution);
        }
        PresalePurchase(beneficiary, contribution, token.name());
        return true;
    }

    // Fulfills one presale in the cache. Returns the number of contributors
    // left to service.
    function fufillOnePresale() returns (uint remainingPresales) {
        require(msg.sender == auditor || msg.sender == merchant);
        require(rate > 0);

        if(cache.getContributorCount() == 0) {
            return 0;
        }
        // We know there is at least one contributor cached by this point
        address beneficiary = cache.contributorList(0);
        uint256 contribution = cache.getContribution(beneficiary);
        token.mint(beneficiary, contribution);
        cache.deleteContribution(beneficiary);
        return cache.getContributorCount();
    }

    // Skips one presale in the cache, used when a payment to an address
    // is failing for whatever reason so all payments cannot be halted by one
    // bad actor. Returns the number of contributors
    // left to service.
    function skipOnePresale() returns (uint remainingPresales) {
        require(msg.sender == auditor || msg.sender == merchant);
        if(cache.getContributorCount() == 0) {
            return 0;
        }
        // We know there is at least one contributor cached by this point
        address beneficiary = cache.contributorList(0);
        uint256 contribution = cache.getContribution(beneficiary);
        cache.deleteContribution(beneficiary); // Pop the contributor off the top
        cache.newContributor(beneficiary, contribution); // And put them on the end
        return cache.getContributorCount();
    }

    // Since this is set by the market during the presale period,
    // it's worth making an explicit getter to let people know this can be
    // checked.
    function getRate() public returns (uint256 currentRate) {
        return rate;
    }

    // This logic is to convert is in a handful of places, so it should be in a
    // function to keep the logic consistent by default.
    function weiToTokens(uint256 value) private returns (uint256) {
        return value.mul(rate);
    }
}
