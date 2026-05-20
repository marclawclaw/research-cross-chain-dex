---
tags: [project, lez, logos, positioning]
ecosystem: Logos
category: Privacy-preserving middle chain for cross-chain DEX
status: refined against comparator notes (2026-05-19)
---

# LEZ Positioning as Cross-Chain DEX Middle Layer

This note is the LEZ-side analysis, paired with [[summary]]. The
summary covers the comparator landscape and the necessary
characteristics of a middle chain; this note covers what LEZ should
and should not differentiate on, with citations into the comparator
research.

## Position in one paragraph

LEZ should position itself as a **privacy-preserving middle chain for
cross-chain swaps** in the architectural lineage of
[[projects/thorchain]] and [[projects/serai]], not in the lineage of
[[projects/wormhole]]. The Serai/Thorchain pattern (settlement chain
plus per-validator observers plus TSS vaults plus native AMM, see
[[patterns/middle-chain-swap-settlement]]) is the right starting
point because it offers protocol-owned liquidity, native-asset
settlement without wrapped IOUs, and a single bonded validator set
that is jointly accountable for bridge custody and swap execution.
Wormhole's attestation pattern is the wrong starting point because it
gives up all three. The differentiator LEZ adds on top is anonymity:
shielded swap intents, sealed-bid matching with threshold decryption,
stealth outbound addresses, anonymous deposit attribution, and
Waku-routed orderflow.

## What LEZ already provides

LEZ is a general-purpose execution zone with:

- A bonded validator set with slashing (shared Logos consensus
  security).
- General-purpose programmability sufficient to implement TSS
  observer/signer pipelines, AMM pools, and key-rotation logic as
  LEZ programs.
- Predictable block production and finality.
- Logos-native transport primitives (Waku) for off-chain orderflow.

The eight necessary characteristics enumerated in [[summary]]
(bonded validator set, TSS primitive, per-chain observers, native
execution, churn/rotation, predictable finality, economic-security
ceiling, emergency halt) are all addressable on LEZ without new
consensus-layer work. The interesting design freedom is on top.

## What LEZ should match (do not over-differentiate)

| Axis | Recommended choice | Reason | Citation |
|------|--------------------|--------|----------|
| TSS scheme | FROST per-curve, per external chain | Schnorr threshold signatures have clean proofs; Serai's choice; GG20 has now failed in production on Thorchain | [Serai: To Schnorr or Not to Schnorr](https://serai.exchange/2023/10/08/to-schnorr-or-not-to-schnorr.html); [May 2026 Thorchain incident](https://www.cryptotimes.io/2026/05/17/10-8-million-drained-inside-the-thorchain-exploit-that-froze-cross-chain-defi-for-13-hours/) |
| AMM at launch | Constant-product `xy=k` paired against a single hub asset | Serai chose this for the same reasons (LP fairness, simplicity); concentrated liquidity adds complexity unwarranted at launch | [Serai AMM docs](https://docs.serai.exchange/amm/) |
| Observer architecture | Per-validator daemon per external chain (Bifrost / Processor style) | Both Serai and Thorchain converged on this; chain-agnostic | [Bifrost](https://dev.thorchain.org/bifrost/how-bifrost-works.html); [Serai Processor spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Processor.md) |
| Churn cadence | Per session (Serai), every 3 days (Thorchain). LEZ should pick one and document it | Both ranges are operationally viable | [Multisig Rotation](https://github.com/serai-dex/serai/blob/develop/spec/processor/Multisig%20Rotation.md); [State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) |
| Native-asset settlement (no wrapped IOUs) | Required | Wrapped tokens propagate trust to downstream protocols; both Serai and Thorchain reject this | [[patterns/middle-chain-swap-settlement]] |

## What LEZ should differentiate on (anonymity primitives)

The privacy gap is the same in all three comparators (see [[summary]]
section "What Serai and Thorchain leave on the table" and the
Wormhole privacy section in [[projects/wormhole]]): every cross-chain
swap publishes the source-to-destination link on at least one public
ledger. The candidate primitives, in order of how directly each
addresses a specific comparator gap:

### 1. Shielded swap intents

- **Gap addressed**: Thorchain memos broadcast the destination
  address on the **source chain** before the middle chain even sees
  them ([memos](https://dev.thorchain.org/concepts/memos.html));
  Serai's shorthand expands deterministically into a public Dex
  instruction on the Serai chain
  ([Instructions spec](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Instructions.md)).
- **LEZ primitive**: intents are commitments accompanied by a zk
  proof of well-formedness (correctly funded, within slippage). The
  middle chain matches commitments without learning the cleartext.
- **Requirement**: a zkVM or circuit-friendly execution layer on
  LEZ. Open question; see [[summary]] §"Open positioning questions".

### 2. Sealed-bid batch matching with threshold decryption

- **Gap addressed**: MEV on Thorchain is publicly extractable from
  the inbound memo before settlement; slip-based fees (see
  [[patterns/slip-based-fees]]) and streaming swaps damp it but do
  not prevent it. Serai inherits the same exposure.
- **LEZ primitive**: bids in a matching window are encrypted under
  a key held jointly by the validator set; at window close the
  validator set threshold-decrypts and clears at a uniform price.
- **Reuses the same TSS validator set** that already custodies
  external assets, so no new bonded committee is introduced.

### 3. Stealth addresses for outbound transactions on external chains

- **Gap addressed**: Thorchain and Serai outbounds are public
  payments to long-lived user addresses on the destination chain,
  trivially linkable by chain analysis to the inbound on the source
  chain.
- **LEZ primitive**: when the TSS vault signs an outbound, the
  recipient is a freshly derived stealth address per swap. The vault
  produces a one-time output that only the swap recipient can spend.
- **Feasibility**:
  - Bitcoin: BIP 47 / silent payments
  - Ethereum: ERC-5564 stealth meta-addresses
  - Monero: native
  - Solana, Cosmos: per-chain investigation; some chains lack the
    primitives natively. Initial coverage scope drives engineering
    load.

### 4. Anonymous deposit attribution

- **Gap addressed**: a deposit into the TSS vault on Bitcoin is, by
  default, linkable to the user. Even with stealth withdrawals (3),
  the inbound side leaks identity.
- **LEZ primitive**: a deposit zk proof. The user proves on LEZ that
  they own a deposit in the vault, without revealing which deposit.
  Combined with (3), this breaks the end-to-end on-chain trail that
  Thorchain and Serai leave behind.

### 5. Transport-layer privacy via Waku

- **Gap addressed**: order submission and quote dissemination over
  ordinary p2p gossip leaks submitter network identity. Affects every
  public middle chain.
- **LEZ primitive**: Waku content topics decouple publishers and
  subscribers; traffic is unlinkable at the network layer. Logos
  already invests in Waku, so this is mostly an integration cost
  rather than a research cost.

### 6. Validator-set privacy and fraud-proof exits

- **Gap addressed**: in GG20 (Thorchain) it is visible which
  validators contributed to which signing round; in Wormhole the
  VAA carries 19 individual signatures making participation public
  per message. None of the three comparators offer users an exit
  window with cryptographic recourse against a malicious outbound.
- **LEZ primitives**:
  - FROST already hides participation behind a uniform threshold
    signature, so (a) comes mostly for free if FROST is chosen.
  - (b) is novel: a challenge-response exit window during which a
    fraud proof on LEZ can halt an outbound before it is broadcast.
    None of the comparators have this. This is a place LEZ could
    lead.

## What LEZ should not try to do

- **Do not host wrapped tokens.** The whole point of the middle-chain
  pattern is native-asset settlement. Wrapped tokens reintroduce the
  trust-fragmentation problem that Wormhole demonstrates.
- **Do not aim for ~40 chain integrations at launch.** Each new
  external chain is a per-chain Processor library, a curve-compatible
  FROST integration, observer infrastructure, and a stealth-address
  variant. Serai targets 4 networks (BTC, ETH, DAI, XMR); Thorchain
  reached 11 over 5 years. A privacy-led launch with 3-4 chains
  beats a broad launch with shallow privacy.
- **Do not invent new TSS schemes.** FROST per-curve is the right
  baseline. The May 2026 Thorchain GG20 incident is a clear
  cautionary tale about the cost of running a custom TSS in
  production.

## Bond-to-custody ratio

Both comparators with bonded stake express a quantitative ceiling:

- **Thorchain**: 2:1 bond-to-pooled, plus 1:1 pool-to-foreign-asset,
  so total RUNE locked (bonded + pooled) targets 3x the foreign
  asset value. The Incentive Pendulum dynamically shifts rewards to
  preserve the ratio. ([Incentive Pendulum](https://medium.com/thorchain/the-incentive-pendulum-848f3c3e4d1d), accessed 2026-05-19)
- **Serai**: hard cap at 33% of allocated stake. Above the cap the
  protocol must reject new deposits. ([Validator Sets spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md), accessed 2026-05-19)

LEZ should choose one mechanism (static cap or dynamic incentive)
and document it in the RFP. The Serai static cap is conceptually
cleaner; the Thorchain dynamic mechanism is more battle-tested.

## Pre-economic-security era

Both comparators face a chicken-and-egg problem: validator stake must
exist before the protocol can secure custody, but stake derives value
from the protocol operating. Serai's spec acknowledges this with a
distinct pre-economic-security era during which theft is unrecoverable;
the docs.serai.exchange pre/post pages are empty stubs as of
2026-05-19 ([[patterns/serai-trust-model]]).

LEZ should either (a) bootstrap from existing Logos validator stake
(avoiding the era entirely), or (b) document the era with
quantitative bounds and risk disclosure. Skipping it silently is the
worst option.

## Emergency halt authority

- **Thorchain**: any node can call `make halt` once per 3-day churn
  cycle; 67% solvency-disagreement auto-halts trading per chain.
  ([Security docs](https://docs.thorchain.org/technical-documentation/technical-deep-dive/security.md))
- **Serai**: session-level rollback on DKG failure; broader halt
  authority `[NOT FOUND]` in current specs.
- **Wormhole**: governance VAA can temporarily disable functions;
  authority lies with the same Guardian set that secures normal
  operations. ([Security docs](https://wormhole.com/docs/protocol/security/))

LEZ should specify: who can halt, on what evidence, for how long,
and how the halt itself is secured against false-flag activation.

## Open positioning questions for the RFP

Forwarded to [[summary]] §"Open positioning questions for the RFP".

## Sources

Comparator citations are inline above; full sources are on the
respective project notes:

- [[projects/serai]] sources
- [[projects/thorchain]] sources
- [[projects/wormhole]] sources

LEZ-specific claims need citation against Logos docs in the next
revision (zkVM availability, Waku integration scope, validator-set
parameters). For prior LEZ analysis, see `appendix/potential-architectures.md`
and `appendix/lez-vs-dedicated-zone.md` in the rfp repo.
