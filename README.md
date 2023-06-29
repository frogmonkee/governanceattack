# Game: Governance Attack
A financial game whereby players can deposit money into a shared treasury in return for voting shares at a set rate (eg. 0.1 ETH). At a regular cadence (eg. 7 days), there will be a vote to distribute the entire treasury. If the vote passes (eg. 51%), everyone who votes “YES” will receive a pro-rata of the treasury and the game resets.
The game ends either:
- When the players empty the treasury by passing a “YES” vote
- When a set amount of time goes by and all money is returned back to players
Players win the game by voting “YES” and receiving a proportional payout from the treasury that is larger than their initial buy-in.
Players lose the game by voting “NO” when enough players have voted “YES” to pass the vote, thereby draining the treasury.

## Game Details
- This is a game of greed. To win, players must gauge:
  - How much larger will the treasury grow before I want to cash in my share
  - How much larger will the treasury grow before others want to cash in their shares
- Votes will have to be private until all the results are in. Public votes may influence player voting strategies.
- Configurable parameters:
  - The cost of one voting share (0.1 ETH)
  - The time interval between votes (7 days)
  - The time interval of a vote (24 hours)
    - During this period, no new deposits are allowed
  - The vote threshold (51%)
  - A “game end” time limit when all funds are returned (1 month)	
- In order to disincentivize players from voting “YES” all the time, voting will cost money for each share voting “YES”. Voting “NO” will not cost anything. This introduces a cost to being on the favorable end of the bet and increases the size of the payout
