#[test_only]
module decentralized_voting::helpers {
    use sui::test_scenario::{Self as ts};

    const TEST_ADDRESS1: address = @0xee;

    public fun init_test_helper() : ts::Scenario{

       let  scenario_val = ts::begin(TEST_ADDRESS1);
       scenario_val
    }

}