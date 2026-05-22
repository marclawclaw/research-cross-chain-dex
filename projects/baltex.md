---
tags: [project, instant-swap-aggregator, cross-chain-dex, privacy, off-chain]
ecosystem: Off-chain (single-operator service)
category: Instant-swap aggregator with optional Monero-rail privacy
website: https://baltex.io
docs: https://baltex.io/support/how-it-works
launched: 2025 (founded); Private Swaps launched 2025-11-24
operator: GGWP Limited (Jacó, Puntarenas, Costa Rica)
---

# Baltex

Baltex is a privacy-oriented cross-chain instant-swap aggregator operated by GGWP Limited out of Jacó, Costa Rica. It is not a protocol, a chain, or a DEX in the [[thorchain]] / [[serai]] sense — there is no validator set, no bonded stake, and no protocol-owned vault. Instead, a single corporate operator runs a routing engine that fronts an interface across DEX aggregators, cross-chain bridges, centralised-exchange order books, and its own in-house market-making inventory ([[../patterns/instant-swap-aggregator]]). Its distinctive feature, launched 2025-11-24, is a Private Swaps mode that inserts a Monero hop into the route to break external chain-analysis linkability between the inbound and outbound legs, at the cost of trusting Baltex itself with the linkage.

## Operator and corporate facts

| Field | Value | Source |
|-------|-------|--------|
| Trading name | Baltex | [Baltex homepage](https://baltex.io/) |
| Operating entity | GGWP Limited | [Privacy Policy](https://baltex.io/legal/privacy-policy) |
| Stated headquarters | Jacó, Puntarenas, Costa Rica | [Benzinga 2026-03-02 press release](https://www.benzinga.com/pressreleases/26/03/50975393/baltex-announces-xmr-to-trx-swaps-now-completing-in-as-little-as-20-minutes) |
| Governing law | Laws of Costa Rica | [Terms of Service](https://baltex.io/legal/terms-of-services) |
| Founded | 2025 | [TechBehemoths](https://techbehemoths.com/company/baltex) |
| Headcount | ~10 employees | [TechBehemoths](https://techbehemoths.com/company/baltex) |
| Founder | Evgeniia Iarmenko | [Ventureburn](https://ventureburn.com/baltex-unveils-fully-cross-chain-private-swap-technology/) |
| CMO | Andrei K. ("Andri Ko") | [Ventureburn](https://ventureburn.com/baltex-unveils-fully-cross-chain-private-swap-technology/) |
| Private Swaps launch | 2025-11-24 | [DLNews 2025-11-24](https://www.dlnews.com/external/baltex-launches-fully-cross-chain-private-swaps/) |
| Open-source code | None published | Web search; no GitHub presence |

## Adoption metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| TVL | n/a (no protocol-owned vault) | 2026-05-20 | — |
| Public volume figures | None published | 2026-05-20 | Not indexed on DefiLlama |
| Supported tokens (marketing) | 10,000+ | 2026-05-20 | [Baltex homepage](https://baltex.io/) (aggregated upstream count) |
| Supported networks (marketing) | 200+ | 2026-05-20 | [Baltex homepage](https://baltex.io/) — but private-swaps page claims only 13 networks |
| Major chains named | ETH, SOL, BTC, BNB, Polygon, Base, Arbitrum, Optimism, Avalanche, Tron, TON | 2026-05-20 | [Baltex homepage](https://baltex.io/) |
| Trustpilot rating | ~4.3–4.5 stars on ~15 reviews | 2026-05-20 | [Trustpilot listing](https://www.trustpilot.com/review/baltex.io) (only snippet available; Cloudflare blocked full archive) |
| Standard swap fee (claimed) | < 0.1% | 2026-05-20 | [Baltex blog](https://baltex.io/blog/ecosystem/cross-chain-swaps-swap-crypto-between-blockchains-instantly) |
| Private Swap fee | from 0.4% | 2025-11-24 | [DLNews](https://www.dlnews.com/external/baltex-launches-fully-cross-chain-private-swaps/) |
| Private swap completion time | 10–20 min typical, up to 45 min for large USDT→XMR with auto-splitting | 2026-05-20 | [DLNews](https://www.dlnews.com/external/baltex-launches-fully-cross-chain-private-swaps/); [Baltex USDT→XMR blog](https://baltex.io/blog/ecosystem/no-kyc-crypto-swaps-usdt-to-xmr-privately) |

Numbers are operator-reported. No on-chain dashboard, no DefiLlama listing, no independently verified volume.

## How it works

### User perspective

1. User picks source asset, destination asset, destination wallet at app.baltex.io. Two rate modes: **fixed** (locks the quote, higher fee, operator absorbs price risk) or **floating** (executes at fill, lower fee, user absorbs price risk) ([how-it-works](https://baltex.io/support/how-it-works)).
2. For Private Swaps, the user explicitly opts in to the Monero-rail route ([private-swaps page](https://baltex.io/private-swaps)).
3. Baltex generates a one-shot transit deposit address on the source chain. User funds it.
4. Inbound is screened by Baltex's AML / sanctions logic against sanctions lists, darknet markets, mixers, fraud rings, and high-risk clusters ([AML page](https://baltex.io/aml)). Clean funds proceed; flagged funds may be frozen pending KYC / Enhanced Due Diligence and are refundable (minus network fees) on non-completion ([Risk Disclosure](https://baltex.io/legal/risk-disclosure)).
5. Baltex's routing engine executes the path through some combination of DEX aggregators, cross-chain bridges, CEX order books, and its own in-house market-making inventory ([Baltex blog: best tools for cross-chain swaps](https://baltex.io/blog/ecosystem/best-tools-for-cross-chain-swaps)).
6. For Private Swaps, the path inserts a Monero hop: `src → intermediate → XMR → intermediate → dst`, with stealth addresses, ring signatures, and RingCT breaking the on-chain link between legs ([DLNews](https://www.dlnews.com/external/baltex-launches-fully-cross-chain-private-swaps/)).
7. Destination asset is sent from Baltex's withdrawing address to the user wallet. Typical completion 10–45 minutes.

### Protocol perspective

- **No native chain, no validator set, no bonded stake**: Baltex is a routing UI plus operator-controlled inventory. No smart contracts deployed by Baltex on any served chain (no contract addresses disclosed; no GitHub presence verified by web search).
- **Two product layers** described in legal terms ([Terms of Service](https://baltex.io/legal/terms-of-services)):
  - **DEX Layer**: "Non-custodial, on-chain swap interface routing via third-party smart contracts" — Baltex acts as a front-end over upstream DEX aggregators.
  - **Private Exchange**: necessarily includes a custodial leg, since Monero cannot atomically interlock with EVM / UTXO chains without HTLC infrastructure that Baltex does not implement.
- **Custody window**: hackers.tools, in the most candid third-party piece, notes Baltex's "short custody window because Monero routing or off-chain liquidity can't be done purely on-chain" — directly contradicting marketing language that calls the service "100% non-custodial" ([hackers.tools profile](https://hackers.tools/articles/baltex-privacy-first-cross-chain-swap-hackers-actually-use)).
- **AML / sanctions screening** is the only externally verifiable security-related practice ([AML page](https://baltex.io/aml)).

See [[../patterns/instant-swap-aggregator]] for the full pattern.

## Trust model

Baltex is a **single-operator custodian** for any cross-chain or Private Swap leg. Trust assumptions:

- **Operator solvency**: GGWP Limited holds user funds during the cross-chain hop. No proof of reserves, no bond, no third-party slashing. If Baltex absconds, users have only Costa Rican civil recourse.
- **Operator honesty during the privacy hop**: Baltex by construction sees both endpoints of any Private Swap because it executes the conversion. Monero protects against *external* chain analysis but not against Baltex itself, its employees, or anyone with subpoena power.
- **Sanctions discretion**: the operator may freeze any inbound at AML discretion. There is no protocol-enforced settlement guarantee. Prohibited jurisdictions are DPRK, Iran, Syria, Russia, "and others designated from time to time" ([Risk Disclosure](https://baltex.io/legal/risk-disclosure)).
- **No cryptographic accountability**: matching, routing, inventory, and pricing decisions are off-chain and opaque. There is nothing analogous to Thorchain's TSS signing transcript or Serai's published In Instructions.

This is materially weaker than [[../patterns/signer-federation-trust]] (which requires N-of-M collusion among independent firms) and is closest to a centralised exchange that happens to have no account system.

See [[../patterns/instant-swap-aggregator]] for the pattern-level treatment.

## Privacy properties

- **External observer linkability** (chain analysis on the public source and destination chains): broken when Private Swaps are used. Stealth addresses, ring signatures, and RingCT on the Monero hop prevent linking a BTC inbound to an ETH outbound.
- **Operator linkability**: not broken. Baltex sees both endpoints by construction. Privacy depends on Baltex's data-retention policy (5–10 years for KYC-flagged transactions per the Privacy Policy; shorter but no encrypted-at-source guarantee for clean swaps).
- **Shielded execution**: none. Amounts, intent, and timing are exposed to the operator and, in many cases, to upstream venues used to route the swap.
- **KYC posture**: none by default; triggered when AML risk scoring, sanctions screening, or PEP flags trip ([FAQ](https://baltex.io/support/faq); [AML page](https://baltex.io/aml)).
- **Comparison**:
  - Materially **stronger** than [[thorchain]] / [[serai]] for the *external observer* model: their memo / In Instruction systems publish swap intent on the source chain, so chain analysis can trivially link cross-chain swaps end-to-end. Baltex's own blog at [Baltex private swaps guide](https://baltex.io/blog/ecosystem/thorchain-private-swaps-anonymous-btc-2026-guide) explicitly states Thorchain "is decentralised but not private," which is the gap Baltex positions itself to fill.
  - Materially **weaker** than the LEZ ideal of zk-shielded execution where even the middle chain cannot see the linkage. See [[lez-positioning]].

## Incidents and audits

- **No reported incidents** as of 2026-05-20. Baltex did not appear in any major crypto-hack coverage searched (DLNews, Coindesk, Cointelegraph, Decrypt, AMBCrypto).
- **Audits**: self-claimed in press releases ("infrastructure has undergone security audits") but no audit firm named, no audit report published, no scope or date disclosed. Flag as **unverified self-reported**. ([Benzinga press release](https://www.benzinga.com/pressreleases/26/03/50975393/baltex-announces-xmr-to-trx-swaps-now-completing-in-as-little-as-20-minutes)).
- **Open-source code**: none. No public GitHub repository. All "security" claims rest on operator reputation.

## Differentiators vs [[thorchain]], [[serai]], [[wormhole]]

| Axis | Baltex | [[thorchain]] | [[serai]] | [[wormhole]] |
|------|--------|---------------|-----------|--------------|
| Native chain | None | Cosmos SDK L1 | Substrate L1 | None |
| Custody | Single operator (GGWP Limited) | TSS Asgard vaults (validator set) | FROST multisig (validator set) | Per-chain bridge contracts |
| Liquidity | Aggregated DEX/CEX + in-house book | Protocol-owned CLPs | Protocol-owned xy=k AMM | None (solvers / external DEXes) |
| Validator economics | None (single corporate entity) | RUNE-bonded, 103–120 nodes | Stake-bonded, up to 600 | 19 named firms, reputational only |
| Privacy | Optional Monero hop (operator-visible) | None (memos public) | None planned (public Substrate) | None (VAAs public) |
| Settlement guarantee | Operator discretion (AML freeze possible) | Protocol-enforced | Protocol-enforced | Protocol-enforced after VAA |
| Open source | No | Yes | Yes | Yes |
| Audits | Self-claimed, no firm named | Halborn, Trail of Bits, others | Cypher Stack, Trail of Bits, HashCloak, SRLabs | 29 audits across many firms |
| KYC | Triggered on AML risk | None | None | None |

Baltex belongs in a different architectural category to the other three. The closer comparison group is ChangeNOW / SideShift / FixedFloat / Stealthex / Trocador / eXch.cx (single-operator instant-swap aggregators), not protocol-level cross-chain DEXes.

## Why this matters for LEZ

Baltex demonstrates that **privacy is the most productisable feature in the cross-chain swap market** — and that the dominant deployed solution today is "trust a single operator plus a Monero hop." That is the load-bearing demand signal for [[lez-positioning]]: users are paying 0.4% fees and accepting a single-operator trust model to get *external observer* unlinkability. A middle-chain DEX with zk-shielded execution could offer the same external unlinkability *and* break operator linkability simultaneously — addressing both gaps Baltex leaves open.

See [[../patterns/instant-swap-aggregator]] for the pattern, and [[lez-positioning]] for how LEZ could differentiate.

## Limitations and criticisms

- **Single point of failure**: GGWP Limited operates alone. Exit-scam, insolvency, hot-wallet compromise, or regulatory seizure ends the service.
- **No verifiable solvency**: no proof of reserves; users cannot audit whether the operator is running fractional reserves.
- **"100% non-custodial" marketing vs reality**: third-party coverage admits a custody window for any cross-chain or privacy swap. Marketing language overstates the trust model.
- **Sanctions discretion**: the operator may freeze any inbound at AML discretion, with no protocol guarantee of settlement.
- **Unverified audits**: audit claims are self-reported with no firm named, no report published.
- **No open-source code**: no GitHub, no contract addresses, no published implementation. Security claims rest entirely on operator reputation.
- **Operator linkability**: Private Swaps break chain analysis but not the operator's view; the operator and anyone with subpoena power over it can de-anonymise any swap.
- **Inflated chain-count claims**: "10,000 tokens / 200 networks" homepage figures are aggregated upstream counts, not native integrations. The private-swaps page itself lists ~13 networks.
- **Regulatory drift**: increasing pressure on non-KYC swap services (FATF travel rule, EU MiCA, US Treasury sanctions) creates ongoing existential risk for the category.

## Sources

All accessed 2026-05-20.

Primary (Baltex official):
- [Baltex homepage](https://baltex.io/)
- [Baltex Private Swaps](https://baltex.io/private-swaps)
- [Baltex FAQ](https://baltex.io/support/faq)
- [Baltex how-it-works](https://baltex.io/support/how-it-works)
- [Baltex AML policy](https://baltex.io/aml)
- [Baltex Risk Disclosure](https://baltex.io/legal/risk-disclosure)
- [Baltex Terms of Service](https://baltex.io/legal/terms-of-services)
- [Baltex Privacy Policy](https://baltex.io/legal/privacy-policy)

Baltex blog (self-reported, treat with caution):
- [Cross-chain swaps explainer](https://baltex.io/blog/ecosystem/cross-chain-swaps-swap-crypto-between-blockchains-instantly)
- [No-KYC USDT→XMR walkthrough](https://baltex.io/blog/ecosystem/no-kyc-crypto-swaps-usdt-to-xmr-privately)
- [Best tools for cross-chain swaps](https://baltex.io/blog/ecosystem/best-tools-for-cross-chain-swaps)
- [Best no-KYC Monero swappers 2026](https://baltex.io/blog/ecosystem/best-no-kyc-monero-xmr-swappers-2026)
- [Top swapper platforms ranked](https://baltex.io/blog/ecosystem/top-swapper-platforms-ranked-best-places-trade-crypto-fast)
- [Thorchain private swaps guide](https://baltex.io/blog/ecosystem/thorchain-private-swaps-anonymous-btc-2026-guide)

Third-party:
- [DLNews: Baltex launches fully cross-chain private swaps](https://www.dlnews.com/external/baltex-launches-fully-cross-chain-private-swaps/) (2025-11-24; syndicated, partially self-reported)
- [Ventureburn: Baltex unveils private swap technology](https://ventureburn.com/baltex-unveils-fully-cross-chain-private-swap-technology/) (likely sponsored placement)
- [Benzinga press release: XMR→TRX swap timing](https://www.benzinga.com/pressreleases/26/03/50975393/baltex-announces-xmr-to-trx-swaps-now-completing-in-as-little-as-20-minutes) (2026-03-02; press release)
- [hackers.tools: Baltex privacy-first cross-chain swap](https://hackers.tools/articles/baltex-privacy-first-cross-chain-swap-hackers-actually-use) (most candid third-party piece; admits custody window)
- [TechBehemoths company profile](https://techbehemoths.com/company/baltex) (founded 2025, ~10 employees)
- [AlternativeTo: Baltex](https://alternativeto.net/software/baltex/about/) (Cloudflare-blocked; listing-summary only)
- [Slashdot: Baltex](https://slashdot.org/software/p/Baltex/) (Cloudflare-blocked; corroborates Jacó HQ and 2025 founding)
- [Trustpilot reviews of baltex.io](https://www.trustpilot.com/review/baltex.io) (HTTP 403; rating snippet only)

Local source archive: `sources/2026-05-20-*.html` and `sources/2026-05-20-NOTES-baltex-deep-research.md`.
