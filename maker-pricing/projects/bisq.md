---
title: "Bisq — Maker Pricing Configuration"
tags: [bisq, maker-pricing, p2p-dex, bitcoin, atomic-swap]
created: 2026-07-03
access_date: 2026-07-03
sources:
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/bisq_v1/OfferPayload.java
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/Offer.java
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOffer.java
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/provider/price/PriceFeedService.java
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OfferValidation.java
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/btc/wallet/Restrictions.java
  - https://bisq.wiki/Security_deposit
  - https://markets.bisq.network/api/volumes?basecurrency=btc
---

# Bisq — Maker Pricing Configuration

Bisq is a decentralised, non-custodial, peer-to-peer Bitcoin exchange using a 2-of-3 multisig escrow (later evolved to 2-of-2 with BurningMan arbitration) and Tor networking. Makers post signed offers to a distributed P2P orderbook; takers take offers and initiate the trade protocol. The maker's pricing parameters are encoded in a signed `OfferPayload` protobuf that is broadcast to peers.

## Repository

- **GitHub:** https://github.com/bisq-network/bisq  
- **Stars:** 5,114 | **Forks:** 1,295 | **Open issues:** 193 (accessed 2026-07-03)  
- **Language:** Java (JavaFX desktop app + core library)  
- **Licence:** AGPL-3.0

---

## 1. All Pricing Parameters Available to a Maker

All pricing parameters are immutable fields encoded in `OfferPayload.java` at offer creation time. The offer is re-signed and re-published if edited (see §4).

### 1.1 Core pricing fields (`OfferPayload.java`, accessed 2026-07-03)

| Field | Type | Description |
|-------|------|-------------|
| `price` | `long` | Fixed trade price in the counter currency's smallest unit. For fiat offers: units of 10⁻⁴ of the fiat currency (e.g. USD 65,000/BTC is stored as 650,000,000). For altcoin offers: satoshis. Set to 0 when `useMarketBasedPrice=true`. |
| `marketPriceMargin` | `double` | Percentage distance from market price. E.g. `0.05` = 5% above/below. Sign direction depends on offer direction: a BUY offer with `+0.05` offers to buy at 5% *below* market; a SELL offer with `+0.05` offers to sell at 5% *above* market. `0.0` if `useMarketBasedPrice=false`. |
| `useMarketBasedPrice` | `boolean` | Toggles market-based vs. fixed-price mode. When `true`, `price` in the payload is 0 and effective price is computed at take-time from the market price feed. |
| `amount` | `long` | Maximum trade size (satoshis). This is the upper bound of the range if `minAmount < amount`. |
| `minAmount` | `long` | Minimum trade size (satoshis). If equal to `amount`, the offer is for a single fixed size. Otherwise it defines a range. |
| `maxTradeLimit` | `long` | Per-payment-method cap on trade size imposed by the payment account's `PaymentMethod` limits (e.g. SEPA has a lower cap than SWIFT). Set by the platform, not freely chosen by the maker. |
| `maxTradePeriod` | `long` | Offer expiry window in milliseconds. Derived from the payment method (e.g. SEPA = 8 days). Not freely overridden by the maker — it is set by `PaymentMethod.getMaxTradePeriod()`. |
| `buyerSecurityDeposit` | `long` | Security deposit in satoshis locked by the buyer. Range: 15%–50% of `amount` (min 0.0003 BTC in absolute terms). Default is 15%. |
| `sellerSecurityDeposit` | `long` | Security deposit in satoshis locked by the seller. Fixed at 15% of `amount` (min 0.0003 BTC). Not maker-configurable beyond the payment method minimum. |
| `useAutoClose` | `boolean` | Reserved field (added but **not yet active** as of the source examined). Intended to close the offer when a trigger price is reached. |
| `useReOpenAfterAutoClose` | `boolean` | Reserved field. Intended to reopen the offer with remaining funds after an auto-close triggered partial fill. |
| `lowerClosePrice` | `long` | Reserved. Intended lower price trigger for auto-close. |
| `upperClosePrice` | `long` | Reserved. Intended upper price trigger for auto-close. |
| `isPrivateOffer` | `boolean` | Reserved. Intended for private offers requiring an access key (`hashOfChallenge`). Not yet active in the UI. |

**Source:** `OfferPayload.java`, line 65–115, https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/bisq_v1/OfferPayload.java (accessed 2026-07-03)

### 1.2 Trigger price (OpenOffer layer, added v1.5.3)

A separate `triggerPrice` field (`long`, satoshis) lives in `OpenOffer.java`, not `OfferPayload`. It is *not* broadcast to other peers; it is stored locally. When the market price reaches `triggerPrice`, the maker's own node **deactivates** the offer (sets `OpenOffer.State.DEACTIVATED`), removing it from the P2P orderbook. This is the active, working mechanism for price-triggered deactivation — distinct from the reserved `useAutoClose`/`lowerClosePrice`/`upperClosePrice` fields in `OfferPayload`.

**Source:** `OpenOffer.java`, lines 77–79, 93–98, https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOffer.java (accessed 2026-07-03)

### 1.3 Security deposit bounds

From `Restrictions.java` (https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/btc/wallet/Restrictions.java, accessed 2026-07-03):

- `MIN_SECURITY_DEPOSIT` = 0.0003 BTC (absolute minimum in satoshis)
- `MIN_SECURITY_DEPOSIT_AS_PERCENT` = 0.15 (15%)
- `MAX_BUYER_SECURITY_DEPOSIT_AS_PERCENT` = 0.5 (50%)
- Default buyer deposit = 15% (same as minimum)
- Seller deposit is fixed at 15% minimum; it is not a free maker choice

The maker sets `buyerSecurityDeposit` as a percentage of trade amount at offer creation. The taker must match the maker's chosen percentage. A symmetric deposit design (`USE_SYMMETRIC_SECURITY_DEPOSIT = true`) means the taker's deposit equals the maker's stated deposit.

---

## 2. Price Feed / Oracle — PriceFeedService

### 2.1 Architecture

Bisq uses a **pricenode** infrastructure: independent nodes (community-run, on Tor hidden services) aggregate prices from multiple exchanges and serve a JSON feed over HTTP/Tor. The maker's app queries these nodes every 60 seconds ± up to 5 seconds of jitter (`PERIOD_SEC = 60` in `PriceFeedService.java`).

**Default pricenode Onion addresses** (from `PriceFeedNodeAddressProvider.java`, accessed 2026-07-03):
- `http://ro7nv73awqs3ga2qtqeqawrjpbxwarsazznszvr6whv7tes5ehffopid.onion/` (operated by @alexej996)
- `http://runbtcpn7gmbj5rgqeyfyvepqokrijem6rbw7o5wgqbguimuoxrmcdyd.onion` (operated by @runbtc)

Custom providers can be set via the `--providers` program argument.

**Source:** `PriceFeedNodeAddressProvider.java`, lines 42–45, https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/provider/PriceFeedNodeAddressProvider.java (accessed 2026-07-03)

### 2.2 Exchange sources on the pricenode

The `bisq-pricenode` repo (https://github.com/bisq-network/bisq-pricenode) aggregates prices from the following exchange providers (accessed 2026-07-03):

Binance, BitcoinAverage, Bitfinex, Bitflyer, Bitstamp, BTCMarkets, CoinGecko, CoinMarketCap, CoinbasePro, Coinone, CryptoYa, IndependentReserve, Kraken, KuCoin, Luno, MercadoBitcoin, Paribu, Poloniex, Yadio, BlueRateProvider (for Argentine blue-market rate).

The pricenode aggregates per-currency by **averaging prices across providers after removing outliers** (standard deviation filtering, configurable via `bisq.price.outlierStdDeviation`, default 1.1). If only one provider covers a currency, its price is used directly. If multiple providers cover a currency, the outlier-filtered average is used.

**Source:** `ExchangeRateService.java` (bisq-pricenode), https://github.com/bisq-network/bisq-pricenode/blob/master/src/main/java/bisq/price/spot/ExchangeRateService.java (accessed 2026-07-03)

### 2.3 Price staleness and availability

- `MARKET_PRICE_MAX_AGE_SEC = 1800` (30 minutes). Prices older than 30 minutes are considered stale and unavailable. (`MarketPrice.java`, https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/provider/price/MarketPrice.java, accessed 2026-07-03)
- The feed is polled on a 60-second interval with random jitter. On failure, a retry timer increments by 5 seconds each attempt (up to 60 seconds).
- If the current pricenode does not respond, the client rotates to the next available pricenode in round-robin order.

### 2.4 How marketPriceMargin is applied at take time

From `Offer.getPrice()` in `Offer.java` (https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/Offer.java, accessed 2026-07-03):

```java
// For fiat (BUY offer = maker wants to buy BTC for fiat):
factor = (direction == BUY) ? 1 - marketPriceMargin : 1 + marketPriceMargin;

// For crypto altcoins (BUY offer = maker wants to buy altcoin for BTC):
factor = (direction == SELL) ? 1 - marketPriceMargin : 1 + marketPriceMargin;

effectivePrice = marketPrice.getPrice() * factor
```

A positive `marketPriceMargin` always represents a "better deal for the maker" — i.e. the maker offers to sell slightly above market or buy slightly below market.

---

## 3. Offer Lifecycle and Repricing

### 3.1 Offer states

`OpenOffer.State` (from `OpenOffer.java`, accessed 2026-07-03):

| State | Meaning |
|-------|---------|
| `AVAILABLE` | Active in the P2P orderbook; takers can see and take this offer |
| `RESERVED` | Taker is in the process of taking the offer; offer is locked for up to 60 seconds |
| `CLOSED` | Trade completed; offer removed from book |
| `CANCELED` | Maker manually cancelled or system removed the offer |
| `DEACTIVATED` | Maker deactivated the offer (trigger price hit, or manually disabled) — removed from orderbook but can be reactivated |

If a take-offer attempt fails (e.g., deposit tx not completed), the offer automatically reverts from `RESERVED` to `AVAILABLE` after a 60-second timeout.

### 3.2 Can a maker update price without cancelling?

**No — not in real-time.** The maker cannot update `marketPriceMargin` or `price` without going through an edit flow that effectively cancels and republishes the offer under the same ID.

The `editOpenOfferStart` / `editOpenOfferPublish` flow in `OpenOfferManager.java` (accessed 2026-07-03) works as follows:
1. `editOpenOfferStart`: deactivates the existing offer (removes it from P2P network)
2. `editOpenOfferPublish`: marks old offer as `CANCELED`, creates a new `OpenOffer` with edited parameters, republishes it
3. The offer keeps the same ID but gets a new payload and new P2P broadcast

This means **repricing incurs a full network cancel + republish cycle**. However, for *market-based* offers (`useMarketBasedPrice=true`), the effective price updates automatically every poll cycle (60 seconds) as the market price feed refreshes — no republish required. Only changing `marketPriceMargin` itself requires a republish.

**Source:** `OpenOfferManager.java`, lines 625–681, https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOfferManager.java (accessed 2026-07-03)

### 3.3 Taker price tolerance at trade time

When a taker takes a market-based offer, both maker and taker independently compute the effective price from their local price feeds. Because the two nodes may have slightly different market prices (different pricenode, different timing), a tolerance is applied:

- `PRICE_TOLERANCE = 0.01` (1%) in `Offer.java` (accessed 2026-07-03)
- If the deviation between maker's and taker's computed price exceeds 1%, the take-offer attempt is rejected with `PRICE_OUT_OF_TOLERANCE`

**Additionally** at availability check time (before taker fee is paid), the offer price must be within `Preferences.MAX_PRICE_DISTANCE * 1.1` of market:
- `MAX_PRICE_DISTANCE = 0.25` (25%)
- With 10% tolerance applied: max allowed deviation = 0.275 (27.5%)

This means a maker can set a `marketPriceMargin` up to 25% away from market price (UI-validated), but at take time the price must be within 1% of the taker's independently computed price.

**Source:** `Offer.java` line 81; `OfferValidation.java` lines 81–88; `Preferences.java` lines 83–84 (all accessed 2026-07-03)

---

## 4. Adoption Metrics

| Metric | Value | Source |
|--------|-------|--------|
| GitHub stars | 5,114 | https://api.github.com/repos/bisq-network/bisq (accessed 2026-07-03) |
| GitHub forks | 1,295 | https://api.github.com/repos/bisq-network/bisq (accessed 2026-07-03) |
| Open issues | 193 | https://api.github.com/repos/bisq-network/bisq (accessed 2026-07-03) |
| Annual trade volume 2024 | ~2,890 BTC (63,364 trades) | https://markets.bisq.network/api/volumes?basecurrency=btc (accessed 2026-07-03) |
| Annual trade volume 2023 | ~3,800 BTC (61,082 trades) | https://markets.bisq.network/api/volumes?basecurrency=btc (accessed 2026-07-03) |
| Annual trade volume 2022 | ~3,632 BTC (59,048 trades) | https://markets.bisq.network/api/volumes?basecurrency=btc (accessed 2026-07-03) |
| Live ticker (BTC/USD) | ~$58,305 (last traded) | https://markets.bisq.network/api/ticker (accessed 2026-07-03) |
| Active offers count | [NOT FOUND] — no public API for live offer count |  |
| Total user count | [NOT FOUND] — no public metrics; Bisq does not require accounts |  |

**Volume trend note:** Peak was 2019 (~13,907 BTC, 26,714 trades). Volume has declined since 2019 due to Lightning/atomic-swap competition and the Bisq DAO transition. Full-year 2025: 2,322.65 BTC across 64,683 trades. 2026 YTD (to 2026-07-03): 27,334 trades (BTC volume [NOT FOUND] from API at access date).

---

## 5. Limitations of the Bisq Pricing Model

### 5.1 No real-time mid-offer repricing
Changing `marketPriceMargin` requires a full cancel+republish cycle. This creates latency risk: in volatile markets, an offer may be taken at a stale price before the maker can cancel it. For market-based offers, the price tracks market automatically (within the 1% taker tolerance), so this mainly affects fixed-price offers.

### 5.2 Single oracle per polling interval
The maker's node queries one pricenode at a time (round-robin). A compromised or lagging pricenode can cause the maker to compute a materially different price than the taker. The 1% `PRICE_TOLERANCE` mitigates this but does not eliminate it.

### 5.3 Oracle manipulation risk
Bisq pricenodes aggregate from centralised exchanges (Binance, Bitstamp, Kraken, etc.). A coordinated flash crash on multiple exchanges could temporarily distort the pricenode feed, enabling takers to take offers at prices unfavourable to makers before the maker's app detects the discrepancy. The 30-minute staleness window provides a floor but not an upper bound on manipulation timing.

### 5.4 Auto-close fields are reserved but not active
The `useAutoClose`, `lowerClosePrice`, and `upperClosePrice` fields in `OfferPayload` are documented as "reserved for future use cases" in the source code comments. The functional equivalent — local trigger price deactivation — exists in `OpenOffer.triggerPrice` but is local-only and not broadcast to peers. This means other nodes cannot verify or honour trigger conditions; the offer may remain visible to peers briefly after trigger.

### 5.5 Security deposit asymmetry abolished
Bisq originally allowed asymmetric deposits (maker and taker could set different amounts). The `USE_SYMMETRIC_SECURITY_DEPOSIT = true` flag enforces symmetric deposits, simplifying the model but reducing maker flexibility. Makers cannot use a higher seller deposit to signal confidence or discourage frivolous takers.

### 5.6 Payment method constrains expiry and size
`maxTradePeriod` and `maxTradeLimit` are not freely configurable by the maker — they are derived from the selected `PaymentMethod`. A maker who wants a faster expiry than the payment method's maximum must cancel manually.

### 5.7 UX friction for market makers
There is no native Bisq API or daemon mode for automated market-making. A maker must run the full JavaFX desktop application. Programmatic access is possible via the Bisq API (gRPC interface added in later versions), but the application must remain running.

### 5.8 MEV-like exposure
Because offer details (including `marketPriceMargin`) are broadcast to the P2P network in plaintext (signed protobuf), sophisticated takers can identify offers where the maker's local market price is lagging and time their take to exploit the price difference within the 1% tolerance window. This is structurally similar to MEV in Ethereum contexts.

---

## 6. Key Design Decisions for a Maker Daemon

1. **Adopt `useMarketBasedPrice=true` + `marketPriceMargin`** as the default strategy. It eliminates the need for constant republishing; only the margin parameter needs changing when strategy shifts.

2. **Replicate the pricenode architecture** — aggregate from multiple exchanges, apply outlier filtering (sigma-based), cache with a freshness window (30 minutes). See [[market-price-margin]] for the general pattern.

3. **Implement a local trigger price** equivalent to Bisq's `OpenOffer.triggerPrice`: monitor market price locally and deactivate/cancel offers when the price moves adversely. Do not rely on the broadcast offer payload to carry trigger logic.

4. **Treat `PRICE_TOLERANCE` as a two-sided parameter**: set it wide enough to tolerate oracle latency between maker and taker (Bisq uses 1%), but narrow enough to prevent price exploitation. A 0.5%–1% range is appropriate for a single-exchange oracle; use tighter tolerances with multi-exchange aggregation.

5. **Avoid non-configurable expiry by payment method** — in an atomic-swap daemon, expiry (timelock) is configurable at the protocol level. Expose this as a maker parameter.

---

## Sources

| File | URL | Access date |
|------|-----|-------------|
| `OfferPayload.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/bisq_v1/OfferPayload.java | 2026-07-03 |
| `Offer.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/Offer.java | 2026-07-03 |
| `OpenOffer.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOffer.java | 2026-07-03 |
| `OpenOfferManager.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOfferManager.java | 2026-07-03 |
| `PriceFeedService.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/provider/price/PriceFeedService.java | 2026-07-03 |
| `PriceFeedNodeAddressProvider.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/provider/PriceFeedNodeAddressProvider.java | 2026-07-03 |
| `MarketPrice.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/provider/price/MarketPrice.java | 2026-07-03 |
| `OfferValidation.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OfferValidation.java | 2026-07-03 |
| `Restrictions.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/btc/wallet/Restrictions.java | 2026-07-03 |
| ExchangeRateService (pricenode) | https://github.com/bisq-network/bisq-pricenode/blob/master/src/main/java/bisq/price/spot/ExchangeRateService.java | 2026-07-03 |
| Security deposit wiki | https://bisq.wiki/Security_deposit | 2026-07-03 |
| Trade volume API | https://markets.bisq.network/api/volumes?basecurrency=btc | 2026-07-03 |
| Ticker API | https://markets.bisq.network/api/ticker | 2026-07-03 |
| GitHub repo stats | https://api.github.com/repos/bisq-network/bisq | 2026-07-03 |
