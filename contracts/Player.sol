// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILotery{
  function buyNumberBath(address newReferrer, uint cant)external;
}

contract Player{
  IERC20 coin;
  
  constructor(address lotery ){
    coin.approve(lotery, 500000 * 1 ether);
  }

  function playLotery(address _lotery) public{
    ILotery(_lotery).buyNumberBath(address(this),fakeRandom());
  }
  function playLoterySelecRefer(address refer, address _lotery) public{
    ILotery(_lotery).buyNumberBath(refer,1);
  }

  function fakeRandom()public view returns(uint){
    uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 6 ;
    return (answer == 0 ? 1:  answer);
  }
}