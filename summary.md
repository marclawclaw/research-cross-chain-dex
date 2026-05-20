---
tags: [synthesis, summary, cross-chain-dex, lez, anonymity]
updated: 2026-05-19
---

# Research Summary: Cross-Chain DEX Middle Layers and LEZ Positioning

## Methodology

This synthesis covers three projects researched in atomic Obsidian
notes during May 2026. Discovery was scoped to two architectural
camps:

- **Middle-chain DEX**: a purpose-built blockchain whose validator set
  custodies external assets via a threshold signature scheme and runs
  swap matching natively. Selected: [[projects/thorchain]] (Cosmos SDK,
  live since 2021), [[projects/serai]] (Substrate, pre-mainnet as of
  May 2026).
- **Attestation bridge**: a guardian or validator network that signs
  messages between independent chains but does not custody a shared
  reserve or execute swaps natively. Selected as the contrast point:
  [[projects/wormhole]] (no native chain, 19-of-19 PoA committee).

Every metric in the per-project notes has a URL and accessed date of
2026-05-19. Unavailable claims are tagged `[NOT FOUND]` rather than
estimated.

## Ecosystem landscape

| Project | Live? | Cumulative volume | TVL (May 2026) | Validator set | Trust scheme |
|---------|-------|-------------------|----------------|---------------|--------------|
| [[projects/thorchain]] | Yes (2021) | $112.2B | $70.2M (DEX) | ~103 active, cap 120 | GG20 TSS, bonded RUNE, slashable |
| [[projects/serai]]     | No (audit complete; pre-testnet) | n/a | n/a | up to 600 (planned) | FROST per-network, bonded SRI, slashable |
| [[projects/wormhole]]  | Yes (2021) | $58.2B bridged | $2.27B (Portal) | 19 named firms | 13-of-19 independent ECDSA, no bonded stake |

Sources: [DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex), [DefiLlama Portal](https://defillama.com/protocol/portal), [Wormhole blog](https://wormhole.com/blog/connecting-the-internet-economy-wormhole-and-the-w-tokens-past-present-and), [Serai audit blog](https://serai.exchange/2026/04/15/serai-blockchain-audited.html). All accessed 2026-05-19.

## How a middle chain enables cross-chain swaps

The pattern (formalised in [[patterns/middle-chain-swap-settlement]])
has six load-bearing components:

1. **Settlement chain** with its own validator set and consensus
   (Tendermint/CometBFT for Thorchain; Substrate BABE+GRANDPA for
   Serai).
2. **Cross-chain daemon per validator** that watches every external
   chain for inbounds to the active vault address(es): Bifrost on
   Thorchain, Processor + Coordinator on Serai.
3. **Confirmation policy** per external chain, usually value-scaled so
   that larger swaps wait for deeper finality before being accepted on
   the middle chain.
4. **TSS vaults** custodying assets on each external chain (see
   [[patterns/tss-custody-vault]]). One shared key per external coin;
   sharded if the validator set is too large for a single ceremony.
5. **Native swap execution** on the middle chain: AMM pools
   (`xy=k` on Serai, continuous liquidity pools with slip-based fees
   on Thorchain) or order matching.
6. **Outbound queue and signer**: the state machine queues a `TxOut`,
   the assigned vault members run a TSS keysign, and the resulting
   standard signature is broadcast to the destination chain.

Operationally, both projects also run a **churn / rotation** loop
(Thorchain: every 3 days; Serai: per session) that triggers a fresh
DKG and migrates funds from old vault addresses to new ones.

The Wormhole pattern does *none* of this in protocol: it emits signed
messages, and the swap composition happens off-protocol on a
destination-chain DEX or in a solver network (Mayan Swift, deBridge).
See [[patterns/attestation-bridge]] for the contrast pattern.

## Trust models: who custodies the funds and on what assumptions

This is the central question and the user's lead concern. All three
designs reduce to a **federation of signers** with different
membership rules, stake rules, and authorisation rules. See
[[patterns/signer-federation-trust]] for the cross-cutting comparison.

### Thorchain (see [[patterns/thorchain-trust-model]])

- ~100 active node operators, **permissionless by bond auction**. To
  enter, a candidate must bond more RUNE than the lowest active node
  (minimum 400,020 RUNE, around US$159K in February 2026; the cap
  hovers ~US$375K per node).
- **GG20 ECDSA TSS** with EdDSA added for Solana-style chains. Logical
  vaults sharded into ~6 Asgard vaults of 20 members; signing requires
  two-thirds supermajority per shard.
- **Economic invariant**: 3:1 target ratio of total locked RUNE
  (bonded + pooled) to non-RUNE assets, of which $2 is bonded and $1
  pooled per $1 of foreign asset. The Incentive Pendulum shifts
  rewards between bonders and LPs to maintain it. Slashing applies on
  failed keygen/keysign and on chain-attributable misbehaviour.
- **Production failure modes have all been realised**:
  - 2021 ETH Router exploits ($16M): not a TSS failure but signer
    trust of event-data emitted by a hostile wrapper contract.
  - 2024 lending wind-down (~$200M of toxic debt): protocol-level
    insolvency in a peripheral product, resolved by converting debt
    to equity tokens (TCY) and freezing positions.
  - **May 2026 GG20 TSS exploit ($10.8M)**: a churned validator node
    exploited a TSSHOCK-class weakness in GG20 to leak partial key
    material across signing rounds and reconstruct an Asgard key,
    then signed unilateral outbounds. This is the first cryptographic
    failure of the TSS layer itself in production; the network paused
    for ~13 hours via `make pause`. Sources: [Crypto Times](https://www.cryptotimes.io/2026/05/17/10-8-million-drained-inside-the-thorchain-exploit-that-froze-cross-chain-defi-for-13-hours/), [AMBCrypto](https://ambcrypto.com/thorchain-exploit-raises-fresh-concerns-over-mpc-wallet-security/), accessed 2026-05-19.

### Serai (see [[patterns/serai-trust-model]])

- Up to 600 PoS validators, **permissionless by stake**. Validators
  bond against the specific external networks they choose to validate
  (not globally), and only run the per-network Processor for those
  networks.
- **FROST (Schnorr threshold)**, per-curve: Bitcoin and Ethereum use
  Secp256k1, Monero uses Ed25519 (via the bespoke FROSTLASS protocol
  for CLSAG), Serai itself uses Ristretto. Threshold is
  `t = floor(n * 2/3) + 1`. The DKG was migrated from a three-round
  PedPoP-with-complaint protocol to a one-round eVRF-based robust
  DKG (HashCloak-proven).
- **Economic ceiling**: custody is hard-capped at 33% of the
  validator set's allocated stake. The protocol *must reject* new
  deposits above that ratio because a two-thirds collusion is by
  definition cheaper than the value it would steal. Source: [Validator Sets spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md), accessed 2026-05-19.
- **Pre-economic-security era is a real risk window**: SRI does not
  exist before mainnet. Bootstrapping mints SRI to validators in
  exchange for external coins, so until the validator-stake pool
  reaches the 3x custody-value invariant, the cap does not bind and
  theft is unrecoverable. The docs.serai.exchange pages describing
  pre/post phases were empty stubs as of 2026-05-19.
- **Liveness floor weaker than headline**: DKG Exclusions allow an
  honest 2/3 to remove a faulty 1/3, leaving the key controllable by
  4/9 (~44%) of the original set; chained exclusions can degrade
  safety further. Source: [DKG Exclusions spec](https://github.com/serai-dex/serai/blob/develop/spec/DKG%20Exclusions.md), accessed 2026-05-19.
- **No production failure modes yet**: pre-launch, post-audit. The
  Substrate fork is trimmed to 141,980 LoC (from 663,615 upstream)
  precisely to bound the audit surface; SR Labs audit closed April
  2026 with 0 critical / 5 high / 3 medium / 1 low.

### Wormhole (see [[patterns/wormhole-trust-model]])

- 19 named infrastructure firms (Jump Crypto, Chorus One, Everstake,
  Figment, P2P Validator, Triton, etc.) selected by governance.
  **No bonded slashable stake**. The set is permissioned; membership
  changes via Guardian governance vote.
- Each Guardian signs independently with a 65-byte secp256k1 ECDSA
  signature; **13-of-19** signatures form a VAA. **This is not a TSS**
  in the GG20 or FROST sense: there is no DKG, no aggregate
  signature, no shared key shard. The on-chain footprint per VAA is
  larger, but there is no MPC liveness requirement on key generation.
- **No protocol-owned reserve**. Each integrated chain has its own
  Wormhole Core Contract and Token Bridge contract; locked tokens
  live in those per-chain contracts, not in a shared vault.
- **Defences are off-protocol**: reputational stakes; operational
  heterogeneity; Governor rate limits on outflows; Global Accountant
  supply invariants; Jump Crypto's discretionary willingness to bail
  out failures (as in 2022).
- **The 2022 incident bypassed rather than broke the trust model**:
  a Solana-side `load_instruction_at` bug let an attacker pass a fake
  sysvar account and forge a VAA without any Guardian's participation,
  minting 120k wETH unbacked (~$326M). Jump Crypto deposited 120,000
  ETH from its treasury to repeg. Sources: [Halborn](https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022), [Chainalysis](https://www.chainalysis.com/blog/wormhole-hack-february-2022/), [CertiK](https://www.certik.com/blog/wormhole-bridge-exploit-incident-analysis), accessed 2026-05-19.
- A "Guardian compromise" attack has not occurred. The seven keys
  needed to forge any VAA on any integrated chain remain the
  single-largest theoretical risk; there is no in-protocol forfeit
  if it happened.

### What "trust" really means in all three

All three are federations of signers. The user is asked to trust:

1. That a majority of the signer federation will not collude to spend
   from the vault (Thorchain, Serai) or sign a malicious VAA
   (Wormhole).
2. That the cryptographic primitive used to combine signer
   contributions is sound. **Thorchain shows this assumption is not
   free**: GG20 TSS had a production exploit in May 2026.
3. That the implementations on every external chain are correct.
   **Wormhole shows this assumption is not free**: a contract bug on
   one chain (Solana, 2022) drained the vault even though the
   Guardians behaved correctly.

Thorchain and Serai add cryptoeconomic skin in the game (bond
slashable on misbehaviour) on top of (1) and (2). Wormhole does not;
its analogue is Jump Crypto's voluntary post-hoc bailout.

## Necessary characteristics of a cross-chain middle layer

Synthesising across [[projects/serai]] and [[projects/thorchain]],
these are the characteristics a chain must have to play the
middle-layer role for cross-chain swaps:

1. **A bonded validator set with slashable misbehaviour conditions.**
   Reputational trust (Wormhole) is not sufficient when the protocol
   itself must absorb a custody failure rather than relying on a
   single corporate sponsor.
2. **A TSS or threshold signature primitive** producing standard
   signatures (ECDSA, Schnorr, EdDSA) acceptable on external chains
   without contract deployment. This is what lets the design work for
   UTXO chains as well as EVM and SVM. See [[patterns/tss-custody-vault]].
3. **Per-external-chain observers** that watch inbound deposits to
   the active vault address and feed observations into consensus
   with confirmation counting tuned to that chain's finality.
4. **A native execution layer** that can clear swaps atomically:
   AMM pools or order matching, native-asset to native-asset, without
   introducing wrapped IOUs into downstream protocols.
5. **A churn / rotation mechanism** that regenerates vault keys as
   the validator set changes, with a migration window during which
   old and new vaults coexist and funds are forwarded.
6. **Predictable consensus finality** so external chain withdrawals
   can be broadcast without later being orphaned by a middle-chain
   reorg.
7. **An economic security ceiling expressed as a ratio of bonded
   value to custodied value**. Both Serai (33% cap, equivalent to
   3x bonded-to-custodied) and Thorchain (2:1 bond-to-pooled, with
   1:1 pool-to-foreign-asset) make this explicit. Below the
   threshold, the cryptographic security argument no longer holds.
8. **An emergency halt mechanism**. Thorchain has `make halt` and
   `make pause`; Serai has session-level rollback during DKG. The
   ability to freeze withdrawals on suspected solvency or signing
   failure is load-bearing in practice (used three times in
   Thorchain's history).

These eight characteristics are necessary. The interesting design
freedom is what privacy, accountability, and recourse properties the
chain adds on top.

## LEZ positioning

The Logos Execution Zone (LEZ) is a general-purpose execution zone
within the Logos stack. Its base capabilities (bonded validator set,
general-purpose programmability, predictable block production, shared
Logos consensus security) are already sufficient to implement the
eight necessary characteristics above. The middle-chain-DEX pattern
is buildable on LEZ without inventing new primitives at the consensus
layer.

The interesting question is what LEZ can do that Serai and Thorchain
cannot, and why that matters.

### What Serai and Thorchain leave on the table

Both are *transparent* middle chains. Every inbound observation,
every swap intent, every pool state update, every outbound signing,
and every validator-set rotation is publicly readable on the middle
chain. Thorchain's memos broadcast the destination address on the
**source chain** before the middle chain even sees them, which links
source and destination identities on public ledgers regardless of
what the middle chain does. Serai's swap shorthand expands
deterministically into a public Dex instruction.

This produces a clear privacy gap:

- **End-to-end chain analysis is trivial**: third-party tools can
  link a deposit on Bitcoin to a withdrawal on Ethereum via the
  middle chain's public state.
- **Toxic ordering and MEV** are possible on Thorchain's public
  mempool; slip-based fees and streaming swaps damp but do not
  eliminate it. Serai inherits the same exposure for its public swap
  intents.
- **Validator set behaviour is fully visible**, including which
  validators participate in which signing rounds, which makes
  targeted out-of-protocol pressure on individual validators feasible.

Neither project has a clear path to fix this without a fundamental
execution-layer change (Cosmos SDK Thorchain has no zkVM; Serai's
Substrate chain has no shielded primitives in its current spec).

### Anonymity advantages LEZ can bring

LEZ can be a *privacy-preserving* middle chain, which is a category
step beyond either Serai or Thorchain. The candidate primitives that
matter, ordered by how cleanly each addresses a specific gap in the
comparators:

1. **Shielded swap intents.** Treat the middle chain's order book or
   swap intent queue as a shielded pool: intents are commitments,
   accompanied by a zk proof that the intent is well-formed
   (correctly funded, within slippage bounds) but not revealing the
   size, pair, or sender. Closes the link from middle-chain swap
   memo to user. Requires a zkVM or circuit-friendly execution layer
   on LEZ. **Direct contrast**: Thorchain memos are public on the
   source chain; LEZ intents would be commitments on the middle
   chain.

2. **Sealed-bid batch matching with threshold decryption.** Within a
   matching window, bids are encrypted under a key held jointly by
   the validator set; at the window close, threshold-decrypt and
   clear at a uniform price. Generalises the TSS vault construction
   the middle chain already needs. Closes the **MEV** gap directly
   (Thorchain slip-based fees, see [[patterns/slip-based-fees]],
   are a *response* to MEV, not a prevention).

3. **Stealth addresses for outbound transactions on external chains.**
   When the LEZ TSS vault signs an outbound on Bitcoin or Ethereum,
   the recipient is a freshly derived stealth address per swap, not
   a long-lived user address. The vault produces a one-time output
   that only the swap recipient can spend. Closes on-chain clustering
   on the **destination** chain even when that chain has no native
   privacy. Feasible on Bitcoin (BIP 47 / silent payments) and
   Ethereum (ERC-5564 / stealth meta-addresses) with different
   mechanics per chain.

4. **Transport-layer privacy via Waku.** Order submission and quote
   dissemination flow over Waku rather than ordinary p2p gossip;
   publisher and subscriber are decoupled by content topics and
   network-layer traffic is unlinkable. Denies network-level
   deanonymisation of submitters that affects every public middle
   chain. Logos already invests in Waku.

5. **Anonymous deposit attribution.** A deposit into the TSS vault on
   Bitcoin is, by default, linkable to the user. LEZ can mitigate
   this with a deposit zk proof: the user proves on LEZ that they
   own a deposit in the vault, without revealing which deposit.
   Combined with stealth withdrawals (3), this breaks the end-to-end
   on-chain trail that Thorchain and Serai leave behind.

6. **Validator-set privacy and fraud-proof exits.** A privacy-aware
   middle chain can (a) hide which validators contributed to which
   signing round behind a uniform threshold signature (FROST
   already does this; GG20 does not), and (b) offer users a
   challenge-response exit window in which a fraud proof on LEZ
   can halt an outbound before it is broadcast. None of the three
   comparators offer either today.

### Why Serai and Thorchain cannot match this in their current designs

- **Thorchain** has no zkVM and no shielded execution. Its
  transparency is a design value (auditability), not an accident.
  Adding shielded pools would require a hard fork and a new
  execution layer.
- **Serai** is privacy-friendly at the *transport* boundary (Monero
  is custodied in XMR, not wrapped), but the Serai chain itself is a
  public Substrate state machine. There is no shielded pool
  primitive in the current spec, and the AMM is a deliberately
  simple `xy=k` constant-product without sealed bids.
- **Wormhole** has no chain. It cannot host a shielded pool, and
  every VAA is a public artefact indexed by emitter and sequence.

LEZ, as a general-purpose execution zone in a privacy-first
ecosystem, can adopt these primitives without competing for
blockspace with a public DEX history. The same validator set that
secures Logos applications can secure the TSS vaults, the shielded
pool, and the sealed batch auctions, with a single bonded-stake
economic argument covering all three.

### What LEZ should not try to differentiate on

Some axes where LEZ matching the comparators is sufficient:

- **TSS primitive**: FROST is the right choice (Serai is right, and
  the May 2026 Thorchain GG20 exploit is a clear lesson). No need to
  invent something new.
- **Constant-product AMM at launch**: Serai's pragmatic `xy=k` choice
  generalises; concentrated liquidity adds complexity that does not
  earn its keep at launch volumes.
- **Per-external-chain observer architecture**: Bifrost and Processor
  are mature reference designs.
- **Churn cadence and migration windows**: Thorchain (3 days) and
  Serai (per session) bracket the reasonable range; pick one.

## Open positioning questions for the RFP

1. **zkVM or co-zone?** Does LEZ have, or commit to, a zkVM or
   circuit-friendly execution layer suitable for shielded swap pools,
   or should the DEX rely on a dedicated co-zone? The analogous
   question for naming has already been answered in favour of staying
   on LEZ; see `appendix/lez-vs-dedicated-zone.md` in the RFP repo.
2. **External chains in scope at launch.** BTC, ETH, XMR are
   non-negotiable (XMR matters precisely for the privacy
   positioning). Bitcoin L2s, Solana, and Cosmos chains drive
   observer/signer engineering load.
3. **TSS scheme and audit posture.** FROST (Serai's choice) is the
   recommended baseline. The May 2026 Thorchain incident makes clear
   that the TSS library audit is load-bearing: budget for at least
   one Cypher Stack or equivalent engagement on the chosen scheme.
4. **Bond-to-custodied-value ratio.** Thorchain runs 2:1 bond and 1:1
   pool. Serai runs a 33% custody cap (3:1 bond-to-custodied). The
   RFP should pick a target and a mechanism to enforce it.
5. **Stealth-address coverage.** Bitcoin (BIP 47 / silent payments)
   and Ethereum (ERC-5564) have working specs; XMR is native.
   Solana and Cosmos chains require per-chain investigation. Initial
   coverage scope drives engineering load.
6. **Emergency halt authority.** Who can halt outbounds, on what
   evidence, and how is the halt itself secured? Thorchain `make
   halt` is invoked by node consensus; Serai's mechanism is more
   tied to DKG failure detection. LEZ should specify.
7. **Recourse beyond slashing.** None of the comparators offer fraud
   proofs or exit windows. This is a place LEZ could lead.

## Why none of these used atomic swaps

The question of why Serai, Thorchain, and Wormhole did not use atomic swaps (HTLC or adaptor-signature scriptless scripts) is worth recording explicitly, because Serai's lead developer Luke Parker (kayabaNerve) has direct context in the BTC-XMR atomic-swap ecosystem. Full investigation in [[patterns/atomic-swaps-vs-middle-chain]]; key findings:

- **Thorchain** has a canonical written rejection: a 2019-07-02 Medium post, "Why Cross-Chain bridges are superior to Atomic Swaps", argues atomic swaps face "major limitations (mostly at the cryptography level)" and that validator-mandated bridges have "greater access to instant liquidity" ([Thorchain Medium](https://medium.com/thorchain/why-cross-chain-bridges-are-superior-to-atomic-swaps-aebde263103c), accessed 2026-05-19).
- **Serai** has no written rejection in its blog, specs, RFCs, or GitHub issues. The strongest direct quote is from a MoneroTalk interview: Luke Parker said *"while I do love atomic swaps [..] I don't feel the community actually wants atomic swaps, which is a brutal truth"* ([Monero Observer](https://monero.observer/monerotalk-kayabanerve-interview-serai-dex/), accessed 2026-05-19), and he groups Serai with Thorchain, Maya, and Chainflip rather than with Farcaster/COMIT. The lack of any *written* rationale in a project led by someone who knows the atomic-swap design space intimately is itself a finding.
- **Wormhole** is a category-mismatch case: generic message passing is strictly more expressive than HTLC. No design document discusses atomic swaps because HTLC was never a candidate for the use cases Wormhole targets (NFT bridges, governance messages, oracle relay).
- **Industry trajectory**: the atomic-swap category has stalled rather than scaled. Liquality discontinued its consumer wallet 2024-06-15 after roughly US$35M lifetime volume ([Liquality on X](https://x.com/Liquality_io/status/1792678368694985162), [defiprime](https://defiprime.com/liquality), accessed 2026-05-19); the COMIT xmr-btc-swap canonical implementation is unmaintained as of late 2024 ([github.com/comit-network/xmr-btc-swap](https://github.com/comit-network/xmr-btc-swap), accessed 2026-05-19); AtomicDEX rebranded to Komodo Wallet and shows essentially no recent volume. Farcaster remains active but at community scale.
- **Implication for LEZ**: the structural reasons that pushed Serai and Thorchain away from atomic swaps (P2P liquidity gravity, multi-hour timelocks, refund flows, no AMM-style pricing) apply with equal force to LEZ. The middle-chain pattern is the right starting point. Atomic-swap-style primitives may still be useful as a complementary mechanism for specific high-trust pairs, but not as the core DEX engine.

## Common patterns surfaced

- [[patterns/signer-federation-trust]]: cross-cutting trust-model
  comparison across all three projects.
- [[patterns/middle-chain-swap-settlement]]: the architectural
  pattern shared by Serai and Thorchain.
- [[patterns/tss-custody-vault]]: the custody primitive shared by
  Serai (FROST) and Thorchain (GG20).
- [[patterns/slip-based-fees]]: Thorchain's pricing approach,
  partially MEV-mitigating but not privacy-providing.
- [[patterns/attestation-bridge]] and [[patterns/lock-mint-bridging]]:
  the contrast patterns instantiated by Wormhole.
- [[patterns/atomic-swaps-vs-middle-chain]]: why none of the three
  surveyed projects used atomic swaps, with the Thorchain 2019 design
  rejection and the Luke Parker MoneroTalk quote as the two anchor
  citations.
- Per-project trust-model deep dives:
  [[patterns/serai-trust-model]],
  [[patterns/thorchain-trust-model]],
  [[patterns/wormhole-trust-model]].

## Key differentiators

- **Serai** vs Thorchain: FROST per-network keys (cleaner crypto,
  no GG20 exposure), per-network staking, narrower asset coverage
  at launch, pre-mainnet. XMR is a first-class citizen.
- **Thorchain** vs Serai: live for 5 years, $112B cumulative volume,
  RUNE-bonded economic security, 11 chain integrations. GG20 has now
  failed in production. CLP with slip-based fees has the most
  battle-tested pricing model in the cross-chain DEX space.
- **Wormhole** vs both: an attestation transport, not a settlement
  chain. Buys ubiquity (~40 chains supported) at the cost of having
  no protocol-owned liquidity, no native swap, and per-chain bridge
  contracts as separate attack surfaces.
- **LEZ proposed** vs all three: a privacy-preserving middle chain.
  Inherits the necessary characteristics from the Serai/Thorchain
  lineage, adds shielded swap intents, sealed-bid matching, stealth
  outbound addresses, anonymous deposit attribution, and Waku-routed
  orderflow on top.

## Problem data

- **Thorchain May 2026 GG20 exploit**: $10.8M drained, 13-hour
  network pause, attributed to TSSHOCK-class TSS implementation
  weakness. First production failure of the TSS layer itself.
  ([Crypto Times](https://www.cryptotimes.io/2026/05/17/10-8-million-drained-inside-the-thorchain-exploit-that-froze-cross-chain-defi-for-13-hours/), accessed 2026-05-19)
- **Wormhole February 2022 incident**: $326M drained from the
  Solana Token Bridge via a `load_instruction_at` sysvar bug. Jump
  Crypto re-deposited 120k ETH out of pocket; protocol had no
  in-protocol recourse. ([Halborn](https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022), accessed 2026-05-19)
- **Thorchain July 2021 ETH Router exploits**: ~$16M across two
  events; root cause was Bifrost trusting smart-contract-emitted
  events instead of canonical transfer data. ([Postmortem](https://medium.com/thorchain/post-mortem-eth-router-exploits-1-2-and-premature-return-to-trading-incident-2908928c5fb), accessed 2026-05-19)
- **Thorchain January 2024 lending wind-down**: ~$200M of insolvent
  positions, resolved by debt-to-equity conversion. ([Cointelegraph](https://cointelegraph.com/news/thorchain-pauses-bitcoin-ether-lending-amid-insolvency-risks), accessed 2026-05-19)
- **Cross-chain DEX privacy gap**: every comparator publishes the
  source-to-destination link on at least one public ledger. None
  offer first-class privacy primitives. This is the precise gap LEZ
  can fill.

## Gaps and open questions

Per-project gaps flagged in the underlying notes:

- **Serai**: per-network `CONFIRMATIONS` constants, Serai chain
  block time and session length in blocks, end-to-end swap latency
  target, quantitative slashing magnitudes, and pre-economic-security
  mint schedule details are all `[NOT FOUND]` in published specs.
- **Thorchain**: quantitative validator slashing percentages for
  failed keysign and TSS misbehaviour; canonical repo URL validation;
  full Trail of Bits 2021/2022 audit report PDFs.
- **Wormhole**: current authoritative Guardian roster (docs defer to
  a live dashboard); explicit DefiLlama Wormhole bridge breakdown
  (HTTP 403 on the bridge page; cross-referenced via Portal page).

Open questions for the RFP itself:

- LEZ zkVM commitment and timeline.
- Stealth-address support feasibility per external chain at launch.
- Fraud-proof exit mechanism design (none of the comparators have
  one).
- Migration window length and overlap behaviour under contested DKG.
- Bond-to-custody ratio target and dynamic enforcement (Incentive
  Pendulum analogue).

## See also

- [[projects/serai]], [[projects/thorchain]], [[projects/wormhole]]
- [[projects/lez-positioning]] (the LEZ-side analysis; refined now
  that comparator notes are complete)
- [[metrics/swap-volume]]
