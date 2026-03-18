// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
/// @title Simple DAO smart contract.

import "./TreasuryManagement.sol";
import "./MemberToken.sol";
import "./LandToken.sol";
import "./GoldToken.sol";
import "./BankToken.sol";

contract MembersDAO {
    // This simple proof of concept DAO smart contract sends ether to the treasury management
    // only if the majority of the DAO members vote "yes" to buy token, else it does not do anything.
    // If the majority of the DAO members decide not to send ether, the members who deposited ether 
    // are able to withdraw the ether they deposited.
    
    address payable public treasuryManagementAddress;
    address public goldAddress;
    address public bankAddress;
    address public landAddress;

    MemberToken public memberToken;
    LandToken private landToken;
    GoldToken private goldToken;
    BankToken private bankToken;
    
    uint public voteEndTime;
    
    // balance of ether in the smart contract
    uint public DAObalance;

    // proposal decision of voters 
    uint public decision;

    // default set as false 
    // makes sure votes are counted before ending vote
    bool public ended;
    
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    // address of the person who set up the MemberDAO
    address public chairperson;
    address public memberDao;

    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    //error handlers

    /// The vote has already ended.
    error voteAlreadyEnded();
    /// The auction has not ended yet.
    error voteNotYetEnded();

    // Input string: ["Gold","Land","Bank"]
    // _treasuryManagementAddress is the address where 0.001 ETH will be sent
    constructor(
        address payable _treasuryManagementAddress,
        address _goldAddress,
        address _landAddress,
        address _bankAddress,
        uint _voteTime,
        string[] memory proposalNames
    ) {

        treasuryManagementAddress = _treasuryManagementAddress;
        goldAddress=_goldAddress;
        landAddress=_landAddress;
        bankAddress=_bankAddress;
        
        chairperson = msg.sender;
        memberDao = address(this);
        
        voteEndTime = block.timestamp + _voteTime;

        for (uint i = 0; i < proposalNames.length; i++) {

            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }


    // anyone can deposit ether to the DAO smart contract to purchase tokens
    function DepositEth() public payable {
        
        if (block.timestamp > voteEndTime) {
            revert voteAlreadyEnded();
        }

        DAObalance = address(this).balance;
    }

    // Store the memberTokenAddress
    function membersTokenId(address memberAddress) public{
        memberToken=MemberToken(memberAddress);
    }

    // only the chairperson can decide who can vote and tranfer the membertoken 
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        
        require(
            !voters[voter].voted,
            "The voter already voted."
        );

        if(memberToken.balanceOf(address(this))<uint256(1)){
            memberToken.mint(address(this), 1);
        }

        memberToken.approve(address(this), 1 * (10 ** uint256(18)));
        memberToken.approve(voter, 1 * (10 ** uint256(18)));

        if(memberToken.balanceOf(voter)<uint256(1))
            memberToken.transferFrom(address(this), voter, 1 * (10 ** uint256(18)));

    }


    // proposals are in format 0,1,2, and the below funtion is used for voting
    function vote(uint proposal) public returns(uint256) {
        Voter storage sender = voters[msg.sender];

        require(memberToken.balanceOf(msg.sender)!=uint256(0), "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += 1;

        memberToken.transferFromCustom(msg.sender, address(this), 1 * (10 ** uint256(18)), address(this));
        return memberToken.balanceOf(msg.sender);
    }


    // winningProposal must be executed before EndVote
    function countVote() public returns (uint winningProposal_) {
        require(block.timestamp > voteEndTime, "Vote not yet ended.");
        
        uint winningVoteCount = 0;

        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
                
                decision = winningProposal_;
            }
        }
        ended = true;
    }


   // Individuals can withdraw
    function withdraw(uint amount) public {
        payable(msg.sender).transfer(amount * (10 ** (uint256(18))));
        
    }


    // ends the vote
    // after end vote based on decision, transfer of tokens(gold/land/bank/none) will take place in exchange of ETH 
    function EndVote() public {

       DAObalance = address(this).balance;

        require(
            block.timestamp > voteEndTime,
            "Vote not yet ended.");
          
        require(
            ended == true,
            "Must count vote first");  
            
        require(
            DAObalance >= 10**15,
            "Not enough balance in DAO required to buy tokens. Members may withdraw deposited ether.");
            
        
        if (DAObalance  <  10**15 ) revert();

        // If Gold is chosen
        if(decision == 0){
          
            TreasuryManagement treasuryManagement=TreasuryManagement(treasuryManagementAddress);
            treasuryManagement.transferToken{value : 10**15}(0,1,goldAddress, memberDao);
        }
        //If Land is chosen
        if(decision == 1){
           TreasuryManagement treasuryManagement=TreasuryManagement(treasuryManagementAddress);
            treasuryManagement.transferToken{value : 10**15}(1,1,landAddress, memberDao);
        }

        // If Bank is chosen
        if(decision == 2){
          TreasuryManagement treasuryManagement=TreasuryManagement(treasuryManagementAddress);
            treasuryManagement.transferToken{value : 10**15}(2,1,bankAddress, memberDao);
        }

        DAObalance = address(this).balance;
    }
}