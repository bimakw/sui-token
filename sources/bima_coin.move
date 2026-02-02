/*
 * Copyright (c) 2025 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Licensed under MIT License with Attribution Requirement.
 * See LICENSE file for details.
 */

/// BIMA Token - A custom fungible token on Sui blockchain.
/// Demonstrates the Coin standard with treasury cap for controlled minting.
module sui_token::bima_coin {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::url;

    /// One-Time-Witness for the BIMA coin
    public struct BIMA_COIN has drop {}

    /// Token decimals (9 = 1 BIMA = 1_000_000_000 smallest units)
    const DECIMALS: u8 = 9;

    /// Initialize the BIMA token
    fun init(witness: BIMA_COIN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            DECIMALS,
            b"BIMA",
            b"Bima Token",
            b"A custom token demonstrating Sui's Coin standard",
            option::some(url::new_unsafe_from_bytes(b"https://example.com/bima-token.png")),
            ctx
        );

        // Freeze metadata so it cannot be changed
        transfer::public_freeze_object(metadata);

        // Transfer treasury cap to deployer
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    /// Mint new tokens (only treasury cap holder can mint)
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<BIMA_COIN>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Mint tokens to self
    public entry fun mint_to_self(
        treasury_cap: &mut TreasuryCap<BIMA_COIN>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        mint(treasury_cap, amount, sender, ctx);
    }

    /// Burn tokens
    public entry fun burn(
        treasury_cap: &mut TreasuryCap<BIMA_COIN>,
        coin: Coin<BIMA_COIN>
    ) {
        coin::burn(treasury_cap, coin);
    }

    /// Transfer tokens
    public entry fun transfer_coin(
        coin: Coin<BIMA_COIN>,
        recipient: address
    ) {
        transfer::public_transfer(coin, recipient);
    }

    /// Split coin and transfer partial amount
    public entry fun split_and_transfer(
        coin: &mut Coin<BIMA_COIN>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let split_coin = coin::split(coin, amount, ctx);
        transfer::public_transfer(split_coin, recipient);
    }

    /// Merge multiple coins into one
    public entry fun merge_coins(
        coin: &mut Coin<BIMA_COIN>,
        to_merge: Coin<BIMA_COIN>
    ) {
        coin::join(coin, to_merge);
    }

    /// Get total supply
    public fun total_supply(treasury_cap: &TreasuryCap<BIMA_COIN>): u64 {
        coin::total_supply(treasury_cap)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(BIMA_COIN {}, ctx);
    }
}
