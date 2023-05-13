// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ILotery{
  function buyNumber(address newReferrer, uint cant)external;
}

contract Player{
  IERC20 coin = IERC20(0xD6920eeAF9b9bc7288765F72B4d6Da3e47308464);
  
  constructor(address lotery ){
    coin.approve(lotery, 500000000 * 1 ether);
  }

  function playLotery(address _lotery, uint cant) public{
    ILotery(_lotery).buyNumber(address(0),cant);
  }
  function playLoterySelecRefer(address refer, address _lotery) public{
    ILotery(_lotery).buyNumber(refer,1);
  }

  function fakeRandom()public view returns(uint){
    uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        ) % 6 ;
    return (answer == 0 ? 1:  answer);
  }
  function aprovess(address lotery) public {
    coin.approve(lotery, 500000000 * 1 ether);
  }
}

contract CreatePlayersInLotery{
  
  Player[] public players;
  IERC20 public currenci = IERC20(0xD6920eeAF9b9bc7288765F72B4d6Da3e47308464);
  uint public counter;
  address public loteryAdrress;

  constructor(address _lotery){
    loteryAdrress = _lotery;
  }

  function factory() public{
    Player player = new Player(loteryAdrress);
    currenci.transfer(address(player), 2000 * 1 ether);
    players.push(player);
  }
  function factoryInBath(uint cant) public{
   for(uint i; i < cant; i++){
       factory();
   }
  }

  function playAux(uint start, uint finish, uint cant)public {   
    for(uint i=start; i < finish; i++){   
      players[i].playLotery(loteryAdrress, cant);
    }
  }

  function playRefers(address refer, uint start, uint finish)public {   
    for(uint i=start; i < finish; i++){   
      players[i].playLoterySelecRefer(refer,loteryAdrress);
    }
  }
  
  function playAproves(address lotery, uint start, uint finish)public {   
    for(uint i=start; i < finish; i++){   
        players[i].aprovess(lotery);       
    }
  }

  function SLoteryAdrress(address _lotery)public {
    loteryAdrress = _lotery;
  }
  function VTotalPlayers() external view returns(uint){
    return players.length;
  }
  function VPlayersList() external view returns(Player[] memory){
    return players;
  }

}