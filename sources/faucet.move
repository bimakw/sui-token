/*
 * Copyright (c) 2025 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Licensed under MIT License with Attribution Requirement.
 * See LICENSE file for details.
 */

/// Token Faucet - A controlled token dispenser with rate limiting.
/// Useful for testnet token distribution.
module sui_token::faucet {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};
    use sui::event;

    /// One-Time-Witness for faucet token
    public struct FAUCET has drop {}

    /// Error codes
    const ECooldownNotPassed: u64 = 0;
    const EFaucetEmpty: u64 = 1;
    const EAmountExceedsMax: u64 = 2;

    /// Faucet configuration and state
    public struct Faucet has key {
        id: UID,
        balance: Balance<FAUCET>,
        drip_amount: u64,        // Amount per claim
        cooldown_ms: u64,        // Cooldown in milliseconds
        last_claim: Table<address, u64>,
    }

    /// Events
    public struct TokensClaimed has copy, drop {
        claimer: address,
        amount: u64,
        timestamp: u64,
    }

    public struct FaucetFunded has copy, drop {
        funder: address,
        amount: u64,
    }

    /// Initialize faucet token and faucet
    fun init(witness: FAUCET, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            9,
            b"FAUCET",
            b"Faucet Token",
            b"A testnet token distributed via faucet",
            option::none(),
            ctx
        );

        // Create faucet with default settings
        let faucet = Faucet {
            id: object::new(ctx),
            balance: balance::zero(),
            drip_amount: 1_000_000_000, // 1 token per claim
            cooldown_ms: 3600_000,       // 1 hour cooldown
            last_claim: table::new(ctx),
        };

        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::share_object(faucet);
    }

    /// Fund the faucet with tokens
    public entry fun fund_faucet(
        faucet: &mut Faucet,
        coin: Coin<FAUCET>,
        ctx: &TxContext
    ) {
        let amount = coin::value(&coin);
        balance::join(&mut faucet.balance, coin::into_balance(coin));

        event::emit(FaucetFunded {
            funder: tx_context::sender(ctx),
            amount,
        });
    }

    /// Claim tokens from faucet
    public entry fun claim(
        faucet: &mut Faucet,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);

        // Check cooldown
        if (table::contains(&faucet.last_claim, sender)) {
            let last = *table::borrow(&faucet.last_claim, sender);
            assert!(current_time >= last + faucet.cooldown_ms, ECooldownNotPassed);
        };

        // Check balance
        let available = balance::value(&faucet.balance);
        assert!(available >= faucet.drip_amount, EFaucetEmpty);

        // Update last claim time
        if (table::contains(&faucet.last_claim, sender)) {
            *table::borrow_mut(&mut faucet.last_claim, sender) = current_time;
        } else {
            table::add(&mut faucet.last_claim, sender, current_time);
        };

        // Dispense tokens
        let coin = coin::from_balance(
            balance::split(&mut faucet.balance, faucet.drip_amount),
            ctx
        );

        event::emit(TokensClaimed {
            claimer: sender,
            amount: faucet.drip_amount,
            timestamp: current_time,
        });

        transfer::public_transfer(coin, sender);
    }

    /// Check if address can claim (cooldown passed)
    public fun can_claim(faucet: &Faucet, addr: address, clock: &Clock): bool {
        if (!table::contains(&faucet.last_claim, addr)) {
            return true
        };

        let last = *table::borrow(&faucet.last_claim, addr);
        let current = clock::timestamp_ms(clock);
        current >= last + faucet.cooldown_ms
    }

    /// Get time until next claim (in milliseconds)
    public fun time_until_claim(faucet: &Faucet, addr: address, clock: &Clock): u64 {
        if (!table::contains(&faucet.last_claim, addr)) {
            return 0
        };

        let last = *table::borrow(&faucet.last_claim, addr);
        let current = clock::timestamp_ms(clock);
        let next_claim = last + faucet.cooldown_ms;

        if (current >= next_claim) {
            0
        } else {
            next_claim - current
        }
    }

    /// View functions
    public fun drip_amount(faucet: &Faucet): u64 { faucet.drip_amount }
    public fun cooldown_ms(faucet: &Faucet): u64 { faucet.cooldown_ms }
    public fun faucet_balance(faucet: &Faucet): u64 { balance::value(&faucet.balance) }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(FAUCET {}, ctx);
    }
}
