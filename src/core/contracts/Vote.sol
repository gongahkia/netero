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

    address[] public authorities;
    mapping(address => bool) public isAuthority;

    modifier onlyAuthority() {
        require(isAuthority[msg.sender], "Not an authority");
        _;
    }

    constructor(bytes32[] memory proposalNames, address[] memory initialAuthorities) {
        chairperson = msg.sender;
        voters[chairperson].hasVoted = false;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }

        for (uint256 i = 0; i < initialAuthorities.length; i++) {
            authorities.push(initialAuthorities[i]);
            isAuthority[initialAuthorities[i]] = true;
        }
    }

    function giveRightToVote(address voter) public onlyAuthority {
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

    function addAuthority(address newAuthority) public onlyAuthority {
        require(!isAuthority[newAuthority], "Already an authority");
        authorities.push(newAuthority);
        isAuthority[newAuthority] = true;
    }
}