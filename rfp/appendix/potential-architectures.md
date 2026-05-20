# Potential Architectures

## Two-Layer Design

Eight naming systems were surveyed (ENS, Handshake, GNS, IPNS, D3/Doma,
Unstoppable Domains, SPACE ID, Namecoin). DHT-based systems offer
privacy and chain-agnosticism but lack human-readable names;
blockchain-based systems offer human-readable names but sacrifice
privacy and chain-independence. No existing system solves both.

A two-layer architecture splits the problem:

```
┌──────────────────────────────────────────────────┐
│  Layer 2: Human-Friendly Naming                  │
│  (on LEZ, or as a custom registrar zone)         │
│                                                  │
│  - Human-readable names (e.g. alice.logos)        │
│  - Anti-squatting via fees or auctions            │
│  - Dispute resolution                            │
│  - Optional: on-chain registry for persistence   │
│  - Maps: human name → Layer 1 zone key           │
└───────────────────┬──────────────────────────────┘
                    │ resolves to
┌───────────────────▼──────────────────────────────┐
│  Layer 1: DHT-Based Self-Certifying Names        │
│  (chain-agnostic, privacy-preserving)            │
│                                                  │
│  - Name = hash of public key (self-certifying)   │
│  - Records stored in DHT with key blinding       │
│  - No blockchain dependency for resolution       │
│  - Query privacy by design                       │
│  - Multi-transport: DHT, Waku, HTTP              │
│  - Record encryption at rest                     │
└──────────────────────────────────────────────────┘
```

**Layer 1 (DHT base)** is the core naming infrastructure. It is entirely
chain-agnostic: any keypair can publish records to the DHT, and any
client can resolve them, without touching a blockchain. Key blinding
prevents DHT peers from enumerating zones or correlating queries. The
design borrows from GNS (RFC 9498) for privacy and from IPNS for
transport flexibility.

**Layer 2 (human-friendly naming)** is an optional layer that maps
human-readable names to Layer 1 zone keys. This could be implemented as:

1. **A LEZ smart contract registry:** names are registered on-chain with
   anti-squatting fees. The registry maps `alice.logos` to a Layer 1
   zone public key. Resolution then proceeds via the DHT. Blockchain registration handles Sybil resistance; DHT
   resolution handles privacy.

2. **A custom registrar zone (GNS model):** a designated zone operator
   runs a first-come-first-served registrar (or auction-based registrar)
   that maps human-readable labels to zone keys within a GNS-style zone.
   Multiple registrar zones can coexist; users choose which to trust.
   Fully chain-agnostic, but availability depends on the registrar
   operator.

3. **A hybrid:** the LEZ registry provides the canonical mapping for
   high-value names, while lightweight registrar zones handle
   community-specific or application-specific namespaces.

Layer 1 resolution never touches a blockchain. Even when
Layer 2 uses a blockchain for name registration, the actual record
lookup (address records, content hashes, service endpoints) goes through
the DHT. The blockchain only answers "what zone key does this
human-readable name point to?"

## Why Two Layers?

**Zooko's triangle** states that a naming system can have at most two of
three properties: human-meaningful, secure, decentralised. Existing
systems navigate this differently:

| System | Human-meaningful | Secure | Decentralised |
|--------|-----------------|--------|---------------|
| DNS    | Yes | Yes (DNSSEC) | No (ICANN) |
| ENS    | Yes | Yes | Partially (Ethereum dependency) |
| GNS    | No (petnames) | Yes | Yes |
| IPNS   | No (key hashes) | Yes | Yes |

Layer 1 is secure and decentralised but gives up human-meaningful names.
Layer 2 adds human-meaningful names within a chosen trust context (a
blockchain, a registrar zone, or both). Someone who wants maximum
decentralisation can use Layer 1 directly with petnames; someone who
wants convenience uses Layer 2.

## DHT Reliability

DHT-based naming systems are unreliable by default: records are
ephemeral and require active maintenance by the publisher to stay
available.

### DHT record persistence characteristics

| Property | IPNS | GNS |
|----------|------|-----|
| Default record TTL | 48 hours | Publisher-defined |
| Republish interval | Every 4 hours (mandatory) | ZONEMASTER daemon (configurable) |
| Replication factor | k=20 (Kademlia standard) | k=20 (R5N) |
| What happens if publisher goes offline | Name unresolvable within 48 hours | Name unresolvable after expiry |
| Expired record handling | Stale records may persist in DHT | Cryptographically inert (decryption fails with expired IV) |

The replication factor of k=20 means each record is stored on the 20
DHT nodes whose IDs are closest to the record's key. Under normal
network churn (nodes joining and leaving), Kademlia's periodic
republishing keeps records available. However:

- **Publisher failure is fatal.** If the zone owner's device is offline
  or destroyed, all records become unresolvable within hours to days.
  There is no fallback.
- **Network partitions degrade availability.** If enough of the 20
  replica nodes become unreachable at once (data centre outage, regional
  internet disruption), the record may be temporarily unresolvable even
  while the publisher is online.
- **Small networks amplify churn effects.** GNS's self-described "tiny"
  network means each node holds a disproportionate share of the keyspace.
  A single node departure can affect availability for many zones. IPNS
  is more resilient with ~575,000 nodes, but its median resolution
  latency of ~11 seconds (with 37-60 second outliers) shows that even
  large DHTs have real performance limits.

### What a blockchain adds

A blockchain is a write-once, read-forever store. For naming, the
tradeoffs look like this:

| Property | DHT only | Blockchain only | Two-layer (proposed) |
|----------|----------|-----------------|----------------------|
| Record availability | Depends on publisher uptime | Permanent (while chain operates) | Critical mapping: permanent; records: publisher-dependent |
| Cost per update | Free | Gas/fee per transaction | Zone key mapping: gas; records: free |
| Update latency | Seconds (DHT propagation) | Block time (seconds to minutes) | Zone key: block time; records: seconds |
| Query privacy | Strong (with key blinding) | None (public chain state) | Zone key lookup: public; record lookup: private |
| Write frequency | Unlimited | Constrained by block space | Zone key: rare (registration/transfer only); records: unlimited |

The name-to-zone-key mapping is a small, infrequent write (once at
registration, updated only on transfer or key rotation). Paying a gas
fee for that is tolerable because it happens rarely. The actual record
data (wallet addresses, content hashes, service endpoints) changes often
and belongs in the DHT, where updates are free and fast.

### Reliability comparison with existing systems

Tor's .onion addresses prove DHT-based naming works at scale (millions
of active services), but .onion addresses are tied to running services.
When a hidden service goes offline, its address stops resolving, and
users accept this because the address *is* the service. A
general-purpose naming system where the name outlives any particular
service cannot rely on this model.

BitTorrent's Mainline DHT (~20 million nodes) handles hundreds of
millions of entries, but those entries are content-addressed (infohashes),
not mutable name records. Availability depends on peers seeding the
associated content, not on a single publisher.

ENS on Ethereum is the other extreme: ~910,000 active names, 100%
availability (as long as Ethereum operates), but no privacy and a cost
per write (gas fees).

The two-layer architecture puts name-to-zone-key mappings on-chain (ENS
model) and record resolution in the DHT (GNS model). The blockchain
never stores or serves record data. It answers one question: "what zone
key does alice.logos point to?"
