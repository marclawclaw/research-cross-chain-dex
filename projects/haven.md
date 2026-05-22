---
tags: [project, monero, privacy, stablecoin, offshore-banking, shutdown]
ecosystem: Monero-based L1
category: Privacy/Stablecoin
website: https://havenprotocol.org
docs: https://docs.havenprotocol.org
launched: 2018
status: Shut down 2024-12-12 after range-proof exploit allowed ~1.3B illicit XHV mint over 42 transactions since 2023-08; >94% of known supply controlled by attackers at closure
---

# Haven Protocol

**STATUS UPDATE (verified 2026-05-22)**: Haven Protocol announced project closure on **2024-12-12** following discovery of a range-proof validation vulnerability introduced in the 3.2 rebase to Monero (effective from August 2023) that allowed at least 1.3 billion XHV to be illicitly minted across at least 42 transactions. At the time of the closure announcement, the development team stated "over 94% of the known supply is now controlled by the attackers" and that "there is no realistic way forward". Source: [Project Closure Announcement, havenprotocol.org, 2024-12-12](https://havenprotocol.org/2024/12/12/project-closure-announcement/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-havenprotocol-org-project-closure-announcement.html). The CoinGecko market-cap and on-chain numbers in the metrics table below reflect **residual exchange trading of an unbacked token**, not active protocol use; xUSD's stated pegging mechanism has been non-operational since the closure.

Historically (2018-2024), Haven Protocol was a Monero-forked L1 that enabled users to mint, transfer, and burn privacy-preserving synthetic assets (xAssets) pegged to fiat currencies, commodities, and cryptocurrencies. Its flagship asset was xUSD, a privacy-preserving USD stablecoin. The protocol used Monero's ring-signature and stealth-address model to hide transaction amounts, senders, and recipients.

## Adoption metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| XHV market cap | ~$5.5M | 2026-05-22 | [CoinGecko](https://www.coingecko.com/en/coins/haven) |
| xUSD supply | ~$1.2M | 2026-05-22 | [Haven Explorer](https://explorer.havenprotocol.org) |
| Daily transactions | ~50-100 | 2026-05-22 | [Haven Explorer](https://explorer.havenprotocol.org) |
| Active addresses | [NOT FOUND] | — | — |
| Circulating supply | 29.5M XHV | 2026-05-22 | [CoinGecko](https://www.coingecko.com/en/coins/haven) |

## How it works

### User perspective

1. User acquires XHV (the base currency) via exchange or mining.
2. User locks XHV in the Haven vault and mints xUSD (or other xAssets) at the current oracle price.
3. User transfers xUSD to another Haven address: amount, sender, and recipient are hidden via ring signatures and stealth addresses.
4. Recipient can convert xUSD back to XHV (or another xAsset) at the current oracle price.
5. All conversions burn the source asset and mint the destination asset.

### Protocol perspective

- **Ring signatures:** Transactions are signed with a ring of decoy keys, making it impossible to identify the true signer.
- **Stealth addresses:** One-time addresses are generated for each transaction, hiding the recipient's public address.
- **Confidential transactions:** Transaction amounts are hidden using Pedersen commitments and range proofs (Bulletproofs+).
- **Oracle pricing:** Conversion rates between XHV and xAssets are fetched from decentralised oracles (Chainlink-style feeds) to prevent manipulation.
- **Collateralisation:** xAssets are over-collateralised by XHV; the protocol maintains a minimum collateralisation ratio to ensure solvency.
- **Burn-mint mechanism:** Converting between assets burns the source and mints the destination, creating an elastic supply model.

## Key behaviours

- [[patterns/ring-signatures]] — privacy via decoy key rings
- [[patterns/offshore-banking-crypto]] — synthetic fiat assets on a privacy chain
- [[patterns/collateralised-synthetic-assets]] — over-collateralised minting of pegged assets
- [[patterns/privacy-stablecoin]] — stablecoins with hidden amounts and counterparties

## Architecture decisions

- **Monero fork:** Inherited battle-tested ring-signature privacy but also Monero's scalability limits (large transaction sizes, slow verification).
- **Elastic supply:** No fixed supply for xAssets; supply expands and contracts with conversions, similar to Terra/Luna but with over-collateralisation.
- **Oracle-dependent pricing:** Conversions rely on external price feeds, creating an oracle trust assumption and potential manipulation vector.
- **No smart contracts:** Haven is a transfer-and-convert layer only; no programmable DeFi, limiting composability.
- **Proof-of-work consensus:** Uses RandomX (CPU-friendly mining), same as Monero, avoiding stake centralisation but consuming energy.

## Differentiators

- **True privacy for stable value:** Unlike USDC/USDT (transparent) or even MakerDAO (transparent collateral), xUSD hides holder balances and transaction graphs.
- **Offshore banking metaphor:** The protocol markets itself as a decentralised offshore bank, appealing to users seeking financial privacy outside traditional systems.
- **No bridge required:** xAssets exist natively on Haven; there is no wrapping or bridging from another chain, reducing bridge risk.
- **Decentralised oracles:** Price feeds are sourced from multiple oracles to reduce single-point-of-failure risk.

## Limitations and criticisms

- **Project shutdown (2024-12-12)**: The protocol announced closure after discovery of a range-proof validation vulnerability in the August 2023 rebase to Monero. At least 1.3B XHV were illicitly minted across 42+ transactions; >94% of known supply controlled by attackers at closure. Listed here as a structural failure mode for any privacy-preserving CDP / mint-burn synthetic protocol — the same ring-signature properties that protect users prevent post-incident wallet identification and freezing. See [Project Closure Announcement, 2024-12-12](https://havenprotocol.org/2024/12/12/project-closure-announcement/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-havenprotocol-org-project-closure-announcement.html).
- **Depeg events:** xUSD depegged multiple times prior to the shutdown (notably in 2022-2023) due to low liquidity, oracle delays, and market stress.
- **Low liquidity:** Thin order books and low trading volume make xUSD impractical for large transfers or as a medium of exchange.
- **Regulatory risk:** Privacy stablecoins attract intense regulatory scrutiny; exchanges have delisted XHV in multiple jurisdictions.
- **Oracle trust:** While decentralised, oracles remain a trust assumption; a compromised oracle could enable infinite-mint attacks.
- **No smart contract composability:** Cannot build DeFi primitives (lending, DEX, derivatives) on Haven, limiting utility to simple transfers and conversions.
- **Scalability:** Ring signatures and Bulletproofs+ make transactions large (~2-3 KB) and verification slow, limiting throughput.
- **Network effects:** Monero has far larger network effects for private payments; Haven's xUSD competes with transparent stablecoins that have deeper liquidity.

## Sources

- [Haven Protocol: Project Closure Announcement (2024-12-12)](https://havenprotocol.org/2024/12/12/project-closure-announcement/) — accessed 2026-05-22 :: [archived](../sources/2026-05-22-havenprotocol-org-project-closure-announcement.html)
- [Haven Protocol Documentation](https://docs.havenprotocol.org) — accessed 2026-05-22
- [Haven Protocol Whitepaper](https://havenprotocol.org/whitepaper/) — accessed 2026-05-22
- [CoinGecko: Haven (XHV)](https://www.coingecko.com/en/coins/haven) — accessed 2026-05-22
- [Haven Explorer](https://explorer.havenprotocol.org) — accessed 2026-05-22
- [Haven Protocol: xUSD Depeg Analysis (2023)](https://havenprotocol.org/knowledgebase/xusd-depeg/) — accessed 2026-05-22
- [Messari: Haven Protocol Sector Classification](https://messari.io/asset/haven-protocol) — accessed 2026-05-22
