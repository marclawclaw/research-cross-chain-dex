---
tags: [pattern, privacy, tokens]
seen_in: [secret-network]
---

# Private Tokens

Private token standards define how tokens hide balances, transfer amounts, and/or counterparties while maintaining fungibility and programmability. They are the privacy equivalent of ERC-20.

## Implementations

- **[[projects/secret-network]]:** SNIP-20 is the dominant standard. Balances and transfer amounts are encrypted by default. Transfers require the sender to authorise the contract to spend. Metadata (token symbol, decimals) is public. Viewing keys enable selective disclosure.
- **Zcash (ZSA):** Shielded Asset standard extends ZEC shielding to custom assets. Uses zk-SNARKs to hide transaction graphs and amounts. No smart contract support.
- **Aztec:** Aztec Connect and the UTXO-based token model enable private ERC-20 interactions on Ethereum via zk-rollup. Uses UTXO notes rather than account balances.

## Relevance to Logos

A private token standard is foundational for LEZ: all assets bridged into the zone should be representable as private tokens. Requirements: encryption of balances and transfer amounts; support for approvals and allowances (for DEX integration); compatibility with viewing keys for selective disclosure; and efficient proof generation (for zk-based approaches) or low latency (for TEE-based approaches).
