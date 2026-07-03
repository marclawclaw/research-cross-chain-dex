---
title: Pattern — Percentage Premium Markup Over Market Price
tags: [pattern, pricing, premium, p2p, maker-daemon]
created: 2026-07-03
related: [[projects/robosats]], [[projects/bisq]], [[projects/haveno]]
---

# Pattern: Percentage Premium Markup Over Market Price

## Description

A maker specifies their desired trade price not as an absolute fiat figure, but as a signed percentage deviation from an external market reference price (the "oracle" or "benchmark" rate). The system continuously recomputes the effective trade price as:

```
effective_price = oracle_price × (1 + premium_pct / 100)
sats            = (fiat_amount / effective_price) × 100_000_000
```

A positive premium means the maker is pricing above market (more expensive for a buyer to buy BTC from the maker). A negative premium is a discount. Zero means at-market.

## Canonical Implementation: RoboSats

RoboSats uses this pattern as its **primary and default pricing model**:

- Field: `premium` (`DecimalField(max_digits=5, decimal_places=2)`)
- Range: −99.99% to +999% (fiat), −99.99% to +99% (swap)
- Default: 0%
- Oracle: Coordinator-cached median of blockchain.info + yadio.io (and optionally bitpay, criptoya), refreshed every 30 seconds via Celery task
- Finalisation: `last_satoshis` is re-computed on every status poll (marked-to-market) until the taker bond is locked; after that the satoshi count is frozen

Source: https://github.com/RoboSats/robosats/blob/main/api/logics.py#L220-L258
Accessed: 2026-07-03.

## Key Properties of the Pattern

### Advantages

1. **Market-tracking:** The order remains competitively priced even if it sits in the book for hours. A fixed-price order posted at $60,000/BTC becomes stale if the market moves to $62,000; a 0% premium order always quotes the current market.

2. **Simplicity for maker:** The maker only needs to decide "how much margin do I want?" rather than "what is the exact BTC price right now?" This is especially useful for long-running automated daemons.

3. **Competitive signalling:** Order books sorted by premium allow takers to quickly identify the best-priced offers. A maker at −1% (discount) will be taken much faster than one at +5%.

4. **No repricing needed:** Because the price floats with the oracle, the maker does not need to cancel and re-post as the market moves, reducing bond friction.

### Disadvantages / Risks

1. **Oracle dependency:** If the oracle returns a stale or manipulated rate, the effective price may be wrong. A maker daemon must monitor oracle staleness.

2. **Mark-to-market risk at finalisation:** There is a window between when the taker initiates (picks up the order) and when both bonds are locked, during which the market can move. The final `last_satoshis` is set at taker-bond-lock, not at the moment the taker first hits "take".

3. **No post-creation update:** In RoboSats, `premium` cannot be updated after the order is published. A daemon must cancel and re-post to adjust premium (losing bond time).

4. **Free-option during public phase:** Any taker can observe the order and wait for an advantageous market moment to take it. The taker bond creates a cost for non-completion but does not prevent the taker from timing the market at the maker's expense.

## Alternative: Explicit / Fixed-Satoshi Mode

RoboSats also supports `is_explicit = true` with a fixed `satoshis` field. This eliminates oracle dependency and free-option risk (the price is static), but:
- The maker must reprice manually as the market moves.
- If the order sits for hours at a stale fixed price, it may become very attractive to takers at the maker's expense.

Best for: short-lived orders where the maker wants certainty on the satoshi amount.

## Adoption by Other P2P Protocols

| Protocol | Premium Model | Notes |
|----------|--------------|-------|
| RoboSats | `premium` % | Marked-to-market until taker bond; |
| Bisq | Percentage price or fixed price | Maker chooses; marked-to-market via oracle |
| Haveno (Monero) | Percentage premium | Similar to Bisq model |

(See [[projects/bisq]] and [[projects/haveno]] for details.)

## Implementation Notes for Daemon Developers

A maker daemon implementing this pattern should:

1. **Set premium at order creation** based on desired margin and competitive analysis of the current order book.
2. **Monitor order age**: if the order has been public for a significant fraction of `public_duration` without a taker, consider cancelling and re-posting at a lower (more competitive) premium.
3. **Track `last_satoshis` from API responses**: this is the real-time satoshi amount that will be locked. Use it to validate that the effective price is still within acceptable bounds before accepting a taker.
4. **Handle oracle staleness**: if `currentPrice` is unavailable, the coordinator API returns an error; do not post new orders until the oracle recovers.
5. **Set `bond_size` to balance security and attractiveness**: a 3% bond is the default and a reasonable starting point; increase for large orders or suspicious counterparties.
6. **Set `public_duration` and `escrow_duration`** based on operational tolerance — shorter durations reduce capital lockup but may miss slow takers.

Source: https://github.com/RoboSats/robosats/blob/main/api/logics.py
Accessed: 2026-07-03.
