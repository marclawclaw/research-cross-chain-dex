---
tags: [pattern, privacy, stablecoin]
seen_in: [haven, secret-network]
---

# Privacy Stablecoin

A privacy stablecoin is a fiat-pegged token that hides transaction amounts, senders, and/or recipients. This contrasts with transparent stablecoins (USDC, USDT, DAI) where all transaction data is publicly visible on-chain.

## Implementations

- **[[projects/haven]]:** xUSD uses Monero's ring signatures, stealth addresses, and confidential transactions to hide all transaction metadata. No smart contract support; transfers are the only operation.
- **[[projects/secret-network]]:** SNIP-20 tokens (e.g., sSCRT, sETH) encrypt balances and transfer amounts by default. Users can share viewing keys for selective disclosure. Supports programmable DeFi via secret contracts.
- **Zcash (ZSA):** The Zcash Shielded Assets proposal extends ZEC shielding to custom assets, enabling private stablecoins on Zcash.

## Relevance to Logos

Privacy stablecoins are a critical component of a private cross-chain DEX: users need a private store of value to exit volatile assets. LEZ could support privacy stablecoins via zkVM-based shielding (hiding balances and transfers) or TEE-based encryption. Trade-offs: ring signatures offer strong anonymity but poor scalability; TEEs offer programmability but hardware trust assumptions; zk-SNARKs offer both but require trusted setup or high proof-generation costs.
