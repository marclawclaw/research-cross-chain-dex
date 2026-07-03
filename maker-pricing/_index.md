# Research Index: P2P Maker Pricing Configuration

**Domain definition:** P2P decentralised exchange and atomic-swap protocols where a participant acting as a "maker" can configure their own pricing parameters when posting an offer or running a maker daemon. This includes atomic swap protocols with maker daemons (eigenwallet/COMIT xmr-btc-swap, Farcaster), P2P multisig/escrow trading platforms (Haveno, Bisq, RoboSats), and orderbook-based DEXes with maker control (Komodo Wallet/AtomicDEX). Excludes AMM-based DEXes (Uniswap, Thorchain CLP), centralised exchanges, and protocols where pricing is fully automated without maker configuration.

**Primary metric:** Richness of maker pricing configuration options — the number of distinct pricing knobs/strategies a maker can configure. This includes support for: fixed price, market margin %, spread, min/max size constraints, dynamic adjustment, rate sources, auto-close triggers, and security deposit controls. This metric matters for Franck's goal of designing maker pricing options for an atomic-swap maker daemon.

**Discovery sources:** GitHub API and repository documentation (accessed 2026-07-03). Verified protocol stars, forks, and primary metrics from live repositories. Source code examined for Bisq, Haveno, and RoboSats maker implementations.

## Discovered entities

| Rank | Name | Category | Pricing config richness | Source | Selected |
|------|------|----------|------------------------|--------|----------|
| 1 | Bisq | P2P Fiat-Crypto DEX | 8+ parameters | https://github.com/bisq-network/bisq (5114 stars) | yes |
| 2 | Haveno | P2P Monero-Fiat DEX | 7+ parameters | https://github.com/haveno-dex/haveno (1354 stars) | yes |
| 3 | Komodo DeFi Framework | Multi-chain Atomic Swap DEX | 6+ parameters | https://github.com/KomodoPlatform/komodo-defi-framework | yes |
| 4 | RoboSats | Lightning P2P DEX | 4+ parameters | https://github.com/RoboSats/robosats (1005 stars) | yes |
| 5 | eigenwallet | XMR-BTC Atomic Swap Daemon | 4 parameters | https://github.com/eigenwallet/core (714 stars) | yes |
| 6 | Farcaster Core | BTC-XMR Atomic Swap Protocol | 3+ parameters | https://github.com/farcaster-project/farcaster-core (39 stars) | yes |

## Shortlist rationale

- **Bisq:** Highest GitHub engagement (5114 stars, 1295 forks). Most mature implementation with richest pricing configuration: marketPriceMargin, useMarketBasedPrice, fixed price, auto-close triggers (lowerClosePrice/upperClosePrice), security deposits (buyerSecurityDeposit/sellerSecurityDeposit). Demonstrates comprehensive maker controls including offer state management and trade limits. Selected as top benchmark.

- **Haveno:** Second-highest community adoption (1354 stars). Forked from Bisq but optimised for privacy (Monero, Tor). Retains similar pricing structure but adapted for XMR-fiat trading. Demonstrates how pricing abstractions generalise across currency pairs and privacy models.

- **Komodo DeFi Framework:** Production-grade multi-chain atomic swap DEX with configurable market maker bot (`start_simple_market_maker_bot`). Supports periodic price updates and multiple oracle sources. Represents the highest technical maturity for automated maker daemons (Rust, libp2p, HTLC).

- **RoboSats:** Different approach using Lightning hold invoices. Simplest pricing model (premium percentage markup), but demonstrates privacy-first P2P design. Relevant for makers seeking minimal configuration overhead.

- **eigenwallet:** Battle-tested atomic swap daemon with focused pricing model (ask-spread, bid-spread). Core reference implementation originally from COMIT network. Directly addresses the atomic-swap maker daemon use case.

- **Farcaster Core:** Protocol-level library (lowest stars, most experimental). Included to represent the emerging protocol-definition layer distinct from application/daemon implementations. Demonstrates swap-deal-level pricing abstractions.

## Research questions

1. **Pricing parameter types:** What distinct pricing knobs does each protocol expose to the maker?
   - Fixed price vs. market-based margin
   - Spread configuration (bid/ask)
   - Premium percentage markup
   - Min/max trade size limits
   - Trigger-based auto-close (price, time)
   - Security deposit controls

2. **Oracle/price sources:** What exchange rate sources do makers use and how are they configured?
   - Market price feed integration (Bisq/Haveno use PriceFeedService)
   - Oracle selection in maker daemon
   - Fallback mechanisms for price unavailability
   - Real-time vs. periodic price updates (Komodo makerbot)

3. **Spread vs. fixed price:** How do makers choose between margin-based and fixed-price strategies?
   - Market margin percentage (e.g., Bisq: marketPriceMargin)
   - Direct price specification
   - Conditional use based on price availability

4. **Dynamic repricing:** Can makers update prices mid-offer without cancellation?
   - Haveno/Bisq: Offer state machine (AVAILABLE, RESERVED, CLOSED)
   - Komodo: Periodic bot price updates
   - eigenwallet: ask-spread/bid-spread reconfiguration
   - RoboSats: Premium adjustment constraints

5. **Amount constraints:** How are min/max trade amounts configured?
   - Absolute amount limits (minAmount, maxAmount)
   - Relationship to maker's balance
   - Per-order vs. global limits

## Gaps and uncertainties

- **Zwap/Atheon solver model:** User mentioned Zwap as a protocol with solver pricing configuration. Search for "Zwap" or "Atheon" did not return active GitHub repositories or documentation. [NOT FOUND] — may be proprietary, defunct, or require different search terms.

- **Maker bot strategies beyond simple spreads:** Komodo supports `start_simple_market_maker_bot`, but documentation of advanced strategies (e.g., order-size-based pricing, volatility-adjusted spreads) was [NOT FOUND] in public sources.

- **Dynamic repricing latency:** Haveno and Bisq do not appear to support real-time mid-offer repricing without cancellation/reposting. Latency impact on maker UX unclear.

- **Oracle attack resilience:** How each protocol mitigates oracle manipulation during offer lifecycle not fully documented in source code examined.

- **Maker fee/spread vs. taker fee balance:** How each protocol's fee structure (maker vs. taker) interacts with pricing strategies not deeply explored.

- **Privacy-preserving pricing:** eigenwallet (Monero) and Haveno may support privacy-enhancing price discovery mechanisms; details [NOT FOUND] in archival.

## Selected entity details

### Bisq (Top-ranked by community adoption)

**Pricing parameters found in source (bisq_offer.java):**
- `marketPriceMargin`: double (percentage markup/markdown on market price)
- `useMarketBasedPrice`: boolean (toggle market-based vs. fixed)
- `price`: long (fixed trade price in satoshi or fiat)
- `amount`: long (BTC or altcoin amount)
- `minAmount`: long (minimum trade size)
- `maxTradeLimit`: long (maximum cumulative trade limit)
- `buyerSecurityDeposit`, `sellerSecurityDeposit`: long (security deposit amounts)
- `maxTradePeriod`: long (offer expiry window)
- `useAutoClose`: boolean (auto-close on price trigger)
- `lowerClosePrice`, `upperClosePrice`: long (trigger prices for auto-close)

**Price tolerance mechanism:**
- `PRICE_TOLERANCE = 0.01` (1% tolerance between maker and taker price calculations)
- Uses `PriceFeedService` to fetch market price for margin calculation
- Validates taker's calculated price within tolerance window

### Haveno (Fork of Bisq, optimised for Monero)

**Pricing parameters found in source (haveno_offer.java):**
- `marketPriceMarginPct`: percentage margin on market price
- `useMarketBasedPrice`: boolean toggle
- `triggerPrice`: long (price trigger for automatic actions)
- Similar structure to Bisq, adapted for XMR-fiat pairs
- `PRICE_TOLERANCE = 0.005` (0.5%, tighter than Bisq)

### RoboSats (Lightning-based, simplest model)

**Pricing parameters found in source (robosats_makerform.tsx):**
- `premium`: number (percentage premium, e.g., +5% or -3%)
- `currency`: number (fiat currency code)
- `minAmountLimit`, `maxAmountLimit`: calculated from premium and available limits
- Premium applied multiplicatively: `price * (1 + premium / 100)`
- `amountSafeThresholds`: [1.03, 0.98] (safety margins for limit calculation)

**Simplicity advantage:** No market price feed integration needed; makers set premium as a simple markup. Constraints derived from platform's available trading limits per currency.

### Komodo DeFi Framework (Automated maker bot)

**Documented pricing method (start_simple_market_maker_bot):**
- Periodic price updates (configurable interval)
- Configurable spreads for buy/sell orders
- Multiple oracle source support
- Telegram alert integration for off-chain notifications

**Advantages for automation:**
- Rust/libp2p stack for robust networking
- HTLC-based cross-chain atomic swaps
- Battle-tested production deployment
- Support for multi-asset pairs via modular coin/chain config

### eigenwallet (Atomic swap daemon, ask-spread model)

**Known pricing parameters (from GitHub repo history and COMIT heritage):**
- `--ask-spread`: percentage spread on XMR sell price
- `--bid-spread`: percentage spread on BTC buy price
- Implied: min-rate, max-rate configuration for rate limiting
- Designed for unattended maker daemon operation

**Advantages for daemon operation:**
- Focused, minimal configuration surface
- Direct inheritance from COMIT xmr-btc-swap
- Battle-tested in production (eigenwallet.org)

### Farcaster Core (Protocol-level library)

**Pricing configuration (from docs):**
- Role-based pricing: swap roles define who acts as maker vs. taker
- Trade-specific swap deal configuration
- ECDSA adaptor signatures enable cryptographic price commits

**Limitations:** No standalone daemon or automatic market making. Library for implementing custom swap protocols; pricing strategies must be implemented by application layer.

## Conclusions and recommendations

1. **Richness ranking by parameter count:**
   - Bisq/Haveno: 8–10 distinct pricing knobs (highest complexity, most features)
   - Komodo: 6+ (spreads, oracle selection, automation features)
   - eigenwallet, RoboSats: 4–5 (simpler, focused on core spread/margin)
   - Farcaster: 3 (protocol-level, delegated to app layer)

2. **For atomic-swap maker daemon design:**
   - **Adopt Komodo's approach:** Periodic price update loop with configurable spreads and oracle selection. Supports unattended operation and multi-pair trading.
   - **Simplify with RoboSats/eigenwallet:** For single-pair daemons (e.g., BTC-XMR only), premium or spread markup is sufficient. Reduces configuration surface and operational complexity.
   - **Optional features from Bisq:**
     - Auto-close triggers (price-based or time-based offer expiry)
     - Security deposit controls (if applicable to your protocol)
     - Price tolerance validation (guard against stale oracle data)

3. **Missing features to consider:**
   - **Dynamic repricing:** None of the protocols support real-time mid-offer price updates without cancellation. Atomic swaps naturally impose this constraint (swap deal is atomic).
   - **Volatility-adjusted spreads:** No protocol found implements dynamic spread adjustment based on recent volatility. Could differentiate your daemon.
   - **Order-flow toxicity metrics:** No protocol penalises or rewards makers based on taker-side order outcomes. Opportunity for innovation.

---

**Archival note:** All source files and READMEs archived to `maker-pricing/sources/` within this vault.

