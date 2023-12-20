// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/**
* @title An abstract contract for contract funding
* @author Fabian Diemand
*
* @notice The abstract contract is intended to fund other contracts (e.g. for demo purposes).
*
* @custom:educational This contract is intended only as an educational piece of work. No productive use is intended.
*/
abstract contract Fundable{

    constructor() {}

    /*
    * @notice Load contract with some eth to be able to payout claims.
    * @param _value The amount of eth to be loaded into the contract.
    * @dev This function is used to fund the contract with some ether for demonstration purposes.
    * @dev It requires the caller to provide a non-zero amount of ether as the `_value` parameter.
    * @dev If the `_value` is provided as zero, the function will revert the transaction.
    */
    function fundContract() public payable requireNonZeroValue {
    }

    /**
     * @dev Modifier to require value of a message being positive (DRY)
     * 
     * @dev Requirements:
     * @dev - The value sent with the message must be greater than zero
     */
    modifier requireNonZeroValue {
        require(msg.value > 0, "Cannot load the contract with 0");
        _;
    }
}