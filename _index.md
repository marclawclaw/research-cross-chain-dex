# Research Index: Cross-Chain DEX

Scope: how do cross-chain DEX architectures use a middle-ground
blockchain to enable swaps across heterogeneous chains, and how could
the Logos Execution Zone (LEZ) position itself as such a middle layer
with stronger anonymity guarantees.

## Selected projects

| Rank | Project    | Category                              | Selected |
|------|------------|---------------------------------------|----------|
| 1    | [[projects/thorchain]] | Middle-chain DEX (Cosmos SDK)            | yes      |
| 2    | [[projects/serai]]     | Middle-chain DEX (Substrate)             | yes      |
| 3    | [[projects/wormhole]]  | Attestation bridge (contrast point)      | yes      |
| 4    | [[projects/baltex]]    | Instant-swap aggregator (privacy-focused)| yes      |
| 5    | [[projects/comit]]     | Atomic swaps (contrast: no staking/reputation) | yes |
| 6    | [[projects/liquity]]   | CDP stablecoin (contrast: category mismatch — CCIP bridge consumer, not middle-chain DEX) | yes |
| 7    | [[projects/haven]]     | Privacy-preserving stablecoin (Monero-based offshore banking) | yes |
| 8    | [[projects/secret-network]] | Privacy-preserving smart contracts (TEE-based private DeFi) | yes |

## Research status

- [x] [[projects/serai]] :: complete (2026-05-19)
- [x] [[projects/thorchain]] :: complete (2026-05-19)
- [x] [[projects/wormhole]] :: complete (2026-05-19)
- [x] [[projects/baltex]] :: complete (2026-05-20)
- [x] [[projects/comit]] :: complete (2026-05-20) :: scoped audit of comit-network ADRs/RFCs for staking and reputation (none found; included as negative result)
- [x] [[projects/liquity]] :: complete (2026-05-21) :: included on colleague request; documented as category mismatch — Liquity is a CDP stablecoin issuer using Chainlink CCIP (attestation-bridge family) for BOLD multi-chain, not a middle-chain DEX
- [x] [[projects/haven]] :: complete (2026-05-22) :: privacy-preserving stablecoin (xUSD) on Monero-forked L1; ring signatures, offshore banking model, depeg history
- [x] [[projects/secret-network]] :: complete (2026-05-22) :: TEE-based private smart contracts on Cosmos SDK; SNIP-20 tokens, IBC integration, SGX trust assumptions
- [x] [[projects/lez-positioning]] :: complete (2026-05-19)
- [x] [[summary]] :: complete (2026-05-19)
- [x] Patterns: [[patterns/signer-federation-trust]], [[patterns/middle-chain-swap-settlement]], [[patterns/tss-custody-vault]], [[patterns/slip-based-fees]], [[patterns/attestation-bridge]], [[patterns/lock-mint-bridging]], [[patterns/atomic-swaps-vs-middle-chain]], [[patterns/instant-swap-aggregator]], [[patterns/ring-signatures]], [[patterns/offshore-banking-crypto]], [[patterns/collateralised-synthetic-assets]], [[patterns/privacy-stablecoin]], [[patterns/tee-based-privacy]], [[patterns/encrypted-smart-contracts]], [[patterns/viewing-keys]], [[patterns/private-tokens]], [[patterns/cross-chain-privacy]], [[patterns/monero-bridge]]
- [x] Trust-model deep dives: [[patterns/serai-trust-model]], [[patterns/thorchain-trust-model]], [[patterns/wormhole-trust-model]]
- [x] Metrics: [[metrics/swap-volume]], [[metrics/privacy-protocol-comparison]]

## Research questions

1. How do Serai and Thorchain use a middle-ground chain to enable swaps between native assets on otherwise non-communicating L1s?
2. How does Wormhole's attestation-bridge model differ, and what does that tradeoff buy or cost?
3. What characteristics are *necessary* for a middle chain to settle cross-chain swaps (custody, validator economics, asset support, latency, finality)?
4. How could LEZ position itself as such a middle chain?
5. What anonymity properties can LEZ bring (zkVM, shielded state, Waku transport, sealed orderflow) that Serai, Thorchain, and Wormhole cannot match?
