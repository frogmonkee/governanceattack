// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import "../src/GameFactory.sol";
import "../src/CoreGame.sol";
import "../src/Voting.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Tests a game that lasts for just one vote
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
        vm.deal(userA, 4.1 ether);
        userB = makeAddr("User B");
        vm.deal(userB, 3.1 ether);
        userC = makeAddr("User C");
        vm.deal(userC, 2 ether);        
        userD = makeAddr("User D");
        vm.deal(userD, 2 ether);        
    }

    function testVariables() public {
        assertEq(game.costOfShare(), 1000000000000000000); // Cost of share in Wei
        assertEq(voting.votingPeriod(), 25200); // Voting period in seconds
        assertEq(voting.votingInterval(), 2073600); // Voting interval in seconds
        assertEq(voting.votingThreshold(), 51); // Numerator of voting threshold
    }

    function testVote() public {
        /*
        +--------+----------------+
        |  User  | Deposit Amount |
        +--------+----------------+
        | User A |              4 |
        | User B |              3 |
        | User C |              2 |
        | User D |              2 |
        +--------+----------------+
        */
        vm.prank(userA);
        game.deposit{ value: 4 ether } ();
        vm.prank(userB);
        game.deposit{ value: 3 ether } ();
        vm.prank(userC);
        game.deposit{ value: 2 ether } ();
        vm.prank(userD);
        game.deposit{ value: 2 ether } ();
        assertEq(address(game).balance, 11e18); // Confirms balance is 11 ETH
        
        /*
        +-------+------+-------------+
        | User  | Vote | Vote Weight |
        +-------+------+-------------+
        | UserA | Yes  |           4 |
        | UserB | Yes  |           3 |
        | UserC | No   |           2 |
        | UserD | No   |           2 |
        +-------+------+-------------+
        */
        vm.prank(userA);
        voting.vote{ value: 0.1 ether }(true); // Vote True
        assertEq(address(game).balance, 11.1e18);
        assertEq(voting.getTotalYesVotes(), 4);
        vm.prank(userB);
        voting.vote{ value: 0.1 ether }(true); // Vote True
        assertEq(address(game).balance, 11.2e18);
        assertEq(voting.getTotalYesVotes(), 7);
        vm.prank(userC);
        voting.vote(false); // Vote True
        assertEq(address(game).balance, 11.2e18);
        assertEq(voting.getTotalNoVotes(), 2);
        vm.prank(userD);
        voting.vote(false); // Vote True
        assertEq(address(game).balance, 11.2e18);
        assertEq(voting.getTotalNoVotes(), 4);

        /*
        +--------+----------------------+
        |  User  |       Balance        |
        +--------+----------------------+
        | UserA  | 4/7 * 11.2 = 6.4 ETH |
        | UserB  | 3/7 * 11.2 = 4.8 ETH |
        | UserC  | 0 ETH                |
        | UserD  | 0 ETH                |
        +--------+----------------------+
        */
        uint256 newTimestamp = block.timestamp + 24 * 60 * 60;
        vm.warp(newTimestamp);
        voting.endVote();
        assertEq(userA.balance, 6.4e18);
        assertEq(userB.balance, 4.8e18);
        assertEq(userC.balance, 0);
        assertEq(userD.balance, 0);
    }
}