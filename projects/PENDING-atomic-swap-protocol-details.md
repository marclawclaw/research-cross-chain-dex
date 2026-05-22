---
tags: [resolved, atomic-swaps, comit, eigenwallet, protocol-detail, sourcing-request]
status: RESOLVED 2026-05-22 — all 11 claims sourced/verified/contradicted; see deliverable notes
requested_by: rfp-orchestrator (fryorcraken)
requested_at: 2026-05-22
resolved_at: 2026-05-22
purpose: source protocol-level claims for `appendix/atomic-swaps-primer.md` in logos-co/rfp PR #57
deliverable_notes:
  - "[[projects/atomic-swap-protocol-details]] — claims 1-7 (atomic-swap protocol)"
  - "[[projects/stacks-sbtc]] — claim S1 (sBTC custody)"
  - "[[projects/synthetix]] — claims S2 and S4 (SIP-302 and sXMR)"
  - "[[projects/haven]] (updated) — claim S3 (Haven shutdown confirmed 2024-12-12)"
---

## Status summary (filled in 2026-05-22)

- **Claim 1 (quote phase)**: CONTRADICTED — not a protocol step; implementation convention for makers. See [[projects/atomic-swap-protocol-details]].
- **Claim 2 (BTC-locks-first by construction)**: PARTIALLY CONTRADICTED — order is driven by draining-attack economics, not by the primitive. Gugger 2020 has XMR-first. See [[projects/atomic-swap-protocol-details]].
- **Claim 3 (BTC vs XMR timelock asymmetry)**: CONTRADICTED — no XMR timelock exists (Gugger §3.1); both timelocks are Bitcoin-side. eigenwallet mainnet: 24/144 blocks. See [[projects/atomic-swap-protocol-details]].
- **Claim 4 (4-year gap from 2017 proposal)**: CONTRADICTED — TierNolan 2013, Decred-LTC 2017, Gugger 2020, COMIT mainnet 2021. The 4 years works from Decred-LTC to BTC-XMR launch. See [[projects/atomic-swap-protocol-details]].
- **Claim 5 (Han 2019 free-option)**: VERIFIED with framing caveat — paper proves equivalence to premium-free American Call Option and quantifies premium ≈ 2% for crypto pairs; does not directly attribute volume scarcity. See [[projects/atomic-swap-protocol-details]].
- **Claim 6 (production status of XMR-BTC implementations)**: MOSTLY VERIFIED — bump eigenwallet to 4.6.4 (2026-05-21); soften AtomicDEX claim. See [[projects/atomic-swap-protocol-details]] and [[projects/eigenwallet]].
- **Claim 7 (HTLC vs adaptor applicability)**: VERIFIED with refinement — HTLC also needs malleability fix (Gugger §3.2). See [[projects/atomic-swap-protocol-details]].
- **Claim S1 (sBTC custody)**: VERIFIED — 15-signer federation, 70% threshold (11/15 in SIP-028, 14/10 operating), mainnet deposits 2024-12-17. See [[projects/stacks-sbtc]].
- **Claim S2 (Synthetix SIP-302)**: VERIFIED — SIP-302 (Pools V3) is the canonical V3 CDP-minting reference. See [[projects/synthetix]].
- **Claim S3 (Haven shutdown 2024-12)**: VERIFIED — Haven Protocol announced closure 2024-12-12 after range-proof exploit; [[projects/haven]] updated to reflect this.
- **Claim S4 (Synthetix sXMR paired with Secret Network)**: CONTRADICTED — Synthetix sXMR is an SNX-collateralised oracle synth on Ethereum (Hadar 2020-03-30), unrelated to Secret Network's separate sXMR SNIP-20 wrapped-Monero token. See [[projects/synthetix]].

---


# PENDING: BTC-XMR Atomic Swap Protocol Details

The cross-chain RFP bundle (PR #57) has a new appendix
`appendix/atomic-swaps-primer.md` that describes the BTC-XMR atomic-swap
flow. Several claims in that appendix were written from inference rather
than from sourced material and need verification or correction. This
note enumerates the open claims as a sourcing request.

The RFP CLAUDE.md rule "never fabricate data; unsourced → research more"
applies; please source each claim below, or mark it as "no primary
source found, suggest removing from the appendix".

The primary candidate sources are:

- **Gugger, IACR 2020/1126** — "Bitcoin-Monero Cross-chain Atomic Swap"
  ([eprint.iacr.org/2020/1126.pdf](https://eprint.iacr.org/2020/1126.pdf))
- **Hoenisch and del Pino, arXiv 2101.12332** — "Atomic Swaps between
  Bitcoin and Monero" ([arxiv.org/abs/2101.12332](https://arxiv.org/abs/2101.12332))
- **comit-network/xmr-btc-swap** source code and `swap/src/protocol/` —
  the canonical reference implementation
- **eigenwallet/core** — active fork, current production behaviour
- **comit-network/spikes/0017-negotiation-and-execution-protocol.adoc**
  — already cited in `projects/comit.md`, may cover the quote/setup
  question directly

## Claims to verify

For each claim, please record in your atomic note one of:
- **VERIFIED** with primary source quote and URL, OR
- **CONTRADICTED** with what the source actually says, OR
- **NO PRIMARY SOURCE FOUND** (in which case the claim must be removed
  from the appendix)

### Claim 1: BTC-XMR swap has a "quote" phase as step 0

The appendix currently shows a step 0: "Quote and joint-key setup" where
Bob sends Alice a "Signed quote (price, expiry, refund pubkeys)" before
joint-key setup begins.

**Questions:**
1. Does the paper/implementation define a distinct "quote" phase, or is
   parameter agreement folded into joint-key setup?
2. Is the quote **signed** by the maker? If so, what does the signature
   cover (price + amounts? expiry? refund pubkeys?) and what does the
   signature protect against?
3. Is the signature required by the cryptographic primitive (i.e.
   without it the atomic-swap construction does not compose) or is it
   an implementation convention for non-repudiation / matching markets?

### Claim 2: BTC locks first by construction of the adaptor-signature primitive

The appendix claims BTC must be locked first because the adaptor-
signature reveal flows from BTC settlement to XMR claimability.
Specifically:

> the secret that completes the swap is an Ed25519 scalar `s` whose
> discrete log corresponds to one half of the joint Monero spend key.
> Alice's adaptor signature on a Bitcoin transaction is a signature
> with `s` factored out; Bob can adapt it into a valid signature by
> adding `s`, but the act of broadcasting that adapted signature on
> Bitcoin publishes `s` as part of the on-chain transaction.

**Questions:**
1. Is this description of the secret accurate? What is the secret
   actually (Ed25519 scalar? secp256k1 scalar? something else)?
2. Which party's signature is the "adaptor signature" — Alice's or
   Bob's? In which direction does the construction work?
3. Is BTC-locks-first a hard requirement of the primitive, or is it
   conventional? What if XMR were locked first — would the construction
   fail, or would the secret-reveal direction simply flip?
4. The appendix asserts "reversing the order does not compose." Is this
   accurate? Reference to which part of which paper supports this?

### Claim 3: Refund timelock asymmetry

The appendix claims:
> The script-side refund (Alice's BTC) typically has a shorter timelock
> than the secret-side refund (Bob's XMR), so Alice cannot wait until
> Bob has refunded his XMR and then claim Alice-side BTC anyway.

**Questions:**
1. Is the BTC-refund-shorter-than-XMR-refund relationship correct?
2. What are the canonical timelock values in the xmr-btc-swap
   implementation? Hours, blocks, configurable per swap?
3. Does the Gugger or Hoenisch paper specify the timelock ordering as a
   protocol requirement, or is it implementation policy?

### Claim 4: BTC-XMR atomic swap took ~4 years from proposal to working implementation

The appendix says "BTC-XMR specifically required about four years of
cryptographic work (2017 proposal to 2021 working implementation via
adaptor signatures over Ed25519 and secp256k1)."

**Questions:**
1. What is the 2017 origin point? Is there a specific paper, mailing
   list post, or blog?
2. The "2021 working implementation" is presumably the comit-network
   August 2021 launch announcement on getmonero.org. Confirm exact date
   and link.
3. What was the primary technical blocker that took those years?
   (Cross-curve DLEQ? Verifiable timed commitments? Implementation
   complexity?)

### Claim 5: Free-option problem citation (Han et al. 2019)

The appendix cites Han et al., IACR 2019/896, "On the optionality and
fairness of Atomic Swaps", as the literature reference for the free-
option problem.

**Questions:**
1. Confirm the citation accurately reflects the paper's argument. Does
   Han et al. actually identify the free-option as the structural
   reason atomic-swap volume has remained small, or is that a stronger
   claim than the paper makes?
2. Is there a more authoritative or earlier reference?

### Claim 6: Production status of XMR-BTC implementations

The appendix lists:
- COMIT `xmr-btc-swap`: unmaintained since 2024-11
- eigenwallet `core`: v4.6.1, 2026-05-15
- Farcaster: last release v0.8.4, 2023-01-16
- AtomicDEX/Komodo: "no significant recent BTC-XMR volume"
- Liquality: discontinued 2024-06-15

**Questions:**
1. The COMIT status is already verified in `projects/comit.md` —
   confirm that note's facts cover this primer's claim.
2. Verify eigenwallet's current release version and date.
3. Verify Farcaster's last release.
4. The AtomicDEX/Komodo claim "no significant recent volume" is too
   vague to source. Either find a volume citation or weaken the claim
   to a verifiable status (e.g. last release date).
5. Verify Liquality's discontinuation date and link.

### Claim 7: HTLC vs adaptor-signature applicability

The appendix says HTLC works for "script-compatible pairs" and adaptor
signatures generalise to pairs "where one side has restricted scripting
(e.g. Monero)."

**Questions:**
1. Is this dichotomy accurate? Are there pairs where neither HTLC nor
   adaptor signatures work?
2. Decred-Litecoin 2017 first-on-chain HTLC swap — confirm the date and
   the Decred blog URL already cited.

## Deliverable

Either an atomic note per claim in `projects/` or `patterns/` (whichever
fits the vault's existing structure), or a single revised version of
this file with each claim marked VERIFIED / CONTRADICTED / NO SOURCE
plus the source quotes.

Once verified, the orchestrator will edit `appendix/atomic-swaps-primer.md`
in `~/src/logos-co/rfp/` to reflect the sourced facts and remove anything
that could not be verified.

---

# Additional pending: sBTC (Stacks) and Synthetix detail

For the synthetics survey appendix `appendix/synthetics-design-space.md`
in PR #57, the bundle's prior text makes several claims about sBTC
(Stacks) and Synthetix that need sourcing before they can be re-stated
verbatim. Please produce a `projects/stacks-sbtc.md` and a
`projects/synthetix.md` atomic note in the vault (if not already
present), or revise existing notes, to cover:

### Claim S1: sBTC trust model

The bundle states sBTC is "redeem-to-underlying with custody". Confirm:
1. What is the actual custody arrangement? Threshold-signer multisig?
   PoX-stacked stackers? How many signers? What is the threshold?
2. What is the redemption guarantee shape (is there an SLA, a queue,
   a market-clearing process)?
3. Confirm the canonical citation. The bundle currently cites
   `docs.stacks.co/learn/sbtc` — verify this URL is the official docs
   page for sBTC and quote a 1-line description directly from it.
4. What is the BTC-side privacy property of redemption (does sBTC
   redemption deposit BTC at a specifically-trackable address, or is
   it routed)?

### Claim S2: Synthetix SIP-302

The bundle currently cites SIP-302 for "V3 collateral and snxUSD
minting (CDP reference)". Confirm:
1. Does SIP-302 cover the CDP minting model accurately, or is this
   citation drift?
2. What is the canonical Synthetix minting reference (white paper,
   docs, or a specific SIP)?

### Claim S3: Haven Protocol shutdown

The bundle currently states "Haven Protocol shutdown notice (December
2024; historical xAsset family of privacy-chain synthetics)". The vault
project note (`projects/haven.md`) shows XHV market cap ~$5.5M and
xUSD supply ~$1.2M as of 2026-05-22, with the protocol still apparently
operational. Confirm:
1. Did Haven Protocol shut down in December 2024 or not?
2. If not shut down, what is the actual status?
3. If shut down, what is the primary source for the shutdown
   announcement?

### Claim S4: "Closest prior art is custodial: Synthetix's historical
   sXMR token paired with the Secret Network Monero Bridge"

The bundle claims Synthetix had a historical sXMR token paired with
the Secret Monero Bridge. The vault note on Secret Network mentions an
sXMR SNIP-20 on Secret Network specifically, not on Synthetix. Confirm:
1. Did Synthetix ever list an sXMR synth? When? What was its trust
   shape (Synthetix CDP-collateralised, or Secret Network bridge-
   wrapped)?
2. Is the bundle's claim that Synthetix paired *its* sXMR with the
   Secret Monero Bridge accurate, or is the sXMR-on-Secret a separate
   product?

Once these are sourced, the orchestrator will edit
`appendix/synthetics-design-space.md` in `~/src/logos-co/rfp/`.
