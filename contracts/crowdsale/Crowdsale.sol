pragma solidity ^ 0.4.13;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/MintableToken.sol';

contract Crowdsale {

    using SafeMath for uint256;

    MintableToken public token;

    // The start and end time that contributions are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // The wallet owned by the person selling the tokens.
    address public merchant;

    // The wallet owned by the third party enforcing ethical behavior.
    address public auditor;
    // The percentage fee the auditor receives for services. Expressed in
    // something like '5'.
    uint private auditorFee;

    // Amount raised in presale (off-blockchain) period
    uint256 public presaleRaised;

    // Amount raised in token sale
    uint256 public tokenSaleRaised;

    event PresalePurchase(address indexed beneficiary, uint256 amount, string
                          tokenName);

    function Crowdsale(uint256 _startTime, uint256 _endTime, address _merchant,
                      address _auditor, uint _auditorFee)
    {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_merchant != 0x0);
        require(_auditor != 0x0);
        require(_auditorFee < 100);

        token = createTokenContract();
        startTime = _startTime;
        endTime = _endTime;
        merchant = _merchant;
        auditor = _auditor;
        auditorFee = _auditorFee;
    }

    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }

    // fallback function can be used to buy tokens
    function () payable {
       buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        tokenSaleRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

    function totalRaised() public constant returns (uint256) {
        return presaleRaised.add(tokenSaleRaised);
    }

    function logPresale(address beneficiary, uint256 amount) public {
        require(msg.sender == auditor);
        PresalePurchase(beneficiary, amount, "token name");
    }
}
