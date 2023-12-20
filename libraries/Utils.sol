// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/utils/Strings.sol";

library Utils {
    function getRecordId(uint256 year, string memory region) internal pure returns(string memory){
        return string.concat(Strings.toString(year), region);
    }
}