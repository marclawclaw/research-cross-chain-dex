---
tags: [project, atomic-swaps, htlc, adaptor-signatures, contrast-point, unmaintained]
ecosystem: Bitcoin, Ethereum, Monero (cross-chain primitive, no own chain)
category: HTLC and adaptor-signature atomic swaps
website: https://comit.network/
docs: https://github.com/comit-network/RFCs
launched: First public release 2019; reference implementation (comit-rs) archived 2021-03; xmr-btc-swap declared unmaintained 2024
---

# COMIT Network

COMIT (Collaborative Multi-chain Transactions) is a Rust-based reference implementation of HTLC and adaptor-signature atomic swaps between Bitcoin, Ethereum, ERC20, and Monero. It is included in this vault as a **contrast point** to the middle-chain DEX pattern (see [[patterns/atomic-swaps-vs-middle-chain]]): COMIT is the canonical "no middle chain, no validator set, no protocol-owned liquidity" design. Its design corpus (`comit-network/RFCs` and `comit-network/spikes`) is interesting precisely for what it does not contain.

## Why this note exists

A core question for the LEZ positioning work is whether atomic-swap projects ever introduced a staking or reputation layer to compensate for the lack of bonded validators. COMIT is the most thoroughly documented atomic-swap project (Rust reference implementation, full RFC series, 25+ ADR-style spike documents, public blog). A complete audit of its public design corpus (2026-05-20) found:

- **No mention of staking** in any RFC, spike, source file, or blog post across the comit-network organisation.
- **No mention of reputation systems**; the word "reputation" appears once in spike `0024-more-protocol-naming.adoc` as a tongue-in-cheek aside about token quality, not as a protocol mechanism.
- **No mention of maker bonds, slashing, griefing prevention, or any counterparty accountability layer.**
- The only "collateral" hits in the org are in unrelated DeFi products (`baru` Liquid loans, `waves` borrowing UI, `maia`/`itchysats` CFDs); none are accountability mechanisms for swap counterparties.

This is itself architecturally significant: COMIT relied entirely on timelock refund paths and adaptor-signature secrecy for safety, with no on-chain economic layer to penalise non-cooperation. This is the structural reason it cannot offer the AMM-style "one-shot deposit, no counterparty handshake" UX that Serai and Thorchain offer (see [[patterns/atomic-swaps-vs-middle-chain]]).

## Project status (2026-05-20)

| Repo                                | Role                              | Status    | Last push    | Stars |
|-------------------------------------|-----------------------------------|-----------|--------------|-------|
| `comit-network/comit-rs`            | Reference implementation (cnd + nectar) | Archived  | 2021-03-23   | 190   |
| `comit-network/RFCs`                | Protocol specifications (RFC-000 to RFC-011) | Archived  | 2020-05-08   | 9     |
| `comit-network/spikes`              | MADR-flavoured ADR collection (0000 to 0027) | Not archived (idle) | 2020-08-24 | 3     |
| `comit-network/xmr-btc-swap`        | BTC-XMR adaptor-signature implementation | Unmaintained (per repo notice) | last release 2024-11-15 (v1.0.0-rc.1) | (high, exact count not fetched) |
| `comit-network/nectar` (subdir of comit-rs) | Custodial maker daemon            | Archived with comit-rs | 2021-03-23 | n/a   |

The original COMIT team has moved to other projects; xmr-btc-swap maintenance has shifted to community-led `eigenwallet/core`, which the upstream notice flags has "introduced breaking changes at the network level" ([github.com/comit-network/xmr-btc-swap](https://github.com/comit-network/xmr-btc-swap) :: accessed 2026-05-19, already cited in [[patterns/atomic-swaps-vs-middle-chain]]). See [[projects/eigenwallet]] for the active fork's current status, fork lineage, network-level breaking changes (v2.0.0 collaborative `tx_refund_early` co-signing, v4.0.0 cancel-timelock reduction), and adoption metrics (>3,000 mainnet swaps via the GUI in 2023, 2 live mainnet makers on 2026-05-22).

## RFC series (specifications)

The `comit-network/RFCs` repo defines the on-the-wire protocol. Topics covered:

| RFC | Title (abbreviated)                        | Theme                       |
|-----|--------------------------------------------|-----------------------------|
| 000 | Process description                        | Meta                        |
| 001 | libp2p                                     | Transport                   |
| 002 | SWAP (protocol)                            | Negotiation framing         |
| 003 | SWAP-Basic                                 | Baseline HTLC swap          |
| 004 | Bitcoin                                    | Ledger integration          |
| 005 | SWAP-Basic-Bitcoin                         | Bitcoin-leg HTLC            |
| 006 | Ethereum                                   | Ledger integration          |
| 007 | SWAP-Basic-Ether                           | Ether-leg HTLC              |
| 008 | ERC20                                      | Asset integration           |
| 009 | SWAP-Basic-ERC20                           | ERC20-leg HTLC              |
| 010 | Omni-Layer                                 | Ledger integration          |
| 011 | SWAP-Omni-Layer-basic                      | Omni-leg HTLC               |

Source: [comit-network/RFCs contents listing](https://github.com/comit-network/RFCs) :: accessed 2026-05-20. None of these RFCs introduce a staking, bond, or reputation primitive; they are protocol-level message and script specifications for HTLC swaps.

## Spikes (ADR-equivalent design decisions)

`comit-network/spikes` describes itself as "MADR-like solution for spike outcomes" ([spikes/0000-use-madr-like-solution-for-spike-outcomes.md](https://github.com/comit-network/spikes/blob/master/0000-use-madr-like-solution-for-spike-outcomes.md) :: accessed 2026-05-20). The 25 substantive entries (0001 to 0027, with gaps) cover:

- **Expiry and timelock design**: `0001-basic-expiry-model.adoc`, `0010-timestamps.adoc`, `0015-ethereum-htlc-graceful-exit.adoc`, `0027-standardizing-comit-expiry-times.adoc`.
- **Cryptography**: `0005-kzen-two-party-ecdsa.adoc`, `0006-scriptless-scripts-with-ecdsa.adoc`.
- **Ledger and asset integration**: `0002-ether-htlc-dynamic-final-addresses.md`, `0003-lightning-as-alpha-ledger.adoc`, `0022-lnd-plan-of-attack.adoc`.
- **Network and transport**: `0008-onion-routing-over-libp2p.adoc`, `0023-communication-protocol.adoc`.
- **Storage and persistence**: `0007-secret-seed-storage-and-key-derivation.md`, `0009-comit-btsieve-db.adoc`, `0014-resume-swaps-after-restart.adoc`, `0025-an-extensible-db-design.adoc`.
- **API, tooling, operations**: `0004-siren-prototype-accept-decline.adoc`, `0011-revise-e2e-test-framework.adoc`, `0012-release-strategy.adoc`, `0013-secure-http-api.adoc`, `0016-how-to-document-cnd-http-api.adoc`, `0018-async-stack.adoc`, `0019-domain-model.adoc`, `0020-logging.adoc`.
- **Protocol naming and negotiation**: `0017-negotiation-and-execution-protocol.adoc`, `0021-protocol-naming.adoc`, `0024-more-protocol-naming.adoc`.

**None of the spikes addresses staking, reputation, slashing, maker bonds, griefing prevention, or any counterparty accountability mechanism.** The closest topic is `0017-negotiation-and-execution-protocol.adoc`, which separates the negotiation and execution phases of a swap; verified that this spike does not discuss trust or accountability ([comit-network/spikes/0017](https://github.com/comit-network/spikes/blob/master/0017-negotiation-and-execution-protocol.adoc) :: accessed 2026-05-20). The economic model is implicit: timelock refunds and adaptor-signature secrecy substitute for any on-chain bond.

## Trust and economics model (by inference)

Reconstructed from the source artefacts since no document states it explicitly:

- **Counterparty risk handled by timelocks, not bonds.** A non-cooperative or offline counterparty causes a swap to time out and refund, not to be penalised. Maximum cost of misbehaviour is the gas and time spent locking in, not loss of bond.
- **No protocol-owned liquidity.** Each swap requires a willing peer. The `nectar` daemon ([comit-rs/nectar README](https://github.com/comit-network/comit-rs/blob/dev/nectar/README.md) :: accessed 2026-05-20) is a custodial market-maker tool a user runs locally; it has no on-chain identity, no bond, no public reputation.
- **No mempool privacy or shielding.** HTLC and adaptor-signature swaps reveal swap structure on-chain (with the adaptor-signature variant minimising the linkability of preimages).
- **Fees are local market-making margins, not protocol fees.** Nothing equivalent to Thorchain's `RUNE`-bonded validators receiving slip fees (see [[patterns/slip-based-fees]]) exists in COMIT.

## Differentiators vs middle-chain DEXes

- **vs [[projects/serai]]**: COMIT publishes BTC-XMR adaptor-signature code; Serai publishes BTC-XMR threshold-custody code (FROSTLASS CLSAGs). Both projects target the same asset pair, but Serai chose a 600-validator bonded set with slashing as its safety mechanism, while COMIT chose pure timelock-and-secrecy. The Serai team explicitly groups itself with Thorchain, Maya, Chainflip rather than with COMIT or Farcaster ([Monero Observer interview](https://monero.observer/monerotalk-kayabanerve-interview-serai-dex/) :: accessed 2026-05-19, already cited in [[patterns/atomic-swaps-vs-middle-chain]]).
- **vs [[projects/thorchain]]**: Thorchain's "Why Cross-Chain bridges are superior to Atomic Swaps" (2019-07-02) was written against the COMIT-style model directly. The crux of Thorchain's argument is that bond-slashing plus a global ordered AMM ([[patterns/slip-based-fees]]) gives liquidity and UX properties HTLC cannot.
- **vs [[projects/wormhole]]**: category mismatch. Wormhole is a generic attestation bridge; COMIT is a swap primitive. Neither uses a bond on the swap counterparty.

## Limitations and criticisms

- **No on-chain accountability mechanism.** As documented above, the absence of staking or reputation in COMIT's design corpus is by design: HTLC and adaptor-signature swaps are constructed to be safe without trusting the counterparty, by refunding on timeout. The practical cost is the UX and liquidity constraints listed in [[patterns/atomic-swaps-vs-middle-chain]].
- **Unmaintained.** The reference implementation has been archived for over five years; xmr-btc-swap, the only sub-project that achieved active production use, was officially declared unmaintained in 2024 and redirected to the community fork eigenwallet.
- **Narrow asset coverage.** RFC series covers Bitcoin, Ethereum, ERC20, Omni Layer; XMR was added via a separate repo (xmr-btc-swap) using scriptless-script primitives that took roughly five years from first published research to working community implementation.
- **No protocol fees, no token economy.** COMIT never proposed a native token, validator set, or fee distribution layer. Maker income relies on local spread.

## Implication for LEZ positioning

COMIT establishes a useful negative result: the most engineering-thorough atomic-swap project of the 2018-2024 period chose **not** to introduce any staking or reputation primitive, even after several years and 25+ ADRs of design iteration. This corroborates the [[patterns/atomic-swaps-vs-middle-chain]] thesis that introducing such a layer is structurally incompatible with the pure-atomic-swap model: once you bond counterparties, you have built a small middle chain. A privacy-focused middle chain (the LEZ direction) is therefore the natural setting in which staking, slashing, and reputation become available primitives, and COMIT's history is evidence that this trade-off has been actively avoided by adjacent projects rather than overlooked.

## Sources

- [comit-network/comit-rs (archived)](https://github.com/comit-network/comit-rs) :: accessed 2026-05-20
- [comit-network/RFCs (archived)](https://github.com/comit-network/RFCs) :: accessed 2026-05-20
- [comit-network/spikes (idle, public)](https://github.com/comit-network/spikes) :: accessed 2026-05-20
- [comit-network/spikes/README.md (MADR-like format declaration)](https://github.com/comit-network/spikes/blob/master/0000-use-madr-like-solution-for-spike-outcomes.md) :: accessed 2026-05-20
- [comit-network/spikes/0017-negotiation-and-execution-protocol.adoc](https://github.com/comit-network/spikes/blob/master/0017-negotiation-and-execution-protocol.adoc) :: accessed 2026-05-20
- [comit-network/spikes/0024-more-protocol-naming.adoc](https://github.com/comit-network/spikes/blob/master/0024-more-protocol-naming.adoc) :: accessed 2026-05-20
- [comit-network/RFCs/registry.md](https://github.com/comit-network/RFCs/blob/master/registry.md) :: accessed 2026-05-20
- [comit-network/comit-rs/nectar README](https://github.com/comit-network/comit-rs/blob/dev/nectar/README.md) :: accessed 2026-05-20
- [comit-network/xmr-btc-swap (unmaintained notice)](https://github.com/comit-network/xmr-btc-swap) :: accessed 2026-05-19 (via [[patterns/atomic-swaps-vs-middle-chain]])
- [comit.network blog index (post listing via GitHub source)](https://github.com/comit-network/comit.network/tree/master/blog) :: accessed 2026-05-20
- Verification queries (no results): `gh search code --owner comit-network "staking"`, `"reputation"` (one tongue-in-cheek hit in spike 0024), `"griefing"`, `"incentive"`, `"maker bond"` :: run 2026-05-20
