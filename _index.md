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
| 9    | [[projects/eigenwallet]]    | BTC-XMR adaptor-signature atomic swap wallet (live community fork of comit-network/xmr-btc-swap) | yes |
| 10   | [[projects/synthetix]]      | CDP-based synthetic assets (sourced for the synthetics-design-space appendix) | yes |
| 11   | [[projects/stacks-sbtc]]    | Bitcoin-pegged asset on Stacks L2 (federation custody) — sourced for the synthetics-design-space appendix | yes |
| —    | [[projects/atomic-swap-protocol-details]] | Verification responses to PENDING-atomic-swap-protocol-details (appendix sourcing request) | reference note |
| —    | [[projects/xmr-first-atomic-swaps]] | Reverse-direction (XMR-locked-first) BTC-XMR atomic swaps — implementation status survey | reference note |
| —    | [[projects/xmr-first-required-monero-features]] | Which Monero hardfork/feature would enable XMR-first atomic swaps | reference note |
| 12   | [[projects/samourai-wallet]] | Defunct Bitcoin privacy wallet with BTC↔XMR atomic-swap GUI (seized 2024-04, founders sentenced 2025-11) | yes |
| 13   | [[projects/zwap]] | Unlinkable cross-chain atomic swaps (ECDH multiplicative key aggregation; Zcash-Orchard↔EVM; solver model; no shared hash) — Atheon | yes |
| 14   | [[projects/satora]] | Browser BTC↔EVM-stablecoin HTLC atomic swaps (Lendasat/Lendaswap; Lightning/Arkade/on-chain BTC; gasless EVM via Permit2+EIP-712; shared-hash; Ark-mediated Lightning bridge) | yes |

## Research status

- [x] [[projects/serai]] :: complete (2026-05-19)
- [x] [[projects/thorchain]] :: complete (2026-05-19)
- [x] [[projects/wormhole]] :: complete (2026-05-19)
- [x] [[projects/baltex]] :: complete (2026-05-20)
- [x] [[projects/comit]] :: complete (2026-05-20) :: scoped audit of comit-network ADRs/RFCs for staking and reputation (none found; included as negative result)
- [x] [[projects/liquity]] :: complete (2026-05-21) :: included on colleague request; documented as category mismatch — Liquity is a CDP stablecoin issuer using Chainlink CCIP (attestation-bridge family) for BOLD multi-chain, not a middle-chain DEX
- [x] [[projects/haven]] :: complete (2026-05-22) :: privacy-preserving stablecoin (xUSD) on Monero-forked L1; ring signatures, offshore banking model, depeg history
- [x] [[projects/secret-network]] :: complete (2026-05-22) :: TEE-based private smart contracts on Cosmos SDK; SNIP-20 tokens, IBC integration, SGX trust assumptions
- [x] [[projects/eigenwallet]] :: complete (2026-05-22) :: live community fork of comit-network/xmr-btc-swap; 3000+ swaps in 2023, ~89k cumulative downloads, two on-network makers on 2026-05-22; documents fork lineage and protocol-break versions
- [x] [[projects/atomic-swap-protocol-details]] :: complete (2026-05-22) :: sourcing-verification responses to the appendix request — Gugger 2020, Hoenisch–del Pino 2021, Han 2019, eigenwallet/comit env.rs timelock constants; identifies appendix claims to revise (quote step, locks-first rationale, timelock framing, 4-year timeline, Han 2019 framing)
- [x] [[projects/xmr-first-atomic-swaps]] :: complete (2026-05-22) :: no production implementation exists; eigenwallet team actively removed XMR-first chapter from protocol paper 2025-11-04 with note "unsupported by current Monero protocol, will require a hardfork to work"; Hoenisch-del Pino 2021 §4 sketch remains paper-only; surveys academic adaptor-signature work (LTRAS 2026, 2P-CLRAS 2024, MoNet 2022) and alternative chain pairs (AthanorLabs ETH-XMR, Tari RFC-0241, omarespejel Monero-Starknet) — all confirm script-rich-side-first
- [x] [[projects/xmr-first-required-monero-features]] :: complete (2026-05-22) :: digs into which Monero hardfork/feature the eigenwallet team's comment refers to; finds no specific proposal — Monero core's 2026-05-10 blog post explicitly states "no scheme has been specified that utilizes Monero's Unlock Time feature"; FCMP++ (mid-2026 target) does NOT add adaptor signatures and actively deprecates unlock_time; DLSAG (2019) and hidden timelocks (2020 issue #65) are the closest research candidates but neither is on the Monero roadmap
- [x] [[projects/samourai-wallet]] :: complete (2026-05-22) :: defunct Bitcoin privacy wallet; BTC↔XMR atomic swap GUI launched 2024-01-16 (beta 0.0.13) wrapping COMIT/xmr-btc-swap protocol via Java; founders Rodriguez and Hill arrested 2024-04-24, sentenced 2025-11-06 (5y) and 2025-11-19 (4y); community forks at noosphere888/samourai-swaps and Dezirae-Stark/Atomic-Swaps continue the codebase
- [x] [[projects/synthetix]] :: complete (2026-05-22) :: SIP-302 V3 CDP-minting citation confirmed; Synthetix sXMR (Hadar 2020-03-30, SNX-collateralised oracle synth) is NOT bridged via Secret Network — bundle's claim that the two were paired is incorrect (Secret Network sXMR is a separate SNIP-20 product)
- [x] [[projects/stacks-sbtc]] :: complete (2026-05-22) :: 15-signer federation, 70% threshold (11/15 in SIP-028, 14/10 in current operating set), mainnet deposits live 2024-12-17, withdrawals planned March 2025
- [x] [[projects/zwap]] :: complete (2026-07-01) :: Atheon's unlinkable cross-chain atomic swap; ECDH multiplicative key aggregation (`P_SB = s·P_B = b·P_S`) replaces HTLC shared hash, eliminating cross-chain correlation at protocol level; ZK binding proof ties hash leg to ECDH leg off-chain; solver/maker model (Alice locks first); Zcash-Orchard↔Ethereum/Base live in capped early access from 2026-05-27 ($1–$100), BTC + shielded-to-shielded planned; formal unlinkability proof but honest that amount/timing/UTXO-graph linkability remains; not yet externally audited. Distinct from hanh's 2023 DLEq-based "Zwap"
- [x] [[projects/satora]] :: complete (2026-07-03) :: consumer front-end for Lendasat's Lendaswap (github.com/satorahq mirrors lendasat); non-custodial browser wallet (12-word seed), shared-hash HTLC (SHA256 EVM / HASH160 BTC+Ark), Lightning→EVM is a 3-leg chain bridged by Arkade VHTLC + Boltz submarine swap; EVM leg gasless via Permit2 funding + EIP-712 relayed claim (HTLCCoordinator + 1inch); asymmetric 24h client / 12h server timelocks (hardcoded). REFUND: two routes per leg — collaborative gasless (EVM CollabRefund EIP-712 server-cosigned waiving timelock; Arkade refund_script PSBT co-sign; both instant) vs unilateral timelocked fallback (EVM self-refund after 24h w/ own gas; on-chain P2TR timelock path via MTP; server never required — all refund authority derives from mnemonic, /swap/recover re-derives history from Xpub). Refunds land in derived internal wallet not origin. 3 EVM chains (ETH/Polygon/Arbitrum), 0.25% fee, max ~0.13 BTC/swap; launched 2025-11-14; no public volume or audit found
- [x] Haven update :: complete (2026-05-22) :: status amended from "operational" to "shut down 2024-12-12 after range-proof exploit"; CoinGecko-visible XHV trading is residual
- [x] [[projects/lez-positioning]] :: complete (2026-05-19)
- [x] [[summary]] :: complete (2026-05-19)
- [x] Patterns: [[patterns/signer-federation-trust]], [[patterns/middle-chain-swap-settlement]], [[patterns/tss-custody-vault]], [[patterns/slip-based-fees]], [[patterns/attestation-bridge]], [[patterns/lock-mint-bridging]], [[patterns/atomic-swaps-vs-middle-chain]], [[patterns/instant-swap-aggregator]], [[patterns/ring-signatures]], [[patterns/offshore-banking-crypto]], [[patterns/collateralised-synthetic-assets]], [[patterns/privacy-stablecoin]], [[patterns/tee-based-privacy]], [[patterns/encrypted-smart-contracts]], [[patterns/viewing-keys]], [[patterns/private-tokens]], [[patterns/cross-chain-privacy]], [[patterns/monero-bridge]]
- [x] Trust-model deep dives: [[patterns/serai-trust-model]], [[patterns/thorchain-trust-model]], [[patterns/wormhole-trust-model]]
- [x] Metrics: [[metrics/swap-volume]], [[metrics/privacy-protocol-comparison]]
- [x] **Maker pricing research** :: complete (2026-07-03) :: [[maker-pricing/_index]] — how makers configure pricing in 6 P2P DEX/atomic-swap protocols (Bisq, Haveno, Komodo DeFi, RoboSats, eigenwallet, Farcaster). Cross-protocol comparison: [[maker-pricing/metrics/maker-pricing-parameters]]

## Research questions

1. How do Serai and Thorchain use a middle-ground chain to enable swaps between native assets on otherwise non-communicating L1s?
2. How does Wormhole's attestation-bridge model differ, and what does that tradeoff buy or cost?
3. What characteristics are *necessary* for a middle chain to settle cross-chain swaps (custody, validator economics, asset support, latency, finality)?
4. How could LEZ position itself as such a middle chain?
5. What anonymity properties can LEZ bring (zkVM, shielded state, Waku transport, sealed orderflow) that Serai, Thorchain, and Wormhole cannot match?
