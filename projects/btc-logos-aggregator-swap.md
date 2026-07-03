---
tags: [project, idea, lambda-prize, atomic-swaps, bitcoin, logos, lez, rfp-003, aggregator, browser-swap, design]
ecosystem: Bitcoin ↔ Logos Execution Zone (LEZ)
category: Lambda-prize on RFP-003 — aggregator web app that proxies the RFP-003 taker module, plus a Satora-style browser BTC wallet
status: idea / design sketch
based_on: logos-co/rfp RFP-003 (Atomic Swaps with LEZ) — this is a Lambda-prize built ON TOP of it, not a competing submission
related: [[projects/satora]], [[projects/eigenwallet]], [[projects/comit]]
author: Marclaw
---

# BTC ↔ Logos aggregator web app — a Lambda-prize on top of RFP-003

**Idea (Marclaw).** A **Lambda-prize built on top of
[RFP-003](https://github.com/logos-co/rfp/blob/main/RFPs/RFP-003-atomic-swaps.md)**.
RFP-003 delivers the trust-minimised BTC↔LEZ **maker/taker adaptor-signature
protocol** *and its taker module* (Schnorr/BIP-340 + Taproot/BIP-341, taker-first
ordering, LEZ Risc0 escrow, resumable swap state). This Lambda-prize does **not
reimplement any of that** — it **consumes RFP-003's taker module as a dependency**.

Concretely: the aggregator **runs the RFP-003 taker module** and **deploys a web app
that drives that taker module as a proxy**. The user-facing web app is a thin client
(price browsing, an embedded [[projects/satora]]-style BTC wallet, LEZ-address entry,
status/refund UI); all swap logic is delegated to the RFP-003 taker running on the
aggregator node, which the web app talks to over a proxy/RPC interface. The prize's
deliverable is the **aggregation + hosted-taker-proxy + consumer web app** layer, not
the swap protocol.

The design borrows Satora's two best UX ideas — an in-browser BTC wallet from a
seed, and a **user-driven refund path that never depends on the server** — and grafts
them onto the RFP-003 taker module and LEZ escrow.

## Relationship to RFP-003 (dependency, not fork)

| | RFP-003 delivers | This Lambda-prize delivers |
|---|---|---|
| Swap protocol | BTC↔LEZ adaptor-sig + Taproot; LEZ Risc0 escrow; atomicity | — (consumed as-is) |
| Taker | taker module + taker CLI + taker mini-app | **runs the taker module as a hosted service** |
| Coordination | Logos Delivery (offers) + Logos Chat (negotiation) | aggregates maker prices into a web view |
| Client | CLI / Logos mini-app | **consumer web app that proxies the taker module** + embedded BTC wallet |
| Refund/recovery | on-chain-only, resumable state, taker CLI | Satora-style seed-refund UI + "import mid-flight swap into standalone taker" recovery |

So the aggregator web app is a **presentation + hosting layer over RFP-003's taker**,
analogous to how Satora is a hosted front-end over the Lendaswap protocol.

## Roles

| Role | Who runs it | What it does |
|------|-------------|--------------|
| **User** | Browser web app | Holds an embedded BTC wallet (seed-derived, à la Satora), provides a **Logos/LEZ wallet address** to receive tokens, funds the BTC side, and can refund BTC unilaterally. |
| **Aggregator** | Hosted node running the **RFP-003 taker module** + a web app that proxies it | Ingests maker price quotes over Logos Delivery, surfaces them in the web app; on user request, calls the taker module (over a proxy/RPC interface) to negotiate with the selected maker and drive the taker side. Unlocks the LEZ tokens to the user's LEZ address on success. |
| **Maker** | Independent RFP-003 maker daemon | Advertises offers over Logos Delivery, locks LEZ-side funds after the user's BTC is confirmed, and claims the BTC via the adaptor secret. |

The aggregator is **taker-as-a-service**: it *runs RFP-003's taker module unchanged*
and exposes it to a web app as a proxy. The prize's own code is the aggregation UI,
the proxy/RPC glue to the taker module, the embedded BTC wallet, and the
refund/recovery UX — not the swap protocol.

## Happy-path flow (user buys LEZ tokens with BTC)

1. **Discovery.** Aggregator node subscribes to maker offers over Logos Delivery and
   surfaces a best-price view in the web app. User picks a pair/amount.
2. **Wallet setup.** Web app generates (or restores) a local BTC wallet from a
   12-word seed (Satora pattern). User pastes their **LEZ wallet address** as the
   token destination.
3. **Negotiation.** User starts the swap. The aggregator, acting as **taker**,
   negotiates swap parameters (amount, price, timelocks, adaptor point, Taproot
   output) with the selected maker over Logos Chat.
4. **User funds BTC first (taker-first ordering, RFP-003 Reliability #1).** The web
   app shows a **Taproot (P2TR) address**; the user sends BTC to it **from any wallet
   — including the embedded wallet, an external wallet, or a CEX withdrawal**. Only
   the *funding* must hit that address; the spend authority for claim/refund is what
   must be seed-controlled (see Refund).
5. **Maker locks LEZ.** After the BTC funding confirms, the maker locks the
   corresponding tokens in the **LEZ Risc0 escrow** (RFP-003 Functionality #5),
   contingent on the adaptor secret.
6. **Aggregator unlocks LEZ for the user.** The taker completes its side; the LEZ
   escrow releases tokens to the **user's LEZ address**. Revealing the adaptor
   secret on LEZ is what lets the maker claim the BTC.
7. **Maker claims BTC** via the cooperative **key-path spend** (indistinguishable
   from a normal Taproot payment — RFP-003 Functionality #2).

```
User BTC  → P2TR (Taproot)      → Maker claims BTC (key-path, after secret revealed)
Maker LEZ → LEZ Risc0 escrow    → Aggregator/taker unlocks LEZ → User's LEZ address
```

## Refund path (Satora-style, user-driven)

Mirrors [[projects/satora]]'s principle: **the BTC refund authority derives from the
user's seed, so it never depends on the aggregator being online or honest.**

- **BTC refund.** If the swap stalls (maker never locks LEZ, or aggregator never
  unlocks), the user refunds the Bitcoin **from the embedded wallet** after the
  Bitcoin timelock. RFP-003 Functionality #2 allows the refund branch to be either a
  **pre-signed timelocked key-path transaction** or a **Taproot script-path tapleaf
  (`OP_CHECKSEQUENCEVERIFY`)**; the script-path is the RFP's recommended default and
  is the safer fit here, because it is consensus-enforced and needs no fragile
  pre-signed refund tx to be stored client-side (RFP-003 Reliability #7). The embedded
  wallet signs the tapleaf spend to a user-chosen BTC address.
- **No aggregator needed for refund.** This is the key safety property, taken
  straight from Satora and reinforced by RFP-003 Reliability #2 ("on-chain-only
  execution after lock"): once BTC is locked, the user can reclaim it using only
  their seed + a Bitcoin node/Esplora, with no Logos Delivery/Chat and no aggregator.

## Recovery mode (import a mid-flight swap into a taker app)

Needed for the failure mode: **the user's BTC is locked, the maker locked LEZ, but
the aggregator never unlocked the LEZ tokens** (aggregator down, censoring, or buggy).
The user must be able to complete or refund without the aggregator.

- The web app persists swap state (RFP-003 Reliability #4: swap state persistence +
  resumable) and can **export a swap descriptor** — the adaptor point, Taproot
  details, escrow ID, timelocks, and the seed-derived keys needed to act.
- The user **imports the mid-flight swap into a standalone RFP-003 taker app/CLI**
  (RFP-003 Usability #4 taker CLI, #6 taker mini-app) and drives it to completion
  (claim the LEZ) or waits out the timelock and refunds the BTC.
- Because RFP-003 mandates on-chain-only execution after lock and resumable state,
  this hand-off is a supported path, not a hack. A Satora-style `recover`-from-seed
  routine re-derives the necessary keys.

## Where this diverges from RFP-003 (call it out honestly)

- **Centralisation of coordination.** RFP-003 Functionality #1 is a hard requirement
  that the app *not* depend on any centralised server; coordination must use Logos
  Delivery + Logos Chat directly. **The aggregator is centralised infrastructure** —
  it is a UX layer on top of the decentralised protocol, not a replacement for it.
  This is a deliberate product tradeoff (frictionless onboarding, price aggregation,
  taker-as-a-service) that a pure RFP-003 submission would not make. Mitigation: the
  aggregator must be *non-custodial and refund-safe by construction* (the recovery
  and BTC-refund paths above), so its centralisation affects **liveness/UX, never
  fund safety** — exactly Satora's trust boundary.
- **The prize runs RFP-003's taker module unchanged**, so it inherits RFP-003's
  taker-side security (taker-first ordering means the *user's* BTC is the first
  on-chain action, and the maker is never exposed to a non-responsive taker). The
  Lambda-prize adds no new consensus-critical or on-chain code — its surface is the
  web app, the taker-module proxy, and the embedded wallet.
- **Proxy trust surface.** Because the web app drives the taker module *remotely*,
  the proxy/RPC interface between them is new attack surface (auth, request
  integrity, which side signs what). The seed-controlled BTC refund and the
  recovery-mode hand-off are what keep this from becoming a custody risk: worst case
  the proxy misbehaves and the user recovers via their own seed.

## Open questions / to design

1. **Secret custody: hosted taker module vs. seed-controlled client.** In vanilla
   RFP-003 the taker (which holds the adaptor secret) *is* the user. Here the
   **hosted taker module** holds it while the *user* must still be able to recover
   unilaterally. So the key question is the split: the client's embedded wallet must
   hold the **BTC refund key** and enough swap material to complete via recovery mode
   (import into a standalone taker); the hosted taker module holds only what it needs
   to relay/negotiate. If the hosted module held the *only* copy of the adaptor
   secret, an aggregator outage after BTC lock would strand the user until timelock —
   acceptable (they refund) but worth minimising. Needs a precise key-split spec, and
   ideally the recovery export carries whatever the standalone taker needs to *claim*
   (not just refund). This is the single most important thing to get right.
2. **LEZ destination binding.** Bind the user's LEZ address into the swap parameters
   (analogous to Satora's EIP-712 signed-destination binding) so the aggregator
   cannot redirect the unlocked tokens.
3. **Timelock choice** for the BTC leg vs the LEZ escrow refund deadline — must
   account for block-time variance and give the user's refund a safe margin
   (RFP-003 Reliability #6).
4. **Price-feed integrity** — the aggregator surfaces maker prices; how are stale or
   adversarial quotes handled before the user commits BTC?
5. **BTC funding from a CEX.** Funding the Taproot address from a CEX is fine for the
   *funding* leg, but refund/recovery requires the spend keys — so the UX must make
   clear that claim/refund happen from the embedded (seed-controlled) wallet, not the
   CEX.

## Prior-art contrast

- **[[projects/satora]]** — the UX/refund template: browser wallet from seed,
  user-driven refund, recovery-from-seed. But Satora is **shared-hash HTLC**
  (linkable) and BTC↔EVM-stablecoin. This design instead uses RFP-003's
  **adaptor-signature + Taproot key-path** (unlinkable cooperative spend) against
  **LEZ**.
- **[[projects/eigenwallet]] / [[projects/comit]]** — the adaptor-signature swap
  lineage RFP-003 builds on (xmr-btc-swap). RFP-003 explicitly cites
  comit-network as prior art.

## Sources

- [RFP-003 — Atomic Swaps with LEZ](https://github.com/logos-co/rfp/blob/main/RFPs/RFP-003-atomic-swaps.md) — local: `~/src/logos-co/rfp/RFPs/RFP-003-atomic-swaps.md` — accessed 2026-07-03
- Appendix: Bitcoin and Monero Adaptor-Signature Swap Primitives — `~/src/logos-co/rfp/appendix/btc-xmr-adaptor-swap-primitives.md` (referenced by RFP-003; not yet read for this sketch)
- [[projects/satora]] — refund/recovery UX template (this vault)
