pragma solidity ^0.8.4;

import "./Cheems-token-imports.sol";

abstract contract Tokenomics {
    using SafeMath for uint256;

    string internal constant NAME = "Cheems";
    string internal constant SYMBOL = "CHMS";

    uint16 internal constant FEES_DIVISOR = 10**4;
    uint8 internal constant DECIMALS = 12;
    uint256 internal constant ZEROES = 10**DECIMALS;
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant TOTAL_SUPPLY = 1000000000000 * ZEROES;
    uint256 internal _reflectedSupply = (MAX - (MAX % TOTAL_SUPPLY));
    uint256 internal constant maxTransactionAmount = TOTAL_SUPPLY;
    uint256 internal constant maxWalletBalance = TOTAL_SUPPLY;
    uint256 internal constant numberOfTokensToSwapToLiquidity = TOTAL_SUPPLY / 1000;
	address internal burnAddress = 0x0000000000000000000000000000000000000000;

    enum FeeType {AntiWhale, Burn, Liquidity, Rfi, External, ExternalToETH}
    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    uint256 internal sumOfFees;

    constructor() {
        _addFees();
    }

    function _addFee(FeeType name, uint256 value, address recipient) private {
        fees.push(Fee(name, value, recipient, 0));
        sumOfFees += value;
    }

    function _addFees() private {
        _addFee(FeeType.Rfi, 300, address(this));
        _addFee(FeeType.Burn, 3, burnAddress);
        _addFee(FeeType.Liquidity, 30, address(this));
    }

    function _getFeesCount() internal view returns (uint256){return fees.length;}

    function _getFeeStruct(uint256 index) private view returns(Fee storage) {
        require(index >= 0 && index < fees.length, "FeeSettings._getFeeStruct: Fee index out of bounds");
        return fees[index];
    }

    function _getFee(uint256 index) internal view returns(FeeType, uint256, address, uint256){
        Fee memory fee = _getFeeStruct(index);
        return (fee.name, fee.value, fee.recipient, fee.total);
    }

    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    function _getCollectedFeeTotal(uint256 index) internal view returns (uint256) {
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
}