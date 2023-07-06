// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Voting} from "./Voting.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";


contract SharesContract is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mintShares(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}

contract Game {
    event RemainderTransferred(address recipient, uint256 amount);
    event TotalSharesIssued(address depositor, uint256 shares);

    uint public costOfShare; // How much ETH a single share costs
    uint public votingPeriod; // How long between each new vote instance
    uint public votingInterval; // How long a single vote lasts
    uint public votingThreshold; // What percentage of yes votes are need
    mapping(address => uint) winnerPayout;
    address[] public winnerPayoutIndex; // Keeps index of all addresses in `winnerPayout`

    Voting public votingContract; // Declare variable to hold voting contract type
    SharesContract public sharesContract; // Declare variable to hold ERC20 contract type

    constructor(
    uint _costOfShare, 
    uint _votingPeriod, 
    uint _votingInterval, 
    uint _votingThreshold) 
    {
        costOfShare = _costOfShare * 10**18; // Converts into ETH
        votingPeriod = _votingPeriod;
        votingInterval = _votingInterval;
        votingThreshold = _votingThreshold;

        sharesContract = new SharesContract("GovernanceAttack", "ATK"); // Will store address of ERC20 contract
        votingContract = new Voting(votingPeriod, votingInterval, votingThreshold, address(sharesContract), payable(address(this))); // Will store address of voting contract

    }
    function deposit() public payable returns (uint256) {
        // Require that vote is not ongoing
        uint256 quotient = msg.value / costOfShare; // Shares issued
        uint256 remainder = msg.value % costOfShare; // Remainder to be reverted

        if (remainder > 0) { // Refunds remainder
            payable(msg.sender).transfer(remainder);
            emit RemainderTransferred(msg.sender, remainder);
        }
        sharesContract.mintShares(msg.sender, quotient); // Mints ERC20 token as shares
        uint shares = sharesContract.balanceOf(msg.sender);
        emit TotalSharesIssued(msg.sender, shares); // Emits alert for # of shares owned
        return shares; // # of total shares
    }

    function distribute() external {
        require(msg.sender == address(votingContract)); // Requires that only voting contract can call distribute
        address votingContractAddress = address(votingContract);
        uint256 totalYesVotes = Voting(votingContract).getTotalYesVotes(); // sum of all yes votes
        for (uint i=0; i < Voting(votingContractAddress).voterListLength(); i++) { // Calculates payout value for winners
            if(Voting(votingContractAddress).getVotedYes(i)) {
                uint balance = sharesContract.balanceOf(Voting(votingContractAddress).getVoter(i)); // Balance of tokens
                uint payout = balance * address(this).balance / totalYesVotes; // Calculate payout
                winnerPayout[Voting(votingContractAddress).getVoter(i)] = payout; // Payout mapping
                winnerPayoutIndex.push(Voting(votingContractAddress).getVoter(i)); // Add to indexed array of winners
            } else {
                // Do nothing
            }
        }
        for (uint i=0; i < winnerPayoutIndex.length; i++) { // Pay
            payable(winnerPayoutIndex[i]).transfer(winnerPayout[winnerPayoutIndex[i]]);
        }
    }
    receive() external payable {

    }
}