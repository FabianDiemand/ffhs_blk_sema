// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;


import "./libraries/Fundable.sol";
import "./libraries/Utils.sol";

/**
* @title An insurance for solar power
* @author Fabian Diemand
*
* @notice The contract is intended to cover damages in form of additional costs resulting from having to consume power from the mainnet.
* @notice Such damages can result from a lack of sunshine, which limits the power output of photovoltaic panels.
*
* @custom:educational This contract is intended only as an educational piece of work. No productive use is intended.
*/
contract SolarInsurance is Fundable {
    address internal _owner;

    uint256 internal _ENERGY_PRICE = 0.00016 ether; // price of 1 kWh from the mainnet
    uint256 internal _RADIATION_VALUE = 150; // radiation value in watts per square meter
    uint256 internal _EFFICIENCY = 20; // efficiency of the solar module in %

    // SolarInsurancePolicy struct modelling the metadata for a solar insurance policy
    struct SolarInsurancePolicy {
        address client; // The address of the client.
        SwissRegion panelLocation; // The location of the solar panel (0 or 1).
        string locationName; // The location name as a string (Switzerland North or South).
        InsuredRiskLevels riskLevel; // The risk level the client wants to insure (0, 1, 2).
        string riskName; // The risk level name as a string (Low, Mid, High).
        uint256 panelArea; // The area of the solar panel in square meters.
        uint256 premiumToPay; // The premium amount to be paid by the client.
        uint256 registrationDate; // The timestamp of the policy registration.
        uint256 validUntil; // The timestamp until which the policy is valid.
        uint256 claimTimeout; // The timestamp before which no claims can be filed.
    }

    // SolarInsurance Risk Levels (from client perspective)
    struct InsuranceLevel {
        uint256 premium; // The premium per panel square meter per year.
        uint256 insuredHours; // The expected amount of yearly sunshine hours.
    }
    enum InsuredRiskLevels {
        LOW,
        MID,
        HIGH
    }
    mapping(InsuredRiskLevels => InsuranceLevel) _insuranceLevels;

    // Store sunshine duration per region for each year
    // Mapping uses <year>_<SwissRegion> as key, e.g. 2023_SOUTH
    struct SunshineRecord {
        SwissRegion region;
        string regionName;
        uint256 year;
        uint256 sunshineDuration;
    }
    enum SwissRegion {
        SOUTH,
        NORTH
    }
    mapping(string => SunshineRecord) _sunshineRecords;
    // Required to get sunshine records for the demo only!!
    SunshineRecord[] _demoSunshineRecords;

    // Mappings for contracts, clients, claims and payments
    struct Claim {
        uint256 year;
        uint256 amount;
    }
    mapping(address => SolarInsurancePolicy) _policies;
    mapping(address => uint256) _allowedClaims;
    mapping(address => Claim[]) _claims;
    mapping(address => uint256[]) _payments;

    // Create events for write actions to allow debugging on deployed contracts
    event PremiumCalculated(address indexed _from, string riskLevel, uint256 panelArea);
    event PolicyRegistered(address indexed _from, string riskLevel, uint256 panelArea, string location, uint256 value);
    event PolicyExtended(address indexed _from, uint256 value);
    event PolicyDeleted(address indexed _from);
    event ClaimFiled(address indexed _from, uint256 year);
    event DemoClaimFiled(address indexed _from, uint256 year);
    event ClaimRefused(address indexed _from, uint256 year, uint256 insuredHours, uint256 recordedHours);
    event ClaimAccepted(address indexed _from, uint256 year, uint256 insuredHours, uint256 recordedHours);
    event SunshineDurationRecorded(address indexed _from, uint256 year, uint256 duration, string region);

    constructor() {
        _owner = msg.sender;
        // Instantiate the risk levels to be covered
        _insuranceLevels[InsuredRiskLevels.LOW] = InsuranceLevel(
            0.00005 ether, 
            1639 
        );
        _insuranceLevels[InsuredRiskLevels.MID] = InsuranceLevel(
            0.00012 ether,
            1721
        );
        _insuranceLevels[InsuredRiskLevels.HIGH] = InsuranceLevel(
            0.00035 ether,
            1803
        );
    }

    /*
    * @notice Registers a Solar Insurance Policy.
    * 
    * @param riskLevel The risk level of the client (HIGH, MID, LOW).
    * @param panelArea The area of the solar panel in square meters.
    * @param location The location of the solar panel (SOUTH or NORTH).
    * @return void
    * 
    * @dev Requirements:
    * @dev - The client must not be actively insured.
    * @dev - The premium must be covered by the amount of wei sent with the message.
    */
    function registerPolicy(InsuredRiskLevels riskLevel, uint256 panelArea, SwissRegion location) public payable
        requireNotInsured
        requirePremiumCovered(riskLevel, panelArea)
    {
        _policies[msg.sender] = SolarInsurancePolicy(
            msg.sender, // client
            location,
            getRegionNames(location),
            riskLevel,
            getRiskNames(riskLevel),
            panelArea,
            panelArea * _insuranceLevels[riskLevel].premium,
            block.timestamp, // time of registration
            block.timestamp + 365 days, // valid until
            block.timestamp + 365 days // timeout for claims (first claim possible after 1 year)
        );

        uint256 yearInSeconds = 60 * 60 * 24 * 365;
        uint256 epochStartYear = 1970;
        _allowedClaims[msg.sender] = block.timestamp / yearInSeconds + epochStartYear;
        _payments[msg.sender].push(block.timestamp);

        emit PolicyRegistered(msg.sender, getRiskNames(riskLevel), panelArea, getRegionNames(location), msg.value);
    }

    /**
     * @notice Extend an existing Solar Insurance Policy by a year
     * @dev The policy will be extended for another year from the current validUntil timestamp.
     *
     * @dev Requirements:
     * @dev - The client must be insured.
     * @dev - The policy must still be active.
     * @dev - The premium must be covered by the amount of wei sent with the message.
     */
    function extendPolicy() public payable
        requireInsured
        requirePremiumCovered(
            _policies[msg.sender].riskLevel,
            _policies[msg.sender].panelArea
        )
    {
        _policies[msg.sender].validUntil += 365 days;

        emit PolicyExtended(msg.sender, msg.value);
    }

    /**
     * @notice Allows the client to file a claim for insurance for a specific year.
     *
     * @param year The year for which the claim is filed.
     *
     * @dev Requirements:
     * @dev - The client must be insured.
     * @dev - There must be no timeout for client's claims.
     * @dev - The specified year must be claimable by the client.
     * @dev - There must be a recorded sunshine duration for the specified year and region.
     */
    function fileClaim(uint256 year) public
        requireInsured
        requireNoClaimTimeout
        requireYearClaimable(year)
        requireRecordExists(year, _policies[msg.sender].panelLocation)
    {
        emit ClaimFiled(msg.sender, year);
        SolarInsurancePolicy memory p = _policies[msg.sender];

        // transfer the claimable amount (in wei)
        uint256 amount = getClaimAmount(year);
        payable(msg.sender).transfer(amount);

        // extend the timeout by one year
        p.claimTimeout += 365 days;
        if (p.validUntil > 0) {
            // add a new year to be allowed for claims, if the validity allows it
            _allowedClaims[msg.sender] += 1;
        }        
    }

    /**
    * @notice Get owner's address
    *
    * @return The address of the contract owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @notice Get details of own policy
    * 
    * @return The SolarInsurancePolicy with the data from the client's policy
    * 
    * @dev Requirements:
    * @dev - The sender must be insured.
    */
    function getPolicyInformation() public view
        requireInsured
        returns (SolarInsurancePolicy memory){
        return _policies[msg.sender];
    }

    /**
    * @notice Calculate the required premium for a Solar Insurance Policy.
    *
    * @param riskLevel The risk level of the client (HIGH, MID, LOW).
    * @param panelArea The area of the solar panel (in square meters).
    * @return The calculated premium in wei.
    */
    function calculatePremium(InsuredRiskLevels riskLevel, uint256 panelArea) public view returns (uint256){
        return panelArea * _insuranceLevels[riskLevel].premium; // premium to pay
    }

    /**
    * @notice Get details of the insured risk (insured hours, premium)
    * 
    * @return The InsuranceLevel specific to a key
    * 
    * @dev Requirements:
    * @dev - The sender must be insured.
    */
    function getInsuredRiskByKey(InsuredRiskLevels riskLevel) public view 
        returns(InsuranceLevel memory)
    {
        return _insuranceLevels[riskLevel];
    }

    /**
    * @notice Get details of the insured risk (insured hours, premium)
    * 
    * @return The InsuranceLevel from the client's policy
    * 
    * @dev Requirements:
    * @dev - The sender must be insured.
    */
    function getInsuredRiskOfPolicy() public view 
        requireInsured
        returns(InsuranceLevel memory)
    {
        InsuredRiskLevels riskLevel = _policies[msg.sender].riskLevel;
        return _insuranceLevels[riskLevel];
    }

    /**
    * @notice Get earliest sunshine record relevant for allowed claims by the sender
    * 
    * @return The earliest Sunshine Record relevant for the client's policy
    * 
    * @dev Requirements:
    * @dev - The sender must be insured.
    */
    function getRelevantSunshineRecords() public view 
        requireInsured
        returns(SunshineRecord memory)
    {
        uint256 claimYear = _allowedClaims[msg.sender];
        SwissRegion region = _policies[msg.sender].panelLocation;

        string memory key = getRecordsKey(claimYear, region);
        return _sunshineRecords[key];
    } 

    /**
     * @notice Calculates the amount of claim in wei that can be filed for the specified year.
     *
     * @dev The claim amount is calculated based on the difference between the insured hours of sunshine in the specified year and region and the recorded sunshine duration,
     * @dev multiplied by the radiation value, the efficiency of the solar module, the panel area, and the energy price.
     * @dev The calculated amount is then divided by 100'000 to account for the efficiency being used as a decimal (/ 100) and the radiation value being used as kilowatts (/ 1000).
     *
     * @dev Requirements:
     * @dev - The client must be insured.
     * @dev - The claim year must be claimable by the client.
     * @dev - There must be a recorded sunshine duration for the specified year and region.
     * 
     * @param year The year for which the claim amount is calculated.
     * @return The amount to be claimed in wei.
     */
    function getClaimAmount(uint256 year) internal returns (uint256) {
        SolarInsurancePolicy memory p = _policies[msg.sender];
        string memory key = getRecordsKey(year, p.panelLocation);

        uint256 sunshineDelta = _insuranceLevels[p.riskLevel].insuredHours - _sunshineRecords[key].sunshineDuration;

        if(sunshineDelta <= 0){
            emit ClaimRefused(msg.sender, year, _insuranceLevels[p.riskLevel].insuredHours, _sunshineRecords[key].sunshineDuration);
            revert();
        }

        uint256 amount = _RADIATION_VALUE * sunshineDelta * _EFFICIENCY * p.panelArea * _ENERGY_PRICE;
        emit ClaimAccepted(msg.sender, year, _insuranceLevels[p.riskLevel].insuredHours, _sunshineRecords[key].sunshineDuration);
        return amount / 100000;
    }

    /**
    * @notice Get the records key for a specific year.
    *
    * @param year The year for which the records key is needed.
    * @return The records key in the format "<year>_<region>", e.g. "2023_SOUTH".
    */
    function getRecordsKey(uint256 year, SwissRegion region) internal view 
        requireInsured
        returns (string memory)
    {
        bool isLocationSouth = region == SwissRegion.SOUTH;
        string memory key = isLocationSouth ? Utils.getRecordId(year, "_SOUTH") : Utils.getRecordId(year, "_NORTH");

        return key;
    }

    /*
    * @notice Get the key for a region in the SwissRegion enum as a string.
    *
    * @param region The region for which the stringified key is needed.
    * @return stringified key of a region.
    */
    function getRegionNames(SwissRegion region) internal pure returns (string memory){
        if(SwissRegion.NORTH == region){
            return "Switzerland North";
        } else { 
            return "Switzerland South";
        }
    }

    /*
    * @notice Get the key for a risk in the InsuredRiskLevels enum as a string.
    *
    * @param region The risk for which the stringified key is needed.
    * @return stringified key of a risk.
    */
    function getRiskNames(InsuredRiskLevels risk) internal view returns (string memory){
        uint256 insuredHours = _insuranceLevels[risk].insuredHours;
        if(InsuredRiskLevels.HIGH == risk){
            return Utils.concatRiskInformation("High", insuredHours);
        } else if(InsuredRiskLevels.MID == risk){
            return Utils.concatRiskInformation("Mid", insuredHours);
        } else {
            return Utils.concatRiskInformation("Low", insuredHours);
        }
    }

    /*
     * @notice Record the sunshine duration for a specific year and region.
     *
     * @param year The year for which the sunshine duration is recorded.
     * @param region The region for which the sunshine duration is recorded (SOUTH or NORTH).
     * @param duration The duration of sunshine in the specified year and region.
     */
    function createSunshineRecord(uint256 year, uint256 duration, SwissRegion region) public
        requireNonExistingRecord(year, region)
     {
        bool isLocationSouth = region == SwissRegion.SOUTH;
        string memory key = isLocationSouth ? Utils.getRecordId(year, "_SOUTH") : Utils.getRecordId(year, "_NORTH");

        SunshineRecord memory record = SunshineRecord(
            region,
            getRegionNames(region),
            year,
            duration
        );

        // The way to handle the record in the intended way for real scenarios
        _sunshineRecords[key] = record;

        // Only done to allow the demo functionality!!
        _demoSunshineRecords.push(record);

        emit SunshineDurationRecorded(msg.sender, year, duration, getRegionNames(region));
    }

    /*
     * @notice File a claim without checking the timeout (for demo purpose only!!)
     * @param year The year for which the claim is filed.
     * @return claimAmount The amount of the claim in wei.
     *
     * @dev Requirements:
     * @dev - Client must be insured.
     * @dev - Client must be allowed to file a claim for the specified year.
     * @dev - There must be a recorded sunshine duration for the specified year and region.
     */
    function fileClaimWithoutChecks(uint256 year) public
        requireInsured
        requireRecordExists(year, _policies[msg.sender].panelLocation) {
        emit DemoClaimFiled(msg.sender, year);

        // Calculate the claim amount
        uint256 claimAmount = getClaimAmount(year);

        // Transfer the claim amount to the client
        payable(msg.sender).transfer(claimAmount);

        // Update the claim timeout and allowed claims for the client
        _policies[msg.sender].claimTimeout += 365 days;
        if (_policies[msg.sender].validUntil > 0) {
            _allowedClaims[msg.sender] += 1;
        }
    }

    /**
    * @notice Get sunshine record relevant for allowed claims by the sender without checking allowed claims (for demo purpose only!!)
    * 
    * @return The earliest Sunshine Record relevant for the client's policy
    * 
    * @dev Requirements:
    * @dev - The sender must be insured.
    */
    function getRelevantSunshineRecordsWithoutChecks() public view 
        requireInsured
        returns(SunshineRecord[] memory)
    {           
        return _demoSunshineRecords;
    } 

    /*
     * @notice Delete a policy (for demo purpose only!!)
     *
     * @dev Requirements:
     * @dev - Client must be insured.
     */
    function deletePolicy() public 
        requireInsured {

        emit PolicyDeleted(msg.sender);
        delete _policies[msg.sender];
    }

    /*
     * @notice Modifier to require sender being the owner (DRY)
     * 
     * @dev Requirements:
     * @dev - Sender must be owner.
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
    * @dev Modifier to require a valid sender address (DRY)
    *
    * @dev Requirements:
    * @dev - Sender must have an address other than the zero-address
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
     * @dev Requirements:
     * @dev - Wei of message must cover the premium.
     */
    modifier requirePremiumCovered(InsuredRiskLevels riskLevel, uint256 panelArea) {
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
     * @dev Requirements:
     * @dev - There must be no active policy registered for the senders address
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
     * @dev Requirements:
     * @dev - There must be a policy registered for the sender address
     * @dev - The registered policy must still be active
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
     * @dev Requirements:
     * @dev - A sunshine duration must be recorded for a given year
     */
    modifier requireRecordExists(uint256 year, SwissRegion region) {
        string memory key = getRecordsKey(year, region);

        bool recordExists = _sunshineRecords[key].sunshineDuration != 0;
        require(
            recordExists,
            "There is no record for the required year or region."
        );
        _;
    }

    /**
     * @dev Modifier to require the sender being insured already (DRY)
     * 
     * @dev Requirements:
     * @dev - There must be a policy registered for the sender address
     * @dev - The registered policy must still be active
     */
    modifier requireNoClaimTimeout() {
        bool claimsOnTimeout = _policies[msg.sender].claimTimeout < block.timestamp;
        require(
            !claimsOnTimeout,
            "Claims can only be filed every year."
        );
        _;
    }

    /**
     * @dev Modifier to require a year to be claimable by the sender (DRY)
     * 
     * @dev Requirements:
     * @dev - The given year must be in the list of allowed claims for the sender
     */
    modifier requireYearClaimable(uint256 year) {
        bool isYearClaimable = _allowedClaims[msg.sender] == year;
        require(
           isYearClaimable,
            "The specified year is not allowing a claim for your policy."
        );
        _;
    }

    /**
     * @dev Modifier to require a record to not already being existent (DRY)
     * 
     * @dev Requirements:
     * @dev - The given record must not already be part of the sunshine records
     */
    modifier requireNonExistingRecord(uint256 year, SwissRegion region) {
        bool isLocationSouth = region == SwissRegion.SOUTH;
        string memory key = isLocationSouth ? Utils.getRecordId(year, "_SOUTH") : Utils.getRecordId(year, "_NORTH");
        
        bool isRecordExisting = _sunshineRecords[key].year > 0;

        require(
            !isRecordExisting,
            "Cannot create the record, due to a clash with an already existing record."
        );
        _;
    }
}
