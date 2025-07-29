// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Test {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedCandidateId;
        address delegatedTo;
        bool hasDelegated;
    }

    address public administrator;
    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    uint public votingStartTime;
    uint public votingEndTime;
    bool public votingOpen;

    event CandidateAdded(uint id, string name);
    event VoterRegistered(address voterAddress);
    event VoteCast(address voterAddress, uint candidateId);
    event VoteDelegated(address from, address to);
    event VotingPeriodSet(uint startTime, uint endTime);

    constructor(uint _votingStartTime, uint _votingEndTime) {
        administrator = msg.sender;
        setVotingPeriod(_votingStartTime, _votingEndTime);
    }

    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Only administrator can perform this action.");
        _;
    }

    modifier onlyDuringVotingPeriod() {
        require(votingOpen, "Voting is not open at this time.");
        _;
    }

    function setVotingPeriod(uint _startTime, uint _endTime) public onlyAdministrator {
        require(_startTime < _endTime, "End time must be after start time.");
        votingStartTime = _startTime;
        votingEndTime = _endTime;
        votingOpen = block.timestamp >= _startTime && block.timestamp <= _endTime;
        emit VotingPeriodSet(_startTime, _endTime);
    }

    function addCandidate(string memory _name) public onlyAdministrator {
        uint newCandidateId = candidates.length;
        candidates.push(Candidate({
            id: newCandidateId,
            name: _name,
            voteCount: 0
        }));
        emit CandidateAdded(newCandidateId, _name);
    }

    function registerVoter(address _voterAddress) public onlyAdministrator {
        require(!voters[_voterAddress].isRegistered, "Voter is already registered.");
        voters[_voterAddress].isRegistered = true;
        emit VoterRegistered(_voterAddress);
    }

    function vote(uint _candidateId) public onlyDuringVotingPeriod {
        require(voters[msg.sender].isRegistered, "You are not registered to vote.");
        require(!voters[msg.sender].hasVoted, "You have already voted.");
        require(_candidateId < candidates.length, "Invalid candidate ID.");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = _candidateId;
        candidates[_candidateId].voteCount++;
        emit VoteCast(msg.sender, _candidateId);
    }

    function delegateVote(address _to) public onlyDuringVotingPeriod {
        require(voters[msg.sender].isRegistered, "You are not registered to vote.");
        require(!voters[msg.sender].hasVoted, "You have already voted.");
        require(_to != msg.sender, "Cannot delegate vote to yourself.");
        require(voters[_to].isRegistered, "Delegatee is not registered to vote.");

        voters[msg.sender].hasDelegated = true;
        voters[msg.sender].delegatedTo = _to;
        emit VoteDelegated(msg.sender, _to);
    }

    function getCandidate(uint _index) public view returns (uint, string memory, uint) {
        require(_index < candidates.length, "Invalid candidate index.");
        Candidate memory candidate = candidates[_index];
        return (candidate.id, candidate.name, candidate.voteCount);
    }

    function getVoterStatus(address _voterAddress) public view returns (bool, bool, uint, address, bool) {
        Voter memory voter = voters[_voterAddress];
        return (voter.isRegistered, voter.hasVoted, voter.votedCandidateId, voter.delegatedTo, voter.hasDelegated);
    }
}