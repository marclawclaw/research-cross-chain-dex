---
tags: [atomic-swaps, btc-xmr, monero-first, monero-protocol, hardfork, fcmp-plus-plus, dlsag]
status: VERIFIED — primary-source check on 2026-05-22
research_question: What specific Monero hardfork or protocol feature does the eigenwallet team's "will require a hardfork to work" comment refer to?
short_answer: There is no specific proposal. The eigenwallet team's comment refers to a class of needed primitives (CLSAG-compatible adaptor signatures, or DLSAG, or hidden timelocks) that have been discussed in Monero research but never specified, never proposed for inclusion in a hardfork, and as of 2026-05 the Monero core team has affirmed publicly that **"no scheme has been specified"** for using Monero's existing timelock feature in an atomic swap. Worse, the upcoming FCMP++ hardfork (mid-2026) is actively *deprecating* the timelock primitive, not extending it.
---

# Which Monero hardfork or feature would enable XMR-first atomic swaps?

This is the follow-on to [[projects/xmr-first-atomic-swaps]]. The eigenwallet team's protocol paper at [eigenwallet/protocol/xmr_btc_atomic_swaps.tex](../sources/2026-05-22-github-eigenwallet-protocol-xmr-btc.tex) lines 60-62 contains the comment:

> `% We don't care about swaps where the Bitcoin seller is the maker because that is unsupported by the current Monero protocol.`
> `% It will require a hardfork to work`

The natural question is: *which* hardfork, and *what* feature? The answer turns out to be that there is **no specific hardfork proposal** under discussion in Monero. The eigenwallet team's comment refers to a hypothetical primitive that has been the subject of research papers since 2019 but has never made it to a Monero release-engineering plan.

## Direct quote from Monero core on the matter (2026-05-10)

The most authoritative recent statement comes from the Monero core team's blog post on 2026-05-10, "Deprecating Monero's Custom Transaction Unlock Time" ([getmonero.org/2026/05/10/deprecating-unlock-time.html](../sources/2026-05-22-getmonero-org-deprecating-unlock-time.html) :: accessed 2026-05-22):

> *"It is a common misconception that Monero's Unlock Time is useful for known atomic swap or payment channel protocols. To date, no scheme has been specified that utilizes Monero's Unlock Time feature."*

In other words, the Monero core team **officially confirms** that no published atomic-swap scheme uses Monero's existing on-chain timelock primitive. The "hardfork-needed" hand-wave in the eigenwallet paper is not pointing at a queued feature — it is pointing at a research gap.

## Three distinct protocol gaps

To make this concrete, the three things that have been discussed in research as candidates for "what Monero would need to add" are:

### 1. CLSAG-compatible adaptor signature primitive

This is the direct cryptographic gap from Hoenisch–del Pino 2021 §4. Monero's signature scheme is **CLSAG** (Concise Linkable Spontaneous Anonymous Group), which replaced MLSAG in October 2020. CLSAG combines a ring signature with a key image for linkability. An adaptor-signature variant of CLSAG would need:

- A pre-signature that is well-formed but invalid until "adapted" with a witness `y`
- An adapt operation that converts pre-signature + `y` → valid signature
- An extract operation that recovers `y` from pre-signature + valid signature
- Witness extractability: extracting `y` is the only way to convert a pre-signature into a valid signature

**Status**: No peer-reviewed CLSAG-adaptor construction has been adopted by the Monero project. The closest published works are:

- **Consecutive Adaptor Signature Scheme (IACR 2024/241)**: introduces a 2P-CLRAS (two-party consecutive linkable ring adaptor signature) for Monero-compatible *payment channels* (MoNet). Specifically targeted at off-chain payment channels, not on-chain single-shot atomic swaps. ([archived](../sources/2026-05-22-eprint-iacr-2024-241-consecutive.pdf))
- **LTRAS (arXiv 2602.05431, Liang–Han, 2026-02)**: a Linkable Threshold Ring Adaptor Signature targeting cross-chain transactions. Theoretical with experimental validation, no production code, no Monero core team endorsement. ([archived](../sources/2026-05-22-arxiv-2602-05431-ltras.pdf))
- **MoNet (IACR 2022/744)**: payment-channel-focused, uses adaptor signatures with a "locking key" mechanism. Targets payment channels, not atomic swaps.

**Importantly**: a CLSAG-adaptor signature primitive **does not require a Monero hardfork** to deploy. CLSAG signatures themselves are the primitive — an adaptor variant is constructed off-chain in the signing protocol. So this gap is a *cryptographic research gap*, not a Monero protocol gap. The hardfork comment cannot be referring to this.

### 2. DLSAG (Dual Linkable Spontaneous Anonymous Group Signatures)

Goodell, Noether, Blue (2019), *DLSAG: Non-Interactive Refund Transactions For Interoperable Payment Channels in Monero*, IACR 2019/595 ([eprint.iacr.org/2019/595](https://eprint.iacr.org/2019/595)). DLSAG is a **new ring-signature scheme** that would replace CLSAG. It adds support for **non-interactive refund transactions**: an output can be programmed so that after a deadline, a different key can spend it without the original signer cooperating.

This is precisely the primitive an XMR-first atomic swap needs for the locked-XMR refund path: Alice locks XMR, time passes without Bob locking BTC, Alice spends the XMR back to herself non-interactively (or, more precisely, the refund leaks a secret that lets the counterparty unlock the funds without needing the original signer online).

**Status**: DLSAG is a research proposal from 2019. It has **never been integrated into the Monero codebase**, never been part of a Monero hardfork, and is not on the Monero roadmap. The Monero research-lab GitHub issues from 2020 onwards ([issue #65 "Hidden timelocks", issue #78 "Removing/Fixing/Encrypting monero's timelocks"]) discuss adjacent primitives but do not propose DLSAG adoption. The Monero project has been focused on Seraphis and then FCMP++ instead.

**A DLSAG hardfork** is the most concrete "specific hardfork" that would enable XMR-first atomic swaps. But it is not under active consideration.

### 3. Hidden / encrypted timelocks

A separate research thread (Monero research-lab issue #65, January 2020) proposes adding **encrypted timelocks** to Monero outputs. Each output would carry a Pedersen commitment to a lock time, with a range proof showing the time is in a sensible range. This would allow on-chain enforcement of time-bound spending conditions without leaking the time value publicly.

If hidden timelocks were added, an XMR-first atomic swap could use them to enforce the Alice-refunds-XMR path directly on Monero, without needing a non-interactive refund signature.

**Status**: Issue #65 has been open since 2020 with no implementation. The opposite proposal (issue #78, October 2020) — to *remove* timelocks entirely — has actually won the policy argument: the FCMP++ hardfork (planned mid-2026) will **deprecate `unlock_time`** ([getmonero.org/2026/05/10/deprecating-unlock-time](../sources/2026-05-22-getmonero-org-deprecating-unlock-time.html)). New transactions with `unlock_time > 0` will be banned by consensus after the fork.

So Monero is moving **away from** the on-chain expressiveness that XMR-first atomic swaps could exploit.

## FCMP++ is not the hardfork the eigenwallet team is waiting for

FCMP++ (Full-Chain Membership Proofs + Spend Authorization + Linkability) is the next Monero hardfork, tentatively scheduled for mid-2026. The activation rule was proposed in research-lab issue #125 (2024-10-22) and the design has gone through five revisions through 2026-01.

The natural assumption is that the eigenwallet team's "needs a hardfork" comment points at FCMP++. **It does not.**

- **kayabaNerve's FCMP++ specification gist** ([gist.github.com/kayabaNerve/0e1f7719e5797c826b87249f21ab6f86](../sources/2026-05-22-gist-github-com-kayabaNerve-fcmp-sa-l.md)) **does not mention adaptor signatures, scriptless scripts, or atomic swaps** anywhere in its design.
- **The Monero project's FCMP++ blog post** (2024-04-27, [getmonero.org/2024/04/27/fcmps.html](../sources/2026-05-22-getmonero-org-fcmps.html)) does not mention atomic swaps.
- FCMP++ is built on **Curve Trees** and elliptic curve divisors, using a **Generalized Schnorr Protocol (GSP)** and Generalized Bulletproofs. The signature primitive is fundamentally different from CLSAG — it is a *membership-proof-with-spend-authorization* scheme, not a classical ring signature.

Whether an adaptor-signature variant of FCMP++ is *possible* is an open research question. The new GSP-based primitive does have Schnorr-like structure, which is friendlier to adaptor signatures than CLSAG in principle. But:

1. No such construction has been published.
2. The FCMP++ design has not been built with adaptor signatures in mind.
3. The deprecation of `unlock_time` in the same hardfork removes the *other* primitive that an atomic swap could use.

So even after FCMP++ ships, the XMR-first atomic swap problem remains open.

## Summary table — what each candidate hardfork would deliver

| Candidate | What it adds | Enables XMR-first BTC-XMR? | Status as of 2026-05-22 |
|-----------|--------------|----------------------------|-------------------------|
| **CLSAG adaptor signatures** (off-chain construction) | A cryptographic primitive Monero already supports the inputs for | Yes, in principle — if a secure construction exists. **No Monero hardfork needed.** | Active research; no peer-reviewed, Monero-endorsed construction. Recent work (LTRAS, 2P-CLRAS) is in the right family but targets payment channels, not atomic swaps. |
| **DLSAG ring-signature replacement** | Non-interactive refund transactions natively on Monero | Yes — would directly enable the protocol Hoenisch–del Pino 2021 §4 sketches | Proposed 2019. Never implemented. Not on Monero roadmap. |
| **Hidden timelocks** (research-lab #65) | Encrypted on-chain timelock with range proof | Yes — would provide an XMR-side cancel path | Proposed 2020. Never implemented. Trend is the opposite: FCMP++ is *removing* the existing timelock. |
| **FCMP++** (the actual next hardfork) | Full-chain anonymity, spend authorization, linkability; removes unlock_time | No — does not include adaptor-signature primitive, does not include DLSAG, removes the only existing timelock | Mid-2026 tentative target; design at v0.5.2 (2026-01-08). |
| **A hypothetical future hardfork** that adds CLSAG/FCMP++-adaptor signatures *or* DLSAG | The complete primitive set for XMR-first atomic swaps | Yes | Not proposed. Not on any roadmap. |

## Why this matters for the eigenwallet team's stance

The eigenwallet team's "will require a hardfork to work" comment is, in the most charitable reading, a placeholder for *"this requires Monero protocol work that we are not going to do or wait for"*. The strict reading is that the team is aware of the DLSAG / hidden-timelocks research thread and is correctly identifying that Monero would need to add a primitive of that class.

What the comment does **not** mean is that there is a specific MRL bulletin, CCS proposal, or hardfork plan that the team is tracking. **There is not.** The Monero core team's 2026-05-10 statement *"no scheme has been specified that utilizes Monero's Unlock Time feature"* makes this concrete: the research community has not even agreed on the **shape** of the primitive that would enable XMR-first atomic swaps, let alone scheduled it for a hardfork.

## What this implies for someone building a privacy-aware cross-chain DEX

1. **Do not bet on XMR-first BTC-XMR atomic swaps shipping on Monero in the next 18-24 months.** The combined evidence — no Monero core engagement, FCMP++ removing rather than adding script-like primitives, the eigenwallet team actively *removing* the XMR-first chapter from their living protocol paper on 2025-11-04 — points to multi-year horizons at minimum.
2. **The XMR-sell-side liquidity problem remains structural.** A user holding XMR and wanting BTC must use either: (a) a centralised exchange or instant swap service (KYC), (b) a multisig-with-dispute-resolution DEX like Haveno, (c) a middle-chain settlement like [[projects/serai]], or (d) a [[projects/baltex]]-style centralised privacy-broker. No atomic-swap option.
3. **If a CLSAG-compatible adaptor signature primitive is published and peer-reviewed**, the dependence on a hardfork might dissolve — but the eigenwallet team's specific phrasing ("hardfork") suggests they see this as DLSAG-class work, not pure cryptography work, and the path to even an off-chain CLSAG-adaptor primitive being adopted by the Monero project is unclear.
4. **FCMP++ might re-open the question.** The Schnorr-like GSP structure of FCMP++ could be more amenable to adaptor-signature construction than CLSAG. If, post-FCMP++, a research group publishes an FCMP++-compatible adaptor signature, the dependency on a *new* hardfork might be smaller (the FCMP++ signature scheme itself would be the primitive). But this is speculative — no such construction exists in the public literature today.

## Sources

- **getmonero.org 2026-05-10**, *Deprecating Monero's Custom Transaction Unlock Time*. [link](https://www.getmonero.org/2026/05/10/deprecating-unlock-time.html) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-getmonero-org-deprecating-unlock-time.html). **Key quote**: *"It is a common misconception that Monero's Unlock Time is useful for known atomic swap or payment channel protocols. To date, no scheme has been specified that utilizes Monero's Unlock Time feature."*
- **getmonero.org 2024-04-27**, *Full-Chain Membership Proofs Development*. [link](https://www.getmonero.org/2024/04/27/fcmps.html) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-getmonero-org-fcmps.html). FCMP++ overview; no atomic swap or adaptor signature mention.
- **kayabaNerve gist**, *Full-Chain Membership Proofs + Spend Authorization + Linkability*. [link](https://gist.github.com/kayabaNerve/0e1f7719e5797c826b87249f21ab6f86) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-gist-github-com-kayabaNerve-fcmp-sa-l.md). FCMP++ specification; explicitly does not address adaptor signatures.
- **Goodell, Noether, Blue (2019)**, *DLSAG: Non-Interactive Refund Transactions For Interoperable Payment Channels in Monero*. IACR ePrint 2019/595. [link](https://eprint.iacr.org/2019/595). Source of the canonical "Monero needs a hardfork to enable non-interactive refunds" position. The most-cited candidate for the eigenwallet team's "hardfork" comment.
- **Monero research-lab issue #65** (2020-01-31), *Hidden timelocks*. [link](https://github.com/monero-project/research-lab/issues/65). Proposes encrypted on-chain timelocks. Open with no implementation activity.
- **Monero research-lab issue #78** (2020-10), *Removing/Fixing/Encrypting monero's timelocks*. [link](https://github.com/monero-project/research-lab/issues/78). Proposes *removing* timelocks; the policy direction the FCMP++ hardfork is taking.
- **Monero research-lab issue #125** (2024-10-22), *Proposal for FCMP++ HF Activation Rule to Retroactively Ignore Future unlock_time*. [link](https://github.com/monero-project/research-lab/issues/125). Concretises the unlock_time deprecation as a FCMP++ activation rule.
- **getmonero.org 2024-03-08**, *CLSAG security proof revisions*. [link](https://www.getmonero.org/2024/03/08/clsag-security-proof-revisions.html) :: [archived](../sources/2026-05-22-getmonero-org-clsag-security-revisions.html). State of CLSAG security proofs.
- **Hoenisch and del Pino 2021**, *Atomic Swaps between Bitcoin and Monero*, arXiv 2101.12332. [archived](../sources/2026-05-22-arxiv-org-2101-12332.pdf). §4 is the original source of the XMR-first protocol sketch and the CLSAG-adaptor-signatures-as-WIP framing.
- **eigenwallet/protocol** [xmr_btc_atomic_swaps.tex](../sources/2026-05-22-github-eigenwallet-protocol-xmr-btc.tex) lines 60-62. The active eigenwallet team's "will require a hardfork to work" comment.
- **eigenwallet/protocol** commit `6151734` (2025-11-04, binarybaron), *"remove xmr to btc protocol"*. The decision to drop the XMR-first chapter from the compiled paper.
- **Consecutive Adaptor Signature Scheme**, IACR 2024/241. [archived](../sources/2026-05-22-eprint-iacr-2024-241-consecutive.pdf). 2P-CLRAS payment-channel work; closest published CLSAG-adaptor-signature-family construction.
- **LTRAS**, arXiv 2602.05431. [archived](../sources/2026-05-22-arxiv-2602-05431-ltras.pdf). Threshold ring adaptor signatures; cross-chain focus; not Monero-endorsed.

## Cross-references

- [[projects/xmr-first-atomic-swaps]] — the parent question, "has anyone implemented this?"
- [[projects/atomic-swap-protocol-details]] — the BTC-first protocol mechanics
- [[projects/eigenwallet]] — the implementation that explicitly declined to ship XMR-first
- [[projects/serai]] — the middle-chain alternative that side-steps the direction problem
- [[patterns/ring-signatures]] — CLSAG / FCMP++ background
