# Baltex deep-research working notes (2026-05-20)

Output of the deep-research skill for subject **Baltex** (https://baltex.io/).

## Subject classification

Baltex is **not** a middle-chain DEX in the sense of [[../projects/thorchain]] or [[../projects/serai]]. It is a **privacy-oriented instant-swap aggregator** — closer in architecture to ChangeNOW, SideShift AI, FixedFloat, or Stealthex than to Thorchain — that fronts an interface across multiple liquidity sources (DEX aggregators, bridges, and "in-house liquidity") and offers an optional "Private Swap" mode that routes through Monero to break on-chain linkability.

This is an important categorical contrast: Baltex does not run a chain, does not hold a validator set, does not bond capital, and does not custody pools on connected chains. It runs a routing/quoting service on top of other liquidity venues, with a "short custody window" during cross-chain or privacy swaps (acknowledged explicitly in third-party coverage).

## Key facts extracted

| Topic | Value | Source |
|-------|-------|--------|
| Trading name | Baltex | https://baltex.io/ |
| Operating entity | GGWP Limited | Privacy Policy (https://baltex.io/legal/privacy-policy) |
| Stated headquarters | Jacó, Puntarenas, Costa Rica | Benzinga press release 2026-03-02; Slashdot listing |
| Governing law | Laws of Costa Rica, Costa Rican courts | Terms of Service (https://baltex.io/legal/terms-of-services) |
| Founded | 2025 | Slashdot listing; TechBehemoths |
| Private Swaps launch | 2025-11-24 | DLNews (https://www.dlnews.com/external/baltex-launches-fully-cross-chain-private-swaps/) |
| Founder | Evgeniia Iarmenko | Ventureburn (https://ventureburn.com/baltex-unveils-fully-cross-chain-private-swap-technology/) |
| CMO | Andrei K. / "Andri Ko" | Ventureburn; Benzinga press release |
| Supported tokens (claimed) | 10,000+ tokens | Homepage, multiple blog posts |
| Supported networks (claimed) | 200+ networks | Homepage; conflicts with private-swaps page claiming "13 networks" |
| Major chains named | Ethereum, Solana, BTC, BNB, Polygon, Base, Arbitrum, Optimism, Avalanche, Tron, TON | Homepage |
| Rate options | Fixed rate ("stability") and Floating rate ("speed") | https://baltex.io/support/how-it-works |
| Private Swap fee | starting at 0.4% | DLNews 2025-11-24 |
| Standard cross-chain swap fee (claimed) | <0.1% | Multiple blog posts |
| Private swap time | 10-20 min typical (5-45 min for USDT->XMR with auto-splitting on large volumes) | DLNews; USDT->XMR blog |
| Custody model | Non-custodial wallet-to-wallet for DEX swaps; "transit addresses" with "short custody window" for cross-chain and privacy swaps | Risk Disclosure; hackers.tools |
| KYC | None by default; triggered when AML risk scoring, sanctions screening, or PEP flags trip | FAQ; AML page; Risk Disclosure |
| Prohibited jurisdictions | DPRK, Iran, Syria, Russia "and others designated from time to time" | Risk Disclosure |
| Trustpilot rating | 4.3-4.5 stars on 15+ reviews (sources disagree slightly; verified business) | Trustpilot (HTTP 403, headline only); Benzinga press release |
| Hybrid liquidity (key disclosure) | "scouts top DEX quotes, then blends them with its own in-house liquidity" | https://baltex.io/blog/ecosystem/best-tools-for-cross-chain-swaps |
| Specific upstream providers | Not disclosed publicly. Self-described as aggregating "DEX aggregators ... bridges ... centralized exchange order books". Likely overlap with Thorchain/Maya/Chainflip/Li.Fi based on token coverage but unverified. | hackers.tools; FAQ |
| Audits | Self-claimed "security audits" but no specific firm named; no public audit report linked | Benzinga press release; FAQ has no audit info |
| Open-source code | None found. No GitHub repo for Baltex; not in search results | Web search |

## Architecture model

User flow (best reconstruction from all sources):

1. User picks source asset, destination asset, destination wallet on app.baltex.io.
2. Two rate types: fixed (locks quote, higher fee) or floating (executes at fill rate).
3. Baltex routing engine quotes the path. For same-chain DEX swaps: routes user wallet directly through third-party smart contracts (DEX aggregators). For cross-chain or privacy swaps: Baltex receives funds at a transit address.
4. Baltex executes the route through some combination of DEX aggregators, cross-chain bridges (unnamed), CEX order books, and Baltex's own market-making inventory.
5. For Private Swaps, the path inserts a Monero hop: source -> intermediate -> XMR -> intermediate -> destination, with stealth addresses + ring signatures + RingCT breaking the on-chain link.
6. Destination asset is sent to user wallet from Baltex's withdrawing address. Typical completion 10-45 minutes depending on route and Monero confirmations.

Protocol perspective:

- No native chain. No validator set. No bonded stake. No smart contracts owned by Baltex on the chains served (verified by absence of GitHub repo and any contract address disclosure).
- The "DEX Layer Terms" describe a "Non-custodial, on-chain swap interface routing via third-party smart contracts" — Baltex is a router UI, not a contract operator on chain.
- The "Private Exchange Terms" describe a separate "Private Swaps" product that necessarily includes a custodial leg (since Monero cannot atomically interlock with EVM/UTXO chains without HTLC, which Baltex does not implement).
- AML/sanctions screening happens before and during the custody window: inbound funds are screened against "sanctions, darknet markets, mixers, fraud rings, stolen funds, and high-risk clusters". Risky deposits can be frozen pending KYC/EDD; refundable minus network fees on non-completion.

## Trust model

Baltex is a **federated single-operator custodian** for any non-trivial cross-chain swap. Trust assumptions:

- **Operator solvency**: GGWP Limited (Costa Rica) holds user funds during the cross-chain hop. No proof of reserves; no bond; no third-party slashing. If Baltex absconds, users have only Costa Rican civil recourse.
- **Operator honesty during the privacy hop**: the user must trust Baltex not to log the linkage between the inbound deposit address and the outbound destination address. Monero protects the on-chain trail from external observers (chain analysis cannot link), but Baltex itself is by construction the *one* entity that does see the linkage internally because it controls both legs.
- **Sanctions discretion**: the operator may freeze any inbound transaction at AML discretion. The user has no protocol-enforced settlement guarantee.
- **No cryptographic accountability**: unlike Thorchain's TSS signing transcript or Serai's published In Instructions, Baltex's matching, routing, and inventory decisions are entirely off-chain and opaque.

This is the **single-operator instant-swap** trust model, which is the dominant model for non-KYC swap exchanges (SideShift, ChangeNOW, FixedFloat, Stealthex, Trocador, eXch.cx), differing from [[../patterns/middle-chain-swap-settlement]] (Thorchain/Serai) and [[../patterns/attestation-bridge]] (Wormhole). It is closest to a centralised exchange that happens to have no account system.

## Privacy properties

- Baltex's distinctive claim is **privacy as a product feature**, not a protocol property. Privacy is delivered by inserting a Monero hop, leveraging Monero's stealth addresses, ring signatures, and RingCT to make the deposit-to-payout linkage invisible to external chain analysis.
- This breaks **external observer linkability**: an outside party watching Bitcoin and Ethereum cannot connect a Bitcoin inflow to an Ethereum outflow if they routed through XMR.
- It does **not** break **operator linkability**: Baltex itself necessarily knows both endpoints because it is the entity making the conversion. Privacy depends on the operator's data retention policies (5-10 years per their Privacy Policy for KYC-flagged transactions; less for clean swaps but no encrypted-at-source guarantee).
- It does **not** provide **shielded execution**: amounts, intent, and timing are exposed to the operator.
- For comparison: this is materially weaker than the LEZ ideal of zk-shielded execution where even the middle chain operator cannot link, but materially stronger than Thorchain/Serai where the entire swap is publicly on-chain. [[../patterns/middle-chain-swap-settlement]] vs [[../patterns/atomic-swaps-vs-middle-chain]] discussion applies.
- Note that Baltex's own blog at https://baltex.io/blog/ecosystem/thorchain-private-swaps-anonymous-btc-2026-guide (cited by [[../projects/thorchain]]) explicitly states Thorchain "is decentralised but not private," which is the gap Baltex positions itself to fill at the cost of trusting a centralised operator.

## Adoption metrics

- **No on-chain TVL** (no protocol-owned vault, no pool contracts).
- **No published volume figures** (the operator does not publish dashboards; not indexed by DefiLlama).
- **Trustpilot rating ~4.3-4.5 stars on 15+ reviews** as of May 2026 (verified business, but small sample).
- **Token/chain claims**: marketing material varies between "1,000+ tokens / 13-25 networks" (older blogs and private-swaps page) and "10,000+ tokens / 200+ networks" (current homepage); the latter is almost certainly the aggregated count across all upstream providers, not a Baltex-native integration count.
- **Founded 2025, ~10 employees** per TechBehemoths.
- **Press / coverage**: DLNews 2025-11-24, Ventureburn 2025-11, Benzinga press release 2026-03-02. No mainstream financial press coverage.

## Incidents / audits

- **No reported incidents** in 2025 or 2026 found in search. Baltex did not appear in any "crypto hack" coverage in the queried period.
- **Audits**: self-claimed in press releases ("Infrastructure has undergone security audits") but no firm named, no audit report linked, no scope or date provided. Flag as **unverified self-reported**.
- **AML/sanctions screening framework**: documented in detail (https://baltex.io/aml) — this is the only externally verifiable security-related practice.
- **No open-source code**: no GitHub, no public contracts. All "security" claims rest on the operator's reputation.

## Notable comparison axes vs [[../projects/thorchain]], [[../projects/serai]], [[../projects/wormhole]]

| Axis | Baltex | Thorchain | Serai | Wormhole |
|------|--------|-----------|-------|----------|
| Native chain | None | Cosmos SDK L1 | Substrate L1 | None |
| Custody | Single operator (GGWP Limited) for cross-chain leg | TSS Asgard vaults (validator set) | FROST multisig (validator set) | Per-chain bridge contracts |
| Liquidity | Aggregated DEX/CEX + in-house book | Protocol-owned CLPs | Protocol-owned xy=k AMM | None (solvers/external DEXes) |
| Validator economics | None (single corporate entity) | RUNE-bonded, 103-120 nodes | Stake-bonded, up to 600 | 19 named firms, reputational only |
| Privacy | Optional Monero hop (operator-visible) | None (memos public) | None planned (public Substrate) | None (VAAs public) |
| Settlement guarantee | Operator discretion (AML freeze possible) | Protocol-enforced | Protocol-enforced | Protocol-enforced after VAA |
| Open source | No | Yes | Yes | Yes |
| Audits | Self-claimed, no firm named | Halborn, Trail of Bits, others | Cypher Stack, Trail of Bits, HashCloak, SRLabs | 29 audits across many firms |
| KYC | Triggered on AML risk | None | None | None |

## Pattern note recommendation

**Recommend creating ONE new pattern note**:

- **`patterns/instant-swap-aggregator.md`** (or `patterns/non-kyc-swap-aggregator.md`) — characterises the single-operator, non-KYC, instant-swap exchange model (Baltex, ChangeNOW, SideShift, FixedFloat, Stealthex, Trocador, eXch.cx). Properties: federated single-operator custodian, AML/sanctions discretion, fixed-rate vs floating-rate quoting, transit-address model, aggregated upstream liquidity (DEX + CEX + bridges + in-house book), optional Monero privacy hop, no on-chain proof of reserves, no slashing. The pattern should explicitly contrast with [[../patterns/middle-chain-swap-settlement]] and [[../patterns/atomic-swaps-vs-middle-chain]] and note that this is the dominant *deployed* cross-chain swap pattern by user count, even though it doesn't appear on academic taxonomies. Rationale: Baltex doesn't fit any existing pattern in the repo; the closest is [[../patterns/lock-mint-bridging]] but that's for wrapped-token bridges, not swap aggregators.

Optionally a second pattern, **`patterns/monero-privacy-hop.md`**, could be created to describe the design of using Monero as an intermediate asset to break on-chain linkability (used by Baltex Private Swaps, Trocador, some SideShift routes, the "anonymous swap" sections of darknet OPSEC guides). This is a sub-pattern of the instant-swap aggregator pattern but distinctive enough that it might warrant its own note — flag for main thread decision.

## Sources (with archive paths)

All sources accessed 2026-05-20 unless noted.

Primary (Baltex official):
- https://baltex.io/ — homepage — `sources/2026-05-20-baltex-io-home.html`
- https://baltex.io/private-swaps — `sources/2026-05-20-baltex-io-private-swaps.html`
- https://baltex.io/support/faq — `sources/2026-05-20-baltex-io-support-faq.html`
- https://baltex.io/support/how-it-works — `sources/2026-05-20-baltex-io-support-how-it-works.html`
- https://baltex.io/aml — `sources/2026-05-20-baltex-io-aml.html`
- https://baltex.io/legal/risk-disclosure — `sources/2026-05-20-baltex-io-legal-risk-disclosure.html`
- https://baltex.io/legal/terms-of-services — `sources/2026-05-20-baltex-io-legal-terms-of-services.html`
- https://baltex.io/legal/privacy-policy — `sources/2026-05-20-baltex-io-legal-privacy-policy.html`

Baltex blog (own marketing, treat as self-reported):
- https://baltex.io/blog/ecosystem/cross-chain-swaps-swap-crypto-between-blockchains-instantly — `sources/2026-05-20-baltex-io-blog-cross-chain-swaps.html`
- https://baltex.io/blog/ecosystem/no-kyc-crypto-swaps-usdt-to-xmr-privately — `sources/2026-05-20-baltex-io-blog-usdt-to-xmr.html`
- https://baltex.io/blog/ecosystem/best-tools-for-cross-chain-swaps — `sources/2026-05-20-baltex-io-blog-best-tools.html` (contains the "in-house liquidity" admission)
- https://baltex.io/blog/ecosystem/best-no-kyc-monero-xmr-swappers-2026 — `sources/2026-05-20-baltex-io-blog-best-monero-swappers-2026.html`
- https://baltex.io/blog/ecosystem/top-swapper-platforms-ranked-best-places-trade-crypto-fast — `sources/2026-05-20-baltex-io-blog-top-swapper-platforms.html`

Third-party (independent or semi-independent):
- https://www.dlnews.com/external/baltex-launches-fully-cross-chain-private-swaps/ — `sources/2026-05-20-dlnews-com-baltex-launches-private-swaps.html` (DLNews, 2025-11-24; this is an "external" syndicated piece so partially self-reported)
- https://ventureburn.com/baltex-unveils-fully-cross-chain-private-swap-technology/ — `sources/2026-05-20-ventureburn-com-baltex-private-swap-tech.html` (Ventureburn, likely sponsored placement)
- https://www.benzinga.com/pressreleases/26/03/50975393/baltex-announces-xmr-to-trx-swaps-now-completing-in-as-little-as-20-minutes — `sources/2026-05-20-benzinga-com-baltex-xmr-trx.html` (Benzinga press release, 2026-03-02 — self-reported but quotes CMO and gives location)
- https://hackers.tools/articles/baltex-privacy-first-cross-chain-swap-hackers-actually-use — `sources/2026-05-20-hackers-tools-baltex-privacy-first.html` (most useful third-party piece; contains the "short custody window" admission)
- https://techbehemoths.com/company/baltex — `sources/2026-05-20-techbehemoths-com-baltex.html` (directory listing — founded 2025, 10 employees)

Cloudflare-challenged (could not archive body; cited as headline-only):
- https://alternativeto.net/software/baltex/about/ — body was Cloudflare challenge, listing-summary retrieved via WebFetch
- https://slashdot.org/software/p/Baltex/ — body was Cloudflare challenge, listing-summary retrieved via WebFetch (Jacó Costa Rica HQ, founded 2025)
- https://www.trustpilot.com/review/baltex.io — HTTP 403 on both curl and WebFetch; only star-rating snippet from Google search index available
