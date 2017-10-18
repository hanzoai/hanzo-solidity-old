/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.

In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.

2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.

.*/

import 'zeppelin-solidity/contracts/token/MintableToken.sol';

pragma solidity ^0.4.8;

contract NamedMintableToken is MintableToken{

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    bytes32 public name;
    bytes32 public symbol;
    string public version = 'H1.0';       //Hanzo 1.0 standard. Just an arbitrary versioning scheme.
    mapping(address => bool) public minters;
    address public auditor;

    modifier onlyFounders() {
        require(msg.sender == owner || msg.sender == auditor);
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender]);
        _;
    }

    function addMinter(address minter) onlyFounders public returns(bool) {
        minters[minter] = true;
        return true;
    }

    function removeMinter(address minter) onlyFounders public returns(bool) {
        minters[minter] = false;
        return true;
    }

    function NamedMintableToken(
        bytes32 _tokenName,
        bytes32 _tokenSymbol,
        address _owner,
        address _auditor
        ) {
        name = _tokenName;                                   // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        owner = _owner;
        auditor = _auditor;
        minters[_owner] = true;
        minters[_auditor] = true;
        minters[msg.sender] = true;
    }

    function mint(address _to, uint256 _amount) onlyMinters canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}
