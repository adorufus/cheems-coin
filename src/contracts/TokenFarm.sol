pragma solidity ^0.8.4;

import "./CheemsToken.sol";
import "./DaiToken.sol";

contract TokenFarm {
    string public name = "Cheems Token Farm";
    address owner;
    CheemsToken public cheemsToken;
    DaiToken public daiToken;

    address[] public stakers;

    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(CheemsToken _cheemsToken, DaiToken _daiToken) {
        cheemsToken = _cheemsToken;
        daiToken = _daiToken;
        owner = msg.sender;
    }

    //1. stake
    function stakeToken(uint amount) public {
        //check if amount more than 0
        require(amount > 0, "amount cannot be 0");

        //transfer Mock Dai tokens to this contract for staking
        daiToken.transferFrom(msg.sender, address(this), amount);

        //update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + amount;

        //add user to list of stakers only if they haven't staked in this DeFi
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    //2. unstake
    function unstakeToken() public {
        //fetch staking balance
        uint balance = stakingBalance[msg.sender];
        
        //require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        daiToken.transfer(msg.sender, balance);

        stakingBalance[msg.sender] = 0;

        isStaking[msg.sender] = false;
    }

    //3. issuing token
    function issueToken() public {
        require(msg.sender == owner, "caller must be the owner");
        for(uint i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance > 0){
                cheemsToken.transfer(recipient, balance);
            }
        }
    }
}