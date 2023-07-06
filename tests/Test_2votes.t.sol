// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "../src/GameFactory.sol";
import "../src/CoreGame.sol";
import "../src/Voting.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Tests a game that lasts for multiple vote
contract GFTest is Test {
    GameFactory public gameFactory;
    Game public game;
    Voting public voting;
    IERC20 public shares;

    address userA;
    address userB;
    address userC;
    address userD;

    function setUp() public {
        gameFactory = new GameFactory();
        game = Game(gameFactory.createNewGame(1, 7, 24, 51));
            // cost of share = 1 eth
            // voting interval = 7 days
            // vote duration = 24 hours
            // vote threshold = 51%
        voting = game.votingContract();
        shares = game.sharesContract();


        userA = makeAddr("User A");
        vm.deal(userA, 4.2 ether);
        userB = makeAddr("User B");
        vm.deal(userB, 3 ether);
        userC = makeAddr("User C");
        vm.deal(userC, 2 ether);        
        userD = makeAddr("User D");
        vm.deal(userD, 2.1 ether);        
    }

    function testVote() public {
        /* First set of depositors
        +--------+----------------+
        |  User  | Deposit Amount |
        +--------+----------------+
        | User A |              4 |
        | User B |              3 |
        | User C |              2 |
        +--------+----------------+
        */
        vm.prank(userA);
        game.deposit{ value: 4 ether } ();
        vm.prank(userB);
        game.deposit{ value: 3 ether } ();
        vm.prank(userC);
        game.deposit{ value: 2 ether } ();
        assertEq(address(game).balance, 9e18); // Confirms balance is 9 ETH
        
        /* Vote #1
        +-------+------+-------------+
        | User  | Vote | Vote Weight |
        +-------+------+-------------+
        | UserA | Yes  |           4 |
        | UserB | No   |           3 |
        | UserC | No   |           2 |
        +-------+------+-------------+
        */
        vm.prank(userA); // Change to User A
        voting.vote{ value: 0.1 ether }(true); // Vote True
        assertEq(voting.getTotalYesVotes(), 4); // Check that vote count is logged
        assertTrue(voting.getdidVote2(userA)); // Get that voter is logged
        assertEq(voting.getVoter(0), address(userA)); // Check that address is logged

        vm.prank(userB);
        voting.vote(false); // Vote False
        assertEq(voting.getTotalNoVotes(), 3);
        assertTrue(voting.getdidVote2(userB));
        assertEq(voting.getVoter(1), address(userB));

        vm.prank(userC);
        voting.vote(false); // Vote False
        assertEq(voting.getTotalNoVotes(), 5);
        assertTrue(voting.getdidVote2(userC));
        assertEq(voting.getVoter(2), address(userC));

        // Skip 24 hours to end vote
        uint256 endVoteTimestamp = block.timestamp + 24 * 60 * 60;
        vm.warp(endVoteTimestamp);
        voting.endVote();
        assertEq(voting.getTotalNoVotes(), 0); // Asserts Vote struct is cleared
        assertEq(voting.getTotalYesVotes(), 0); // Asserts Vote struct is cleared
        assertEq(voting.voterListLength(), 0); // Asserts voter registry is cleared

        /* New depositors
        +--------+----------------+
        |  User  | Deposit Amount |
        +--------+----------------+
        | User D |              2 |
        +--------+----------------+
        */
        
        vm.prank(userD);
        game.deposit{ value: 2 ether } ();
        assertEq(address(game).balance, 11.1e18); // Confirms balance is 9 ETH

        /* Vote #2
        +-------+------+-------------+
        | User  | Vote | Vote Weight |
        +-------+------+-------------+
        | UserA | Yes  |           4 |
        | UserB | No   |           3 |
        | UserC | No   |           2 |
        | UserD | Yes  |           2 |
        +-------+------+-------------+
        */
        vm.warp(2073602);
        voting.createVote();
        assertFalse(voting.getdidVote2(userA));
        assertFalse(voting.getdidVote2(userB));
        assertFalse(voting.getdidVote2(userC));
        assertFalse(voting.getdidVote2(userD));

        vm.prank(userA);
        voting.vote{ value: 0.1 ether }(true); // Vote True
        assertEq(voting.getTotalYesVotes(), 4);
        vm.prank(userB);
        voting.vote(false); // Vote False
        assertEq(voting.getTotalNoVotes(), 3);
        vm.prank(userC);
        voting.vote(false); // Vote False
        assertEq(voting.getTotalNoVotes(), 5);
        vm.prank(userD);
        voting.vote{ value: 0.1 ether }(true); // Vote True
        assertEq(voting.getTotalYesVotes(), 6);


        /* Check Balances
        +--------+----------------------+
        |  User  |       Balance        |
        +--------+----------------------+
        | UserA  | 4/6 * 11.3 = 7.53 ETH|
        | UserB  | 0 ETH                |
        | UserC  | 0 ETH                |
        | UserD  | 2/6 * 11.3 = 3.77 ETH|
        +--------+----------------------+
        */

        uint256 newTimestamp = block.timestamp + 24 * 60 * 60;
        vm.warp(newTimestamp);
        voting.endVote();
        assertEq(userA.balance, 7533333333333333333);
        assertEq(userB.balance, 0);
        assertEq(userC.balance, 0);
        assertEq(userD.balance, 3766666666666666666);  
    }
}