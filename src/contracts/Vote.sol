// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote {
    struct Voter {
        bool hasVoted;
        uint256 vote;
    }

    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }

    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].hasVoted = false;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "Only chairperson can give right to vote.");
        require(!voters[voter].hasVoted, "The voter already voted.");
        voters[voter].hasVoted = false;
    }

    function vote(uint256 proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.hasVoted, "Already voted.");
        require(proposal < proposals.length, "Invalid proposal index.");

        sender.hasVoted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += 1;
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() public view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}