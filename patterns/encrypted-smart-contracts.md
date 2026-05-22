---
tags: [pattern, privacy, smart-contracts]
seen_in: [secret-network]
---

# Encrypted Smart Contracts

Encrypted smart contracts are programs whose state and inputs are encrypted by default, readable only by authorised parties (typically the contract's execution environment and the user). This enables private DeFi where balances, positions, and strategies are hidden from public view.

## Implementations

- **[[projects/secret-network]]:** Contract state is stored as ciphertext on-chain. The enclave decrypts state on read, executes logic, and re-encrypts on write. Users submit encrypted inputs; outputs are encrypted and decrypted client-side with viewing keys.
- **Oasis Sapphire:** An EVM-compatible ParaTime on Oasis Network that encrypts transaction data and contract state using TEEs.
- **Fhenix:** An EVM-compatible chain using fully homomorphic encryption (FHE) for encrypted smart contracts, avoiding TEE trust assumptions but with higher computational cost.

## Relevance to Logos

Encrypted smart contracts are essential for a private cross-chain DEX: order books, liquidity positions, and user balances must remain confidential to prevent MEV extraction and front-running. LEZ could implement encrypted contracts via a zkVM (state is committed but contents are hidden) or TEEs (state is encrypted at rest and in use). The key requirement is that encryption does not break composability: contracts must be able to interact while maintaining privacy boundaries.
