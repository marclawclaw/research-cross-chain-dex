---
tags: [tool, defi, atomic-swap, market-maker, p2p-dex]
category: multi-chain atomic swap DEX framework
website: https://komodoplatform.com/en/docs/komodo-defi-framework/
docs: https://komodoplatform.com/en/docs/komodo-defi-framework/api/
github: https://github.com/GLEECBTC/komodo-defi-framework
launched: 2017
language: Rust
---

# Komodo DeFi Framework (formerly AtomicDEX)

Komodo DeFi Framework (KDF, binary: `kdf`) is an open-source, production-grade atomic-swap framework written in Rust. It enables peer-to-peer, custodian-free trading of almost any blockchain asset via Hash Time Lock Contracts (HTLCs) and libp2p for orderbook propagation. A key feature is the `start_simple_market_maker_bot` API, which allows a node to act as an automated market-maker by periodically refreshing orders against external price oracles.

The framework was originally called AtomicDEX and renamed to Komodo DeFi Framework as the project matured. The primary consumer-facing application built on top of it is Komodo Wallet (formerly Komodo Desktop Wallet).

## Adoption / usage metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| GitHub stars (komodo-defi-framework) | 125 | 2026-07-03 | [GitHub API](https://api.github.com/repos/KomodoPlatform/komodo-defi-framework) — [archived](../sources/2026-07-03-api-prices-gleec-tickers.json) |
| GitHub forks (komodo-defi-framework) | 118 | 2026-07-03 | [GitHub API](https://api.github.com/repos/KomodoPlatform/komodo-defi-framework) |
| Open issues | 414 | 2026-07-03 | [GitHub API](https://api.github.com/repos/KomodoPlatform/komodo-defi-framework) |
| Latest release | v3.0.0-beta (2026-04-01) | 2026-07-03 | [GitHub releases](https://github.com/KomodoPlatform/komodo-defi-framework/releases) |
| Supported coins/assets | 782 | 2026-07-03 | [KomodoPlatform/coins](https://raw.githubusercontent.com/KomodoPlatform/coins/master/coins) — [archived](../sources/2026-07-03-api-prices-gleec-tickers.json) |
| Komodo Wallet repo stars | 286 | 2026-07-03 | [GitHub API](https://api.github.com/repos/KomodoPlatform/komodo-wallet) |
| Komodo Wallet repo forks | 252 | 2026-07-03 | [GitHub API](https://api.github.com/repos/KomodoPlatform/komodo-wallet) |
| Latest release Linux downloads (v3.0.0-beta) | 806 | 2026-07-03 | [GitHub releases API](https://api.github.com/repos/KomodoPlatform/komodo-defi-framework/releases) |
| Latest release Linux downloads (v2.6.0-beta) | 1,084 | 2026-07-03 | [GitHub releases API](https://api.github.com/repos/KomodoPlatform/komodo-defi-framework/releases) |
| Price oracle tickers served | 293 | 2026-07-03 | [prices.gleec.com/api/v2/tickers](https://prices.gleec.com/api/v2/tickers) — [archived](../sources/2026-07-03-api-prices-gleec-tickers.json) |
| DEX trade volume (on-chain) | [NOT FOUND] | — | No third-party source found (DeFiLlama does not index KDF) |
| Active open orders (live) | [NOT FOUND] | — | No public orderbook aggregator found |
| Monthly active users | [NOT FOUND] | — | Not published by Komodo Platform |

## How it works

### User perspective

1. Run the `kdf` binary; it serves a local JSON-RPC API on port 7783 (password-protected).
2. Activate coins via `electrum` or `enable` RPC calls — no local node needed for UTXO coins.
3. To act as a maker: either place a single fixed-price order with `setprice`, or start the automated bot with `start_simple_market_maker_bot` (providing price oracle URLs, spread, and volume constraints per pair).
4. The bot loop runs every `bot_refresh_rate` seconds (default 30 s), fetches prices from the oracle list, computes `price = oracle_rate × spread`, and updates or creates maker orders.
5. Takers browse the peer-to-peer orderbook and initiate swaps using `buy` or `sell`.
6. An HTLC atomic swap executes: maker and taker lock funds on their respective chains; each party redeems with the revealed secret or reclaims after timeout.

### System perspective

- **P2P network:** libp2p propagates orderbook entries and swap negotiation messages across the `netid` (default 8762). Seed nodes bootstrap discovery.
- **Order matching:** `lp_ordermatch` module matches orders locally and relays matches via P2P. Orders are stored in the local SQLite database.
- **Price oracle:** `coins::lp_price::fetch_price_tickers` iterates through the configured `price_urls` list, returning the first successful response. The `TickerInfosRegistry` maps ticker symbols to USD prices. Cross-rates are computed as `base_price_usd / rel_price_usd` (implicit triangulation via USD).
- **Bot loop:** `lp_bot_loop` in `simple_market_maker.rs` sleeps for `bot_refresh_rate` seconds, then calls `process_bot_logic`. Existing maker orders are updated; pairs with no open order get a new order created.
- **HTLC swap:** Standard HTLC-based atomic swap; no intermediary; funds never leave maker/taker custody.

## Key behaviours

- [[patterns/market-maker-bot]] — periodic repricing loop with configurable spread and oracle fallback chain
- [[patterns/vwap-floor-guard]] — VWAP-based price floor: if `check_last_bidirectional_trade_thresh_hold = true`, the bot will never post a price below the volume-weighted average of recent completed swaps for that pair
- [[patterns/confirmation-risk-controls]] — per-pair `base_confs`/`rel_confs` and `base_nota`/`rel_nota` to control counterparty confirmation requirements

## Maker pricing API reference

### `start_simple_market_maker_bot` (v2.0 API)

Starts the automated market-maker bot. Only one bot instance can run at a time.

**Top-level parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `price_urls` | list of strings | `PRICE_ENDPOINTS` constant | Ordered list of oracle URLs; first working URL is used each refresh cycle |
| `price_url` | string | — | Legacy singular form (deprecated; use `price_urls`) |
| `bot_refresh_rate` | float (seconds) | 30.0 | Bot loop interval; minimum enforced at 30 s even if lower value supplied |
| `cfg` | object | — | Map of `"BASE/REL"` string keys to per-pair config objects |

**Per-pair config (`cfg.name`) parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `base` | string | yes | Ticker of the coin to sell |
| `rel` | string | yes | Ticker of the coin to receive |
| `spread` | string (numeric) | yes | Multiplier applied to oracle price. `1.05` = 5 % above oracle. Must be > 1 to earn margin |
| `max` | boolean | conditional | Trade entire coin balance. At least one of `max`, `max_volume.percentage`, or `max_volume.usd` must be set |
| `max_volume.percentage` | string | conditional | Maximum trade volume as fraction of balance (0–1). Values ≥ 1.0 imply `max = true` |
| `max_volume.usd` | string | conditional | Maximum trade volume in USD. If balance × oracle_price < this value, implies `max = true` |
| `min_volume.percentage` | string | optional | Minimum volume accepted as fraction of balance (or of `max_volume` if set) |
| `min_volume.usd` | float | optional | Minimum volume in USD; if balance × oracle_price < min_volume.usd the order is skipped |
| `min_base_price` | float | optional | Skip order if oracle USD price of base coin is below this value |
| `min_rel_price` | float | optional | Skip order if oracle USD price of rel coin is below this value |
| `min_pair_price` | float | optional | Skip order if computed pair price (base_usd / rel_usd) is below this value |
| `base_confs` | integer | optional | Required confirmations for base coin HTLC transaction; defaults to coin config |
| `base_nota` | boolean | optional | Require dPoW notarisation for base coin; defaults to coin config |
| `rel_confs` | integer | optional | Required confirmations for rel coin HTLC transaction; defaults to coin config |
| `rel_nota` | boolean | optional | Require dPoW notarisation for rel coin; defaults to coin config |
| `enable` | boolean | yes | Set `false` to temporarily disable this pair without removing it from config |
| `price_elapsed_validity` | float (seconds) | 300.0 (5 min) | Cancel orders and skip new creation if oracle data is older than this |
| `check_last_bidirectional_trade_thresh_hold` | boolean | false | Enable VWAP floor guard (see [[patterns/vwap-floor-guard]]) |

**Price computation (source: `simple_market_maker.rs`, line 481):**
```
calculated_price = oracle_rate × spread
```
Where `oracle_rate = base_price_usd / rel_price_usd` from the `TickerInfosRegistry`.

**Fallback when price source unavailable (source: `simple_market_maker.rs`, lines 657–663):**
```rust
match fetch_price_tickers(&mut running_state.price_urls).await {
    Ok(model) => model,
    Err(err) => {
        let nb_orders = cancel_pending_orders(ctx, &cfg).await;
        error!("error fetching price: {err:?} - cancel {nb_orders} orders");
        return;
    },
}
```
All current bot-managed orders are **cancelled** when all oracle URLs fail. The bot loop continues and will recreate orders on the next successful tick.

**Per-pair staleness check (source: `simple_market_maker.rs`, lines 449–458):**
If oracle data for a specific pair is older than `price_elapsed_validity` seconds, that pair's order is cancelled and not recreated this tick.

**Minimum refresh rate enforcement (source: `simple_market_maker.rs`, line 754):**
```rust
if refresh_rate < BOT_DEFAULT_REFRESH_RATE {
    refresh_rate = BOT_DEFAULT_REFRESH_RATE;
}
```
`BOT_DEFAULT_REFRESH_RATE = 30.0`. Even if a caller passes a lower value, the bot enforces 30 s minimum.

---

### `setprice` (legacy API — primary maker order placement)

Places a fixed-price maker order. Always interpreted as a sell of `base` for `rel`.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `base` | string | yes | Coin to sell |
| `rel` | string | yes | Coin to receive |
| `price` | numeric string or rational | yes | Amount of `rel` to receive per 1 unit of `base` |
| `volume` | numeric string or rational | conditional | Max amount of `base` available for sale; ignored if `max = true` |
| `max` | bool | conditional | Use entire coin balance (reserves 0.001 for fees) |
| `min_volume` | numeric string or rational | optional | Minimum `base` amount per matched trade; must be ≤ `volume` |
| `cancel_previous` | bool | default true | Cancel all existing orders for this pair before placing |
| `base_confs` | number | optional | Confirmations required for base coin HTLC; defaults to coin config |
| `base_nota` | bool | optional | Require dPoW notarisation for base |
| `rel_confs` | number | optional | Confirmations required for rel coin HTLC |
| `rel_nota` | bool | optional | Require dPoW notarisation for rel |
| `save_in_history` | boolean | default true | Whether to persist order history to local SQLite |

**Rational number formats:** Price and volume can be expressed as:
- Plain decimal string: `"0.9"`
- `num-rational` crate format: `[[1, [1]], [1, [1]]]`
- Fraction object: `{"numer": "3", "denom": "4"}`

**Note:** `setprice` always cancels existing orders for the pair by default (`cancel_previous = true`). To maintain multiple open orders for the same pair, set `cancel_previous = false`.

---

### `update_maker_order` (legacy API)

Updates an existing maker order in place, without cancelling and recreating. This is what the MM bot uses internally to reprice without disrupting in-progress matches.

| Parameter | Type | Description |
|-----------|------|-------------|
| `uuid` | string | UUID of the order to update |
| `new_price` | numeric string or rational | New price (optional) |
| `volume_delta` | numeric string or rational | Amount to add/subtract from current max volume |
| `max` | bool | Switch to using full balance |
| `min_volume` | numeric string or rational | New minimum volume per match |
| `base_confs`, `base_nota`, `rel_confs`, `rel_nota` | as per `setprice` | Optional; update confirmation requirements |

---

### `sell` (legacy API — taker-first, falls through to maker)

Issues a sell request as a taker. If not matched within 30 seconds, auto-converts to a `GoodTillCancelled` maker order. Use `setprice` to always act as a maker from the start.

**DEX fee:** `max(dust, 0.0001 TAKER_COIN, size / 777)` charged to taker.

**Parameters:** `base`, `rel`, `price`, `volume`, `min_volume` (optional), `match_by` (optional, filter by pubkey/uuid), `order_type` (optional), `base_confs`, `base_nota`, `rel_confs`, `rel_nota`, `save_in_history`.

---

### `buy` (legacy API — taker-first, falls through to maker)

Mirror of `sell` from the buyer's perspective. Same fallback behaviour and DEX fee.

**Parameters:** `base` (coin to receive), `rel` (coin to spend), `price`, `volume`, `min_volume`, `match_by`, `order_type`, `base_confs`, `base_nota`, `rel_confs`, `rel_nota`, `save_in_history`.

---

### `cancel_order`

Cancels a single active order by UUID.

```json
{"method": "cancel_order", "uuid": "<uuid>"}
```

Returns `{"result": "success"}` or an error if the UUID is not found.

---

### `cancel_all_orders`

Cancels orders matching a filter condition. Orders currently in active swap matching are excluded and returned in `currently_matching`.

**Filter types (`cancel_by.type`):**
- `"All"` — cancel every open maker order
- `"Pair"` — cancel orders for a specific base/rel pair (`data.base`, `data.rel`)
- `"Coin"` — cancel all orders involving a specific ticker (`data.ticker`)

---

## Price oracles

### Default oracle list (source: `mm2src/coins/lp_price.rs`, line 14)

```rust
pub const PRICE_ENDPOINTS: [&str; 3] = [
    "https://prices.gleec.com/api/v2/tickers",
    "https://prices.cipig.net:1717/api/v2/tickers",
    "https://defistats.gleec.com/api/v3/prices/tickers_v2",
];
```

These are Komodo Platform-operated price aggregator services. The API response returns 293 tickers (observed 2026-07-03) with each ticker's USD price sourced from aggregated data.

### Oracle data providers (source: `mm2src/coins/lp_price.rs`, lines 81–98)

The ticker endpoint aggregates price data from multiple upstream providers:

| Provider enum variant | `price_provider` field value | Description |
|----------------------|------------------------------|-------------|
| `Provider::Binance` | `"binance"` | Binance CEX spot price |
| `Provider::Coingecko` | `"coingecko"` | CoinGecko market data |
| `Provider::Coinpaprika` | `"coinpaprika"` | CoinPaprika market data |
| `Provider::Forex` | `"forex"` | Forex rates (for fiat pairs) |
| `Provider::LiveCoinWatch` | `"livecoinwatch"` | LiveCoinWatch aggregator |
| `Provider::Unknown` | `"unknown"` | Fallback; triggers `ProviderUnknown` error and skips order |

**KMD example (observed 2026-07-03):** Price provider = `coingecko`, price = 0.00550804 USD, volume 24 h provider = `coingecko`.

### Multi-hop pricing (triangulation via USD)

The framework does **not** use a direct base/rel price. It fetches USD prices independently for both coins, then divides:

```rust
rate_infos.price = base_price_infos.last_price.checked_div(&rel_price_infos.last_price)
```

This means any pair can be priced as long as both coins have a USD price in the oracle. There is no explicit multi-hop path configured; USD acts as the implicit bridge currency.

**Consequence for rare pairs:** If either coin is missing from the oracle response (or has `Provider::Unknown`), the bot skips the pair for that tick and logs `ProviderUnknown` — it does **not** attempt alternative routing.

### Custom oracle support

Makers can supply any URL(s) via `price_urls` in the `start_simple_market_maker_bot` call. The endpoint must return the same JSON schema as the default endpoints: a flat map of `TICKER → {last_price, last_updated_timestamp, price_provider, ...}`. The docs note: *"please ensure it conforms to the same schema as the url in the example."*

The framework also supports a legacy `price_url` (singular string) field, which is marked for deprecation in favour of `price_urls` (list).

### Oracle URL fallback rotation

`fetch_price_tickers` (source: `lp_price.rs`) iterates the URL list in order. On the first success it calls `price_urls.rotate_left(i)` to promote the working URL to the front for the next tick — a simple priority rotation ensuring the working endpoint is tried first next time.

---

## `base_confs` / `rel_confs` and risk implications

`base_confs` and `rel_confs` control how many confirmations each party's HTLC transaction must receive before the swap proceeds to the next step.

- **Higher `base_confs`:** The maker waits longer before releasing the secret, reducing the risk of a double-spend by the taker. Slower swap completion.
- **Higher `rel_confs`:** The taker must wait longer for the maker's HTLC to confirm before redeeming. More protection for the taker, but slower.
- **`base_nota` / `rel_nota`:** When `true`, the Komodo dPoW (Delayed Proof of Work) notarisation must occur in addition to confirmations. Notarisation embeds KMD block hashes into the Bitcoin blockchain, providing additional finality guarantees. This adds latency (notarisation occurs roughly every 10 minutes) but greatly reduces the risk of chain reorganisations invalidating the HTLC.

**Pricing risk:** A maker setting very low `base_confs = 1` on a coin with slow finality (e.g., a coin prone to reorganisations) risks a successful taker double-spend before the HTLC is sufficiently buried. Conversely, very high confirmation counts increase the time the maker's funds are locked, reducing capital efficiency and increasing the window during which price moves against the maker's posted spread.

---

## Architecture decisions

- **Rust + libp2p:** Performance and memory safety for the networking and swap logic. libp2p handles peer discovery and orderbook propagation without a central server.
- **USD-as-bridge for pricing:** Eliminates the need to maintain a cross-rate oracle for every pair. Any coin with a USD price can participate in any pair.
- **HTLC, no proxy tokens:** Funds never leave makers' wallets into a bridge contract; private keys stay local. Trade-off: requires both chains to support HTLC-compatible scripting.
- **Bot cancels on oracle failure:** Rather than using stale prices (which could result in lossy trades if markets moved), the conservative choice is to cancel all orders and wait for oracle recovery.
- **Minimum 30 s refresh rate:** Hard-coded floor prevents accidental DoS of oracle endpoints or network congestion from bot operators.
- **VWAP floor guard (optional):** Draws on up to 1,000 of the most recent completed swaps for the pair (in both directions) to compute a volume-weighted average price. If the current oracle price × spread is below this historical VWAP, the bot uses the VWAP instead. Protects against oracle manipulation or sudden oracle price drops below the maker's average cost basis.
- **`cancel_previous = true` in bot:** Each bot tick that creates a new order for a pair calls `SetPriceReq` with `cancel_previous: true`, ensuring no duplicate orders accumulate.
- **`save_in_history = true` in bot:** Bot-created orders are always persisted in the local SQLite database for audit and VWAP calculation.

## Differentiators

Compared to other P2P maker pricing systems (see [[metrics/maker-pricing-parameters]]):

- **Only protocol with a built-in automated maker bot** in the core daemon — no external tooling required to run continuous market-making.
- **Oracle URL list with fallback rotation** provides resilience without operator intervention.
- **VWAP floor guard** is a unique mechanism for protecting against oracle manipulation and trading below cost basis.
- **Per-pair price staleness window** (`price_elapsed_validity`) lets the maker tune acceptable oracle latency per pair, useful when oracle refresh rates differ across assets.
- **USD-bridge triangulation** supports any pair that has USD pricing, without configuring explicit multi-hop routes.
- **dPoW notarisation flags** (`base_nota`, `rel_nota`) give makers on KMD-ecosystem chains additional settlement finality assurance — a feature unique to Komodo's ecosystem.

## Limitations and criticisms

1. **"Alpha stage software" self-labelling:** The GitHub README carries a `WARNING: Use with test coins only or with assets which value does not exceed an amount you are willing to lose. This is alpha stage software!` notice as of 2026-07-03, despite v3.0.0-beta being released. This is a credibility concern for production deployments.

2. **Conservative oracle failure behaviour (all orders cancelled):** When all price oracle URLs fail, all bot-managed orders are immediately cancelled. This means any network hiccup to the Komodo-operated oracle hosts causes complete liquidity withdrawal. A maker running on an isolated network or with unreliable connectivity will frequently lose all orders. There is no configurable "use last known price for N seconds" option.

3. **No direct pair oracle:** The USD-bridge approach means both coins must be listed on CoinGecko/Binance/etc. Niche coins or new tokens may have `Provider::Unknown` and be silently skipped. There is no mechanism to supply a direct base/rel price without building and hosting a custom oracle.

4. **Minimum 30 s refresh rate:** The hard minimum prevents high-frequency makers from competing on latency. For volatile pairs, a 30 s repricing window can result in stale quotes being matched against rapidly.

5. **Single bot instance per daemon:** Only one `start_simple_market_maker_bot` call can be active at a time. Running multiple independent strategies (e.g., different spreads for different conditions) would require multiple daemon instances.

6. **Taker DEX fee (1/777th rule):** The taker pays `max(dust, 0.0001 TAKER_COIN, size / 777)`. For very small trades this fee is proportionally high, reducing taker demand and indirectly limiting maker fill rates on small-volume pairs.

7. **Low GitHub engagement relative to peers:** 125 stars vs. Bisq (5,114 stars) and Haveno (1,354 stars). Suggests a smaller developer/integrator community, which may affect long-term support and auditability.

8. **No public aggregate trade volume data:** No third-party source (DeFiLlama, on-chain scanner) tracks KDF trade volume. Komodo Platform self-reported metrics only.

9. **Oracle infrastructure dependency:** All three default price endpoints (`prices.gleec.com`, `prices.cipig.net`, `defistats.gleec.com`) are operated by Komodo Platform affiliates. A maker running in production is entirely dependent on these services remaining available and honest. A custom oracle requires significant engineering to match the expected JSON schema.

## Sources

- [Komodo DeFi Framework README](https://github.com/KomodoPlatform/komodo-defi-framework/blob/main/README.md) — accessed 2026-07-03 — [archived](../sources/komodo_readme.md)
- [start_simple_market_maker_bot API docs (v2.0)](https://komodoplatform.com/en/docs/komodo-defi-framework/api/v20/swaps_and_orders/start_simple_market_maker_bot/) — accessed 2026-07-03 — [archived](../sources/2026-07-03-komodo-docs-start_simple_market_maker_bot.html)
- [setprice API docs (legacy)](https://komodoplatform.com/en/docs/komodo-defi-framework/api/legacy/setprice/) — accessed 2026-07-03 — [archived](../sources/2026-07-03-komodo-docs-setprice.html)
- [sell API docs (legacy)](https://komodoplatform.com/en/docs/komodo-defi-framework/api/legacy/sell/) — accessed 2026-07-03 — [archived](../sources/2026-07-03-komodo-docs-sell.html)
- [buy API docs (legacy)](https://komodoplatform.com/en/docs/komodo-defi-framework/api/legacy/buy/) — accessed 2026-07-03 — [archived](../sources/2026-07-03-komodo-docs-buy.html)
- [cancel_order API docs (legacy)](https://komodoplatform.com/en/docs/komodo-defi-framework/api/legacy/cancel_order/) — accessed 2026-07-03 — [archived](../sources/2026-07-03-komodo-docs-cancel_order.html)
- [cancel_all_orders API docs (legacy)](https://komodoplatform.com/en/docs/komodo-defi-framework/api/legacy/cancel_all_orders/) — accessed 2026-07-03 — [archived](../sources/2026-07-03-komodo-docs-cancel_all_orders.html)
- [update_maker_order API docs (legacy)](https://komodoplatform.com/en/docs/komodo-defi-framework/api/legacy/update_maker_order/) — accessed 2026-07-03 — [archived](../sources/2026-07-03-komodo-docs-update_maker_order.html)
- [simple_market_maker.rs source](https://github.com/KomodoPlatform/komodo-defi-framework/blob/main/mm2src/mm2_main/src/lp_ordermatch/simple_market_maker.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-komodo-simple_market_maker.rs)
- [lp_bot.rs source](https://github.com/KomodoPlatform/komodo-defi-framework/blob/main/mm2src/mm2_main/src/lp_ordermatch/lp_bot.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-komodo-lp_bot.rs)
- [lp_price.rs source](https://github.com/KomodoPlatform/komodo-defi-framework/blob/main/mm2src/coins/lp_price.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-komodo-lp_price.rs)
- [Gleec prices oracle API](https://prices.gleec.com/api/v2/tickers) — accessed 2026-07-03 — [archived](../sources/2026-07-03-api-prices-gleec-tickers.json)
- [GitHub repo API](https://api.github.com/repos/KomodoPlatform/komodo-defi-framework) — accessed 2026-07-03
- [GitHub releases API](https://api.github.com/repos/KomodoPlatform/komodo-defi-framework/releases) — accessed 2026-07-03
- [KomodoPlatform/coins repository](https://raw.githubusercontent.com/KomodoPlatform/coins/master/coins) — accessed 2026-07-03 (782 coins counted)
