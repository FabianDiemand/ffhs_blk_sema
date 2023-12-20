// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libraries/Demoable.sol";
import "../libraries/Utils.sol";

contract SolarInsurance is Demoable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    address internal _owner;

    uint256 internal _ENERGY_PRICE = 0.00016 ether; // price of 1 kWh from the mainnet
    uint256 internal _RADIATION_VALUE = 150; // radiation value in watts per square meter
    uint256 internal _EFFICIENCY = 20; // efficiency of the solar module in %

    // SolarInsurance Policy
    struct SolarInsurancePolicy {
        address client;
        SwissRegion panelLocation;
        ClientRiskLevels riskLevel;
        uint256 panelArea;
        uint256 premiumToPay;
        uint256 registrationDate;
        uint256 validUntil; // validity duration of the policy (can be more than one year, hence the differenciation from the claim timeout)
        uint256 claimTimeout; // limit the claims to one each year
    }

    // SolarInsurance Risk Levels (from client perspective)
    struct InsuranceLevel {
        uint256 premium;
        uint256 insuredHours;
    }
    enum ClientRiskLevels {
        HIGH,
        MID,
        LOW
    }
    mapping(ClientRiskLevels => InsuranceLevel) _insuranceLevels;

    // Store sunshine duration per region for each year
    // Mapping uses <year>_<SwissRegion> as key, e.g. 2023_SOUTH
    enum SwissRegion {
        SOUTH,
        NORTH
    }
    mapping(string => uint256) public _sunshineRecords;

    // Mappings for contracts, clients, claims and payments
    struct Claim {
        uint256 year;
        uint256 amount;
    }
    mapping(address => SolarInsurancePolicy) _policies;
    mapping(address => uint256) public _allowedClaims;
    mapping(address => Claim[]) _claims;
    mapping(address => uint256[]) _payments;

    constructor() {
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

    /**
     * @dev Register for Solar Insurance Policy
     */
    function registerPolicy(ClientRiskLevels riskLevel, uint256 panelArea, SwissRegion location) public payable
        requireNotInsured
        requirePremiumCovered(riskLevel, panelArea)
    {
        _policies[msg.sender] = SolarInsurancePolicy(
            msg.sender, // client
            location,
            riskLevel,
            panelArea,
            panelArea * _insuranceLevels[riskLevel].premium, // premium to pay
            block.timestamp, // time of registration
            block.timestamp.add(1 * 365 days), // valid until
            block.timestamp.add(1 * 365 days) // timeout for claims (first claim possible after 1 year)
        );

        uint256 yearInSeconds = 60 * 60 * 24 * 365;
        uint256 epochStartYear = 1970;
        _allowedClaims[msg.sender] = block.timestamp / yearInSeconds + epochStartYear;
        _payments[msg.sender].push(block.timestamp);
    }

    /**
     * @dev Renew Solar Insurance Policy
     */
    function renewPolicy() public payable
        requireInsured
        requirePremiumCovered(
            _policies[msg.sender].riskLevel,
            _policies[msg.sender].panelArea
        )
    {
        _policies[msg.sender].validUntil.add(365 days);
    }

    /**
     * @dev File Claim for Insurance
     */
    function fileClaim(uint256 year) public
        requireInsured
        requireNoClaimTimeout
        requireYearClaimable(year)
        requireRecordExists(year)
    {
        SolarInsurancePolicy memory p = _policies[msg.sender];

        uint256 amount = getClaimAmount(year);
        payable(msg.sender).transfer(amount);

        p.claimTimeout.add(1 * 365 days);
        if (p.validUntil > 0) {
            _allowedClaims[msg.sender] += 1;
        }
    }

    /**
     * @dev Get owner's address
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Get details of own contract
     */
    function getSolarInsurance() public view
        requireInsured
        returns (SolarInsurancePolicy memory){
        return _policies[msg.sender];
    }

    /**
     * @dev Calculate required premium
     */
    function calculatePremium(ClientRiskLevels riskLevel, uint256 panelArea) public view returns (uint256){
        return panelArea * _insuranceLevels[riskLevel].premium; // premium to pay
    }

        function getClaimAmount(uint256 year) public view returns (uint256) {
        string memory key = getRecordsKey(year);

        SolarInsurancePolicy memory p = _policies[msg.sender];
        uint256 sunshineDelta = _insuranceLevels[p.riskLevel].insuredHours - _sunshineRecords[key];
        uint256 amount = _RADIATION_VALUE * sunshineDelta * _EFFICIENCY * p.panelArea * _ENERGY_PRICE;
        return amount / 100000;
    }

    function getRecordsKey(uint256 year) public view returns (string memory){
        bool isLocationSouth = _policies[msg.sender].panelLocation == SwissRegion.SOUTH;
        string memory key = isLocationSouth ? Utils.getRecordId(year, "_SOUTH") : Utils.getRecordId(year, "_NORTH");

        return key;
    }

    /*
     * @dev Record the sunshine duration for a specific year and region.
     * @param year The year for which the sunshine duration is recorded.
     * @param region The region for which the sunshine duration is recorded (SOUTH or NORTH).
     * @param duration The duration of sunshine in the specified year and region.
     */
    function createSunshineRecord(uint256 year, uint256 duration) public {
        string memory key = getRecordsKey(year);
        _sunshineRecords[key] = duration;
    }

    /*
     * @dev File a claim without checking the timeout (for demo purpose only!!)
     * @param year The year for which the claim is filed.
     * @return claimAmount The amount of the claim in wei.
     *
     * Requirements:
     * - Client must be insured.
     * - Client must be allowed to file a claim for the specified year.
     * - There must be a recorded sunshine duration for the specified year and region.
     */
    function fileClaimWithoutTimeoutCheck(uint256 year) public
        requireInsured
        requireYearClaimable(year)
        requireRecordExists(year) {

        // Calculate the claim amount
        uint256 claimAmount = getClaimAmount(year);

        // Transfer the claim amount to the client
        payable(msg.sender).transfer(claimAmount);

        // Update the claim timeout and allowed claims for the client
        _policies[msg.sender].claimTimeout.add(1 * 365 days);
        if (_policies[msg.sender].validUntil > 0) {
            _allowedClaims[msg.sender] += 1;
        }
    }

    /*
     * @dev Modifier to require sender being the owner (DRY)
     * 
     * Requirements:
     * - Sender must be owner.
     */
    modifier requireOwner() {
        bool senderIsOwner = msg.sender == _owner;
        require(
            senderIsOwner,
            "Only the contract owner is allowed to do the desired action."
        );
        _;
    }

    /*
    * @dev: Modifier to require a valid sender address (DRY)
    *
    * Requirements:
    * - Sender must have an address other than the zero-address
    */
    modifier requireValidAddress(){
        bool isValidAddress = msg.sender != address(0);
        require(
            isValidAddress, 
            "The sender address must be valid."
        );
        _;
    }

    /*
     * @dev Modifier to require the premium being covered by the amount of wei sent with the message (DRY)
     * 
     * Requirements:
     * - Wei of message must cover the premium.
     */
    modifier requirePremiumCovered(ClientRiskLevels riskLevel, uint256 panelArea) {
        // Calculate the premium for the policies risk level and the insured panel area
        uint256 prem = _insuranceLevels[riskLevel].premium * panelArea;
        
        bool premiumCovered = msg.value == prem;
        require(
            premiumCovered,
            "The premium must be covered to register or renew a policy."
        );
        _;
    }

    /**
     * @dev Modifier to require the sender not being insured already (DRY)
     * 
     * Requirements:
     * - There must be no active policy registered for the senders address
     */
    modifier requireNotInsured() {
        bool noPolicyRegistered = _policies[msg.sender].client == address(0);
        bool policyNotActive = _policies[msg.sender].validUntil < block.timestamp;

        require(
            noPolicyRegistered ||  policyNotActive,
            "The client is already insured."
        );
        _;
    }

    /**
     * @dev Modifier to require the sender being insured already (DRY)
     * 
     * Requirements:
     * - There must be a policy registered for the sender address
     * - The registered policy must still be active
     */
    modifier requireInsured() {
        bool policyRegistered = _policies[msg.sender].client != address(0);
        bool policyActive = _policies[msg.sender].validUntil > block.timestamp;

        require(
            policyRegistered && policyActive,
            "The client is not insured."
        );
        _;
    }

    /**
     * @dev Modifier to require an existing sunshine record for a given year (DRY)
     * 
     * Requirements:
     * - A sunshine duration must be recorded for a given year
     */
    modifier requireRecordExists(uint256 year) {
        string memory key = getRecordsKey(year);

        bool recordExists = _sunshineRecords[key] != 0;
        require(
            recordExists,
            "There is no record for the required year."
        );
        _;
    }

    /**
     * @dev Modifier to require the sender being insured already (DRY)
     * 
     * Requirements:
     * - There must be a policy registered for the sender address
     * - The registered policy must still be active
     */
    modifier requireNoClaimTimeout() {
        bool claimsOnTimeout = _policies[msg.sender].claimTimeout < block.timestamp;
        require(
            claimsOnTimeout,
            "Claims can only be filed every year."
        );
        _;
    }

    /**
     * @dev Modifier to require a year to be claimable by the sender (DRY)
     * 
     * Requirements:
     * - The given year must be in the list of allowed claims for the sender
     */
    modifier requireYearClaimable(uint256 year) {
        bool isYearClaimable = _allowedClaims[msg.sender] == year;
        require(
           isYearClaimable,
            "You cannot file a claim for the desired year."
        );
        _;
    }
}
