module decentralized_voting::System {
    use std::string::String;
    use sui::event;
    use sui::tx_context::sender;
    use sui::object::new;

    // Errors
    const ENotAdmin: u64 = 1;
    const EVoterAlreadyRegistered: u64 = 2;
    const ENotAuthorized: u64 = 3;
    const ECandidateNotExists: u64 = 4;
    const EVoteAlreadyCasted: u64 = 5;
    const ENoVotesToRevoke: u64 = 6;
    const EInvalidElectionState: u64 = 7;

    // Structs
    public struct VotingSystem has key, store {
        id: UID,
        admin: address,
        voters: vector<Voter>,
        elections: vector<Election>,
        next_election_id: u64,
    }

    public struct Voter has key, store {
        id: UID,
        address: address, // Added field to store the voter's address
        details: String,
        has_voted: bool,
        vote_history: vector<u64>, // Stores election_id
    }

    public struct Election has key, store {
        id: UID,
        election_id: u64, // Field for ID comparison
        name: String,
        candidates: vector<Candidate>,
        vote_counts: vector<VoteCount>,
        state: u64,
        next_candidate_id: u64,
        start_time: u64,
        end_time: u64,
    }

    public struct Candidate has key, store {
        id: UID,
        candidate_id: u64, // Field for candidate ID
        name: String,
    }

    public struct VoteCount has store {
        candidate_id: u64,
        count: u64,
    }

    public struct CandidateDetails has store {
        candidate_id: u64,
        name: String,
    }

    public struct VoteCastedEvent has copy, drop {
        voter: address,
        election_id: u64,
        candidate_id: u64,
    }

    // Enums
    const ELECTION_STATE_UPCOMING: u64 = 0;
    const ELECTION_STATE_ONGOING: u64 = 1;
    const ELECTION_STATE_ENDED: u64 = 2;

    // Initialize Voting System
    public fun init_voting_system(ctx: &mut TxContext): VotingSystem {
        let id = new(ctx);
        let admin = sender(ctx);

        VotingSystem {
            id,
            admin,
            voters: vector::empty(),
            elections: vector::empty(),
            next_election_id: 1,
        }
    }

    // Helper function to find voter index
    fun find_voter_index(voters: &vector<Voter>, voter_address: address): u64 {
        let mut i = 0;
        while (i < vector::length(voters)) {
            let voter = vector::borrow(voters, i);
            if (voter_address == voter.address) { // Compare with voter.address
                return i
            };
            i = i + 1;
        };
        abort EVoterAlreadyRegistered
    }

    // Helper function to find election index
    fun find_election_index(elections: &vector<Election>, election_id: u64): u64 {
        let mut i = 0;
        while (i < vector::length(elections)) {
            let election = vector::borrow(elections, i);
            if (election.election_id == election_id) {
                return i
            };
            i = i + 1;
        };
        abort EInvalidElectionState
    }

    // Helper function to find candidate index
    fun find_candidate_index(candidates: &vector<Candidate>, candidate_id: u64): u64 {
        let mut i = 0;
        while (i < vector::length(candidates)) {
            let candidate = vector::borrow(candidates, i);
            if (candidate.candidate_id == candidate_id) {
                return i
            };
            i = i + 1;
        };
        abort ECandidateNotExists
    }

    // Helper function to find vote count index
    fun find_vote_count_index(vote_counts: &vector<VoteCount>, candidate_id: u64): u64 {
        let mut i = 0;
        while (i < vector::length(vote_counts)) {
            let vote_count = vector::borrow(vote_counts, i);
            if (vote_count.candidate_id == candidate_id) {
                return i
            };
            i = i + 1;
        };
        abort ECandidateNotExists
    }

    // Register Voter
    public fun register_voter(voting_system: &mut VotingSystem, _voter_address: address, voter_details: String, ctx: &mut TxContext) {
        let id = new(ctx);
        let vote_history = vector::empty();
        let voter = Voter {
            id,
            address: _voter_address,
            details: voter_details,
            has_voted: false,
            vote_history,
        };

        vector::push_back(&mut voting_system.voters, voter);
    }

    // Create Election
    public fun create_election(voting_system: &mut VotingSystem, election_name: String, start_time: u64, end_time: u64, ctx: &mut TxContext): u64 {
        assert!(voting_system.admin == sender(ctx), ENotAdmin);

        let election_id = voting_system.next_election_id;
        voting_system.next_election_id = election_id + 1;

        let id = new(ctx);
        let candidates = vector::empty();
        let vote_counts = vector::empty();
        let election = Election {
            id,
            election_id,
            name: election_name,
            candidates,
            vote_counts,
            state: ELECTION_STATE_UPCOMING,
            next_candidate_id: 1,
            start_time,
            end_time,
        };

        vector::push_back(&mut voting_system.elections, election);
        election_id
    }

    // Add Candidate
    public fun add_candidate(voting_system: &mut VotingSystem, election_id: u64, candidate_name: String, ctx: &mut TxContext) {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow_mut(&mut voting_system.elections, election_index);
        assert!(election.state == ELECTION_STATE_UPCOMING, EInvalidElectionState);

        let candidate_id = election.next_candidate_id;
        election.next_candidate_id = candidate_id + 1;

        let candidate = Candidate {
            id: new(ctx),
            candidate_id,
            name: candidate_name,
        };

        vector::push_back(&mut election.candidates, candidate);
        vector::push_back(&mut election.vote_counts, VoteCount { candidate_id, count: 0 });
    }

    // Vote
    public fun vote(voting_system: &mut VotingSystem, election_id: u64, candidate_id: u64, ctx: &mut TxContext) {
        let voter_address = sender(ctx);
        let voter_index = find_voter_index(&voting_system.voters, voter_address);
        let voter = vector::borrow_mut(&mut voting_system.voters, voter_index);
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow_mut(&mut voting_system.elections, election_index);
        assert!(election.state == ELECTION_STATE_ONGOING, EInvalidElectionState);

        let _candidate_index = find_candidate_index(&election.candidates, candidate_id);
        let vote_count_index = find_vote_count_index(&election.vote_counts, candidate_id);

        assert!(voter.has_voted == false, EVoteAlreadyCasted);

        voter.has_voted = true;
        vector::push_back(&mut voter.vote_history, election_id);

        let vote_count = vector::borrow_mut(&mut election.vote_counts, vote_count_index);
        vote_count.count = vote_count.count + 1;

        emit_vote_casted_event(voter_address, election_id, candidate_id);
    }

    // Emit Vote Casted Event
    public fun emit_vote_casted_event(voter: address, election_id: u64, candidate_id: u64) {
        let event = VoteCastedEvent {
            voter,
            election_id,
            candidate_id,
        };

        event::emit(event);
    }

    // Tally Votes
    public fun tally_votes(voting_system: &VotingSystem, election_id: u64): vector<VoteCount> {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow(&voting_system.elections, election_index);
        assert!(election.state == ELECTION_STATE_ENDED, EInvalidElectionState);

        let mut results = vector::empty<VoteCount>();
        let len = vector::length(&election.candidates);

        let mut i = 0;
        while (i < len) {
            let candidate_id = vector::borrow(&election.candidates, i).candidate_id;
            let vote_count_index = find_vote_count_index(&election.vote_counts, candidate_id);
            let vote_count = vector::borrow(&election.vote_counts, vote_count_index).count;
            vector::push_back(&mut results, VoteCount { candidate_id, count: vote_count });
            i = i + 1;
        };

        results
    }

    // End Election
    public fun end_election(voting_system: &mut VotingSystem, election_id: u64, ctx: &mut TxContext) {
        let sender_addr = sender(ctx);
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow_mut(&mut voting_system.elections, election_index);
        assert!(sender_addr == voting_system.admin, ENotAdmin);

        election.state = ELECTION_STATE_ENDED;
    }

    // Revoke Vote
    public fun revoke_vote(voting_system: &mut VotingSystem, election_id: u64, candidate_id: u64, ctx: &mut TxContext) {
        let voter_address = sender(ctx);
        let voter_index = find_voter_index(&voting_system.voters, voter_address);
        let voter = vector::borrow_mut(&mut voting_system.voters, voter_index);
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow_mut(&mut voting_system.elections, election_index);
        assert!(voter.has_voted, ENoVotesToRevoke);

        let mut i = 0;
        while (i < vector::length(&voter.vote_history)) {
            let voted_election_id = vector::borrow(&voter.vote_history, i);
            if (voted_election_id == election_id) {
                let vote_count_index = find_vote_count_index(&election.vote_counts, candidate_id);
                let vote_count = vector::borrow_mut(&mut election.vote_counts, vote_count_index);
                vote_count.count = vote_count.count - 1;

                voter.has_voted = false;
                vector::remove(&mut voter.vote_history, i);
                break
            };
            i = i + 1;
        };
    }

    // Verify Voter
    public fun verify_voter(voting_system: &VotingSystem, voter_address: address): bool {
        let voters = &voting_system.voters;
        let mut i = 0;
        while (i < vector::length(voters)) {
            let voter = vector::borrow(voters, i);
            if (voter_address == voter.address) {
                return true
            };
            i = i + 1;
        };
        false
    }

    // Get Election Results
    public fun get_election_results(voting_system: &VotingSystem, election_id: u64): vector<VoteCount> {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow(&voting_system.elections, election_index);
        let mut results = vector::empty<VoteCount>();

        let len = vector::length(&election.candidates);

        let mut i = 0;
        while (i < len) {
            let candidate_id = vector::borrow(&election.candidates, i).candidate_id;
            let vote_count_index = find_vote_count_index(&election.vote_counts, candidate_id);
            let vote_count = vector::borrow(&election.vote_counts, vote_count_index).count;
            vector::push_back(&mut results, VoteCount { candidate_id, count: vote_count });
            i = i + 1;
        };

        results
    }

    // Get Voter Details
    public fun get_voter_details(voting_system: &VotingSystem, voter_address: address): String {
        let voter_index = find_voter_index(&voting_system.voters, voter_address);
        let voter = vector::borrow(&voting_system.voters, voter_index);
        voter.details
    }

    // Update Voter Details
    public fun update_voter_details(voting_system: &mut VotingSystem, voter_address: address, new_details: String, ctx: &mut TxContext) {
        let voter_index = find_voter_index(&voting_system.voters, voter_address);
        let voter = vector::borrow_mut(&mut voting_system.voters, voter_index);
        assert!(voter_address == sender(ctx), ENotAuthorized);

        voter.details = new_details;
    }

    // Get Election Details
    public fun get_election_details(voting_system: &VotingSystem, election_id: u64): (String, vector<CandidateDetails>, u64, u64, u64) {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow(&voting_system.elections, election_index);
        let mut candidate_names = vector::empty<CandidateDetails>();

        let len = vector::length(&election.candidates);

        let mut i = 0;
        while (i < len) {
            let candidate = vector::borrow(&election.candidates, i);
            vector::push_back(&mut candidate_names, CandidateDetails { candidate_id: candidate.candidate_id, name: candidate.name });
            i = i + 1;
        };

        (election.name, candidate_names, election.state, election.start_time, election.end_time)
    }

    // Get Candidates
    public fun get_candidates(voting_system: &VotingSystem, election_id: u64): vector<CandidateDetails> {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow(&voting_system.elections, election_index);
        let mut candidates = vector::empty<CandidateDetails>();

        let len = vector::length(&election.candidates);

        let mut i = 0;
        while (i < len) {
            let candidate = vector::borrow(&election.candidates, i);
            vector::push_back(&mut candidates, CandidateDetails { candidate_id: candidate.candidate_id, name: candidate.name });
            i = i + 1;
        };

        candidates
    }
}
