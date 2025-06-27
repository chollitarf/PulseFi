# PulseFi 🏃‍♂️⛓️

A Blockchain-Based Fitness Challenge & Reward Platform

PulseFi is a Clarity smart contract that enables users to participate in fitness challenges, submit progress, and earn tokenized rewards for meeting their health and activity goals. It gamifies personal fitness through decentralized incentives—where your pulse earns you profit.

## 🚀 Features

* 🏋️‍♀️ Create and host custom fitness challenges
* 👥 Join existing challenges as a participant
* 📈 Submit progress tied to measurable goals (e.g., steps, reps, calories)
* 🎯 Claim rewards upon successful challenge completion
* 🔐 Verifiable, trustless tracking of participation and results

## 🛠️ Contract Components

### Data Variables

* `total-challenges` — Total number of challenges created
* `reward-token` — Token contract from which rewards are distributed
* `reward-amount` — Reward per successful participant (in token units)

### Maps

* `challenges` — Stores challenge data keyed by `challenge-id`
* `user-progress` — Tracks users' submitted progress per challenge

### Error Constants

* `ERR_NOT_STARTED`, `ERR_ENDED`, `ERR_ALREADY_JOINED`, `ERR_NOT_PARTICIPANT`, `ERR_GOAL_NOT_MET` — To handle typical challenge state issues

## 📋 Functions

* `create-challenge(goal, start-time, end-time)`
  Initializes a new challenge with a target goal and timeframe.

* `join-challenge(challenge-id)`
  Lets a user join a challenge if it’s ongoing.

* `submit-progress(challenge-id, progress)`
  Submits user progress toward a specific challenge goal.

* `claim-reward(challenge-id)`
  Checks if the user met the challenge goal and transfers reward tokens.

* `contains?` (private helper)
  Determines whether a user is already participating in a challenge.

## 🧪 Example Use Case

1. Alice deploys PulseFi and sets `reward-token` and `reward-amount`.
2. Bob creates a “10,000 Steps in 7 Days” challenge.
3. Alice and Carol join the challenge.
4. Participants submit their progress daily.
5. At the end of the challenge, those who met the goal claim their rewards.

## 🔐 Security Notes

* Only verified participants can submit progress.
* Rewards are only claimable after the challenge ends and if the goal is met.
* Token transfers require the reward-token contract to be pre-approved or managed via SIP-010 compliant interfaces.

## 📄 License

MIT License © 2025 PulseFi Contributors
