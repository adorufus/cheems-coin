pragma solidity ^0.8.4;

import "./ATokenomics.sol";

abstract contract AntiWhale is Tokenomics {
    function _getAntiwhaleFees(uint256, uint256) internal view returns (uint256) {
        return sumOfFees;
    }
}