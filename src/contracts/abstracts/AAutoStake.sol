pragma solidity ^0.8.4;

import "./AAntiWhale.sol";
import "./ABaseRfiToken.sol";
import "./ALiquifier.sol";

abstract contract Auto_Stake is BaseRfiToken, Liquifier, AntiWhale {
    using SafeMath for uint256;

    constructor(Env _env){
        initializeLiquiditySwapper(_env, maxTransactionAmount, numberOfTokensToSwapToLiquidity);

        _exclude(_pair);
        _exclude(burnAddress);
    }

    function _isV2Pair(address account) internal view override returns (bool){
        return (account == _pair);
    }

    function _getSumOfFees(address sender, uint256 amount) internal view override returns (uint256) {
        return _getAntiwhaleFees(balanceOf(sender), amount);
    }

    function _beforeTokenTransfer(address sender, address, uint256, bool) internal override {
        uint256 contractTokenBalance = balanceOf(address(this));
        liquify(contractTokenBalance, sender);
    }

    function _takeTransactionFees(uint256 amount, uint256 currentRate) internal override {
        uint256 feesCount = _getFeesCount();
        for(uint256 index = 0; index < feesCount; index++) {
            (FeeType name, uint256 value, address recipient,) = _getFee(index);

            if(value == 0) continue;

            if(name == FeeType.Rfi) {
                _redistribute(amount, currentRate, value, index);
            } else if(name == FeeType.Burn){
                _burn(amount, currentRate, value, index);
            } else if(name == FeeType.AntiWhale){

            } else if(name == FeeType.ExternalToETH) {
                _takeFeeToETH(amount, currentRate, value, recipient, index);
            } else {
                _takeFee(amount, currentRate, value, recipient, index);
            }
        }
    }

    function _burn(uint256 amount, uint256 currentRate, uint256 fee, uint256 index) private {
        uint256 tBurn = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rBurn = tBurn.mul(currentRate);

        _burnTokens(address(this), tBurn, rBurn);
        _addFeeCollectedAmount(index, tBurn);
    }

    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient, uint256 index) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);
        
        _addFeeCollectedAmount(index, tAmount);
    }

    function _takeFeeToETH(uint256 amount, uint256 currentRate, uint256 fee, address recipient, uint256 index) private {
        _takeFee(amount, currentRate, fee, recipient, index);
    }

    function _approveDelegate(address owner, address spender, uint256 amount) internal override {
        _approve(owner, spender, amount);
    }
}