---
tags: [pattern, privacy, cryptography]
seen_in: [haven, monero]
---

# Ring Signatures

Ring signatures allow a transaction to be signed by any one member of a group (ring) of possible signers, without revealing which member actually signed. An observer can verify that the signature was produced by someone in the ring, but cannot identify the true signer.

## Implementations

- **[[projects/haven]]:** Uses Monero-style ring signatures combined with stealth addresses and confidential transactions (Bulletproofs+) to hide sender, recipient, and amount. Ring size is typically 11-16 decoy keys.
- **Monero:** The originator of the CryptoNote ring-signature scheme. Uses a dynamic ring size and decoy selection algorithm to maximise entropy.

## Relevance to Logos

Ring signatures provide strong anonymity guarantees but at significant scalability cost: transactions are large (2-3 KB) and verification is slow. For LEZ, ring signatures could be considered for specific privacy-preserving operations (e.g., shielded transfers) but are unlikely to scale as a general-purpose execution model. Alternative approaches (zk-SNARKs, TEEs) offer better throughput but different trust assumptions.
