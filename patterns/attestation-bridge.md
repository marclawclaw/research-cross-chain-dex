---
tags: [pattern, cross-chain, bridge, contrast]
---

# Attestation bridge pattern

An attestation bridge is a cross-chain messaging system in which a fixed (or governed) committee of off-chain validators observes events on a source chain, signs a structured proof, and any party can submit that proof on a destination chain to trigger an action. The bridge itself has no native chain, no native consensus, and no native asset settlement: it is a signature relay.

## Canonical example

[[projects/wormhole]]: 19 Guardians sign 13-of-19 multisignature attestations called Verifiable Action Approvals (VAAs); each connected chain has its own Core Contract that verifies the Guardian signatures and dispatches the message payload to a target contract ([Wormhole Architecture](https://wormhole.com/docs/protocol/architecture/) :: accessed 2026-05-19).

Other examples that fit this pattern: Axelar (validator set with PoS, threshold signatures), LayerZero (oracle + relayer split), Multichain/Anyswap (MPC committee, now defunct), Ronin (small validator set; exploited 2022).

## Architecture sketch

1. Source-chain contract emits an event by calling a "core" contract on the source chain.
2. Off-chain attesters (committee) each observe the event independently across full nodes for each connected chain.
3. Attesters sign a structured message (`keccak256(keccak256(body))` for Wormhole) using ECDSA or BLS or threshold signatures.
4. Once a threshold of signatures is reached, the signed bundle (VAA-like artefact) is broadcast publicly.
5. Anyone (a permissionless relayer) submits the bundle to the destination chain's core contract.
6. The destination core contract verifies the signatures against the active committee set and forwards the payload to the target contract.

## What attestation bridges are good at

- **Generality.** The payload is opaque bytes: a token transfer, a governance vote, an oracle update, a CCTP-style burn-mint instruction all share the same primitive.
- **Latency.** Signing finishes as soon as a quorum is reached; not coupled to underlying chain finality.
- **Chain reach.** Adding a chain requires only deploying a core contract, not bootstrapping a new validator economy.
- **No protocol-owned liquidity needed.** Bridging is a wrap/unwrap or mint/burn primitive on each chain.

## What attestation bridges cannot do (without an external venue)

- **Native-asset to native-asset swap.** The protocol moves a token A on chain X to a wrapped or native form of A on chain Y. Converting A to B requires an external DEX or solver network (see Wormhole + Mayan Swift; see [[patterns/middle-chain-swap-settlement]] for the alternative).
- **Atomic price discovery.** There is no order book or AMM inside the bridge.
- **Slashing or economic security.** Wormhole's Guardians have no bond and no slashing; security is reputational. Other attestation bridges (Axelar) add PoS but still concentrate trust in a smaller validator set than the chains they connect.

## Trust root

Two distinct trust roots stack:

1. **The committee.** N of M attesters must remain honest. For Wormhole this is 7-of-19 honest (1 - 13/19 = 6/19, so 7 needed to corrupt). The committee can in principle forge arbitrary messages.
2. **The per-chain core contract.** Each chain has its own implementation of signature verification, message dispatch, and (for token bridges) lock/mint accounting. A single buggy contract on one chain can drain all assets bound to it without the committee being implicated, as in the [[projects/wormhole]] February 2022 incident.

The composition means the bridge is no more secure than the weakest of (committee, every connected chain's contract).

## Privacy properties

Attestation bridges are designed to be radically public. Every attestation is a broadcast artefact carrying recipient addresses and amounts in cleartext. There is no anonymity primitive; the signed bundle plus the source-chain emit transaction plus the destination-chain redemption transaction provide a complete public audit trail.

## Contrast with middle-chain settlement

See [[patterns/middle-chain-swap-settlement]]. The middle-chain pattern (Thorchain, Serai) places the validator set, the custody, and the swap matching all on a single chain that the protocol owns. The attestation pattern outsources execution to whatever venue exists on the destination chain.

Net result: an attestation bridge is a transport, not a venue. A middle-chain DEX is a venue.

## Sources

- [Wormhole Architecture](https://wormhole.com/docs/protocol/architecture/) :: accessed 2026-05-19
- [Wormhole VAAs docs](https://wormhole.com/docs/protocol/infrastructure/vaas/) :: accessed 2026-05-19
- [Wormhole Security docs](https://wormhole.com/docs/protocol/security/) :: accessed 2026-05-19
- [Halborn: February 2022 Wormhole hack](https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022) :: accessed 2026-05-19
