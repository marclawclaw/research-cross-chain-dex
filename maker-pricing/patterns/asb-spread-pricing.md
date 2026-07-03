---
tags: [pattern, pricing, atomic-swaps, maker, spread, oracle]
pattern: ASB spread-over-oracle maker pricing
canonical-implementation: eigenwallet ASB (swap-feed + swap-env crates)
accessed: 2026-07-03
---

# Pattern: Spread-Over-Oracle Maker Pricing (ASB Model)

## What This Pattern Is

A maker daemon quotes prices to takers by:

1. Maintaining live connections to one or more centralised exchange price feeds (oracles).
2. Computing an arithmetic mean of the current ask prices from enabled feeds.
3. Multiplying by `(1 + spread)` to derive the maker's effective ask price.
4. Capping the available swap volume at the maker's current available inventory.

The maker does not run an AMM, does not require a chain, and does not hold taker funds. The price is set entirely by the maker's config and the oracle aggregator.

## When to Use

- P2P swap protocol where makers bear inventory risk (e.g. XMR sellers holding illiquid asset).
- No on-chain price discovery is available or desirable.
- Maker count is small (single-digits); competition sets effective spreads rather than protocol mechanics.
- Maker wants full pricing autonomy with zero protocol governance.

## Implementation Recipe (from eigenwallet/core)

### Step 1: Multi-feed oracle aggregator

Connect to N exchange feeds (WebSocket streams or REST polling). On each tick, compute:

```rust
average_ask = sum(enabled_fresh_asks) / count(enabled_fresh_asks)
```

Guard conditions before using the average:
- **Freshness:** exclude any feed whose last update is older than `validity_duration` (eigenwallet default: 600s).
- **Divergence:** if `(max_ask - min_ask) / average_ask > 10%`, refuse to quote (`SpreadTooWide`).
- **All-failed:** if every feed is in error or stale, refuse to quote (`AllExchanges` / `AllStaleData`).

### Step 2: Apply spread

```
effective_ask = average_ask * (1 + ask_spread)
```

This is the price per 1 XMR in BTC. All precision is preserved in `Decimal` (not `f64`).

### Step 3: Compute available inventory

```
available_xmr = unlocked_balance / (1 + developer_tip)
                - sum(in_flight_reserved_xmr)
max_btc_offerable = available_xmr * effective_ask
```

Clip to `[min_buy_btc, max_buy_btc]`. If `max_btc_offerable < min_buy_btc`, publish a zero-quote.

### Step 4: Publish quote

Respond to taker quote requests with:
```
BidQuote {
  price: effective_ask,        // BTC per 1 XMR
  min_quantity: min_buy_btc,   // min BTC the taker must send
  max_quantity: max_buy_btc,   // max BTC (capped by inventory)
  refund_policy: ...,          // anti-spam deposit terms
  reserve_proof: ...,          // optional Monero reserve proof
}
```

Cache this quote for `cache_ttl` (eigenwallet: 120 seconds) to avoid redundant balance queries.

## Config Surface (eigenwallet model — all TOML, no CLI flags)

```toml
[maker]
# --- Pricing ---
ask_spread = 0.02                  # sole spread parameter; no bid/ask asymmetry

# --- Size ---
min_buy_btc = 0.001
max_buy_btc = 0.1

# --- Oracle: which feeds to enable ---
price_ticker_source_kraken_enabled = true    # WebSocket, push
price_ticker_source_bitfinex_enabled = true  # WebSocket, push
price_ticker_source_kucoin_enabled = true    # REST-ticket WebSocket, push
# price_ticker_source_exolix_api_key = "..."  # REST poll, optional

# --- Oracle: freshness ---
price_ticker_validity_duration_secs = 600    # 10-minute stale window
price_ticker_rest_poll_interval_exolix_secs = 10  # Exolix poll (if enabled)

# --- Fee buffer ---
btc_redeem_fee_multiplier = 1.0   # overpay BTC fees for safety (range 0.1–10.0)

# --- Anti-spam (optional) ---
[maker.refund_policy]
anti_spam_deposit_ratio = 0.0     # fraction of BTC withheld on cancel (max 0.2)
```

## What This Pattern Deliberately Omits

| Feature | Omitted? | Note |
|---|---|---|
| Bid spread (asymmetric) | Yes | Single `ask_spread` applies to all swaps |
| Fixed-price mode | Yes | Always oracle-backed (no CLI/config toggle) |
| Per-size spread tiers | Yes | Flat spread regardless of swap size |
| Runtime spread update | Yes | Requires daemon restart to change spread |
| Oracle weight configuration | Yes | All feeds weighted equally (unweighted mean) |
| Custom aggregation (median, VWAP) | Yes | Arithmetic mean only |
| Quote-expiry timestamp | Yes | Taker not told when cache expires |
| Taker fee | Yes | No protocol-level fee; spread is the only margin |

## Limitations and Attack Surfaces

### Free-option on quote staleness (120-second window)
A taker can request a quote, wait up to 120 seconds while monitoring spot price, and initiate a swap at the cached price if it has moved in their favour. Mitigation: set `ask_spread` wide enough to absorb worst-case 2-minute price movement.

### Oracle dependency
If all three default feeds (Kraken, Bitfinex, KuCoin) are simultaneously unreachable or return divergent prices (>10% spread), the ASB stops quoting. No fallback price, no last-known-good mode. Mitigation: configure Exolix as a fourth feed; or run a local price-feed proxy to de-risk exchange API downtime.

### Single spread for all takers
A maker cannot charge more from large takers or offer discounts for repeat users. The spread is a flat multiplier. This is a design simplicity trade-off, not an oversight.

### Restart required for spread changes
Dynamic spread adjustment (e.g. widening during high-volatility periods) requires a daemon restart. The eigenwallet JSON-RPC API exposes no spread-update method. A developer building on this pattern who wants runtime spread changes must implement an RPC endpoint for it (e.g. `set_ask_spread`).

## Adoption Evidence

- eigenwallet ASB is the canonical live deployment: 3,000+ mainnet swaps via the GUI in 2023 (developer-reported in a funded Monero CCS proposal), ~89,400 cumulative binary downloads across two repos through May 2026.
- Observed spread range in the wild: 1.5%–20% over market (third-party review at [kycnot.me/service/eigenwallet](https://kycnot.me/service/eigenwallet) :: accessed 2026-05-22). Default in config/wizard: 2%.
- Two public mainnet makers on the registry as of 2026-05-22 (small but active network).

## Related Patterns

- [[patterns/atomic-swaps-vs-middle-chain]] — contrast with AMM/pool pricing in middle-chain DEXes (Thorchain, Serai)
- [[projects/eigenwallet]] — full project note

## Sources

- `swap-env/src/config.rs` (struct `Maker`) :: [github.com/eigenwallet/core](https://github.com/eigenwallet/core/blob/master/swap-env/src/config.rs) :: accessed 2026-07-03
- `swap-feed/src/rate.rs` :: [github.com/eigenwallet/core](https://github.com/eigenwallet/core/blob/master/swap-feed/src/rate.rs) :: accessed 2026-07-03
- `swap/src/asb/event_loop.rs` (mod quote) :: [github.com/eigenwallet/core](https://github.com/eigenwallet/core/blob/master/swap/src/asb/event_loop.rs) :: accessed 2026-07-03
- eigenwallet docs (maker overview) :: [docs.eigenwallet.org](https://docs.eigenwallet.org/becoming_a_maker/overview) :: accessed 2026-07-03 (via [github.com/eigenwallet/core/blob/master/docs/content/becoming_a_maker/overview.mdx](https://github.com/eigenwallet/core/blob/master/docs/content/becoming_a_maker/overview.mdx))
