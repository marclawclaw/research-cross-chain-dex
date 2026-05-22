---
tags: [project, atomic-swaps, monero, bitcoin, btc-xmr, community-fork, active]
ecosystem: Bitcoin, Monero (cross-chain primitive, no own chain)
category: BTC-XMR adaptor-signature atomic swap wallet
website: https://eigenwallet.org/
docs: https://docs.eigenwallet.org/
github: https://github.com/eigenwallet/core
launched: As UnstoppableSwap GUI, December 2021 (Monero CCS milestone payouts began 2021-12); rebranded to eigenwallet 2025-07-18 (v3.0.0-beta); active maintenance through 2026-05 (v4.6.4 released 2026-05-21)
---

# eigenwallet (formerly UnstoppableSwap)

**eigenwallet** is the active community fork of [[projects/comit]]'s `xmr-btc-swap`. It is a desktop application that lets a user (the "taker") atomically swap Bitcoin for Monero with a peer-to-peer market maker (the "maker") running the `asb` (Automated Swap Backend) daemon, using adaptor-signature cryptography rather than HTLCs. The original COMIT maintainers (`@comit-network`) marked their repository unmaintained and redirected to eigenwallet ([github.com/comit-network/xmr-btc-swap](https://github.com/comit-network/xmr-btc-swap) :: accessed 2026-05-22). The project rebranded from "UnstoppableSwap" to "eigenwallet" on 2025-07-18 with v3.0.0-beta, reflecting an expanded scope from a swap tool to a full non-custodial Monero wallet with atomic swaps as a built-in feature.

## Swap direction is one-way: BTC → XMR only

This is a structural property of the deployed protocol, not an implementation gap. **Every swap in eigenwallet is the taker giving Bitcoin and receiving Monero, with the maker giving Monero and receiving Bitcoin.** There is no XMR→BTC swap option in the GUI, no `sell-xmr` CLI command, and no `asb` mode that buys BTC for XMR. Sources:

- **User-facing docs** ([docs.eigenwallet.org/getting_started/first_swap](https://docs.eigenwallet.org/getting_started/first_swap) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-github-eigenwallet-core-docs-first-swap.mdx)): *"To complete an atomic swap, you'll need to have [..] some Bitcoin funds which will be swapped for Monero."*
- **Maker-side docs** ([docs.eigenwallet.org/becoming_a_maker/overview](https://docs.eigenwallet.org/becoming_a_maker/overview) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-github-eigenwallet-core-docs-maker-overview.mdx)): *"The `asb` accepts Bitcoin and sells Monero, for a fee."*
- **CLI module name**: `swap/src/cli/command/list_sellers.rs` — the discovery API returns "sellers" (of XMR), not generic peers; upstream `comit-network/xmr-btc-swap` README echoes this: *"swaps are only offered in one direction with the `swap` CLI on the buying side (send BTC, receive XMR)."* ([github.com/comit-network/xmr-btc-swap](https://raw.githubusercontent.com/comit-network/xmr-btc-swap/master/README.md) :: accessed 2026-05-22).

**Why this is a hard limitation, not a design choice**: the BTC→XMR direction works because Bitcoin has script (timelock + 2-of-2 multisig + adaptor-signature primitive ECDSA-one-time-VES) and Monero has none. To run the swap XMR→BTC, the BTC seller would have to move first; Hoenisch and del Pino 2021 §4 explicitly analyses this and calls it the **"draining attack"**: a malicious taker would force the BTC seller to lock BTC, then bail at zero cost (the BTC seller pays the refund transaction fee), draining the BTC seller's working capital over many trials. The mathematical fix requires **adaptor signatures over Monero's CLSAG ring-signature scheme**, which Hoenisch and del Pino describe as "work-in-progress" in 2021; eigenwallet's `protocol/` repo (created 2025-11-04) re-hosts the original COMIT papers including the §4 stub on the reverse direction but does not propose a CLSAG-adaptor instantiation. See [[projects/atomic-swap-protocol-details]] for the full sourcing of the locks-first/draining-attack analysis.

**Consequence for the maker economy**: every active eigenwallet maker is, structurally, **an XMR seller / BTC buyer**. A user who has XMR and wants BTC must route through a centralised exchange or a different atomic-swap design (e.g. Farcaster's Lightning Network BTC support adds a BTC-side throughput advantage, but the direction is the same). [[projects/serai]]'s middle-chain AMM is the closest "go either way at AMM pricing" alternative within the privacy-aware design space.

## Project status (2026-05-22)

| Field | Value |
|-------|-------|
| Repo | [eigenwallet/core](https://github.com/eigenwallet/core) (fork of comit-network/xmr-btc-swap) |
| Latest release | 4.6.4, 2026-05-21 (one day before this note) |
| Stars / forks | 268 / 74 |
| Total releases | 117 |
| Open issues | 156 |
| Commits | 3,749 |
| Primary language | Rust 77%, TypeScript 20% |
| Licence | GPL-3.0 |
| Contributors | 44 distinct (including `binarybaron` 699 commits, `thomaseizinger` 313, `da-kami` 300, `delta1` 250, `rishflab` 199, `Einliterflasche` 95) |
| Legacy repo | [eigenwallet/unstoppableswap-gui](https://github.com/eigenwallet/unstoppableswap-gui) (archived 2024-11-15) |

Source: [api.github.com/repos/eigenwallet/core](https://api.github.com/repos/eigenwallet/core) :: accessed 2026-05-22; [api.github.com/repos/eigenwallet/core/contributors](https://api.github.com/repos/eigenwallet/core/contributors) :: accessed 2026-05-22.

## Adoption / usage metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| Mainnet swaps via UnstoppableSwap GUI in 2023 | "more than 3,000" | 2024-07-09 | [CCS proposal "From Prototype to Marketplace"](https://ccs.getmonero.org/proposals/mature-atomic-swaps-ecosystem.html) — quote: *"3,000 swaps were completed using our GUI"* |
| Swaps performed by binarybaron's own ASB instance | "over a thousand" | 2024-07-09 | same proposal — *"our [..] swap provider [..] performed over a thousand swaps with users. This has been put on pause for now as more swap providers have emerged"* |
| BTC↔XMR atomic-swap volume growth 2025 | "+180%" (Eigenwallet data, attribution by third party) | 2026 (article) | [xgram.io: Swap Crypto Between Unlinked Wallets](https://xgram.io/blog/swap-crypto-between-unlinked-wallets) — *"Atomic swap volume between BTC ↔ XMR pairs increased 180% (Eigenwallet data)"* — note this is a third-party characterisation; no Eigenwallet-published dashboard located. |
| Cumulative downloads, eigenwallet/core (Apr 2022 onwards) | 55,769 across 114 numbered releases | 2026-05-22 | aggregated from [api.github.com/repos/eigenwallet/core/releases](https://api.github.com/repos/eigenwallet/core/releases) :: accessed 2026-05-22 |
| Cumulative downloads, legacy eigenwallet/unstoppableswap-gui | 33,661 | 2026-05-22 (repo archived 2024-11) | [api.github.com/repos/eigenwallet/unstoppableswap-gui/releases](https://api.github.com/repos/eigenwallet/unstoppableswap-gui/releases) :: accessed 2026-05-22 |
| Top download release (current monorepo) | 1.0.0-rc.13: 5,156 downloads | release dated 2025-05 era | same releases endpoint |
| Top download release (legacy GUI repo) | v0.5.2: 8,000 downloads | 2023-09-28 | same releases endpoint |
| Latest release 4.6.4 downloads (1 day old) | 52 | 2026-05-22 | same releases endpoint |
| Most-recent stable release 4.6.1 downloads | 614 | 2026-05-15 onwards (7 days) | same releases endpoint |
| Public market makers visible on discovery API | 2 mainnet makers | 2026-05-22 | [api.eigenwallet.org/api/list](https://api.eigenwallet.org/api/list) :: accessed 2026-05-22 (returns 2 mainnet `asb` instances on Tor `.onion3` multiaddrs, versions 3.6.4 and 3.6.7, ages 132 and 167 days) |
| Privacy rating (third party) | 10/10 overall, 100 privacy, 92 trust, "Level 0" KYC | 2024-11 verification | [kycnot.me/service/eigenwallet](https://kycnot.me/service/eigenwallet) :: accessed 2026-05-22 |

**Is it used? Short answer:** yes, in a community-scale way. Two independent corroborated signals: (a) the developers reported >3,000 mainnet swaps via the GUI in 2023 alone in a Monero CCS funding proposal that was fully funded in July 2024 ([CCS proposal](https://ccs.getmonero.org/proposals/mature-atomic-swaps-ecosystem.html) :: accessed 2026-05-22); (b) GitHub releases show ~89,400 cumulative binary downloads across the eigenwallet/core (55,769) and legacy unstoppableswap-gui (33,661) repos. Recent release cadence is rapid: 14 releases in the 47 days from 2026-04-05 to 2026-05-21, with hundreds-to-low-thousands of downloads per stable release. **However**, the network is small at any given moment: only 2 mainnet makers were registered at the public discovery endpoint on 2026-05-22. The third-party "+180% BTC↔XMR atomic swap volume growth in 2025" attribution to "Eigenwallet data" ([xgram.io](https://xgram.io/blog/swap-crypto-between-unlinked-wallets) :: accessed 2026-05-22) has no first-party dashboard to verify it; the percentage should be treated as suggestive of growth rather than as a sourced absolute volume.

## Fork lineage and breaking changes

The project's name and home have moved twice. The chain of repos:

1. **comit-network/xmr-btc-swap** (2020-08 onwards). Original COMIT BTC-XMR adaptor-signature implementation. Reference implementation of the protocol described in [Hoenisch and del Pino, 2021, IACR 2021/441](https://eprint.iacr.org/2020/1126.pdf) and the August 2021 launch on getmonero.org. Last release v1.0.0-rc.1 on 2024-11-15. Marked unmaintained; README now reads ([github.com/comit-network/xmr-btc-swap README](https://raw.githubusercontent.com/comit-network/xmr-btc-swap/master/README.md) :: accessed 2026-05-22):

   > **This repository is unmaintained**. The original developers (@comit-network) have moved on to other projects. Community volunteers are continuing development at eigenwallet/core, which includes a graphical user interface. Please note that the fork has introduced network-level breaking changes, making it incompatible with peers running this repository - you will not be able to initiate swaps with them.

2. **UnstoppableSwap/core** (forked 2022-04-13) — the community fork run by `binarybaron` and `einliterflasche`, two Berlin-based computer-science students who had been Monero CCS-funded since 2021 to build a GUI on top of `xmr-btc-swap`. Their CCS funding chain:
   - **2021-10 proposal**: 52 XMR for the initial GUI prototype, including Tor + Rendezvous integration and 6 months of infrastructure maintenance ([ccs.getmonero.org/proposals/binarybaron-unstoppableswap.html](https://ccs.getmonero.org/proposals/binarybaron-unstoppableswap.html) :: accessed 2026-05-22). Fully paid out December 2021 to May 2022 across five milestones.
   - **2022-05 proposal**: 232 XMR for continued development across 4 monthly milestones ([ccs.getmonero.org/proposals/unstoppableswap-gui-2.html](https://ccs.getmonero.org/proposals/unstoppableswap-gui-2.html) :: accessed 2026-05-22). Paid out across 2022-08 to 2023-01.
   - **2024-07 proposal**: 729 XMR, raised 729/729 from 62 contributors, paid out across 2024-10 to 2025-09 ([ccs.getmonero.org/proposals/mature-atomic-swaps-ecosystem.html](https://ccs.getmonero.org/proposals/mature-atomic-swaps-ecosystem.html) :: accessed 2026-05-22). This proposal funded the migration from Electron to Tauri, JSON-RPC server for `asb` controllers, mobile work, and stabilisation toward "a mature marketplace".

3. **eigenwallet/core** (renamed 2025-07 onwards). The same GitHub fork; the organisation and product were renamed. The rename was first surfaced in v2.5.6 release notes on 2025-07-18 ([eigenwallet/core release 2.5.6](https://github.com/eigenwallet/core/releases/tag/2.5.6) :: accessed 2026-05-22):

   > ASB: Docker image has moved to https://github.com/eigenwallet/core/pkgs/container/asb
   > ASB + GUI + CLI: We have renamed from UnstoppableSwap to eigenwallet (why?). We will slowly migrate the entire infrastructure to the new name.

   The rename rationale page reads ([eigenwallet.org/rename](https://eigenwallet.org/rename) :: accessed 2026-05-22): the project no longer wants to be "just a swap tool"; the goal is now "the best non-custodial cross-platform Monero wallet" with atomic swaps as a feature rather than the entire focus. The v3.0.0-beta release on 2025-07-18 introduced the wallet-first mode: the GUI can open Monero wallet files from monero-wallet-cli/-rpc/-gui or Feather, generate new wallets, recover from seed, change restore height, and use Bitcoin wallet + p2p identity directly integrated with the Monero wallet ([Monero Observer: rebrand 3.0.0-beta release](https://monero.observer/unstoppableswap-completes-eigenwallet-rebrand-3.0.0-beta-release/) :: accessed 2026-05-22).

### Network-level protocol break

The "breaking changes" mentioned in the COMIT README are explicit in eigenwallet/core's own release notes ([eigenwallet/core release 2.0.0, 2025-06-12](https://github.com/eigenwallet/core/releases/tag/2.0.0) :: accessed 2026-05-22):

> **BREAKING PROTOCOL CHANGE**: Takers/GUIs running >= 2.0.0 will not be able to initiate new swaps with makers/asbs running < 2.0.0. Please upgrade as soon as possible. Already started swaps from older versions are not be affected. Taker and Maker now collaboratively sign a `tx_refund_early` [..]

A second protocol-level change was v4.0.0 (2026-03-16), which reduced the cancel timelock from 12 to 4 hours, shortening the refund window from 36 hours to 28 hours, and added an optional "anti-spam deposit" for makers ([eigenwallet/core release 4.0.0](https://github.com/eigenwallet/core/releases/tag/4.0.0) :: accessed 2026-05-22).

This is significant: the fork is not just a UI re-skin of `xmr-btc-swap`. It has changed the on-the-wire protocol at least twice (the `tx_refund_early` co-signing change in v2.0.0 and the timelock-window reduction in v4.0.0) and is the only implementation that can interoperate with current makers.

## How it works

### User perspective (taker / "Bob", buying XMR with BTC)
1. Install eigenwallet desktop binary for Linux/macOS/Windows ([eigenwallet.org](https://eigenwallet.org/) :: accessed 2026-05-22; mobile listed as "coming soon").
2. Open the app. The bundled Tor client bootstraps; a Monero wallet is created or opened.
3. The GUI shows a list of makers learned from the discovery service ([api.eigenwallet.org/api/list](https://api.eigenwallet.org/api/list) :: accessed 2026-05-22) — each entry shows peer ID, version, price per XMR, min/max swap amount, age and "relevancy". Sorted by largest max amount (default), smallest min amount, or cheapest price ([release 4.4.0](https://github.com/eigenwallet/core/releases/tag/4.4.0) :: accessed 2026-05-22).
4. Pick a maker, lock BTC into the swap script. After BTC confirms, the maker locks XMR. The user then redeems XMR. If anything goes wrong, the swap refunds within ~4 hours (cancel timelock; v4.0.0 reduced this from 12 hours).

### System perspective (BTC→XMR adaptor-signature swap)
1. **Discovery**: makers register on community-operated libp2p Rendezvous Points (`/dns4/rendezvous.observer/tcp/8888/...`, plus eigen.center, discover.unstoppableswap.net, and others). A registry indexer (api.eigenwallet.org) caches the list and adds metadata: uptime, age, recent activity ([docs.eigenwallet.org/usage/market_maker_discovery](https://docs.eigenwallet.org/usage/market_maker_discovery) :: accessed 2026-05-22).
2. **Quote**: the taker GUI requests a quote from chosen makers. The maker (`asb`) computes its price from a fee multiplier (`ask_spread`, e.g. 0.02 for 2%) over an average of Kraken, Bitfinex, KuCoin, and optionally Exolix tickers ([release 3.5.0, 2025-12-04](https://github.com/eigenwallet/core/releases/tag/3.5.0) :: accessed 2026-05-22; [release 4.4.1](https://github.com/eigenwallet/core/releases/tag/4.4.1) :: accessed 2026-05-22).
3. **Swap**: BTC-XMR adaptor-signature protocol (Hoenisch and del Pino, 2021). Joint Schnorr/Ed25519 keys, BTC lock, XMR lock, BTC redeem reveals an Ed25519 scalar that lets the taker claim XMR.
4. **Resilience extras shipped in the eigenwallet era**:
   - Monero RPC pool with multi-node failover, TCP/Tor caching ([release 3.0.0-beta.6](https://github.com/eigenwallet/core/releases/tag/3.0.0-beta.6) :: accessed 2026-05-22).
   - "Wormholes": maker-issued onion services exclusively for takers who have committed funds, surviving DoS on the maker's public address (default-enabled, [release 4.3.0](https://github.com/eigenwallet/core/releases/tag/4.3.0) :: accessed 2026-05-22).
   - Background view-only Monero wallet scanning so a taker can detect XMR lock even if the maker-taker p2p connection drops ([release 3.6.0](https://github.com/eigenwallet/core/releases/tag/3.6.0) :: accessed 2026-05-22).
   - Concurrency-limited, spaced-out Tor dials so the embedded Tor client is not overwhelmed by bursts ([release 4.6.3](https://github.com/eigenwallet/core/releases/tag/4.6.3) :: accessed 2026-05-22).

## Key behaviours
- [[patterns/atomic-swaps-vs-middle-chain]] — the project is the canonical live example of the atomic-swap branch of the family tree, as the contrast point to [[projects/serai]] and [[projects/thorchain]].
- [[patterns/monero-bridge]] — eigenwallet is the only Monero-related "bridge" that does not hold any user funds at any point; it is purely a peer-to-peer adaptor-signature protocol.

## Architecture decisions
- **Tauri over Electron.** Migrated as part of the 2024-07 CCS proposal to reduce binary size and resource use ([CCS 2024 proposal](https://ccs.getmonero.org/proposals/mature-atomic-swaps-ecosystem.html) :: accessed 2026-05-22).
- **Native C++ Monero bindings rather than monero-wallet-rpc.** Reduced operational complexity; allows the GUI to behave as a Monero wallet without spawning a subprocess ([eigenwallet.org/rename](https://eigenwallet.org/rename) :: accessed 2026-05-22).
- **Bundled Tor by default.** All inbound and outbound traffic is anonymised; makers publish on `.onion` v3 multiaddrs.
- **Maker-set spreads, not protocol-set fees.** Each maker chooses an `ask_spread` over the centralised-exchange average. No protocol fee; no token; no governance; no validator set. Optional `developer_tip` (disabled by default) lets makers contribute back ([docs.eigenwallet.org/becoming_a_maker/overview](https://docs.eigenwallet.org/becoming_a_maker/overview) :: accessed 2026-05-22).
- **Community-operated discovery infrastructure**, not protocol-mandated. Rendezvous Points and the public registry indexer are volunteer-run. The default list of rendezvous points is hard-coded into the release ([release 3.0.0-beta.4](https://github.com/eigenwallet/core/releases/tag/3.0.0-beta.4) :: accessed 2026-05-22). A taker can manually add an "unknown" maker by multiaddress + peer ID.

## Differentiators

- **vs upstream [[projects/comit]]**: COMIT is unmaintained; eigenwallet has rewritten the maker daemon API (JSON-RPC controller, `get-swaps`, dynamic Bitcoin redeem address, runtime config changes), changed the on-the-wire protocol twice (v2.0.0 collaborative `tx_refund_early`, v4.0.0 timelock reduction), and bundled a full Monero wallet. eigenwallet is the only consumer of the adaptor-signature primitive with active commits in 2026.
- **vs [[projects/serai]]**: Serai is a Substrate L1 with a 600-validator threshold-signature custody set and BTC-XMR AMM pools ([projects/serai.md] cross-reference); eigenwallet has no chain, no validator set, no AMM, no liquidity pool. Two structurally different answers to the same BTC↔XMR routing question; both are still pre-mainstream.
- **vs [[projects/thorchain]]**: Thorchain settles on a middle chain with TSS vaults and CLP pricing; eigenwallet has no middle chain. The price is set per-maker from off-chain ticker data, not by an `xy=k` invariant.

## Limitations and criticisms

- **Small live maker set.** The public registry returned 2 mainnet makers on 2026-05-22, both on Tor onion addresses, running versions 3.6.4 and 3.6.7 (i.e. ~4 to 5 months behind 4.6.4). The Rendezvous network is permissionless so private/known makers may exist off-registry, but a casual user opening the GUI without a specific peer ID is matched against this short list ([api.eigenwallet.org/api/list](https://api.eigenwallet.org/api/list) :: accessed 2026-05-22).
- **User-reported execution variability.** Third-party review records swap completion times from "25 minutes to 11+ hours", maker rates varying 1.5%–20% above market, and "high failure rates for some users; inconsistent success" ([kycnot.me/service/eigenwallet](https://kycnot.me/service/eigenwallet) :: accessed 2026-05-22). Same source records improvement in recent versions ("Many swaps now complete in around 30-35 minutes [..] 1–2 BTC swaps, and even larger ones, are consistently possible").
- **No first-party usage dashboard.** The "+180% BTC↔XMR volume in 2025" figure ([xgram.io](https://xgram.io/blog/swap-crypto-between-unlinked-wallets) :: accessed 2026-05-22) is attributed to "Eigenwallet data" but no public dashboard or signed data export is published. Treat as third-party characterisation rather than a sourced absolute number.
- **Free-option problem inherent to atomic swaps.** As with [[projects/comit]], a non-cooperative counterparty can grief by abandoning a swap mid-flow; the only cost to them is gas + time, not bond slashing (see [[patterns/atomic-swaps-vs-middle-chain]] for the comparison with [[projects/serai]]'s validator bonds). The v4.0.0 "anti-spam deposit" is the first protocol-level griefing mitigation ([release 4.0.0](https://github.com/eigenwallet/core/releases/tag/4.0.0) :: accessed 2026-05-22): a maker can withhold part of a refund for up to 30 minutes, then release it with "mercy". This is a partial mitigation, not a structural fix.
- **BTC-XMR-only AND one-way (BTC→XMR).** Despite the "wallet for the future" framing, the swap engine supports only Bitcoin and Monero, and only in the direction BTC → XMR. A user holding XMR who wants BTC cannot swap on eigenwallet at all. See the "Swap direction is one-way" section above for the draining-attack reason this is a hard structural limit, not an implementation gap.
- **Mobile not yet shipped.** Mobile is listed as "coming soon" on the homepage as of 2026-05-22, despite being a stated objective of the 2024-07 CCS proposal that completed in 2025-09.
- **Two-developer dependency.** binarybaron (699 commits) and einliterflasche (95 commits, plus 40 bot commits as `unstoppableswap-botty`) account for the bulk of post-fork work. No formal governance or multi-org maintainer structure has been announced. The donation address is a single Monero address signed by `binarybaron` ([github.com/eigenwallet/core README](https://raw.githubusercontent.com/eigenwallet/core/master/README.md) :: accessed 2026-05-22).

## Implication for LEZ positioning

For the cross-chain DEX RFP work, eigenwallet is the live data point for "does the atomic-swap branch still get used in 2026, and how much?". Answer:

- **Yes**, in a measurable but not scale-competitive way: 3,000+ swaps via the GUI in 2023 alone (developer-reported in a successful CCS), 89k+ binary downloads cumulative, active 2026 release cadence (14 releases in 7 weeks pre-2026-05-22).
- **Small concurrent network**: 2 visible mainnet makers on the public registry on 2026-05-22.
- **Active development**: the project is the most active atomic-swap implementation in the BTC-XMR space; it has changed the on-the-wire protocol at least twice since 2025-06 and added DoS-resistance features (wormholes, concurrency-limited Tor dials) that go materially beyond the original COMIT design.
- **Structural ceiling unchanged**: even with active maintenance, the atomic-swap model still has the free-option/UX/liquidity ceiling described in [[patterns/atomic-swaps-vs-middle-chain]]. eigenwallet is not closing the gap with middle-chain DEXes — it is making the atomic-swap option more usable for the privacy-maximalist sub-segment that is willing to pay the UX cost. The user base is a meaningfully different population from the volume-chasing Thorchain users.

This corroborates rather than contradicts the [[projects/comit]] negative result: even when the protocol is actively maintained, the design space deliberately does not introduce staking/reputation/protocol-fees, and the on-network maker count remains in the single digits. The LEZ positioning conclusion — that introducing a bonded counterparty layer is structurally incompatible with the atomic-swap branch and is the dividing line with middle-chain DEXes — holds.

## Sources

- [eigenwallet.org homepage](https://eigenwallet.org/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-eigenwallet-org-home.html)
- [eigenwallet.org/rename](https://eigenwallet.org/rename) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-eigenwallet-org-rename.html)
- [docs.eigenwallet.org home](https://docs.eigenwallet.org/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-docs-eigenwallet-org-home.html)
- [eigenwallet/core README](https://github.com/eigenwallet/core/blob/master/README.md) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-github-com-eigenwallet-core-readme.md)
- [eigenwallet/core GitHub API metadata](https://api.github.com/repos/eigenwallet/core) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-api-github-com-eigenwallet-core.json)
- [eigenwallet/core releases API](https://api.github.com/repos/eigenwallet/core/releases?per_page=100) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-api-github-com-eigenwallet-core-releases.json)
- [eigenwallet/core contributors API](https://api.github.com/repos/eigenwallet/core/contributors?per_page=100) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-api-github-com-eigenwallet-core-contributors.json)
- [eigenwallet maker discovery API](https://api.eigenwallet.org/api/list) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-api-eigenwallet-org-list.json)
- [comit-network/xmr-btc-swap README (unmaintained notice)](https://raw.githubusercontent.com/comit-network/xmr-btc-swap/master/README.md) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-github-comit-network-xmr-btc-swap-readme.md)
- [Monero CCS proposal: XMR-BTC Atomic Swaps Desktop GUI (2021)](https://ccs.getmonero.org/proposals/binarybaron-unstoppableswap.html) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-ccs-getmonero-org-binarybaron-unstoppableswap.html)
- [Monero CCS proposal: Continued development for 4 months (2022)](https://ccs.getmonero.org/proposals/unstoppableswap-gui-2.html) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-ccs-getmonero-org-unstoppableswap-gui-2.html)
- [Monero CCS proposal: From Prototype to Marketplace (2024)](https://ccs.getmonero.org/proposals/mature-atomic-swaps-ecosystem.html) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-ccs-getmonero-org-mature-atomic-swaps-ecosystem.html)
- [Monero Observer: UnstoppableSwap completes 'eigenwallet' rebrand with GUI 3.0.0-beta release](https://monero.observer/unstoppableswap-completes-eigenwallet-rebrand-3.0.0-beta-release/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-monero-observer-unstoppableswap-eigenwallet-rebrand.html)
- [monero.com news: binarybaron and einliterflasche submit CCS proposal to transform XMR-BTC atomic swaps ecosystem into mature marketplace](https://monero.com/post/binarybaron%20and%20einliterflasche%20submit%20CCS%20proposal%20to%20'transform'%20XMR-BTC%20atomic%20swaps%20ecosystem%20into%20'mature%20marketplace'/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-monero-com-binarybaron-einliterflasche-mature-marketplace.html) (contains the "more than 3,000 mainnet swaps in 2023" quote)
- [KYCnot.me: eigenwallet review (third-party privacy and trust score)](https://kycnot.me/service/eigenwallet) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-kycnot-me-eigenwallet.html)
- [xgram.io: Swap Crypto Between Unlinked Wallets (third-party volume figure)](https://xgram.io/blog/swap-crypto-between-unlinked-wallets) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-xgram-io-swap-crypto-between-unlinked-wallets.html)
- [eigenwallet/core release 2.0.0 (BREAKING PROTOCOL CHANGE)](https://github.com/eigenwallet/core/releases/tag/2.0.0) :: accessed 2026-05-22 (release-notes JSON archived in the releases dump above)
- [eigenwallet/core release 2.5.6 (rename announcement)](https://github.com/eigenwallet/core/releases/tag/2.5.6) :: accessed 2026-05-22 (release-notes JSON archived in the releases dump above)
- [eigenwallet/core release 3.0.0-beta (wallet-first mode)](https://github.com/eigenwallet/core/releases/tag/3.0.0-beta) :: accessed 2026-05-22 (release-notes JSON archived in the releases dump above)
- [eigenwallet/core release 4.0.0 (cancel-timelock reduction, anti-spam deposit)](https://github.com/eigenwallet/core/releases/tag/4.0.0) :: accessed 2026-05-22 (release-notes JSON archived in the releases dump above)
- [eigenwallet/core release 4.3.0 (wormholes)](https://github.com/eigenwallet/core/releases/tag/4.3.0) :: accessed 2026-05-22 (release-notes JSON archived in the releases dump above)
- [eigenwallet/core release 4.6.4 (latest as of this note)](https://github.com/eigenwallet/core/releases/tag/4.6.4) :: accessed 2026-05-22 (release-notes JSON archived in the releases dump above)
