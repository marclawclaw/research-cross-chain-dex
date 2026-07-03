---
title: "Pattern: Market Price Margin (% offset from oracle price)"
tags: [pricing-pattern, market-price-margin, oracle, maker-daemon]
created: 2026-07-03
access_date: 2026-07-03
sources:
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/bisq_v1/OfferPayload.java
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/Offer.java
---

# Pattern: Market Price Margin (% offset from oracle price)

## Summary

A maker configures their offer price as a **percentage distance from a live market price oracle** rather than an absolute fixed price. The effective trade price is computed at take-time by applying the margin to the current oracle price. This allows offers to remain valid across price movements without constant republishing.

## Exemplar implementation: Bisq

### Fields

```java
// OfferPayload.java
double marketPriceMargin;  // e.g. 0.05 = 5%
boolean useMarketBasedPrice;  // true = use margin; false = use fixed price
```

### Price computation at take-time (`Offer.getPrice()`)

```java
// Fiat pairs (base=BTC, counter=USD/EUR/etc.)
factor = (direction == BUY) ? 1 - marketPriceMargin
                             : 1 + marketPriceMargin;

// Altcoin pairs (base=ALT, counter=BTC)
factor = (direction == SELL) ? 1 - marketPriceMargin
                              : 1 + marketPriceMargin;

effectivePrice = oraclePrice * factor
```

**Convention:** positive `marketPriceMargin` always favours the maker — a SELL offer at +5% is priced 5% above market; a BUY offer at +5% offers to buy 5% below market.

### Staleness guard

The oracle price is rejected if it is older than 30 minutes (`MARKET_PRICE_MAX_AGE_SEC = 1800`). If no recent price is available, `getPrice()` returns `null` and the offer cannot be taken.

### Price tolerance at take-time

Because maker and taker may observe different oracle prices (different polling time, different pricenode), a tolerance is applied:

```
PRICE_TOLERANCE = 0.01  (1%)
if |takerPrice / makerPrice - 1| > 0.01 → reject with PRICE_OUT_OF_TOLERANCE
```

### Pricenode architecture

Bisq runs community-operated **pricenodes** (Tor hidden services) that aggregate prices from Binance, Bitstamp, Kraken, CoinGecko, and 15+ other exchanges, then compute an outlier-filtered average for each currency pair. Clients poll every 60 seconds and rotate to a backup node on failure.

This avoids coupling the maker's app to any single exchange API, and provides resilience to individual exchange outages.

## Adoption across P2P protocols

| Protocol | Field name | Notes |
|----------|-----------|-------|
| Bisq | `marketPriceMargin` (double, e.g. 0.05) | Applied at take-time; pricenode aggregates 15+ exchanges |
| Haveno | `marketPriceMarginPct` (percentage) | Fork of Bisq; tighter PRICE_TOLERANCE of 0.5% vs Bisq's 1% |
| RoboSats | `premium` (number, e.g. 5.0 = 5%) | Applied multiplicatively; uses Kraken/Bitfinex via Lightning |
| eigenwallet | `--ask-spread`, `--bid-spread` | Symmetric around mid; single Kraken oracle |

## Advantages

- **No constant republishing:** effective price updates every oracle poll cycle without touching the signed offer payload.
- **Fair price discovery:** both maker and taker compute price from the same oracle source; neither can unilaterally fix a stale price.
- **Protocol simplicity:** single parameter (`marketPriceMargin`) captures the entire pricing strategy for range of market conditions.

## Risks and mitigations

| Risk | Bisq mitigation | Recommendation for daemon |
|------|----------------|--------------------------|
| Oracle lag | 60s poll + 30min staleness window | Add a jitter/freshness check before accepting a take |
| Pricenode manipulation | Multi-exchange outlier-filtered average | Use your own price aggregation with ≥3 independent sources |
| Taker exploiting oracle latency | 1% PRICE_TOLERANCE | Set tolerance proportional to oracle freshness guarantee |
| Flash crash distortion | 30min staleness window catches prolonged outages | Add volatility-scaled tolerance: widen in high-vol periods |

## Implementation recipe for an atomic-swap daemon

```
1. Poll price_oracle(currency_pair) every T seconds
2. Cache with timestamp; reject if age > MAX_PRICE_AGE
3. effectivePrice = oracle_price * (1 + maker_margin * direction_factor)
4. Broadcast offer with (maker_margin, oracle_timestamp_hint)
5. At take-time: both sides compute effectivePrice independently
6. Reject take if |delta| > PRICE_TOLERANCE
```

`PRICE_TOLERANCE` should be ≥ `oracle_poll_interval / oracle_update_frequency` to account for timing differences.

---

## Sources

| File | URL | Access date |
|------|-----|-------------|
| `OfferPayload.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/bisq_v1/OfferPayload.java | 2026-07-03 |
| `Offer.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/Offer.java | 2026-07-03 |
| `MarketPrice.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/provider/price/MarketPrice.java | 2026-07-03 |
