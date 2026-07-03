---
tags: [atomic-swaps, btc-xmr, monero-first, reverse-direction, cryptography, not-deployable]
status: VERIFIED — primary-source check on 2026-05-22
research_question: Has anyone implemented Monero-first (reverse-direction) BTC-XMR atomic swaps, and is it possible on the current Monero protocol?
short_answer: No, and not deployably possible on current Monero. Monero core team's 2026-05-10 blog post states "no scheme has been specified" that uses Monero's existing on-chain primitives for atomic swaps. The eigenwallet team removed the XMR-first chapter from their compiled paper on 2025-11-04 calling it "unsupported by current Monero protocol". The upcoming FCMP++ hardfork (mid-2026) actively REMOVES timelocks rather than adding them. Treat XMR-first BTC↔XMR atomic swaps as structurally unavailable.
---

# XMR-first (reverse-direction) BTC-XMR atomic swaps — not deployable on current Monero

This note tracks whether anyone has implemented the **reverse-direction** BTC-XMR atomic swap, in which the Monero seller locks XMR first and the Bitcoin seller locks BTC second. The standard direction (BTC locks first) is the only one shipped by [[projects/comit]] `xmr-btc-swap`, [[projects/eigenwallet]] `core`, and Farcaster `farcaster-node`. The reverse direction is sometimes called "XMR-first", "Monero moves first", or "BTC sell-side" because in that direction the maker is selling BTC (buying XMR) rather than the other way around.

## TL;DR — XMR-first is not possible on current Monero

**XMR-first BTC↔XMR atomic swaps are not deployably possible on the current Monero protocol, and no Monero hardfork is scheduled that would enable them.** Treat the capability as **structurally unavailable** for the foreseeable horizon (24+ months). Plan around it rather than around it.

Four primary-source data points, in order of weight:

1. **Monero core team, 2026-05-10**: in the official blog post *Deprecating Monero's Custom Transaction Unlock Time* ([getmonero.org](../sources/2026-05-22-getmonero-org-deprecating-unlock-time.html)) — *"It is a common misconception that Monero's Unlock Time is useful for known atomic swap or payment channel protocols. To date, no scheme has been specified that utilizes Monero's Unlock Time feature."* The Monero project is officially confirming that there is no published, ready-to-deploy scheme for using Monero's existing on-chain primitives in an atomic swap.

2. **eigenwallet team, 2025-11-04**: commit `6151734` (*"remove xmr to btc protocol"*, binarybaron) removed the XMR-first chapter from the compiled protocol paper. The replacement comment in `xmr_btc_atomic_swaps.tex` reads:

   > `% We don't care about swaps where the Bitcoin seller is the maker because that is unsupported by the current Monero protocol.`
   > `% It will require a hardfork to work`
   > `% \input{new_protocol}`

   ([archived](../sources/2026-05-22-github-eigenwallet-protocol-xmr-btc.tex), lines 60-62). The team maintaining the only actively-shipped BTC-XMR atomic-swap implementation explicitly declined to pursue XMR-first.

3. **FCMP++ (mid-2026 hardfork) moves AWAY from the needed primitives**: the upcoming FCMP++ hardfork **deprecates** `unlock_time` rather than extending it (research-lab issue #125; getmonero.org 2026-05-10), and the FCMP++ specification gist ([kayabaNerve](../sources/2026-05-22-gist-github-com-kayabaNerve-fcmp-sa-l.md)) makes no mention of adaptor signatures, scriptless scripts, or atomic swaps. Monero's roadmap is going in the opposite direction from what XMR-first would need.

4. **Hoenisch and del Pino 2021 §4** itself flags the cryptographic dependency as unsolved: *"This depends on the development of adaptor signatures based on Monero's ring signature scheme, which is a work-in-progress and whose details are left out of the scope of this work."* No peer-reviewed, Monero-endorsed CLSAG-adaptor-signature construction has been published in the five years since.

## Why it's not possible — the protocol gap

For Alice (XMR seller) to lock XMR first safely, the protocol must guarantee:

1. **Alice can recover her XMR** if Bob never locks BTC (an XMR-side cancel/refund path).
2. **Atomicity**: if Bob locks BTC and Alice claims it, Bob can claim the XMR — and the reveal of either secret unlocks both paths consistently.

The hard part is **(1)**. In the BTC-first protocol, the BTC-side script enforces a non-interactive refund: after a timelock expires, the BTC locker can spend the BTC back unilaterally. **Monero has no equivalent on-chain primitive.** Specifically:

- **Monero has no script language**, so you cannot encode "Alice can spend after T, Bob can spend if he provides secret y" directly on-chain.
- **Monero's `unlock_time` field locks the entire transaction**, not specific outputs, and does not allow conditional spend paths. Monero core has now officially confirmed *no scheme has been specified that uses it for atomic swaps*.
- **CLSAG (Monero's current ring-signature scheme) does not have a peer-reviewed adaptor-signature variant** that has been adopted by the Monero project. The Hoenisch-del Pino §4 protocol assumes such a primitive exists; it does not.
- **2-of-2 multisig refund requires Bob's cooperation.** Without an XMR-side timelock or non-interactive refund primitive, Alice's only way to recover XMR is for Bob to co-sign — which is exactly the draining-attack condition the reverse direction is meant to eliminate.

So the protocol gap is: **Monero today has no on-chain primitive that lets Alice unilaterally and non-interactively recover XMR after Bob fails to lock BTC, without a cryptographic primitive (CLSAG-adaptor-signatures, or DLSAG, or hidden timelocks) that does not exist in deployed form**. See [[projects/xmr-first-required-monero-features]] for the detailed breakdown of which research candidates would close the gap.

## Other directions that don't work on current Monero either

Each of the following has been proposed informally and fails:

| Approach | Why it fails on current Monero |
|----------|-------------------------------|
| Use `unlock_time` as an XMR-side timelock | Monero core 2026-05-10: *"no scheme has been specified that utilizes Monero's Unlock Time feature"* for atomic swaps. Field is being deprecated in FCMP++ anyway. |
| Multi-step interactive refund (Bob co-signs Alice's refund) | Reintroduces the draining-attack condition the reverse direction was meant to solve. Collapses to Haveno-style multisig escrow with dispute resolution — not an atomic swap. |
| TEE-attested refund signer | Trades cryptographic atomicity for hardware-trust; not trust-minimised. |
| Time-lock puzzle / VDF on Monero side | Wall-clock-bound (vulnerable to attacker with more compute); no production integration with Monero signing. |
| Build CLSAG adaptor signatures off-chain (no hardfork needed) | The cryptographic primitive itself has no peer-reviewed, Monero-endorsed construction. Recent academic work (LTRAS 2026-02, 2P-CLRAS IACR 2024/241, MoNet IACR 2022/744) is in the right family but targets payment channels, not atomic swaps. |

## This is structural, not implementation-specific

This applies to BTC-XMR specifically, and **for the same reason** to **every chain pair where Monero is one side**: ETH-XMR (AthanorLabs is ETH-first), Tari-XMR (Tari RFC-0241 is Tari-first), Monero-Starknet (omarespejel is Starknet-first). The script-rich side moves first in every case. The "Monero moves first" direction is uniformly unavailable.

## What "reverse direction" means concretely

In the deployed BTC-first protocol (and its current implementations):
- **Bob** holds BTC, wants XMR, **locks BTC first** via a 2-of-2 multisig + relative timelock script on Bitcoin (`tx_lock^btc`).
- **Alice** holds XMR, wants BTC, **locks XMR second** in a shared (`S_a + S_b`, `V_a + V_b`) Monero output (`tx_lock^xmr`).
- The maker (eigenwallet `asb`) is always Alice, the XMR seller. The taker (`swap-cli buy-xmr`) is always Bob, the BTC seller.

In the reverse direction (XMR-first):
- **Alice** holds XMR, wants BTC, **locks XMR first**.
- **Bob** holds BTC, wants XMR, **locks BTC second**.
- The maker would be the BTC seller (the "buy XMR with BTC" side from the maker's perspective is gone; instead the maker would be selling BTC for XMR).

The motivation for the reverse direction is the **draining attack** from [[projects/atomic-swap-protocol-details]]. In the BTC-first direction, an attacker can engage a maker who's selling XMR, force the maker to lock BTC (which the maker doesn't have to do in the BTC-first direction — but if the protocol were used in the *opposite* role, with the maker as BTC seller, the attacker could force the maker to lock BTC and then bail at zero cost, forcing the maker to pay refund tx fees over and over. Hoenisch and del Pino §4 explicitly call out this asymmetry: *"the taker's ability to make the SP incur in transaction fees without penalty would expose the SP to running out of funds over time"* ([eigenwallet/protocol new_protocol.tex](../sources/2026-05-22-github-eigenwallet-protocol-new-protocol.tex) lines 9-12, mirroring [Hoenisch–del Pino 2021](../sources/2026-05-22-arxiv-org-2101-12332.pdf) §4 pp.10-11).

So the reverse direction is needed not because the BTC-first direction is broken, but because **the deployed protocol can only be operated profitably from one side of the trade**. A maker who wants to *sell BTC for XMR* (e.g. a Monero-native business wanting to acquire BTC liquidity) has no on-protocol way to do it; they must run a centralised exchange or use [[projects/serai]]-style middle-chain settlement.

## Why CLSAG adaptor signatures are required

Both papers (Gugger 2020 and Hoenisch–del Pino 2021) explain the issue: in the BTC-first direction, the cryptographic glue is an **adaptor signature on the Bitcoin side**. ECDSA-one-time-VES (Fournier 2019) lets a Bitcoin signature carry a discrete-log puzzle whose solution is revealed on-chain when the signature is broadcast. The puzzle's secret is also a Monero spend-key share. So broadcasting the Bitcoin redeem transaction reveals the Monero key, allowing the counterparty to spend the Monero. The cross-curve DLEQ proof (Noether 2018, MRL-0010) proves that the secp256k1 puzzle point and the Ed25519 key share share the same scalar.

For the **reverse direction**, the cryptographic glue must be an **adaptor signature on the Monero side**: Alice's Monero refund must reveal a Bitcoin secret. Monero's signature scheme is CLSAG (Concise Linkable Spontaneous Anonymous Group, replacing MLSAG since the Oct 2020 fork; see [getmonero.org CLSAG transaction announcement](https://www.getmonero.org/resources/moneropedia/clsag.html) :: accessed 2026-05-22). An adaptor signature variant of CLSAG would need:

1. **A pre-signature** (`pSign`) that produces an output verifying CLSAG signature structure but not yet a valid CLSAG signature.
2. **An adapt** operation that takes the pre-signature and a witness `y` and produces a valid CLSAG signature.
3. **An extract** operation that, given the pre-signature and the final on-chain CLSAG signature, recovers `y`.
4. **Witness extractability**: extracting `y` must be the only way to convert a pre-signature into a valid signature.

Hoenisch and del Pino (2021) §4 sketch the protocol assuming these primitives exist, but explicitly defer their construction: *"This depends on the development of adaptor signatures based on Monero's ring signature scheme, which is a work-in-progress and whose details are left out of the scope of this work."* ([new_protocol.tex](../sources/2026-05-22-github-eigenwallet-protocol-new-protocol.tex) line 16). The conclusion to the eigenwallet/protocol paper [PDF Build 20251105](https://github.com/eigenwallet/protocol/releases) is more cautious still: *"This proposal hinges on the viability of using adaptor signatures on Monero, a topic which we do not discuss here, but one which is being researched at the time of writing."* ([conclusion.tex](../sources/2026-05-22-github-eigenwallet-protocol-conclusion.tex)).

### Why this is hard (the technical obstacles)

Ring signatures have a structural property that makes adaptor-signature construction non-trivial: the signer's identity is **hidden among decoys**, and the signature's validity depends on a key image (`I = x H_p(P)` for spend key `x`) being correctly linked to *exactly one* of the ring members. An adaptor-signature pre-signature must:

- Verify the ring/key-image structure without revealing which ring member is the signer.
- Embed a discrete-log puzzle whose extraction is tied to one specific scalar (the secret spend-key share).
- Be unforgeable in the same security sense as the underlying CLSAG.

There is no security proof in the public literature of a CLSAG-compatible adaptor-signature scheme with witness extractability that the Monero core team or Cypher Stack have endorsed. The recent revisions to CLSAG's own security proofs ([getmonero.org 2024-03-08, CLSAG security proof revisions](https://www.getmonero.org/2024/03/08/clsag-security-proof-revisions.html) :: accessed 2026-05-22) suggest the underlying CLSAG scheme's proofs are themselves still being tightened, which would make a proof of an adaptor-signature variant building on CLSAG even more delicate.

### What "would require a hardfork" means

The eigenwallet team's note that it "will require a hardfork to work" is ambiguous. Two readings:

1. **CLSAG adaptor signatures themselves are fine on the current protocol, but the protocol composition requires Monero-side validation features that don't exist today** (e.g. a way to commit to an adaptor point on-chain that is later revealed; or a multi-signature protocol over CLSAG with specific homomorphic properties). This is a hardfork to add new Monero functionality.
2. **The construction works in principle but interacts badly with current Monero rules** (key image uniqueness, ring selection rules, view-tag enforcement, FCMP+ migration), and the cleanest fix is a hardfork.

Either way, the practical statement is: **the eigenwallet team does not view this as a near-term implementation target**.

## Implementation status — by project (2026-05-22)

| Project | Direction supported | XMR-first status | Last release | Source |
|---------|---------------------|------------------|--------------|--------|
| [[projects/comit]] `xmr-btc-swap` | BTC-first only | Not implemented; repo unmaintained | v1.0.0-rc.1, 2024-11-15 | [github.com/comit-network/xmr-btc-swap README](../sources/2026-05-22-github-comit-network-xmr-btc-swap-readme.md) |
| [[projects/eigenwallet]] `core` | BTC-first only | Not implemented; team has actively removed XMR-first chapter from protocol paper (commit `6151734`, 2025-11-04) and labelled it "unsupported by current Monero protocol, will require a hardfork" | v4.6.4, 2026-05-21 | [eigenwallet/protocol xmr_btc_atomic_swaps.tex](../sources/2026-05-22-github-eigenwallet-protocol-xmr-btc.tex) |
| Farcaster (`farcaster-node`) | BTC-first only (Alice = accordant asset = XMR = second; Bob = arbitrating asset = BTC = first) | Not implemented; design RFC fixes BTC-first | v0.8.4, 2023-01-16; project inactive | [farcaster-project/RFCs 02-user-stories.md](https://github.com/farcaster-project/RFCs/blob/main/02-user-stories.md) |
| `noosphere888/samourai-swaps` | BTC-first only (despite "selling XMR" framing) | Not implemented; the "sell XMR" path is just running the ASB maker role under the COMIT BTC-first protocol — same direction at the cryptographic level | No releases | [github.com/noosphere888/samourai-swaps](https://github.com/noosphere888/samourai-swaps) |
| Academic papers — Hoenisch–del Pino 2021 §4 | XMR-first sketched | Paper-only; explicit "work-in-progress" | 2021-02 (v2) | [arxiv.org/abs/2101.12332](../sources/2026-05-22-arxiv-org-2101-12332.pdf) |
| Academic papers — LTRAS (Liang, Han 2026-02) | Generic threshold ring adaptor signature; cross-chain | "Theoretical with experimental validation"; no production code | arXiv 2602.05431 v1, 2026-02-05 | [arxiv.org/pdf/2602.05431](../sources/2026-05-22-arxiv-2602-05431-ltras.pdf) |
| Academic papers — Consecutive Adaptor Signature (IACR 2024/241) | 2P-CLRAS for Monero-compatible payment channels (MoNet) | Payment channels, not atomic swaps; theoretical with experimental implementation | IACR ePrint 2024/241 | [eprint.iacr.org/2024/241](../sources/2026-05-22-eprint-iacr-2024-241-consecutive.pdf) |
| Academic papers — Attribute-Based Adaptor Signature (Springer 978-981-95-3540-8_9) | Control-based atomic swap with attribute-based adaptor signatures | Not directly XMR-first; conference paper, full text paywalled | Springer chapter, 2025 | [link.springer.com](https://link.springer.com/chapter/10.1007/978-981-95-3540-8_9) — full text auth-gated, unarchived |

## Alternative chain pairs where Monero locks first

The "Monero-first" direction is implemented for some Monero chain pairs **other than BTC**, by exploiting the other chain's stronger script support to side-step the CLSAG-adaptor-signature problem. These are not solutions to BTC-XMR XMR-first; they are evidence that *given a sufficiently expressive partner chain, the cryptographic glue can sit entirely on the partner side*.

### ETH-XMR (AthanorLabs/atomic-swap)

[`AthanorLabs/atomic-swap`](https://github.com/AthanorLabs/atomic-swap) implements ETH↔XMR. Per its [protocol documentation](../sources/2026-05-22-github-athanorlabs-atomic-swap-protocol.md), the direction is **ETH-first**: *"Alice deploys a smart contract on Ethereum and locks her ETH in it"* followed by *"Bob sees the smart contract has been deployed with the correct parameters. He sends his XMR to an account address constructed from P_a + P_b"*. **The same direction problem as BTC-XMR exists**: the side with the script-rich chain moves first; the Monero side moves second. AthanorLabs' construction does not use CLSAG adaptor signatures. It uses an EVM contract that verifies an Ed25519 key-share reveal directly on-chain. Status: beta, last release v0.4.3 (2023-12-14).

So ETH-XMR has the same XMR-second limitation as BTC-XMR. ETH-XMR XMR-first is not implemented either.

### Tari-XMR (Tari RFC-0241)

[Tari RFC-0241 Atomic Swap XMR](https://rfc.tari.com/RFC-0241_AtomicSwapXMR) ([archived](../sources/2026-05-22-rfc-tari-com-RFC-0241.html)) describes a protocol for Tari↔Monero swaps. Per the RFC, *"the protocol is not Monero-first. Alice (the Tari holder) initiates by creating a Tari UTXO first."* — same direction as ETH-XMR and BTC-XMR. Tari's TariScript is described as having *"a few advantages over Bitcoin script regarding adaptor signatures, as the script key was explicitly designed with scriptless scripts in mind"*; despite this, the RFC still defaults to **Tari-first** because the underlying CLSAG-adaptor-signature problem on Monero is unsolved. Status: draft RFC, maintainer S W van Heerden, no production implementation.

### Monero-Starknet (omarespejel/monero-starknet-atomic-swap)

[`omarespejel/monero-starknet-atomic-swap`](https://github.com/omarespejel/monero-starknet-atomic-swap) is an alpha/testnet implementation of XMR↔Starknet swaps using DLEQ proofs (Serai-style) rather than CLSAG adaptor signatures. Direction is **Starknet-first**: *"Bob reveals s_b on Starknet when ready, unlocking tokens; Alice detects reveal, recovers full key x = s_a + s_b, spends Monero"*. Same pattern: the script-rich side moves first.

### The Serai exception

[[projects/serai]] avoids the direction problem entirely by interposing a **middle chain** (Serai itself) between any two assets. There is no atomic swap between Monero and Bitcoin in Serai; instead, you deposit XMR into Serai (Serai's validator set runs a Monero multisig vault), trade against the Serai AMM, and withdraw on the other chain. The direction asymmetry is absorbed into Serai's validator set, which always moves first on the deposit chain and second on the withdrawal chain by running multisig vaults on both chains. This is not an "atomic swap" in the Hoenisch–del Pino sense but is the closest production-grade alternative.

## What would change the picture (none of these are queued)

A working XMR-first BTC-XMR atomic swap would require **all three** of:

1. **A cryptographic construction of CLSAG-compatible adaptor signatures with witness extractability**, published with a security proof and adopted by the Monero project. As of 2026-05, no such construction has been peer-reviewed and adopted. The LTRAS paper (Liang and Han 2026-02) and the 2P-CLRAS construction (IACR 2024/241) are in the right family but target payment channels rather than single-shot atomic swaps, and neither is endorsed by Monero core. **Active research; no timeline.**

2. **A Monero protocol primitive enabling unilateral non-interactive refund** of locked Monero (DLSAG-style ring-signature replacement, or hidden timelocks, or an equivalent). **No such primitive is on the Monero roadmap.** Research-lab issues #65 (hidden timelocks, 2020) and the DLSAG paper (2019) have been open without implementation activity for 5+ years. The FCMP++ hardfork (mid-2026) goes in the opposite direction by deprecating `unlock_time`.

3. **Time for that primitive to be specified, audited, and ship in a Monero hardfork**. Even a green-light decision today would mean a ~24-month minimum to deployment, based on FCMP++'s own timeline as a comparable cryptographic upgrade (paper to hardfork: roughly 3 years).

Until **all three** conditions are met, XMR-first BTC↔XMR atomic swaps cannot be deployed in a trust-minimised, atomic, non-interactive form. The realistic horizon is 3+ years, with the precondition (peer-reviewed CLSAG-adaptor-signature primitive) not yet satisfied at year zero.

**Alternatives that side-step rather than solve the problem** (these do not produce atomic swaps, they produce different trust models):

- [[projects/serai]]'s middle-chain approach (validator-set custody, AMM pricing).
- Haveno-style multisig + arbitrator dispute resolution (not an atomic swap; introduces arbitrator trust).
- TEE-based construction (hardware-trust, not protocol-level atomicity).
- Centralised broker / instant-swap service (custodial in practice).

None of these is an XMR-first atomic swap. They are the **practical replacements** for one.

## Why this matters strategically

The XMR-first limitation is **structural to the BTC-XMR atomic-swap maker economy** and is not going away in any realistic planning horizon:

- Every maker in the [[projects/eigenwallet]] network is **selling XMR for BTC**.
- A user who already holds XMR and wants BTC **cannot use any atomic-swap protocol** to convert it. They must route through (a) a centralised exchange or instant-swap service ([[projects/baltex]], etc.), (b) Haveno-style multisig with dispute resolution, (c) a middle-chain DEX ([[projects/serai]]), or (d) a TEE-based construction. **None of these is an atomic swap**, and each carries its own trust assumptions.
- For privacy-aware DEX design (e.g. LEZ positioning, [[projects/lez-positioning]]): **do not propose XMR-first atomic swaps in any spec or roadmap**. The cryptographic primitive does not exist, the Monero protocol does not support it, and the Monero core team has officially confirmed no scheme has been specified. Any DEX that needs XMR-sell-side liquidity must use one of the four alternatives above and accept the corresponding trust model.
- This is one of the reasons [[projects/serai]] and Haveno co-exist with the atomic-swap protocols rather than competing directly: they offer the **XMR-sell-side** liquidity that atomic swaps cannot provide, and **cannot be replaced by an atomic-swap protocol** on current or near-term Monero.

## What to verify before relying on this note

This is a survey of a research/engineering frontier. The following could change the picture, in order of likelihood:

1. **Monero core team accepts a CLSAG adaptor-signature construction**. Track [getmonero.org/research-lab](https://www.getmonero.org/community/research-lab/) and the Monero Research Lab Bulletins (MRL-NNNN). If MRL publishes a new bulletin on CLSAG adaptor signatures, this note is stale.
2. **FCMP+ migration completes and includes an adaptor-signature-friendly primitive**. Track [Monero/FCMP](https://github.com/kayabaNerve/fcmp-plus-plus) progress and Cypher Stack reports.
3. **eigenwallet team publishes a new revision of the protocol paper with the XMR-first chapter re-enabled**. Track [eigenwallet/protocol](https://github.com/eigenwallet/protocol) commits.
4. **Farcaster project returns to active development** and ships an XMR-first variant. As of 2026-05, last release is 2023-01.

## Sources

- **eigenwallet/protocol** at master, key files:
  - [xmr_btc_atomic_swaps.tex](../sources/2026-05-22-github-eigenwallet-protocol-xmr-btc.tex) — main paper; lines 60-62 contain the explicit "unsupported, will require a hardfork" comment
  - [new_protocol.tex](../sources/2026-05-22-github-eigenwallet-protocol-new-protocol.tex) — the (commented-out from main paper) XMR-first chapter
  - [introduction.tex](../sources/2026-05-22-github-eigenwallet-protocol-introduction.tex)
  - [conclusion.tex](../sources/2026-05-22-github-eigenwallet-protocol-conclusion.tex)
  - [old_protocol.tex](../sources/2026-05-22-github-eigenwallet-protocol-old-protocol.tex)
- **Hoenisch, P. and del Pino, L.S. (2021)**: *Atomic Swaps between Bitcoin and Monero*. arXiv 2101.12332v2. [pdf](https://arxiv.org/pdf/2101.12332) :: [archived](../sources/2026-05-22-arxiv-org-2101-12332.pdf). §4 introduces the XMR-first direction and notes the CLSAG adaptor signature dependency.
- **Gugger, J. (2020)**: *Bitcoin–Monero Cross-chain Atomic Swap*. IACR ePrint 2020/1126. [pdf](https://eprint.iacr.org/2020/1126.pdf) :: [archived](../sources/2026-05-22-eprint-iacr-org-2020-1126-gugger.pdf). The original BTC-XMR protocol; note that Gugger's direction is technically XMR-first at the protocol level (Alice = XMR holder = moves first) — but in deployment the maker takes the role with the *larger* refund-fee risk to absorb it as a cost of doing business, which is why the deployed protocol is described as "BTC-first" from the user's perspective.
- **Liang, Y. and Han, J. (2026)**: *LTRAS: A Linkable Threshold Ring Adaptor Signature Scheme for Efficient and Private Cross-Chain Transactions*. arXiv 2602.05431. [pdf](../sources/2026-05-22-arxiv-2602-05431-ltras.pdf). Threshold ring adaptor signature; not a single-signer CLSAG-compatible construction; not endorsed by Monero core team.
- **Consecutive Adaptor Signature Scheme: From Two-Party to N-Party Settings**, IACR ePrint 2024/241 [pdf](../sources/2026-05-22-eprint-iacr-2024-241-consecutive.pdf). 2P-CLRAS for Monero-compatible payment channels (MoNet); applies to payment channels, not single-shot atomic swaps.
- **You, S., Joshi, A., Kuehlkamp, A., Nabrzyski, J. (2024)**: *A Multi-Party, Multi-Blockchain Atomic Swap Protocol with Universal Adaptor Secret*. arXiv 2406.16822. [pdf](../sources/2026-05-22-arxiv-2406-16822-multi-party.pdf). Generic multi-chain atomic swap using Schnorr-like signatures; not Monero-specific, not CLSAG.
- **Attribute-Based Adaptor Signature and Application in Control-Based Atomic Swap**, Springer chapter 10.1007/978-981-95-3540-8_9, 2025 — full text paywalled and unarchived. Surfaces in adaptor-signature search results but the abstract does not specifically address Monero CLSAG or XMR-first BTC-XMR.
- **Kopyciok, Y., Victor, F., Schmid, S. (2025)**: *Monero's Decentralized P2P Exchanges*. arXiv 2505.02392, v2 2025-05-20. [archived](../sources/2026-05-22-arxiv-2505-02392-monero-p2p.html) (HTML abstract page only; full PDF not pulled here). Surveys Monero P2P exchanges including atomic swaps and Haveno; identifies a Haveno privacy issue.
- **AthanorLabs/atomic-swap** ETH↔XMR protocol doc :: [archived](../sources/2026-05-22-github-athanorlabs-atomic-swap-protocol.md).
- **Tari RFC-0241 Atomic Swap XMR** :: [archived](../sources/2026-05-22-rfc-tari-com-RFC-0241.html).
- **Farcaster-project/RFCs 02-user-stories.md** :: accessed 2026-05-22 — confirms BTC-first direction (Alice = accordant = XMR = moves second).
- **comit-network/xmr-btc-swap README** :: [archived](../sources/2026-05-22-github-comit-network-xmr-btc-swap-readme.md) — confirms BTC-first only.
- **eigenwallet/core README** :: [archived](../sources/2026-05-22-github-eigenwallet-core-readme.md) — confirms BTC-first only.
- **getmonero.org Moneropedia: CLSAG** [link](https://www.getmonero.org/resources/moneropedia/clsag.html) :: accessed 2026-05-22 — for CLSAG background.
- **getmonero.org 2024-03-08, CLSAG security proof revisions** [link](https://www.getmonero.org/2024/03/08/clsag-security-proof-revisions.html) :: accessed 2026-05-22 — for the state of CLSAG security proofs.

## Cross-references

- [[projects/atomic-swap-protocol-details]] for the BTC-first protocol mechanics and the draining-attack analysis at full detail
- [[projects/eigenwallet]] for the canonical implementation status (BTC-first only)
- [[projects/comit]] for the original COMIT implementation and unmaintained status
- [[projects/serai]] for the middle-chain alternative that side-steps the direction problem
- [[patterns/atomic-swaps-vs-middle-chain]] for the broader trade-off
- [[patterns/ring-signatures]] for CLSAG background
