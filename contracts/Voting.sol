// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Game} from "./CoreGame.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";



contract Voting {
    struct Vote {
        uint yes;
        uint no;   
        uint timeEnd; // Time at when vote is invalid
    }

    uint public votingPeriod; // How long between each new vote instance
    uint public votingInterval; // How long a single vote lasts
    uint public votingThreshold; // What percentage of yes votes are need
    address public sharesContract; // ERC20 contract
    address payable public coreGame; // CoreGame contract
    mapping (address => bool) public didVote; // Mapping if user has voted
    mapping (address => bool) public votedYes; // Mapping if user has voted "YES"
    address[] public voterList; // To loop through and clear didVote
    Vote public voteInstance; // Init Vote struct instance
    uint public nextVoteTime; // Next valid vote start time
    IERC20 public token; // Create interface for ERC20

    constructor(
        uint _votingPeriod,
        uint _votingInterval,
        uint _votingThreshold,
        address _sharesContract,
        address payable _coreGame
    ){
        votingPeriod = _votingPeriod * 3600; // Input in hours converted to seconds
        votingInterval = _votingInterval * 86400; // Input in days converted to seconds
        votingThreshold = _votingThreshold;
        sharesContract = _sharesContract;
        coreGame = _coreGame;
        voteInstance = Vote(0, 0, block.timestamp + votingPeriod); // Initialize Vote struct
        nextVoteTime = block.timestamp + votingInterval; // Next valid vote instance
        token = IERC20(sharesContract);
    }

    modifier hasNotVoted() {
        require(!didVote[msg.sender], "You've already voted!");
        _; // Checks against mapping of voters to vote struct
    }

    modifier voteOngoing() {
        require(block.timestamp <= voteInstance.timeEnd, "Vote has ended");
        _;
    }

    modifier voteConcluded() {
        require(block.timestamp > voteInstance.timeEnd, "Vote is ongoing");
        _;
    }

    modifier voteStandby() {
        require(block.timestamp >= nextVoteTime, "Vote cannot start yet");
        _; // Voting interval must have passed
    }

    function createVote() public voteConcluded voteStandby {
        voteInstance = Vote(0, 0, block.timestamp + votingPeriod); // Reset vote with new timeEnd
        nextVoteTime = block.timestamp + votingInterval; // Set new time for next valid vote
    }

    function endVote() public voteConcluded {
        uint passingAmmount;
        passingAmmount = (token.totalSupply() * votingThreshold) / 100; // voting threshold as % of total shares
        if (voteInstance.yes > passingAmmount) {
             Game(coreGame).distribute(); // Calls distributed on CoreGame.sol
        }
        else {
            voteInstance = Vote(0, 0, 0); // Clear voteInstance struct
            deleteMapping(); // Clear didVote mapping
            voterList = new address[](0); // Clear voterList
        }
    }

    function vote(bool yesVote) public payable hasNotVoted voteOngoing {
        uint256 balance = token.balanceOf(msg.sender); // local var for msg.sender's token balance
        if (yesVote) { // True = voted Yes
            require(msg.value >= 1e17, "Voting yes costs 0.1 ETH"); // Hardcoded as 10% of share price
            payable(coreGame).transfer(msg.value);
            voteInstance.yes += balance;
        } else {
            voteInstance.no += balance;
        }
        didVote[msg.sender] = true; // Log that user has voted
        votedYes[msg.sender] = yesVote; // Log what the user voted
        voterList.push(msg.sender); // Add to array of voter addresses
    }

        function getTotalYesVotes() public view returns(uint256) {
        return voteInstance.yes;
    }

    function getTotalNoVotes() public view returns(uint256) {
        return voteInstance.no;
    }

    function voterListLength() public view returns(uint) {
        return voterList.length;
    }

    function getdidVote2(address _address) public view returns(bool) {
        return didVote[_address];
    }

    function getdidVote(uint _i) public view returns(bool) {
        return didVote[voterList[_i]];
    }

    function getVotedYes(uint _i) public view returns(bool) {
        return votedYes[voterList[_i]];
    }


    function getVoter(uint _i) public view returns(address) {
        return voterList[_i];
    }

    function deleteMapping() internal { // Clear didVote and votedYes mapping
        for (uint i=0; i < voterList.length; i++) {
            didVote[voterList[i]] = false;
            votedYes[voterList[i]] = false;
        } 
    }
}