// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Poll} from "./Poll.sol";

contract PollFactory {
    event PollCreated(address indexed org, address indexed creator, address poll, string title);

    // org => list of polls
    mapping(address => address[]) private _orgPolls;

    function createPoll(
        address org,
        string memory title,
        string memory description,
        string[] memory options,
        uint64 startTime,
        uint64 endTime,
        bool restricted
    ) external returns (address pollAddr) {
        require(options.length >= 2, "Need at least 2 options");
        require(endTime == 0 || endTime > startTime, "Bad time window");

        Poll poll = new Poll(org, msg.sender, title, description, options, startTime, endTime, restricted);
        pollAddr = address(poll);
        _orgPolls[org].push(pollAddr);
        emit PollCreated(org, msg.sender, pollAddr, title);
    }

    function getOrgPolls(address org) external view returns (address[] memory) {
        return _orgPolls[org];
    }
}
