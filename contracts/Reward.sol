// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Reward {
  
  address admin;
  address staking;
  IERC20 METALOT;

  constructor() {
    admin = msg.sender;  
  } 

  function setToken(IERC20 _METALOT) public {
    require(msg.sender == admin, "You cant set anything!");
    METALOT = _METALOT;

  }

  function setStakingAddress(address _staking) external{
    require(msg.sender == admin, "You cant set anything!");
    staking = _staking;
    admin = address(0);
  }

  function payTo(address to, uint256 amount) external{
    require(msg.sender == staking, "You cant pay anyone!");
    
    uint256 METALOTBalance = METALOT.balanceOf(address(this));
    if (amount > METALOTBalance) {
        METALOT.transfer(to, METALOTBalance);
    } else {
        METALOT.transfer(to, amount);
    }
  }

  function totalMETALOTInContract() public view returns(uint256){
    return METALOT.balanceOf(address(this));
  }
}
