module decentralized_voting::System {

    use 0x1::Event;
    use 0x1::Signer;
    use 0x1::Vector;

    struct Voter has key {
        id: u64,
        name: vector<u8>,
        has_voted: bool,
    }

    struct Candidate has key {
        id: u64,
        name: vector<u8>,
        votes: u64,
    }

    struct Election has key {
        id: u64,
        name: vector<u8>,
        start_time: u64,
        end_time: u64,
        candidates: vector<Candidate>,
        state: bool, // true if election is active
        results_finalized: bool,
    }

    struct VotingSystem has key {
        admin: address,
        voters: vector<Voter>,
        elections: vector<Election>,
    }

    public fun initialize_voting_system(admin: address): VotingSystem {
        VotingSystem {
            admin,
            voters: vector::empty<Voter>(),
            elections: vector::empty<Election>(),
        }
    }

    // Access control helper function for admin verification
    fun assert_admin(system: &VotingSystem, ctx: &Signer) {
        assert!(signer::address_of(ctx) == system.admin, 0x1001 /* EAdminRequired */);
    }

    public fun create_election(
        system: &mut VotingSystem,
        ctx: &Signer,
        name: vector<u8>,
        start_time: u64,
        end_time: u64,
        candidates: vector<Candidate>
    ) {
        assert_admin(system, ctx);
        // Validate start and end times
        let current_time = /* get current time function */;
        assert!(start_time >= current_time, 0x2001 /* EInvalidStartTime */);
        assert!(end_time > start_time, 0x2002 /* EInvalidEndTime */);

        let election_id = vector::length(&system.elections) as u64;
        let new_election = Election {
            id: election_id,
            name,
            start_time,
            end_time,
            candidates,
            state: true,
            results_finalized: false,
        };
        vector::push_back(&mut system.elections, new_election);
    }

    // Helper function to find election index by id
    fun find_election_index(system: &VotingSystem, election_id: u64): Option<u64> {
        let elections = &system.elections;
        let len = vector::length(elections);
        let i = 0;
        while (i < len) {
            let election = vector::borrow(elections, i);
            if (election.id == election_id) return option::some(i as u64);
            i = i + 1;
        }
        option::none()
    }

    public fun end_election(system: &mut VotingSystem, ctx: &Signer, election_id: u64) {
        assert_admin(system, ctx);
        let election_idx = find_election_index(system, election_id);
        assert!(option::is_some(election_idx), 0x3001 /* EElectionNotFound */);

        let idx = option::unwrap(election_idx);
        let election = vector::borrow_mut(&mut system.elections, idx);
        election.state = false;
    }

    public fun tally_votes(system: &mut VotingSystem, ctx: &Signer, election_id: u64) {
        assert_admin(system, ctx);
        let election_idx = find_election_index(system, election_id);
        assert!(option::is_some(election_idx), 0x3001 /* EElectionNotFound */);

        let idx = option::unwrap(election_idx);
        let election = vector::borrow_mut(&mut system.elections, idx);
        assert!(election.state == false, 0x3002 /* EElectionStillActive */);
        assert!(election.results_finalized == false, 0x3003 /* EResultsAlreadyFinalized */);

        // Mark the results as finalized
        election.results_finalized = true;
    }

    // Voter helper functions with improved error handling
    fun find_voter_index(system: &VotingSystem, voter_id: u64): Option<u64> {
        let voters = &system.voters;
        let len = vector::length(voters);
        let i = 0;
        while (i < len) {
            let voter = vector::borrow(voters, i);
            if (voter.id == voter_id) return option::some(i as u64);
            i = i + 1;
        }
        option::none()
    }

    public fun vote(
        system: &mut VotingSystem,
        voter_id: u64,
        election_id: u64,
        candidate_id: u64
    ) {
        let election_idx = find_election_index(system, election_id);
        assert!(option::is_some(election_idx), 0x3001 /* EElectionNotFound */);
        let idx = option::unwrap(election_idx);
        let election = vector::borrow_mut(&mut system.elections, idx);
        assert!(election.state, 0x3002 /* EElectionClosed */);

        let voter_idx = find_voter_index(system, voter_id);
        assert!(option::is_some(voter_idx), 0x4001 /* EVoterNotFound */);
        let v_idx = option::unwrap(voter_idx);
        let voter = vector::borrow_mut(&mut system.voters, v_idx);
        assert!(!voter.has_voted, 0x4002 /* EAlreadyVoted */);

        let candidates = &mut election.candidates;
        let len = vector::length(candidates);
        let mut found = false;

        for i in 0..len {
            let candidate = vector::borrow_mut(candidates, i);
            if candidate.id == candidate_id {
                candidate.votes += 1;
                found = true;
                break;
            }
        }
        assert!(found, 0x5001 /* ECandidateNotFound */);
        voter.has_voted = true;
    }

    public fun get_election_details(system: &VotingSystem, election_id: u64): Option<Election> {
        let election_idx = find_election_index(system, election_id);
        if option::is_none(election_idx) {
            return option::none();
        }
        let idx = option::unwrap(election_idx);
        let election = vector::borrow(&system.elections, idx);
        option::some(*election)
    }

    // Register voter with checks to avoid duplicates
    public fun register_voter(system: &mut VotingSystem, voter_id: u64, name: vector<u8>) {
        let voter_exists = find_voter_index(system, voter_id);
        assert!(option::is_none(voter_exists), 0x4003 /* EVoterAlreadyExists */);

        let new_voter = Voter {
            id: voter_id,
            name,
            has_voted: false,
        };
        vector::push_back(&mut system.voters, new_voter);
    }
}
