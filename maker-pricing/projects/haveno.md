---
tags: [p2p-dex, monero, maker-pricing, atomic-swap]
category: P2P Decentralised Exchange
website: https://haveno.exchange
docs: https://github.com/haveno-dex/haveno/blob/master/docs/user-guide.md
github: https://github.com/haveno-dex/haveno
launched: 2024
---

# Haveno

Haveno is an open-source, non-custodial P2P exchange platform for trading Monero (XMR) against fiat currencies (USD, EUR, GBP, etc.) and other cryptocurrencies. It is a fork of Bisq adapted for Monero as the base currency, with all trade settlement on the Monero blockchain and all communications routed through Tor. The official repository produces a reference implementation; real trades happen on independently operated third-party networks that build from the codebase.

## Adoption / usage metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| GitHub stars (haveno-dex/haveno) | 1,355 | 2026-07-03 | [GitHub API](https://api.github.com/repos/haveno-dex/haveno) — [archived](sources/2026-07-03-github-api-haveno-repo.json) |
| GitHub forks | 174 | 2026-07-03 | [GitHub API](https://api.github.com/repos/haveno-dex/haveno) — [archived](sources/2026-07-03-github-api-haveno-repo.json) |
| Open issues | 208 | 2026-07-03 | [GitHub API](https://api.github.com/repos/haveno-dex/haveno) — [archived](sources/2026-07-03-github-api-haveno-repo.json) |
| Repository created | 24 February 2020 | 2026-07-03 | [GitHub API](https://api.github.com/repos/haveno-dex/haveno) — [archived](sources/2026-07-03-github-api-haveno-repo.json) |
| First mainnet release | 1.0.0 (10 April 2024) | 2026-07-03 | [GitHub Releases API](https://api.github.com/repos/haveno-dex/haveno/releases) — [archived](sources/2026-07-03-github-api-haveno-releases.json) |
| Latest release | v1.8.0 (20 June 2026) | 2026-07-03 | [GitHub Releases API](https://api.github.com/repos/haveno-dex/haveno/releases) — [archived](sources/2026-07-03-github-api-haveno-releases.json) |
| Total releases since v1.0.0 | 28 | 2026-07-03 | [GitHub Releases API](https://api.github.com/repos/haveno-dex/haveno/releases) — [archived](sources/2026-07-03-github-api-haveno-releases.json) |
| On-chain trade volume | [NOT FOUND] | — | No public dashboard; third-party network data not aggregated centrally |
| Active users | [NOT FOUND] | — | Not publicly reported by any tracked network |
| Number of third-party networks | [NOT FOUND] | — | Not enumerated in official docs |

## How it works

### User perspective — creating a maker offer

1. The maker opens the "Create offer" screen in the desktop client (or calls `PostOffer` via the gRPC API).
2. The maker chooses direction (BUY or SELL XMR) and a fiat/crypto counter currency.
3. The maker selects pricing mode: **market-based** (relative margin from live market price) or **fixed price**.
4. If market-based, the maker enters a `marketPriceMarginPct` (e.g., 5% above market for a SELL offer).
5. Optionally, the maker sets a `triggerPrice`. If the market moves past this threshold the offer is automatically deactivated; it reactivates when the market returns.
6. The maker sets trade amount range: `amount` (maximum XMR) and `minAmount`.
7. The maker sets a `securityDepositPct`. Both buyer and seller lock this percentage of the trade amount in a 2-of-3 Monero multisig output for the duration of the trade.
8. The maker optionally toggles `isPrivateOffer` (requires the taker to know a challenge hash).
9. The maker optionally sets `buyerAsTakerWithoutDeposit` to waive the buyer's deposit obligation (shifting the full counterparty risk to the maker).
10. The offer is signed by an arbitrator, reserved on-chain by locking XMR in a multisig output, and broadcast to the Haveno Tor P2P network. It appears on other nodes' offer books within seconds.

### System perspective

1. **Offer construction:** `placeOffer()` in `OpenOfferManager` validates that a `triggerPrice` is not set for fixed-price offers (they are mutually exclusive). It creates an `OpenOffer` wrapping an `Offer` (which wraps `OfferPayload`).
2. **Offer broadcast:** The P2P layer broadcasts the signed `OfferPayload` protobuf over Tor to all peers. TTL is **11 minutes** — the offer must be re-broadcast by the maker's node before expiry.
3. **Price resolution at take-time:** When a taker hits the offer, both sides independently compute the trade price from their local `PriceFeedService` cache. The taker's proposed price is validated in `Offer.verifyTradePrice()` against a `PRICE_TOLERANCE` of 0.5%.
4. **Trigger monitoring:** `TriggerPriceService` listens to `PriceFeedService.updateCounterProperty()` (fires every ~60 seconds). On each price update it checks every open offer with a `triggerPrice != 0`. If the condition is met, it calls `OpenOfferManager.deactivateOpenOffer()`.
5. **Trade settlement:** Buyer and seller each pre-fund a 2-of-3 Monero multisig UTXO. The arbitrator holds the third key only for dispute resolution.

## Pricing parameters — complete maker-configurable set

### Core pricing fields (in `OfferPayload`)

| Field | Type | Description |
|-------|------|-------------|
| `useMarketBasedPrice` | `boolean` | `true` = price tracks live market; `false` = fixed price mode |
| `marketPriceMarginPct` | `double` | Fractional distance from market price (e.g., `0.05` = 5%). For BUY offers, `factor = 1 − margin` (maker buys below market). For SELL offers, `factor = 1 + margin` (maker sells above market). Zero when `useMarketBasedPrice = false`. |
| `price` | `long` | Fixed price in the counter currency's smallest unit. Zero when `useMarketBasedPrice = true`. |
| `amount` | `long` | Maximum trade amount in XMR atomic units (1 XMR = 10¹² atomic units). |
| `minAmount` | `long` | Minimum trade amount in XMR atomic units. Range trading is `isRange() = (amount != minAmount)`. |
| `buyerSecurityDepositPct` | `double` | Buyer's security deposit as a fraction of trade amount (e.g., `0.15` = 15%). |
| `sellerSecurityDepositPct` | `double` | Seller's security deposit as a fraction of trade amount. |
| `makerFeePct` | `double` | Trading fee the maker pays to the network (set per-network; default 0.15% for both fiat and crypto). |
| `takerFeePct` | `double` | Trading fee the taker pays (default 0.5% crypto, 0.75% fiat). |
| `penaltyFeePct` | `double` | Penalty charged from security deposit on trade failure (default 25% of security deposit). |
| `isPrivateOffer` | `boolean` | If `true`, taker must supply a pre-image matching `challengeHash`. |
| `extraInfo` | `String` | Free-text field shown to takers (max 1,500 characters). |
| `maxTradeLimit` | `long` | Payment-method-level trade limit in smallest currency unit (set by payment method, not directly by maker). |
| `maxTradePeriod` | `long` | Time-to-complete limit in milliseconds (set by payment method). |

### Out-of-payload trigger field (in `OpenOffer`, not broadcast)

| Field | Type | Description |
|-------|------|-------------|
| `triggerPrice` | `long` | Market price threshold in the counter currency's smallest unit. Stored locally only — **not included in the broadcast `OfferPayload`**. Cannot be set for fixed-price offers (`price != 0`). |
| `deactivatedByTrigger` | `boolean` | Flag set when the trigger caused deactivation; used to distinguish trigger-deactivation from manual deactivation so auto-reactivation applies only to trigger-caused deactivation. |

### API fields (gRPC `PostOfferRequest`, grpc.proto lines 500–516)

| gRPC field | Maps to |
|-----------|---------|
| `currency_code` | counter currency (e.g., `"USD"`) |
| `direction` | `"BUY"` or `"SELL"` (XMR direction) |
| `price` | fixed price string |
| `use_market_based_price` | `useMarketBasedPrice` |
| `market_price_margin_pct` | `marketPriceMarginPct` |
| `amount` | max XMR amount in atomic units |
| `min_amount` | min XMR amount in atomic units |
| `security_deposit_pct` | applied to both buyer and seller (single entry point) |
| `trigger_price` | `triggerPrice` (string, converted internally) |
| `reserve_exact_amount` | whether to reserve exactly `amount` or `minAmount` |
| `is_private_offer` | `isPrivateOffer` |
| `buyer_as_taker_without_deposit` | waive buyer deposit |
| `extra_info` | `extraInfo` free-text |
| `source_offer_id` | clone from existing offer (shared-funds feature) |

Sources: `OfferPayload.java` — [archived](sources/2026-07-03-haveno-offer-payload.java); `Offer.java` — [archived](sources/haveno_offer.java); `grpc.proto` — [archived](sources/2026-07-03-haveno-grpc-proto.proto)

## PRICE_TOLERANCE = 0.005 (0.5%)

Defined in `Offer.java` line 73:

```java
private final static double PRICE_TOLERANCE = 0.005;
```

This tolerance allows for up to 0.5% divergence between the maker's computed offer price and the taker's computed offer price at take-time. If either side's `PriceFeedService` cache is slightly stale, this buffer prevents spurious rejections.

Bisq uses `PRICE_TOLERANCE = 0.01` (1%). The comment in the Haveno source (`Offer.java` lines 69–72) reads: *"The tolerance will get smaller once we have multiple price feeds avoiding fast price fluctuations from one provider."* This is exactly the rationale: the pricenode system now aggregates multiple exchange sources (Binance, Kraken, Bitfinex, Poloniex, CoinGecko), so divergence between two nodes is expected to be smaller, warranting the tighter tolerance.

Source: `Offer.java` — [archived](sources/haveno_offer.java); Bisq `Offer.java` — [archived](sources/bisq_offer.java)

## Security deposit model

### Haveno vs Bisq

| Aspect | Haveno | Bisq |
|--------|--------|------|
| Unit | XMR atomic units (piconeros) | BTC satoshis |
| Expressed as | **Percentage of trade amount** (`buyerSecurityDepositPct`, `sellerSecurityDepositPct`) | **Fixed absolute amount** in BTC |
| Minimum deposit | `max(15% of trade amount, 0.1 XMR)` — `Restrictions.getMinSecurityDeposit()` | Variable; enforced at UI level |
| Maximum deposit pct | 50% (`Restrictions.MAX_SECURITY_DEPOSIT_PCT`) | Not directly comparable |
| Default | 15% (`Restrictions.MIN_SECURITY_DEPOSIT_PCT = 0.15`) | Network-defined |
| Buyer deposit waiver | `buyerSecurityDepositPct = 0` allowed only when `direction = SELL` (buyer is taker); maker absorbs all risk; maker fee increases to cover lost taker fee | Not supported |
| Mechanism | 2-of-3 Monero multisig; arbitrator holds 3rd key but never has custody | 2-of-2 BTC multisig + deposit address |

The percentage model means the security deposit scales automatically with trade size, whereas Bisq's fixed deposit underprotects large trades and overprotects small ones.

Source: `Restrictions.java` — [archived](sources/2026-07-03-haveno-restrictions.java); `OfferPayload.java` — [archived](sources/2026-07-03-haveno-offer-payload.java)

## Price feed / oracle system

### Architecture

Haveno uses a **pricenode** architecture (repo: `haveno-dex/haveno-pricenode`). A pricenode is a Java/Spring HTTP service deployed as a Tor hidden service. Clients call `GET /getAllMarketPrices` every 60 seconds (`PERIOD_SEC = 60` in `PriceFeedService`).

Three default pricenodes are hard-coded in `ProvidersRepository` (shuffled on startup to load-balance):

```
http://elaxlgigphpicy5q7pi5wkz2ko2vgjbq4576vic7febmx4xcxvk6deqd.onion/  # Haveno
http://lrrgpezvdrbpoqvkavzobmj7dr2otxc5x6wgktrw337bk6mxsvfp5yid.onion/  # Cake
http://agorise7ae5g7lkqp7r7qddsyzskft7cqhgguwkadbqamtsrap5onead.onion/  # Agorise
```

All three are `.onion` addresses, so price lookups never leave the Tor network. Users can override with `--providers` CLI flag.

### Exchange sources aggregated by the pricenode

The pricenode polls 18 exchange provider implementations for BTC/fiat, XMR/BTC, and XMR/fiat pairs every minute (sourced from `ExchangeRateService.java`, accessed 2026-07-03):

Binance, Bitfinex, Bitflyer, Bitstamp, BlueRate, BTCMarkets, CoinbasePro, CoinGecko, Coinone, CryptoYa, IndependentReserve, Kraken, KuCoin, Luno, MercadoBitcoin, Paribu, Poloniex, Yadio.

Not all providers carry XMR pairs directly; XMR/fiat rates not natively available are synthesised: `XMR/fiat = XMR/BTC × BTC/fiat`. Providers with confirmed direct XMR pairs include Binance (XMR/BTC, XMR/USDT), Kraken (XMR/USD, XMR/EUR, XMR/BTC), Bitfinex (XMR/USD, XMR/BTC), and Poloniex (XMR/BTC).

The pricenode aggregates these by computing a trimmed mean (outliers removed at 1.1 standard deviations, configurable via `haveno.price.outlierStdDeviation`). If only one exchange has data for a pair, that rate is used directly. XMR/fiat pairs not available directly are synthesised: `XMR/USD = XMR/BTC × BTC/USD`.

### How `PriceFeedService` uses data

- Prices are cached in `Map<String, MarketPrice>` keyed by counter currency code.
- Each `MarketPrice` carries a timestamp. Stale prices (beyond `MARKET_PRICE_MAX_AGE_MS`) are rejected by `isRecentPriceAvailable()` and `isRecentExternalPriceAvailable()` — the offer then fails at take-time with `MARKET_PRICE_NOT_AVAILABLE_MSG`.
- Additionally, `applyLatestHavenoMarketPrice()` seeds the cache with observed trade prices from `TradeStatistics3` — so even without an external pricenode, past trades inform pricing. External prices take precedence if available.

Source: `PriceFeedService.java` — [archived](sources/2026-07-03-haveno-price-feed-service.java); `ProvidersRepository.java` — [archived](sources/2026-07-03-haveno-providers-repository.java); `PriceProvider.java` — [archived](sources/2026-07-03-haveno-price-provider.java); pricenode README — [archived](sources/2026-07-03-haveno-pricenode-readme.md); `ExchangeRateService.java` — [archived](sources/2026-07-03-haveno-pricenode-exchange-rate-service.java)

## Offer lifecycle and repricing

### States

```
PENDING → AVAILABLE → RESERVED → CLOSED (trade complete)
                    ↘ DEACTIVATED (manual or trigger)
                    ↘ CANCELED (maker cancels)
```

(`INVALID` is a state on the `Offer` side, not the `OpenOffer` side.)

### Can a maker edit price without cancelling?

**Yes.** `EditOfferRequest` in the gRPC API (and `editOpenOfferStart` / `editOpenOfferPublish` in `OpenOfferManager`) allows updating `price`, `use_market_based_price`, `market_price_margin_pct`, and `trigger_price` without creating a new offer. Internally, the implementation:
1. Replaces the `OpenOffer` object with an edited copy.
2. If the arbitrator signature becomes invalid (because the signed fields changed), the offer goes back to `PENDING` and is re-signed by the arbitrator before re-publishing.
3. The offer ID is preserved so takers mid-availability-check do not lose their slot.

### Trigger price deactivation and reactivation

See [[patterns/trigger-price-deactivation]].

The trigger is **asymmetric by direction**:
- **SELL offer:** deactivated when `marketPrice < triggerPrice` (market dropped below maker's floor — maker does not want to sell at that price).
- **BUY offer:** deactivated when `marketPrice > triggerPrice` (market rose above maker's ceiling — maker would buy above their intended threshold).

Reactivation is automatic: `TriggerPriceService.checkPriceThreshold()` also handles the reverse condition (lines 144–158 of `TriggerPriceService.java`): if `openOffer.isDeactivatedByTrigger() && !isTriggered(marketPrice, openOffer)`, the offer is reactivated.

There is **no hysteresis band** — reactivation fires the moment the market price is no longer past the trigger, on the next 60-second price poll.

### Offer invalidation by stale price

If the pricenode becomes unreachable, `PriceFeedService` retries with the next provider in its shuffled list with exponential backoff. If all providers fail, the price cache becomes stale. A market-based offer queried at take-time with a stale cache throws `MarketPriceNotAvailableException` — the take fails, protecting both parties.

Source: `OpenOfferManager.java` — [archived](sources/2026-07-03-haveno-open-offer-manager.java); `TriggerPriceService.java` — [archived](sources/2026-07-03-haveno-trigger-price-service.java); `OpenOffer.java` — [archived](sources/2026-07-03-haveno-open-offer.java)

## Privacy model

### Tor + Monero effects on offer broadcasting

- **Maker identity:** The offer includes `ownerNodeAddress` (the maker's Tor onion address) and a `pubKeyRing`. The onion address changes between sessions if the maker restarts (ephemeral Tor identity), but the `pubKeyRing` is stable for the lifetime of the node identity. A sophisticated observer watching the P2P gossip layer could correlate offers from the same `pubKeyRing` across sessions.
- **Offer broadcast:** All P2P messages (offer publication, availability checks, trade messages) are relayed over Tor circuit-by-circuit. There is no IP address leakage by design.
- **Price privacy:** Pricenodes are Tor hidden services. The maker's price queries do not leave Tor, so there is no clearnet metadata linking price lookups to maker IP addresses.
- **Cross-offer linkability:** The `groupId` field in `OpenOffer` groups cloned offers (shared-funds feature) for the maker's local ledger management. It is **not** broadcast and does not appear in `OfferPayload`, so external observers cannot link cloned offers.
- **Monero settlement:** All funds flow through standard Monero transactions with ring signatures and stealth addresses. The maker's XMR reserve output is a normal Monero output — on-chain analysis cannot distinguish it from other outputs.

Source: `OfferPayload.java` fields `ownerNodeAddress`, `pubKeyRing`; `OpenOffer.java` field `groupId` — [archived](sources/2026-07-03-haveno-open-offer.java); `ProvidersRepository.java` — [archived](sources/2026-07-03-haveno-providers-repository.java)

## Differences from Bisq

| Aspect | Bisq | Haveno |
|--------|------|--------|
| Base currency | BTC | XMR |
| Security deposit unit | Absolute BTC amount | **Percentage of trade amount** |
| `marketPriceMargin` field name | `marketPriceMargin` (in `OfferPayload`) | `marketPriceMarginPct` (explicit `Pct` suffix for clarity) |
| `PRICE_TOLERANCE` | 1% (`0.01`) | **0.5% (`0.005`)** — tighter because multi-source aggregation reduces price divergence |
| Trade settlement | Bitcoin multisig | Monero 2-of-3 multisig (arbitrator holds key 3) |
| Maker fee | Fixed BSQ or BTC amount | **Percentage of trade amount** (`makerFeePct`) |
| Offer state: `OFFER_FEE_PAID` | Present (fee pre-paid on-chain) | Replaced by `OFFER_FEE_RESERVED` (XMR locked in output) |
| `triggerPrice` field | In `OfferPayload` (broadcast) | **In `OpenOffer` only (local, not broadcast)** |
| `lowerClosePrice` / `upperClosePrice` | Explicitly in `OfferPayload` (broadcast) | **Kept in `OfferPayload` for protocol compatibility, but UI/API uses `triggerPrice` instead** |
| `useAutoClose` / `useReOpenAfterAutoClose` | Exposed in `OfferPayload` | **Present in `OfferPayload` for compatibility, described as "reserved for future use cases"** |
| `penaltyFeePct` | Not present | **Added** — explicit penalty fraction charged on dispute |
| `buyerSecurityDepositPct` | Single `buyerSecurityDeposit` (absolute) | Split: `buyerSecurityDepositPct` + `sellerSecurityDepositPct` (both percentage) |
| `extraInfo` field | Not in `OfferPayload` | **Added** — free-text up to 1,500 chars for maker notes to takers |
| `isPrivateOffer` / `challengeHash` | Present in Bisq | Retained and functional in Haveno |
| Network | Open, one network | Federated — each operator runs own network; official repo ships reference only |
| Privacy routing | Tor | Tor (all pricenodes are `.onion`) |

Sources: Bisq `Offer.java` — [archived](sources/bisq_offer.java); Haveno `Offer.java` — [archived](sources/haveno_offer.java); `OfferPayload.java` — [archived](sources/2026-07-03-haveno-offer-payload.java)

## Limitations and criticisms

1. **Federated fragmentation:** The official Haveno repo does not run a mainnet network. Each third-party operator runs an isolated network with its own liquidity, arbitration services, and update cadence. This splits liquidity and complicates maker software targeting multiple networks.

2. **Single-source price fallback risk:** Despite multi-source aggregation at the pricenode, each Haveno client fetches from a **single active pricenode** at a time (round-robin failover). If that node's exchange data is momentarily stale or manipulated, all clients on that node see the bad price simultaneously. There is no client-side multi-node price verification.

3. **No hysteresis on trigger reactivation:** `TriggerPriceService` reactivates an offer the moment the market price clears the trigger threshold on the next 60-second poll. In choppy markets, an offer could oscillate rapidly between AVAILABLE and DEACTIVATED, generating unnecessary network traffic and potential reserve-locking/unlocking cycles.

4. **triggerPrice not broadcast:** Because `triggerPrice` is stored only in `OpenOffer` (local to the maker's node) and not in the broadcast `OfferPayload`, the trigger logic requires the maker's node to remain online. If the maker's daemon is offline, no deactivation occurs even if the market moves past the trigger. This is a deliberate privacy choice (not leaking trigger intent to the network) but it means the trigger is not a true stop-loss for offline makers.

5. **Price tolerance at exactly 0.5%:** In fast-moving markets (XMR has historically moved >5% in minutes), the 60-second price poll interval means that by the time a taker's `verifyTradePrice()` runs, the market price on either side could have moved more than 0.5% from the cached value. This causes valid takes to fail and the taker must retry. Bisq's 1% tolerance was set specifically to avoid this.

6. **Maker fee not maker-configurable:** `makerFeePct`, `takerFeePct`, and `penaltyFeePct` are set by the network operator (hard-coded in `HavenoUtils.java`), not by the individual maker. Makers cannot offer lower fees to attract takers.

Sources: `TriggerPriceService.java` — [archived](sources/2026-07-03-haveno-trigger-price-service.java); `ProvidersRepository.java` — [archived](sources/2026-07-03-haveno-providers-repository.java); Haveno README — [archived](sources/haveno_readme.md); `HavenoUtils.java` — [archived](sources/2026-07-03-haveno-utils.java)

## Key patterns

- [[patterns/trigger-price-deactivation]] — how trigger-based offer auto-deactivation and reactivation works
- [[metrics/maker-pricing-parameters]] — cross-protocol comparison of maker pricing knobs

## Sources

- [haveno-dex/haveno GitHub](https://github.com/haveno-dex/haveno) — accessed 2026-07-03 — [archived repo stats](sources/2026-07-03-github-api-haveno-repo.json)
- [haveno-dex/haveno releases](https://api.github.com/repos/haveno-dex/haveno/releases) — accessed 2026-07-03 — [archived](sources/2026-07-03-github-api-haveno-releases.json)
- [`Offer.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/Offer.java) — accessed 2026-07-03 — [archived](sources/haveno_offer.java)
- [`OfferPayload.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/OfferPayload.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-offer-payload.java)
- [`OpenOffer.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/OpenOffer.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-open-offer.java)
- [`OpenOfferManager.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/OpenOfferManager.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-open-offer-manager.java)
- [`TriggerPriceService.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/TriggerPriceService.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-trigger-price-service.java)
- [`PriceFeedService.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/provider/price/PriceFeedService.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-price-feed-service.java)
- [`ProvidersRepository.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/provider/ProvidersRepository.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-providers-repository.java)
- [`Restrictions.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/xmr/wallet/Restrictions.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-restrictions.java)
- [`HavenoUtils.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/trade/HavenoUtils.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-utils.java)
- [`grpc.proto`](https://github.com/haveno-dex/haveno/blob/master/proto/src/main/proto/grpc.proto) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-grpc-proto.proto)
- [haveno-pricenode README](https://github.com/haveno-dex/haveno-pricenode) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-pricenode-readme.md)
- [`ExchangeRateService.java`](https://github.com/haveno-dex/haveno-pricenode/blob/main/src/main/java/haveno/price/spot/ExchangeRateService.java) — accessed 2026-07-03 — [archived](sources/2026-07-03-haveno-pricenode-exchange-rate-service.java)
- Bisq `Offer.java` (for PRICE_TOLERANCE comparison) — accessed 2026-07-03 — [archived](sources/bisq_offer.java)
