---
tags: [pattern, offer-lifecycle, maker-pricing, auto-deactivation]
seen_in: [haveno, bisq]
---

# Trigger-Price Offer Deactivation

A maker sets a **trigger price** — a market price level — at which their open offer is automatically deactivated (removed from the public order book). When the market returns to the acceptable range, the offer is automatically reactivated. This lets makers protect themselves from fills at adverse prices without manually monitoring the market.

## Why it matters

Without a trigger, a market-based offer continues to track the live price indefinitely. If the market crashes or spikes, a maker may fill at a price they would not have chosen. The trigger acts as a conditional stop: it does not close a trade already in progress, but it prevents new takers from hitting the offer in adverse conditions.

## Implementations

### [[projects/haveno]]

**Source:** `TriggerPriceService.java`, `OpenOffer.java`, `OpenOfferManager.java` — [archived](../sources/2026-07-03-haveno-trigger-price-service.java)

**Configuration field:** `triggerPrice` (type `long`, counter-currency smallest unit, e.g., US cents × 10⁴ for USD/XMR).

**Where stored:** In `OpenOffer` (local to the maker's daemon), **not** in the broadcast `OfferPayload`. Takers and other network participants never see the trigger price.

**Trigger logic (from `TriggerPriceService.isTriggered()`, lines 99–122):**

```java
boolean isSellOffer = direction == OfferDirection.SELL;
return isSellOffer ?
        marketPriceAsLong < triggerPrice :  // SELL: deactivate if market drops below
        marketPriceAsLong > triggerPrice;   // BUY:  deactivate if market rises above
```

**Semantics by direction:**

| Offer direction | Trigger fires when | Maker's intent |
|----------------|--------------------|----------------|
| SELL XMR | `marketPrice < triggerPrice` | Market fell below the maker's acceptable sell floor; no longer willing to sell that cheap |
| BUY XMR | `marketPrice > triggerPrice` | Market rose above the maker's acceptable buy ceiling; no longer willing to buy that expensive |

**Poll interval:** 60 seconds (`PERIOD_SEC` in `PriceFeedService`). Trigger checks fire on every price update event from `PriceFeedService.updateCounterProperty()`.

**Deactivation flow:**
1. `TriggerPriceService.onPriceFeedChanged()` iterates all open offers indexed by currency code.
2. For each: `checkPriceThreshold(marketPrice, openOffer)`.
3. If `isTriggered()` returns `true` and offer state is `AVAILABLE`: `openOfferManager.deactivateOpenOffer(openOffer, true, ...)`.
4. `openOffer.deactivate(true)` sets `deactivatedByTrigger = true` and state to `DEACTIVATED`.
5. The offer is removed from the P2P offer book.

**Reactivation flow:**
1. Same poll, different branch: if state is `DEACTIVATED` AND `isDeactivatedByTrigger() == true` AND `!isTriggered(...)`: `openOfferManager.activateOpenOffer(...)`.
2. State returns to `AVAILABLE`.
3. The offer is re-published to the P2P offer book.
4. `setState(AVAILABLE)` internally resets `deactivatedByTrigger = false`.

**Key constraints:**
- `triggerPrice` cannot be set for fixed-price offers (`price != 0`). Validated in both `placeOffer()` and `editOpenOfferPublish()`.
- Trigger logic requires the maker's node to be **online**. If the daemon is offline, no deactivation occurs.
- No hysteresis: reactivation fires immediately when the price clears the threshold on the next poll. In volatile markets this can cause rapid oscillation.
- Manual deactivation (`deactivatedByTrigger = false`) does **not** auto-reactivate. Only trigger-caused deactivation auto-reactivates.

**Privacy note:** Because `triggerPrice` is not broadcast, observers on the P2P network cannot infer the maker's risk tolerance or stop-loss strategy from the offer alone.

### Bisq (reference)

**Source:** Bisq's Offer model (see `bisq_offer.java` in sources).

In Bisq, `lowerClosePrice` and `upperClosePrice` are fields in the **broadcast `OfferPayload`** — they are visible to all peers. `useAutoClose` and `useReOpenAfterAutoClose` are also in `OfferPayload`.

Haveno retains these same fields in its `OfferPayload` for wire-compatibility, but the comment explicitly labels them *"reserved for future use cases"*. The actual trigger mechanism in Haveno moved the active logic into `triggerPrice` on `OpenOffer` (local only), a deliberate privacy improvement.

## Design considerations for a maker daemon

1. **Online requirement:** A maker daemon implementing trigger-price deactivation must remain online and polling prices. It cannot rely on the protocol to enforce the trigger for an offline maker.
2. **Hysteresis:** Consider adding a configurable deadband (e.g., reactivate only if price clears trigger by X%) to prevent oscillation costs.
3. **Privacy vs. verifiability:** Haveno's local-only trigger is more private but cannot be verified by external monitors. A maker daemon could offer both models: local trigger (private) and broadcast trigger (auditable).
4. **Direction-aware semantics:** The asymmetric BUY/SELL logic (`< triggerPrice` for SELL, `> triggerPrice` for BUY) is intuitive once understood but non-obvious. Document it clearly in any maker API.

## Sources

- [`TriggerPriceService.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/TriggerPriceService.java) — accessed 2026-07-03 — [archived](../sources/2026-07-03-haveno-trigger-price-service.java)
- [`OpenOffer.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/OpenOffer.java) — accessed 2026-07-03 — [archived](../sources/2026-07-03-haveno-open-offer.java)
- [`OpenOfferManager.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/OpenOfferManager.java) — accessed 2026-07-03 — [archived](../sources/2026-07-03-haveno-open-offer-manager.java)
- [`OfferPayload.java`](https://github.com/haveno-dex/haveno/blob/master/core/src/main/java/haveno/core/offer/OfferPayload.java) (for `lowerClosePrice`/`upperClosePrice` fields) — accessed 2026-07-03 — [archived](../sources/2026-07-03-haveno-offer-payload.java)
