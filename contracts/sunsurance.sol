// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract Sunsurance{
    address internal _owner;

    struct SunsuranceContract {
        address _client;
        uint256 _duration;
        string _panelLocation;
    }

    mapping (address => SunsuranceContract) _contracts;

    constructor() {
        _owner = msg.sender;
    }

    /**
    * @dev Extract logic to require owner (DRY)
    */
    modifier requireOwner(){
        require(msg.sender == _owner, "Only the contract owner is allowed to do the desired action.");

        _; 
    }

    function owner() public view requireOwner() returns(address){
        return _owner;
    }
}