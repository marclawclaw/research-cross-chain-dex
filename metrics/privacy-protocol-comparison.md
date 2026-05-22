---
tags: [metrics, privacy, comparison]
updated: 2026-05-22
---

# Privacy Protocol Comparison

| Project | Privacy Mechanism | Programmable | Cross-Chain | Stablecoin | TVL / Market Cap | Validator Count | Key Risk |
|---------|------------------|--------------|-------------|------------|------------------|-----------------|----------|
| [[projects/haven]] | Ring signatures + stealth addresses | No (transfers only) | No (native only) | xUSD (privacy stablecoin) | ~$5.5M XHV / ~$1.2M xUSD | PoW miners | Low liquidity, depeg risk |
| [[projects/secret-network]] | TEE (Intel SGX) | Yes (secret contracts) | Yes (IBC + Ethereum bridge) | SNIP-20 tokens (sSCRT, sETH) | ~$8M TVL / ~$45M market cap | ~70 validators | TEE vulnerabilities, hardware centralisation |
| [[projects/serai]] | TSS + threshold signatures | Yes (Substrate runtime) | Yes (native bridging) | No native stablecoin | [NOT FOUND] | [NOT FOUND] | Signer federation trust |
| [[projects/thorchain]] | Transparent (public ledger) | Limited (native swaps) | Yes (native bridging) | No native stablecoin | ~$300M TVL | ~100 validators | Node bond centralisation |
| [[projects/wormhole]] | Transparent | No (messaging only) | Yes (attestation bridge) | No | N/A (messaging protocol) | N/A | Guardian set trust |

## Notes

- Haven and Secret Network are the only projects in this research set with native privacy features. Serai and Thorchain rely on transparent ledgers; privacy is not a design goal.
- Haven's privacy is stronger (ring signatures) but non-programmable; Secret's privacy is weaker (TEE trust) but programmable.
- Neither Haven nor Secret Network has achieved significant DeFi traction, suggesting privacy DeFi remains a niche or unsolved problem.
- LEZ's positioning should consider combining Haven's strong anonymity (zkVM) with Secret's programmability (smart contracts), while avoiding both projects' weaknesses (low liquidity, TEE trust).
