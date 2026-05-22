---
tags: [pattern, privacy, cross-chain]
seen_in: [secret-network]
---

# Cross-Chain Privacy

Cross-chain privacy refers to the ability to move assets and data between chains while maintaining confidentiality of the transfer amount, sender, recipient, and/or purpose. This is harder than single-chain privacy because bridge mechanisms and destination chains may leak metadata.

## Implementations

- **[[projects/secret-network]]:** Uses IBC for private cross-chain messaging within Cosmos, and the Secret Ethereum Bridge for wrapping ERC-20s as SNIP-20s. The bridge encrypts assets on Secret but the source chain (Ethereum) still has a public record of the deposit.
- **Aztec Connect:** Enables private interactions with Ethereum DeFi via zk-rollup. Users deposit to Aztec, interact privately, and withdraw back to Ethereum. The deposit and withdrawal are public on Ethereum, but intermediate state is private.
- **LayerZero + privacy:** Emerging approaches combine omnichain messaging with ZK proofs to hide cross-chain transfer metadata.

## Relevance to Logos

Cross-chain privacy is the core challenge for LEZ: users deposit assets from public chains (Ethereum, Solana) and expect privacy inside the zone. The deposit itself is public (source chain record), but subsequent activity should be private. Requirements: shielded state inside LEZ; private order submission (e.g., via Waku); and privacy-preserving settlement (zkVM or TEE). The bridge deposit is an unavoidable metadata leak; LEZ should minimise what can be inferred from deposit/withdrawal patterns (e.g., via mixing, delayed withdrawals, or decoy transactions).
