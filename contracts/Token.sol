// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, ERC20Burnable, Ownable {
    uint public fee = 100; // 100 = 1% -> 10000 = 100%
    uint public burnfee = 100;
    uint public transferfee = 100;

    uint public maxSupply = 96300000 * 1 ether;
    address public houseWallet;


    mapping(address => bool) public banedList; // Address cant transfer tokens
    mapping(address => bool) public vipList;// Address not pay fees (lotery, staking..)


    constructor(
        address _houseWallet,  // 10,2% (team/markegin/airdrops)
        address loteyContract, // 17,72%
        address stakingContract, // 35%
        address salesAndLiquidity // 37.08%
        ) ERC20("Token", "EBF") {
        houseWallet = _houseWallet;
        _mint(houseWallet, 9822600 * 1 ether);
        _mint(loteyContract, 17064360 * 1 ether);
        _mint(stakingContract, 33705000 * 1 ether);
        _mint(salesAndLiquidity, 35708040 * 1 ether);

        vipList[loteyContract] = true;
        vipList[stakingContract] = true;
        vipList[salesAndLiquidity] = true;

        require(totalSupply() == maxSupply);
    }

    // => Set functions
    function setFees(uint _burnfee, uint _fee,uint _transferfee)public {
        require((_burnfee+_fee+_transferfee)<10000, "total fee must be minor to 100");
        burnfee = _burnfee;
        fee = _fee;
        transferfee = _transferfee;
    }

    function toggleVipList(address newVipAddress) public onlyOwner{
        vipList[newVipAddress] = !vipList[newVipAddress];
    }
    function toggleBanedList(address newBanedAddress) public onlyOwner{
        banedList[newBanedAddress] = !banedList[newBanedAddress];
    }
    
    function transfer(address to, uint256 amount) public virtual override returns(bool) {
        require(!banedList[msg.sender],"Baned wallet" );
        uint newAmount = _executeFees(msg.sender, amount); 
        
        return super.transfer(to, newAmount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(!banedList[msg.sender],"Baned wallet" );
        uint newAmount = _executeFees(from,  amount);  
        
        return super.transferFrom(from, to, newAmount);
    }
    

    function _executeFees(address from, uint256 amount) internal returns(uint){
        uint newAmount = amount;
        if(!vipList[msg.sender]){
            uint amountFee = (amount * fee) / 10000;
            uint amountBurnFee = (amount * burnfee) / 10000;
            uint amountTransferFee = (amount * transferfee) / 10000;

            _transfer(from, houseWallet, amountFee);
            _burn(from, amountBurnFee);
            _transfer(from, houseWallet, amountTransferFee);

            newAmount = amount - amountFee - amountBurnFee - amountTransferFee;
        }
        return newAmount;
    }
}