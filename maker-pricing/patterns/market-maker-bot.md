---
tags: [pattern, market-making, pricing, automation]
seen_in: [komodo-defi]
---

# Automated Periodic Repricing Bot

A maker daemon that runs a continuous loop, fetching external price oracle data on each tick, computing an adjusted order price (oracle rate × spread multiplier), and updating or creating maker orders. All order management is handled automatically; the human operator configures parameters once at bot start.

This pattern solves the core problem of running an atomic-swap market maker unattended: prices move continuously, so a static `setprice` order would quickly become stale and either unprofitable or untradeable. The bot keeps quotes current without operator intervention.

## Implementations

### [[projects/komodo-defi]] — `start_simple_market_maker_bot`

**Language:** Rust (source: `mm2src/mm2_main/src/lp_ordermatch/simple_market_maker.rs`)

**Loop mechanics:**
1. Bot starts with a registry of per-pair configs (`SimpleMakerBotRegistry`).
2. Each tick: fetch all oracle prices from the URL list (first working URL wins; rotate on success).
3. For each pair in the config:
   - If an open maker order already exists for the pair: call `update_maker_order` with the new price and volume.
   - If no open order exists: call `setprice` (with `cancel_previous: true`) to create one.
4. If oracle fetch fails entirely: cancel all bot-managed orders and skip the tick.
5. Sleep for `bot_refresh_rate` seconds (minimum 30 s), then repeat.

**Configurable parameters (per-pair):**

| Knob | Type | What it controls |
|------|------|-----------------|
| `spread` | float multiplier | Price markup above oracle rate (e.g., `1.025` = 2.5% spread) |
| `max` | bool | Trade entire balance |
| `max_volume.percentage` | 0–1 | Maximum volume as fraction of balance |
| `max_volume.usd` | USD amount | Maximum volume in USD terms |
| `min_volume.percentage` | 0–1 | Minimum accepted trade size as fraction of balance |
| `min_volume.usd` | USD amount | Minimum accepted trade size in USD terms |
| `min_base_price` | USD | Floor on base coin USD price (skip if oracle below this) |
| `min_rel_price` | USD | Floor on rel coin USD price |
| `min_pair_price` | base/rel units | Floor on computed pair price |
| `price_elapsed_validity` | seconds | Cancel pair's order if oracle data is older than this (default 300 s) |
| `check_last_bidirectional_trade_thresh_hold` | bool | Activate VWAP floor guard |
| `base_confs`, `rel_confs` | integers | HTLC confirmation requirements affecting settlement latency vs. security |
| `base_nota`, `rel_nota` | bool | Require dPoW notarisation (Komodo ecosystem only) |
| `enable` | bool | Hot-disable a pair without removing config |

**Global parameters:**

| Knob | Type | What it controls |
|------|------|-----------------|
| `price_urls` | list of strings | Ordered oracle URL list with automatic fallback |
| `bot_refresh_rate` | float (seconds) | Loop interval; minimum 30 s enforced |

**Price computation:**
```
calculated_price = (base_usd / rel_usd) × spread
```
USD prices are fetched independently per ticker; the pair price is derived by division (implicit USD bridge).

**Order update vs. create distinction:**
The bot distinguishes between updating an existing order (`update_maker_order`) and creating a new one (`setprice`). This matters because `update_maker_order` does not disrupt an order that is currently being matched in an active swap — the bot checks the existing maker orders and only updates those that belong to the configured pairs.

**Oracle failure handling:**
- All URLs fail: all bot-managed orders cancelled; loop continues.
- Single URL fails: next URL in list tried; successful URL promoted to front.
- Per-pair data stale beyond `price_elapsed_validity`: that pair's order cancelled; other pairs unaffected.
- Per-pair coin has `Provider::Unknown`: that pair skipped with `ProviderUnknown` error log.

**VWAP floor guard (`check_last_bidirectional_trade_thresh_hold`):**
Up to 1,000 recent completed swaps for the pair (in both directions) are loaded from local SQLite. The volume-weighted average price (VWAP) is computed across these. If `calculated_price < VWAP`, the bot uses `VWAP` as the submitted price instead, preventing the maker from selling below their historical average. If no swap history exists, the calculated price is used unchanged.

**Stopping:**
`stop_simple_market_maker_bot` transitions the bot to a `Stopping` state. On the next loop tick, the state transitions to `Stopped` and all bot-managed orders are cancelled via `cancel_all_orders` (by pair, for each pair in the config).

**State machine:**
```
Stopped → Running (on start_simple_market_maker_bot)
Running → Stopping (on stop_simple_market_maker_bot)
Stopping → Stopped (on next loop tick)
```
Only one running state at a time. Starting while `Running` returns `AlreadyStarted` error. Starting while `Stopping` returns `CannotStartFromStopping`.

**Telegram alerts:**
The bot publishes swap status change events (via `MakerSwapStatusChanged` event listener) and bot lifecycle events to a configured Telegram room (via `MessageServiceContext`). This gives operators out-of-band notifications without polling the API. Configuration is via the `MM2.json` startup file, not the bot API call itself.

**Adoption:**
Deployed in the [Komodo Wallet](https://github.com/KomodoPlatform/komodo-wallet) (286 GitHub stars, 252 forks as of 2026-07-03) and used by liquidity providers on the Komodo DeFi P2P network. Total binaries downloaded across all platforms: ~10,000+ across v2.5.1 and v2.6.0 releases.

## Design lessons for atomic-swap maker daemons

1. **Fail safe on oracle outage:** Cancel open orders rather than let stale prices be matched. The risk of an unprofitable fill on stale data outweighs the cost of temporarily being out of the market.

2. **Per-pair staleness control:** Different pairs have different liquidity on price oracles. Allow the operator to set per-pair staleness thresholds rather than a single global value.

3. **Oracle URL fallback list:** A single oracle URL is a single point of failure. A list with rotation-on-success is simple to implement and dramatically improves uptime.

4. **Separate update from create:** When repricing an existing order, prefer an in-place update over cancel + recreate to avoid disrupting in-progress match negotiations.

5. **VWAP floor guard:** Purely oracle-driven pricing exposes the maker to oracle manipulation. A VWAP floor computed from the maker's own trade history provides a self-referential sanity check. This is particularly relevant for atomic swaps where the maker cannot quickly hedge.

6. **Minimum refresh enforced in code, not docs:** Operators will accidentally over-configure bot refresh rates. Enforce a minimum in the code (30 s in KDF) to protect both the operator and the oracle infrastructure.

7. **Volume expressed in both native and USD terms:** Providing `percentage`, `usd`, and `max` volume modes lets operators reason about exposure in familiar units regardless of the coin's native denomination.

## Sources

- [simple_market_maker.rs source](https://github.com/KomodoPlatform/komodo-defi-framework/blob/main/mm2src/mm2_main/src/lp_ordermatch/simple_market_maker.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-komodo-simple_market_maker.rs)
- [lp_bot.rs source](https://github.com/KomodoPlatform/komodo-defi-framework/blob/main/mm2src/mm2_main/src/lp_ordermatch/lp_bot.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-komodo-lp_bot.rs)
- [start_simple_market_maker_bot API docs](https://komodoplatform.com/en/docs/komodo-defi-framework/api/v20/swaps_and_orders/start_simple_market_maker_bot/) — accessed 2026-07-03 — [archived](../sources/2026-07-03-komodo-docs-start_simple_market_maker_bot.html)
