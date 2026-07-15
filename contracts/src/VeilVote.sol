// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title VeilVote
/// @notice A single-proposal secret ballot using Seismic shielded types.
/// @dev Individual participation and running tallies remain confidential.
contract VeilVote {
    enum Outcome {
        Rejected,
        Accepted,
        Tied
    }

    error AlreadyVoted();
    error EmptyProposal();
    error InvalidVotingWindow();
    error NotAdmin();
    error NotEligible();
    error VotingAlreadyStarted();
    error VotingClosed();
    error VotingStillOpen();
    error ZeroAddress();

    address public immutable admin;
    string public proposal;
    uint256 public immutable votingStart;
    uint256 public immutable votingEnd;

    mapping(address => bool) public isEligible;
    mapping(address => sbool) private hasVoted;
    suint256 private votesFor;
    suint256 private votesAgainst;

    event VoterAdded(address indexed voter);
    event BallotSubmitted(address indexed voter);

    constructor(string memory proposal_, uint256 votingStart_, uint256 votingEnd_) {
        if (bytes(proposal_).length == 0) revert EmptyProposal();
        if (votingStart_ < block.timestamp || votingEnd_ <= votingStart_) {
            revert InvalidVotingWindow();
        }

        admin = msg.sender;
        proposal = proposal_;
        votingStart = votingStart_;
        votingEnd = votingEnd_;
    }

    /// @notice Adds voters before the voting period begins.
    function addVoters(address[] calldata voters) external {
        if (msg.sender != admin) revert NotAdmin();
        if (block.timestamp >= votingStart) revert VotingAlreadyStarted();

        for (uint256 i; i < voters.length; ++i) {
            address voter = voters[i];
            if (voter == address(0)) revert ZeroAddress();
            if (!isEligible[voter]) {
                isEligible[voter] = true;
                emit VoterAdded(voter);
            }
        }
    }

    /// @notice Casts a confidential ballot. True is for; false is against.
    /// @dev The event proves participation but never exposes the ballot choice.
    function vote(sbool inFavor) external {
        if (block.timestamp < votingStart || block.timestamp >= votingEnd) {
            revert VotingClosed();
        }
        if (!isEligible[msg.sender]) revert NotEligible();
        if (bool(hasVoted[msg.sender])) revert AlreadyVoted();

        hasVoted[msg.sender] = sbool(true);
        if (bool(inFavor)) {
            votesFor += suint256(1);
        } else {
            votesAgainst += suint256(1);
        }

        emit BallotSubmitted(msg.sender);
    }

    /// @notice Reveals only the aggregate totals after voting closes.
    function results() public view returns (uint256 forVotes, uint256 againstVotes) {
        if (block.timestamp < votingEnd) revert VotingStillOpen();
        forVotes = uint256(votesFor);
        againstVotes = uint256(votesAgainst);
    }

    function outcome() external view returns (Outcome) {
        (uint256 forVotes, uint256 againstVotes) = results();
        if (forVotes > againstVotes) return Outcome.Accepted;
        if (againstVotes > forVotes) return Outcome.Rejected;
        return Outcome.Tied;
    }
}
