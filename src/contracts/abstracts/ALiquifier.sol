pragma solidity ^0.8.4;

import "./Cheems-token-imports.sol";

abstract contract Liquifier is Ownable, Manageable {

    using SafeMath for uint256;

    uint256 private withdrawableBalance;

    enum Env {Testnet, MainnetV1, MainnetV2}
    Env private _env;

    address private _mainnetRouterV1Address = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;

    address private _mainnetRouterV2Address = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private _testnetRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    IPancakeV2Router internal _router;
    address internal _pair;
    
    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;

    uint256 private maxTransactionAmount;
    uint256 private numberOfTokensToSwapToLiquidity;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event RouterSet(address indexed router);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);

    receive() external payable {}

    function initializeLiquiditySwapper(Env env, uint256 maxTx, uint256 liquifyAmount) internal {
        _env = env;
        if (_env == Env.MainnetV1){ _setRouterAddress(_mainnetRouterV1Address); }
        else if (_env == Env.MainnetV2){ _setRouterAddress(_mainnetRouterV2Address); }
        else { _setRouterAddress(_testnetRouterAddress); }

        maxTransactionAmount = maxTx;
        numberOfTokensToSwapToLiquidity = liquifyAmount;

    }

    function liquify(uint256 contractTokenBalance, address sender) internal {

        if (contractTokenBalance >= maxTransactionAmount) contractTokenBalance = maxTransactionAmount;
        
        bool isOverRequiredTokenBalance = ( contractTokenBalance >= numberOfTokensToSwapToLiquidity );
        
        if ( isOverRequiredTokenBalance && swapAndLiquifyEnabled && !inSwapAndLiquify && (sender != _pair) ){
            _swapAndLiquify(contractTokenBalance);            
        }

    }

    function _setRouterAddress(address router) private {
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(router);
        _pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        _router = _newPancakeRouter;
        emit RouterSet(router);
    }
    
    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);
        
        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function _swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approveDelegate(address(this), address(_router), tokenAmount);

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approveDelegate(address(this), address(_router), tokenAmount);

        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = _router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );

        withdrawableBalance = address(this).balance;
        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }
    
    function setRouterAddress(address router) external onlyManager() {
        _setRouterAddress(router);
    }

    function setSwapAndLiquifyEnabled(bool enabled) external onlyManager {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    function withdrawLockedEth(address payable recipient) external onlyManager(){
        require(recipient != address(0), "Cannot withdraw the BNB balance to the zero address");
        require(withdrawableBalance > 0, "The BNB balance must be greater than 0");

        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        recipient.transfer(amount);
    }

    function _approveDelegate(address owner, address spender, uint256 amount) internal virtual;
}