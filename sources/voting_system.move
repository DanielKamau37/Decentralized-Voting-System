module decentralized_voting::voting_system {
    use std::string::String;
    use sui::event;
    use sui::tx_context::sender;
    use sui::object::new;

    // Error Codes
    // Defining constants for different error cases to handle exceptions in the contract
    const ENotAdmin: u64 = 1;                // Error: Action requires admin privileges
    const EVoterAlreadyRegistered: u64 = 2;  // Error: Voter already registered
    const ENotAuthorized: u64 = 3;           // Error: Unauthorized action
    const ECandidateNotExists: u64 = 4;      // Error: Candidate does not exist
    const EVoteAlreadyCasted: u64 = 5;       // Error: Voter has already cast a vote
    const ENoVotesToRevoke: u64 = 6;         // Error: No votes to revoke for this voter
    const EInvalidElectionState: u64 = 7;    // Error: Invalid state for election operation

    // VotingSystem struct representing the primary voting system state
    public struct VotingSystem has key, store {
        id: UID,                             // Unique ID for the voting system
        admin: address,                      // Address of the administrator
        voters: vector<Voter>,               // List of registered voters
        elections: vector<Election>,         // List of elections in the system
        next_election_id: u64,               // ID for the next created election
    }

    // Voter struct representing a single voter's information
    public struct Voter has key, store {
        id: UID,                             // Unique ID for each voter
        address: address,                    // Address of the voter
        details: String,                     // Additional voter details
        has_voted: bool,                     // Status indicating if the voter has cast a vote
        vote_history: vector<u64>,           // Stores election IDs that the voter has participated in
    }

    // Election struct representing the details of a single election
    public struct Election has key, store {
        id: UID,                             // Unique ID for each election
        election_id: u64,                    // Unique identifier for the election
        name: String,                        // Name of the election
        candidates: vector<Candidate>,       // List of candidates in the election
        vote_counts: vector<VoteCount>,      // Stores the vote count for each candidate
        state: u64,                          // Current state of the election
        next_candidate_id: u64,              // ID for the next candidate added to the election
        start_time: u64,                     // Election start time
        end_time: u64,                       // Election end time
    }

    // Candidate struct for each candidate in an election
    public struct Candidate has key, store {
        id: UID,                             // Unique ID for each candidate
        candidate_id: u64,                   // Unique identifier for the candidate
        name: String,                        // Candidate's name
    }

    // VoteCount struct to keep track of each candidate's vote count in an election
    public struct VoteCount has store {
        candidate_id: u64,                   // Candidate ID associated with the vote count
        count: u64,                          // Number of votes received by the candidate
    }

    // CandidateDetails struct to provide detailed information about a candidate
    public struct CandidateDetails has store {
        candidate_id: u64,                   // Unique identifier for the candidate
        name: String,                        // Candidate's name
    }

    // Event struct emitted each time a vote is casted
    public struct VoteCastedEvent has copy, drop {
        voter: address,                      // Address of the voter who casted the vote
        election_id: u64,                    // ID of the election in which the vote was casted
        candidate_id: u64,                   // ID of the candidate who received the vote
    }

    // Enum-like Constants for Election States
    const ELECTION_STATE_UPCOMING: u64 = 0; // Election state: Upcoming
    const ELECTION_STATE_ONGOING: u64 = 1;  // Election state: Ongoing
    const ELECTION_STATE_ENDED: u64 = 2;    // Election state: Ended

    // Initialize Voting System and Share Object
    // Creates a new VotingSystem object and shares it properly to avoid runtime issues
    public fun init_voting_system(ctx: &mut TxContext) {
        let id = new(ctx);                   // Generate a unique ID for the voting system
        let admin = sender(ctx);             // Set the creator as the admin of the voting system

        let voting_system = VotingSystem {
            id,
            admin,
            voters: vector::empty(),
            elections: vector::empty(),
            next_election_id: 1,
        };
        // Ensure the VotingSystem object is shared, not returned, to avoid runtime errors
        transfer::share_object(voting_system);
    }

    // Helper function to find the index of a voter in the voters vector
    fun find_voter_index(voters: &vector<Voter>, voter_address: address): u64 {
        let mut i = 0;
        while (i < vector::length(voters)) {
            let voter = vector::borrow(voters, i);
            if (voter_address == voter.address) {
                return i                      // Return index if address matches
            };
            i = i + 1;
        };
        abort EVoterAlreadyRegistered         // Abort if voter is already registered
    }

    // Helper function to find the index of an election in the elections vector
    fun find_election_index(elections: &vector<Election>, election_id: u64): u64 {
        let mut i = 0;
        while (i < vector::length(elections)) {
            let election = vector::borrow(elections, i);
            if (election.election_id == election_id) {
                return i                      // Return index if election_id matches
            };
            i = i + 1;
        };
        abort EInvalidElectionState           // Abort if election ID is invalid
    }

    // Helper function to find the index of a candidate in the candidates vector
    fun find_candidate_index(candidates: &vector<Candidate>, candidate_id: u64): u64 {
        let mut i = 0;
        while (i < vector::length(candidates)) {
            let candidate = vector::borrow(candidates, i);
            if (candidate.candidate_id == candidate_id) {
                return i                      // Return index if candidate ID matches
            };
            i = i + 1;
        };
        abort ECandidateNotExists             // Abort if candidate does not exist
    }

    // Helper function to find the index of a candidate's vote count in vote_counts vector
    fun find_vote_count_index(vote_counts: &vector<VoteCount>, candidate_id: u64): u64 {
        let mut i = 0;
        while (i < vector::length(vote_counts)) {
            let vote_count = vector::borrow(vote_counts, i);
            if (vote_count.candidate_id == candidate_id) {
                return i                      // Return index if candidate ID matches
            };
            i = i + 1;
        };
        abort ECandidateNotExists             // Abort if candidate vote count does not exist
    }

    // Register a new voter in the system
    public fun register_voter(voting_system: &mut VotingSystem, _voter_address: address, voter_details: String, ctx: &mut TxContext) {
        let id = new(ctx);                    // Create unique ID for voter
        let vote_history = vector::empty();   // Initialize empty vote history
        let voter = Voter {
            id,
            address: _voter_address,
            details: voter_details,
            has_voted: false,
            vote_history,
        };

        vector::push_back(&mut voting_system.voters, voter); // Add voter to the voting system
    }

    // Create a new election within the voting system
    public fun create_election(voting_system: &mut VotingSystem, election_name: String, start_time: u64, end_time: u64, ctx: &mut TxContext): u64 {
        assert!(voting_system.admin == sender(ctx), ENotAdmin); // Only admin can create an election

        let election_id = voting_system.next_election_id;       // Fetch next election ID
        voting_system.next_election_id = election_id + 1;       // Update for next election

        let id = new(ctx);
        let candidates = vector::empty();                       // Initialize empty candidate list
        let vote_counts = vector::empty();                      // Initialize empty vote count list
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

        vector::push_back(&mut voting_system.elections, election); // Add election to the system
        election_id
    }

    // Add a candidate to an election
    public fun add_candidate(voting_system: &mut VotingSystem, election_id: u64, candidate_name: String, ctx: &mut TxContext) {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow_mut(&mut voting_system.elections, election_index);
        assert!(election.state == ELECTION_STATE_UPCOMING, EInvalidElectionState); // Ensure election is upcoming

        let candidate_id = election.next_candidate_id;          // Fetch candidate ID
        election.next_candidate_id = candidate_id + 1;          // Increment for next candidate

        let candidate = Candidate {
            id: new(ctx),
            candidate_id,
            name: candidate_name,
        };

        vector::push_back(&mut election.candidates, candidate); // Add candidate to the election
        vector::push_back(&mut election.vote_counts, VoteCount { candidate_id, count: 0 }); // Initialize vote count
    }

    // Cast a vote in an election
    public fun vote(voting_system: &mut VotingSystem, election_id: u64, candidate_id: u64, ctx: &mut TxContext) {
        let voter_address = sender(ctx);                        // Address of the voting user
        let voter_index = find_voter_index(&voting_system.voters, voter_address);
        let voter = vector::borrow_mut(&mut voting_system.voters, voter_index);

        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow_mut(&mut voting_system.elections, election_index);
        assert!(election.state == ELECTION_STATE_ONGOING, EInvalidElectionState); // Ensure election is ongoing

        let _candidate_index = find_candidate_index(&election.candidates, candidate_id);
        let vote_count_index = find_vote_count_index(&election.vote_counts, candidate_id);

        assert!(voter.has_voted == false, EVoteAlreadyCasted);  // Ensure voter hasn't already voted
        voter.has_voted = true;                                 // Mark voter as having voted
        vector::push_back(&mut voter.vote_history, election_id);

        let vote_count = vector::borrow_mut(&mut election.vote_counts, vote_count_index);
        vote_count.count = vote_count.count + 1;                // Increment candidate's vote count

        emit_vote_casted_event(voter_address, election_id, candidate_id); // Emit vote event
    }

    // Emit a vote casted event for record-keeping and tracking
    public fun emit_vote_casted_event(voter: address, election_id: u64, candidate_id: u64) {
        let event = VoteCastedEvent {
            voter,
            election_id,
            candidate_id,
        };
        event::emit(event);                                     // Emit the vote casted event
    }

    // Tally the votes for a completed election
    public fun tally_votes(voting_system: &VotingSystem, election_id: u64): vector<VoteCount> {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow(&voting_system.elections, election_index);
        assert!(election.state == ELECTION_STATE_ENDED, EInvalidElectionState); // Ensure election has ended

        let mut results = vector::empty<VoteCount>();           // Initialize results vector
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

    // End an election, setting its state to "ended"
    public fun end_election(voting_system: &mut VotingSystem, election_id: u64, ctx: &mut TxContext) {
        let sender_addr = sender(ctx);                          // Address of the ending user
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow_mut(&mut voting_system.elections, election_index);
        assert!(sender_addr == voting_system.admin, ENotAdmin); // Only admin can end the election

        election.state = ELECTION_STATE_ENDED;                  // Set election state to "ended"
    }

    // Revoke a vote if a voter wants to take back their vote
    public fun revoke_vote(voting_system: &mut VotingSystem, election_id: u64, candidate_id: u64, ctx: &mut TxContext) {
        let voter_address = sender(ctx);                        // Address of the revoking user
        let voter_index = find_voter_index(&voting_system.voters, voter_address);
        let voter = vector::borrow_mut(&mut voting_system.voters, voter_index);
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow_mut(&mut voting_system.elections, election_index);
        assert!(voter.has_voted, ENoVotesToRevoke);             // Ensure voter has voted

        let mut i = 0;
        while (i < vector::length(&voter.vote_history)) {
            let voted_election_id = vector::borrow(&voter.vote_history, i);
            if (voted_election_id == election_id) {
                let vote_count_index = find_vote_count_index(&election.vote_counts, candidate_id);
                let vote_count = vector::borrow_mut(&mut election.vote_counts, vote_count_index);
                vote_count.count = vote_count.count - 1;        // Decrement candidate's vote count

                voter.has_voted = false;                        // Mark voter as not having voted
                vector::remove(&mut voter.vote_history, i);     // Remove election from vote history
                break
            };
            i = i + 1;
        };
    }

    // Verify if a given address is registered as a voter
    public fun verify_voter(voting_system: &VotingSystem, voter_address: address): bool {
        let voters = &voting_system.voters;
        let mut i = 0;
        while (i < vector::length(voters)) {
            let voter = vector::borrow(voters, i);
            if (voter_address == voter.address) {
                return true                  // Return true if address matches
            };
            i = i + 1;
        };
        false                                 // Return false if voter not found
    }

    // Get the election results for a specific election
    public fun get_election_results(voting_system: &VotingSystem, election_id: u64): vector<VoteCount> {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow(&voting_system.elections, election_index);
        let mut results = vector::empty<VoteCount>();           // Initialize results vector

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

    // Retrieve the details of a voter by their address
    public fun get_voter_details(voting_system: &VotingSystem, voter_address: address): String {
        let voter_index = find_voter_index(&voting_system.voters, voter_address);
        let voter = vector::borrow(&voting_system.voters, voter_index);
        voter.details                               // Return details of the voter
    }

    // Update the details of a voter if they are the sender
    public fun update_voter_details(voting_system: &mut VotingSystem, voter_address: address, new_details: String, ctx: &mut TxContext) {
        let voter_index = find_voter_index(&voting_system.voters, voter_address);
        let voter = vector::borrow_mut(&mut voting_system.voters, voter_index);
        assert!(voter_address == sender(ctx), ENotAuthorized); // Ensure only voter can update details

        voter.details = new_details;               // Update voter details
    }

    // Retrieve details about a specific election, including candidates
    public fun get_election_details(voting_system: &VotingSystem, election_id: u64): (String, vector<CandidateDetails>, u64, u64, u64) {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow(&voting_system.elections, election_index);
        let mut candidate_names = vector::empty<CandidateDetails>(); // Initialize candidate names list

        let len = vector::length(&election.candidates);

        let mut i = 0;
        while (i < len) {
            let candidate = vector::borrow(&election.candidates, i);
            vector::push_back(&mut candidate_names, CandidateDetails { candidate_id: candidate.candidate_id, name: candidate.name });
            i = i + 1;
        };

        (election.name, candidate_names, election.state, election.start_time, election.end_time) // Return election details
    }

    // Get a list of candidates for a particular election
    public fun get_candidates(voting_system: &VotingSystem, election_id: u64): vector<CandidateDetails> {
        let election_index = find_election_index(&voting_system.elections, election_id);
        let election = vector::borrow(&voting_system.elections, election_index);
        let mut candidates = vector::empty<CandidateDetails>(); // Initialize candidates vector

        let len = vector::length(&election.candidates);

        let mut i = 0;
        while (i < len) {
            let candidate = vector::borrow(&election.candidates, i);
            vector::push_back(&mut candidates, CandidateDetails { candidate_id: candidate.candidate_id, name: candidate.name });
            i = i + 1;
        };

        candidates                                       // Return list of candidates
    }
}
