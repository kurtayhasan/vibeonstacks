# Youth Mental Health Crisis Center - Registry (Stacks)

A minimal, secure Clarity registry contract that stores anonymized metadata for a Youth Mental Health Crisis Center dApp. The contract is intentionally minimal and forbids storing PII or chat content on-chain; it provides a trusted configuration and registry layer for off-chain services (anonymous chat, hotlines, counselor availability trackers).

## Features
- Key ownership: each key is owned by its creator; only owner can update/transfer/delete.
- Moderation: admin can appoint moderators who can freeze/unfreeze keys.
- Pause switch: admin can pause new writes in emergencies.
- Events: prints for create/update/delete/transfer/freeze to support off-chain indexing.
- Versioning: per-entry version increments on updates for cache invalidation.

## Project Structure
```
├── contracts/           # Clarity smart contracts
├── tests/              # Contract test files
├── scripts/            # Deployment scripts
├── deployments/        # Deployment configurations
├── docs/              # Documentation
└── settings/          # Environment settings
```

## Prerequisites
- [Node.js](https://nodejs.org/) (v14 or higher)
- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development tool
- [Stacks CLI](https://docs.stacks.co/references/stacks-cli) - For contract deployment

## Installation

1. Clone the repository:
```bash
git clone https://github.com/kurtayhasan/vibeonstacks.git
cd vibeonstacks
```

2. Install dependencies:
```bash
npm install
```

3. Install Clarinet (if not already installed):
```bash
curl -sL https://install.clarinet.sh | sh
```

## Development

### Testing
Run the contract tests:
```bash
clarinet test
```

Check contracts for issues:
```bash
clarinet check
```

### Local Development
Start a local Clarinet console:
```bash
clarinet console
```

## Deployment
See `docs/DEPLOYMENT.md` for detailed deployment instructions.

Quick deployment to testnet:
```bash
npm run deploy:testnet
```

## Documentation
- `docs/CONTRACT_GUIDE.md` - Detailed contract documentation
- `docs/DEPLOYMENT.md` - Deployment guide
- `docs/SECURITY.md` - Security considerations and best practices

## Contributing
Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Security
For security concerns, please email [security contact]. See `docs/SECURITY.md` for our security policy.
