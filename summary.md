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

## Trust-model contrast: federated signers vs atomic swaps

The two architectural camps in this research collapse to a binary choice about *who you have to trust to complete a swap*. Stating that contrast in one place, then walking through what would actually be needed to make the trustless camp viable, is the clearest way to frame the LEZ design decision.

### Federated-signer middle chain (Thorchain, Serai, Maya, Chainflip)

**What you trust**: a threshold of the validator set, the soundness of the TSS primitive, and the correctness of the per-chain observer/signer implementations.

**Pros**:

- **AMM-style liquidity**: a single ordered state machine maintains pool invariants and serves all-comers without per-trade matching. See [[patterns/middle-chain-swap-settlement]].
- **One-step UX**: deposit-with-memo, await outbound. No counterparty interactivity, no refund flows, no online-availability requirement past broadcast.
- **Sub-block-time settlement** on the middle chain; only the destination-chain finality and the TSS keysign delay the outbound.
- **Arbitrary asset pairs** at protocol-set pricing; the pair coverage problem is reduced to "does the validator set run an observer for chain X".
- **Cryptoeconomic recourse**: misbehaviour is slashable; Thorchain and Serai both express an explicit bond-to-custodied ratio (Thorchain 2:1 bonded + 1:1 pooled; Serai 33% custody cap).

**Cons**:

- **Custody risk is real and realised**. Thorchain's GG20 vault was drained in May 2026 ($10.8M); Wormhole's Solana bridge was drained in February 2022 ($326M). The TSS primitive itself can fail, and the cryptographic argument that supports the bond ratio depends on auditor-grade review of the chosen scheme.
- **The signer federation is a chokepoint** for censorship, surveillance, and out-of-protocol pressure on individually identifiable validators.
- **Pre-economic-security bootstrap**: Serai's mint-on-bootstrap design illustrates that the slashable-bond argument does not bind until the validator-stake pool catches up with custody, and that window is a real risk.
- **Public middle-chain state** links source and destination identities on the comparator chains; see the privacy gap discussion in the LEZ positioning section above.

### Atomic swap (HTLC; adaptor-signature scriptless scripts)

**What you trust**: nothing beyond the soundness of the cryptographic construction and the liveness of the two parties for the duration of the swap.

**Pros**:

- **No custody risk.** Funds never leave control of one of the two participants. There is no validator set to slash and no vault to drain.
- **No signer federation.** No 13-of-19, no 67% threshold, no per-chain observer to be censored or compromised.
- **No pre-economic-security window**: the cryptographic security is full from day one because there is no bond/custody ratio to bootstrap.

**Cons** (these are the ones the user asked about, taken from [[patterns/atomic-swaps-vs-middle-chain]] and the COMIT operational record in [[projects/comit]]):

1. **Free option on both sides**. Once one party has locked, the other can wait and observe price movement before completing or walking away. Their downside is gas plus time; the locker's downside is opportunity cost on inventory locked for the entire timelock window. Empirically this is the failure mode that kills BTC-XMR adoption: makers refuse to lock against takers who can free-option them for hours.
2. **Settlement time dominated by the slowest chain**. The xgram.io 2026 review records "a single swap can take 30 minutes to several hours to finalise" because BTC-side confirmations and XMR-side confirmations stack. Refund timelocks are measured in hours, not minutes.
3. **Mandatory interactivity for both parties**. Both parties must be online for lock, reveal, and (in adversarial paths) refund. This is a hard constraint, not a UX preference: if Alice goes offline mid-swap, Bob waits out the refund window, and vice versa.
4. **Per-trade matching**. No protocol-owned liquidity, no AMM pricing; each swap requires a willing counterparty for the exact pair and exact size.
5. **Pair coverage**. HTLC requires compatible scripting on both chains. BTC-XMR specifically required ~5 years of cryptographic work (2017 proposal → 2021 working implementation via adaptor signatures over Ed25519/Secp256k1).

Cons (1)–(3) are the ones the design space can plausibly attack without abandoning the atomic-swap model entirely. (4) is structural: an atomic swap is a one-shot peer-to-peer primitive by definition, and "fixing" it by adding protocol-owned liquidity reinvents the middle-chain DEX. (5) is a per-pair engineering cost paid once.

### Mitigations for the addressable atomic-swap cons

Three independent levers, none of which is sufficient on its own. The interesting design question is which combination buys enough back to make atomic swaps competitive for a specific niche on LEZ — not whether they replace the middle-chain DEX outright.

#### Mitigation 1: same-asset-to-same-asset (bridge, not trade) — hypothesis

If the two legs of the swap are denominations of the *same* underlying asset (e.g. native XMR on Monero and an LEZ-side wrapped-XMR token redeemable 1:1 to native XMR via a custodian, SPV proof, or threshold-signer reserve), the *trade* component disappears: there is no relative-price volatility between the two legs, so the free-option value collapses toward zero. The mid-swap optionality that makes the maker refuse to lock against an arbitrary taker is a function of `σ × √T × notional`; if `σ → 0` for the pair, the option is worthless and the timelock window stops being an exploitable asset.

**Important scoping**: this argument applies only to a *1:1 wrapped or SPV-backed* token, where redemption is at a contractually fixed ratio and the only `σ` is residual peg slack (premium/discount, queue depth, fees). It does *not* apply to an oracle-priced synthetic token (e.g. an sXMR that tracks the XMR price via oracle, collateralised by stables or other assets), because the peg slack of an oracle-priced synthetic *is* the volatility the free option pays out on. Oracle-priced synthetic exposure is a distinct product (see [[rfp/appendix/sxmr-design-space]]); it does not solve the free-option problem.

**Status**: hypothesis, not validated. Caveats to investigate before relying on it for XMR specifically:

- The 1:1 wrapped/SPV approach requires either (a) someone holding the underlying XMR while the wrapped token circulates, with a redemption path, or (b) a cryptographic proof that the underlying is held without disclosure. **For Monero, no principled (b) is currently feasible**: Monero has no SPV-style proof primitive that can demonstrate "address Y holds amount X" without view-key sharing (ring signatures, RingCT, and one-time stealth addresses defeat external observation). Any deployable 1:1 XMR wrap therefore reverts to (a) with a custodian or signer set, at which point the design has collapsed back into the middle-chain pattern and atomic swaps are no longer the primitive. The same constraint applies in `[[patterns/atomic-swaps-vs-middle-chain]]` and underpins why every deployed cross-chain DEX that supports XMR (Serai, Thorchain via Maya) uses view-key-shared TSS custody.
- For chains with public outputs (BTC, ETH), a 1:1 wrap via light-client proofs is principled and the `σ → 0` argument applies cleanly. The lock-mint construction with a verifiable inclusion proof on LEZ is exactly what `[[patterns/lock-mint-bridging]]` describes.
- The peg is not exactly 1:1 in practice even for the principled cases. Bridge premium/discount, redemption queue depth, and fee asymmetry between the two directions reintroduce non-zero `σ` that an attentive counterparty can extract; the residual option is small but non-zero.
- Same-asset framing does not remove cons (2) and (3): settlement time and interactivity are functions of the underlying chains' finality and the adaptor-signature protocol, not of the asset pair.

**LEZ implication**: 1:1 wrapped/SPV-backed pairs are a viable atomic-swap niche for BTC and ETH (where the underlying proof is principled). For XMR, the wrap leg is not principled today and the design degenerates into the middle-chain pattern; the design space for XMR free-option mitigation moves to Mitigation 2 (where it is also constrained, see below) or Mitigation 3.

#### Mitigation 2: bonded atomic swap (forced completion via slashing) — protocol sketch

**The free-option problem in standard adaptor-signature swap.** Alice locks first (XMR or BTC) into a 2-of-2 output. Bob then locks Logos in an LEZ contract conditioned on secret `s`. To claim Logos, Alice publishes a signature that reveals `s` to Bob; Bob uses `s` to sweep Alice's lock. Between Lock-Logos and Reveal, Alice holds a free option on the price; symmetrically, between Alice's first lock and Bob's Logos lock, Bob can refuse to lock if the price moved.

**Why slashing only works on the LEZ side.** Monero and Bitcoin have either no scripting (Monero) or scripting too limited to hold a bond conditioned on protocol behaviour (Bitcoin). The only place a slash can be enforced is on a smart-contract chain. LEZ is therefore the right host for both bonds. But the LEZ contract needs to *verify the preconditions* (Alice's lock, Bob's lock) before applying any slash. This verification primitive is what differentiates the two tiers below.

**Tier 1: symmetric bonding for LEZ↔BTC and LEZ↔ETH.** Both sides' locks are verifiable on LEZ via a chain-watching light-client module: BTC via a RISC0 header-chain light client (forkable from ZeroSync or Citrea's Clementine LCP); ETH via the eth-light-client / Nimbus-derived module. The locker's outputs on these chains are publicly identifiable to a known scriptpubkey or address, so an inclusion proof on LEZ leaks nothing the locker relied on as private. Both Alice's and Bob's bonds are slashable on default: full bilateral free-option mitigation.

**Bonds (Tier 1)**:

- **Bob (Maker)** posts a standing bond `B_bob` to a Maker registry contract on LEZ. Sized per-maker, slashable per-swap up to a cap, covers many swaps. Maker bonds amortise cleanly because makers are repeat participants.
- **Alice (Taker)** posts a per-swap bond `B_alice` on LEZ at quote acceptance, in a stablecoin or Logos-native asset. Sized to exceed the expected value of the free option over the lock window: roughly `σ × √T × notional`, so 2–5% of trade notional for 1-hour windows. Refunded on honest completion.

**Phases and slash conditions (Tier 1, LEZ↔BTC example)**:

| Phase | What happens | Slash condition |
|-------|--------------|-----------------|
| 0. Quote | Bob signs quote (price, expiry, swap_id, refund_pubkeys); Alice and Bob run joint-key setup for the BTC 2-of-2 Taproot output | — |
| 1. Commit | Alice posts `B_alice` on LEZ referencing swap_id | — |
| 2. Lock-BTC | Alice constructs and signs the BTC lock tx, sends raw bytes to Bob over Waku; Bob verifies and broadcasts to Bitcoin (if Bob stalls, Alice broadcasts herself). Once confirmed, *anyone* submits `{btc_block_headers, merkle_proof, raw_tx}` to the LEZ swap contract, which verifies PoW + inclusion + scriptpubkey + amount | If lock is confirmed on BTC but Bob does not advance to Lock-Logos within window: `B_bob_slice` → Alice |
| 3. Lock-Logos | Bob locks `trade_amount` + `B_bob_slice` in LEZ contract conditioned on `s` | — |
| 4. Reveal | Alice publishes adaptor signature → reveals `s` to Bob | If Alice doesn't reveal within window: `B_alice` → Bob |
| 5. Settle | Bob claims BTC using `s`; Alice's bond and Bob's bond slice released | If Bob doesn't claim before deadline: no slash (capital loss is on Bob); Alice's bond auto-refunds |

**The unauthenticated proof-submitter property (Tier 1).** Bob can broadcast Alice's signed lock tx himself (broadcasting is permissionless on every chain); the LEZ inclusion-proof submitter is also unauthenticated. This eliminates a class of grief vectors: if Alice signs a malformed lock tx (wrong amount, wrong scriptpubkey), Bob simply does not broadcast it, the tx never lands on Bitcoin, the inclusion proof never materialises, and the LEZ state machine quietly times out. There is no "attest or be slashed" dispute to adjudicate, because the precondition for state advancement (a real BTC lock) never holds. Same reasoning applies to ETH.

**Tier 2: asymmetric bonding for LEZ↔XMR.** Monero has no SPV-style proof primitive that can demonstrate "this Monero output contains amount X for stealth key K" without view-key sharing. Ring signatures, RingCT, and one-time stealth addresses defeat external observation by design; Monero's bilateral `check_tx_proof` requires the verifier to receive the per-tx private key `r` and the output blinding factor, which works in a private wallet-to-wallet context but, if submitted to an LEZ contract, lands in world-readable public state. Submitting `r` on a public chain is mathematically equivalent to view-key disclosure for the swap output: anyone can re-derive the stealth output key, identify the recipient component, and confirm the amount. That is the privacy break XMR users pay to avoid, and it makes the Tier-1 design infeasible for LEZ↔XMR with the current Monero cryptography. FCMP++ (full-chain membership and metadata-private proofs, currently research-grade in the Monero ecosystem) may unlock a non-disclosing proof primitive in future; until then the LEZ↔XMR design is asymmetric.

**What survives for LEZ↔XMR**: Bob's lock is on LEZ and fully observable; Bob's bond is slashable on default exactly as in Tier 1. Alice's bond cannot be slashed for "failing to lock XMR" because LEZ cannot verify whether she did. It *can* be slashed for failing to reveal the secret on LEZ after Bob has locked Logos, because both the reveal and Bob's lock are LEZ-observable.

**The residual free option Alice keeps in Tier 2**: Alice can refuse to lock XMR after Commit without on-chain consequence (her bond is gated by the reveal-after-Bob-lock event, which never occurs in this branch). Bob detects this off-chain by not seeing the XMR lock arrive on Monero and walks away without locking Logos; no slash on either side. Alice keeps a *pre-XMR-lock* free option but loses the *post-Bob-lock* free option. The residual option is smaller (it is the option to walk away from a quote before any meaningful commitment, similar to a maker quote that does not get hit) but it is real.

**Tier 2 framing**: LEZ↔XMR under the current cryptography is "Bob is bonded; Alice is reputation-gated only" (Mitigation 3 then becomes more load-bearing for the taker side specifically). When FCMP++ ships, Alice's lock becomes verifiable on LEZ without view-key disclosure and Tier 2 collapses into Tier 1.

**What both tiers fix**: con (1), the free option, partially or fully depending on tier. In Tier 1 the slash makes both parties' optionality strictly EV-negative; in Tier 2 only Bob's optionality is closed.

**What neither tier fixes**:

- Con (2): settlement time is still bounded by source-chain finality plus LEZ finality plus the timelock window. The bond does not accelerate cryptographic settlement.
- Con (3): both parties still must be online to lock, reveal, and (if the other side defaults) submit the slash claim. The bond removes the *incentive* to grief but not the *requirement* to participate.
- Cross-chain bond correlation: if Bob is matched against N concurrent swaps and LEZ re-orgs or his observer crashes, all N swaps slash him. Per-maker concurrency caps or bond scaling with active-swap count are needed.
- The chicken-and-egg of `B_alice` denomination: an XMR-holding or BTC-holding Alice may not already hold a Logos-side bond asset. Either accept the friction, allow stablecoin-on-LEZ as bond, or specify a bondless capped-entry mode for first-time takers (e.g. US$100 first swap with no bond, cap lifted once the taker accumulates LEZ-denominated assets they can post).

**LEZ implication**: a bonded atomic swap turns the trust model from "no trust" into "trust the LEZ slashing contract and the soundness of the adaptor-signature scheme". That is a weaker custody assumption than the federated-signer model (no vault to drain, no TSS to break), but a stronger one than vanilla atomic swaps. The right framing is: Tier 1 bonded atomic swaps are *the privacy-preserving alternative to AMM swap for BTC and ETH users who specifically do not want vault custody*, accepting longer settlement and interactivity in exchange. Tier 2 is the same primitive degraded for XMR; it ships meaningfully better than vanilla atomic swaps on the maker side but not on the taker side, and depends on reputation primitives (Mitigation 3) for the taker constraint.

#### Mitigation 3: on-chain reputation for makers (and capped takers)

A maker is a repeat participant; a long history of completed swaps is itself a slashable asset, because losing the reputation forfeits all future fee revenue. This is the same argument that secures Wormhole's Guardians without bonded stake — reputation as economic gravity — but applied to a maker registry rather than a signer set.

**Maker reputation**: trivially valuable. Bob already wants a persistent identity on LEZ to receive quote requests, accumulate Maker-side fee revenue, and amortise bond posting. Layering reputation (count of completed swaps, slash history, time-in-protocol) on top of the bond compounds the cost of defection. A maker with 10,000 completed swaps walking away from a single griefable trade is an irrational actor; the reputation acts as a long-tailed bond that the protocol cannot directly slash but the market does.

**Taker reputation — the privacy tension**: takers are the population LEZ specifically wants to keep anonymous. A persistent on-chain taker identity that accumulates reputation is at direct odds with the privacy positioning, because reputation requires linkability across swaps by definition. Two partial paths:

- **Capped anonymous takers**: first-swap takers are size-capped (e.g., $100 notional) without reputation; the cap relaxes after N successful completions under the same persistent pseudonym. Linkability is opt-in: a taker who wants larger size accepts linkability as the cost.
- **Zero-knowledge reputation**: takers prove "I have completed ≥ N swaps with zero slashes" without revealing which swaps, using a Sparse Merkle Tree of swap outcomes and a zk membership proof. Preserves unlinkability across swaps while letting the taker borrow against accumulated reputation. Engineering-expensive; requires a circuit-friendly execution layer on LEZ (which the positioning section already argues for on other grounds).

**Risk**: even zk-reputation has linkability sidechannels. Timing of reputation accrual, swap size distribution, and the maker's view of which takers it interacts with all leak information. The privacy claim is "unlinkable across the public ledger" not "unlinkable to a maker who actively profiles its counterparties". For a privacy-positioned DEX this distinction matters and should be documented for users.

**LEZ implication**: reputation is a low-cost layer on top of either mitigation (1) or mitigation (2) for the *maker* role, and worth designing in from day one. Taker reputation is a deferred, second-order question that should *not* gate the v1 design; the bond from mitigation (2) is sufficient for the v1 free-option problem without requiring takers to be linkable.

### Synthesis

None of the three mitigations is sufficient on its own; their combination defines a specific niche.

- Mitigation (1) collapses the option for 1:1 wrapped/SPV pairs where the underlying-chain proof is principled. This works for BTC and ETH (light-client inclusion proofs) and does *not* work for XMR with current cryptography (no non-disclosing proof primitive exists). Oracle-priced synthetics do not satisfy this mitigation; they keep the option live because the peg slack is itself the volatility.
- Mitigation (2) collapses the option bilaterally for BTC/ETH (Tier 1) and only on the maker side for XMR (Tier 2). It reintroduces a weaker trust assumption (the LEZ slashing contract and the adaptor-signature scheme's soundness) and does not fix settlement time or interactivity.
- Mitigation (3) compounds (2) by making defection more expensive over a maker's career, and becomes load-bearing on the taker side for the XMR Tier-2 pair (where bonding cannot constrain Alice's pre-lock free option). The privacy tension on takers is real and must be addressed via capped pseudonyms or zk membership proofs.

The honest framing for LEZ is: **a bonded atomic-swap primitive with maker reputation is the right *complement* to a middle-chain AMM, not a *substitute* for it**. The middle-chain AMM is the right answer for the bulk of cross-chain swap volume, on the same grounds that pushed Thorchain, Serai, Maya, and Chainflip to converge there. The bonded atomic swap is the right answer for users who specifically reject vault custody and accept settlement-time/interactivity costs in exchange for the stronger trust model. LEZ is in a rare position to ship both, because its execution-layer privacy primitives (shielded swap intents, sealed-bid matching, stealth outbounds, Waku transport) are useful to both modes.

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
