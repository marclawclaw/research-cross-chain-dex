---
tags: [project, atomic-swaps, btc-xmr, bitcoin-wallet, mixer, defunct, doj-takedown]
ecosystem: Bitcoin (with XMR cross-chain swap integration)
category: Bitcoin privacy wallet with Whirlpool CoinJoin and BTC↔XMR atomic-swap GUI
website: samourai.io (seized by US authorities April 2024)
github: code.samourai.io (seized); community forks at github.com/noosphere888/samourai-swaps and github.com/Dezirae-Stark/Atomic-Swaps
launched: Samourai Wallet 2015; BTC↔XMR atomic swaps announced 2023-08-14, public beta 2024-01-16; service seized 2024-04-24
status: Original project legally defunct (founders sentenced to 5 and 4 years in prison Nov 2025); atomic-swap GUI carries on via community forks
---

# Samourai Wallet (and its BTC↔XMR atomic-swap GUI)

**Samourai Wallet** was a Bitcoin-only privacy wallet that, in late 2023, added a BTC↔XMR atomic-swap GUI as a privacy enhancement: a way for users to convert "tainted" Whirlpool change UTXOs into Monero rather than continuing to mix them on Bitcoin. The atomic-swap feature was a thin wrapper around [[projects/comit]]'s `xmr-btc-swap` reference implementation, with the Automated Swap Backend (ASB) bundled and Whirlpool CoinJoin auto-applied to redeemed BTC. Samourai's founders were arrested by US authorities in April 2024, the official codebase was seized, and the project is now legally defunct. The atomic-swap GUI lives on via two community forks (`noosphere888/samourai-swaps` and `Dezirae-Stark/Atomic-Swaps`) that target the same protocol.

## What Samourai's atomic-swap feature actually was

The atomic-swap GUI was **not** an original protocol. It used the COMIT [[projects/comit]] xmr-btc-swap codebase via a Java wrapper at `code.samourai.io/wallet/comit-swaps-java`. The user experience added:

1. **Samourai Wallet pairing-code integration** — the GUI could authenticate with a paired Samourai Wallet instance, eliminating the need to manually paste Bitcoin XPUB or psbts.
2. **Built-in ASB** — the application bundled the maker-side `asb` binary, so a user could run the maker role from the same desktop app.
3. **Auto-Whirlpool of redeemed BTC** — after an XMR-receiving swap completed and the ASB earned BTC, that BTC could be automatically routed into Whirlpool CoinJoin to remove the linkability tail.
4. **Tor by default** — all P2P traffic routed through Tor.

**Direction**: the same BTC-first limitation as the underlying COMIT protocol (see [[projects/xmr-first-atomic-swaps]]). The bidirectional framing in the press release ("BTC<->XMR") refers to a user being able to act either as **the BTC-locking taker** (sending BTC, receiving XMR) *or* as **the XMR-locking maker** via the integrated ASB (sending XMR, receiving BTC). At the protocol level, every swap was still BTC-locked-first — the bidirectional capability was about which role the user played, not about reversing the cryptographic protocol.

The motivation was the **"tainted change"** problem: Whirlpool CoinJoin mixes Bitcoin outputs into anonymity-set pools, but every CoinJoin round produces small "change" outputs that are not part of the pool and remain linkable to the input. Repeatedly cycling these change outputs through Whirlpool was diminishing returns. Atomic-swapping them to Monero converted them into a privacy-by-default chain, breaking the chain of linkability outright.

## Timeline

| Date | Event | Source |
|------|-------|--------|
| 2023-08-14 | BTC↔XMR atomic swap feature first announced by Samourai with Pokkst as collaborating developer | [news.bitcoin.com Aug 2023 article](https://news.bitcoin.com/revolutionizing-bitcoin-privacy-samourai-wallet-unveils-btc-to-xmr-atomic-swaps/) |
| 2024-01-16 | Public beta launched, version 0.0.13-beta, codebase at code.samourai.io/wallet/comit-swaps-java | [news.bitcoin.com Jan 2024 beta launch](../sources/2026-05-22-news-bitcoin-com-samourai-beta-launch.html) |
| 2024-04-24 | Samourai Wallet founders **Keonne Rodriguez** (CEO, age 35) and **William Lonergan Hill** (CTO, age 65) arrested by US authorities. Charges: conspiracy to commit money laundering, conspiracy to operate an unlicensed money transmitting business. Website (hosted in Iceland) seized. Google Play Store seizure warrant issued. Hill was arrested in Portugal and faced extradition. | [Coindesk 2024-04-24](https://www.coindesk.com/policy/2024/04/24/samourai-wallet-founders-arrested-and-charged-with-money-laundering) |
| 2024-04 onwards | Samourai Wallet service offline. The atomic-swap-specific code (`code.samourai.io/wallet/comit-swaps-java`) included in the seizure. | Same source |
| 2025-11-06 | Rodriguez sentenced to **5 years in prison** | [DOJ press release](https://www.justice.gov/usao-sdny/pr/founders-samourai-wallet-cryptocurrency-mixing-service-sentenced-five-and-four-years) |
| 2025-11-19 | Hill sentenced to **4 years in prison**. Both ordered to forfeit $237,832,360.55 (total of laundered proceeds; paid total of $6,367,139.69 in fees forfeiture, satisfying the order) | [Bloomberg 2025-11-19](https://www.bloomberg.com/news/articles/2025-11-19/crypto-mixer-co-founder-gets-four-years-in-money-laundering-case); same DOJ release |

## Why Samourai's swap feature mattered for the BTC↔XMR ecosystem

Even though the protocol underneath was just COMIT's, Samourai's adoption was a meaningful adoption signal. It is one of three pre-eigenwallet third-party clients to ship the protocol to a non-developer user base (the others being `farcaster-project/farcaster-node` and [[projects/eigenwallet]]'s predecessor UnstoppableSwap). Samourai's user base was several hundred thousand Bitcoin-privacy-aware users, far larger than the eigenwallet community at the time.

The Samourai integration also produced two side-effects that outlived the original project:

1. **The Whirlpool-then-atomic-swap conversion pattern is now part of how the privacy-Bitcoin community thinks about cross-chain hygiene**. The notion that a privacy-Bitcoin user's natural off-ramp is an atomic swap to XMR became mainstreamed.
2. **The "tainted change" use case became a recognised category** of atomic-swap demand. The eigenwallet team's 2024 CCS proposal "From Prototype to Marketplace" implicitly addresses this audience.

## Community forks (post-seizure)

Two GitHub repos carry on the Samourai atomic-swap codebase:

### `noosphere888/samourai-swaps`

Description: *"A GUI for COMIT XMR-BTC atomic swaps with modifications to further enhance anonymity"*. Built on the COMIT BTC-first protocol with built-in ASB and Samourai Whirlpool. Same Java/Rust architecture as the original Samourai release. No formal releases published through GitHub releases; only 7 commits on main. ([github.com/noosphere888/samourai-swaps](https://github.com/noosphere888/samourai-swaps))

The same user, `noosphere888`, maintains a constellation of post-seizure Samourai forks: `ExtLibJ` ("Samourai Artillery"), `whirlpool-client`, `whirlpool-server`, `Whirlpool`. Most are flagged as "Not fully up to date". This is a hobbyist preservation effort, not a maintained product.

### `Dezirae-Stark/Atomic-Swaps`

Description: *"A privacy-focused web interface for performing trustless atomic swaps between Bitcoin (BTC) and Monero (XMR), featuring seamless integration with Samourai Wallet pairing codes."* Built on Next.js 14 (TypeScript 96.9%) with libp2p, rather than the Java wrapper of the original Samourai release. Latest release **v1.1.0 on 2026-01-12**, 5 commits on main. ([github.com/Dezirae-Stark/Atomic-Swaps](https://github.com/Dezirae-Stark/Atomic-Swaps))

Direction: BTC-first only (matches the underlying COMIT protocol).

### Status assessment

Neither fork has the original Samourai Wallet's user base or the legal cover of being a non-mixer codebase. They run the same protocol as [[projects/eigenwallet]]; the value-add is the Whirlpool integration (which is itself legally fraught after the Samourai precedent — operating a Whirlpool-style mixing service was the specific conduct that led to the DOJ charges).

A user on a privacy threat model who would have used Samourai for BTC↔XMR swaps in 2024 is, in 2026, best served by:

1. **[[projects/eigenwallet]]** for the swap itself (mature, actively maintained, GUI).
2. A separate Bitcoin CoinJoin tool (Wasabi, JoinMarket) for input-side hygiene *if* they need it before the swap.

## Legal / chilling-effect context

The Samourai precedent is the **most prominent post-Tornado-Cash DOJ action against US-based privacy-tooling developers**. The DOJ's theory was that the Samourai founders' operation of Whirlpool (a Chaumian-CoinJoin-style coordinator) and Ricochet (an additional-hop service) constituted operating an unlicensed money transmitter, even though Samourai itself never custodied Bitcoin. The same legal theory could in principle be applied to:

- Any project that runs a market-making service for atomic swaps (e.g. eigenwallet `asb` operators, depending on whether the service is "for-profit and US-touching").
- Any team that maintains a mixer-style privacy tool in the US.

The Samourai atomic-swap feature itself was **not the conduct prosecuted** — the case was about Whirlpool/Ricochet. But the takedown removed the atomic-swap distribution channel with it, illustrating that bundled privacy products have correlated legal risk.

This is relevant to [[projects/lez-positioning]] and the broader privacy-aware cross-chain DEX design space: the **operator** of a privacy-enhancing service is the natural enforcement target, not the underlying cryptographic protocol. An atomic-swap protocol with **no operator** (peer-to-peer, no maker fees flowing to a central account, no domain to seize) is more resilient than one bundled with mixer infrastructure.

## Sources

- **Samourai BTC-XMR atomic swap launch, beta, 2024-01-16**: [news.bitcoin.com Jan 2024 article](https://news.bitcoin.com/samourai-wallet-unveils-privacy-enhancing-btc-to-xmr-atomic-swaps-in-beta-launch/) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-news-bitcoin-com-samourai-beta-launch.html). Quote on direction: *"trustlessly swap BTC<-> XMR, completely over Tor"*. Quote on protocol: *"the application is essentially a GUI for COMIT's XMR-BTC atomic swaps protocol with modifications to further enhance anonymity, with the Automated Swap Backend (ASB) built-in, as well as Samourai Wallet Whirlpool for automatic mixing of redeemed BTC."*
- **Samourai BTC-XMR atomic swap original announcement, 2023-08-14**: [news.bitcoin.com Aug 2023 announcement](https://news.bitcoin.com/revolutionizing-bitcoin-privacy-samourai-wallet-unveils-btc-to-xmr-atomic-swaps/) :: accessed 2026-05-22.
- **DOJ arrest announcement, 2024-04-24**: [Coindesk policy desk](https://www.coindesk.com/policy/2024/04/24/samourai-wallet-founders-arrested-and-charged-with-money-laundering) :: accessed 2026-05-22.
- **DOJ sentencing press release, Nov 2025**: [DOJ SDNY release](https://www.justice.gov/usao-sdny/pr/founders-samourai-wallet-cryptocurrency-mixing-service-sentenced-five-and-four-years) :: accessed 2026-05-22 (page is HTML, mostly server-side rendered text). Confirms Rodriguez 5 years, Hill 4 years, $237M forfeiture order.
- **Hill sentencing, 2025-11-19**: [Bloomberg](https://www.bloomberg.com/news/articles/2025-11-19/crypto-mixer-co-founder-gets-four-years-in-money-laundering-case) :: web-search-confirmed 2026-05-22.
- **noosphere888/samourai-swaps**: [github.com](https://github.com/noosphere888/samourai-swaps) :: accessed 2026-05-22.
- **Dezirae-Stark/Atomic-Swaps**: [github.com](https://github.com/Dezirae-Stark/Atomic-Swaps) :: accessed 2026-05-22.
- **Monero Talk: Samourai Wallet on Monero**: [monerotalk.live](https://www.monerotalk.live/samourai-wallet-on-monero) — interview context, not archived here.
- **pokkst/monero-wallet (Mysu Wallet)**: [github.com/pokkst](https://github.com/pokkst/monero-wallet/releases) — collaborator's wallet project, unaffected by the Samourai seizure since Pokkst was a third-party contractor, not a Samourai co-founder.

## Cross-references

- [[projects/comit]] — the underlying BTC↔XMR atomic-swap protocol that Samourai wrapped
- [[projects/eigenwallet]] — the current canonical implementation; what a former Samourai user should migrate to for the swap functionality
- [[projects/xmr-first-atomic-swaps]] — Samourai's protocol direction limitation
- [[projects/lez-positioning]] — operator-targeting enforcement risk relevant to the Logos / privacy-aware DEX framing
- [[patterns/atomic-swaps-vs-middle-chain]] — broader directional trade-off
