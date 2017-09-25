pragma solidity ^ 0.4.13;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

library mappedContributor{

    struct Contributor {
        address addr;
        uint256 contribution;
        uint listpointer;
    }

    mapping(address => Contributor) internal contributors;
    address[] public contributorList;

    function isContributor(address contributorAddress) public constant returns(bool isContributor) {
        if(contributorList.length==0) return false;
        return (contributorList[contributors[contributorAddress].listPointer]
                == contributorAddress);
    }

    function getContributorCount() public constant returns(uint contributorCount) {
        contributorList.length;
    }
    function newContributor(address contributorAddress, uint256 contribution) public returns(bool success) {
        if(isContributor(entityAddress)) return false;
        contributors[contributorAddress].contribution = contribution;
        contributors[contributorAddress].addr = contributorAddress;
        contributors[contributorAddress].listPointer = contributorList.push(contributorAddress) - 1;
        return true;
    }

    function updateContributor(address contributorAddress, uint256 contribution) public returns(bool success) {
        if(!isContributor(contributorAddress)) return false;
        contributors[contributorAddress].contribution = contribution;
        return true;
    }

    function addToContribution(address contributorAddress, uint256 contribution) public returns(bool success) {
        if(!isContributor(contributorAddress)) return false;
        contributors[contributorAddress].contribution = contribution;
        return true;
    }

    function deleteEntity(address entityAddress) public returns(bool success) {
        if(!isEntity(entityAddress)) throw;
        uint rowToDelete = entityStructs[entityAddress].listPointer;
        address keyToMove   = entityList[entityList.length-1];
        entityList[rowToDelete] = keyToMove;
        entityStructs[keyToMove].listPointer = rowToDelete;
        entityList.length--;
        return true;
    }
}
