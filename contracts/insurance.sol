// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract Insurance {
    address[] public holders;

    mapping(address => uint256) public policies;
    mapping(address => uint256) public claims;

    struct Test{
        uint b;
        bool t;
    }

    mapping(address => Test) _test;

    address payable owner;
    uint256 public totalPrem;

    constructor() {
        owner = payable(msg.sender);
    }

    function testCreate() public {
        _test[msg.sender].b = block.timestamp;
    }

    function test() public view returns(Test memory){
        return _test[msg.sender];
    }

    function registerPolicy(uint256 premium) public payable {
        require(msg.value == premium, "Incorrect premium ammount");
        require(premium > 0, "Premium amount must be greater than 0.");
        
        holders.push(msg.sender);
        policies[msg.sender] = premium;
        totalPrem += premium;
    }

    function claim(uint256 amount) public {
        require(policies[msg.sender] > 0, "Must have a valid policy to claim");
        require(amount > 0, "Claim amount must be greater than 0.");
        require(amount <= policies[msg.sender], "Claim amount cannot exceed policy.");

        claims[msg.sender] += amount;
    }

    function approveClaim(address holder) public {
        require(msg.sender == owner, "Only the owner can approve claims.");
        require(claims[holder] > 0, "Holder has no outstanding claims.");

        payable(holder).transfer(claims[holder]);
        claims[holder] = 0;
    }

    function getPolicy(address holder) public view returns (uint256){
        return policies[holder];
    }

    function getClaim(address holder) public view returns (uint256){
        return claims[holder];
    }

    function getTotalPremium() public view returns (uint256){
        return totalPrem;
    }

    function grantAccess(address payable user) public {
        require(msg.sender == owner, "Only owner can grant access.");
        owner = user;
    }

    function revokeAccess(address payable user) public {
        require(msg.sender == owner, "Only owner can revoke access");
        require(user != owner, "Cannot revoke access for the current owner.");

        owner = payable(msg.sender);
    }
}