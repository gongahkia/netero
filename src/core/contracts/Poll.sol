// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Poll {
    enum State { Draft, Active, Ended, Finalized }

    address public immutable org;
    address public admin;

    string public title;
    string public description;

    string[] private _options;
    uint256[] private _tallies;

    uint64 public startTime; // 0 = immediate
    uint64 public endTime;   // 0 = no scheduled end
    bool   public restricted; // if true, only allowlisted addresses can vote

    State public state;

    mapping(address => bool) public allowlist;
    mapping(address => bool) public hasVoted;

    event StateChanged(State indexed oldState, State indexed newState);
    event VoterAllowlisted(address indexed voter, bool allowed);
    event Voted(address indexed voter, uint256 indexed optionIndex);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(
        address _org,
        address _admin,
        string memory _title,
        string memory _description,
        string[] memory options,
        uint64 _startTime,
        uint64 _endTime,
        bool _restricted
    ) {
        require(options.length >= 2, "Need at least 2 options");
        org = _org;
        admin = _admin;
        title = _title;
        description = _description;
        for (uint256 i = 0; i < options.length; i++) {
            _options.push(options[i]);
            _tallies.push(0);
        }
        startTime = _startTime;
        endTime = _endTime;
        restricted = _restricted;
        state = State.Draft;
    }

    // Admin actions
    function setAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Zero addr");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function setAllowlisted(address[] calldata voters, bool allowed) external onlyAdmin {
        for (uint256 i = 0; i < voters.length; i++) {
            allowlist[voters[i]] = allowed;
            emit VoterAllowlisted(voters[i], allowed);
        }
    }

    function setSchedule(uint64 _startTime, uint64 _endTime) external onlyAdmin {
        require(state == State.Draft || state == State.Active, "Locked");
        require(_endTime == 0 || _endTime > _startTime, "Bad window");
        startTime = _startTime;
        endTime = _endTime;
    }

    function setRestricted(bool _restricted) external onlyAdmin {
        require(state == State.Draft, "Only in draft");
        restricted = _restricted;
    }

    function activate() external onlyAdmin {
        require(state == State.Draft, "Not draft");
        state = State.Active;
        emit StateChanged(State.Draft, State.Active);
    }

    function end() external onlyAdmin {
        require(state == State.Active, "Not active");
        state = State.Ended;
        emit StateChanged(State.Active, State.Ended);
    }

    function finalize() external onlyAdmin {
        require(state == State.Ended, "Not ended");
        state = State.Finalized;
        emit StateChanged(State.Ended, State.Finalized);
    }

    // Voting
    function vote(uint256 optionIndex) external {
        require(state == State.Active, "Not active");
        if (startTime != 0) require(block.timestamp >= startTime, "Too early");
        if (endTime != 0) require(block.timestamp <= endTime, "Too late");

        if (restricted) {
            require(allowlist[msg.sender], "Not allowlisted");
        }
        require(!hasVoted[msg.sender], "Already voted");
        require(optionIndex < _options.length, "Invalid option");

        hasVoted[msg.sender] = true;
        _tallies[optionIndex] += 1;
        emit Voted(msg.sender, optionIndex);
    }

    // Reads
    function optionCount() external view returns (uint256) { return _options.length; }
    function getOptions() external view returns (string[] memory) { return _options; }
    function getTallies() external view returns (uint256[] memory) { return _tallies; }
}
