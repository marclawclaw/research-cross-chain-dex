---
tags: [pattern, cross-chain-dex, custody, architecture, off-chain]
status: established
---

# Pattern: Instant-swap aggregator

A single corporate operator runs a routing / quoting service that fronts an interface across multiple liquidity sources (DEX aggregators, cross-chain bridges, CEX order books, and often in-house market-making inventory). The user picks an asset pair and a destination wallet, sends the source asset to a one-shot **transit address** controlled by the operator, and the operator delivers the destination asset from its own withdrawing address. There is no shared validator set, no bonded stake, no on-chain proof of reserves; the operator is a single point of trust for the cross-chain leg.

This is the dominant *deployed* cross-chain swap pattern by retail user count (Baltex, ChangeNOW, SideShift, FixedFloat, Stealthex, Trocador, eXch.cx, Godex, SimpleSwap) despite being architecturally the weakest. It does not appear in most academic taxonomies of cross-chain DEXes because it is not a protocol, but a productised CeFi service.

## Core components

1. **Routing engine**: off-chain service that, given a `(src_asset, dst_asset, amount)` tuple, scouts upstream venues (DEX aggregators, bridges, CEX books) and produces a quote. Often blends quotes with in-house inventory.
2. **Quote modes**: typically two — **fixed rate** (lock the quote at request time, higher fee, operator absorbs price risk) and **floating rate** (execute at fill, lower fee, user absorbs price risk).
3. **Transit address**: a one-shot deposit address generated per swap on the source chain. Custody window is open from inbound confirmation until destination payout.
4. **AML / sanctions screening**: incoming funds are screened against sanctions lists, darknet markets, mixers, stolen-funds clusters, and high-risk addresses. Operator may freeze a swap and trigger KYC / EDD at discretion.
5. **Withdrawing address**: the operator's hot wallet on the destination chain. Inventory replenishment is opaque to the user.
6. **Optional privacy hop**: see "Monero rail" variant below.

## Reference flow (Baltex)

1. User picks src/dst assets and destination wallet at the front-end. Two rate types offered: fixed or floating ([Baltex how-it-works](https://baltex.io/support/how-it-works), accessed 2026-05-20).
2. Baltex generates a transit deposit address on the source chain.
3. User funds the transit address. Inbound is screened by AML / sanctions logic ([Baltex AML page](https://baltex.io/aml), accessed 2026-05-20).
4. If clean: routing engine executes the path — some combination of DEX aggregator calls, cross-chain bridges, CEX order books, and Baltex's own in-house market-making inventory ([Baltex blog: best tools for cross-chain swaps](https://baltex.io/blog/ecosystem/best-tools-for-cross-chain-swaps), accessed 2026-05-20).
5. Destination asset is sent from Baltex's withdrawing address to the user wallet, typically 10–45 minutes after inbound depending on route and confirmations.
6. If flagged: funds may be frozen pending KYC / Enhanced Due Diligence; refundable (minus network fees) on non-completion ([Baltex Risk Disclosure](https://baltex.io/legal/risk-disclosure), accessed 2026-05-20).

## Monero-rail privacy variant

A subset of aggregators (Baltex Private Swaps, Trocador, some SideShift routes) insert a Monero hop into the route: `src -> intermediate -> XMR -> intermediate -> dst`. Stealth addresses, ring signatures, and RingCT break **external observer linkability** between the inbound and outbound legs on the public chains.

Important: this does **not** break **operator linkability**. The operator, by construction, knows both endpoints because it is the entity executing the conversion. Privacy depends entirely on the operator's data-retention policy and resistance to subpoena.

This is the only widely-deployed cross-chain-swap privacy pattern that does not require zk-shielded execution. It sits well below the LEZ ideal (zk-shielded execution where even the middle chain cannot link) but well above transparent middle-chain DEXes ([[middle-chain-swap-settlement]]) where the entire swap is publicly traceable.

## Trust model

- **Operator solvency**: the operator holds user funds during the cross-chain hop, with no proof of reserves, no bond, no third-party slashing. If the operator absconds, users have only civil recourse in the operator's jurisdiction.
- **Operator honesty**: matching, routing, inventory, and pricing decisions are off-chain and opaque. No cryptographic accountability comparable to Thorchain's TSS signing transcript or Serai's published In Instructions.
- **Sanctions discretion**: the operator can freeze any inbound at AML discretion. No protocol-enforced settlement guarantee.
- **Privacy** (when offered): the operator sees the linkage between deposit address and payout address even when external chain analysis cannot.

This is materially weaker than [[signer-federation-trust]] (which at least requires N-of-M collusion among independent firms) — a single-operator instant-swap aggregator is closer to a centralised exchange that happens to have no account system.

## Why this pattern wins in practice

Despite the weak trust model, this pattern dominates the deployed cross-chain swap market because:

- **No protocol risk**: no consensus to bootstrap, no validator economics to tune, no TSS implementation to harden. The operator just glues existing venues together.
- **Chain coverage is rented**: by aggregating upstream, the operator inherits whatever chains its providers support. Baltex's "10,000+ tokens / 200+ networks" claim is the aggregated count across upstream providers, not native integrations.
- **Time-to-market**: the entire pattern can be a small team plus AML vendor plus inventory. Baltex went from founding (2025) to a cross-chain private-swap launch (2025-11-24) in under a year ([DLNews coverage](https://www.dlnews.com/external/baltex-launches-fully-cross-chain-private-swaps/), accessed 2026-05-20).
- **No KYC by default**: most operators only invoke KYC when AML risk scoring trips, which is acceptable to a large segment of users.
- **Privacy is productisable**: adding a Monero hop is a routing-engine change, not a protocol redesign.

## Constraints / failure modes

- **Single point of failure**: operator exit-scam, insolvency, or seizure of withdrawing-address hot wallets ends the service.
- **Sanctions exposure**: KYC discretion means the operator can refuse settlement after funds are received; the user has no recourse other than refund-after-screening.
- **No verifiable solvency**: users cannot audit whether the operator is running fractional reserves.
- **Privacy is operator-trusted**: the Monero hop hides the linkage from chain analysis but not from the operator or anyone with subpoena power over the operator.
- **Liquidity dependence**: an upstream provider outage degrades coverage. The aggregator is only as live as its venues.
- **Regulatory drift**: increasing pressure on non-KYC swap services (FATF travel rule, EU MiCA, US Treasury sanctions) creates ongoing existential risk for the category.

## Used by

- [[../projects/baltex]] (single-operator aggregator with Monero-rail privacy variant)
- Not yet researched but fit the pattern: ChangeNOW, SideShift AI, FixedFloat, Stealthex, Trocador, eXch.cx, Godex, SimpleSwap.

## Contrast with

- [[middle-chain-swap-settlement]]: protocol-owned vaults, bonded validator set, on-chain settlement guarantees, fully public swaps. Slower to ship, much stronger trust model.
- [[attestation-bridge]]: signed messages emitted by a guardian set; no swap matching or pool custody, but no aggregated quoting either.
- [[atomic-swaps-vs-middle-chain]]: HTLCs require no operator custody at all, but suffer from liquidity / coordination problems that aggregators sidestep by paying for inventory.
- [[signer-federation-trust]]: N-of-M independent firms attesting jointly. Instant-swap aggregators are 1-of-1 — the weakest end of the federation spectrum.

## See also

- [[lock-mint-bridging]]
- [[signer-federation-trust]]
