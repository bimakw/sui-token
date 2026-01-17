# Sui Token

Custom fungible token implementations on Sui blockchain using the Coin standard.

## Tech Stack

- **Language**: Move
- **Blockchain**: Sui Network
- **Standard**: Sui Coin Framework

## Modules

| Module | Description | Features |
|--------|-------------|----------|
| `bima_coin` | Simple fungible token | Mint, burn, transfer |
| `regulated_coin` | Compliance-ready token | Pause, blacklist, admin controls |
| `faucet` | Token dispenser | Rate limiting, cooldown |

## Prerequisites

```bash
# Install Sui CLI
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui

# Setup wallet
sui client new-address ed25519
sui client faucet
```

## Quick Start

```bash
# Clone repository
git clone https://github.com/bimakw/sui-token.git
cd sui-token

# Build
sui move build

# Test
sui move test

# Deploy
sui client publish --gas-budget 100000000
```

## Usage

### BIMA Token

```bash
# Mint 1000 tokens (requires treasury cap)
sui client call --package $PACKAGE --module bima_coin --function mint \
  --args $TREASURY_CAP 1000000000000 $RECIPIENT \
  --gas-budget 10000000

# Transfer tokens
sui client call --package $PACKAGE --module bima_coin --function transfer_coin \
  --args $COIN_ID $RECIPIENT \
  --gas-budget 10000000

# Burn tokens
sui client call --package $PACKAGE --module bima_coin --function burn \
  --args $TREASURY_CAP $COIN_ID \
  --gas-budget 10000000
```

### Regulated Token

```bash
# Pause all transfers (admin only)
sui client call --package $PACKAGE --module regulated_coin --function pause \
  --args $ADMIN_CAP $REG_STATE \
  --gas-budget 10000000

# Add address to blacklist
sui client call --package $PACKAGE --module regulated_coin --function add_to_blacklist \
  --args $ADMIN_CAP $REG_STATE $ADDRESS_TO_BLACKLIST \
  --gas-budget 10000000

# Transfer with compliance check
sui client call --package $PACKAGE --module regulated_coin --function regulated_transfer \
  --args $REG_STATE $COIN_ID $RECIPIENT \
  --gas-budget 10000000
```

### Faucet

```bash
# Fund faucet (treasury cap holder)
sui client call --package $PACKAGE --module faucet --function fund_faucet \
  --args $FAUCET $COIN_ID \
  --gas-budget 10000000

# Claim tokens (once per hour)
sui client call --package $PACKAGE --module faucet --function claim \
  --args $FAUCET 0x6 \
  --gas-budget 10000000
```

## Token Economics

### BIMA Token
- **Symbol**: BIMA
- **Decimals**: 9 (1 BIMA = 1,000,000,000 units)
- **Supply**: Unlimited (controlled by treasury cap)

### Regulated Token
- **Symbol**: RGLD
- **Decimals**: 6
- **Features**: Pausable, blacklist support

### Faucet Token
- **Symbol**: FAUCET
- **Drip Amount**: 1 token per claim
- **Cooldown**: 1 hour

## Architecture

```
sui-token/
├── sources/
│   ├── bima_coin.move      # Basic fungible token
│   ├── regulated_coin.move # Compliance token
│   └── faucet.move         # Token faucet
├── tests/
├── Move.toml
└── README.md
```

## Key Concepts

### Treasury Cap Pattern
- Only treasury cap holder can mint
- Burning decreases total supply
- Can be transferred to new admin

### Regulated Token Pattern
- Pause: Stop all transfers globally
- Blacklist: Block specific addresses
- Admin Cap: Separate from treasury cap

### Faucet Pattern
- Rate limiting with cooldown
- Clock-based time tracking
- Self-service token distribution

## Testing

```bash
# Run all tests
sui move test

# Run with coverage
sui move test --coverage
```

## License

MIT License with Attribution - See [LICENSE](LICENSE)

Copyright (c) 2024 Bima Kharisma Wicaksana
