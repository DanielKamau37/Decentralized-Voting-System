#[test_only]
module decentralized_voting::test_voting {
    use sui::test_scenario::{Self as ts, next_tx, ctx};
    use sui::test_utils::{assert_eq};
    use sui::coin::{Coin, mint_for_testing};
    use sui::clock::{Clock, Self};
    use sui::sui::{SUI};

    use std::string::{Self};
    use std::debug::print;

    use decentralized_voting::helpers::init_test_helper;
    use decentralized_voting::voting_system::{Self as vs, VotingSystem, Voter, Election, Candidate};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS1: address = @0xee;
    const TEST_ADDRESS2: address = @0xbb;

    #[test]
    #[expected_failure(abort_code = decentralized_voting::voting_system::ENotAdmin)]
    public fun test_not_admin() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // create the voting shared object 
        next_tx(scenario, TEST_ADDRESS1);
        {
            vs::init_voting_system(ts::ctx(scenario));

        };

        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
            let voter_det = string::utf8(b"bytsdses");
            vs::register_voter(&mut voting, voter_det, ts::ctx(scenario));

            ts::return_shared(voting);

        };
        // Address2 joining the dao
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
            let voter_det = string::utf8(b"bytsdses");
            vs::register_voter(&mut voting, voter_det, ts::ctx(scenario));

            ts::return_shared(voting);
        };

        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
            let election = string::utf8(b"bytsdses");
            let start: u64 = 1000000;
            let end: u64 = 2000000;

            let _num =  vs::create_election(
            &mut voting,
            election,
            start,
            end,
            ts::ctx(scenario)
            );
            ts::return_shared(voting);
        };

        ts::end(scenario_test);
    }

    #[test]
    public fun test() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // create the voting shared object 
        next_tx(scenario, TEST_ADDRESS1);
        {
            vs::init_voting_system(ts::ctx(scenario));

        };

        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
            let voter_det = string::utf8(b"bytsdses");
            vs::register_voter(&mut voting, voter_det, ts::ctx(scenario));

            ts::return_shared(voting);

        };
        // Address2 joining the dao
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
            let voter_det = string::utf8(b"bytsdses");
            vs::register_voter(&mut voting, voter_det, ts::ctx(scenario));

            ts::return_shared(voting);
        };
        // admin creates voting
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
            let election = string::utf8(b"election1");
            let start: u64 = 1000000;
            let end: u64 = 2000000;

            let _num =  vs::create_election(
            &mut voting,
            election,
            start,
            end,
            ts::ctx(scenario)
            );
            ts::return_shared(voting);
        };
        // admin creates election 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
            let election = string::utf8(b"election1");
            let start: u64 = 1000000;
            let end: u64 = 2000000;

            let _num =  vs::create_election(
            &mut voting,
            election,
            start,
            end,
            ts::ctx(scenario)
            );
            ts::return_shared(voting);
        };
        
        // get voter object 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
            let details = string::utf8(b"bytsdses");
          
            vs::register_voter(
            &mut voting,
            details,
            ts::ctx(scenario)
            );
            ts::return_shared(voting);
        };

        // add candidate
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
    
            let index = 1;
            let election = string::utf8(b"election1");

            vs::add_candidate(
            &mut voting,
            index,
            election,
            ts::ctx(scenario)
            );
            ts::return_shared(voting);
        };

        // add candidate
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut voting = ts::take_shared<VotingSystem>(scenario);
    
            let election = 1;
            let canditate_id = 1;

            vs::vote(
            &mut voting,
            election,
            canditate_id,
            ts::ctx(scenario)
            );
            ts::return_shared(voting);
        };



        ts::end(scenario_test);
    }

}