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

## Research status

- [x] [[projects/serai]] :: complete (2026-05-19)
- [x] [[projects/thorchain]] :: complete (2026-05-19)
- [x] [[projects/wormhole]] :: complete (2026-05-19)
- [x] [[projects/lez-positioning]] :: complete (2026-05-19)
- [x] [[summary]] :: complete (2026-05-19)
- [x] Patterns: [[patterns/signer-federation-trust]], [[patterns/middle-chain-swap-settlement]], [[patterns/tss-custody-vault]], [[patterns/slip-based-fees]], [[patterns/attestation-bridge]], [[patterns/lock-mint-bridging]], [[patterns/atomic-swaps-vs-middle-chain]]
- [x] Trust-model deep dives: [[patterns/serai-trust-model]], [[patterns/thorchain-trust-model]], [[patterns/wormhole-trust-model]]
- [x] Metrics: [[metrics/swap-volume]]

## Research questions

1. How do Serai and Thorchain use a middle-ground chain to enable swaps between native assets on otherwise non-communicating L1s?
2. How does Wormhole's attestation-bridge model differ, and what does that tradeoff buy or cost?
3. What characteristics are *necessary* for a middle chain to settle cross-chain swaps (custody, validator economics, asset support, latency, finality)?
4. How could LEZ position itself as such a middle chain?
5. What anonymity properties can LEZ bring (zkVM, shielded state, Waku transport, sealed orderflow) that Serai, Thorchain, and Wormhole cannot match?
