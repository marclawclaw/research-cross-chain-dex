---
tags: [metric, swap-volume, cross-project]
---

# Metric: Cross-chain swap volume

Tracks user level swap volume across the projects being compared. Volume here means notional value of native asset to native asset (or native to wrapped) swaps mediated by the protocol.

## Snapshot

| Project | TVL | 30d volume | Cumulative volume | Active operators | Date | Source |
|---------|-----|------------|--------------------|-------------------|------|--------|
| [[../projects/thorchain]] | $70.24M | $1.632B | $112.201B | 103 nodes (cap 120) | 2026-05-19 | [DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex), [State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) |
| [[../projects/serai]] | [NOT FOUND] | [NOT FOUND] | [NOT FOUND] | [NOT FOUND] | [NOT FOUND] | (testnet at time of writing, see project note) |
| [[../projects/wormhole]] | [NOT FOUND] | [NOT FOUND] | [NOT FOUND] | 19 guardians | [NOT FOUND] | (attestation bridge; volume tracked as messages and bridged value) |

## Notes

- Thorchain monthly volume in February 2026 was $882M, down from $1.07B in January 2026 ([State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/)).
- Thorchain Q1 2025 cumulative was $19.62B with a peak day of $1.49B ([THORChain Q1 2025 Report](https://medium.com/thorchain/thorchain-q1-2025-report-q2-roadmap-ffdb9e303c74)).
- Thorchain DefiLlama page reports $112.201B cumulative and $29.76M annualised fees as of 2026-05-19 ([DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex)).
- Wormhole metrics need a dedicated lookup in its native dashboard (volume measured as bridged value plus message count, not swap volume in the AMM sense).

## Sources

- [DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex) :: accessed 2026-05-19
- [State of the Network February 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) :: accessed 2026-05-19
- [THORChain Q1 2025 Report](https://medium.com/thorchain/thorchain-q1-2025-report-q2-roadmap-ffdb9e303c74) :: accessed 2026-05-19
