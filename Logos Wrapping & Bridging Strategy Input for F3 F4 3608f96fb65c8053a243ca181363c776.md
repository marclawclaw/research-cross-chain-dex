# Logos Wrapping & Bridging: Strategy Input for F3/F4

**Author:** @Martin Strobl 
**Date:** 14 May 2026

*Note: Apologies for the AI patterns and structure — assembled under time pressure, but every claim is carefully sourced, fact-checked and curated.*

## 1. Purpose & Scope

This document is R&D / strategy input on the wrapping and cross-chain architecture that frames Flywheels 3 (Private Assets DeFi) and 4 (Trustless Swaps on Private Assets). It exists because the BD pipeline needs an architectural boundary inside which partner conversations (Mezo, Threshold, Cypher Stack, Cake, etc.) are coherent.

## 2. The Architectural Split

The wrapping problem decomposes into two asymmetric sub-problems. 

### 2.1 Inbound vs outbound asymmetry

**Inbound** — proving source-chain state to LEZ. A deposit happens on Bitcoin or Ethereum or Zcash; LEZ needs to know it happened, at what block, with what payload. This is fully solvable with ZK light clients today: ZeroSync, Citrea's Clementine LCP, Polyhedra zkBridge, Succinct SP1, and various RISC0-based Ethereum block provers all demonstrate the pattern. LEZ's RISC0 zkVM makes this a natural fit. **No signer set is required for inbound.**

**Outbound** — releasing source-chain funds when LEZ contracts authorise it. Burn wrapped BTC on LEZ → release native BTC to a user-supplied address on Bitcoin. *Someone has to produce a Bitcoin signature.* Bitcoin Script cannot verify a ZK proof in consensus. Neither can Monero or Zcash. This is structurally a multi-party signing problem.

The minimum-trust outbound options are:

- **BitVM2-style optimistic operators** — 1-of-n honesty assumption; pre-production
- **Babylon-secured threshold signers** — cryptoeconomic security via slashable BTC stake; untested at scale
- **Threshold-network-style sortitioned committees (tBTC v2)** — 51-of-100 honest-majority; production
- **FROST/CGGMP MPC over Logos validators** — requires building new signer infrastructure

This is the irreducible compromise surface. Logos wrapping design can also be a hybrid: ZK-verified inbound, multi-party-signed outbound.

### 2.2 Three primitive types

Next, the architecture resolves into three orthogonal primitive types, each with different principle implications:

1. **Chain-watching light-client modules** — verify external-chain state inside LEZ. Pure inbound, principle-aligned, no signer set in the verification path. Examples: `eth-light-client` (possibly ethnimbus-fluffy), `btc-light-client` (forkable from ZeroSync or Citrea LCP), eventually `zec-light-client` (research-grade, depends on ECC research progress). XMR has no comparable primitive.
2. **Atomic-swap modules per pair** — one-shot trustless exchange between LEZ and an external chain via cryptographic atomicity. [RFP-003 deliverables.](https://github.com/logos-co/rfp/blob/master/RFPs/RFP-003-atomic-swaps.md) Non-custodial, no wrapping, no persistent position. Suitable for "user wants to swap X for Y once" but *not* for "user wants to deposit X and use it as collateral."
3. **Wrapped-asset modules** — persistent wrapped positions on LEZ, redeemable to the source asset. Required for F3's "wrap → collateralise → borrow" thesis. Outbound signing is the irreducible compromise here. Per-asset feasibility varies wildly.

A fourth quadrant — external-messaging integration (LayerZero / Wormhole / CCIP / Axelar / Hyperlane / Across) — is discussed in §6 below but is *not* a current Logos workstream. Logos should make itself technically easy to integrate and then let these providers come to us on their own initiative once Logos has volume worth their integration effort.

### 2.3 Why this split matters for BD

The three primitive types map to three different partner conversations and three different principle stories:

- Light-client modules → "we ship verifiable views of external chains; nothing to compromise"
- Atomic-swap modules → "we ship RFP-003; cryptographic atomicity; nothing to compromise"
- Wrapped-asset modules → "feasibility varies per asset; on BTC we have an explicit choice to make about trust; on XMR we don't wrap at all; on ZEC we wait for ZSAs"

---

## 3. Per-Asset Feasibility Under Logos Principles

### 3.1 ETH

**Inbound:** Ethereum consensus + state proof inside RISC0 guest. Mature: Zeth, Succinct's Telepathy, Polyhedra's zkBridge all do this. The `eth-light-client` Basecamp module is the natural home.

**Outbound:** Ethereum verifies ZK proofs natively (precompiles, Groth16 verifier on-chain). A burn on LEZ can be proven to Ethereum and the wrapped position released via pure validity-proof verification. **No signer set required in either direction.**

**Principle verdict:** Fully principle-aligned. The cleanest cypherpunk wrapping design anywhere in the ecosystem.

**Strategic observation:** Shipping weth-on-lez with full ZK on both sides, minting directly into LEZ private state, would be the first private-execution chain with validity-proven wETH roundtrip — a real positioning wedge for F3.

**BD framing:** "Logos ships principled wETH wrapping with full ZK on both inbound and outbound. Mint into LEZ private state, redeem to any Ethereum address via validity proof. No signer set, no honest-majority assumption, no challenge window."

### 3.2 BTC

**Inbound:** RISC0 Bitcoin header-chain light client. Fork ZeroSync's headers proof or Citrea's Clementine LCP. BOB already runs unmodified RISC0 circuits in its BitVM2 prover, so the integration path is known. **Principle-aligned.**

**Outbound:** This is the hard one. Four options ranked by trust-minimisation:

| Option | Trust assumption | Status | Engineering cost | Principle posture |
| --- | --- | --- | --- | --- |
| BitVM2 operators | 1-of-n optimistic | Testnet (Citrea Apr 2025; BOB / Bitlayer similar) | High | Strongest |
| Babylon-secured signers | Slashable BTC stake | Live but slashing untested at scale | Medium | Strong |
| tBTC v2 | 51-of-100 honest-majority | Production, multi-chain | Low (consume as-is) | Compromised |
| FROST/CGGMP over Logos validators | Honest-majority of Logos validators | Greenfield build | High (key refresh, audit) | Conditional on validator set |

**Principle verdict:** Inbound is clean. Outbound forces a choice. tBTC v2 is the fastest path but accepts an honest-majority assumption on a committee — that's a compromise even though it's the best-in-production option. BitVM2 is the principled answer at scale, but it's not production-ready. 

**BD framing options** (this is where §4 strategy options bite):

- *Wait:* "We ship `btc-light-client` now. wBTC outbound ships when BitVM2 or Babylon mature."
- *Compromise:* "We ship via tBTC v2 outbound. Honest-majority on the BTC release side. Privacy primitive on LEZ is the differentiator, not the BTC custody."
- *Transition:* "We ship v1 via tBTC v2 as a partner integration; v2 is BitVM2 or Babylon; migration path is 1:1 redeemable."
- *Default:* "We don't ship; LayerZero or Wormhole will deploy their wBTC into Logos with their own signer sets."

### 3.3 XMR — cannot wrap

**Inbound:** Monero has no useful primitive for an SPV-style proof. Ring signatures + confidential amounts + one-time stealth addresses mean an external observer cannot prove "address Y received amount X" without view-key sharing. FCMP++ research is interesting but pre-production.

**Outbound:** Worse. Any signer set custodying XMR must coordinate spend authority over outputs they cannot publicly identify. View-key-shared multisig is the only deployable model and it leaks the deposit history to the signer set — which is the privacy break Monero users are paying to avoid.

**Principle verdict:** Wrapping XMR under any signer-set model breaks the privacy assumption XMR holders hold. There is no principled wrapping design currently feasible.

**What we can ship instead:**

- RFP-003's `LEZ-XMR` atomic-swap module: trustless one-shot exchange via Ed25519 adaptor sigs + cross-curve DLEQ proofs. Non-custodial. This covers the user journey of "I have XMR, I want to do a thing on LEZ" via swap, not wrap.
- Atomic-swap rail integration (Eigenwallet, Haveno, COMIT lineage) for on/off ramps.
- *Research:* if FCMP++ ships in deployable form, revisit.

**BD framing:** "We don't wrap XMR. We ship trustless XMR↔LEZ atomic swaps. XMR collateral on LEZ is a problem nobody has solved cryptographically; we won't ship a custodial pretender." Anything below the cryptographic stndard will likely kill the conversation with Monero-native crowd.

**Implication for F3 thesis:** The "wrap → collateralise → borrow" is not feasible at the moment. The atomic-swap route still serves Monero users for one-shot DeFi interactions.

**Adjacent product worth flagging: synthetic XMR price exposure on LEZ.** A separate primitive worth naming explicitly because it's the closest thing to "XMR-flavoured collateral position on LEZ" that doesn't break principles. The shape:

- A LEZ-native asset (`sXMR` or similar) that *tracks the price of XMR via oracle*, collateralised by something else — USDC, ETH, LOGOS, or a basket. Synthetix-style or Liquity-style design.
- No real XMR is held anywhere. No signer set, no custody, no view-key sharing.
- The token can be held in LEZ private state. User gets shielded XMR-price exposure plus the full LEZ DeFi surface (collateralisation, borrowing, leverage, structured products).
- Redemption: user closes the position for the collateral asset, not for XMR. If they want XMR exposure outside LEZ afterwards, they atomic-swap (via RFP-003) into real XMR.

There is no claim that real XMR backs the token. It's an explicit derivative, not a promise. The trust assumption is the oracle and the collateral solvency.

**Who this serves:** users who want XMR price exposure inside shielded DeFi without holding the underlying. Not the XMR maximalist who wants to keep actual XMR while borrowing against it — that's the audience for whom no principled product exists, and we should be honest about that. 

### 3.4 ZEC

**Background.** Zcash's shielded-pool privacy uses zero-knowledge proofs (zk-SNARKs) to hide sender, receiver, and amount. Since the NU5 network upgrade (May 2022), the active shielded pool is **Orchard**, which uses a proof system called **Halo 2** developed by the Electric Coin Company (ECC). The relevant technical properties:

- **Halo 2** is a SNARK proof system over the **Pallas / Vesta curve cycle** (a pair of elliptic curves where each one's scalar field equals the other's base field — a structure that enables efficient recursive proof composition).
- **No trusted setup** is required since NU5 — a meaningful improvement over earlier Zcash pools (Sprout, Sapling), which relied on a multi-party trusted-setup ceremony. "No trusted setup" means there's no shared secret that could compromise the system if leaked. Important for cypherpunk credibility.
- **Recursion-friendly** means a Halo 2 proof can verify another Halo 2 proof inside itself, cheaply. This is what makes the technical idea of "prove Zcash state inside another proof system" tractable at all.
- **Orchard spend authority** is governed by Orchard spend keys held by users; producing a valid spend requires a signature plus a ZK proof of authorisation. Multi-party Orchard spend means coordinating both the signature *and* the proof across the signer set without leaking note contents.
- The **transparent pool** is a separate construction: it uses secp256k1 ECDSA, same as Bitcoin. This split matters for wrapping — transparent-pool ZEC is reachable via existing ECDSA primitives; shielded-pool ZEC requires the RedPallas + Halo 2 stack above.

**Inbound (proving Zcash state to LEZ):** Still research-grade. Two routes:

1. **Composition route.** A Halo 2 proof of Zcash shielded-pool state (e.g., "this commitment exists in the Orchard note-commitment tree at block N") gets verified *inside* a RISC0 guest. The guest then emits a RISC0 STARK that LEZ verifies. This sandwiches Halo 2 inside RISC0.
2. **Direct verification route.** LEZ verifies the Halo 2 proof directly (no RISC0 wrapping), via a Halo 2 verifier circuit deployed on LEZ.

This is hard in practice:

- **Curve arithmetic mismatch.** Halo 2 uses Pallas/Vesta. RISC0 STARKs use different field arithmetic. Verifying Pallas operations inside a RISC0 guest is expensive (every elliptic-curve point operation has to be simulated in arithmetic native to RISC0), and verifying STARK arithmetic inside a Halo 2 verifier is similarly expensive in the other direction.
- **No production reference.** Several research projects explore this composition but none is production at scale.
- **Engineering surface.** Even with the math worked out, the implementation is a custom circuit requiring deep ZK cryptography expertise and a serious audit budget.

**Outbound (releasing ZEC from a LEZ-controlled position):** 

- Cypherpunk grade — FROST adapted to RedPallas (research). A signer set holds threshold shares of an Orchard spend key. When LEZ authorises a ZEC outbound, the signer set co-produces a RedPallas spend signature plus the accompanying Halo 2 spend proof — distributed ZK proof generation is arguably the harder problem than the threshold signature itself. Threshold semantics: t-of-n signers can produce the signature and proof together; fewer than t cannot, and no party ever reconstructs the full spend key. Additional cryptographic challenges:
    - Nullifier handling under threshold signing is delicate. Orchard nullifiers prevent double-spending; producing them correctly in a threshold setting without leaking note contents (or nullifier-deriving key shares) to the signer set is open research.
    - No production deployment of FROST-style multi-party Orchard spending exists — i.e., spending without any single party ever reconstructing the spend key.
    - ZecShield ([link](https://forum.zcashcommunity.com/t/grant-application-zecshield-universal-privacy-bridge-between-solana-and-zcash/55232)) is the closest active workstream targeting this design — a ~$48k grant request (May–December 2026) proposing a Solana ↔ Zcash bridge. However, its MVP explicitly defers FROST and any validator/threshold-signing components to later phases.
    - Trust assumption when shipped: honest-majority on the signer set, cryptoeconomically secured if validators stake. Same caveats as the BTC FROST case (§3.2).
- Honest-majority MPC grade — chain-signatures / TSS vault networks (live today). Distinct from FROST: the signer set runs distributed key generation, but the spend key is reconstructed (in some MPC schemes momentarily, in others held as a TSS-shared secret with full signing capability) during signing. Production deployments exist today via partner infrastructure — these are what currently power shielded-ZEC off-ramps for end users.
    - Trust assumption: honest-majority of the operator/validator set, plus the additional caveat that the threshold scheme exposes more of the key material during signing than FROST does. Stronger trust assumption than FROST, weaker than single-operator custody.
- Single-operator grade — custodial wrappers (live, not recommended). One operator holds ZEC, mints an ERC-20 wrapper. Trust = the operator. Politically toxic for the F3/F4 BD audience.

**Principle verdict:** Trustless / FROST-grade ZEC outbound is research-grade and 12-24 months from production at best. Honest-majority MPC ZEC custody is available today through partner integrations under explicit honest-majority assumption. 

**Worth noting: ZSA,** Zcash Shielded Assets (**ZIP 226 / ZIP 227**), currently in development, specify a primitive for issuing **arbitrary fungible assets natively inside the Orchard shielded pool**.

When ZSAs ship:

- Any token (USDC, a Logos-native asset, an RWA token, whatever) can live *inside Zcash's existing shielded pool* with the same privacy properties ZEC itself has.
- The asset issuer registers the asset; users hold and transact shielded balances of it directly on Zcash; redemption is governed by the issuer's policy.
- This **inverts the wrapping direction.** Instead of "ZEC needs to escape Zcash to participate in DeFi," the natural play becomes "DeFi assets enter the Zcash shielded pool as ZSAs to gain Zcash's privacy." Zcash can be the destination.

For Logos specifically: LEZ-native assets become candidates for ZSA issuance into Orchard. The LEZ → Orchard issuance flow is conceptually similar to a wrapping primitive in reverse — Logos burns or escrows a LEZ asset, ECC's ZSA infrastructure mints the corresponding ZSA inside Orchard. 

ZSA timeline depends on Zcash protocol governance and ECC engineering capacity. Best-guess production timeline is 12-18 months from now, though estimates from Zcash community vary.

**Do ZSAs unblock ZEC → LEZ wrapping?** No, ZSAs are a Zcash-side *issuance* primitive: they let an issuer mint a new fungible asset directly inside Orchard. They do not move ZEC off Zcash, and they do not provide threshold signing or custody primitives for ZEC outbound. The original outbound problem (multi-party Orchard spend on real ZEC) remains exactly as before.

**Adjacent product — synthetic ZEC price exposure on LEZ (`sZEC`).** Mirroring the `sXMR` pattern in §3.3. A LEZ-native asset that tracks the ZEC price via oracle, collateralised by USDC / LOGOS / a basket, held in LEZ private state, composable across the LEZ DeFi surface. 

**What we can ship:**

- **Near term:** scope an RFP-003 extension (or follow-up RFP) for LEZ↔ZEC transparent-pool atomic swaps — same adaptor-signature primitive as LEZ↔BTC, principled and Logos-native, made possible by the transparent pool's secp256k1 base. A shielded-pool atomic swap would require a cross-curve DLEQ between secp256k1 and Pallas, which is open research (the same kind of cryptographic gap §3.3 flags for XMR's Ed25519 ↔ secp256k1 case). For shielded ZEC flows specifically, integrate honest-majority MPC partner networks (TSS-vault and chain-signatures providers) as one-shot off-ramps. These are not atomic swaps: the user trusts the partner's validator/operator set during the swap, but the end state is real ZEC on Zcash or a LEZ asset on LEZ, never a persistent wrapped ZEC token on LEZ.
- **Medium term:** collaborate with ECC and the Zcash Foundation on Halo 2 ↔ RISC0 proof composition research, and track FROST-RedPallas progress (ZecShield, ECC R&D).
- **Long term:** when ZSAs ship, build the LEZ → Orchard ZSA issuance flow. This is the reverse direction from what the F3 thesis currently assumes — needs verification if attractive as a product.

### 3.5 Per-asset summary table

| Asset | Inbound | Outbound | Principle posture | Near-term ship |
| --- | --- | --- | --- | --- |
| ETH | RISC0 ETH light client | Native ZK verification | Fully principled | wETH module + RFP-003 ETH leg |
| BTC | RISC0 BTC header-chain LC | Compromise required (§4) | Inbound principled; outbound choice-dependent | `btc-light-client` module + RFP-003 BTC leg; wBTC pending §4 decision |
| XMR | No useful primitive | No principled custody | Wrap is incompatible | RFP-003 XMR leg + optional `sXMR` synthetic price-tracking asset; no wrapping |
| ZEC | Halo 2 ↔ RISC0 (research) | FROST/Orchard (research) | Research-grade | Maya / NEAR Intents integration + optional `sZEC` synthetic; LEZ→Orchard ZSA issuance flow when ZSAs ship |

---

## 4. Strategy Options for BTC

**The active compromise question is BTC outbound.** This section frames four explicit options, including what we should tell partners under each.

The framing applies equally to any future wrapped asset where the outbound side lacks a principle-pure design.

### 4.1 Option A — Wait

**What it means:** Ship only principle-aligned primitives. `btc-light-client` Basecamp module now; wBTC outbound deferred until BitVM2 or Babylon (or a Bitcoin SNARK opcode) reach production at meaningful scale.

**Engineering cost:** Lowest. Inbound module + LEZ private-state mint primitive only.

**Principle cost:** Zero.

**Opportunity cost:** Highest. If F3's BTC use case (wrap → collateralise → borrow) doesn't ship for the entire wait window competitors may capture BTC users in the meantime.

**Strategic risk:** If we don't ship, LayerZero / Wormhole / a tBTC-on-Logos community deployment ships *for* us, with trust assumptions we didn't choose.

**BD framing:** "We ship `btc-light-client` as a Basecamp module now. wBTC follows when BitVM2 production matures. Until then, F3 BTC users route via atomic swap (RFP-003), not wrapped position." Narrows F3's near-term BTC market to swap users only.

### 4.2 Option B — Compromise now, lock in permanently

**What it means:** Ship wBTC via tBTC v2 outbound integration as the canonical Logos wBTC. Accept 51-of-100 honest-majority on the BTC release side. Frame the privacy primitive on LEZ as the differentiator, not the BTC custody.

**Engineering cost:** Lowest functional. tBTC v2 already deploys on Ethereum, Arbitrum, Optimism, Polygon, Solana, Base. Adding LEZ as a destination requires Threshold Council approval + Bank balance / L2 logic + LEZ-side private-state mint integration.

**Principle cost:** High and permanent. tBTC's honest-majority assumption becomes the trust floor for all Logos wBTC. Hardcore BTC holders will note this, undermines "Logos is cypherpunk" pitch.

**Opportunity cost:** Lowest. wBTC ships fast; F3's wrap-collateral-borrow thesis works on day one.

**Strategic risk:** Hardest to reverse. Once tBTC-on-Logos wBTC has TVL and integrations, replacing it with a more-principled outbound requires migrating user funds, which is operationally painful and politically fraught.

**BD framing:** "Logos wBTC uses Threshold Network for BTC custody — 51-of-100 sortitioned committee, T-token bonded. The Logos differentiator is the private-state primitive that mints into LEZ. Privacy is what we ship."

### 4.3 Option C — Partner now, build parallel, transition as upgrade

**What it means:** Ship v1 via a partner integration (tBTC v2 or similar) while engineering v2 (BitVM2-based or Babylon-secured or FROST-over-Logos-validators) in parallel. Migrate users via an explicit upgrade path with backwards-compatible UX.

This is the middle path. It buys time-to-market without permanently locking in the compromise.

**For "upgrade as transition" to work the migration must satisfy concrete criteria:**

- **User UX continuity:** Same wBTC token, same address, same balance. Users don't see the migration as a forced action.
- **Provably-strictly-better trust:** v2's trust assumption must be unambiguously stronger than v1's, with a public threat-model document. Otherwise the "upgrade" framing is dishonest.
- **Forced sunset of v1:** v2 supply replaces v1 supply on a known timeline. If v1 outbound remains live indefinitely, users on v1 inherit the original compromise permanently.
- **Pre-committed migration spec:** Engineering and BD must agree the v2 design *before* v1 ships with the partner willing to phase out their implementation.

**Engineering cost:** Medium-to-high. Two outbound infrastructures need to exist simultaneously during the migration window, plus migration tooling.

**Principle cost:** Time-bounded. The compromise exists during the v1 window but is committed to dissolve on a known timeline. This is materially different from Option B.

**Opportunity cost:** Low. F3's BTC use case works from v1 onwards.

**Strategic risk:** 

- *Migration slippage.* If v2 doesn't ship on schedule (BitVM2 doesn't mature, Babylon slashing fails an adversarial test, FROST audit drags), v1 silently becomes permanent. The discipline question is whether to sunset v1 or just keep it running.
- *Trust narrative whiplash.* Telling users "we use tBTC; trust us, it's temporary" requires sustained communication discipline across BD, marketing, and engineering. Easy to lose the thread.
- *Engineering double-load.* Running v1 + building v2 + planning migration is a real engineering tax that competes with other Logos workstreams.

**BD framing:** "Logos wBTC v1 ships via Threshold Network as a partnership. v2 is a Logos-native outbound (BitVM2 / Babylon-secured / FROST validator set) targeting [date]. Migration is 1:1, backwards-compatible, and the v1 path sunsets on [date]. The trust posture during the v1 window is honest-majority on the Threshold committee; from v2 onwards it's [stronger assumption]." This is the framing that gives BTC maxis something they can endorse *conditionally*, which is better than a hard kill.

### 4.4 Option D — Default (do nothing actively, accept the consequences)

**What it means:** Logos doesn't ship canonical wBTC. Third-party bridges (LayerZero deploys, Wormhole deploys, a community tBTC-on-Logos deployment) populate the wrapped-asset surface on Logos with their own signer sets and trust assumptions.

**Engineering cost:** Zero.

**Principle cost:** *Out of Logos's hands.* Whoever deploys first defines the trust expectation. Users land on whatever has liquidity, which historically is whatever the largest bridge deploys first.

**Opportunity cost:** Logos cedes the wrapped-asset narrative to third parties. The F3 wedge thesis is owned by whichever bridge gets there first.

**Strategic risk:** The most likely actual outcome if leadership doesn't make an active decision or avoids further engineering costs.

**BD framing:** None as there's nothing to pitch. Partners discussing wrapped BTC on Logos default to talking about whichever third-party bridge they prefer. Logos becomes a destination chain in the LayerZero / Wormhole / Axelar story rather than a source of cypherpunk-grade wrapping.

### 4.5 Recommended strategy

**For BTC: Option C (partner now, build parallel, transition as upgrade)** is the most defensible position *if* IFT commits to the migration spec upfront and assigns headcount to the v2 build.

The reasoning:

- Option A defers F3 BTC indefinitely and lets Option D happen anyway
- Option B locks the compromise permanently and creates a credibility gap with cypherpunk gatekeepers
- Option D is what we get if we don't choose
- Option C is the only path that ships F3 BTC near-term while preserving the cypherpunk story long-term

**Option A (wait)** is an alternative if we are willing to accept a future market where a custodial wrapped BTC (adopted via Option D) exists alongside a principle-driven non-custodial BTC product (that is more niche).

---

## 5. RFP-003 in closer detail

[RFP-003: Atomic Swaps with LEZ](https://github.com/logos-co/rfp/blob/master/RFPs/RFP-003-atomic-swaps.md) is the existing Logos RFP that delivers trustless LEZ↔BTC, LEZ↔XMR, and LEZ↔ETH atomic swaps. 

- **LEZ↔BTC** via Schnorr adaptor signatures (BIP-340) + Taproot key-path spends (BIP-341). No HTLCs, no custom scripts. Swap txs indistinguishable from normal Taproot payments.
- **LEZ↔XMR** via Ed25519 adaptor signatures + cross-curve DLEQ proofs (h4sh3d / COMIT protocol). Monero spend-key share transfer; no on-chain scripting on the Monero side.
- **LEZ↔ETH** via HTLCs or adaptor signatures, using the Logos Ethereum module.
- **LEZ escrow** as a RISC0 guest program holding funds contingent on the appropriate cryptographic proof per chain.
- **Coordination** via Logos Delivery (maker liquidity advertisement) + Logos Chat (maker/taker coordination). No central server.
- **Per-pair SDKs** explicitly intended to be "buildable into Logos modules" — the deliverables are module-shaped by design.

This is genuinely the cypherpunk solution at its purest with cryptographic atomicity, non-custodial, no signer set, no bridge.

---

## 6. Basecamp-Module Framing

The Logos architectural shape is modular by design: Nimbus as ETH light client, similar potential for BTC and beyond. Wrapping and cross-chain primitives map onto this naturally, and the framing matters for BD because "we ship modules" is a different story from "we ship a bridge."

### 6.1 Three primitive types as Basecamp modules

**Type 1 — Chain-watching light-client modules**

- `eth-light-client` (Nimbus-derived; the ethnimbus-fluffy precedent). Verifies Ethereum consensus + state inside LEZ.
- `btc-light-client` (forkable from ZeroSync's headers proof or Citrea's Clementine LCP). RISC0 Bitcoin header-chain prover, exposed to LEZ contracts as a verified primitive.
- `zec-light-client` (research-grade; depends on Halo 2 ↔ RISC0 composition work with ECC). Far horizon.
- No equivalent for XMR — the chain primitive doesn't support it.

These modules are pure inbound. They expose a single capability to LEZ contracts: "is transaction T at block H confirmed on chain C." Any higher-level primitive (atomic swap, wrapping, oracle) consumes the light-client module for verification.

**Type 2 — Atomic-swap modules per pair**

RFP-003 deliverables: `lez-btc-swap`, `lez-xmr-swap`, `lez-eth-swap`. The RFP explicitly specifies these as per-pair SDKs "buildable into Logos modules for interacting with that pair's swap protocol." Module-shaped by design.

Future RFPs extend the pattern to additional pairs (LEZ↔ZEC, LEZ↔LTC, LEZ↔SOL, etc.) as user demand justifies.

**Type 3 — Wrapped-asset modules**

`weth-on-lez` (principled, full ZK) and `wbtc-on-lez`as examples.

Each wrapped-asset module consumes the relevant chain-watching light-client module for inbound proof, and exposes mint/burn primitives to LEZ contracts. The private-state mint primitive (LEZ-side) is the key cypherpunk differentiator that lets the wrapped position live in private state.

### 6.2 External-messaging protocols

LayerZero, Wormhole, Chainlink CCIP, Axelar, Hyperlane, Across, Polyhedra, Succinct — the existing cross-chain messaging ecosystem — are **not** in the Logos primitive set.

The argument:

1. **Don't compete on commodity infrastructure.** Generic cross-chain messaging is a contested commercial market where Logos has no defensible advantage.
2. **If Logos gains traction, the bridges integrate Logos anyway.**
3. **But:** when bridges deploy to Logos, they will deploy *their* wrapped models with *their* signer sets. If Logos hasn't shipped canonical wrapping primitives, the third-party wrapped versions become the default, and Logos cedes the wrapped-asset trust narrative. This is Option D in §4.4.

### 

---

## 7. Namada in closer detail

### 7.1 What Namada is

Namada is a proof-of-stake L1 launched on mainnet in December 2024. Built by Heliax / Anoma Foundation. CometBFT consensus, ~141 validators at mainnet, NAM as the native token.

The core primitive is the **Multi-Asset Shielded Pool (MASP)** — a generalisation of Zcash's Sapling shielded pool that supports arbitrary asset types inside a single shielded set. Technical shape:

- Zk-SNARK circuit derived from Zcash's Sapling Spend / Output circuits, extended with an asset-type commitment in each note so multiple assets can share one anonymity set.
- Groth16 proofs over the BLS12-381 curve. Trusted setup inherited from Sapling's MPC ceremony (so not "no trusted setup" in the Halo 2 sense).
- A **Convert circuit** that allows shielded conversions between asset types at protocol-defined ratios — used to mint shielding rewards (you hold a shielded asset, you accrue a "reward asset" that can be converted at a public ratio).
- All shielded assets share **one anonymity set**, regardless of underlying chain origin. This is the structural advantage over Zcash (one pool per asset type) and Tornado-style mixers (one pool per denomination).

The user-facing pitch: deposit any IBC- or Ethereum-bridged asset into the MASP, transact shielded, withdraw on either chain. Shielding rewards (paid in NAM) incentivise users to keep balances inside the pool, deepening the anonymity set.

### 7.2 How Namada bridges assets in

Two routes today:

**IBC (Cosmos):** Standard IBC channels with chains like Cosmos Hub, Osmosis, Stride. Trust model = IBC light clients (Tendermint light client on each side). This is the principled route, same trust as any IBC transfer — no extra signer set, validity proven by the IBC protocol. Asset coverage is whatever's reachable via IBC: ATOM, OSMO, TIA, USDC via Noble, etc.

**Ethereum bridge:** A validator-set-multisig design inspired by **Cosmos Gravity Bridge**. Specifically:

- Each Namada validator runs an Ethereum full node and watches the Ethereum bridge smart contracts for events.
- When a user deposits an ERC-20 on the Ethereum side, all validators observe the event; once ≥2/3 voting power has attested to it, the wrapped ERC-20 is minted on Namada.
- Withdrawals work the inverse way: a withdrawal on Namada produces an event that ≥2/3 of validators co-sign via a Bridge smart contract on Ethereum, which releases the locked ERC-20.
- Validator-set updates on the Ethereum side use a snapshot-and-relay pattern: when the Namada validator set changes, the Ethereum contract is updated with a new signer set (≥2/3 of the *old* set must sign the *new* set).

So Namada's Ethereum bridge trust assumption is **honest-majority of the Namada validator set**, secured by NAM staking. Same shape as Cosmos Gravity, Axelar, Wormhole's guardian set — just bound to Namada's own validators rather than a separate guardian committee.

The Ethereum bridge has been in spec / development since 2022 and shipped in stages; live wrapped-ERC20 flows are limited compared to the IBC route. NAM exists on Ethereum as wNAM (ERC-20) via this bridge.

### 7.3 How Namada tackled the wrapping problems we discuss

It's worth being explicit about the trust assumptions side by side.

| Asset class | Namada's approach | Our doc's verdict |
| --- | --- | --- |
| Cosmos / IBC assets | IBC light client (principled, full cryptographic verification) | We'd likely ship the sameif in scope |
| Ethereum ERC-20s | Validator-set multisig (honest-majority of Namada validators) | We'd consider it too but non-custodial solution available via zk-proving |
| Bitcoin | No native BTC bridge. Routed via IBC partners like Nomic, Babylon-issued bBTC, or as ERC-20 wBTC over the Ethereum bridge | Wait for BitVM or use tBTC |
| Monero | No XMR support. Not on roadmap. | No principled wrapping primitive exists |
| Zcash | No native ZEC support. MASP is *Sapling-derived* but the pool is Namada's, not Zcash's | Verification is conditional on future research |

**Key observation:** Namada did *not* solve the irreducible-signing problem for BTC / XMR / ZEC. They shipped what's principled (IBC) and accepted the honest-majority compromise for Ethereum. For BTC specifically, they delegate to upstream bridge designs and inherit those trust assumptions.

The BD pitch "Namada solved cross-chain privacy" is misleading. They solved *shielded multi-asset transfers given that the assets arrive*. The arrival problem (cross-chain wrapping trust) is solved for the IBC subset and compromised in the same way ours would be for Ethereum. They have no advantage over Logos on BTC/XMR/ZEC outbound.

### 7.4 Logos vs. Namada

Overlap:

- **Shielded balances of multiple asset types** in one anonymity set. Namada ships this today via MASP. LEZ's private state could host equivalent functionality; it's a different implementation route (RISC0 guest programs maintaining state vs a fixed Sapling-derived circuit) but the user-visible primitive looks similar.
- **Bridged-asset wrapping.** Both systems face the §3 / §4 trust trade-offs identically for ETH and BTC. Namada chose validator-set multisig; we have the option to ship principled ZK for ETH inbound and to make the BTC Option choice openly.
- **Shielded swaps.** Namada is working on shielded swaps via Osmosis (Penumbra / Osmosis-shielded routing). RFP-003 is the equivalent Logos workstream. Different implementations, similar user journey.

No overlap:

- **General-purpose private execution.** Namada's MASP is a fixed primitive: shielded transfers, shielded rewards, shielded swaps via the Convert circuit. It's not Turing-complete. LEZ runs RISC0 guest programs — arbitrary computation against private state.
- **Compositional trust boundary across primitives.** Logos has private execution (LEZ) + private messaging + private storage under a single trust model. Namada has the shielded pool, but coordination (intent broadcasting, solver discovery, settlement messaging) happens on external infrastructure under different trust assumptions. The "private end-to-end" pitch is structurally easier for Logos.
- **Atomic-swap modules (RFP-003).** Logos ships native cryptographic atomic swaps to BTC/XMR/ETH via adaptor signatures + cross-curve DLEQ. Namada doesn't have this primitive — their swap story is Osmosis-routed, which is liquidity-pool-based, not atomic-swap-based.

### 7.5 Partnership shape

*Logos is the execution layer for private finance; Namada is the shielded transfer layer for private finance*. These are complementary primitives.

Concrete partnership shapes:

- **NAM ↔ LEZ atomic-swap pair.** Extend RFP-003 to add Namada as a supported chain. User with shielded MASP balance atomic-swaps into LEZ private state for execution access, optionally swaps back. Both sides keep shielded semantics. This is the most tangible joint deliverable. Note, however, that wrapping/bridging Namada tokens would inherit their trust assumptions (non-custodial only for IBC).
- **Joint BD into the privacy-asset ecosystem.** Cake, Zashi, Power Up Privacy, MAGIC Grants — these gatekeepers will compare Namada and Logos. A joint pitch ("transfers via Namada, execution via Logos") may be stronger than two competing pitches.

---

## 8. Summary

**The architectural insight:** wrapping decomposes into inbound (ZK-solvable) and outbound (irreducible signing). Logos's three primitive types — chain-watching light-client modules, atomic-swap modules, wrapped-asset modules — map cleanly onto this split. A fourth quadrant (external messaging) is not a current Logos workstream.

**Per-asset feasibility:**

- ETH: fully principled in both directions possible.
- BTC: inbound principled; outbound requires the §4 strategy decision (recommended: Option C, partner now via tBTC and build principled v2 via upcoming BitVM in parallel)
- XMR: principled wrap not feasible; RFP-003 atomic-swap module covers one-shot user journeys; `sXMR` synthetic available as an option for persistent price exposure without custody
- ZEC: principled wrap not feasible near-term; integrate Maya / THORChain and NEAR Intents for shielded swaps or extend RFP-003; `sZEC` synthetic again available as an option

Given that noncustodial wrapping isn't available for XMR or ZEC, the best partner shape in trust-assumption terms is threshold-MPC vault networks.

**RFP-003 covers F4 substantially.** Trustless LEZ↔BTC/XMR/ETH atomic swaps via adaptor signatures + cross-curve DLEQ. F4 BD is aggregator routing + solver-economy design. F3 BD is custody architecture + distribution gatekeepers + lending markets, on top of the wrapped-asset modules where they're feasible.

**The Basecamp-module framing is a solid BD story.** "Logos ships modules, not bridges" distinguishes us from LayerZero / Wormhole / CCIP / Axelar / Hyperlane / Across.

**Namada can be a solid partner.** Their MASP is mature for shielded transfers across IBC and (via validator-multisig bridge) ERC-20s; they did not solve the irreducible signing problem for BTC/XMR/ZEC. Logos's defensible differentiation is private *execution* + atomic swaps + private coordination, which Namada doesn't offer. The right joint deliverable is a NAM↔LEZ atomic-swap pair similarvto RFP-003 and a coordinated BD posture into the privacy-asset gatekeepers.