// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/RandomGenerator.sol";

contract Lotery is Ownable, Pausable{

  uint public ticketCost;
  uint public actualNumber = 1; 
  uint public minNumber = 5;
  uint public minNumberOfAddress = 3;
  uint public loteryCounter; 
  uint public cantOfAddress;

  uint public stableFee; //in percernt  
  uint public stablePrize; //in percent
  uint public totalPrize;
  uint public totalVolumeInPrize;
  uint public totalTiketSell;
  uint public totalFee;

  uint[] public winersNumbers; 
  uint[] public percentForWiners;
  uint32 public cantOfNumbers = 5; //cant of winers per gift
  bool public whiteList = true;

  address public caller;
  address public manager = msg.sender;
  address public house;
  address[] public LastAddressWiners; 
  address[] public list;
  address[] public topReferrers;
  IERC20 public ticketCoin;
  RandomGenerator public vrf;
  mapping(uint => address) public ownerOfTiket;
  mapping(address=>uint) public referralsBuys;
  mapping(address=>uint) public referralsAmount;
  mapping(address=>address) public referrer;
  mapping(address=>bool) public referrerSpecialList;
  mapping(address=>uint) public referrerSpecialListAmount;
  mapping(uint=>uint) public historicalTotalPrize; 
  mapping(uint=>uint) public historicalTotalNumbers; 
  mapping(uint=>uint[]) public historicalWinnerNumbers;
  mapping(uint=>address[]) public historicalWinnerAddress;
  mapping(uint=>mapping(address=>uint[])) public historicalTiketsOwner;
  mapping(uint=>mapping(address=>bool)) public listOfBuyers;

  event BuyNumber(uint number, address buyer, address ref, uint _loteryCounter);
  event Winners(uint loteryNumber, address[] winersNumbers, uint[] winners);
 
  constructor ( 
    uint _ticketCost,
    uint _stableFee,
    address _house,
    uint[] memory _percentForWiners,
    RandomGenerator _RandomGenerator,
    IERC20 _ticketCoin
    ){     
    ticketCost = _ticketCost;
    caller = msg.sender;
    ticketCoin = _ticketCoin;
    house = _house;
    setStableFee(_stableFee);
    vrf = _RandomGenerator;
    setPercentForWiners(_percentForWiners);
  }  

  function buyNumber(address newReferrer) public whenNotPaused {
    ticketCoin.transferFrom(msg.sender, address(this), ticketCost);
    _newTiket( msg.sender);
    address ref =  referrer[msg.sender];

    if(!(ref == address(0) && newReferrer == msg.sender)){
      ref = referralSystem(newReferrer);
    }else{
      totalFee = totalFee + (ticketCost * (stableFee) ) / 100;
    }

    
    totalPrize = totalPrize + (ticketCost * stablePrize) / 100;
    
    historicalTiketsOwner[loteryCounter][msg.sender].push(actualNumber-1);
    whiteLister();
    countAddress();
    emit BuyNumber(actualNumber-1, msg.sender, ref, loteryCounter);
  }
  
  //implemented 1day before launch, i dont have time to optimized this :C
  function buyNumberBath(address newReferrer, uint cant )public whenNotPaused{
    for(uint i; i < cant; i++){
      buyNumber(newReferrer);
    }
  }

  function selectNumbers() public {
    require(msg.sender == caller, "You dont are de caller");    
    require(actualNumber >= minNumber, "actual number is down");
    require(cantOfAddress > minNumberOfAddress, "need more diferents buyers");
    vrf.requestRandomWords(cantOfNumbers);
  }

  function finishPlay(uint[] memory randomNumber) public {
    require(msg.sender == address(vrf), "You dont are de caller");
    require(actualNumber >= minNumber, "actual number is down");
    require(cantOfAddress > minNumberOfAddress, "need more diferents buyers");
     
    winersNumbers = winersVerifications(randomNumber);
   
    for(uint i; i < LastAddressWiners.length; i++){       
      ticketCoin.transfer(LastAddressWiners[i], winAmount(i));
    }

    totalVolumeInPrize += totalPrize;
    historicalWinnerNumbers[loteryCounter] = winersNumbers;
    historicalWinnerAddress[loteryCounter] = LastAddressWiners;
    historicalTotalNumbers[loteryCounter] = actualNumber-1;
    historicalTotalPrize[loteryCounter] = totalPrize;
    actualNumber = 1;
    loteryCounter++;
    ticketCoin.transfer(house, totalFee);
    delete totalFee;
    delete cantOfAddress;
    delete totalPrize;
    emit Winners(loteryCounter-1, viewLastAddressWiners(), viewWinerNumbers());
  }

  // winners mustn't be repeated 
  function winersVerifications(uint[] memory randomNumber) internal returns(uint[] memory){
    delete LastAddressWiners; 
    delete winersNumbers;
    uint[]  memory subWinersNumbers = randomNumber;
    for(uint i; i < randomNumber.length; i++){
      uint subWinerNumber = (randomNumber[i] % actualNumber) + 1 ;
      
      if(i == 0){ 
        subWinersNumbers[i] = subWinerNumber ; 
        LastAddressWiners.push(ownerOfTiket[subWinersNumbers[i]]);
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
        subWinersNumbers[i]=subWinerNumber;
        LastAddressWiners.push(ownerOfTiket[subWinersNumbers[i]]);
      }
    }    
    return subWinersNumbers;
  }  

  function withDrawhticketCoins() public  onlyOwner{
    ticketCoin.transfer(house, totalFee);
    delete totalFee;
  }
  // ------------ Set FUNCTONS --------------
  function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

  function setticketCoin(IERC20 _ticketCoin) public onlyOwner{
    ticketCoin = _ticketCoin;
  }

  function setTicketCost(uint _ticketCost) public onlyOwner{
    ticketCost = _ticketCost;
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
    stablePrize = 100-newStableFee;
  }

  function setMinNumber(uint newMinNumber) public onlyOwner{
    minNumber = newMinNumber;
  }

  function setHouse(address _house) public onlyOwner{
    house = _house;
  }

  function setSpecialReferrers(address addressOfReferrer, uint amount) public onlyOwner{
    require(amount <= stableFee, "Amount is to high");
    require(amount > 0, "amount can not be zero");
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
  function setMinNumberOfAddress(uint _minNumberOfAddress) public {
    minNumberOfAddress = _minNumberOfAddress;
  }
  // ------------ VIEW FUNCTONS --------------

  function winAmount(uint i) public view returns(uint){   
    return (totalPrize * percentForWiners[i]) / 100;  
  }

  function viewWhiteListLength() public view returns(uint){
    return list.length;
  }

  function viewLastAddressWiners() public view returns(address[] memory){
    return LastAddressWiners;
  }

  function viewWinerNumbers() public view returns(uint[] memory){
    return winersNumbers;
  }

  function viewLastWinersData() public view returns(uint[] memory, uint[] memory, address[] memory){
    uint[] memory winAmountValue = viewWinerNumbers();
    for(uint i; i < LastAddressWiners.length; i++){
      winAmountValue[i] = (historicalTotalPrize[loteryCounter-1] * percentForWiners[i]) / 100;
    }
    return (viewWinerNumbers(),winAmountValue, viewLastAddressWiners());
  }

  function viewLotery() public view returns(uint[10] memory){
    return([  
            cantOfNumbers,
            loteryCounter,
            ticketCost,
            cantOfAddress,
            actualNumber,
            totalPrize,
            historicalTotalPrize[loteryCounter-1],
            historicalTotalNumbers[loteryCounter-1],
            totalVolumeInPrize,
            totalTiketSell
          ]
          );
  }
  function viewLoteryData() public view returns(uint[10] memory, uint[31] memory ){
    return([  
            cantOfNumbers,
            loteryCounter,
            ticketCost,
            cantOfAddress,
            actualNumber,
            totalPrize,
            historicalTotalPrize[loteryCounter-1],
            historicalTotalNumbers[loteryCounter-1],
            totalVolumeInPrize,
            totalTiketSell
          ],
          viewLastHistoricalTotalPrizes()
          );
  }

  function viewReferralsData(address user) public view returns(bool,uint, uint, address, uint[] memory, uint[] memory  ){
    return (
      referrerSpecialList[user],
      referrerSpecialListAmount[user],
      referralsAmount[user],
      referrer[user],
      historicalTiketsOwner[loteryCounter][user],
      historicalTiketsOwner[loteryCounter-1][user]    
    );
  }
  
  function viewTopReferresAndAmount() public view returns(address[] memory ,uint[5] memory ){
    uint[5] memory topReferralsAmount;
    for (uint i; i < topReferrers.length; i++){
      topReferralsAmount[i] = referralsAmount[topReferrers[i]];
    }
    return (topReferrers, topReferralsAmount);
  }

  function viewLastHistoricalTotalPrizes() public view returns(uint[31] memory){
    uint[31] memory lastPrizes;
    uint stop =30;
    if(loteryCounter < 30 ){      
       stop = loteryCounter; 
    }
    uint j;
    for(uint i=stop ; i > 0; i--){
      lastPrizes[j] = historicalTotalPrize[loteryCounter-i];
      j++;
    }
    
    return lastPrizes;
  }   

  function lastLoteryData(uint i) public view returns(uint, uint, address[] memory, uint[] memory) {
    return (
      historicalTotalNumbers[i],
      historicalTotalPrize[i],
      historicalWinnerAddress[i],
      historicalWinnerNumbers[i]
    );
  }

  // ------------ INTERNAL FUNCTONS --------------
  function _newTiket(address tiketFor) internal {
    ownerOfTiket[actualNumber] = tiketFor;    
    actualNumber++;
    totalTiketSell++;
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
    if(!referrerSpecialList[realReferrer]){
      topReferrerVerification(realReferrer);
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

  function topReferrerVerification(address refererrToCompare) public {
    if(topReferrers.length == 0){
      topReferrers.push(refererrToCompare);
    }else{
      (bool isRepited, uint pos) = topRepitedAddress(refererrToCompare);
      uint lenght = topReferrers.length;
      if(!isRepited){
        if(referralsAmount[refererrToCompare] < referralsAmount[topReferrers[lenght-1]] && lenght < 5){
          topReferrers.push(refererrToCompare);  
          lenght++; 
        }else{
          address aux;
          for(uint i = 0; i < lenght ; i++){
            if(referralsAmount[refererrToCompare] > referralsAmount[topReferrers[i]]){
              aux = topReferrers[i];
              topReferrers[i] = refererrToCompare;
              refererrToCompare = aux;
            }
            if(i == lenght-1 && lenght < 5){
              topReferrers.push(refererrToCompare);
            }
          }
        }
      }
      if(isRepited){
        address aux;          
        for(uint i=pos; i > 0; i--){
          if(referralsAmount[refererrToCompare] > referralsAmount[topReferrers[i-1]]){
            aux =  topReferrers[i-1];
            topReferrers[i-1] = refererrToCompare;
            topReferrers[i] = aux;
          }                     
        }
      }        
    }
  }
  

  function topRepitedAddress(address refererrToCompare) internal view returns(bool verification, uint index){
    
    for(uint i; i < topReferrers.length; i++){
     if(topReferrers[i] == refererrToCompare) {
      verification = true;
      index = i;
     }
    }

  }
  
}