---
tags: [pattern, defi, synthetic-assets]
seen_in: [haven, synthetix]
---

# Collateralised Synthetic Assets

Synthetic assets are tokens that track the price of an underlying asset (fiat, commodity, crypto) without holding the asset directly. They are minted by locking collateral (usually the protocol's native token) and burning when redeemed. Over-collateralisation protects against insolvency during price volatility.

## Implementations

- **[[projects/haven]]:** XHV is locked to mint xAssets at oracle prices. The protocol targets a minimum collateralisation ratio. Conversions between xAssets burn the source and mint the destination, creating an elastic supply.
- **Synthetix:** SNX stakers mint sUSD and other synths against SNX collateral at a 400% collateralisation ratio. Debt is pooled across all stakers.
- **MakerDAO:** ETH and other assets are locked in CDPs to mint DAI. Liquidation mechanisms protect against under-collateralisation.

## Relevance to Logos

Collateralised synthetic assets could be a building block for LEZ: users deposit assets as collateral and mint private synthetic equivalents for cross-chain use. Requirements include reliable oracle feeds, liquidation mechanisms, and privacy of collateral positions. Haven's depeg history shows that oracle reliability and liquidity depth are critical failure modes.
