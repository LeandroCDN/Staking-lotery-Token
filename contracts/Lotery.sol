// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/RandomGenerator.sol";

contract Lotery is Ownable{

  uint public ticketCost;
  uint public actualNumber = 1; 
  uint public minNumber = 5;
  uint public loteryCounter; 
  uint public cantOfAddress;

  uint public stableFee; //in percernt  
  uint public stablePrice; // in percent
  uint public totalPrice;
  uint public totalFee;

  uint[] public winersNumbers; 
  uint[] public percentForWiners;
  uint32 public cantOfNumbers = 3; //cant of winers per gift
  bool public whiteList = true;

  address caller;
  address manager = msg.sender;
  address[] public LastAddressWiners; 
  address[] list;
  IERC20 public ticketCoin;
  RandomGenerator public vrf;
  mapping(uint => address) public ownerOfTiket;
  mapping(address=>uint) public referralsBuys;
  mapping(address=>uint) public referralsAmount;
  mapping(address=>address) public referrer;
  mapping(address=>bool) public referrerSpecialList;
  mapping(address=>uint) public referrerSpecialListAmount;
  mapping(uint=>mapping(address=>bool)) public listOfBuyers;

  event BuyNumber(uint number, address buyer, address ref);
  event Winners(uint[] winNumbers,address[] winners);
 
  constructor ( 
    uint _ticketCost,
    uint _stableFee,
    RandomGenerator _RandomGenerator,
    IERC20 _ticketCoin
    ){     
    ticketCost = _ticketCost;
    caller = msg.sender;
    ticketCoin = _ticketCoin;
    setStableFee(_stableFee);
    vrf = _RandomGenerator;
  }  

  function buyNumber(address newReferrer) public {
    ticketCoin.transferFrom(msg.sender, address(this), ticketCost);
    _newTiket( msg.sender);
    address ref;

    if(newReferrer != msg.sender){
      ref=referralSystem(newReferrer);
    }else{
      totalFee = totalFee + (ticketCost * (stableFee) ) / 100;
    }

    totalPrice = totalPrice + (ticketCost * stablePrice) / 100;        
    whiteLister();
    countAddress();

    emit BuyNumber(actualNumber-1, msg.sender, ref);
  }

  function selectNumbers() public {
    require(msg.sender == caller, "You dont are de caller");    
    require(actualNumber > minNumber);
    require(cantOfAddress > cantOfNumbers);
    vrf.requestRandomWords(cantOfNumbers);
  }

  function finishPlay(uint[] memory randomNumber) public {
    require(msg.sender == address(vrf), "You dont are de caller");
    winersNumbers = randomNumber;    
    winersVerifications(randomNumber);
   
    for(uint i; i < LastAddressWiners.length; i++){       
      ticketCoin.transfer(LastAddressWiners[i], winAmount(i));
    }

    actualNumber = 1;
    loteryCounter++;
    delete cantOfAddress;
    emit Winners(winersNumbers, LastAddressWiners);
  }

  // winners mustn't be repeated 
  function winersVerifications(uint[] memory randomNumber) internal {
    delete LastAddressWiners;    
    for(uint i; i < randomNumber.length; i++){
      uint subWinerNumber = (randomNumber[i] % actualNumber) + 1 ;
      
      if(i == 0){ 
        winersNumbers[i] = subWinerNumber ; 
        LastAddressWiners.push(ownerOfTiket[winersNumbers[i]]);
      }
      else{
        for(uint j; j < i; j++){                 
          if( LastAddressWiners[j] == ownerOfTiket[subWinerNumber]){
            if (subWinerNumber == actualNumber){ subWinerNumber == 0; }
            subWinerNumber++;
            j = 0;
          }          

          if(LastAddressWiners[0] == ownerOfTiket[subWinerNumber]){
            subWinerNumber++;
          }
        }
        winersNumbers[i]=subWinerNumber;
        LastAddressWiners.push(ownerOfTiket[winersNumbers[i]]);
      }
    }    
  }  

  // ------------ Set FUNCTONS --------------
  function withDrawhticketCoins() public  onlyOwner{
    ticketCoin.transfer(msg.sender, totalFee);
    delete totalFee;
  }

  function setticketCoin(IERC20 _ticketCoin) public onlyOwner{
    ticketCoin = _ticketCoin;
  }

  function setVRF(RandomGenerator _vrf) public onlyOwner{
    vrf = _vrf;
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

  function setMinNumber(uint newMinNumber) public onlyOwner{
    minNumber = newMinNumber;
  }

  function setSpecialReferrers(address addressOfReferrer, uint amount) public onlyOwner{
    require(amount <= stableFee, "Amount is to high");
    referrerSpecialList[addressOfReferrer] = true;
    referrerSpecialListAmount[addressOfReferrer] = amount;
  }

  function toggleWhiteList() public onlyOwner{
    whiteList = !whiteList;
  }

  function deleteSpecialReferrers(address addressOfReferrer)public onlyOwner{
    delete referrerSpecialList[addressOfReferrer];
    delete referrerSpecialListAmount[addressOfReferrer];
  }

  // ------------ VIEW FUNCTONS --------------

  function winAmount(uint i) public view returns(uint){   
    return (totalPrice * percentForWiners[i]) / 100;  
  }

  function viewWhiteList() public view returns(address[] memory){
    return list;
  }

  function viewLastAddressWiners() public view returns(address[] memory){
    return LastAddressWiners;
  }

  // ------------ INTERNAL FUNCTONS --------------
  function _newTiket(address tiketFor) internal {
    ownerOfTiket[actualNumber] = tiketFor;    
    actualNumber++;
  }  

  //function de comprar voleto automatico para referentes
  function referralSystem(address newReferrer) internal returns(address){
    address realReferrer = setReferrer(newReferrer);
    uint fee = 5;
    if(referrerSpecialList[realReferrer]){
      fee = referrerSpecialListAmount[realReferrer];
    }

    totalFee = totalFee + (ticketCost * (stableFee-fee) ) / 100; 
    ticketCoin.transfer(realReferrer, ((ticketCost*fee)/100));

    //special list cant recive free tikets
    if((referralsBuys[realReferrer] == 3) && !(referrerSpecialList[realReferrer])){
     _newTiket( realReferrer); 
     delete referralsBuys[realReferrer];
    }

    return realReferrer;
  }

  function whiteLister() internal {
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
  }

  function countAddress() internal {
    if(!listOfBuyers[loteryCounter][msg.sender]){
      cantOfAddress++;
      listOfBuyers[loteryCounter][msg.sender] = true;
    }
  }

  function setReferrer(address newReferrer) internal returns(address){
    address RealReferrer = referrer[msg.sender];

    if(RealReferrer == address(0)){
      if(newReferrer != address(0) ){
        referrer[msg.sender] = newReferrer;
        referralsBuys[newReferrer]++;
        referralsAmount[newReferrer]++;
        RealReferrer = newReferrer;
      }
    }else{
      referralsBuys[RealReferrer]++;
      referralsAmount[RealReferrer]++;
    }
    return RealReferrer;
  }
}
