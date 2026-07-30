# Base Guess Game

A simple, fully on-chain number-guessing game for deployment on [Base](https://base.org).

## How it works
- A player pays an entry fee (`entryFee`) and guesses a number between 1 and `range`.
- The contract generates a random number. If it matches the player's guess, they win `entryFee * payoutMultiplier`.
- Otherwise, the entry fee stays in the contract's prize pool.

## ⚠️ Important security note
Randomness in this version comes from block data (`block.prevrandao`, `timestamp`, ...). This is:
- Fine for a demo, testing, or a low-stakes game.
- **Not sufficient** for a real-money game with meaningful value, since a validator or a watching contract could predict or influence the outcome.
- For production, consider a commit-reveal scheme or an oracle like [Chainlink VRF](https://docs.chain.link/vrf).

## Requirements
- Node.js v18 or later
- A wallet with some ETH on Base or Base Sepolia

## Install
```bash
npm install
cp .env.example .env
# Fill in PRIVATE_KEY and (optionally) BASESCAN_API_KEY in .env
```

## Compile & Test
```bash
npm run compile
npm test
```

## Deploy

On the testnet first (recommended):
```bash
npm run deploy:baseSepolia
```

On Base mainnet:
```bash
npm run deploy:base
```

The deploy script automatically funds the prize pool with 0.01 ETH so the first winners can be paid out.

## Adjustable settings (owner only)
Use `setParams(entryFee, range, payoutMultiplier)` to change the entry fee, guess range, and payout multiplier.

## Networks
| Network | Chain ID | RPC |
|---|---|---|
| Base Mainnet | 8453 | https://mainnet.base.org |
| Base Sepolia (testnet) | 84532 | https://sepolia.base.org |
