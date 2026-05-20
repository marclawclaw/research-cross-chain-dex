# Other DHT-Based and P2P Name Services

Several other systems use DHT or P2P techniques for naming, though none
are production-ready alternatives to GNS or IPNS:

## Waku Naming Service (WNS)

A hackathon prototype (September 2025) built on the Waku messaging
protocol (part of the Logos stack). WNS maps names to public keys
(rather than wallet addresses) and uses Waku messaging for private
resolution negotiation. Not a production system, but it shows Waku can carry naming queries,
making it a useful proof-of-concept for Layer 1 resolution over Waku.

## Tor Onion Services (.onion)

Tor's hidden service naming uses a self-certifying model similar to
IPNS: the `.onion` address is derived from the service's public key.
Resolution goes through the Tor network's DHT (hash ring of HSDir
nodes). Strong anonymity, no human-readable names. With millions of active
services, .onion is the largest proof that DHT-based self-certifying
naming works at scale when privacy properties are strong enough.

## Mainline DHT (BitTorrent)

BitTorrent's Mainline DHT is the largest Kademlia deployment in
production (~15-25 million nodes). While designed for content lookup
(infohash to peer list), BEP 44 added mutable items: signed key-value
pairs stored in the DHT, indexed by public key. Architecturally similar to IPNS records. Mainline DHT has been used
experimentally for naming (e.g., the Pkarr project) but lacks
encryption, expiry enforcement, and any privacy mechanism. At hundreds
of millions of entries, it proves Kademlia works at that size.

## Pkarr

An experimental project that uses BitTorrent's Mainline DHT (BEP 44)
for DNS-compatible name resolution. Pkarr stores signed DNS resource
records under Ed25519 public keys in the Mainline DHT. Self-certifying
names with DNS compatibility, but no privacy (records are plaintext,
keys are unhashed). Simple and builds on existing DHT infrastructure, but not
production-grade.

## Emercoin EmerDNS

A Bitcoin-fork blockchain (not strictly DHT-based) that uses a
Name-Value Storage (NVS) system for domain names under the `.coin`,
`.emc`, and `.lib` TLDs. Included here because its NVS is conceptually
similar to a key-value DHT but backed by PoW consensus. Low adoption
(~$13M market cap). An example of what happens to blockchain-based naming without ecosystem
integration: technically functional, practically unused.

## Summary: DHT Naming Landscape

| System | DHT/Transport | Human Names | Privacy | Production | Scale |
|--------|--------------|-------------|---------|------------|-------|
| GNS | R5N (GNUnet) | No (petnames) | Strong (key blinding) | Alpha | Tiny |
| IPNS | Amino (libp2p) | No (key hash) | Weak | Production | ~575K nodes |
| WNS | Waku | No (key based) | Moderate (Waku privacy) | Prototype | N/A |
| Tor .onion | Tor HSDir | No (key hash) | Strong (Tor anonymity) | Production | Millions |
| Mainline DHT | Mainline (BitTorrent) | No (key hash) | None | Production | ~20M nodes |
| Pkarr | Mainline (BitTorrent) | No (key hash) | None | Experimental | Inherits Mainline |
| EmerDNS | Blockchain (NVS) | Yes (.coin) | None | Production | Near zero |

DHT-based naming works at massive scale (Mainline DHT, Tor), but no
existing system combines human-readable names, privacy, and high
availability. The two-layer architecture in the potential architectures
appendix is an attempt to get all three by splitting the problem across
layers.
