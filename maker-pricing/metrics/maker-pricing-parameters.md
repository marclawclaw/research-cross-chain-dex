---
tags: [metrics, maker-pricing, comparison, bisq, haveno, robosats, eigenwallet, komodo, farcaster]
updated: 2026-07-03
---

# Maker Pricing Parameters — Cross-Protocol Comparison

Pricing knobs available to a maker at offer/order creation time across the six P2P protocols surveyed. Data sourced from source code and documentation as of 2026-07-03.

## Full parameter matrix

| Parameter | Bisq | [[projects/haveno]] | RoboSats | Komodo DeFi | eigenwallet | [[projects/farcaster]] |
|-----------|------|---------------------|----------|-------------|-------------|------------------------|
| **Fixed price** | ✓ (`price` long, counter-currency smallest unit) | ✓ | ✗ (premium % only) | ✓ (absolute price in MM bot) | ✗ (spread over oracle only) | ✓ (implicit: set `arbitrating_amount` + `accordant_amount` directly) |
| **Market margin %** | ✓ `marketPriceMargin` (double, e.g. 0.05=5%) | ✓ `marketPriceMarginPct` | ✓ `premium` (number, e.g. 5.0=5%) | ✓ (spread % in MM bot config) | ✓ `ask_spread` (TOML decimal, default 0.02 = 2%; no bid-side equivalent) | ✗ (no oracle integration; rate is implicit in chosen amounts) |
| **Min trade size** | ✓ `minAmount` | ✓ | ✓ `min_amount` (fiat) | ✓ `min_volume` | ✓ `min_buy_btc` (TOML, default 0.002 BTC) | N/A (single absolute amount per deal) |
| **Max trade size** | ✓ `amount` | ✓ | ✓ `max_amount` (fiat) | ✓ `max_volume` | ✓ `max_buy_btc` (TOML, default 0.02 BTC; auto-reduced by XMR balance) | N/A (single absolute amount per deal) |
| **Buyer security deposit** | ✓ 15%–50% of trade (absolute BTC) | ✓ 15%–50% (% of trade amount; scales with size) | N/A (Lightning hold invoice) | N/A | N/A | N/A |
| **Seller security deposit** | ✓ fixed 15% min (absolute BTC) | ✓ `sellerSecurityDepositPct` | N/A | N/A | N/A | N/A |
| **Buyer deposit waiver** | ✗ | ✓ `buyerAsTakerWithoutDeposit` (SELL offers; maker fee rises) | N/A | N/A | N/A | N/A |
| **Offer expiry / timelock** | Limited — derived from `PaymentMethod`; stored in `maxTradePeriod` | Similar; 11-min TTL (re-broadcast required) | 24h–168h (maker choice) | No expiry — bot continuously updates | HTLC timelock (configured) | ✓ `cancel_timelock` + `punish_timelock` (CSV block counts, set per deal) |
| **Local trigger price deactivation** | ✓ `OpenOffer.triggerPrice` (v1.5.3+) | ✓ `triggerPrice` (local only; auto-reactivates on recovery) | ✗ | ✗ | ✗ | ✗ |
| **Broadcast auto-close (price-bound)** | Reserved (`useAutoClose`, `lowerClosePrice`, `upperClosePrice`) | ✗ | ✗ | ✗ | ✗ | ✗ |
| **Auto-reopen after partial fill** | Reserved (`useReOpenAfterAutoClose`) | ✓ (automatic on price recovery; no extra config) | ✗ | ✗ | ✗ | ✗ |
| **Price tolerance (taker check)** | ✓ 1% (`PRICE_TOLERANCE = 0.01`) | ✓ 0.5% (`PRICE_TOLERANCE = 0.005`) | N/A | N/A | N/A | N/A |
| **Max price distance from market** | ✓ 25% UI cap (`MAX_PRICE_DISTANCE = 0.25`) | ✓ similar | No hard limit | No hard limit | No hard limit | No hard limit |
| **Private offer (access key)** | Reserved (`isPrivateOffer`, `hashOfChallenge`) | ✓ `isPrivateOffer` + `challengeHash` (functional) | ✗ | ✗ | ✗ | ✗ |
| **Free-text extra info** | ✗ | ✓ `extraInfo` (max 1,500 chars) | ✗ | ✗ | ✗ | ✗ |
| **Clone from existing offer** | ✗ | ✓ `sourceOfferId` (up to 10 shared-funds clones) | ✗ | ✗ | ✗ | ✗ |
| **Penalty fee** | ✗ | ✓ `penaltyFeePct` (default 25% of security deposit) | N/A | N/A | N/A | N/A |
| **Payment method constraint** | ✓ (payment method sets maxTradeLimit, maxTradePeriod) | ✓ | ✓ (currency-based limits) | ✓ (coin-specific) | ✗ (BTC-XMR only) | ✗ (BTC-XMR only) |
| **Oracle sources** | 20+ exchanges via pricenode aggregation | 18 exchanges via pricenode aggregation | Single provider (CoinGecko/Kraken) | Multiple providers configurable | 3 live feeds (Kraken WS, Bitfinex WS, KuCoin WS) + optional Exolix REST; arithmetic mean; stale-feed window 600 s; quotes halted if all feeds fail | None — no oracle; maker supplies explicit amounts |
| **Oracle freshness window** | 30 min (`MARKET_PRICE_MAX_AGE_SEC = 1800`) | Similar | Real-time | Configurable (bot refresh interval) | 600 s per feed (`price_ticker_validity_duration_secs`); quotes halted beyond | N/A |
| **Periodic auto-republish** | ✓ (offers re-broadcast every ~6 min) | ✓ (11-min TTL; daemon re-broadcasts) | N/A | ✓ (bot re-posts orders) | N/A (quote served on demand via libp2p; not broadcast) | ✗ (single-use deal string; maker must recreate for each swap) |
| **Symmetric deposit enforcement** | ✓ enforced (`USE_SYMMETRIC_SECURITY_DEPOSIT=true`) | ✓ | N/A | N/A | N/A | N/A |

## Pricing parameter count by protocol

| Protocol | Active knobs | Reserved/planned | Notes |
|----------|-------------|-----------------|-------|
| Bisq | 10 | 4 | Most complete; reserved fields show planned features |
| Haveno | 12 | 0 | Fork of Bisq; tighter tolerances; adds private offer, deposit waiver, cloning, penalty fee |
| Komodo DeFi | 6 | — | Best for automated market-making; bot-native |
| RoboSats | 4 | — | Simplest; Lightning; premium % only |
| eigenwallet | 4 | — | Atomic swap focus; ask-only spread via TOML config; no runtime repricing |
| Farcaster | 2 | — | Protocol-only; implicit rate from absolute amounts; no oracle; effectively abandoned (last commit 2023) |

## Security deposit defaults and constraints

### Bisq
| Constraint | Value | Source |
|-----------|-------|--------|
| Minimum buyer deposit % | 15% | `Restrictions.java` |
| Maximum buyer deposit % | 50% | `Restrictions.java` |
| Absolute minimum deposit | 0.0003 BTC | `Restrictions.java` |

### Haveno
| Constraint | Value | Source |
|-----------|-------|--------|
| Default security deposit % | 15% (`MIN_SECURITY_DEPOSIT_PCT = 0.15`) | `Restrictions.java` |
| Minimum security deposit % | 15% | `Restrictions.java` |
| Maximum security deposit % | 50% (`MAX_SECURITY_DEPOSIT_PCT = 0.5`) | `Restrictions.java` |
| Absolute minimum deposit | 0.1 XMR | `Restrictions.java` |
| Minimum trade amount | 0.05 XMR | `Restrictions.java` |
| Max shared-funds clones | 10 (`MAX_OFFERS_WITH_SHARED_FUNDS`) | `Restrictions.java` |

## Fee defaults

### Bisq
Maker fee paid in BTC or BSQ; amount varies by BSQ market price. Not a fixed percentage.

### Haveno (set by network operator in `HavenoUtils.java`)
| Fee | Crypto pairs | Fiat pairs | Source |
|-----|-------------|-----------|--------|
| Maker fee | 0.15% | 0.15% | `HavenoUtils.java` lines 103–105 |
| Taker fee | 0.50% | 0.75% | `HavenoUtils.java` lines 104–106 |
| Maker fee (buyer taker without deposit) | 0.65% | 0.90% | `HavenoUtils.java` lines 107–108 |
| Penalty fee | 25% of security deposit | 25% of security deposit | `HavenoUtils.java` line 102 |

## Key design decisions for atomic-swap daemon

### Adopt from Bisq/Haveno
- `marketPriceMargin` / `marketPriceMarginPct` as primary pricing parameter with market-based price tracking
- Local `triggerPrice` for defensive deactivation (private, daemon-enforced)
- `PRICE_TOLERANCE` check at swap initiation time (0.5%–1% range)
- Multi-source oracle aggregation with outlier filtering and freshness window

### Adopt from Haveno only
- Percentage-based security deposits (scale with trade size, fairer for both parties)
- `buyerAsTakerWithoutDeposit` option for SELL-side liquidity provisioning
- `extraInfo` free-text for maker-to-taker communication

### Adopt from Farcaster
- `DealParameters` struct as a clean separation of concerns: `arbitrating_amount`, `accordant_amount`, `cancel_timelock`, `punish_timelock`, and `fee_strategy` are independent fields — no conflation of exchange rate with fee rate
- `TradeRole`/`SwapRole` orthogonality: maker can choose to be Alice (XMR seller) or Bob (BTC seller) independently of being maker or taker
- `FeeStrategy` type: `Fixed(SatPerKvB)` or `Range { min_inc, max_inc }` decouples Bitcoin on-chain fee from exchange rate

### Add beyond all surveyed protocols
- Configurable offer expiry (timelock parameter, not payment-method-derived)
- Asymmetric spread (different margin for buy vs. sell direction)
- Volatility-scaled tolerance (widen `PRICE_TOLERANCE` when market is volatile)
- Broadcast trigger bounds (lowerClosePrice/upperClosePrice) — planned in Bisq but not yet implemented

## Sources

| Source | URL | Access date |
|--------|-----|-------------|
| Bisq OfferPayload.java | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/bisq_v1/OfferPayload.java | 2026-07-03 |
| Bisq Restrictions.java | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/btc/wallet/Restrictions.java | 2026-07-03 |
| Haveno Restrictions.java | https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/xmr/wallet/Restrictions.java | 2026-07-03 |
| Haveno HavenoUtils.java | https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/trade/HavenoUtils.java | 2026-07-03 |
| Haveno OfferPayload.java | https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/OfferPayload.java | 2026-07-03 |
| RoboSats repo | https://github.com/RoboSats/robosats | 2026-07-03 |
| eigenwallet repo | https://github.com/eigenwallet/core | 2026-07-03 |
| eigenwallet config defaults | https://github.com/eigenwallet/core/blob/master/swap-env/src/defaults.rs | 2026-07-03 |
| eigenwallet config struct | https://github.com/eigenwallet/core/blob/master/swap-env/src/config.rs | 2026-07-03 |
| Komodo DeFi repo | https://github.com/KomodoPlatform/komodo-defi-framework | 2026-07-03 |
| Farcaster core repo | https://github.com/farcaster-project/farcaster-core | 2026-07-03 |
| Farcaster node repo | https://github.com/farcaster-project/farcaster-node | 2026-07-03 |
| Farcaster RFC 01 | https://github.com/farcaster-project/rfcs/blob/main/01-high-level-overview.md | 2026-07-03 |
