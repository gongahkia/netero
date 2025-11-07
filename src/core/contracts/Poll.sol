// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract Poll is ERC2771Context {
    enum State { Draft, Active, Ended, Finalized }

    address public immutable org;
    address public admin;

    string public title;
    string public description;

    string[] private _options;
    uint256[] private _tallies;

    uint64 public startTime; // 0 = immediate
    uint64 public endTime;   // 0 = no scheduled end
    bool   public restricted; // if true, only allowlisted/proved addresses can vote
    bool   public privateMode; // if true, use commit-reveal instead of open voting
    bytes32 public merkleRoot; // optional allowlist merkle root

    State public state;

    mapping(address => bool) public allowlist;
    mapping(address => bool) public hasVoted;
    mapping(address => bytes32) public commitments; // commit-reveal
    mapping(address => bool) public hasRevealed;    // commit-reveal

    event StateChanged(State indexed oldState, State indexed newState);
    event VoterAllowlisted(address indexed voter, bool allowed);
    event Voted(address indexed voter, uint256 indexed optionIndex);
    event VoteCommitted(address indexed voter, bytes32 commitment);
    event VoteRevealed(address indexed voter, uint256 indexed optionIndex);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Not admin");
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
        bool _restricted,
        bool _privateMode,
        address _trustedForwarder,
        bytes32 _merkleRoot
    ) ERC2771Context(_trustedForwarder) {
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
        privateMode = _privateMode;
        merkleRoot = _merkleRoot;
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

    function setMerkleRoot(bytes32 _root) external onlyAdmin {
        require(state == State.Draft, "Only in draft");
        merkleRoot = _root;
    }

    function setSchedule(uint64 _startTime, uint64 _endTime) external onlyAdmin {
        _maybeAutoClose();
        require(state == State.Draft || state == State.Active, "Locked");
        require(_endTime == 0 || _endTime > _startTime, "Bad window");
        startTime = _startTime;
        endTime = _endTime;
    }

    function setRestricted(bool _restricted) external onlyAdmin {
        require(state == State.Draft, "Only in draft");
        restricted = _restricted;
    }

    function setPrivateMode(bool _private) external onlyAdmin {
        require(state == State.Draft, "Only in draft");
        privateMode = _private;
    }

    function activate() external onlyAdmin {
        _maybeAutoClose();
        require(state == State.Draft, "Not draft");
        state = State.Active;
        emit StateChanged(State.Draft, State.Active);
    }

    function end() external onlyAdmin {
        _maybeAutoClose();
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
        _maybeAutoClose();
        require(state == State.Active, "Not active");
        if (startTime != 0) require(block.timestamp >= startTime, "Too early");
        if (endTime != 0) require(block.timestamp <= endTime, "Too late");
        require(!privateMode, "Use commit");

        if (restricted) {
            require(allowlist[_msgSender()], "Not allowlisted");
        }
        require(!hasVoted[_msgSender()], "Already voted");
        require(optionIndex < _options.length, "Invalid option");
        hasVoted[_msgSender()] = true;
        _tallies[optionIndex] += 1;
        emit Voted(_msgSender(), optionIndex);
    }

    // Commit-reveal
    // commitment = keccak256(abi.encodePacked(voter, optionIndex, salt))
    function commit(bytes32 commitment, bytes32[] calldata proof) external {
        _maybeAutoClose();
        require(privateMode, "Not private");
        require(state == State.Active, "Not active");
        if (startTime != 0) require(block.timestamp >= startTime, "Too early");
        if (endTime != 0) require(block.timestamp <= endTime, "Too late");
        address sender = _msgSender();
        if (restricted) {
            if (merkleRoot != bytes32(0)) {
                bytes32 leaf = keccak256(abi.encodePacked(sender));
                require(MerkleProof.verifyCalldata(proof, merkleRoot, leaf), "Not allowlisted");
            } else {
                require(allowlist[sender], "Not allowlisted");
            }
        }
        require(commitments[sender] == bytes32(0), "Already committed");
        commitments[sender] = commitment;
        emit VoteCommitted(sender, commitment);
    }

    function reveal(uint256 optionIndex, bytes32 salt) external {
        require(privateMode, "Not private");
        require(state == State.Ended, "Not reveal phase");
        address sender = _msgSender();
        require(!hasRevealed[sender], "Already revealed");
        require(optionIndex < _options.length, "Invalid option");
        bytes32 expect = keccak256(abi.encodePacked(sender, optionIndex, salt));
        require(commitments[sender] == expect, "Bad reveal");
        hasRevealed[sender] = true;
        _tallies[optionIndex] += 1;
        emit VoteRevealed(sender, optionIndex);
        emit Voted(sender, optionIndex);
    }

    // Reads
    function optionCount() external view returns (uint256) { return _options.length; }
    function getOptions() external view returns (string[] memory) { return _options; }
    function getTallies() external view returns (uint256[] memory) { return _tallies; }

    function remainingSeconds() external view returns (int64) {
        if (endTime == 0) return int64(-1);
        int256 diff = int256(uint256(endTime)) - int256(uint256(block.timestamp));
        return int64(diff);
    }

    function autoCloseIfExpired() external {
        _maybeAutoClose();
    }

    function _maybeAutoClose() internal {
        if (state == State.Active && endTime != 0 && block.timestamp > endTime) {
            State previous = state;
            state = State.Ended;
            emit StateChanged(previous, State.Ended);
        }
    }

    // ERC2771 overrides
    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        sender = ERC2771Context._msgSender();
    }
    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
