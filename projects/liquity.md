---
tags: [project, cdp, stablecoin, contrast-point, category-mismatch]
ecosystem: Ethereum mainnet + L2s (Arbitrum, Base, Optimism) via Chainlink CCIP; EVM friendly-fork ecosystem
category: CDP-based decentralised stablecoin (not a cross-chain DEX)
website: https://www.liquity.org/
docs: https://docs.liquity.org/
launched: Liquity v1 mainnet 2021-04-05 (LUSD); Liquity v2 mainnet 2025 (BOLD)
---

# Liquity

Liquity is an Ethereum-native, immutable, governance-free CDP protocol issuing a USD-pegged stablecoin (LUSD in v1, BOLD in v2) against ETH and (in v2) liquid-staking-token collateral. It is included in this vault as a **negative-fit / contrast point**: colleagues mentioned it during scoping, so it is captured here for completeness, but Liquity is not a cross-chain DEX in the sense this research uses the term (see [[_index]] scope and [[patterns/middle-chain-swap-settlement]]). Its "cross-chain" story is BOLD being mintable on a few EVM L2s via Chainlink CCIP's Cross-Chain Token standard — a [[patterns/lock-mint-bridging]] / [[patterns/attestation-bridge]] consumer pattern, not a middle-chain-DEX architecture.

## Why this note exists

The research scope is "middle-ground blockchain enabling swaps between native assets on otherwise non-communicating L1s" (Thorchain, Serai, Chainflip family — see [[patterns/middle-chain-swap-settlement]]). Liquity was raised as a possible comparable. A scoped audit of its public design corpus (whitepapers, docs, official blog, monorepos) on 2026-05-21 found:

- **No middle chain.** Liquity v1 and v2 are Solidity smart-contract systems on Ethereum mainnet, with v2 friendly forks deployed independently on other EVM chains. There is no protocol-owned chain that holds custody of foreign-chain assets.
- **No native-asset cross-chain swap path.** Liquity has no analogue of Thorchain's BTC-in/ETH-out vaults or Serai's threshold-custody design. Collateral is restricted to assets that already live on the EVM chain where each branch is deployed (WETH, wstETH, rETH on mainnet v2).
- **No TSS validator set, no signer federation.** Operations are executed by immutable Solidity contracts; there are no validators bonded to a global cross-chain state. This is in deliberate contrast to [[patterns/signer-federation-trust]] and [[patterns/tss-custody-vault]].
- **Cross-chain BOLD is delegated to Chainlink CCIP.** The official integration uses CCIP's Cross-Chain Token (CCT) standard for burn-and-mint of BOLD between Ethereum, Arbitrum, Base, and Optimism. This is the same trust-model family as [[projects/wormhole]] (external attestation network mints a wrapped representation on the destination chain) — not a middle-chain DEX.

These are not omissions or roadmap items; they are explicit design choices flowing from Liquity being a borrowing protocol, not a swap venue.

## Project status (2026-05-21)

| Repo / property                | Role                                       | Status         | Notes |
|--------------------------------|--------------------------------------------|----------------|-------|
| `liquity/dev`                  | v1 monorepo (contracts, SDK, dev UI)       | Maintained     | v1 contracts are immutable on mainnet since 2021-04-05 |
| `liquity/bold`                 | v2 monorepo (contracts, subgraph, frontend)| Maintained     | v2 mainnet launch 2025 |
| v2 friendly-fork program       | Licensed redeployments on other chains     | Active, 20+ forks | Felix on Hyperliquid, Quill on Scroll, Nerite on Arbitrum, AsymmetryFi on mainnet, plus Ebisu/DeFi Dollar/Orki/Aesyx/Soneta/Mustang/Ēnosys live (per liquity.org/forks 2026-05-21) |
| BOLD cross-chain               | CCIP CCT integration                       | Live           | Ethereum + Arbitrum + Base + Optimism per official announcement |

## What Liquity actually is

### v1 (LUSD), launched 2021-04-05

- Single-collateral CDP: lock ETH in a **Trove**, mint **LUSD** at minimum 110% collateral ratio, zero interest.
- One-time borrowing fee + redemption fee, no recurring interest.
- **Stability Pool**: LUSD depositors absorb liquidations and receive the liquidated ETH at a discount. This is the system's first line of defence; if drained, debt is redistributed pro-rata to remaining Troves.
- Governance-free, immutable contracts. No admin keys, no upgradability.
- Frontends pay a kickback from LQTY rewards rather than the protocol running a single UI.

### v2 (BOLD), launched 2025

- **Multi-collateral via separate "branches":** WETH, wstETH (Lido), rETH (RocketPool). Each branch has its own `TroveManager`, `StabilityPool`, MCR, CCR, SCR, and oracle wiring. Branches do not cross-collateralise.
- **User-set interest rates:** every Trove chooses its own annual rate, denominated in BOLD. The rate is the borrower's lever for redemption risk: redemptions sweep Troves in ascending order of interest rate (lowest rate first), so paying a higher rate buys a lower probability of being redeemed.
- **75% of borrower interest** flows to BOLD depositors in each branch's Stability Pool ("Earn"). 25% is redirected to a Protocol-Incentivised Liquidity (PIL) mechanism.
- **Redemption mechanics changed vs v1.** In v2 the redemption fee stays with the redeemed Trove rather than being captured by the protocol (`borrower_loss = redeemer_gain`).
- Still immutable + governance-free; no admin key over deployed branches.

## Cross-chain story: CCIP / CCT for BOLD

This is the only sense in which Liquity is "cross-chain", and it is the relevant comparison point against this research vault.

- Liquity AG announced adoption of Chainlink's CCT standard for BOLD's cross-chain interoperability. BOLD is operational across Ethereum, Arbitrum, Base, and Optimism via this path ([liquity.org blog, 2025](https://www.liquity.org/blog/liquity-adopts-the-chainlink-standard-for-cross-chain-interoperability-for-bold) :: accessed 2026-05-21).
- **Burn-and-mint, not lock-and-mint:** CCT pools burn the token on the source chain and mint an equivalent amount on the destination chain, with pre-audited pool contracts ensuring source-burn ≡ destination-mint. This avoids per-chain liquidity pools but does not avoid the underlying attestation trust assumption.
- **Security model = Chainlink DON + Risk Management Network.** Off-chain Chainlink oracle node operators (the Decentralized Oracle Network) observe source-chain events and submit attestations to the destination chain; a separate Risk Management Network independently monitors for anomalies ([chain.link CCIP blog, 2026](https://blog.chain.link/ccip-cross-chain-standard/) :: accessed 2026-05-21).
- **Trust model classification:** this is structurally an [[patterns/attestation-bridge]] with a [[patterns/lock-mint-bridging]] variant (burn-and-mint on a fungible token). The trust root is Chainlink's oracle set + RMN, not Liquity's smart-contracts.

Implication: Liquity does not own its cross-chain layer. It is a stablecoin issuer that has outsourced multi-chain availability to a third-party bridge in the same family as Wormhole — see [[patterns/wormhole-trust-model]] for the equivalent attestation-network risk surface.

### What BOLD-on-L2 is *not*

- Not a cross-chain swap of one native asset for another. BOLD is the same asset moved between EVM domains.
- Not bonded on a Liquity-specific validator set. The bond, if any, lives in Chainlink's economic-security layer (LINK staking + node operator slashing on the CCIP/RMN side).
- Not custody of non-EVM assets. Liquity does not vault BTC, XMR, SOL, ATOM, or any non-EVM collateral on any chain.

## Trust and economics model

| Dimension                         | Liquity v1 / v2 native protocol                                       | BOLD cross-chain (CCIP CCT)                          |
|-----------------------------------|------------------------------------------------------------------------|------------------------------------------------------|
| Custody of collateral             | Solidity contracts on a single EVM chain per deployment               | n/a — BOLD only, not collateral                      |
| Validator / signer set            | None on protocol side; immutable contracts                            | Chainlink DON + Risk Management Network              |
| Slashable bond                    | Borrowers' collateral (110%+ MCR) absorbs liquidations                | LINK staking on CCIP node operators (external to Liquity) |
| Fee distribution                  | 75% borrower interest → Stability Pool depositors; 25% → PIL          | Bridge fees flow to Chainlink, not Liquity           |
| Governance over deployed system   | None (immutable contracts, no admin key, no upgradability)            | Chainlink-side governance over CCIP versioning, RMN composition, lane allowlists |
| Reorg / finality assumption       | Single-chain (Ethereum L1) finality per deployment                    | Multi-chain — depends on weakest finality among connected lanes |

The split matters: Liquity's celebrated "immutable, governance-free" property holds for the borrowing protocol itself. The cross-chain layer it relies on has none of those properties — CCIP and its RMN are externally governed and upgradable. This is not a criticism of Liquity (they were explicit in choosing CCIP), but it does mean that any "Liquity is fully decentralised" claim is scoped to the single-chain CDP, not to the multi-chain BOLD experience.

## Differentiators vs cross-chain DEXes in this vault

- **vs [[projects/thorchain]] and [[projects/serai]]**: category mismatch. Thorchain and Serai vault foreign-chain native assets (BTC, ETH, XMR, etc.) in TSS or threshold custody and provide native-asset swaps via [[patterns/middle-chain-swap-settlement]]. Liquity vaults only EVM assets that are already on the chain where its contracts run, and provides borrowing, not swapping.
- **vs [[projects/wormhole]]**: Liquity is a *consumer* of an attestation-bridge–style system (CCIP CCT) for the same job Wormhole's Portal would do — mint a representation of an asset on a destination chain. Wormhole and CCIP are direct competitors; Liquity chose CCIP. If anything, Liquity strengthens the case made in [[patterns/attestation-bridge]] that stablecoin issuers prefer attestation bridges over middle-chain DEXes when they need multi-chain token presence (it is operationally simpler and aligns with their issuer-centric trust model).
- **vs [[projects/baltex]] and [[projects/comit]]**: also category mismatch. Baltex is a privacy-focused swap aggregator and COMIT is an atomic-swap primitive; Liquity is a CDP issuer. They share no surface.

## Limitations and criticisms (in scope for this research)

These are the points relevant to *why Liquity does not belong in this vault as a peer*, not a full critique of the project on its own terms.

- **Not a swap venue.** There is no Liquity-native primitive that exchanges asset A on chain X for asset B on chain Y. Any such swap involving BOLD requires either (a) CCIP to move BOLD between EVM chains, then a DEX on the destination chain, or (b) a third-party aggregator to compose the two legs. This puts Liquity strictly outside the [[patterns/middle-chain-swap-settlement]] family.
- **EVM-only reach.** The friendly-fork program extends BOLD's reach by *redeploying the v2 codebase* on other EVM chains (Hyperliquid, Scroll, Arbitrum, etc.). It does not extend Liquity to non-EVM ecosystems. Bitcoin/Monero/Solana/Cosmos collateral is not on the roadmap and would require an entirely different architecture.
- **Cross-chain trust is outsourced, not absorbed.** This is the meaningful structural contrast against this vault: Thorchain, Serai, and the LEZ direction explicitly internalise cross-chain custody and validator economics, accepting the complexity in exchange for not depending on an external bridge consortium. Liquity does the opposite — and the trade-off looks correct *for an issuer of an EVM-native stablecoin*, but is the wrong template for a privacy-focused cross-chain DEX.
- **Friendly-fork fragmentation.** Each friendly fork mints its *own* stablecoin (e.g., Felix's stable on Hyperliquid is not BOLD, even though the codebase is shared). Liquidity for "Liquity-family stables" is therefore fragmented across forks, with CCIP only bridging the canonical BOLD. This is a deliberate licensing choice but means the "BOLD everywhere" framing is narrower than it first appears.

## Implication for LEZ positioning

Liquity provides a useful boundary case for [[projects/lez-positioning]]:

1. **It confirms the issuer-vs-DEX split.** Stablecoin issuers (Liquity, Circle USDC's CCTP, etc.) increasingly choose attestation-bridge or burn-and-mint paths for multi-chain reach because their job is to keep one asset (the stable) consistent across chains. DEXes — and the LEZ direction — face a strictly harder problem: maintaining *bidirectional* custody of *heterogeneous* native assets. Liquity's choice of CCIP corroborates that the attestation-bridge pattern is well-fit for issuers, leaving the middle-chain-DEX pattern as the appropriate frame for the LEZ.
2. **It does not contribute to the trust-model peer set.** Adding Liquity to comparisons in [[metrics/swap-volume]] or [[patterns/signer-federation-trust]] would mix categories and weaken the analysis. The peer set for LEZ remains Thorchain, Serai, Chainflip-class designs, with Wormhole as the attestation-bridge contrast already on file.
3. **The privacy story is absent.** Liquity has no shielded-state, sealed-orderflow, or mempool-privacy properties. BOLD transactions and Trove positions are publicly visible on each EVM chain it inhabits. This is one more axis on which the LEZ thesis (zkVM + Waku transport + shielded state, per [[projects/lez-positioning]]) does not overlap Liquity's design space.

**Verdict: do not promote Liquity to a peer of Thorchain/Serai/Wormhole.** Keep this note as the documented reason colleagues' suggestion was considered and scoped out.

## Sources

- [Liquity Adopts the Chainlink Standard for Cross-Chain Interoperability for BOLD (Liquity blog)](https://www.liquity.org/blog/liquity-adopts-the-chainlink-standard-for-cross-chain-interoperability-for-bold) :: accessed 2026-05-21 :: [archived](sources/2026-05-21-liquity-org-blog-chainlink-ccip-bold.html)
- [Chainlink CCIP: The Secure and Decentralized Cross-Chain Standard (Chainlink blog)](https://blog.chain.link/ccip-cross-chain-standard/) :: accessed 2026-05-21 :: [archived](sources/2026-05-21-blog-chain-link-ccip-cross-chain-standard.html)
- [Chainlink Cross-Chain Token (CCT) standard (docs)](https://docs.chain.link/ccip/concepts/cross-chain-tokens) :: accessed 2026-05-21 :: archival failed (JS-rendered docs SPA returned stub); content cross-verified against the Chainlink blog above
- [Liquity V2 Whitepaper](https://liquity.gitbook.io/v2-whitepaper) :: accessed 2026-05-21 :: [archived](sources/2026-05-21-liquity-gitbook-io-v2-whitepaper.html)
- [Liquity V2 Documentation home](https://docs.liquity.org/) :: accessed 2026-05-21 :: [archived](sources/2026-05-21-docs-liquity-org-v2-home.html)
- [Liquity V1 Documentation home](https://docs.liquity.org/liquity-v1) :: accessed 2026-05-21 :: [archived](sources/2026-05-21-docs-liquity-org-v1-home.html)
- [Liquity V2 Redemptions and Delegation (docs)](https://docs.liquity.org/v2-faq/redemptions-and-delegation) :: accessed 2026-05-21 :: [archived](sources/2026-05-21-docs-liquity-org-redemptions-delegation.html)
- [Liquity V2 Friendly Fork Program (docs)](https://docs.liquity.org/v2-documentation/friendly-fork-program) :: accessed 2026-05-21 :: [archived](sources/2026-05-21-docs-liquity-org-friendly-fork-program.html)
- [Liquity V2 Forks page (liquity.org/forks)](https://www.liquity.org/forks) :: accessed 2026-05-21 :: [archived](sources/2026-05-21-liquity-org-forks.html)
- [liquity/bold (v2 monorepo, GitHub)](https://github.com/liquity/bold) :: accessed 2026-05-21 :: unarchived (GitHub UI; sources for v2 are covered via the whitepaper and docs)
- [liquity/dev (v1 monorepo, GitHub)](https://github.com/liquity/dev) :: accessed 2026-05-21 :: unarchived (GitHub UI; sources for v1 are covered via the docs)
