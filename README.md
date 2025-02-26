[![](https://img.shields.io/badge/netero_1.0.0-passing-green)](https://github.com/gongahkia/netero/releases/tag/1.0.0) 

# `Netero`

Decentralized voting platform powered by the blockchain.

For the [stack used](#tech-used).

<div align="center">
    <img src="./asset/screenshot/home.png" width="80%">
</div>

## Usage

Instructions below are for local hosting.

1. Install the [MetaMask](https://metamask.io/) Browser Extension.
    1. [Chrome Extension](https://chromewebstore.google.com/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?hl=en&pli=1)
    2. [Firefox  Extension](https://addons.mozilla.org/en-US/firefox/addon/ether-metamask/)
    3. [Microsoft Edge Extension](https://microsoftedge.microsoft.com/addons/detail/metamask/ejbalbakoplchlghecdalmeeeajnimhm?hl=en-US)
    4. [Brave Extension](https://support.metamask.io/configure/wallet/using-metamask-wallet-in-brave-browser/)
2. Create a new wallet or import an existing one.
3. Connect to the local network with the following details.
    1. **Network Name**: Any string
    2. **New RPC URL**: *http://localhost:8545* 
    3. **Chain ID**: *1337* 
    4. **Currency Symbol**: *ETH*
4. Run the following.

```console
$ git clone https://github.com/gongahkia/netero
$ cd netero/src
$ python3 main.py
$ cd netero-app/
$ npm run serve
```

5. View `netero-app` at [localhost:8080](http://localhost:8080/).

## Screenshots

![](./asset/screenshot/register.png)
![](./asset/screenshot/create.png)
![](./asset/screenshot/cast.png)
![](./asset/screenshot/result.png)

## Tech used

`Netero` was built with the following stack.

* [Vue.js](https://vuejs.org/) for the frontend
* [Truffle](https://archive.trufflesuite.com/), [Ganache](https://archive.trufflesuite.com/ganache/) and [Solidity](https://soliditylang.org/) for the smart contract and local Ethereum deployment middleware
* Raw [Python](https://www.python.org/) for the backend 

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

## References

The name `Netero` is in reference to [Isaac Netero](https://hunterxhunter.fandom.com/wiki/Isaac_Netero) (アイザック＝ネテロ), the 12th Chairman of the [Hunter Association](https://hunterxhunter.fandom.com/wiki/Hunter_Association). His death in the [Chimera Ant arc](https://hunterxhunter.fandom.com/wiki/Chimera_Ant_arc) at the hands of Chimera Ant King [Meruem](https://hunterxhunter.fandom.com/wiki/Meruem) directly trigger the events of the [13th Hunter Chairman Election arc](https://hunterxhunter.fandom.com/wiki/13th_Hunter_Chairman_Election_arc), as part of the the ongoing manga series, [HunterXhunter](https://hunterxhunter.fandom.com/wiki/Hunterpedia).

![](./asset/logo/netero.png)
