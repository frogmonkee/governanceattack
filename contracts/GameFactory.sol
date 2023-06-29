// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Game} from "./CoreGame.sol";

contract GameFactory {
    Game public coreGame; // Address for deployed CoreGame.sol contract

    function createNewGame(
        uint256 _costOfShare, 
        uint256 _votingPeriod, 
        uint256 _votingInterval, 
        uint256 _votingThreshold) 
        public returns(address payable) {
            coreGame = new Game(_costOfShare, _votingPeriod, _votingInterval, _votingThreshold);
            return payable(address(coreGame)); // Would this be sent to the FE so user know where the game contract is?
        }
}