---
tags: [project, middle-chain, cross-chain-dex, substrate]
ecosystem: Standalone (Substrate)
category: Cross-chain DEX
website: https://serai.exchange
docs: https://docs.serai.exchange
launched: Pre-mainnet (Substrate blockchain audit completed April 2026; integration testing and internal testnet pending before public testnet and mainnet)
---

# Serai

Serai is a Substrate-based execution layer whose validator set forms threshold multisig wallets to custody coins on connected external networks (Bitcoin, Ethereum, Monero), with a constant-product AMM running natively on the chain. It is positioned as a fairly launched, audit-first cross-chain DEX with no premine, no ICO, and no admin keys; as of mid-2026 the project is post-audit but pre-launch, led by Luke Parker (kayabaNerve) and a small core team.

## Adoption metrics

| Metric                          | Value                                                                                  | Date       | Source                                                                                                  |
|---------------------------------|----------------------------------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------------------|
| Mainnet status                  | Not launched; Substrate audit complete, internal testnet pending                       | 2026-04-15 | [Audit of Serai's Substrate Blockchain](https://serai.exchange/2026/04/15/serai-blockchain-audited.html) |
| Supported assets (planned)      | BTC, ETH, DAI, XMR, plus native SRI                                                    | 2026-05-19 | [serai.exchange](https://serai.exchange/)                                                               |
| Validators (cap at launch)      | Up to 600, staking per network                                                         | 2023-10-06 | [How Far We've Come](https://serai.exchange/2023/10/06/how-far-weve-come.html)                          |
| Codebase size                   | 141,980 lines Rust (Serai's Substrate fork) vs 663,615 upstream                        | 2026-04-15 | [Audit blog](https://serai.exchange/2026/04/15/serai-blockchain-audited.html)                           |
| Substrate audit findings        | 0 critical, 5 high, 3 medium, 1 low, 12 informational                                  | 2026-04-15 | [Audit blog](https://serai.exchange/2026/04/15/serai-blockchain-audited.html)                           |
| Repo activity                   | 414 stars, 79 forks, 1,886 commits on `develop`                                        | 2026-05-19 | [serai-dex/serai](https://github.com/serai-dex/serai)                                                   |
| Token (SRI) supply pre-mainnet  | Does not exist; no ICO, IEO, presale, dev tax, or airdrop                              | 2026-05-19 | [serai.exchange](https://serai.exchange/)                                                               |
| Bug bounty                      | Up to USD 30,000 via Immunefi                                                          | 2026-05-19 | [Immunefi: Serai](https://immunefi.com/bug-bounty/serai/information/)                                   |
| External chain block time (BTC) | Per-network `CONFIRMATIONS` constant (numeric value in source, not in spec doc)        | 2026-05-19 | [Multisig Rotation spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Multisig%20Rotation.md) `[NOT FOUND]` per-network numeric values in published spec |
| Serai chain block time          | `[NOT FOUND]` in spec; inherited from Substrate defaults until configured              | 2026-05-19 | [serai-dex/serai](https://github.com/serai-dex/serai)                                                   |

## How it works

### User perspective

1. A user sends BTC, ETH, DAI, or XMR to the current multisig address on the source network, embedding a SCALE-encoded "In Instruction" alongside the transfer. Encodings differ by chain:
   - Bitcoin: `OP_RETURN` output, up to 80 bytes ([Bitcoin spec](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Bitcoin.md)).
   - Ethereum: either ERC20 calldata appended to `transfer`/`transferFrom`, or a direct call to the Serai Router's `inInstruction` ([Ethereum spec](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Ethereum.md)).
   - Monero: `tx.extra` with `TX_EXTRA_NONCE` tag, up to 254 bytes ([Monero spec](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Monero.md)).
2. A "Shorthand" form expands into a `RefundableInInstruction`: for example, a swap shorthand expands into a DEX instruction that combines deposit, swap, and (optionally) burn to a destination address ([Instructions spec](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Instructions.md)).
3. Serai's per-network Processor scans finalised blocks on the external chain, detects outputs to the current multisig key, and batches them ([Scanning spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Scanning.md)).
4. The validator set produces a threshold signature on the Batch and publishes it to Serai as an unsigned transaction; verification on Serai is O(1) ([In Instructions spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/In%20Instructions.md)).
5. On confirmation, Serai mints an internal representation of the deposited coin (e.g. internal BTC) and executes the swap against the relevant pool.
6. To withdraw, the user (or the swap pipeline) emits an `Out Instruction` and burns the internal coin; this enqueues a payment which the Processor builds, threshold-signs, and broadcasts on the destination chain ([Processor spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Processor.md)).

### Protocol perspective

- **Serai chain (Substrate):** authoritative state, validator set, key registry, batch inclusion, AMM. Substrate is chosen as "an implementation detail" for validator selection and ordering, not as a novel consensus innovation ([Audit blog](https://serai.exchange/2026/04/15/serai-blockchain-audited.html)). Uses GRANDPA-style finality (the audit explicitly notes a high-severity finding where GRANDPA validation logic was inverted, confirming GRANDPA usage).
- **Tributaries:** per-multisig disposable side-chains, used only as a verifiable broadcast layer for DKG and signing messages. They have BFT consensus but are not load-bearing for finality; the Serai mainnet remains the authoritative settlement layer ([Tributary spec](https://github.com/serai-dex/serai/blob/develop/spec/coordinator/Tributary.md)).
- **Coordinator:** one per validator; talks to local Processors, to other Coordinators over a secondary P2P network, and to the Serai node. Publishes signed Batches as unsigned Serai transactions ([Coordinator spec](https://github.com/serai-dex/serai/blob/develop/spec/coordinator/Coordinator.md)).
- **Processor:** one per external network per validator; scans finalised blocks, signs Batches, builds and publishes outbound transactions, manages UTXOs ([Processor spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Processor.md)).
- **Message Queue:** ordered service-to-service bus internal to a validator ([README](https://github.com/serai-dex/serai)).

## Why not atomic swaps?

Despite Luke Parker (kayabaNerve) having direct context in the Bitcoin to Monero atomic-swap ecosystem (the Monero project publicly grouped Serai's team alongside Farcaster, COMIT, and Thorchain in January 2021: [@monero on X](https://x.com/monero/status/1354495848391049218), accessed 2026-05-19), Serai chose a middle-chain DEX. The strongest direct quote located is from a MoneroTalk interview: *"while I do love atomic swaps [..] I don't feel the community actually wants atomic swaps, which is a brutal truth"* ([Monero Observer summary](https://monero.observer/monerotalk-kayabanerve-interview-serai-dex/), accessed 2026-05-19). No Serai blog post, RFC, GitHub issue, or spec file gives a written design-time rejection; the rationale lives only in podcast form. See [[patterns/atomic-swaps-vs-middle-chain]] for the full investigation, including the implied UX/liquidity reasoning reconstructed from the Serai design itself.

## Architecture decisions

- **Substrate over a custom L1:** Serai treats Substrate as plumbing; the team forked it and trimmed it from 663,615 to 141,980 lines of Rust to bound the audit surface ([Audit blog](https://serai.exchange/2026/04/15/serai-blockchain-audited.html)). Rationale: focus engineering on the cross-chain primitive (threshold custody) rather than novel consensus.
- **Stake per network, not globally:** validators bond stake against the specific networks they choose to validate; they need only run nodes for those external chains plus a Serai node, not all of them. Cap of up to 600 validators at launch ([How Far We've Come](https://serai.exchange/2023/10/06/how-far-weve-come.html)).
- **FROST (Schnorr threshold) over threshold ECDSA:** Serai chose FROST because threshold ECDSA has a track record of practical attacks (Alpha-Rays against GG18/GG20 in 2021; further Makriyannis and Yomtov attacks in 2023). Schnorr threshold signatures have clean security proofs and IETF standardisation ([To Schnorr or Not to Schnorr](https://serai.exchange/2023/10/08/to-schnorr-or-not-to-schnorr.html)).
- **Per-curve cryptography:** Bitcoin and Ethereum use Secp256k1, Monero uses Ed25519, Serai itself uses Ristretto. SCALE-encoded ([Constants spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Constants.md)).
- **AMM = constant-product `xy=k` at launch:** rejected concentrated liquidity for v1 on the grounds that it disadvantages passive LPs and conflicts with a community-driven fair launch. All pools paired against SRI to route the network's liquidity through a single hub ([docs.serai.exchange/amm](https://docs.serai.exchange/amm/), [serai.exchange](https://serai.exchange/)).
- **Tributaries as ephemeral verifiable broadcast:** signing protocol messages flow through per-multisig disposable chains that reach BFT consensus then are discarded, preventing replay and avoiding storage bloat on the mainnet ([Tributary spec](https://github.com/serai-dex/serai/blob/develop/spec/coordinator/Tributary.md), [How Far We've Come](https://serai.exchange/2023/10/06/how-far-weve-come.html)).
- **One-round robust DKG via eVRF:** the project moved from PedPoP with a complaint round (three rounds, always-online assumption) to a one-round protocol based on the eVRF construction (paper 2024/397). Encrypts whole 256-bit shares with a proof of correctness; security proofs contracted from HashCloak ([DKG eVRF blog](https://serai.exchange/2025/09/26/dkg-evrf-security-proofs.html)).

## Custody model

- **Threshold:** `t-of-n` multisig with `t = floor(n * 2/3) + 1` ([Validator Sets spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md)).
- **Economic ceiling:** a validator set can securely hold coins valued up to 33% of its allocated stake; beyond that the protocol's economic security assumption breaks ([Validator Sets spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md)).
- **Key generation:** distributed key generation runs on the Tributary; on completion the resulting group key is confirmed on Serai via a MuSig-style signature requiring 100% participant agreement ([Validator Sets spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md)).
- **Rotation:** at each session (epoch) a new multisig is generated; activation happens at a designated external-chain "queue block" plus `CONFIRMATIONS` blocks. The new multisig must verify, retrospectively across multiple generations, that all prior multisigs behaved correctly before assuming custody. The old multisig continues to handle in-flight batches and burns through several windows totalling many hours, then forwards residual outputs to the new key ([Multisig Rotation spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Multisig%20Rotation.md)).
- **Misbehaviour handling during DKG:** removal of malicious validators is encoded by a MuSig signature naming the excluded signers; honest validators must also stop accepting transactions from them on the tributary and exclude them from Tendermint-style consensus ([DKG Exclusions spec](https://github.com/serai-dex/serai/blob/develop/spec/DKG%20Exclusions.md)).
- **Slashing:** validators that prevent multisig creation are subject to slashing or removal; cooldown of one session before deallocation after rotation ([Validator Sets spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md)). Specific slashing magnitudes are `[NOT FOUND]` in published specs.
- **External signature schemes used by Processor:**
  - Bitcoin: Schnorr (BIP-340) via modular FROST.
  - Ethereum: Schnorr verified by the Serai Router contract (Trail of Bits audited, zero high or medium findings; identity-point check made explicit) ([ToB audit blog](https://serai.exchange/2025/06/06/ethereum-contracts-audited-by-tob.html)).
  - Monero: FROSTLASS, a FROST-inspired threshold signing protocol for CLSAGs with constant per-participant upload, linear computation, and identifiable aborts; security proven by Cypher Stack ([SeraiDEX on X](https://x.com/SeraiDEX/status/1902028683608531050), [monero-oxide blog](https://serai.exchange/2025/09/09/monero-serai-oxide.html)).

See [[patterns/tss-custody-vault]] for a generalised treatment.

## Privacy properties

- **On-chain transparency:** Serai itself is a public Substrate chain. Validator set, stake, key registrations, In Instructions, Out Instructions, swap intents, and AMM pool state are all public to anyone running a Serai node. There is no shielded execution and no encrypted mempool described in the specs.
- **No native shielding for swap intents:** swap shorthand expands deterministically on Serai into a Dex instruction; the swap path and recipient internal account are observable.
- **Monero is custodied, not used as a privacy sink:** XMR is treated like any other external coin; deposits and withdrawals are observable on the Monero chain (subject to Monero's own ring signature privacy on the deposit-side input set), but inside Serai the internal Monero representation is a regular fungible balance. Serai explicitly clarifies it is not Monero-focused: integration is technically heavy but architecturally equal to BTC and ETH ([Is Serai Monero Focused?](https://serai.exchange/2023/10/07/is-serai-monero-focused.html)).
- **Net privacy improvement is link-breaking, not unobservability:** a user can deposit XMR, swap to BTC, and withdraw to a fresh BTC address, breaking the on-chain link between the XMR source and BTC destination at the cost of trusting Serai's threshold custody. The Serai-side trace itself is fully public.
- **Implication for LEZ:** Serai leaves a clear privacy gap that a zk-shielded execution zone could fill: identical custody model, but with private balances and sealed swap intents.

See [[patterns/middle-chain-swap-settlement]] for the broader pattern.

## Differentiators vs [[projects/thorchain]] and [[projects/wormhole]]

- **vs Thorchain:** both use a Substrate-style middle chain with a validator-controlled TSS custody vault and an `xy=k` AMM. Differences: Serai uses FROST/Schnorr across all networks with per-network keys (Thorchain uses TSS-ECDSA, GG20-family historically); Serai's validator set caps at 600 with per-network staking (Thorchain caps active set at around 100 with `RUNE`-bonded global staking); Serai targets BTC/ETH/DAI/XMR initially, with XMR as a first-class citizen, whereas Thorchain does not support Monero; Serai is pre-mainnet as of mid-2026, Thorchain is live and has suffered multiple solvency and contract incidents.
- **vs Wormhole:** Wormhole is an attestation bridge with a guardian set signing messages between chains; it does not custody or execute swaps natively. Serai is the opposite design point: the middle chain *is* the custodian and the execution venue, settling swaps atomically against pools rather than passing messages to external venues.
- **Engineering posture:** Serai is unusually audit-led for a pre-launch DEX: separate audits by Cypher Stack (FROST, monero-oxide, Bitcoin-Serai), Trail of Bits (Ethereum router and Schnorr verifier), HashCloak (DKG proofs), and Security Research Labs (Substrate chain), with audit reports surfaced publicly via GitHub issues during the engagement ([Audit blog](https://serai.exchange/2026/04/15/serai-blockchain-audited.html), [Audit kick-off](https://serai.exchange/2026/01/14/serai-blockchain-audit.html)).

## Limitations and criticisms

- **Asset coverage is narrow:** BTC, ETH, DAI, XMR only at launch. Each new chain requires a chain-specific Processor library and a curve-compatible FROST integration; this is not cheap (Monero alone required producing the FROSTLASS protocol and a security proof).
- **Trust assumption is a 2/3 threshold over a stake-bonded validator set:** a coalition of >1/3 of stake can stall (liveness attack), and a >2/3 coalition can sign arbitrary withdrawals from the multisig vault. The economic security ceiling is explicitly stated at 33% of allocated stake ([Validator Sets spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md)); above that, custody is no longer cryptoeconomically safe.
- **Bootstrap problem:** SRI does not exist before mainnet, with no presale or airdrop. Pre-economic-security phase relies on bootstrapping validator stake by selling freshly minted SRI for external coins, which is a chicken-and-egg trust problem until liquidity grows ([Economics](https://docs.serai.exchange/economics/)).
- **Latency:** no published end-to-end latency target. Swap finality from a user's perspective is at minimum: source-chain confirmation depth (`CONFIRMATIONS` blocks) + Batch inclusion on Serai + AMM execution + Out Instruction signing + destination-chain confirmation. For Bitcoin or Monero the source-chain confirmation alone is on the order of tens of minutes; end-to-end timing is `[NOT FOUND]`.
- **Traction:** sub-1000 GitHub stars, no live network, small contributor base centred on Luke Parker. The project has been in development since around 2021 and is still pre-public-testnet in May 2026.
- **No mempool privacy:** swap intents are visible on the Serai mempool and chain; MEV concerns equivalent to Uniswap V2 on a single ordered chain.
- **Bridges-to-bridges risk surface:** the Ethereum Router contract is a classic bridge target; ToB audit was clean but historically these are the highest-value attack surfaces in cross-chain protocols.

## Sources

- [Serai DEX homepage](https://serai.exchange/) :: accessed 2026-05-19
- [Serai Documentation](https://docs.serai.exchange/) :: accessed 2026-05-19
- [Serai AMM docs](https://docs.serai.exchange/amm/) :: accessed 2026-05-19
- [Serai Economics docs](https://docs.serai.exchange/economics/) :: accessed 2026-05-19
- [serai-dex/serai GitHub](https://github.com/serai-dex/serai) :: accessed 2026-05-19
- [Spec: Serai overview](https://github.com/serai-dex/serai/blob/develop/spec/Serai.md) :: accessed 2026-05-19
- [Spec: Validator Sets](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md) :: accessed 2026-05-19
- [Spec: Constants](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Constants.md) :: accessed 2026-05-19
- [Spec: In Instructions](https://github.com/serai-dex/serai/blob/develop/spec/protocol/In%20Instructions.md) :: accessed 2026-05-19
- [Spec: Processor](https://github.com/serai-dex/serai/blob/develop/spec/processor/Processor.md) :: accessed 2026-05-19
- [Spec: Scanning](https://github.com/serai-dex/serai/blob/develop/spec/processor/Scanning.md) :: accessed 2026-05-19
- [Spec: Multisig Rotation](https://github.com/serai-dex/serai/blob/develop/spec/processor/Multisig%20Rotation.md) :: accessed 2026-05-19
- [Spec: UTXO Management](https://github.com/serai-dex/serai/blob/develop/spec/processor/UTXO%20Management.md) :: accessed 2026-05-19
- [Spec: Coordinator](https://github.com/serai-dex/serai/blob/develop/spec/coordinator/Coordinator.md) :: accessed 2026-05-19
- [Spec: Tributary](https://github.com/serai-dex/serai/blob/develop/spec/coordinator/Tributary.md) :: accessed 2026-05-19
- [Spec: FROST](https://github.com/serai-dex/serai/blob/develop/spec/cryptography/FROST.md) :: accessed 2026-05-19
- [Spec: Distributed Key Generation](https://github.com/serai-dex/serai/blob/develop/spec/cryptography/Distributed%20Key%20Generation.md) :: accessed 2026-05-19
- [Spec: DKG Exclusions](https://github.com/serai-dex/serai/blob/develop/spec/DKG%20Exclusions.md) :: accessed 2026-05-19
- [Spec: Bitcoin integration](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Bitcoin.md) :: accessed 2026-05-19
- [Spec: Ethereum integration](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Ethereum.md) :: accessed 2026-05-19
- [Spec: Monero integration](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Monero.md) :: accessed 2026-05-19
- [Spec: Instructions](https://github.com/serai-dex/serai/blob/develop/spec/integrations/Instructions.md) :: accessed 2026-05-19
- [Blog: Audit of Serai's Substrate Blockchain (Apr 2026)](https://serai.exchange/2026/04/15/serai-blockchain-audited.html) :: accessed 2026-05-19
- [Blog: Serai DEX's Blockchain's Audit Kicks Off (Jan 2026)](https://serai.exchange/2026/01/14/serai-blockchain-audit.html) :: accessed 2026-05-19
- [Blog: Security Proofs for One-Round Robust Threshold DKG (Sep 2025)](https://serai.exchange/2025/09/26/dkg-evrf-security-proofs.html) :: accessed 2026-05-19
- [Blog: Announcing monero-oxide (Sep 2025)](https://serai.exchange/2025/09/09/monero-serai-oxide.html) :: accessed 2026-05-19
- [Blog: Ethereum Contracts Audited by Trail of Bits (Jun 2025)](https://serai.exchange/2025/06/06/ethereum-contracts-audited-by-tob.html) :: accessed 2026-05-19
- [Blog: To Schnorr or Not to Schnorr (Oct 2023)](https://serai.exchange/2023/10/08/to-schnorr-or-not-to-schnorr.html) :: accessed 2026-05-19
- [Blog: How Far We've Come (Oct 2023)](https://serai.exchange/2023/10/06/how-far-weve-come.html) :: accessed 2026-05-19
- [Blog: Is Serai Monero Focused? (Oct 2023)](https://serai.exchange/2023/10/07/is-serai-monero-focused.html) :: accessed 2026-05-19
- [Immunefi: Serai bug bounty](https://immunefi.com/bug-bounty/serai/information/) :: accessed 2026-05-19
- [Serai DEX FROST presentation (Blockchain Commons)](https://developer.blockchaincommons.com/assets/pdfs/frostimp2/presentation-serai.pdf) :: accessed 2026-05-19
- [SeraiDEX X post on FROSTLASS proof](https://x.com/SeraiDEX/status/1902028683608531050) :: accessed 2026-05-19
- [Monero Observer: MoneroTalk interview with Luke Parker](https://monero.observer/monerotalk-kayabanerve-interview-serai-dex/) :: accessed 2026-05-19
