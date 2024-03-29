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
  uint public minNumberOfAddress = 5;
  uint public loteryCounter; 
  uint public cantOfAddress;

  uint public stableFee; //in percernt  
  uint public stablePrize; //in percent
  uint public totalPrize;
  uint public totalVolumeInPrize;
  uint public totalTiketSell;
  uint public totalTiketFree;
  uint public totalFee;
  uint public time =  block.timestamp;
  uint public timePlus = 1 hours;

  uint[] public winersNumbers; 
  uint[] public percentForWiners;
  uint32 public cantOfNumbers = 5; //number of winers per gift

  address public caller;
  address public manager = msg.sender;
  address public house;
  address[] public LastAddressWiners; 
  address[] public referralList;
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
  mapping(uint=>mapping(address=>uint[])) public historicalTiketsFree;

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

  function buyNumber(address newReferrer, uint _amount) public whenNotPaused {
    require(msg.sender != newReferrer, "bad referrer");
    uint amount = ticketCost *   _amount;
    ticketCoin.transferFrom(msg.sender, address(this), amount);
    countAddress();
    _newTiket(msg.sender, _amount, false);
    address ref = referrer[msg.sender];
    if(ref != address(0) || newReferrer != address(0)){
      ref = referralSystem(newReferrer, _amount);
    }else{
      totalFee = totalFee + (amount * stableFee ) / 100;
    }        
    totalPrize = totalPrize + (amount * stablePrize) / 100;
    
    emit BuyNumber(actualNumber-1, msg.sender, ref, loteryCounter);    
  }
  
  function selectNumbers() public {
    require(msg.sender == caller, "You dont are de caller");    
    require(time < block.timestamp, "need more time");
    time =  block.timestamp + timePlus;

    if(cantOfAddress > minNumberOfAddress){
      require(actualNumber >= minNumber, "actual number is down");
      vrf.requestRandomWords(cantOfNumbers);
    }
  }

  function finishPlay(uint[] memory randomNumber) public {
    require(msg.sender == address(vrf), "You dont are de caller");
    require(actualNumber >= minNumber, "actual number is down");
    require(cantOfAddress > minNumberOfAddress, "need more diferents buyers");
    //require(time < block.timestamp, "need more time");
    //time =  block.timestamp + timePlus;
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
      uint subWinerNumber = (randomNumber[i] % actualNumber);
      if (subWinerNumber == 0) {
        subWinerNumber++;
      }
      if(i == 0){ 
        subWinersNumbers[i] = subWinerNumber ; 
        LastAddressWiners.push(ownerOfTiket[subWinersNumbers[i]]);
      }else{
        bool change;
        for(uint j; j < i; j++){  
          while( LastAddressWiners[j] == ownerOfTiket[subWinerNumber]){
            subWinerNumber++;
            if (subWinerNumber == actualNumber){ subWinerNumber = 1; }
            change = true;
          }          
          while( LastAddressWiners[0] == ownerOfTiket[subWinerNumber]){
            subWinerNumber++;
            if (subWinerNumber == actualNumber){ subWinerNumber = 1; }
            change = true;
          }          
         
          if(change){
            j=0;
            change = false;
          }
        }
        subWinersNumbers[i]=subWinerNumber;
        LastAddressWiners.push(ownerOfTiket[subWinersNumbers[i]]);
      }
    }    
    return subWinersNumbers;
  }  

  function withDrawhticketCoins() public onlyOwner{
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

  function setCantOfNumbers(uint32 _amountOfNumbers) public onlyOwner{
    cantOfNumbers = _amountOfNumbers;
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

  function viewLotery() internal view returns(uint[11] memory){
    return(
      [  
        cantOfNumbers,
        loteryCounter,
        ticketCost,
        cantOfAddress,
        actualNumber,
        totalPrize,
        historicalTotalPrize[loteryCounter-1],
        historicalTotalNumbers[loteryCounter-1],
        totalVolumeInPrize,
        totalTiketSell,
        totalTiketFree
      ]
    );
  }
  
  function viewLoteryData() public view returns(uint[11] memory, uint[31] memory ){
    return(viewLotery(),viewLastHistoricalTotalPrizes());
  }

  function viewUserData(address user) public view returns(
    bool, uint, uint, address, uint[] memory, uint[] memory
  ){
    return (
      referrerSpecialList[user], 
      referrerSpecialListAmount[user], 
      referralsAmount[user],
      referrer[user],
      historicalTiketsOwner[loteryCounter][user],
      historicalTiketsOwner[loteryCounter-1][user]
      );
  }

  function viewFreeTickets(uint n, address user) public view returns(uint[] memory, uint[] memory){
    return(
      historicalTiketsFree[loteryCounter][user],
      historicalTiketsFree[loteryCounter-n][user]
    );
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

  function getAmountOfList() public view returns (uint[] memory) {
    address[] memory referralListMemory= referralList;
    uint length = referralList.length;
    uint[] memory amounts = new uint[](length);
    for(uint i; i < referralListMemory.length; i++){
      amounts[i] = referralsAmount[referralListMemory[i]];
    }
    return amounts;
  }

  function getRefferalList() public view returns(address[] memory){
    return referralList;
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
  function _newTiket(address ticketFor, uint amount, bool freeTicket) internal {
    for(uint i; i < amount; i++){
      if(freeTicket){
        historicalTiketsFree[loteryCounter][ticketFor].push(actualNumber);
        totalTiketFree++;
      }else{
        totalTiketSell++;
      }
      ownerOfTiket[actualNumber] = ticketFor;    
      historicalTiketsOwner[loteryCounter][ticketFor].push(actualNumber);
      actualNumber++;
    }
  }  

  //function de comprar voleto automatico para referentes
  function referralSystem(address newReferrer, uint _amount) internal returns(address){
    uint amount = ticketCost * _amount;
    address realReferrer = setReferrer(newReferrer, _amount);
    uint fee = 5;
    if(referrerSpecialList[realReferrer]){
      fee = referrerSpecialListAmount[realReferrer];
    }

    totalFee = totalFee + (amount * (stableFee-fee) ) / 100; 
    ticketCoin.transfer(realReferrer, ((amount*fee)/100));

    //special list cant recive free tikets
    if((referralsBuys[realReferrer] >= 3) && !(referrerSpecialList[realReferrer])){
      uint freeAmount = referralsBuys[realReferrer]/ 3;
      _newTiket( realReferrer, freeAmount, true); 
      referralsBuys[realReferrer] = referralsBuys[realReferrer] % 3;
    }
    return realReferrer;
  }

  function countAddress() internal {
    if(historicalTiketsOwner[loteryCounter][msg.sender].length == 0 ){
      cantOfAddress++;
    }
  }
  
  //In seconds
  function setTimePlus(uint newTimePlusSeconds) public {
    timePlus = newTimePlusSeconds;
  }

  function setReferrer(address newReferrer, uint amount) internal returns(address){
    address realReferrer = referrer[msg.sender];
    
    if(realReferrer == address(0)){
      if(newReferrer != address(0) ){
        referrer[msg.sender] = newReferrer;
        if(referralsAmount[newReferrer] == 0 && !(referrerSpecialList[newReferrer])){
          referralList.push(newReferrer);
        }
        referralsBuys[newReferrer] +=amount;
        referralsAmount[newReferrer]+=amount;
        realReferrer = newReferrer;
      }
    }else{
      referralsBuys[realReferrer]+=amount;
      referralsAmount[realReferrer]+=amount;
    }
    return realReferrer;
  }
}