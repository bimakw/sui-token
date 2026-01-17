/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Licensed under MIT License with Attribution Requirement.
 * See LICENSE file for details.
 */

/// Regulated Coin - A token with additional controls like pause and blacklist.
/// Demonstrates advanced token patterns for compliance use cases.
module sui_token::regulated_coin {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::event;

    /// One-Time-Witness
    public struct REGULATED_COIN has drop {}

    /// Error codes
    const EPaused: u64 = 0;
    const EBlacklisted: u64 = 1;
    const ENotAdmin: u64 = 2;

    /// Admin capability for regulatory controls
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Regulatory state
    public struct RegState has key {
        id: UID,
        paused: bool,
        blacklist: Table<address, bool>,
    }

    /// Events
    public struct Paused has copy, drop { by: address }
    public struct Unpaused has copy, drop { by: address }
    public struct Blacklisted has copy, drop { address: address, by: address }
    public struct Unblacklisted has copy, drop { address: address, by: address }

    /// Initialize the regulated coin
    fun init(witness: REGULATED_COIN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            6,
            b"RGLD",
            b"Regulated Token",
            b"A regulated token with pause and blacklist functionality",
            option::none(),
            ctx
        );

        let admin_cap = AdminCap {
            id: object::new(ctx),
        };

        let reg_state = RegState {
            id: object::new(ctx),
            paused: false,
            blacklist: table::new(ctx),
        };

        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::transfer(admin_cap, tx_context::sender(ctx));
        transfer::share_object(reg_state);
    }

    /// Check if transfer is allowed
    fun assert_can_transfer(state: &RegState, from: address, to: address) {
        assert!(!state.paused, EPaused);
        assert!(!table::contains(&state.blacklist, from), EBlacklisted);
        assert!(!table::contains(&state.blacklist, to), EBlacklisted);
    }

    /// Pause all transfers (admin only)
    public entry fun pause(_: &AdminCap, state: &mut RegState, ctx: &TxContext) {
        state.paused = true;
        event::emit(Paused { by: tx_context::sender(ctx) });
    }

    /// Unpause transfers (admin only)
    public entry fun unpause(_: &AdminCap, state: &mut RegState, ctx: &TxContext) {
        state.paused = false;
        event::emit(Unpaused { by: tx_context::sender(ctx) });
    }

    /// Add address to blacklist (admin only)
    public entry fun add_to_blacklist(
        _: &AdminCap,
        state: &mut RegState,
        addr: address,
        ctx: &TxContext
    ) {
        if (!table::contains(&state.blacklist, addr)) {
            table::add(&mut state.blacklist, addr, true);
        };
        event::emit(Blacklisted { address: addr, by: tx_context::sender(ctx) });
    }

    /// Remove address from blacklist (admin only)
    public entry fun remove_from_blacklist(
        _: &AdminCap,
        state: &mut RegState,
        addr: address,
        ctx: &TxContext
    ) {
        if (table::contains(&state.blacklist, addr)) {
            table::remove(&mut state.blacklist, addr);
        };
        event::emit(Unblacklisted { address: addr, by: tx_context::sender(ctx) });
    }

    /// Mint tokens (treasury cap holder)
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<REGULATED_COIN>,
        state: &RegState,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(!state.paused, EPaused);
        assert!(!table::contains(&state.blacklist, recipient), EBlacklisted);

        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Transfer with regulatory checks
    public entry fun regulated_transfer(
        state: &RegState,
        coin: Coin<REGULATED_COIN>,
        recipient: address,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert_can_transfer(state, sender, recipient);
        transfer::public_transfer(coin, recipient);
    }

    /// Burn tokens
    public entry fun burn(
        treasury_cap: &mut TreasuryCap<REGULATED_COIN>,
        coin: Coin<REGULATED_COIN>
    ) {
        coin::burn(treasury_cap, coin);
    }

    /// View functions
    public fun is_paused(state: &RegState): bool { state.paused }
    public fun is_blacklisted(state: &RegState, addr: address): bool {
        table::contains(&state.blacklist, addr)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(REGULATED_COIN {}, ctx);
    }
}
