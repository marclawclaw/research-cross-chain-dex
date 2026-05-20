---
tags: [pattern, cross-chain, bridge, token-transfer]
---

# Lock-mint bridging

Lock-mint (also "lock-and-mint") is the dominant token bridging primitive used by attestation bridges and most cross-chain token bridges. A token on a source chain is locked in a custodian contract; an attestation that the lock occurred authorises a destination-chain mint of a wrapped representation. Burning the wrapped representation on the destination chain authorises a release on the source chain.

## Canonical example

[[projects/wormhole]] Wrapped Token Transfers (WTT): the source-chain Token Bridge contract locks the native token, a 13-of-19 Guardian VAA attests the lock, and the destination-chain Token Bridge mints a Wormhole-wrapped version of the token. The wrapped contracts are owned by Wormhole Governance and are not upgradeable by the original issuer ([Wormhole Token Transfers Overview](https://wormhole.com/docs/products/token-transfers/overview/) :: accessed 2026-05-19).

## Variants

- **Lock-mint (canonical):** token never leaves source chain; an IOU minted on destination. Wormhole WTT, classic Token Bridge.
- **Burn-mint:** token is destroyed on source and minted on destination. Same total supply, different distribution. Wormhole Native Token Transfers (NTT) burn-and-mint mode; Circle CCTP.
- **Hub-and-spoke (lock-mint on one chain, burn-mint elsewhere):** the original chain is the hub holding inventory; spokes mint wrapped versions but with the issuer retaining contract ownership. Wormhole NTT hub-and-spoke mode.

## What it gives you

- Strict 1:1 backing as long as the lock and the mint stay in sync.
- Permissionless wrapped-token deployment for new chains.
- Composability with destination-chain DeFi as soon as the wrapped token exists.

## What it does not give you

- **No swap.** Lock-mint produces wrapped-A on chain Y in exchange for native-A on chain X. To get native-B on chain Y, the user must then trade on a destination-chain DEX. The bridge does not match orders or hold inventory of B.
- **No protocol-owned liquidity.** Unlike middle-chain DEXes (see [[patterns/middle-chain-swap-settlement]]), the bridge has no LP pools and bears no inventory risk; but it also cannot offer cross-asset swaps natively.
- **Fragmentation.** A token issued natively on chain X with a Wormhole-wrapped version on chain Y is not the same asset as the same token bridged via LayerZero, Axelar, or a chain-specific canonical bridge. Each wrapping is its own contract address.
- **Liveness coupled to the attesters.** If the Guardian set or equivalent committee halts, both directions of the bridge halt; the locked tokens are stranded.

## Custodial properties

- Custody is per-chain. The Wormhole Token Bridge on Ethereum holds the locked ETH/USDC/etc.; the Token Bridge on Solana mints wrapped representations.
- A bug in any chain's bridge contract (as in [[projects/wormhole]] February 2022) lets an attacker mint unbacked wrapped tokens without touching the lock side; the resulting under-collateralisation propagates to every chain holding the wrapped representation.
- This contrasts with TSS-vault custody on a middle chain ([[patterns/middle-chain-swap-settlement]]), where the validator set itself controls the keys and there is a single accounting record.

## Privacy properties

Both legs (the lock and the mint) are public. The attestation bundle (Wormhole VAA, etc.) names the source address, destination address, amount, and token contract; both transactions are linkable via the attestation index. No anonymity primitive is part of the lock-mint design.

## Sources

- [Wormhole Token Transfers Overview](https://wormhole.com/docs/products/token-transfers/overview/) :: accessed 2026-05-19
- [Wormhole Native Token Transfers FAQs](https://wormhole.com/docs/products/token-transfers/native-token-transfers/faqs/) :: accessed 2026-05-19
- [Wormhole VAAs docs](https://wormhole.com/docs/protocol/infrastructure/vaas/) :: accessed 2026-05-19
- [Halborn: February 2022 Wormhole hack](https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022) :: accessed 2026-05-19
