// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
/// @title treasury management smart contract.

import "./LandToken.sol";
import "./GoldToken.sol";
import "./BankToken.sol";

contract TreasuryManagement {

    // Declare state variables of the contract
    address public owner;
    address public treasuryManagement;
    LandToken private landToken;
    GoldToken private goldToken;
    BankToken private bankToken;

    // When 'Treasury Management' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    constructor() {
        owner = msg.sender;
        treasuryManagement=address(this);
    }

    // Allow anyone to purchase token by giving what to buy, how much to buy and where the token needs to be transfered.
    function transferToken(uint decision, uint amount, address token, address members) public payable {
        require(msg.value >= amount * (10**15) , "You must pay 0.001 ETH per token requested");

        //decision is to invest in gold
         if(decision == 0){
            goldToken=GoldToken(token);
            // If treasury management does not have gold tokens we mint
             if(goldToken.balanceOf(treasuryManagement) < amount *(10**18)){
                goldToken.mint(treasuryManagement, amount);
            }
            // Approve and transfer the token 
            goldToken.approve(address(this), amount* (10**18));
            goldToken.transferFrom(address(this), members, amount* (10**18));
        }

        //  decision is to invest in land
         if(decision == 1){
            landToken=LandToken(token);
             // If treasury management does not have land tokens we mint
            if(landToken.balanceOf(address(this)) < amount *(10**18)){
                landToken.mint(address(this), amount);
            }
            // Approve and transfer the token 
            landToken.approve(address(this), amount *(10**18));
            landToken.transferFrom(address(this), members,amount *(10**18));
         }

         //decision is to invest in bank
         if(decision == 2){
            bankToken=BankToken(token);
             // If treasury management does not have bank tokens we mint
            if(bankToken.balanceOf(address(this)) <amount *(10**18)){
                bankToken.mint(address(this), amount);
            }
            // Approve and transfer the token 
            bankToken.approve(address(this),amount *(10**18));
            bankToken.transferFrom(address(this), members, amount *(10**18));
         }
    }

}