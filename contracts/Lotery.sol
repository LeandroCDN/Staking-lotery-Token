// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/RandomGenerator.sol";

// TODO:  Integrar swaps
contract Lotery is Ownable{

  uint public ticketCost;
  uint public actualNumber = 1; 

  uint public stableFee; //in percernt  
  uint public stablePrice; // in percent

  uint public teamFee = 160; // 16%
  uint public pricePercent = 420; //42%
  uint public burnPercent = 420; //42%

  uint public totalPrice;
  uint public totalFee;

  uint[] public winersNumbers; 
  uint[] public percentForWiners;
  uint32 public cantOfNumbers = 3; //cant of winers per gift
  bool public withStable = true;
  bool public whiteList;

  address caller;
  address manager = msg.sender;
  address[] public LastAddressWiners; 
  address[] list;
  IERC20 public ticketCoin;
  IERC20 public priceCoin;
  RandomGenerator public vrf;
  mapping(uint => address) public numberOwner;
  mapping(address=>uint) public referralsBuys;
  mapping(address=>address) public referrer;

  event BuyNumber(uint number, address buyer, address ref);
  event Winners(uint[] winNumbers, address[] winners);
 
  constructor ( uint _ticketCost){     
    ticketCost = _ticketCost;
  }

  function setticketCoin(IERC20 _ticketCoin, IERC20 _priceCoin) public onlyOwner{
    ticketCoin = _ticketCoin;
    priceCoin = _priceCoin;
  }

  function setVRF(RandomGenerator _vrf) public onlyOwner{
    vrf = _vrf;
  }

  function buyNumber(address newReferrer) public {
    ticketCoin.transferFrom(msg.sender, address(this), ticketCost);
    _newTiket( msg.sender);
    address ref;
    if(newReferrer != msg.sender){
      ref=referralSystem(newReferrer);
    }
    if(withStable){
      totalPrice = totalPrice + (ticketCost * stablePrice) / 100;
      totalFee = totalFee + (ticketCost * stableFee) / 100;      
    }

    if(whiteList){
      bool inList;
      for(uint i; i < list.length; i++){
        if(list[i]==msg.sender){
          inList = true;
        }
      }
      if(!inList){
        list.push(msg.sender);
      }
    }
    emit BuyNumber(actualNumber-1, msg.sender, ref);
  }

  function selectNumbers() public {
    require(msg.sender == caller, "You dont are de caller");    
    vrf.requestRandomWords(cantOfNumbers);
  }

  function finishPlay(uint[] memory randomNumber) public {
    require(msg.sender == address(vrf), "You dont are de caller");
    winersNumbers = randomNumber;    
    winersVerifications(randomNumber);
   
   //Contorlar resultados repetidos
    for(uint i; i < randomNumber.length; i++){       
      priceCoin.transfer( LastAddressWiners[i], winAmount(i));
    }

    actualNumber = 1;
    emit Winners(winersNumbers, LastAddressWiners);
  }

  function winersVerifications(uint[] memory randomNumber) internal {
    delete LastAddressWiners;
    
    for(uint i; i < randomNumber.length; i++){
       uint subWinerNumber = (randomNumber[i] % actualNumber) + 1 ;
      //first number enther in Winumbers and save the winner addres in an  array
      if(i == 0){ 
        winersNumbers[i] = subWinerNumber ; 
        LastAddressWiners.push(numberOwner[winersNumbers[i]]);
      }
      else{
        for(uint j; j < i; j++){ 
          if( winersNumbers[j] == subWinerNumber ){
            if (subWinerNumber == actualNumber){ subWinerNumber == 0; }
            subWinerNumber++;
            j = 0; //Reset loop to check the new number 
          }
          
          if( winersNumbers[0] == subWinerNumber ){
            subWinerNumber++;
          }

          if( LastAddressWiners[j] == numberOwner[subWinerNumber]){
            if (subWinerNumber == actualNumber){ subWinerNumber == 0; }
            subWinerNumber++;
            j = 0;
          }          
        }
        winersNumbers[i]=subWinerNumber;
        LastAddressWiners.push(numberOwner[winersNumbers[i]]);
      }
    }    
  }

  function toggleWhiteList() public onlyOwner{
    whiteList = !whiteList;
  }

  // TODO > WIN AMOUNT view Function
  function winAmount(uint i) public view returns(uint){
    uint amount;
    if(withStable){
      amount = (totalPrice * percentForWiners[i]) / 100;
    }else{
      
    }
    return amount;
  }

  function viewWhiteList() public view returns(address[] memory){
    return list;
  }

  function withDrawhticketCoins() public  onlyOwner{
    ticketCoin.transfer(msg.sender, ticketCoin.balanceOf(address(this)));
  }

  function setCantOfNumbers(uint32 _cantOfNumbers) public onlyOwner{
    cantOfNumbers = _cantOfNumbers;
  }

  function setPercentForWiners(uint[] memory _percentForWiners) public onlyOwner{
    percentForWiners = _percentForWiners;
    setCantOfNumbers(uint32(_percentForWiners.length));
  }

  function setCaller(address _caller) public onlyOwner {
    caller = _caller;
  }

  function setStableFee(uint newStableFee) public onlyOwner{
    stableFee = newStableFee;
    stablePrice = 100-newStableFee;
  }

  // internal functions
  function _newTiket(address tiketFor) public {
    numberOwner[actualNumber] = tiketFor;
    
    actualNumber++;
  }

  //function de comprar voleto automatico para referentes
  function referralSystem(address newReferrer) public returns(address){
    address RealReferrer = referrer[msg.sender];

    if(RealReferrer == address(0)){
      if(newReferrer != address(0) ){
        referrer[msg.sender] = newReferrer;
        referralsBuys[newReferrer]++;
        RealReferrer = newReferrer;
      }
    }else{
      referralsBuys[RealReferrer]++;
    }
//why this dont work?
    if((referralsBuys[RealReferrer] == 3) || (referralsBuys[newReferrer] == 3) ){
     _newTiket( RealReferrer); 
     delete referralsBuys[RealReferrer];
    }
    return RealReferrer;
  }
}
