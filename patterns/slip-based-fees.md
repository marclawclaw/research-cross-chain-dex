---
tags: [pattern, amm, fees, mev]
status: established
---

# Pattern: Slip-based fees for AMMs

In a constant product (xy = k) AMM the fee is typically a flat percentage of trade size (Uniswap v2: 0.30 percent). This is independent of pool depth, so very large trades, which create the most price impact and the most MEV opportunity, pay a relatively small fee. Slip-based fees instead scale with the swap size relative to pool depth, charging more for trades that move price further.

## Formula (Thorchain CLP)

For an input `x` swapped into a pool with input balance `X` and output balance `Y`:

- Output `y = (x * Y * X) / (x + X)^2`
- Slip-based fee `fee = (x^2 * Y) / (x + X)^2`

The fee is implicitly subtracted from the constant product output; quoted in the asset being received. Reference: [CLP docs](https://docs.thorchain.org/technical-documentation/thorchain-finance/continuous-liquidity-pools.md).

## Why it works

- Small swaps relative to pool depth approach zero fee, encouraging arbitrage to keep price aligned with reference markets.
- Large swaps see fee rise quadratically in the slip term, making them expensive without explicit limit setting.
- Naturally throttles toxic flow without a separate MEV protection mechanism.
- LP revenue scales with both volume and pool stress, not just volume.

## Composition with streaming swaps

Thorchain lets a single inbound be split into many sub swaps over many blocks, each one priced against a fractional pool footprint. A price optimised stream can drive the effective swap fee as low as 5 basis points ([streaming swaps](https://dev.thorchain.org/swap-guide/streaming-swaps.html), [CLP docs](https://docs.thorchain.org/technical-documentation/thorchain-finance/continuous-liquidity-pools.md)). This trades latency for fee compression and further reduces MEV surface.

## Trade-offs vs flat fee

| Property | Slip-based | Flat percentage |
|----------|-----------|-----------------|
| Sensitive to pool depth | yes | no |
| Discourages toxic large flow | yes, automatic | no, separate guard needed |
| Simple to communicate | no, depends on depth at fill | yes |
| Arbitrage friction at parity | very low | constant |
| LP revenue at high stress | very high | linear in volume |

## Used by

- [[../projects/thorchain]] continuous liquidity pools

## See also

- [[middle-chain-swap-settlement]]
