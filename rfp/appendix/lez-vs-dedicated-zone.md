# LEZ Program vs Dedicated Zone

Should the human-friendly naming layer (Layer 2) run as a program on
the canonical Logos LEZ, or should it have its own dedicated execution
zone?

## ENS on Ethereum L1 vs the Abandoned L2

ENS tried both paths and ended up back on L1.

**Timeline:**

| Date | Decision |
|------|----------|
| May 2024 | ENSv2 announced; L2 under evaluation |
| Nov 2024 | Linea (zkEVM) selected as L2 target |
| Nov 2025 | Switched to Namechain (Taiko/Surge based rollup) |
| Dec 2025 | Ethereum Fusaka upgrade doubles gas limit to 60M |
| Feb 2026 | Namechain cancelled; ENSv2 will deploy on Ethereum L1 only |

The primary motivation for an L2 was cost:
ENS registration on Ethereum L1 cost ~$5 in gas in 2024. By late 2025,
Ethereum's gas limit increases (30M to 60M, targeting 200M in 2026)
reduced registration cost to ~$0.05. At that price, the operational
complexity of running a dedicated rollup (sequencer infrastructure,
bridge contracts, data availability, fraud/validity proofs) was not
justified.

ENS also cited L2 risks: upgradability risks (rollup contracts are
typically upgradeable by a multisig), centralised sequencers, and
reduced security guarantees compared to L1 settlement.

If LEZ transaction costs are low (comparable to Ethereum L1 post-Fusaka),
deploying the naming registry as a LEZ program is the simpler, more
secure option. A dedicated zone only becomes worth the overhead if LEZ
costs are prohibitively high for naming operations.

## What ENS Actually Computes On-Chain

### Core operations

| Operation | Computation | Could be a fixed state machine? |
|-----------|------------|-------------------------------|
| Registry read/write | Key-value lookup: `node → (owner, resolver, TTL)` | Yes |
| Commit-reveal registration | One keccak256 hash, one timestamp comparison | Yes |
| Name renewal | Timestamp comparison + fee calculation | Yes |
| Record storage (addresses, text, content hash) | Key-value write with owner authorisation | Yes |
| Name Wrapper fuses | 32-bit bitmask operations (AND/OR) | Yes (finite automaton) |
| Pricing oracle | 16 fixed multiplications + 2 bit-shifts (bounded, loop-free) | Yes |
| Subdomain creation | keccak256(parent_node, label) + owner check | Yes |
| Reverse resolution | Second key-value mapping | Yes |

### Extension operations

| Operation | Computation | Requires general-purpose execution? |
|-----------|------------|-------------------------------------|
| Custom resolvers | Arbitrary logic per resolver contract | Yes |
| CCIP-Read proof verification | Merkle proof validation, signature recovery | Yes (verifier logic varies by proof type) |
| DAO governance | Token-weighted voting, arbitrary proposal execution | Yes |
| ERC-721/1155 composability | NFT marketplace integration, DeFi hooks | Yes |

The naming protocol itself (registration, renewal, resolution, record
storage) is a state machine: ~35 state transitions, all bounded and
deterministic, expressible as a fixed set of transaction types. None
require Turing-complete computation. Handshake and Aeternity AENS both
run production naming systems without smart contracts.

The extension layer (custom resolvers, governance, NFT composability)
does benefit from general-purpose programmability.

## Evidence from Non-EVM Naming Systems

### Handshake (UTXO covenants, no smart contracts)

Handshake registered 11.3 million TLDs using 12 covenant types encoded
as protocol-native transaction types. Its Vickrey blind-bid auction uses
only Blake2b hashing and integer comparisons. DNS records are stored as
512-byte binary blobs in UPDATE covenants. Adding new features requires a
network soft fork.

Naming works fine without smart contracts. The cost is that extending
the protocol becomes a governance and coordination problem (soft forks)
rather than a deployment problem (new contract).

### Aeternity AENS (protocol-native transaction types)

Five native transaction types handle the full naming lifecycle:
preclaim, claim, update, transfer, revoke. Auction logic is hardcoded
(5% bid increment, 120-block extensions). The fee schedule is fixed by
name length. No smart contract involvement.

### BNS on Stacks (Clarity, decidable language)

Clarity is deliberately non-Turing-complete: no recursion, no unbounded
loops, all execution costs are known at compile time. BNS implements
preorder, register, update, transfer, and revoke within this restricted
model. Each name is an NFT. Custom pricing per namespace is possible.
Of the non-EVM systems, BNS comes closest to ENS-like flexibility.

### Summary

| System | Execution model | Naming-complete? | Extensible without fork? |
|--------|----------------|------------------|--------------------------|
| ENS | Full EVM | Yes | Yes (deploy new contracts) |
| Handshake | UTXO covenants (12 types) | Yes | No (soft fork required) |
| Aeternity AENS | Protocol-native (5 types) | Yes | No (hard fork required) |
| BNS / Stacks | Decidable language (Clarity) | Yes | Partially (new Clarity contracts, but bounded) |

## Evaluation: LEZ Program vs Dedicated Zone

### Option A: Program on canonical LEZ

**Advantages:**

- The naming registry inherits LEZ consensus security with no separate
  validator set or sequencer to maintain.
- Other LEZ programs can resolve names natively via cross-program calls.
  A lending protocol can accept `.logos` names as identifiers; a DEX can
  display human-readable names in its UI.
- No separate chain, sequencer, bridge, or data availability layer to
  deploy and operate.
- ENS on Ethereum L1 is the most successful naming system by adoption
  (~910K active names, $28.77M annual revenue in 2024). ENSv2 explicitly
  chose to stay on L1 after evaluating the L2 alternative.
- If LEZ has a governance mechanism, naming governance can compose with
  it directly.

**Disadvantages:**

- If LEZ becomes expensive (high demand for block space from other
  applications), naming operations become expensive too. This is
  exactly what drove ENS to consider an L2 in 2024 (when Ethereum gas
  was high).
- A surge in naming registrations competes with other applications for
  block space if LEZ has limited throughput.
- All on-chain state is public, so the name-to-zone-key mapping is
  visible to anyone reading LEZ state. This is acceptable (the mapping
  is meant to be public; privacy comes from Layer 1 DHT resolution),
  but LEZ observers can enumerate all registered human-readable names.

### Option B: Dedicated naming zone (separate chain or rollup)

**Advantages:**

- Naming fees are not affected by activity on the canonical LEZ.
- A naming-specific zone can use a simpler execution model (state
  machine with fixed transaction types), reducing overhead.
- Naming governance can evolve without coordination with the broader
  LEZ governance.

**Disadvantages:**

- Requires its own validator set (or sequencer + data availability),
  bridge contracts, and monitoring.
- Other LEZ programs cannot resolve names via direct cross-program
  calls; they need a bridge or oracle.
- A dedicated zone with a smaller validator set is easier to attack
  than the canonical LEZ.
- ENS abandoned its dedicated L2 because the operational complexity
  outweighed the benefits once L1 costs dropped.
- Users and developers must interact with two chains instead of one.

### Option C: Hybrid (recommended)

Deploy the human-friendly naming registry as a **program on canonical
LEZ**. Use the DHT layer (Layer 1) for actual record resolution. This
avoids a separate zone entirely:

- Registration and ownership are rare, high-value operations; they
  belong on LEZ where they get shared security and persistence.
- Record resolution is frequent and privacy-sensitive; it belongs in
  the DHT where updates are free and queries are private.
- Governance (naming parameters, fee structure, dispute resolution)
  sits on LEZ alongside other LEZ governance.

The LEZ program needs only the core state machine operations
(registration, renewal, transfer, zone key mapping). Custom resolvers
and advanced features can be separate LEZ programs that compose with
the core registry.

## Programmability Requirements

The naming protocol needs:

1. A key-value store with ownership (registry: node to owner/resolver/TTL)
2. Time-based state transitions (commit-reveal delay, expiry, grace period)
3. Fee calculation (bounded arithmetic, oracle price feed)
4. Signature verification (owner authorisation)
5. Hierarchical key derivation (namehashing for subdomains)

None of this requires a full EVM or RISC0. Any programmable blockchain
can handle it. But deploying on LEZ (which has general-purpose
programmability) means new resolver types, governance mechanisms, and
integrations can be added without protocol-level changes.

Full programmability is overkill for the naming state machine, but being
on a programmable layer pays off when the system needs to evolve. ENS
added CCIP-Read resolvers, wildcard resolution, the Name Wrapper, and
gasless DNS import after launch, all as new smart contracts, without
touching the core registry. Handshake would have needed a soft fork for
each.
