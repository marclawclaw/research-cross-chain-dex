---
tags: [project, synthetic-assets, cdp, ethereum]
ecosystem: Ethereum (L1) + L2 deployments
category: CDP-based synthetic assets
website: https://synthetix.io
docs: https://docs.synthetix.io
launched: 2018 (as Havven; rebranded Synthetix late 2018)
status: Active. V3 stack live; V2 sunsetting on most synths
---

# Synthetix

Synthetix is an Ethereum-based CDP protocol for issuing synthetic assets (Synths). Stakers deposit collateral (originally SNX; in V3 SNX, ETH, USDC, stataUSDC and governance-approved tokens) and mint snxUSD (V3) or sUSD (V2) against it; that debt position lets the user hold any Synth representing the price of an external asset, tracked by Chainlink oracle, without holding the underlying.

This note exists to source two specific claims relevant to the cross-chain DEX RFP work:
1. Synthetix's CDP-minting reference is **SIP-302 (Pools V3)**.
2. Whether Synthetix ever listed an **sXMR** synth for Monero, and whether it was bridged via Secret Network.

## Claim S2: SIP-302 covers V3 CDP minting — VERIFIED

SIP-302 "Pools (V3)" introduces the V3 pools and vaults primitive. The relevant text ([sips.synthetix.io/sips/sip-302](https://sips.synthetix.io/sips/sip-302) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-sips-synthetix-io-sip-302.html)):

> The Vault Module creates vaults of each collateral type per pool, similar to a CDP (MakerDAO, Liquity), where accounts can delegate their staked collateral to pools by opening staking positions and then mint and burn snxUSD, backed by their collateral.

The SIP also constrains: *"governance determines the types of collateral that can be deposited"*; *"snxUSD is fungible regardless of the pool from which it was minted"*. The Issuance Ratio per collateral type is the minimum collateralisation ratio.

**Bundle citation is correct.** SIP-302 is the canonical V3 CDP-minting reference. For the V2 c-ratio + sUSD model, the historical reference is the original Synthetix whitepaper plus SIP-7 era; for V3 alone, SIP-302 plus SIP-300 (the V3 master SIP) are the canonical references.

## Claim S4: sXMR — Synthetix DID list a Monero synth, but it was NOT bridged via Secret Network — VERIFIED with correction

- **Synth sXMR (Synthetix-issued ERC-20)**: contract address `0x5299d6F7472DCc137D7f3C4BcfBBB514BaBF341A` on Ethereum L1. Listed as part of the **Hadar release (2020-03-30)** along with five other crypto synths: BCH, ADA, DASH, EOS, **XMR**, ETC ([Synthetix blog: New Synths update for the upcoming Hadar release](https://blog.synthetix.io/new-synths-update-for-the-upcoming-hadar-release/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-blog-synthetix-io-hadar-release.html)).
- **How sXMR worked on Synthetix**: SNX-collateralised CDP synth tracking the Monero price via Chainlink oracle, just like every other Synth in the V2 era. No bridge, no wrapped Monero — the contract held no Monero, only SNX collateral was at risk. Synthetic Monero exposure for traders on Synthetix.Exchange, not a Monero-redeemable token.
- **There is also a separate "sXMR" on Secret Network**: a SNIP-20 wrapped-Monero token issued by the Secret Monero Bridge (see [[projects/secret-network]]). The name collision is unfortunate but the products are unrelated:
  - **Synthetix sXMR**: ERC-20, Ethereum, SNX-collateralised, oracle-priced, not redeemable for XMR.
  - **Secret Network sXMR**: SNIP-20, Secret Network, federation-custodied real XMR, redeemable for XMR.
- **Therefore the bundle's claim that "Synthetix had a historical sXMR token paired with the Secret Network Monero Bridge" is wrong.** Synthetix's sXMR was never connected to Secret Network. The closest historical precedent for "a privacy-style XMR-tracking synth" is either (a) Synthetix sXMR alone (CDP synth on Ethereum, no privacy property), or (b) Secret Network sXMR alone (bridge-wrapped real XMR with TEE privacy), but not their combination.

**Recommended appendix fix**: in the synthetics-design-space appendix, replace *"Synthetix's historical sXMR token paired with the Secret Network Monero Bridge"* with one of two narrower formulations:
1. *"Synthetix listed sXMR (an SNX-collateralised oracle-priced Monero synth on Ethereum L1) from the Hadar release in March 2020. The Secret Network Monero Bridge issued an unrelated 'sXMR' SNIP-20 on Secret Network using TEE-based federation custody of real XMR. The two products share the ticker but not the design."*
2. *"As-CDP precedents for an XMR-tracking synth: Synthetix sXMR (oracle-priced, no underlying XMR). As-bridge precedents: Secret Network Monero Bridge sXMR (custody-backed wrapped real XMR)."*

## How V3 works (brief)

### User perspective
1. Pick a Pool and a Collateral Type approved by governance (e.g. an SNX-only pool, or a multi-collateral pool with ETH/USDC/stataUSDC).
2. Deposit collateral into a Vault.
3. Mint snxUSD against the Vault up to the Issuance Ratio for that collateral.
4. Hold snxUSD or use it elsewhere. To exit, burn the same snxUSD and withdraw collateral.

### Protocol perspective
- The V3 Core (SIP-300) is a market-and-pool primitive. Pools accept collateral and back snxUSD; Markets consume snxUSD liquidity (e.g. perps, spot, perps-on-XMR via oracle).
- Each Vault tracks debt as a share of the system's debt pool. The Issuance Ratio is the minimum c-ratio.
- Liquidations occur if a Vault's c-ratio breaches the threshold; liquidation parameters are per-collateral and governance-set.

## Differentiators (relative to the RFP work)

- **Synthetix is the canonical CDP-synth-of-everything model** — the bundle's reference to "Synthetix CDP" is shorthand for this design. The L1 deployment shows the model works at low-to-mid volume but is constrained by Ethereum gas and oracle update latency.
- **Synths are not bridged assets**. There is no underlying XMR backing sXMR; the trust shape is "do you trust SNX-collateralisation + Chainlink oracle". This is structurally different from a bridge product (Secret Monero Bridge, Wormhole, Thorchain TSS vaults).

## Limitations and criticisms

- **Oracle dependency**: the synth tracks the oracle, not the underlying. An XMR oracle outage or manipulation propagates directly into the sXMR price.
- **No physical redemption**: holders of sXMR cannot redeem real XMR. The synth is a debt instrument against SNX, not a wrapper.
- **Debt pool socialisation**: in V2, all sUSD holders shared aggregate Synth debt. V3 separates per-pool debt but inherits the same accounting model within a pool.

## Sources

- [SIP-302: Pools (V3)](https://sips.synthetix.io/sips/sip-302) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-sips-synthetix-io-sip-302.html)
- [Synthetix blog: New Synths update for the upcoming Hadar release](https://blog.synthetix.io/new-synths-update-for-the-upcoming-hadar-release/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-blog-synthetix-io-hadar-release.html)
- [Synth sXMR ERC-20 contract on Etherscan](https://etherscan.io/token/0x5299d6F7472DCc137D7f3C4BcfBBB514BaBF341A) :: accessed 2026-05-22 (not archived — Etherscan rate-limits archival tools; data point is contract existence at the named address)
- [[projects/secret-network]] for the unrelated Secret Network sXMR SNIP-20
