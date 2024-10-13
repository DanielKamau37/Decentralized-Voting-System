# Decentralized Voting System for Sui

The **Decentralized Voting System** is a secure and transparent on-chain voting platform built using the **Sui Move language**. This system allows election organizers to create and manage elections on-chain while enabling users to register as voters and cast their votes in a secure, tamper-proof environment. It is designed for maximum transparency, ensuring that every vote is publicly verifiable, and results can be trusted without the need for centralized intermediaries.

### Key Features:
- **On-chain Elections**: Secure election creation and management with unique election IDs.
- **Voter Registration**: Unique voter registration and history tracking for ensuring one vote per election.
- **Candidate Management**: Add multiple candidates to elections.
- **Voting**: Secure vote casting and transparent vote counting.
- **Event Emissions**: Track events for voting actions (e.g., vote casting) for easy analysis.
- **Election Result Tallying**: Automatic counting of votes at the end of an election.
- **Transparency**: Publicly accessible election results and audit trails.
  
---

## Table of Contents

1. [Platform Overview](#platform-overview)
2. [Core Concepts](#core-concepts)
3. [Platform Components](#platform-components)
    - [Errors](#errors)
    - [Structs](#structs)
    - [Functions](#functions)
4. [How it Benefits the Sui Community](#how-it-benefits-the-sui-community)
5. [Deployment Instructions](#deployment-instructions)
6. [Testing Instructions](#testing-instructions)

---

## Platform Overview

The Decentralized Voting System leverages the power of the Sui blockchain to offer a transparent and decentralized way to manage voting systems. By using **Sui Move**, the system enables users to create elections, register voters, manage candidates, and ensure that votes are cast and counted transparently. It is designed to prevent unauthorized access, double voting, and tampering with election results.

This project aims to serve communities, organizations, or decentralized applications (dApps) looking for a reliable way to conduct elections or polls that require immutable, publicly-verifiable records.

---

## Core Concepts

### Voter Registration:
Voters are uniquely registered using their **Sui addresses** and can only vote once per election. The voting system ensures that each vote is tied to a specific voter, and voters cannot change their votes after casting them.

### Election Management:
Admins create elections with a **start and end time**, and manage the candidates for each election. An election can either be "upcoming," "ongoing," or "ended." Once an election ends, results can be tallied automatically.

### Voting:
Votes are cast by registered voters during the election period, and results are tallied once the election is over. Every vote cast is linked to a specific voter address and candidate, ensuring transparency.

---

## Platform Components

### Errors
The system defines various error codes for handling error scenarios:
- **ENotAdmin (1)**: Action can only be performed by the admin.
- **EVoterAlreadyRegistered (2)**: Voter has already registered.
- **ENotAuthorized (3)**: Unauthorized actions by non-admins.
- **ECandidateNotExists (4)**: Invalid candidate ID.
- **EVoteAlreadyCasted (5)**: Vote has already been cast by the voter.
- **ENoVotesToRevoke (6)**: Attempt to revoke votes when no votes exist.
- **EInvalidElectionState (7)**: Election is not in the correct state for the action.

### Structs

- **VotingSystem**:
  - Manages voters, elections, and admin controls.
  - Tracks elections and voter registration.
  
- **Voter**:
  - Represents an individual voter, including their address, vote history, and whether they’ve voted in a specific election.

- **Election**:
  - Holds details about the election (e.g., election ID, state, candidates, start/end times).

- **Candidate**:
  - Stores information about each candidate in an election.

- **VoteCount**:
  - Tracks the number of votes received by a candidate.

- **CandidateDetails**:
  - Basic candidate details such as candidate ID and name for reference.

- **VoteCastedEvent**:
  - Event emitted whenever a vote is cast to ensure traceability.

### Functions

- **init_voting_system**: Initializes a new `VotingSystem` with admin control.
- **register_voter**: Registers a new voter to the system.
- **create_election**: Admin function to create a new election.
- **add_candidate**: Admin function to add a candidate to an election.
- **vote**: Function for a voter to cast their vote.
- **tally_votes**: Ends the election and tallies all votes for the candidates.
- **verify_voter**: Verifies if a specific address is registered as a voter.
- **end_election**: Admin function to close the election.
- **revoke_vote**: Allows a voter to revoke their vote if required before the election ends.
- **get_election_results**: Retrieves the final tally for an election.
- **get_voter_details**: Retrieves information about a voter’s details.
- **get_candidates**: Retrieves a list of candidates for an election.

---

## How it Benefits the Sui Community

This decentralized voting system will greatly benefit the **Sui community** by providing:
- **Trustless Elections**: Since the voting process is entirely on-chain, voters do not need to rely on any central authority.
- **Security**: Votes cannot be tampered with or changed after being cast. Only the election admin can end the election, and only the voters can cast votes.
- **Transparency**: All voting data is stored on-chain, making it auditable by the public. Results are available for all to see without the need for intermediaries.
- **Efficiency**: The use of the Sui blockchain ensures fast transaction speeds and low fees, making the system scalable for various communities.
- **Governance**: Decentralized autonomous organizations (DAOs) or communities can leverage this platform for decision-making and governance processes.

---

## Deployment Instructions

### Prerequisites
- You must have the **Sui development environment** set up. You can follow the [Move Intro Course](https://suifoundation.org/) for instructions on setting up your environment and installing dependencies.

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/DanielKamau37/Decentralized-Voting-System
   cd Decentralized-Voting-System
   ```

2. **Build the Modules**:
   ```bash
   sui move build
   ```

3. **Deploy the Contract**:
   Use the `sui move publish` command to deploy the voting system to the Sui network:
   ```bash
   sui move publish --gas-budget <amount>
   ```

   - Replace `<amount>` with a sufficient amount of gas.
   - Make sure to have the necessary funds in your Sui wallet.

4. **Configure Admin**:
   Once deployed, the deployer (sender) will automatically become the admin for managing elections.

---

## Testing Instructions

### Unit Testing with Sui Move

1. **Write Unit Tests**:
   Unit tests can be added to the `tests/` directory. Here, you can write test cases for voter registration, election creation, voting, and result tallying.

2. **Run Tests**:
   Run your tests using the following command:
   ```bash
   sui move test
   ```

   Ensure that all functions, including the edge cases (e.g., vote revocation, duplicate voter registration), are well-tested.

### Manual Testing on Devnet

1. **Register Voters**:
   Use the deployed contract functions to register new voters by calling the `register_voter` function. Ensure that each voter’s details are captured correctly.
   
2. **Create an Election**:
   After registration, the admin should create an election using `create_election`. Set the appropriate start and end times to simulate real election periods.

3. **Add Candidates**:
   Admins can then add candidates to the election using `add_candidate`. Each candidate should have a unique name.

4. **Cast Votes**:
   Voters should cast their votes using the `vote` function within the election period.

5. **End Election**:
   Once the election ends, the admin can close the election using `end_election`.

6. **Tally Votes**:
   Tally the votes using `tally_votes` and check that the results reflect the votes cast.

---


## Use Cases for the Sui Community

- **On-chain Voting Systems:** This module can be used by decentralized organizations (DAOs), token-based voting platforms, or any collective decision-making processes within the Sui ecosystem.
- **Governance and Decision Making:** DAOs running on Sui can use this voting system to implement transparent governance mechanisms where token holders or community members can vote on proposals.
- **Auditable and Transparent Elections:** Sui's blockchain guarantees the immutability of vote data, ensuring that any election conducted with this module is secure and auditable.


## Conclusion

The Decentralized Voting System is a highly secure and scalable on-chain solution for elections and polling. Built on the Sui blockchain, it leverages the speed, security, and transparency of decentralized systems, making it a valuable tool for communities and organizations looking for trustworthy governance solutions.
