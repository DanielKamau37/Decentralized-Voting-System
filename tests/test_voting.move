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
    
    #[test]
    public fun test() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        next_tx(scenario, TEST_ADDRESS1);
        {

       
        };

        ts::end(scenario_test);
    }

}