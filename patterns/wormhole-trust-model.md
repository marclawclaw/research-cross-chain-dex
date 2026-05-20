---
tags: [pattern, trust-model, custody, guardian-network, wormhole]
seen_in: [wormhole]
---

# Wormhole Trust Model

Lead question: *who custodies and releases the bridged assets, and on
what trust assumptions?* For [[projects/wormhole]] the answer is a
permissioned committee of 19 named validator companies whose 13-of-19
signatures authorise mints, burns, and contract upgrades on every
integrated chain. Unlike [[projects/thorchain]] and [[projects/serai]]
this committee posts **no bonded, slashable stake**: the only thing
stopping collusion is reputation and per-chain smart contract
defences. See also [[patterns/signer-federation-trust]] for the cross
project comparison.

## 1. Guardian set composition

Wormhole describes itself as a Proof-of-Authority network: "Wormhole
relies on a network of established validator companies instead of
token-based incentives. These 19 Guardians are among the most trusted
operators in the industry, real entities with a track record, not
anonymous participants."
(https://wormhole.com/docs/protocol/infrastructure/guardians/,
accessed 2026-05-19)

The set is fixed at 19 organisations. The membership has rotated since
launch; commonly cited members across primary and secondary sources
include:

- Jump Crypto (parent of Wormhole; acquired the original Certus One
  team)
  (https://www.chainalysis.com/blog/wormhole-hack-february-2022/,
  accessed 2026-05-19)
- Chorus One, Everstake, Figment, Staked, P2P Validator, Staking
  Facilities, Staking Fund, HashKey Cloud, Forbole, ChainLayer,
  Chainode Tech, 01node, Inotel, MCF (Smith MCF), Moonlet,
  syncnode, Triton, xLabs
  (https://www.disruptionbanking.com/2024/01/30/guardians-of-the-wormhole-the-superheroes-protecting-blockchain-bridges/,
  accessed 2026-05-19; cross-referenced with
  https://01node.com/01node-a-wormhole-guardian/, accessed
  2026-05-19)

The canonical live set is published on the Wormhole dashboard
(https://wormhole-foundation.github.io/wormhole-dashboard/#/?endpoint=Mainnet,
accessed 2026-05-19); the docs explicitly defer to the dashboard
rather than enumerating members in prose
(https://wormhole.com/docs/protocol/infrastructure/guardians/,
accessed 2026-05-19).

**Contrast with [[projects/serai]] and [[projects/thorchain]]:**
membership is permissioned, not earned by bonding tokens. There is no
auction, no slot count, no on-chain stake metric: Guardians are added
or removed by Guardian governance vote.

## 2. Threshold scheme

VAAs (Verifiable Action Approvals) require 13-of-19 Guardian
signatures, a two-thirds supermajority. "Once a two-thirds
supermajority of Guardians agree the message is valid, they sign a
keccak256 hash of the message body." Each Guardian signs
**independently** with a 65-byte secp256k1 ECDSA signature; the
signatures are concatenated into the VAA header and verified on the
destination chain
(https://wormhole.com/docs/protocol/infrastructure/vaas/, accessed
2026-05-19).

This is *not* a TSS in the GG20 or FROST sense. There is no
distributed key generation, no aggregate signature, no shared private
key shard. Each Guardian holds its own keypair; verification on chain
iterates the signature array against the stored Guardian set.

Implications:

- The on-chain footprint per VAA is larger (19 signatures encoded,
  any 13 valid), but the verification has no MPC liveness
  requirement: a Guardian can be down without breaking key generation
  ceremonies, unlike Serai's FROST tributaries or Thorchain's GG20
  keygen-per-churn.
- Compromise of any 13 keys is sufficient to forge any VAA on any
  chain. There is no per-chain or per-asset key isolation as in
  Serai's per-coin tributaries (see [[projects/serai]]).

## 3. Asset custody model

Each integrated chain hosts a Wormhole Core contract plus a Token
Bridge contract. Native tokens are **locked** in the source-chain
Token Bridge; the destination-chain Token Bridge **mints** a wrapped
representation when it sees a valid VAA
(https://wormhole.com/docs/protocol/security/, accessed 2026-05-19).

Key points:

- No shared TSS vault. The trust root on every chain is the same: the
  current Guardian set's public keys, stored in the Core contract,
  plus the requirement that 13 of them have signed.
- Token Bridge contract upgrades and Guardian set updates are
  themselves authorised by signed governance VAAs from the same
  Guardian set, i.e. the Guardians self-govern: "Via governance,
  Guardians can upgrade ecosystem contract implementations and
  configure per-chain Delegated Guardian sets and security
  thresholds." (https://wormhole.com/docs/protocol/security/,
  accessed 2026-05-19)
- The W token MultiGov system (rolled out 2024-2025) layers a
  tokenholder DAO above Guardian governance for *protocol-level*
  decisions, but the cryptographic gate on every cross-chain action
  remains the 13-of-19 Guardian signature
  (https://wormhole.com/blog/connecting-the-internet-economy-wormhole-and-the-w-tokens-past-present-and,
  accessed 2026-05-19).

This is materially different from a middle-chain DEX such as
[[projects/serai]] or [[projects/thorchain]] where the bonded
validator set custodies a *single* vault per external coin and the
chain itself maintains the accounting. In Wormhole the accounting
lives in the contracts on every integrated chain; the Guardians are
not a state machine, they are signers.

## 4. What stops Guardians from colluding to steal

Wormhole's own framing: "19 globally distributed Guardian nodes sign
messages via private key proof of authority but distrust each other.
Diverse ops sec makes compromise nearly impossible."
(https://wormhole.com/platform/security, accessed 2026-05-19)

Real defences:

1. **Reputational stake.** Guardians are large, identifiable
   custodial/staking firms (Jump, Chorus One, Figment, P2P
   Validator, Everstake, etc.) whose other businesses depend on
   continued operation in regulated jurisdictions.
   (https://www.disruptionbanking.com/2024/01/30/guardians-of-the-wormhole-the-superheroes-protecting-blockchain-bridges/,
   accessed 2026-05-19)
2. **Operational heterogeneity.** "Each Guardian is a highly
   competent validator company with its own in-house processes for
   running, monitoring, and securing blockchain operations."
   (https://wormhole.com/docs/protocol/security/, accessed
   2026-05-19)
3. **Governor rate limits.** A per-chain Governor delays large or
   anomalous outflows to limit blast radius from any single bad VAA.
   (https://wormhole.com/docs/protocol/security/, accessed
   2026-05-19)
4. **Global Accountant.** A CosmWasm module on Wormhole Gateway
   "tracks the total circulating supply of all Wormhole assets
   across all chains, preventing any blockchain from bridging assets
   that could violate the supply invariant."
   (https://wormhole.com/docs/protocol/security/, accessed
   2026-05-19)
5. **Open source contracts and external audits** of the on-chain
   verification path.
   (https://wormhole.com/platform/security, accessed 2026-05-19)

What is explicitly *not* present:

- **No bonded slashable stake.** There is no Guardian collateral that
  is forfeit if 13 signers collude. This is the major contrast with
  [[projects/thorchain]] (RUNE bond, 3:1 target ratio of bonded
  value to pooled value) and [[projects/serai]] (SRI PoS stake,
  slashable). [NOT FOUND for any in-protocol Guardian bond or
  slashing condition; Wormhole governance and security docs describe
  PoA, not PoS, and make no mention of slashable Guardian
  collateral.]
- No fraud proofs or exit windows. A user holding wrapped assets has
  no on-chain recourse if the Guardians sign a malicious VAA: the
  destination contract will mint, and the source-chain lock is
  authoritative.

## 5. Failure modes: the February 2022 incident

On 2 February 2022 an attacker drained 120,000 wETH (~US$326 million
at the time) from the Solana Token Bridge.
(https://www.chainalysis.com/blog/wormhole-hack-february-2022/,
accessed 2026-05-19)

Root cause: a **smart contract bug on the Solana side**, not Guardian
collusion. The Solana Token Bridge used a deprecated Solana SDK
function (`load_instruction_at`) to confirm that a prior instruction
had invoked the secp256k1 precompile to verify Guardian signatures.
That helper did **not** validate that the supplied "Instructions"
sysvar account was the real Solana sysvar. The attacker passed in a
fabricated account whose data made the check pass without any actual
secp256k1 verification, then submitted a forged VAA to mint 120k
wETH. (https://halborn.com/explained-the-wormhole-hack-february-2022/,
accessed 2026-05-19;
https://www.certik.com/resources/blog/wormhole-bridge-exploit-incident-analysis,
accessed 2026-05-19)

Critically: "This was explicitly a smart contract vulnerability, not
a guardian collusion issue."
(https://halborn.com/explained-the-wormhole-hack-february-2022/,
accessed 2026-05-19)

Recovery: Jump Crypto, the protocol's parent, "intervened on February
3, 2022, depositing Ether to replace stolen funds after ransom
negotiation attempts failed."
(https://www.certik.com/resources/blog/wormhole-bridge-exploit-incident-analysis,
accessed 2026-05-19) Jump deposited 120,000 ETH from its own
treasury, making wrapped-asset holders whole; this was a discretionary
corporate bailout, not a protocol mechanism. A later counter-exploit
(February 2023) recovered roughly US$140 million of the attacker's
positions.
(https://www.chainalysis.com/blog/wormhole-hack-february-2022/,
accessed 2026-05-19)

Subsequent hardening (visible in current docs):

- **Governor** rate limits on outflows.
  (https://wormhole.com/docs/protocol/security/, accessed
  2026-05-19)
- **Global Accountant** supply invariant enforcement on Gateway.
  (https://wormhole.com/docs/protocol/security/, accessed
  2026-05-19)
- **Delegated Guardian sets** allowing per-chain subsets to perform
  on-chain observation, with the final 13-of-19 VAA threshold
  unchanged.
  (https://wormhole.com/docs/protocol/security/, accessed
  2026-05-19)
- An evolved emergency shutdown strategy that "leverage[s] the
  existing upgrade authority via governance to temporarily patch
  smart contracts for vulnerabilities … (eg. temporarily disabling
  the affected function)."
  (https://wormhole.com/docs/protocol/security/, accessed
  2026-05-19)

The 2022 incident is instructive precisely because it bypassed the
trust model entirely: the attacker did not need any Guardian to
cooperate, only a contract bug on one integrated chain. This is a
structural risk of having identical trust at the *verification* layer
but heterogeneous implementations across many chains.

## 6. Comparison to Serai and Thorchain

[[projects/wormhole]] secures user funds with a permissioned committee
of 19 well-known infrastructure firms whose 13-of-19 signature
authorises any cross-chain action and any contract upgrade; the
Guardians have **no bonded, slashable stake** and the security
argument is reputational plus defence in depth (Governor, Global
Accountant, audits). [[projects/thorchain]] inverts this: its ~100
active nodes are selected by a bond auction, post slashable RUNE
collateral targeted at three times the pooled TVL, and authorise vault
spends through a GG20 TSS over per-Asgard vaults; the federation is
permissionless to enter (by bond) and economically exposed to
misbehaviour. [[projects/serai]] sits closer to Thorchain on stake but
closer to Wormhole on key structure: a permissionless PoS validator
set bonds SRI and signs external-chain spends through FROST t-of-n per
external coin, with slashing for misbehaviour. Wormhole therefore
trades stake-based economic security for the operational simplicity
and chain-agnostic verification of independent ECDSA signatures, and
relies on off-protocol mechanisms (reputation, Jump Crypto's
treasury, rate limiters) to absorb failure when the trust model is
breached or bypassed.
