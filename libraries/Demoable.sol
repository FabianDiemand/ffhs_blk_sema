// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;


abstract contract Demoable{

    constructor() {}

    /*
    * @dev Load contract with some eth to be able to payout claims.
    * @param _value The amount of eth to be loaded into the contract.
    * @notice This function is used to fund the contract with some ether for demonstration purposes.
    *         It requires the caller to provide a non-zero amount of ether as the `_value` parameter.
    *         If the `_value` is provided as zero, the function will revert the transaction.
    */
    function fundContract() public payable requireNonZeroValue {
    }

    modifier requireNonZeroValue {
        require(msg.value > 0, "Cannot load the contract with 0");
        _;
    }
}