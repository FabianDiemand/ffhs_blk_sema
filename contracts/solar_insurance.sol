// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SolarInsurance{
    using SafeMath for uint256;
    using SafeMath for uint8;

    address internal _owner;

    uint256 ENERGY_PRICE = 0.00016 ether; // price of 1 kWh from the mainnet
    uint256 RADIATION_VALUE = 150; // radiation value in watts per square meter
    uint256 EFFICIENCY = 20; // efficiency of the solar module in %

    // SolarInsurance Policy
    struct SolarInsuranceContract {
        address client;
        SwissRegion panelLocation;
        ClientRiskLevels riskLevel;
        uint256 panelArea;
        uint256 premiumToPay;
        uint256 registrationDate;
        uint256 duration;
        uint256 claimTimeout;
    }

    // SolarInsurance Risk Levels (from client perspective)
    struct InsuranceLevel {
        uint256 premium;
        uint256 insuredHours;
    }
    enum ClientRiskLevels { HIGH, MID, LOW }
    mapping(ClientRiskLevels => InsuranceLevel) _insuranceLevels;

    // Store sunshine duration per region for each year
    // Mapping uses <year>_<SwissRegion> as key, e.g. 2023_SOUTH
    enum SwissRegion { SOUTH, NORTH }
    mapping(string => uint256) public _sunshineRecords;

    // Mappings for contracts, clients, claims and payments
    struct Claim{
        uint256 year; 
        uint256 amount;
    }
    mapping(address => SolarInsuranceContract) _contracts;
    mapping(address => uint256) public _allowedClaims;
    mapping(address => Claim[]) claims;
    mapping(address => uint256[]) _payments;

    constructor() payable {
        _owner = msg.sender;
        _insuranceLevels[ClientRiskLevels.HIGH] = InsuranceLevel(
            0.00005 ether,
            1639
        );

        _insuranceLevels[ClientRiskLevels.MID] = InsuranceLevel(
            0.00012 ether,
            1721
        );

        _insuranceLevels[ClientRiskLevels.LOW] = InsuranceLevel(
            0.00035 ether,
            1803
        );
    }

    function owner() public view requireOwner() returns(address){
        return _owner;
    }

    /**
    * @dev Register for Solar Insurance Policy
    */
    function registerPolicy(ClientRiskLevels riskLevel, uint256 panelArea, SwissRegion location) public payable 
        requireNotInsured
        requirePremiumCovered(riskLevel, panelArea) {

        _contracts[msg.sender] = SolarInsuranceContract(
            msg.sender, // client
            location, 
            riskLevel, 
            panelArea, // in square meters
            panelArea * _insuranceLevels[riskLevel].premium, // premium to pay
            block.timestamp, // time of registration
            block.timestamp.add(1 * 365 days), // end of insurance
            block.timestamp.add(1 * 365 days) // timeout for claims (first claim possible after 1 year)
        );

        _allowedClaims[msg.sender] = block.timestamp/(60 * 60 * 24 * 365) + 1970;
        _payments[msg.sender].push(block.timestamp);
    }

    /**
    * @dev Renew Solar Insurance Policy
    */
    function renewPolicy() public payable
        requireInsured
        requirePremiumCovered(_contracts[msg.sender].riskLevel, _contracts[msg.sender].panelArea) {

        _contracts[msg.sender].duration.add(1 * 365 days);
    }

    /**
    * @dev File Claim for Insurance
    */
    function fileClaim(uint256 year) public 
        requireInsured
        requireClaimPossible
        requireAllowedClaim(year)
        requireRecordExists(year) {
        
        SolarInsuranceContract memory c = _contracts[msg.sender];

        string memory key = c.panelLocation == SwissRegion.SOUTH ? string.concat(Strings.toString(year), "_SOUTH") : string.concat(Strings.toString(year), "_NORTH");

        uint256 sunshineDuration = _sunshineRecords[key];
        uint256 sunshineDelta = _insuranceLevels[c.riskLevel].insuredHours - sunshineDuration;
        require(sunshineDelta > 0, "The sunshine duration was equal to or exceeded the insured hours.");

        uint256 amount = RADIATION_VALUE/1000 * sunshineDelta * EFFICIENCY/100 * _contracts[msg.sender].panelArea * ENERGY_PRICE;
        payable(msg.sender).transfer(amount);

        c.claimTimeout.add(1 * 365 days);
        if(c.duration > 0){
            _allowedClaims[msg.sender] += 1;
        }
    }

    function createSunshineRecord(uint256 year, SwissRegion region, uint256 duration) public {
        string memory key = region == SwissRegion.SOUTH ? string.concat(Strings.toString(year), "_SOUTH") : string.concat(Strings.toString(year), "_NORTH");
        _sunshineRecords[key] = duration;
    }

    /**
    * @dev Get details of own contract
    */
    function getSolarInsurance() public 
        requireInsured view returns (SolarInsuranceContract memory){
        return _contracts[msg.sender];
    }

    /**
    * @dev Get required premium
    */
    function getRequiredPremium(ClientRiskLevels riskLevel, uint256 panelArea) public view returns (uint256) {
        return panelArea * _insuranceLevels[riskLevel].premium; // premium to pay
    }

    /**
    * @dev Load contract with some eth to be able to payout claims (for demo purpose only!!)
    */
    function fundContract() public payable {
        require(msg.value > 0, "Cannot load the contract with 0");
    }

    /**
    * @dev File a claim without checking the timeout (for demo purpose only!!)
    */
    function fileClaimWithoutTimeoutCheck(uint256 year) public 
        requireInsured
        requireAllowedClaim(year)
        requireRecordExists(year) {
        
        uint256 claimAmount = getClaimAmount(year);
        payable(msg.sender).transfer(claimAmount);

        _contracts[msg.sender].claimTimeout.add(1 * 365 days);
        if(_contracts[msg.sender].duration > 0){
            _allowedClaims[msg.sender] += 1;
        }
    }

    function getClaimAmount(uint256 year) public view returns(uint256) {
        SolarInsuranceContract memory c = _contracts[msg.sender];

        string memory key = c.panelLocation == SwissRegion.SOUTH ? string.concat(Strings.toString(year), "_SOUTH") : string.concat(Strings.toString(year), "_NORTH");

        uint256 sunshineDuration = _sunshineRecords[key];
        uint256 sunshineDelta = _insuranceLevels[c.riskLevel].insuredHours - sunshineDuration;
        uint256 amount = RADIATION_VALUE * sunshineDelta * EFFICIENCY * _contracts[msg.sender].panelArea * ENERGY_PRICE;
        return amount/100000;
    }
    
    /**
    * @dev Extract logic to require owner (DRY)
    */
    modifier requireOwner(){
        require(
            msg.sender == _owner, 
            "Only the contract owner is allowed to do the desired action.");
        _; 
    }

    /**
    * @dev Extract logic to require premium coverage (DRY)
    */
    modifier requirePremiumCovered(ClientRiskLevels riskLevel, uint256 panelArea){
        uint256 prem = _insuranceLevels[riskLevel].premium * panelArea;
        require(
            msg.value == prem, 
            "The premium must be covered to register or renew a policy.");
        _; 
    }

    /**
    * @dev Extract logic to require not yet insured client (DRY)
    */
    modifier requireNotInsured(){
        require(
            _contracts[msg.sender].duration == 0 || _contracts[msg.sender].duration < block.timestamp, 
            "The client is already insured.");
        _;
    }

    /**
    * @dev Extract logic to require insured client (DRY)
    */
    modifier requireInsured(){
        require(
            _contracts[msg.sender].duration > 0 && _contracts[msg.sender].duration > block.timestamp, 
            "The client is not insured.");
        _;
    }

    modifier requireRecordExists(uint256 year){
        string memory key = _contracts[msg.sender].panelLocation == SwissRegion.SOUTH ? string.concat(Strings.toString(year), "_SOUTH") : string.concat(Strings.toString(year), "_NORTH");

        require(
            _sunshineRecords[key] != 0, 
            "There is no record for the required year.");
        _;
    }

    modifier requireClaimPossible(){
        require(
            _contracts[msg.sender].claimTimeout < block.timestamp, 
            "Claims can only be filed every year." );
        _;
    }

    modifier requireAllowedClaim(uint256 year){
        require(_allowedClaims[msg.sender] == year, "You cannot file a claim for the desired year.");
        _;
    }
}