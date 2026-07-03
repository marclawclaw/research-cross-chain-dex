---
tags: [project, atomic-swaps, zcash, ethereum, bitcoin, privacy, unlinkability, zero-knowledge, ecdh, active]
ecosystem: Zcash, Ethereum/Base, Bitcoin (cross-chain primitive, no own chain)
category: Unlinkable cross-chain atomic swaps (ECDH multiplicative key aggregation, solver model)
website: https://zwap.atheon.xyz/ (whitepaper PDF served at root)
app: https://app.zwap.exchange/
org: Atheon (atheon.xyz) — cryptography R&D team
github: https://github.com/atheonxyz (also https://github.com/atheon-inc)
launched: Early-access release 2026-05-27 (Zcash↔Ethereum/Base); whitepaper published ~2026-03
---

# Zwap (Atheon)

**Zwap** is a cross-chain atomic swap protocol that replaces the HTLC shared-hash atomicity mechanism with **ECDH multiplicative key aggregation**, eliminating the deterministic cross-chain linkage that HTLCs create. It is built by **Atheon** (a cryptography R&D team; founder **Aditya Bisht**), with the whitepaper authored by Aditya Bisht and Yashwanth Reddy ([zwap.atheon.xyz](https://zwap.atheon.xyz/) :: accessed 2026-07-01 :: [archived](../sources/2026-07-01-zwap-atheon-xyz-whitepaper.pdf)). It is **Orchard-native**: swaps fund from and settle into Zcash's Orchard shielded pool. The live app at [app.zwap.exchange](https://app.zwap.exchange/) entered early access on 2026-05-27 supporting **Zcash ↔ Ethereum/Base (USDC, ETH)** with per-swap caps of \$1–\$100 ([forum.zcashcommunity.com — Early Access thread](https://forum.zcashcommunity.com/t/zwap-trustless-shielded-atomic-swaps-for-zcash-early-access/55874) :: accessed 2026-07-01).

> **Name collision warning.** A *different, unrelated* project also called "Zwap" was announced 2023-06-14 by **hanh** (the YWallet developer) for BTC/ZEC swaps using **DLEq proofs** — see [[#Disambiguation]] below. This note is about the **Atheon** Zwap (2026), which uses ECDH key aggregation, not DLEq. The two share only a name and the Zcash forum.

## Why it matters to this research

Zwap is the **privacy-first atomic-swap point in the design space** that the cross-chain DEX bundle has been circling. Where [[projects/eigenwallet]] / [[projects/comit]] use adaptor signatures to swap BTC↔XMR (and are limited to one direction by Monero's lack of script — see [[projects/xmr-first-atomic-swaps]]), Zwap attacks a *different* privacy leak: the **cross-chain correlation** that every HTLC creates by embedding the same hash `H(s)` on both legs. It is directly relevant to research question 5 ("what anonymity properties can LEZ bring that Serai/Thorchain/Wormhole cannot match") because it demonstrates **unlinkable swaps with no middle chain at all** — a contrast point to the middle-chain settlement model of [[projects/serai]] and [[projects/thorchain]]. See [[patterns/atomic-swaps-vs-middle-chain]] and [[patterns/cross-chain-privacy]].

It is the first construction in this bundle that is **EVM-compatible and Zcash-Orchard-native simultaneously**, and the first to provide a **formal cross-chain unlinkability proof** rather than relying on after-the-fact obfuscation.

## Core idea: ECDH aggregate key replaces the shared hash

The canonical HTLC puts the same hash `H(s)` on both chains; when `s` is revealed on one chain to claim funds, any observer matches it against the other chain — "a public bridge between two otherwise independent transaction graphs". Zwap's construction:

- **One leg is an ECDH lock.** The aggregate locking key is the ECDH shared point **`P_SB = s·P_B = b·P_S`** (Alice's secret `s`, Bob's secret `b`). The signing key is the scalar product `s·b mod q`. Neither party can manipulate `P_SB` without solving the discrete-log problem — this gives **rogue-key resistance without commitment ordering** (contrast MuSig's additive `P_A + P_B`, which needs commitment rounds or proofs of possession). See [[patterns/ecdh-key-aggregation]].
- **The other leg is a standard hash lock** `H(s)` (chain-agnostic; `OP_SHA256` on UTXO, `keccak256` on EVM).
- **A zero-knowledge binding proof** ties them together: Alice proves in ZK that her secret `s` is *simultaneously* the preimage of `H(s)` **and** the discrete log of `P_S` (i.e. `s·G = P_S`), for relation `R = {(h, P_S; s) : H(s)=h ∧ s·G=P_S}`. Bob verifies this **off-chain** before committing any capital, so there is **zero on-chain footprint during matching** (Whitepaper §IV).

The result (Whitepaper Theorem 16): **no common value ever appears across the two chains** — `H(s)` appears on exactly one chain, `P_SB` on the other — so a passive observer cannot link the two legs cryptographically. This is *protocol-level* unlinkability, not post-hoc mixing.

## Protocol shape (solver model)

- **Participants**: **Alice** = swap initiator (generates `s`, **always locks first**). **Bob** = **solver** (a known, reputable entity; generates `b`; always locks second). All keys/addresses ephemeral (Whitepaper §III-B). This is a **solver/maker model**, structurally similar to eigenwallet's maker or a Thorchain-style liquidity provider — *not* peer-to-peer symmetric.
- **Phase 0 (off-chain)**: order matching; Alice sends `H(s)`, `P_S`, and ZK binding proof `π`; both compute `P_SB`.
- **Phase 1 (locking)**: Alice locks the ECDH leg (timelock `T`); Bob verifies, then locks the hash leg (timelock `T/c`, the shorter one).
- **Phase 2 (redemption)**: Alice reveals `s` on the hash-lock chain to claim; Bob reads `s`, computes `s·b`, signs under `P_SB`, claims the ECDH leg.

**Alice-locks-first** (Definition 4 / Remark 5) protects the solver: Bob never commits capital before verifying Alice's lock, so his worst case before locking is wasted verification effort, not lost funds. **Timelock assignment** (Definition 6): the party who redeems *second* (Bob) gets the *longer* timelock `T`; recommended divisor `c=2`.

## Chain support and primitives

Asset-agnostic and chain-agnostic; only the **lock encoding differs per chain** (Whitepaper Abstract, §III-C):

| Direction | ECDH leg | Hash leg | Status |
|-----------|----------|----------|--------|
| EVM ↔ UTXO | `ecrecover` (ECDSA) on EVM | `OP_SHA256` / `OP_CHECKSIG` on UTXO | core construction |
| UTXO ↔ UTXO | `OP_CHECKSIG` (sig lock) | `OP_SHA256` (hash lock) | e.g. Bitcoin–Zcash |
| EVM ↔ EVM | `ecrecover` | `keccak256` | supported |

- **EVM chains** need `ecrecover` + `keccak256` + standard contract deployment. The `ZwapHtlc` contract is deployed and on-chain-inspectable. Optional **CREATE2** deterministic deployment makes the locked address indistinguishable from a plain EOA until redemption (§VII).
- **UTXO chains** (Bitcoin post-BIP65, Litecoin, Zcash transparent) need `OP_CHECKSIG`, a hash opcode, and `OP_CHECKLOCKTIMEVERIFY`. Standard P2SH scripts; no soft-fork required.
- **Live pairs (2026-05-27)**: Zcash ↔ Ethereum/Base (USDC, ETH). **In progress**: Bitcoin support, more chains, and native **shielded-to-shielded** swaps. The current Zcash side is **Orchard-native** (funds settle in/out of the Orchard pool), per the early-access announcement, whereas the whitepaper's UTXO instantiation uses Zcash's *transparent* layer — implying the live product wraps Orchard via a Pallas/secp256k1 cross-curve construction the forum describes as a "hashbind" circuit.

## Key technical claims (from whitepaper)

- **Rogue-key resistance** (Theorem 11): under DLog, with both parties validating received public keys, neither can bias `P_SB` regardless of commitment order. Corollary 12: **no commitment ordering needed** — Alice can commit `P_S` first in either direction.
- **Binding proof necessity** (Lemma 13): without the ZK binding proof, Alice can decouple the two locks (publish `P_S = s'·G` for `s'≠s`) and steal Bob's funds. The proof is what prevents this.
- **Hash-collision attack** (Lemma 3): the hash must provide collision resistance ≥ the curve's ~128-bit security, else Alice can steal funds via a birthday collision — so SHA-256/keccak256 are required, not a truncated hash.
- **Zero MEV** (Remark 9): redeem and refund paths are **permissionless with hardcoded recipients** — no `msg.sender` check; any relayer can submit on behalf of either party; funds always route to the hardcoded recipient, so MEV extraction is zero. The non-EVM party never needs to touch EVM infrastructure.
- **Cross-chain unlinkability** (Theorem 16): under DLog + collision-resistant `H` + ephemeral per-chain keys, a real swap pair is indistinguishable from a mismatched pair to a passive observer.

## Candid limitations (the whitepaper is unusually honest about these)

- **Statistical / graph linkability remains** (§X-D): cryptographic linkage is eliminated, but **amount correlation** (matching lock values within a time window), **timing correlation** (the locking/redemption phase structure), and **solver UTXO clustering** (Bob is a known entity; his funding sources are not ephemeral and can be correlated by graph analysis) are "the dominant practical threat." Mitigations (fixed denominations, batched settlement, funding obfuscation, isolated UTXO sets) are **operational, not protocol-enforced**.
- **No forward secrecy**: `s` is revealed on-chain permanently; if Bob's ephemeral `b` is later compromised, `s·b` is retroactively recoverable. Bob must delete `b` after redeeming.
- **Free option**: Alice controls `s` and chooses *when/whether* to reveal during `[0, T/c)`, holding a free option on the exchange rate (valued ≈ `0.96%·S` at the recommended `T=24h, c=2`). Mitigations are pricing/premiums/tighter timelocks — same optionality problem all atomic swaps have.
- **Alice-locks-first capital risk**: if Bob vanishes, Alice's capital is frozen until `T`; mitigated by an optional 2-of-2 mutual-refund multisig and solver bonding.
- **No trustless third-party dispute resolution**: because `P_SB = s·P_B` is *not* publicly verifiable without knowledge of `s` or `b` (unlike additive `P_A+P_B`), there is no on-chain adjudication of a bad binding proof. The relay server can log proofs for reputation only.
- **L2 sequencer censorship** of redeem transactions is acknowledged (cites Winzer et al.); mitigated by permissionless relay + recommended L1 forced-inclusion.

## ZK proving system

Off-chain binding proof, benchmarked on Apple M-series (Whitepaper §IV-A, footnote 1):

| System | Gates | Prove | Proof size | Verify |
|--------|-------|-------|-----------|--------|
| Groth16 (Circom) | 197K | 1.3s | 128 B | 150 ms |
| UltraHonk (Barretenberg) | 23K | 1.4s | 14.25 KB | 200 ms |
| ProveKit | 128K | 1.0s | ~550 KB | 300 ms |

The live product generates proofs **client-side via ProveKit**, verified in milliseconds (forum). Atheon also ships **Verity**, a ZK-proof SDK (Swift/Kotlin/TypeScript) that abstracts over ProveKit/Barretenberg backends ([github.com/atheonxyz/verity](https://github.com/atheonxyz) :: accessed 2026-07-01) — i.e. the proving infrastructure is a reusable in-house component. Groth16 (128 B proof) is recommended for the optional on-chain ZK-verified initiation pool (§XII-A), since BN254 pairing precompiles exist on EVM.

## Recommended parameters (Whitepaper §XI, "very conservative")

`T = 24h`, divisor `c = 2` (so hash-lock timelock `T/c = 12h`), Δ_evm = 64 blocks (post-merge final), Δ_btc = 6 blocks, Δ_zec = 24 blocks. Tighter bounds (e.g. `T = 6h, T/2 = 3h`) are noted as achievable under stronger liveness assumptions to reduce the free-option window and Alice's capital lockup.

## Project / adoption status (2026-07-01)

| Field | Value |
|-------|-------|
| Org | Atheon (atheon.xyz), cryptography R&D; contact hello@atheon.xyz |
| Founder | Aditya Bisht ([LinkedIn](https://www.linkedin.com/in/aditya-bisht-409210105/)) |
| Whitepaper authors | Aditya Bisht, Yashwanth Reddy ("immabeyeet" / "Yashwanth Reddy" on forum) |
| Whitepaper | "Zwap: A Cross-Chain Atomic Swap Protocol Using Multiplicative Key Aggregation", served at [zwap.atheon.xyz](https://zwap.atheon.xyz/) (11pp, IEEE-style; full security proofs + 10 enumerated edge cases). PDF embedded CreationDate 2026-03-28 (pdfTeX), consistent with the 2026-03-27 forum announcement |
| Live app | [app.zwap.exchange](https://app.zwap.exchange/) — early access from 2026-05-27 |
| Live pairs | Zcash ↔ Ethereum/Base (USDC, ETH); swap caps \$1–\$100 |
| Audit status | Two internal security reviews done; **external independent audit planned before raising caps** — explicitly *not yet externally audited* |
| GitHub | [atheonxyz](https://github.com/atheonxyz) (Verity ZK SDK; ~5 repos) |
| Grant | Zcash grant application mentioned (March 2026 forum thread) |

**Volume / usage metrics**: `[NOT FOUND]` — no swap count, TVL, or solver count is published as of 2026-07-01. The product is in capped early access ($100 max/swap).

## Disambiguation

There are **two unrelated "Zwap" projects on the Zcash forum**, and they must not be conflated:

| | **Atheon Zwap (this note)** | **hanh's Zwap (2023)** |
|--|--|--|
| Announced | Whitepaper ~2026-03; app 2026-05-27 | 2023-06-14 ([forum thread 44864](https://forum.zcashcommunity.com/t/zwap-atomic-cross-chain-btc-zec-swaps/44864)) |
| Builder | Atheon (Aditya Bisht, Yashwanth Reddy) | hanh (YWallet developer) |
| Mechanism | ECDH multiplicative key aggregation + ZK binding proof | DLEq (discrete-log-equality) proofs, Halo2 / COPZ |
| Pairs | ZEC↔ETH/Base live; BTC planned | BTC/ZEC (P2TR Taproot + shielded ZEC) |
| Status | Early access live 2026-05-27 | Early-stage, "unproven nor audited" (2023) |

Both are distinct again from **Zswap** (eprint 2022/1002, "zk-SNARK Based Non-Interactive Multi-Asset Swaps") — a same-chain confidential DEX, unrelated to either.

## Sources

- [Zwap whitepaper PDF](https://zwap.atheon.xyz/) — accessed 2026-07-01 — [archived](../sources/2026-07-01-zwap-atheon-xyz-whitepaper.pdf) — NOTE: root URL returns the PDF only with a browser User-Agent; default agents get HTTP 403.
- [Zwap: Trustless Shielded Atomic Swaps for Zcash (Early Access)](https://forum.zcashcommunity.com/t/zwap-trustless-shielded-atomic-swaps-for-zcash-early-access/55874) — accessed 2026-07-01 (early-access announcement, 2026-05-27, caps, audit status, Orchard-native, ProveKit)
- [Zwap: Unlinkable Cross-Chain Atomic Swaps](https://forum.zcashcommunity.com/t/zwap-unlinkable-cross-chain-atomic-swaps/55104) — accessed 2026-07-01 (ECDH/ECDH-Swap protocol, posted 2026-03-27 by Aditya)
- [Zwap - Atomic Cross-chain BTC/ZEC swaps](https://forum.zcashcommunity.com/t/zwap-atomic-cross-chain-btc-zec-swaps/44864) — accessed 2026-07-01 (the *2023 hanh* project — disambiguation only)
- [app.zwap.exchange](https://app.zwap.exchange/) — accessed 2026-07-01 — [archived](../sources/2026-07-01-app-zwap-exchange.html) (JS SPA; no static content)
- [Atheon on GitHub](https://github.com/atheonxyz) / [Verity ZK SDK](https://github.com/atheon-inc) — accessed 2026-07-01
- [Aditya Bisht — LinkedIn](https://www.linkedin.com/in/aditya-bisht-409210105/) — accessed 2026-07-01 (Founder @ Atheon, Cryptography R&D)
