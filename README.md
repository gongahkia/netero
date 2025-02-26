[![](https://img.shields.io/badge/netero_1.0-passing-green)](https://github.com/gongahkia/netero/releases/tag/1.0) 

# `Netero`

Decentralized voting platform powered by blockchain.

> TODO edit the below

* Vue for the frontend
* Truffle and Ganache for the backend blockchain contract logic
* Python for the other backend

## Usage

Instructions below are for local hosting.

```console
$ cd src
$ python3 main.py
$ cd netero-app/
$ npm run serve
```

## Architecture

### Structure

```mermaid
graph TD
    A[App.vue] --> B[Router]
    B --> C[VoterRegistration.vue]
    B --> D[BallotCreation.vue]
    B --> E[VotingInterface.vue]
    B --> F[ResultsDisplay.vue]
    
    C --> G[Web3]
    D --> G
    E --> G
    F --> G
    
    G --> H[Smart Contract]
    H --> I[Blockchain]
    
    J[main.js] --> A
    J --> K[Vue initialization]
    J --> L[Router configuration]
    
    M[Vote.sol] --> H
```

### Overview

```mermaid
sequenceDiagram
    participant User
    participant App
    participant Web3
    participant SmartContract
    participant Blockchain

    User->>App: Open application
    App->>Web3: Initialize Web3
    Web3->>Blockchain: Connect to network
    User->>App: Select action (Register/Create/Vote/Results)
    
    alt Register
        App->>SmartContract: Call giveRightToVote()
        SmartContract->>Blockchain: Update voter status
    else Create Ballot
        App->>SmartContract: Deploy new contract
        SmartContract->>Blockchain: Store new contract
    else Vote
        App->>SmartContract: Call vote()
        SmartContract->>Blockchain: Record vote
    else View Results
        App->>SmartContract: Call winningProposal() and winnerName()
        SmartContract->>App: Return results
    end
    
    App->>User: Display confirmation/results
```

View `netero-app` at [localhost:8080](http://localhost:8080/).

## References

The name `Netero` is in reference to [Isaac Netero](https://hunterxhunter.fandom.com/wiki/Isaac_Netero) (アイザック＝ネテロ), the 12th Chairman of the [Hunter Association](https://hunterxhunter.fandom.com/wiki/Hunter_Association). His death in the [Chimera Ant arc](https://hunterxhunter.fandom.com/wiki/Chimera_Ant_arc) at the hands of Chimera Ant King [Meruem](https://hunterxhunter.fandom.com/wiki/Meruem) directly trigger the events of the [13th Hunter Chairman Election arc](https://hunterxhunter.fandom.com/wiki/13th_Hunter_Chairman_Election_arc), as part of the the ongoing manga series, [HunterXhunter](https://hunterxhunter.fandom.com/wiki/Hunterpedia).

![](https://static.wikia.nocookie.net/hunterxhunter/images/0/04/Netero_in_Dark_Continent.png/revision/latest?cb=20210828043114)