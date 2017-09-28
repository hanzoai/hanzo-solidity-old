pragma solidity ^ 0.4.13;

contract ContributorCache{

    struct Contributor {
        address addr;
        uint256 contribution;
        uint listPointer;
    }

    mapping(address => Contributor) public contributors;
    address[] public contributorList;

    function isContributor(address contributorAddress) public constant returns(bool hasContribution) {
        if(contributorList.length==0) return false;
        return (contributorList[contributors[contributorAddress].listPointer] == contributorAddress);
    }

    function getContributorCount() public constant returns(uint contributorCount) {
        return contributorList.length;
    }

    function getContribution(address contributor) public constant returns(uint256) {
        return contributors[contributor].contribution;
    }

    function newContributor(address contributorAddress, uint256 contribution) public returns(bool success) {
        if(isContributor(contributorAddress)) return false;
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

    function deleteContribution(address contributorAddress) public returns(bool success) {
        if(!isContributor(contributorAddress)) return false;
        uint rowToDelete = contributors[contributorAddress].listPointer;
        address keyToMove = contributorList[contributorList.length-1];
        contributorList[rowToDelete] = keyToMove;
        contributors[keyToMove].listPointer = rowToDelete;
        contributorList.length--;
        return true;
    }
}
