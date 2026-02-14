# Sui Token

Fungible token implementations on Sui: basic token (BIMA), regulated token with pause/blacklist (RGLD), and a rate-limited faucet.

## Building & Testing

```bash
sui move build
sui move test
```

Deploy with `sui client publish --gas-budget 100000000`.

## Modules

- **bima_coin** — mint, burn, transfer (treasury cap pattern)
- **regulated_coin** — pausable, blacklistable, admin-controlled
- **faucet** — self-service token dispenser with 1h cooldown

## License

MIT with attribution — see [LICENSE](LICENSE).
