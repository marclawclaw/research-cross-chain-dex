---
title: "Pattern: Trigger-Based Offer Deactivation (local trigger price)"
tags: [pricing-pattern, auto-close, trigger-price, offer-lifecycle]
created: 2026-07-03
access_date: 2026-07-03
sources:
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOffer.java
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOfferManager.java
  - https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/bisq_v1/OfferPayload.java
---

# Pattern: Trigger-Based Offer Deactivation (local trigger price)

## Summary

A maker sets a price threshold at which their offer is automatically **deactivated** (removed from the public orderbook) if the market price moves beyond that level. This protects the maker from having an offer taken at an adverse price during volatile markets, without requiring the maker to constantly monitor and manually cancel.

## Two approaches found in Bisq

### Approach A: Local trigger price (active, added v1.5.3)

`OpenOffer.triggerPrice` is a `long` (satoshis) stored locally on the maker's node. It is **not** part of the broadcast `OfferPayload` — peers cannot see it. The maker's node monitors the oracle price feed and deactivates the offer locally when the trigger is hit.

```java
// OpenOffer.java, lines 77-79
// "If market price reaches that trigger price the offer gets deactivated"
private final long triggerPrice;

// triggerInfoShouldBeShown() returns true when triggerPrice > 0
public boolean triggerInfoShouldBeShown() {
    return triggerPrice > 0 || feeValidationStatus.fail();
}
```

When deactivated:
- `OpenOffer.State` → `DEACTIVATED`
- Offer is removed from the P2P orderbook (peers see it as gone)
- The offer data and ID are retained locally
- The maker can reactivate the offer manually

The trigger price is set (or cleared) per-offer via the UI or Bisq API. It persists across restarts via protobuf serialisation.

**Limitation:** Because `triggerPrice` is local-only, if the maker's node is offline when the trigger is breached, the offer remains visible to peers until the node reconnects.

### Approach B: Reserved auto-close fields (not yet active)

`OfferPayload` contains `useAutoClose`, `lowerClosePrice`, `upperClosePrice`, and `useReOpenAfterAutoClose`. These are serialised into the broadcast payload but are documented as "reserved for future use cases" in the source code (as of 2026-07-03). They are present in protobuf but have no active execution logic in the examined codebase.

Intent (from code comments):
- `lowerClosePrice`: cancel offer when price falls below this level
- `upperClosePrice`: cancel offer when price rises above this level  
- `useReOpenAfterAutoClose`: reopen with remaining funds after partial fill triggered close

This would be a **network-wide**, cryptographically-committed trigger: all peers could verify and enforce it, rather than relying on the maker's node being online.

**Source:** `OfferPayload.java`, lines 102–110 (accessed 2026-07-03)

## Comparison

| Property | Local trigger (active) | Broadcast auto-close (reserved) |
|----------|----------------------|--------------------------------|
| Where stored | `OpenOffer` (local) | `OfferPayload` (broadcast) |
| Peers can verify | No | Yes (planned) |
| Offline protection | No — node must be online | Yes — peers enforce it |
| Can set lower+upper bounds | One threshold | Yes — both lowerClosePrice and upperClosePrice |
| Auto-reopen on partial fill | No | Planned via `useReOpenAfterAutoClose` |
| Active in codebase | Yes (v1.5.3+) | No (reserved) |

## Implications for an atomic-swap maker daemon

### What to adopt

A daemon is always online, so the local trigger model is sufficient and simpler to implement:

```
1. maker_set trigger_price = P  (e.g. stop accepting swaps if BTC < 50,000 USD)
2. every oracle_poll_interval:
     if oracle_price crosses trigger_price:
         deactivate_all_offers()
         optionally: reactivate when price recovers
```

### What to design differently

If the daemon can be offline (e.g., mobile context), a **commitment-based** approach (Approach B) is preferable: embed the trigger condition in the signed offer payload. Peers that receive the offer can refuse to initiate trades if the condition is violated, even if the maker is offline. This requires:

- Including `triggerCondition` in the serialised offer
- Peers checking `oraclePrice` against `triggerCondition` before initiating
- Oracle attestation (e.g., TLS notary or DLC oracle) to prove the price at take-time

### Reopen-after-partial-fill

Bisq's `useReOpenAfterAutoClose` concept addresses a real maker pain point: if an offer is for 1 BTC range (0.01–1 BTC) and a taker takes only 0.3 BTC, the remaining 0.7 BTC is idle until the maker manually posts a new offer. Auto-reopen would create a new offer for the residual amount. A daemon should handle this in its offer-management layer.

---

## Sources

| File | URL | Access date |
|------|-----|-------------|
| `OpenOffer.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOffer.java | 2026-07-03 |
| `OpenOfferManager.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/OpenOfferManager.java | 2026-07-03 |
| `OfferPayload.java` | https://github.com/bisq-network/bisq/blob/master/core/src/main/java/bisq/core/offer/bisq_v1/OfferPayload.java | 2026-07-03 |
