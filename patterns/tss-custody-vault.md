---
tags: [pattern, custody, tss, mpc]
status: established
---

# Pattern: TSS custody vaults for cross-chain swap settlement

A middle-chain DEX needs to custody assets on every external chain it serves. Instead of using an externally owned account (centralisation) or a smart contract bridge (limited to chains with EVM-like contracts; vulnerable to contract bugs), it can use a Threshold Signature Scheme (TSS) multisig where validators collectively control a single public key per chain. No party ever holds the full private key.

## Core idea

- Validators run a distributed key generation (DKG) ceremony producing one public key per external chain plus secret shares; the corresponding private key never exists at any single location.
- Signing requires at least `ceil(n * 2/3)` (or other threshold) parties to cooperate per signature; outputs are valid standard ECDSA or EdDSA signatures, so the foreign chain sees just a normal transaction.
- Validator rotation triggers a new keygen + a migration of all custodied funds from old to new vault addresses.

## Reference implementation: Thorchain Asgard vaults

- Scheme: GG20 ECDSA (Gennaro and Goldfeder 2020); EdDSA support added for Solana style chains. Fork of Binance `tss-lib` upgraded from GG18 to GG20 ([TSS docs](https://dev.thorchain.org/bifrost/tss.html)).
- Threshold: two thirds supermajority of vault members must cooperate.
- Sharding: logical vault split into physical vaults sized by `asgardsize` (default 20 nodes) so 120 nodes yield 6 shards ([Bifrost, TSS and Vaults](https://docs.thorchain.org/technical-documentation/technology/bifrost-tss-and-vaults.md)).
- Lifecycle: `InitVault` (post keygen) -> `Active` -> `Retiring` (drained over 30 minute rounds) -> `Inactive` ([vault behaviours](https://dev.thorchain.org/bifrost/vault-behaviors.html)).
- Churn cadence: every 3 days oldest, slowest, lowest bonded node is rotated out ([State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/)).
- Failed keygen / keysign: blame is reported to consensus and offending nodes are slashed ([TSS](https://dev.thorchain.org/bifrost/tss.html)).

## Related: deprecated Yggdrasil hot vaults

Thorchain originally let each node hold a per node Yggdrasil hot vault containing up to 50 percent of network funds, signed unilaterally to accelerate small outbounds. ADR 002 deprecated these; nodes must drain Yggdrasil balances before unbonding ([Leaving docs](https://docs.thorchain.org/thornodes/leaving)). Lesson: speed shortcuts that bypass the threshold reintroduce single point of failure risk.

## Trade-offs

| Property | TSS multisig | Smart contract bridge | EOA / custodian |
|----------|-------------|------------------------|------------------|
| Works on any chain (UTXO, EVM, Cosmos) | yes | no, EVM only | yes |
| Single private key | never reconstructed | n/a | yes, single point |
| Slashable on misbehaviour | yes (via L1 consensus) | partially (bond outside) | no |
| Performance | multi round, slow | one transaction | instant |
| Code surface | TSS lib plus chain clients | contract code | minimal |
| Key rotation cost | full vault drain | redeploy + migrate | sweep |

## Known failure modes

- **Implementation bugs in TSS library**: the May 2026 Thorchain incident is attributed to a GG20 weakness in the TSSHOCK class (malformed proofs allowing key reconstruction by a colluding signer over many rounds), drained ~$10.8M ([Crypto Times](https://www.cryptotimes.io/2026/05/17/10-8-million-drained-inside-the-thorchain-exploit-that-froze-cross-chain-defi-for-13-hours/), [AMBCrypto](https://ambcrypto.com/thorchain-exploit-raises-fresh-concerns-over-mpc-wallet-security/)).
- **Observer / signer separation**: the 2021 Bifrost exploits were not TSS failures but signer side trust of manipulated event data; even a perfect TSS will sign anything the state machine queues ([2021 postmortem](https://medium.com/thorchain/post-mortem-eth-router-exploits-1-2-and-premature-return-to-trading-incident-2908928c5fb)).
- **Churn migration windows**: during migration both old and new vaults are live; mis-routed deposits or partial drains create transient solvency mismatches ([vault behaviours](https://dev.thorchain.org/bifrost/vault-behaviors.html)).

## Reference implementation: Serai per-network FROST vaults

- Scheme: FROST (Schnorr threshold) per `draft-irtf-cfrg-frost-11`, per-curve. Bitcoin and Ethereum use Secp256k1, Monero uses Ed25519, Serai's own consensus uses Ristretto. Source: [Serai FROST spec](https://github.com/serai-dex/serai/blob/develop/spec/cryptography/FROST.md) (accessed 2026-05-19).
- Threshold: `t = floor(n * 2/3) + 1`. Custody is hard-capped at 33% of the validator set's allocated stake by the protocol; deposits beyond that must be rejected. Source: [Validator Sets spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/Validator%20Sets.md) (accessed 2026-05-19).
- Per-network staking (not global): a validator can choose which external networks to validate over, staking separately per network, and only runs the matching processors. Up to 600 validators planned at launch. Source: [How Far We've Come](https://serai.exchange/2023/10/06/how-far-weve-come.html) (accessed 2026-05-19).
- DKG: migrated from a three-round PedPoP-with-complaint protocol to a one-round eVRF-based robust DKG with verifiable encryption of whole 256-bit shares; tolerates one-third offline; HashCloak-proven. Source: [eVRF DKG blog](https://serai.exchange/2025/09/26/dkg-evrf-security-proofs.html) (accessed 2026-05-19).
- Monero CLSAG handling: FROSTLASS protocol extends FROST techniques to CLSAG signatures with constant per-participant upload, linear computation, and identifiable aborts; Cypher Stack security proof. Source: [SeraiDEX X](https://x.com/SeraiDEX/status/1902028683608531050) (accessed 2026-05-19).
- Ethereum router: on-chain Schnorr verifier contract authenticates validator-set messages; Trail of Bits audit returned zero high/medium/low findings. Source: [ToB audit blog](https://serai.exchange/2025/06/06/ethereum-contracts-audited-by-tob.html) (accessed 2026-05-19).
- Rotation: per-session DKG with queue-block + `CONFIRMATIONS` activation, multi-window forwarding from old multisig (CONFIRMATIONS + 10 min, then more CONFIRMATIONS, then a 6-hour residual forward), and a multi-generation retrospective audit by the new multisig to surface theft. Source: [Multisig Rotation spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Multisig%20Rotation.md) (accessed 2026-05-19).
- Audit posture: separate audits across Cypher Stack (FROST, monero-oxide, Bitcoin), Trail of Bits (Ethereum router), HashCloak (DKG proofs), and Security Research Labs (Substrate chain, completed April 2026 with 0 critical / 5 high / 3 medium / 1 low / 12 informational). Source: [Audit blog](https://serai.exchange/2026/04/15/serai-blockchain-audited.html) (accessed 2026-05-19).

## Used by

- [[../projects/thorchain]]: GG20 + EdDSA, Asgard vaults
- [[../projects/serai]]: FROST across all networks, per-curve, with FROSTLASS for Monero CLSAG; see [[serai-trust-model]] for the full trust model

## See also

- [[middle-chain-swap-settlement]]
- [[serai-trust-model]]
- [[thorchain-trust-model]]
