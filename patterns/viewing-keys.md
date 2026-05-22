---
tags: [pattern, privacy, access-control]
seen_in: [secret-network]
---

# Viewing Keys

Viewing keys are cryptographic credentials that allow selective disclosure of private data. In privacy-preserving blockchain systems, they enable users to share specific information (balances, transaction history) with third parties (auditors, tax authorities, counterparties) without revealing everything or compromising ongoing privacy.

## Implementations

- **[[projects/secret-network]]:** Users derive viewing keys from their wallet seed. Each key grants read-only access to a specific contract's data for that user. Keys can be revoked and regenerated. This enables compliance use cases while keeping data private by default.
- **Zcash:** Uses "payment disclosure" and "viewing keys" (incoming and outgoing) to allow selective transparency. Full viewing keys reveal all transaction data for an address.
- **Monero/Haven:** No native viewing key mechanism; privacy is absolute and irreversible. This limits auditability and compliance.

## Relevance to Logos

Viewing keys are a critical usability and compliance feature for LEZ. Users need the ability to prove balances or transaction history to regulators, auditors, or dispute-resolution mechanisms without exposing their entire financial history. Requirements: key derivation should be deterministic from the user's master key, revocation should be instant, and sharing should be granular (per-contract, per-time-period).
