# DHT-Based Name Services: IPNS vs GNS

## Overview

IPNS and GNS are the only two production DHT-based naming systems.
Both are chain-agnostic and token-free. Both use Kademlia-derived DHTs.
They differ sharply in privacy model, record format, name model, and
maturity.

## Architectural Comparison

| Dimension | IPNS | GNS |
|-----------|------|-----|
| **DHT implementation** | Amino DHT (Kademlia, libp2p) | R5N DHT (randomised Kademlia, GNUnet) |
| **Network size** | ~25,000 server nodes, ~550,000 clients (Mar 2026) | Self-described "tiny"; no published metrics |
| **Standardisation** | IPFS specs (community standard) | RFC 9498 (IETF Informational, Nov 2023) |
| **Name model** | Self-certifying: name = hash of public key | Zone-based: zone key + label hierarchy |
| **Human-readable names** | No (requires ENS or DNSLink on top) | No (petnames; FCFS registrar for discovery) |
| **Record storage key** | Hash of public key (directly linkable to zone) | Blinded key: ZKDF(zone_key, label) (unlinkable without both inputs) |
| **Record encryption** | None (plaintext in DHT) | Yes (AES-256-CTR or ChaCha20-Poly1305) |
| **Query privacy** | Weak (DHT peers see the key being queried; key is directly the public key hash) | Strong (key blinding prevents correlation; peers cannot determine which zone or label is being queried) |
| **Zone enumeration** | N/A (no zone concept; each key is independent) | Requires brute force on (zone_key, label) pairs |
| **Record expiry** | 48 hours default; configurable | Publisher-defined; expiry baked into encryption IV |
| **Republish interval** | Every 4 hours (mandatory) | ZONEMASTER daemon (configurable) |
| **Record format** | IPNS Record (protobuf): value, sequence, validity, TTL, signatureV2 | GNS Resource Record (binary): type, flags, expiry, data, key, value |
| **Supported record types** | Single pointer (CID or path) | Multiple per zone: PKEY, EDKEY, GNS2DNS, BOX, SBOX, VPN, REDIRECT, NICK, PHONE, DID_DOCUMENT, and all DNS types |
| **Delegation** | None (flat namespace) | Hierarchical via PKEY/EDKEY records (arbitrary depth) |
| **DNS compatibility** | Via DNSLink (TXT record in DNS pointing to IPNS name) | Via dns2gns proxy, NSS plugin, GNS2DNS delegation record, SOCKS5 proxy |
| **Key rotation** | Not supported (name is the key hash; rotation = new name) | Supported (delegate to a new zone key via PKEY record) |
| **Revocation** | No standard mechanism | PoW-based revocation certificate (4-5 days to compute; must be pre-computed) |
| **Transport options** | DHT, PubSub (GossipSub), HTTP (delegated routing) | R5N DHT only (GNUnet transport layer) |
| **Resolution latency** | ~11s median (p50), 37-60s outliers (Aug 2025) | Not formally measured on current network |
| **Post-quantum** | None (Ed25519 only) | In progress (GNUnet 0.26.x PQ layer, Dec 2025) |
| **Active development** | Yes (Kubo v0.34+, Feb 2026) | Yes (GNUnet 0.27.0, Mar 2026) |
| **Software maturity** | Production (IPFS ecosystem) | Alpha ("early adopters only") |
| **Licence** | MIT/Apache 2.0 (libp2p) | AGPL 3.0 (GNUnet) |

## Key Differences Explained

### Privacy model

IPNS stores
records under the hash of the publisher's public key. Any DHT peer
handling a lookup can trivially determine which public key is being
queried. Over time, peers can build a profile of which nodes query which
keys.

GNS uses a **key-blinding scheme** (specified in RFC 9498, Section 5):
the DHT storage key is derived as `ZKDF(zone_key, label)`, a
zone-key-derivation function that produces a key computationally
unlinkable to either the zone key or the label without knowledge of
both. Records are encrypted with a key derived from the same inputs,
with the record expiry timestamp mixed into the IV. This means:

- DHT peers cannot determine which zone a query belongs to
- DHT peers cannot read the record contents
- Expired records are cryptographically inert (decryption fails)
- Zone enumeration requires brute-forcing all possible label strings

If query privacy is a design goal, GNS's key-blinding approach is the
clear choice over IPNS's transparent model.

### Name model

IPNS has a **flat, self-certifying namespace**: each name is the hash of
a public key, with no structure or hierarchy. Simple, but limiting:

- No sub-namespaces (cannot delegate `service.alice` under `alice`)
- No key rotation without changing the name
- Human-readable names require an external system

GNS has a **hierarchical, zone-based namespace**: each zone is a
keypair, and zones can delegate to sub-zones via PKEY/EDKEY records:

- Arbitrary-depth delegation (`service.department.org.zTLD`)
- Key rotation by updating the delegation record in the parent zone
- Multiple record types per zone (addresses, DNS records, VPN configs)
- Petname-based trust model where each user has their own root

For organisational hierarchies, service discovery, and key lifecycle
management, GNS's zone model is more capable.

### Record persistence and republishing

IPNS records expire after 48 hours by default. The publisher must
republish every 4 hours to maintain availability. If the publisher goes
offline, the name becomes unresolvable within 48 hours.

GNS records have publisher-defined expiry. The ZONEMASTER daemon handles
republishing. The expiry is cryptographically enforced (baked into the
encryption IV), so expired records cannot be served even if they remain
in the DHT.

Both systems have the same limitation: DHT records are ephemeral.
Neither gives you "write once, available forever" like a blockchain.
The two-layer architecture addresses this by putting the
name-to-zone-key mapping on LEZ (persistent) while leaving record
distribution in the DHT (ephemeral but private and free).

### Transport flexibility

IPNS is ahead on transport flexibility. The same IPNS record can be
distributed via:

- Amino DHT (Kademlia)
- PubSub (GossipSub for near-instant propagation)
- HTTP delegated routing API
- Any custom transport (the record format is transport-agnostic)

GNS is currently bound to GNUnet's R5N DHT and transport layer. While
the record format is specified independently (RFC 9498), the
implementation is tightly coupled to GNUnet.

A system that must operate over Waku, libp2p, and HTTP needs IPNS's
transport-agnostic record model. GNS's privacy model (key blinding,
record encryption) applies regardless of which transport is chosen.

### Licensing

IPNS's implementation (via libp2p and Kubo) is MIT/Apache 2.0 dual
licensed, which is compatible with any downstream project. GNUnet
(including GNS) is AGPL 3.0, which requires derivative works to be
released under the same licence. For a Logos project that may need
permissive licensing, the IPNS codebase is more directly reusable, but
GNS's cryptographic design (key blinding, record encryption) can be
reimplemented under any licence since the specification is published as
an RFC.

## Recommendation for the RFP

The design should combine:

- **GNS's privacy model** (key blinding for DHT storage, record
  encryption, zone enumeration resistance)
- **IPNS's transport flexibility** (record format decoupled from
  transport; support for DHT, PubSub, HTTP, and Waku)
- **GNS's zone hierarchy** (delegation via zone key records, enabling
  key rotation and sub-namespaces)
- **A custom record format** (protobuf or CBOR) that extends GNS's
  record types with multi-chain address records (ENS-style coin types)

Doing this is harder than it sounds. GNS's key blinding is tightly
coupled to its zone model and R5N DHT. Porting it to a libp2p Kademlia
DHT or Waku transport means adapting the key derivation and encryption
to new primitives; expect research work, not just configuration.
