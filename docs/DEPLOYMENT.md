# Deployment Guide - Simple Registry

This guide describes how to deploy the `main-contract` and `helper-contract` using Clarinet and the included scripts.

Prerequisites:
- Node.js and npm
- Clarinet installed (https://github.com/hirosystems/clarinet)
- A funded testnet wallet for mainnet deployment

1) Build and test locally
- Run `clarinet check` to compile contracts
- Run `clarinet test` to run tests

2) Deploy to testnet (example)
- Update Clarinet config for testnet: create `clarinet-testnet-config.toml` with network endpoints and keys.
- Run `node scripts/deploy-testnet.ts` (or directly `clarinet deploy --config clarinet-testnet-config.toml`)

3) Initialize contracts
- Use `node scripts/initialize-contracts.ts` to call `initialize` if needed.

4) Deploy to mainnet
- Create `clarinet-mainnet-config.toml` with mainnet endpoints and keys.
- Run `node scripts/deploy-mainnet.ts`.

Notes:
- The scripts provided are thin wrappers around clarinet CLI. They can be replaced with direct clarinet commands or extended using the Stacks.js library for programmatic deployments.
