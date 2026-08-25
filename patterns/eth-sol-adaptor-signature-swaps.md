---
tags: [pattern, atomic-swaps, adaptor-signatures, eth-sol, cross-curve-dleq, privacy, research-frontier]
status: RESEARCH SURVEY — no working construction found; cryptographic building blocks exist but unassembled
verified_by: deep-research run on 2026-08-25
sources_archived: none yet (web sources only; see per-claim URLs below)
---

# ETH↔SOL adaptor-signature swaps: is Taproot-style unlinkability reachable?

**Question**: for an atomic swap between Ethereum and Solana, is there a mechanism analogous to Bitcoin Taproot + adaptor signatures that prevents on-chain linkability between the two legs — i.e. avoids the classic HTLC problem where the same hash preimage appears in both chains' transactions, making the two legs trivially correlatable?

**Short answer**: the cryptographic bridge needed (secp256k1↔Ed25519 cross-curve DLEQ) already exists and is directly reusable — because Monero and Solana both use Ed25519, the same curve pair bridged for BTC-XMR swaps applies to ETH-SOL with zero new curve theory. But **nobody has built an ETH↔SOL adaptor-signature swap**. The closest prior art (AthanorLabs ETH-XMR) uses that same DLEQ machinery for a *different, more linkable* purpose (gas-efficient scalar-reveal verification, not signature-level unlinkability). And even if built, cryptographic unlinkability alone would not fully solve cross-chain correlation — timing/amount/network-level analysis is a separately documented residual risk.

## 1. Signature schemes: the curve mismatch

- **Ethereum**: ECDSA/secp256k1 at the base layer, confirmed unchanged by EIP-7702 (Pectra, activated 2025-05-07). Per [QuickNode's EIP-7702 explainer](https://blog.quicknode.com/eip-7702-explained-the-future-of-ethereum/) (accessed 2026-08-25): *"transactions are still signed with the original secp256k1 key; the global nonce rules and ETH-denominated gas costs remain unchanged; and the protocol itself knows nothing about sub-keys, paymasters, or account abstraction."* EIP-7702 adds delegated sub-key flexibility (e.g. secp256r1 passkeys) but the base EOA scheme is unchanged.
- **Solana**: EdDSA/Ed25519. Solana docs on [precompiled programs](https://solana.com/docs/core/programs/precompiles) confirm the Ed25519 precompile "bypass[es] the sBPF VM and run[s] as native code within the validator." Per [RareSkills' Ed25519 verification writeup](https://rareskills.io/post/solana-signature-verification) (accessed 2026-08-25): the Ed25519Program verifies **arbitrary** (message, pubkey, signature) triples supplied as instruction data via instruction introspection — not just native tx signers. A Secp256k1 native program / `secp256k1_recover` syscall also exists, explicitly for Ethereum interop ([docs.rs `solana-secp256k1-program`](https://docs.rs/solana-secp256k1-program/latest/solana_secp256k1_program/)).

Neither verifier special-cases "was this signature produced normally or via an adaptor-signature adapt operation" — a syntactically valid signature verifies regardless of how it was constructed. This is structurally the same property that makes Taproot key-path spends indistinguishable from script-path spends.

This is the same curve pair as **secp256k1 (Bitcoin) ↔ Ed25519 (Monero)** — see [[projects/atomic-swap-protocol-details]].

## 2. Adaptor signatures per curve

- **secp256k1 ECDSA adaptor signatures**: mature, deployed — ECDSA one-time VES (Fournier 2019), used in Lightning submarine swaps and for the BTC leg of BTC-XMR swaps (see [[projects/atomic-swap-protocol-details]]). Directly applicable to Ethereum's signing curve. **Open question**: whether an adaptor-completed ECDSA signature can substitute as a raw Ethereum EOA tx signature (subject to `ecrecover`-compatible low-S rules), versus only being usable as an off-chain value a smart contract checks. No source found confirming either way.
- **Ed25519/EdDSA adaptor signatures**: cryptographically sketched, not confirmed production-ready. **Zhu, Li, Li, Yu (2025)**, *"Adaptor signature based on randomized EdDSA in blockchain,"* Digital Communications and Networks 11(3), published online 2025-07-21. [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S2352864824000713) (paywalled) / [mirror abstract](https://journal.hep.com.cn/dcn/EN/1160605780397319066) (accessed 2026-08-25): proposes a construction using **randomized** EdDSA (rEdDSA), proving unforgeability, witness extractability, and pre-signature adaptability in the ROM. **Unresolved (full text inaccessible)**: whether the construction requires *randomized* nonces specifically (i.e. is incompatible with the deterministic-nonce RFC 8032 EdDSA that Solana's stock verifier expects) or whether the adapted signature verifies under an unmodified standard Ed25519 verifier. This is the single most load-bearing open question for Solana compatibility.
- **No audited, production-deployed Ed25519 adaptor-signature library was found.** This is a genuine maturity gap relative to the secp256k1 side (which has Lightning + BTC-XMR production precedent).

## 3. The cross-curve bridge already exists — reuse from BTC-XMR

**Key finding**: Monero uses Ed25519. Solana uses Ed25519. Bitcoin and Ethereum both use secp256k1. The cross-curve DLEQ proof built for BTC-XMR bridges the *identical* curve pair needed for ETH-SOL:

- [`AthanorLabs/go-dleq`](https://github.com/athanorlabs/go-dleq) (accessed 2026-08-25): implements cross-group DLEQ per [MRL-0010](https://www.getmonero.org/resources/research-lab/pubs/MRL-0010.pdf) (Monero Research Lab). *"Currently, secp256k1 and ed25519 are supported"*; *"other curves can be added."* This is the library AthanorLabs' ETH-XMR swap actually uses. No audit-status statement in the README.
- [`comit-network/cross-curve-dleq`](https://github.com/comit-network/cross-curve-dleq): *"Proof of concept implementation of a cross-group DLEQ proof for secp256k1 and ed25519."* Archived, superseded by `secp256kfun`'s implementation.
- [`LLFourn/secp256kfun`, `dl_secp256k1_ed25519_eq.rs`](https://github.com/LLFourn/secp256kfun/blob/master/sigma_fun/src/ext/dl_secp256k1_ed25519_eq.rs): independent Rust implementation of the same proof — two sets of 252 Pedersen commitments proving corresponding bit-commitments encrypt identical values across both curves. Test coverage: property-based + serialization round-trip only; no audit-readiness statement.

**Implication**: the DLEQ layer for an ETH↔SOL bridge requires no new cryptographic research — only repurposing existing, already-implemented code toward a new chain pair.

## 4. But: existing DLEQ reuse solves gas cost, not privacy — a correction

AthanorLabs' ETH-XMR construction ([protocol docs](https://github.com/AthanorLabs/atomic-swap/blob/master/docs/protocol.md)) is **not** an adaptor-signature scheme and is **not** Taproot-equivalent unlinkable:

- The Ethereum contract does not verify a signature reveal. It verifies a **raw scalar reveal**: *"if Alice or Bob reveals their secret by calling the contract, the contract will verify that the secret corresponds to the expected public key that it was initialized with."* Bob calls `Claim(s_b)` with the raw Ed25519 scalar passed directly as calldata — plainly visible on Ethereum's public ledger.
- The [Monero CCS proposal](https://ccs.getmonero.org/proposals/noot-eth-xmr-atomic-swap.html) for adding DLEQ was explicitly a **gas-efficiency** optimization (*"massive gas savings (~30x improvement on Claim/Refund calls)"* by verifying secp256k1 keys on-chain instead of ed25519), not a privacy measure. No mention of adaptor signatures.

**A raw revealed scalar in ETH calldata is arguably more trivially correlatable than a plain HTLC hash preimage** — no hash computation is even needed to attempt a match; the scalar (or a value derived from it) may be directly comparable to the XMR-side key-share component. Using cross-curve DLEQ cryptography and achieving Taproot-style unlinkability are orthogonal; conflating them is a mistake this research pass explicitly corrects.

**No ETH↔SOL implementation of any kind was found** — prototype, audited, or otherwise. Adjacent projects found were all BTC↔SOL, not ETH↔SOL: [`shriyashsoni/btc-sol-atomic-swap`](https://github.com/shriyashsoni/btc-sol-atomic-swap) (ICP threshold-signature-based) and [`adambor/SolLightning-readme`](https://github.com/adambor/SolLightning-readme) (Lightning-submarine-swap-style, relayer/watchtower-dependent).

## 5. Existing ETH↔SOL bridges are TSS/MPC custody vaults, not atomic swaps

Every production ETH↔SOL path found is federated/TSS custody, structurally unrelated to peer-to-peer adaptor-signature swaps:

- **Wormhole**: *"a cross-chain message delivery service that depends on a set of validator nodes to attest to the validity of messages delivered"* ([Solana News](https://solana.com/news/wormhole---solana-ethereum-bridge)). See [[patterns/wormhole-trust-model]].
- **Bifrost (via Wormhole NTT)**: *"built on Threshold Signature Schemes (TSS)"* ([Wormhole case study](https://wormhole.com/case-studies/bitfrost)).
- General bridge-security pattern: *"most bridge designs use ECDSA TSS for Ethereum compatibility or Ed25519 TSS for Solana and Cosmos-based chains"* ([ChainScore TSS guide](https://chainscorelabs.com/guides/privacy-enhancing-technologies-and-anonymity/secure-multi-party-computation-mpc/launching-a-threshold-signature-scheme-for-blockchain-bridge-security)).
- **THORChain**: federated multisig/TSS vaults, node operators bonding 2x value in RUNE; swaps SOL as of Feb 2026. A 2026-05 exploit (["vault churn address poisoning"](https://secureshift.io/blog/thorchain-exploit-analysis)) illustrates the distinct risk profile of the vault-custody approach vs. atomic swaps — included for context, not a linkability finding. See [[patterns/thorchain-trust-model]].

## 6. Solving the shared-artifact problem doesn't solve linkability fully

Even a hypothetical, fully-realized ETH↔SOL adaptor-signature scheme (no shared cryptographic artifact on either chain) leaves residual correlation risk, per Lightning submarine-swap literature — the closest studied analogue:

- Romiti, Victor, Moreno-Sanchez, Nordholt, Haslhofer, Maffei, *Cross-Layer Deanonymization Methods in the Lightning Protocol*, [arXiv:2007.00764](https://arxiv.org/pdf/2007.00764): linking heuristics *"link 45.97% of all LN nodes to 29.61% BTC addresses interacting with the LN."*
- *Timing Attacks on Privacy in Payment Channel Networks*, [arXiv:2006.12143](https://arxiv.org/pdf/2006.12143): local-adversary timing side-channels can subvert sender/receiver anonymity independent of on-chain content.
- Biryukov & Tikhomirov, [*Deanonymization and Linkability of Cryptocurrency Transactions Based on Network Analysis*](https://s-tikhomirov.github.io/assets/papers/deanonymization-and-linkability.pdf): *"timings of transaction messages leak information about their origin,"* exploitable via mempool/gossip-layer propagation analysis before on-chain settlement.

**Verdict**: removing the shared cryptographic artifact (via adaptor sigs) is necessary but not sufficient. A design claiming Taproot-equivalent unlinkability needs explicit additional mitigations — delay randomization, amount splitting/batching, decorrelated mempool submission — the same requirements real-world Taproot-swap privacy analysis already imposes on the Bitcoin side alone.

## 7. Nearest related academic work

- **Shlomovits & Leiba, *JugglingSwap: Scriptless Atomic Cross-Chain Swaps*, [arXiv:2007.14423](https://arxiv.org/pdf/2007.14423)** (2020, KZen Research). States the obstacle precisely (p.2, §1.1): standard scriptless-script/adaptor-signature techniques are *"limited to blockchains which support either Schnorr or ECDSA signatures that share the same elliptic curve parameters, namely - the same group generated from the same fixed generator."* JugglingSwap sidesteps this with a curve-agnostic "gradual secret release" (segmented verifiable ElGamal encryption of an EC-DLog witness) requiring only a threshold-signature variant and ECDLP hardness — but trades full atomicity for **partial fairness** (*"maximal advantage is to be one segment ahead"*, p.4) and introduces a semi-trusted "provider" (optionally a TEE) per chain pair. Not designed around cross-chain-observer unlinkability specifically.
- **"Enabling High-Frequency Trading with Near-Instant, Trustless Cross-Chain Transactions via Pre-Signing Adaptor Signatures," [arXiv:2503.12719](https://arxiv.org/html/2503.12719v1)** (2025): targets Bitcoin↔Ethereum, both secp256k1 — **not applicable**, same-curve throughout, sidesteps the cross-curve problem entirely.
- **Unread but promising by title**: ["Almost Scriptless Adaptor Signatures from any Signature Scheme," eprint 2026/1346](https://eprint.iacr.org/2026/1346) — generic-signature-scheme framing could plausibly bridge ECDSA/EdDSA; not yet fetched or verified. Flag for follow-up.
- Low-confidence, not deeply verified: ["Hybrid Stabilization Protocol for Cross-Chain Digital Assets Using Adaptor Signatures and AI-Driven Arbitrage," arXiv:2506.05708](https://arxiv.org/html/2506.05708) — claims an ETH/SOL/BTC-compatible adaptor-signature liquidity framework; framing reads speculative, full text not verified.

## Consolidated verdict

| Sub-question | Finding | Confidence |
|---|---|---|
| Cryptographically feasible? | Plausible, not demonstrated. secp256k1 side mature; Ed25519 side has one 2025 paper (rEdDSA) with unconfirmed standard-verifier compatibility. | Medium |
| Cross-curve bridge exists? | **Yes** — directly reusable from BTC-XMR (`go-dleq`, `cross-curve-dleq`, `secp256kfun`); same curve pair since Monero and Solana share Ed25519. | High |
| Has anyone built it? | No. AthanorLabs ETH-XMR is the closest prior art but uses a more-linkable raw-scalar-reveal mechanism, not adaptor signatures. Zero ETH↔SOL implementations found. | High |
| Specific blockers | (1) rEdDSA-adaptor-sig-to-standard-verifier compatibility unconfirmed; (2) no audited Ed25519 adaptor-sig library; (3) ECDSA-adaptor-sig-as-raw-Ethereum-tx-signature substitutability unconfirmed; (4) no prior art combining the DLEQ layer with an actual signature-level reveal on both legs for any EVM↔Solana pair. | Medium-High |
| Does solving crypto fully solve unlinkability? | No — timing/network/amount correlation is a separately documented residual risk requiring independent mitigation. | High |

## Relevance to Logos / LEZ

If LEZ or a Logos-adjacent design wants a genuinely unlinkable ETH↔SOL (or more generally EVM↔Solana) swap primitive, the honest framing is: **the hard cryptographic prerequisite (cross-curve DLEQ) is solved and open-source; the adaptor-signature layer on the Ed25519 side is not**. This is a research/engineering gap, not a fundamental impossibility — closer in shape to "needs someone to do the Ed25519-adaptor-signature engineering + audit + on-chain-verifier integration work" than "needs new cryptography to be invented." Until that lands, any ETH↔SOL swap claiming privacy properties should be scoped honestly as HTLC/scalar-reveal-linkable (like AthanorLabs today) unless paired with off-chain mitigations (§6) — do not market it as Taproot-equivalent.

## What to verify before relying on this note

1. Full text of Zhu et al. 2025 (rEdDSA adaptor signatures) — resolve the deterministic-vs-randomized nonce compatibility question with Solana's stock Ed25519 verifier.
2. Whether an adaptor-completed ECDSA signature can substitute as a raw Ethereum EOA tx signature under `ecrecover`/low-S rules, or only as an off-chain value a contract checks.
3. Read "Almost Scriptless Adaptor Signatures from any Signature Scheme" (eprint 2026/1346) — most promising unread lead for a generic ECDSA/EdDSA-bridging construction.
4. Whether Solana's Ed25519 precompile has any per-instruction cost/size limit that would block using it as an adaptor-signature-reveal verifier in a real swap contract (not investigated in this pass).

## Cross-references

- [[projects/atomic-swap-protocol-details]] — the BTC-XMR adaptor-signature protocol this note's curve-pair reuse insight is drawn from
- [[projects/xmr-first-atomic-swaps]] — documents the same secp256k1↔Ed25519 DLEQ libraries in the BTC-XMR context, including the ETH-XMR (AthanorLabs) prior art referenced above
- [[patterns/wormhole-trust-model]], [[patterns/thorchain-trust-model]] — the TSS/MPC custody-vault alternative actually deployed for ETH↔SOL today
- [[patterns/atomic-swaps-vs-middle-chain]] — broader trade-off framing
