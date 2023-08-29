// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Context.sol";

contract PopoStaking is Ownable {
    IERC20 POPO;
    mapping(address => uint256) public staked;
    mapping(address => uint256) public claimalbeRewards;
    mapping(address => bool) public stakersKnown;
    address[] public stakers;
    uint256 public rounds = 1;
    uint256 public claimableTime = block.timestamp + 60 * 60 * 8;
    uint256 public claimedAmount;
    function setPopo (address _popo) public onlyOwner{
        POPO = IERC20(_popo);
    }

    function stake (uint256 amount) public {
        require(POPO.balanceOf(msg.sender)>=amount, "insufficient amount");
        POPO.transferFrom(msg.sender, address(this), amount);
        staked[msg.sender] += amount;
        if (stakersKnown[msg.sender] == false){
            stakers.push(msg.sender);
            stakersKnown[msg.sender] = true;
        }
    }

    function unstake (uint256 amount) public {
        require(staked[msg.sender]>=amount, "insufficient amount");
        POPO.transfer(msg.sender, amount);
        staked[msg.sender] -= amount;
    }

    function getCurrentRewards () public view returns(uint256 _rewards){
        _rewards = address(this).balance - claimedAmount;
        return(_rewards);
    }

    function distributeRewards() public onlyOwner{
        uint256 rewards = address(this).balance - claimedAmount;
        uint256 totalStaked = POPO.balanceOf(address(this));
         for (uint i =0; i<stakers.length; i++){
            claimalbeRewards[stakers[i]] += rewards * staked[stakers[i]] / totalStaked;
        }
        rounds ++;
        claimableTime = block.timestamp + 60 * 60 * 8;
        claimedAmount += rewards;
    }

    function resetClaimableTime() public onlyOwner{
        claimableTime = block.timestamp + 60 * 60 * 8;
    }

    function claim(address payable wallet) public{
        require(claimalbeRewards[wallet] > 0, "Nothing to Claim");
        wallet.transfer(claimalbeRewards[wallet]);
        claimedAmount -= claimalbeRewards[wallet];
        claimalbeRewards[wallet] = 0;
    }

    function emergencyWithdraw (address payable wallet) public onlyOwner{
        uint256 ETHbalance = address(this).balance;
        wallet.transfer(ETHbalance);
    }
    receive() external payable {}

}
