---
tags: [project, pricing, atomic-swaps, monero, bitcoin, asb, maker]
subject: eigenwallet ASB maker pricing configuration
github: https://github.com/eigenwallet/core
accessed: 2026-07-03
---

# eigenwallet — ASB Maker Pricing Configuration

**eigenwallet** (formerly UnstoppableSwap / comit-network/xmr-btc-swap) is the only live BTC↔XMR adaptor-signature atomic-swap implementation in active maintenance as of 2026. The maker side is the **ASB** (Automated Swap Backend), a daemon that runs continuously, quotes prices to takers via libp2p, and executes swaps atomically.

This note documents every pricing knob available to an ASB operator, how rate derivation works, the daemon architecture, and the protocol-level quote mechanism. All code references are to the `master` branch of [github.com/eigenwallet/core](https://github.com/eigenwallet/core) as accessed 2026-07-03.

---

## 1. Pricing Architecture Overview

The ASB's pricing stack has three layers:

1. **Exchange feeds** (`swap-feed` crate) — WebSocket or REST connections to centralised exchanges that stream live BTC/XMR ask prices.
2. **Rate aggregator** (`swap_feed::ExchangeRate`) — Computes a time-windowed average of live feed prices and applies the maker-configured `ask_spread` on top.
3. **Quote generator** (`swap/src/asb/event_loop.rs`, `mod quote`) — Calls `latest_rate()`, computes the current ask price, checks the maker's unlocked XMR balance, and returns a `BidQuote` struct that takers receive via libp2p.

All maker-configurable parameters live in a **TOML config file** (typically `~/.config/asb/mainnet/config.toml`). There are **no pricing CLI flags**; the ASB `start` subcommand accepts only `--config <path>`, `--testnet`, `--json`, `--trace`, and `--rpc-bind-*` flags. The config file is the sole source of truth.

Source: `swap-asb/src/command.rs` :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-asb-command.rs)

---

## 2. All Maker-Configurable Pricing Parameters

All parameters below live in the `[maker]` section of `config.toml`. They map to the `Maker` struct in `swap-env/src/config.rs` :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-env-config.rs).

### 2.1 `ask_spread` — the only spread parameter

```toml
[maker]
ask_spread = 0.02   # 2% markup over the oracle average
```

- **Type:** `Decimal` (arbitrary-precision floating-point, via the `rust_decimal` crate)
- **Allowed range:** `[0.0, 1.0]` (enforced by the interactive setup wizard; not validated at load time)
- **Default (wizard):** `0.02` (2%)
- **What it does:** A multiplicative markup applied to the arithmetic mean of enabled exchange feeds. If the average of Kraken + Bitfinex + KuCoin is `0.004 BTC/XMR`, an `ask_spread` of `0.02` makes the ASB quote `0.00408 BTC/XMR`. This is the *only spread* — there is no separate `bid_spread`, no asymmetric spread, and no mode for a fixed price (except via the `FixedRate` struct used in tests/integration, which is not exposed in the config).

**Code path:**

```rust
// swap-feed/src/rate.rs
pub fn ask(&self) -> Result<bitcoin::Amount> {
    let sats = Decimal::from(self.ask.to_sat());
    let additional_sats = sats * self.ask_spread;
    Ok(self.ask + bitcoin::Amount::from_sat(additional_sats.to_u64()?))
}
```

The spread is applied as: `final_price = oracle_average * (1 + ask_spread)`.

Source: `swap-feed/src/rate.rs` :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-feed-rate.rs)

### 2.2 `min_buy_btc` / `max_buy_btc` — size constraints

```toml
[maker]
min_buy_btc = 0.001   # minimum BTC the taker must send
max_buy_btc = 0.1     # maximum BTC the taker can send
```

- **Type:** `bitcoin::Amount`, serialised as BTC float (e.g. `0.002`)
- **Default (wizard):** `min = 0.002 BTC`, `max = 0.02 BTC` (from `swap-env/src/defaults.rs`: `DEFAULT_MIN_BUY_AMOUNT = 0.002`, `DEFAULT_MAX_BUY_AMOUNT = 0.02`)
- **What they do:** These become the `min_quantity` and `max_quantity` fields in the `BidQuote` sent to takers. The ASB also dynamically caps `max_quantity` downward to the maker's available unlocked XMR balance converted at the current ask price. If `available_btc_equivalent < min_buy_btc`, the ASB publishes a zero-quote (`min_quantity = 0, max_quantity = 0`) to signal it cannot take new swaps.

Source: `swap-env/src/config.rs` (struct `Maker`) :: accessed 2026-07-03; `swap/src/asb/event_loop.rs` (mod `quote`, `make_quote` function) :: accessed 2026-07-03

### 2.3 Exchange feed sources — which oracles are used

The ASB supports four exchange feeds. All are configured in `[maker]`:

| Config key | Type | Default | What it connects to |
|---|---|---|---|
| `price_ticker_source_kraken_enabled` | `bool` | `true` | Kraken WebSocket `wss://ws.kraken.com` — XMR/BTC ask stream |
| `price_ticker_source_bitfinex_enabled` | `bool` | `true` | Bitfinex WebSocket `wss://api-pub.bitfinex.com/ws/2` — XMR/BTC ask stream |
| `price_ticker_source_kucoin_enabled` | `bool` | `true` | KuCoin REST `https://api.kucoin.com/api/v1/bullet-public` — polled via WebSocket ticket |
| `price_ticker_source_exolix_api_key` | `Option<String>` | `None` (disabled) | Exolix REST `https://exolix.com/api/v2/rate` — polled on interval; requires API key |

The URL for each feed can be overridden:

```toml
[maker]
price_ticker_ws_url_kraken = "wss://ws.kraken.com"
price_ticker_ws_url_bitfinex = "wss://api-pub.bitfinex.com/ws/2"
price_ticker_rest_url_kucoin = "https://api.kucoin.com/api/v1/bullet-public"
price_ticker_rest_url_exolix = "https://exolix.com/api/v2/rate"
```

This allows running a local price-feed proxy that mimics the exchange API format.

**Rate aggregation logic:**
- The arithmetic mean of all enabled feeds with fresh data is used.
- A feed's data is "fresh" if it arrived within the `price_ticker_validity_duration_secs` window (default: 600 seconds = 10 minutes).
- If feeds disagree by more than 10% (hardcoded `MAX_INTEREXCHANGE_SPREAD`), the `latest_rate()` call returns `Err(Error::SpreadTooWide)` and the ASB refuses to quote.
- If all enabled feeds fail or return stale data, the ASB also refuses to quote (returns error to takers).

Source: `swap-feed/src/rate.rs` :: accessed 2026-07-03

### 2.4 `price_ticker_validity_duration_secs` — stale-data window

```toml
[maker]
price_ticker_validity_duration_secs = 600   # default: 10 minutes
```

- If a feed's last update is older than this, it is excluded from the average.
- If all feeds are stale, the ASB returns `AllStaleData` error and cannot produce quotes.
- There is no configurable "oracle unavailable fallback price" — the ASB simply stops quoting.

### 2.5 `price_ticker_rest_poll_interval_exolix_secs` — Exolix poll interval

```toml
[maker]
price_ticker_rest_poll_interval_exolix_secs = 10   # default: 10 seconds
```

Only relevant if `price_ticker_source_exolix_api_key` is set. Controls how often the Exolix REST endpoint is polled. Kraken and Bitfinex are push-based (WebSocket streams); KuCoin uses a WebSocket connection obtained via a REST ticket. Exolix is REST-only and is the only feed that is polled.

### 2.6 `external_bitcoin_redeem_address`

```toml
[maker]
external_bitcoin_redeem_address = "bc1q..."   # optional
```

Not a pricing parameter per se, but affects maker profitability. If set, BTC from redeemed swaps is swept directly to this address. If unset, the ASB generates a fresh internal address per swap. Can also be updated at runtime via the JSON-RPC method `set_external_bitcoin_redeem_address` without restarting the daemon.

### 2.7 `btc_redeem_fee_multiplier`

```toml
[maker]
btc_redeem_fee_multiplier = 1.0   # default 1.0; range: 0.1–10.0
```

Multiplier applied to the fee-estimator's output for the BTC redeem transaction. A value of `2.0` pays 2x the estimated fee to ensure confirmation during high-mempool periods. This reduces the maker's net BTC received per swap but reduces the risk of stuck redeem transactions. Validated at startup: must be in `[0.1, 10.0]`.

### 2.8 `developer_tip`

```toml
[maker]
developer_tip = 0.0   # default: 0 (disabled)
```

A fraction (0.0–1.0) of each swap's XMR amount that is forwarded to the developers as an additional Monero output in the same lock transaction. This reduces the maker's net XMR per swap. The effective available XMR for quoting is adjusted accordingly in `make_quote` (see `unreserved_monero_balance` function). Defaults to `0.0` (disabled).

### 2.9 `refund_policy.anti_spam_deposit_ratio`

```toml
[maker.refund_policy]
anti_spam_deposit_ratio = 0.0   # default: 0 (full refund on cancel)
```

Introduced in v4.0.0 (2026-03-16). When non-zero (max allowed: 0.2), the maker's refund transaction withholds this fraction of the taker's BTC as an "anti-spam deposit" into a separate amnesty output. The maker can later release it ("grant mercy") or withhold it permanently. A value of `0.1` means the taker gets 90% back on cancel; the remaining 10% sits in the amnesty output.

This is communicated to takers in the `BidQuote` as `refund_policy: RefundPolicyWire::PartialRefund { anti_spam_deposit_ratio }`, so takers see the terms before committing.

Source: `swap-p2p/src/protocols/quote.rs` :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-p2p-quote.rs)

---

## 3. Full `[maker]` TOML Config — Annotated

```toml
[maker]
# --- Size constraints ---
min_buy_btc = 0.001          # Min BTC the taker must send (default wizard: 0.002)
max_buy_btc = 0.1            # Max BTC a taker can send (default wizard: 0.02)

# --- Pricing ---
ask_spread = 0.02            # 2% markup over oracle average (sole spread parameter)
btc_redeem_fee_multiplier = 1.0  # Fee safety margin (range: 0.1–10.0)

# --- Oracle sources (all enabled by default) ---
price_ticker_source_kraken_enabled = true
price_ticker_source_bitfinex_enabled = true
price_ticker_source_kucoin_enabled = true
# price_ticker_source_exolix_api_key = "YOUR_EXOLIX_KEY"  # optional 4th feed

# --- Oracle URLs (override to proxy through your own server) ---
price_ticker_ws_url_kraken = "wss://ws.kraken.com"
price_ticker_ws_url_bitfinex = "wss://api-pub.bitfinex.com/ws/2"
price_ticker_rest_url_kucoin = "https://api.kucoin.com/api/v1/bullet-public"
price_ticker_rest_url_exolix = "https://exolix.com/api/v2/rate"

# --- Feed freshness / polling ---
price_ticker_validity_duration_secs = 600  # discard stale samples after 10 min
price_ticker_rest_poll_interval_exolix_secs = 10  # Exolix poll interval (if enabled)

# --- Optional: sweep BTC to external address ---
# external_bitcoin_redeem_address = "bc1q..."

# --- Developer tip (disabled by default) ---
developer_tip = 0.0          # 0.0 = off; e.g. 0.02 = 2% of XMR goes to devs

# --- Anti-spam deposit (disabled by default) ---
[maker.refund_policy]
anti_spam_deposit_ratio = 0.0  # 0 = full refund; max 0.2 (20%)
```

---

## 4. Quote Caching

Quotes are cached for **120 seconds** (`QUOTE_CACHE_TTL = Duration::from_secs(120)`), keyed on `(min_buy_btc, max_buy_btc)`. Within a 120-second window, multiple takers requesting quotes get the same cached `BidQuote` without re-computing the oracle average or re-fetching the Monero balance. After 120 seconds, the next quote request triggers a fresh computation.

This is a latency optimisation, not an oracle-frequency control. The underlying exchange feeds (Kraken, Bitfinex, KuCoin) are streamed continuously in background tasks and are always current; the cache just avoids redundant balance lookups and arithmetic.

Source: `swap/src/asb/event_loop.rs`, `mod quote`, `QUOTE_CACHE_TTL` :: accessed 2026-07-03

---

## 5. ASB Daemon Architecture

### 5.1 Discovery and networking

The ASB registers itself on **libp2p Rendezvous Points** — community-operated servers that maintain a directory of live makers. A taker (the GUI or CLI) contacts one or more rendezvous points to learn the multiaddresses and peer IDs of available makers, then dials them directly over Tor.

Default rendezvous points hard-coded in the release (`swap-env/src/defaults.rs`):

- `/dns4/discovery.eigenwallet.org/tcp/443/wss/p2p/12D3KooW...`
- `/dns4/rendezvous.atomicworld.fun/tcp/443/wss/p2p/12D3KooW...`
- `/dns4/dht.stealthswap.ninja/tcp/443/wss/p2p/12D3KooW...`
- `/dns4/discovery2.eigenwallet.org/tcp/443/wss/p2p/12D3KooW...`
- (Tor `.onion3` mirrors for each)

A public registry API at `https://api.eigenwallet.org/api/list` aggregates this into a cached list for the GUI.

### 5.2 Quote request / response flow

Protocol: `/comit/xmr/btc/bid-quote/2.0.0` over libp2p request-response.

1. Taker sends an empty `()` request to the maker's peer ID.
2. Maker's `EventLoop` receives it, checks the cache; if stale or absent, calls `make_quote(...)`.
3. `make_quote` calls `latest_rate()` on the `ExchangeRate` aggregator (blocking on oracle data), queries unlocked XMR balance from the Monero wallet, computes `unreserved_xmr_balance` (deducting in-flight swaps and the developer tip fraction), converts to BTC equivalent at the ask price, and clips to `[min_buy_btc, max_buy_btc]`.
4. Returns `BidQuote { price, min_quantity, max_quantity, refund_policy, reserve_proof }`.
5. Taker sees the price and decides whether to proceed. The taker either accepts or rejects — **there is no negotiation round**. The maker's quote is final for the swap that follows.

### 5.3 When the oracle is unavailable

If all enabled exchange feeds return errors or stale data:
- `latest_rate()` returns `Err(AllExchanges { ... })` or `Err(AllStaleData)`.
- The `make_quote` call returns an `Arc<anyhow::Error>`.
- The `EventLoop` holds the pending quote channel and eventually responds with an error (the taker sees a failed quote request).
- The ASB logs a warning and does not crash; it resumes quoting as soon as any feed recovers.

There is no "last known good rate" fallback, no hardcoded floor/ceiling, and no configurable static fallback price. The daemon simply cannot produce quotes when all feeds are down.

### 5.4 Can spreads be updated without restarting?

**No.** `ask_spread`, `min_buy_btc`, `max_buy_btc`, and all feed configuration are read from the TOML config file at startup and held in memory for the lifetime of the process. There is no JSON-RPC method to update these at runtime.

The JSON-RPC API (`swap-controller-api`) exposes:
- `get_current_quote` — read the current cached quote
- `set_external_bitcoin_redeem_address` / `clear_external_bitcoin_redeem_address` / `get_external_bitcoin_redeem_address` — runtime update of the BTC sweep address
- `grant_mercy`, `set_burn_on_refund` — per-swap amnesty controls

To change spread, swap limits, or oracle configuration: edit `config.toml` and restart the ASB container (`docker compose restart asb`).

Source: `swap-controller-api/src/lib.rs` :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-controller-api.rs)

### 5.5 Environment variable overrides

The config system layers `config::Environment::with_prefix("ASB").separator("__")` on top of the TOML file. This means any config key can be overridden via environment variables of the form `ASB__MAKER__ASK_SPREAD=0.03`, `ASB__MAKER__MAX_BUY_BTC=0.5`, etc. This allows Docker/k8s operators to inject pricing overrides without modifying the TOML file, but still requires a restart to take effect.

Source: `swap-env/src/config.rs`, `Config::read` :: accessed 2026-07-03

---

## 6. Protocol-Level Pricing Semantics

### 6.1 Who sets the rate?

The maker sets the rate unilaterally. The taker receives a `BidQuote` containing `price` (BTC per XMR), `min_quantity`, `max_quantity`, and `refund_policy`. If the taker finds the price acceptable, they proceed to initiate a swap at exactly that price. There is no counter-offer, no TWAP, no on-chain price discovery.

### 6.2 Is the quote binding?

The quote is **not binding on the maker** in a strict sense. The maker generates a fresh quote for each new swap attempt using the current oracle price. If the oracle price has moved between when the taker received a quote and when they initiate the swap, the maker will use the newer price for the actual swap. In practice, the 120-second cache means a taker could receive a quote, wait up to 120 seconds, and then get that cached quote for the swap. After cache expiry, the maker recomputes.

**This is the free-option problem in miniature:** a taker can request a quote, observe that the XMR price has moved in their favour, and then quickly initiate the swap at the now-stale price. The window is bounded by the 120-second cache TTL and the taker's execution speed. The `anti_spam_deposit_ratio` (Section 2.9) partially mitigates a different vector (repeated cancellations to grief the maker), but does not close the free-option window on quote staleness.

### 6.3 What prevents takers holding quotes speculatively?

Nothing, beyond the 120-second cache window. The taker receives a quote, can wait, and if the quote is still cached when they initiate the swap, they get that price. After the cache expires, the maker recomputes. This is an inherent property of the pull-based quote model with a short cache window. There is no quote-expiry timestamp communicated to the taker, no fee for requesting a quote, and no bond required until the taker actually locks BTC.

The v4.0.0 `anti_spam_deposit_ratio` addresses *swap cancellations* (where the taker locks BTC and then cancels, forcing the maker to refund XMR and pay fees), not quote-time free options.

---

## 7. Adoption Metrics (as of 2026-07-03)

| Metric | Value | Source |
|---|---|---|
| GitHub stars (eigenwallet/core) | 276 | [api.github.com/repos/eigenwallet/core](https://api.github.com/repos/eigenwallet/core) :: accessed 2026-07-03 |
| GitHub forks | 82 | same |
| Open issues | 153 | same |
| Total releases (eigenwallet/core) | 117+ | same |
| Mainnet makers visible on registry | [NOT FOUND — not checked on 2026-07-03; was 2 on 2026-05-22] | [api.eigenwallet.org/api/list](https://api.eigenwallet.org/api/list) :: last checked 2026-05-22 per cross-chain-dex vault |
| Swaps via GUI in 2023 | "more than 3,000" | [Monero CCS 2024 proposal](https://ccs.getmonero.org/proposals/mature-atomic-swaps-ecosystem.html) :: accessed 2026-05-22 |
| Cumulative binary downloads (core repo) | 55,769 across 114 releases | api.github.com/repos/eigenwallet/core/releases :: accessed 2026-05-22 |
| Active release cadence | 14 releases in 47 days (Apr–May 2026) | same |

Note: The GitHub API returned two sets of star/fork numbers (276/82 and 714/170) for the same query on 2026-07-03. The lower figures (276/82) are from the direct `eigenwallet/core` endpoint; the higher may reflect a redirect or stale cache response. The 276/82 pair is used here as the primary source.

---

## 8. Limitations Relevant to a Developer Building an ASB-Style Daemon

### 8.1 Single spread parameter (no bid/ask asymmetry)

There is one spread (`ask_spread`) applied symmetrically to all taker requests. A maker cannot charge different spreads for small versus large swaps, or maintain a different effective price for different taker populations.

### 8.2 No fixed-price mode

The `FixedRate` struct exists in the codebase (used in integration tests) but is not exposed as a config option. The ASB always uses oracle-backed pricing. A developer wanting fixed-price mode would need to implement a stub exchange feed that returns a constant price.

### 8.3 No runtime spread update

Changing `ask_spread` requires a daemon restart. For a maker who wants to adjust spread dynamically (e.g. during high-volatility periods), this means a brief service interruption.

### 8.4 Single oracle aggregation (no per-feed weight)

All enabled feeds contribute equally (unweighted arithmetic mean). A maker cannot weight Kraken more heavily than Bitfinex, or use a median instead of mean. The 10% inter-exchange spread guard (`SpreadTooWide`) is hardcoded.

### 8.5 Free-option exposure on quote staleness

The 120-second quote cache creates a free-option window: a taker can observe price movement and initiate a swap at a cached price that now favours them. Makers should set `ask_spread` high enough to absorb this slippage risk.

### 8.6 Oracle unavailability = no quoting

If all feeds fail, the ASB cannot produce quotes and effectively goes offline for takers. There is no configurable fallback price or "last known good price with extended TTL" mode.

### 8.7 BTC-first only (structural)

The ASB only receives BTC and sends XMR. No XMR-to-BTC direction is possible with current Monero cryptography. See [[projects/xmr-first-atomic-swaps]] for the technical reasons.

---

## 9. Key Files for a Developer Adopting This Design

| File | What it defines |
|---|---|
| `swap-env/src/config.rs` | Complete `Maker` struct — all configurable fields, types, defaults, validation |
| `swap-feed/src/rate.rs` | `Rate::ask()` — spread application; `ExchangeRate::latest_rate()` — multi-feed average |
| `swap-feed/src/kraken.rs`, `bitfinex.rs`, `kucoin.rs`, `exolix.rs` | Individual feed connectors |
| `swap-env/src/defaults.rs` | Default URLs, `DEFAULT_SPREAD = 0.02`, `DEFAULT_MIN/MAX_BUY_AMOUNT` |
| `swap/src/asb/event_loop.rs` (mod `quote`) | `make_quote()`, `QUOTE_CACHE_TTL`, `unreserved_monero_balance()` |
| `swap-p2p/src/protocols/quote.rs` | `BidQuote` wire format, `RefundPolicyWire` enum, protocol string `/comit/xmr/btc/bid-quote/2.0.0` |
| `swap-controller-api/src/lib.rs` | JSON-RPC API surface — what can be updated at runtime (not spread) |

---

## Sources

- [eigenwallet/core GitHub API](https://api.github.com/repos/eigenwallet/core) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-env-config.rs)
- [swap-env/src/config.rs](https://github.com/eigenwallet/core/blob/master/swap-env/src/config.rs) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-env-config.rs)
- [swap-feed/src/rate.rs](https://github.com/eigenwallet/core/blob/master/swap-feed/src/rate.rs) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-feed-rate.rs)
- [swap-env/src/defaults.rs](https://github.com/eigenwallet/core/blob/master/swap-env/src/defaults.rs) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-env-defaults.rs)
- [docs/content/becoming_a_maker/overview.mdx](https://github.com/eigenwallet/core/blob/master/docs/content/becoming_a_maker/overview.mdx) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-docs-becoming-a-maker-overview.mdx)
- [swap-p2p/src/protocols/quote.rs](https://github.com/eigenwallet/core/blob/master/swap-p2p/src/protocols/quote.rs) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-p2p-quote.rs)
- [swap-asb/src/command.rs](https://github.com/eigenwallet/core/blob/master/swap-asb/src/command.rs) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-asb-command.rs)
- [swap-controller-api/src/lib.rs](https://github.com/eigenwallet/core/blob/master/swap-controller-api/src/lib.rs) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-eigenwallet-core-swap-controller-api.rs)
- [swap/src/asb/event_loop.rs](https://github.com/eigenwallet/core/blob/master/swap/src/asb/event_loop.rs) :: accessed 2026-07-03 (mod quote, lines 1660–1950)
- [[cross-chain-dex vault: projects/eigenwallet.md]](../../../research-cross-chain-dex/projects/eigenwallet.md) — prior research, accessed 2026-05-22
