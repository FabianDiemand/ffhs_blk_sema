// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Sunsurance is ERC20{
    using SafeMath for uint256;
    using SafeMath for uint8;

    address internal _owner;
    IERC20 public immutable xCHF;

    struct SunsuranceContract {
        address _client;
        string _panelLocation;
        uint256 _chfValueContributed;
        uint256 _suntValueReceived;
        uint256 _premiumToPay;
        uint256 _registrationDate;
        uint256 _previousPayment;
        uint256 _nextPayment;
        uint256 _duration;
    }

    uint256 constant MIN_PREM = 20 ether;
    uint256 constant MIN_CLAIM = 1000 ether;
    uint256 constant TOKEN_RATION = 20;

    mapping(address => SunsuranceContract) _contracts;
    mapping(address => bool) _isRegisteredAddress;
    mapping(address => uint256[]) _claims;
    mapping(address => uint256[]) _payments;

    event ContractSigning(address indexed client, uint256 timestamp);


    constructor(address _xCHF) ERC20("SunsuranceToken", "SUNT") {
        _owner = msg.sender;
        xCHF = IERC20(_xCHF);
    }

    /**
    * @dev Extract logic to require owner (DRY)
    */
    modifier requireOwner(){
        require(msg.sender == _owner, "Only the contract owner is allowed to do the desired action.");
        _; 
    }

    /**
    * @dev Extract logic to require sufficient premium (DRY)
    */
    modifier requireGreaterOrEqualPremium(uint256 _xchfAmount){
        require(_xchfAmount >= MIN_PREM, "Premium is not sufficient.");
        _;
    }

    /**
    * @dev Extract logic to require sufficient premium (DRY)
    */
    modifier requireGreaterOrEqualClaim(uint256 _suntAmount){
        require(_suntAmount >= MIN_CLAIM, "Claim is not sufficient.");
        _;
    }

    /**
    * @dev Extract logic to require not yet insured client (DRY)
    */
    modifier requireNotInsured(){
        require(!_isRegisteredAddress[msg.sender], "The client is already insured.");
        _;
    }

    /**
    * @dev Extract logic to require insured client (DRY)
    */
    modifier requireInsured(){
        require(_isRegisteredAddress[msg.sender], "The client is not insured.");
        _;
    }

    /**
    * @dev Extract logic to require payment due (DRY)
    */
    modifier requirePaymentDue(){
        require(block.timestamp >= _contracts[msg.sender]._nextPayment, "Payment is not due yet.");
        _;
    }

    function owner() public view requireOwner() returns(address){
        return _owner;
    }

    /**
    * @dev Register for Sunsurance with a certain amount of xCHF
    */
    function register(uint256 _xchfAmount, string calldata _location, uint8 _durationYears) external requireNotInsured requireGreaterOrEqualPremium(_xchfAmount) {
        // TODO Approval process to be allowed to transfer from another account to this contract ?!
        
        // Assign values to potentially safe gas
        address _sender = msg.sender;
        uint256 _now = block.timestamp;
        uint256 _durationDays = _durationYears.mul(365);
        
        xCHF.transferFrom(_sender, address(this), _xchfAmount);
        uint256 _suntAmount = _xchfAmount.mul(TOKEN_RATION);
        _contracts[_sender] = SunsuranceContract(
            _sender,
            _location,
            _xchfAmount,
            _suntAmount,
            _xchfAmount,
            _now,
            _now,
            _now.add(30 days),
            _now.add(_durationDays * 1 days)
        );

        _isRegisteredAddress[_sender] = true;
        _payments[_sender].push(block.timestamp);

        _mint(_sender, _suntAmount);

        emit ContractSigning(_sender, _now);
    }

    /**
    * @dev Claim Sunsurance insurance
    */
    function claimSunsurance(uint256 _suntAmount) external requireInsured requireGreaterOrEqualClaim(_suntAmount) {
        // TODO
    }

    /**
    * @dev Make payment for the Sunsurance insurance
    */
    function pay(uint _xchfAmount) external requirePaymentDue requireGreaterOrEqualPremium(_xchfAmount) {
        // TODO
    }

    /**
    * @dev Get details of own contract
    */
    function getSunsurance() external requireInsured view returns (SunsuranceContract memory){
        return _contracts[msg.sender];
    }
}