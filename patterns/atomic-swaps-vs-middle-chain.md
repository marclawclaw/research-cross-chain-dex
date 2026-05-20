---
tags: [pattern, atomic-swaps, design-rationale, history]
seen_in: [serai, thorchain]
---

# Atomic Swaps vs Middle-Chain DEX

Lead question: why did [[projects/serai]], [[projects/thorchain]], and (to a lesser extent) [[projects/wormhole]] choose middle-chain custody or attestation patterns rather than atomic swaps as the cross-chain swap primitive?

## What atomic swaps are

- **HTLC atomic swaps**: hash-timelocked contracts; both chains must support a common hash-preimage script. Pioneered with the Decred to Litecoin swap in September 2017 ([Decred blog: On-Chain Atomic Swaps](https://blog.decred.org/2017/09/20/On-Chain-Atomic-Swaps/) :: accessed 2026-05-19). Works between Bitcoin and EVM clones; does not work natively between Bitcoin and Monero because Monero has no scripting language for HTLCs.
- **Adaptor signature / scriptless script atomic swaps**: notably the BTC-XMR construction implemented by COMIT Network and the Farcaster Project from 2020 onward, using Schnorr/Ed25519 adaptor signatures so neither chain reveals the swap script on-chain ([getmonero.org: Bitcoin to Monero atomic swaps are now live, 2021-08-20](https://www.getmonero.org/2021/08/20/atomic-swaps.html) :: accessed 2026-05-19; [Atomic Swaps between Bitcoin and Monero, Hoenisch and del Pino, IACR 2021/441](https://www.researchgate.net/publication/348928221_Atomic_Swaps_between_Bitcoin_and_Monero) :: accessed 2026-05-19).
- **Trade-offs vs middle-chain custody**:
  - Atomic swaps need a willing counterparty per swap; there is no protocol-owned liquidity and no AMM-style pricing.
  - Atomic swaps require both parties online for the duration; refunds depend on timelocks measured in hours.
  - Atomic swaps do not natively support arbitrary asset pairs at AMM pricing; they are a primitive for one-shot peer-to-peer exchange.
  - Atomic swaps are non-custodial; that is their structural advantage.

See [[patterns/middle-chain-swap-settlement]] for the opposing pattern.

## Why Serai did not use atomic swaps

- Luke Parker (kayabaNerve), Serai's lead developer, has direct context in the Bitcoin to Monero atomic swap ecosystem and engages with it as a peer. Three teams working on BTC-XMR atomic swaps were publicly identified together by the Monero project in January 2021: Farcaster, COMIT, and Thorchain ([@monero on X, 2021-01-27](https://x.com/monero/status/1354495848391049218) :: accessed 2026-05-19).
- **Stated rationale (community fit)**: in a Monero Talk interview, Luke Parker said: *"while I do love atomic swaps [..] I don't feel the community actually wants atomic swaps, which is a brutal truth"* (timestamp 35:50, [Monero Observer: MoneroTalk interview with kayabaNerve on Serai DEX](https://monero.observer/monerotalk-kayabanerve-interview-serai-dex/) :: accessed 2026-05-19). This is the strongest direct quote located.
- **Stated rationale (UX and liquidity, second-hand summaries)**: third-party documentation of atomic-swap practice records the same constraints that Serai's design solves: BTC-side settlement is dominated by Bitcoin block times, "a single swap can take 30 minutes to several hours to finalise"; users "cannot easily swap large amounts because you need to find a specific peer willing to take the other side of that exact trade"; many providers require running command-line tools or specific nodes ([xgram.io: Best Monero atomic swap platforms 2026](https://xgram.io/blog/best-xmr-atomic-swaps-and-community-services-2026) :: accessed 2026-05-19).
- **Stated rationale on the chosen alternative**: Serai positions itself as a "collection of [..] liquidity pools where all pools have SRI on one side, efficiently connecting the entire network's liquidity and enabling even large swaps to be made quickly" ([docs.serai.exchange/amm](https://docs.serai.exchange/amm/) :: accessed 2026-05-19), and Luke Parker explicitly groups Serai with Thorchain, Maya, and Chainflip rather than with Farcaster or COMIT ([Monero Observer interview](https://monero.observer/monerotalk-kayabanerve-interview-serai-dex/) :: accessed 2026-05-19).
- **`[NOT FOUND]`**: no Serai blog post, GitHub RFC, issue, or spec file uses the words "atomic swap", "HTLC", "Farcaster" or "COMIT" to give a written design-time rejection (verified against [serai.exchange blog](https://serai.exchange/) and [serai-dex/serai](https://github.com/serai-dex/serai) :: accessed 2026-05-19). The rationale is articulated in podcast form, not in the project's documentation.
- **Implied rationale** (clearly labelled as my inference from the published design, not from a direct statement):
  - AMM pricing requires protocol-owned liquidity (LPs stake into pools), not per-swap peer-to-peer counterparty matching.
  - Multi-asset routing via the SRI hub pairing ([docs.serai.exchange/amm](https://docs.serai.exchange/amm/) :: accessed 2026-05-19) needs a global ordered state machine with `xy=k` invariant maintenance, which atomic swaps cannot provide.
  - UX targets a single user action (deposit with memo, await outbound) rather than an interactive multi-hour escrow flow with refund paths.
  - Embedding Monero requires no Monero-side scripting: Serai uses FROSTLASS threshold CLSAGs ([Announcing monero-oxide, 2025-09-09](https://serai.exchange/2025/09/09/monero-serai-oxide.html) :: accessed 2026-05-19), which is more general than the adaptor-signature primitive used by Farcaster and COMIT because it supports arbitrary outbound payments, not just one-shot swaps with a specific counterparty.

## Why Thorchain did not use atomic swaps

- **Stated rationale (the canonical post)**: a Thorchain Medium article titled "Why Cross-Chain bridges are superior to Atomic Swaps" (2019-07-02, authored by the Thorchain account) explicitly addresses this choice ([Thorchain Medium](https://medium.com/thorchain/why-cross-chain-bridges-are-superior-to-atomic-swaps-aebde263103c) :: accessed 2026-05-19). Direct quotes:
  - *"At present major limitations (mostly at the cryptography level) are proving to be an enormous impediment to this solution."*
  - *"Even though the technology works in concept, and even in individual cases, it is not proving to be simple or elegant to implement and solve problems of interoperability."*
  - *"The characteristic of communicating between chains is the breakthrough, not necessarily the method of atomic swaps."*
  - *"Bridges between chains, monitored and mandated by validators, is not only a simpler solution to cross-chain transfer, but a solution that is safer and has greater access to instant liquidity."*
- **Stated rationale (whitepaper framing)**: the original Thorchain whitepaper (v0.1, July 2018, [thorchain/Resources whitepaper-en.md](https://github.com/thorchain/Resources/blob/master/Whitepapers/Archived/THORChain/whitepaper-en.md) :: accessed 2026-05-19) frames the design around "continuous liquidity pools" that "ensure liquidity is always available for any token pair, and double as the source of trustless on-chain price feeds". The whitepaper does not engage with HTLC or scriptless-script atomic swaps at any length; the 2019 Medium post is the more direct comparison.
- **Implied rationale**: the CLP / slip-based fee design (see [[patterns/slip-based-fees]]) requires a single ordered state machine to maintain invariants, which is incompatible with the bilateral, asynchronous nature of an atomic swap. The 67 percent observation threshold in Bifrost ([Bifrost docs](https://dev.thorchain.org/bifrost/how-bifrost-works.html) :: accessed 2026-05-19) is conceptually the substitute for the hash preimage reveal in HTLC; the bond-slashing security model substitutes for the timelock refund path.

## Why Wormhole did not use atomic swaps (or light-client bridges)

- **Category mismatch**: Wormhole is a generic message-passing layer, not a DEX. Settlement on top of Wormhole (the Mayan and Wormhole Settlement products) is built using guardian-attested messages, not HTLC scripts ([Wormhole Settlement architecture docs](https://wormhole.com/docs/learn/messaging/wormhole-settlement/architecture/) :: accessed 2026-05-19; [Mayan Finance: Wormhole Swap architecture](https://docs.mayan.finance/architecture/wh-swap) :: accessed 2026-05-19).
- **Stated rationale on attestations vs alternatives**: Wormhole's design rests on a guardian set producing Verifiable Action Approvals (VAAs) as a general-purpose cross-chain primitive; the docs frame this as "generalised cross-chain messaging, broad network coverage, and a standardised attestation format that applications can reuse across ecosystems" ([Wormhole docs](https://wormhole.com/docs/learn/messaging/wormhole-settlement/architecture/) :: accessed 2026-05-19). The chosen contrast is with light-client bridges and asset-wrapping bridges, not atomic swaps.
- **`[NOT FOUND]`**: no Wormhole design document, whitepaper, or blog post located that explicitly discusses why atomic swaps were not chosen. The omission is consistent with Wormhole being a different category of primitive: HTLC cannot carry an arbitrary cross-chain message between two contracts on chains with different VMs.
- **Implied rationale**: generic message passing (for NFT bridges, governance messages, oracle data, etc.) is strictly more expressive than HTLC, which is essentially a single bit of trustless conditional release; atomic swaps were never a candidate for the use cases Wormhole targets.

## Why atomic swaps have not displaced middle-chain DEXes industry-wide

A brief retrospective covering the four most-cited atomic swap projects in this category:

- **AtomicDEX (Komodo)**: rebranded to "Komodo Wallet" in 2025 ([Komodo Platform Roadmap](https://roadmap.komodoplatform.com/) :: accessed 2026-05-19). Public exchange trackers report no recent volume: BitDegree's listing notes "no data available for AtomicDEX because of exchange inactivity" ([BitDegree: AtomicDEX trading data](https://www.bitdegree.org/top-crypto-exchanges/atomicdex) :: accessed 2026-05-19), and Nomics' last published 24-hour volume figure is approximately USD 5,737 from November 2021 ([Nomics: AtomicDEX](https://nomics.com/exchanges/atomicdex) :: accessed 2026-05-19). The platform has not been wound down, but it has not produced volumes competitive with custodial DEXes.
- **COMIT Network (xmr-btc-swap)**: the canonical BTC to XMR adaptor-signature implementation is explicitly marked unmaintained; the project notice reads "THIS REPO IS UNMAINTAINED PLEASE USE eigenwallet INSTEAD"; last formal release was v1.0.0-rc.1 on 2024-11-15, and the original COMIT team has moved to other projects ([github.com/comit-network/xmr-btc-swap](https://github.com/comit-network/xmr-btc-swap) :: accessed 2026-05-19). Community volunteers maintain a fork at eigenwallet/core which "introduced breaking changes at the network level" relative to upstream COMIT.
- **Farcaster Project**: still listed as actively maintained as of 2026, with Lightning BTC support added to reduce BTC-side confirmation time ([xgram.io: Best Monero atomic swap platforms 2026](https://xgram.io/blog/best-xmr-atomic-swaps-and-community-services-2026) :: accessed 2026-05-19; [github.com/farcaster-project](https://github.com/farcaster-project) :: accessed 2026-05-19). It is a community-scale rather than a volume-scale operation.
- **Liquality**: the consumer atomic-swap wallet extension was discontinued effective 2024-06-15 ([Liquality on X, 2024-05-20](https://x.com/Liquality_io/status/1792678368694985162) :: accessed 2026-05-19; corroborated by [Rootstock Helpdesk: Liquality](https://helpdesk.rootstock.io/solutions/liquality.html) :: accessed 2026-05-19). The company pivoted to in-app wallet and SDK products rather than P2P atomic swaps.
- **Cumulative volume**: Liquality reported "$35M in cross-chain atomic swaps facilitated through its wallet and interface" lifetime ([defiprime.com: Liquality](https://defiprime.com/liquality) :: accessed 2026-05-19). For comparison, Thorchain's cumulative volume is in the multi-billion USD range over the same period (see [[projects/thorchain]] for sourced figures).

### Structural reasons atomic swaps have not scaled

Drawing on the cited sources above:

- **Liquidity gravity**: peer-to-peer matching requires a counterparty per trade; AMM pools concentrate liquidity into a single state machine and serve all-comers ([Thorchain CLP docs](https://docs.thorchain.org/technical-documentation/thorchain-finance/continuous-liquidity-pools) :: accessed 2026-05-19).
- **UX**: multi-hour timelocks, online-availability requirements, refund flows, and CLI-grade tooling have prevented retail adoption ([xgram.io: Best Monero atomic swap platforms 2026](https://xgram.io/blog/best-xmr-atomic-swaps-and-community-services-2026) :: accessed 2026-05-19).
- **Pair coverage**: HTLC is constrained to chain pairs with compatible scripting; XMR specifically required a custom adaptor-signature protocol, which took roughly five years from first proposal (2017) to working community implementation (2021).
- **Implementation cost vs network effects**: as Thorchain's 2019 article put it, "no known repositories of successfully executed atomic swaps" between most pairs even years after the first Decred-Litecoin demo ([Thorchain Medium, 2019-07-02](https://medium.com/thorchain/why-cross-chain-bridges-are-superior-to-atomic-swaps-aebde263103c) :: accessed 2026-05-19).

The cumulative effect: a project that wants to offer cross-chain trading at AMM pricing with one-step UX and large-tail-asset support reaches for a middle chain with TSS custody. Serai, Thorchain, Maya, and Chainflip all converge on this pattern, and the existence of in-ecosystem alternatives (Farcaster, COMIT, AtomicDEX) does not appear to have changed the conclusion for any of the four.

## Sources

- [Bitcoin to Monero atomic swaps are now live (getmonero.org)](https://www.getmonero.org/2021/08/20/atomic-swaps.html) :: accessed 2026-05-19
- [Atomic Swaps between Bitcoin and Monero, Hoenisch and del Pino, IACR 2021/441 (ResearchGate)](https://www.researchgate.net/publication/348928221_Atomic_Swaps_between_Bitcoin_and_Monero) :: accessed 2026-05-19
- [Decred blog: On-Chain Atomic Swaps (2017)](https://blog.decred.org/2017/09/20/On-Chain-Atomic-Swaps/) :: accessed 2026-05-19
- [@monero on X listing Farcaster, COMIT and Thorchain (2021-01-27)](https://x.com/monero/status/1354495848391049218) :: accessed 2026-05-19
- [Monero Observer: MoneroTalk interview with kayabaNerve on Serai DEX](https://monero.observer/monerotalk-kayabanerve-interview-serai-dex/) :: accessed 2026-05-19
- [Serai AMM docs](https://docs.serai.exchange/amm/) :: accessed 2026-05-19
- [Serai blog: Announcing monero-oxide (2025-09-09)](https://serai.exchange/2025/09/09/monero-serai-oxide.html) :: accessed 2026-05-19
- [Serai blog index](https://serai.exchange/) :: accessed 2026-05-19
- [serai-dex/serai GitHub](https://github.com/serai-dex/serai) :: accessed 2026-05-19
- [Thorchain Medium: Why Cross-Chain bridges are superior to Atomic Swaps (2019-07-02)](https://medium.com/thorchain/why-cross-chain-bridges-are-superior-to-atomic-swaps-aebde263103c) :: accessed 2026-05-19
- [Thorchain whitepaper v0.1 (July 2018)](https://github.com/thorchain/Resources/blob/master/Whitepapers/Archived/THORChain/whitepaper-en.md) :: accessed 2026-05-19
- [Thorchain docs: Continuous Liquidity Pools](https://docs.thorchain.org/technical-documentation/thorchain-finance/continuous-liquidity-pools) :: accessed 2026-05-19
- [Thorchain dev docs: How Bifrost Works](https://dev.thorchain.org/bifrost/how-bifrost-works.html) :: accessed 2026-05-19
- [Wormhole Settlement architecture docs](https://wormhole.com/docs/learn/messaging/wormhole-settlement/architecture/) :: accessed 2026-05-19
- [Mayan Finance: Wormhole Swap architecture](https://docs.mayan.finance/architecture/wh-swap) :: accessed 2026-05-19
- [github.com/comit-network/xmr-btc-swap](https://github.com/comit-network/xmr-btc-swap) :: accessed 2026-05-19
- [github.com/farcaster-project](https://github.com/farcaster-project) :: accessed 2026-05-19
- [xgram.io: Best Monero atomic swap platforms 2026](https://xgram.io/blog/best-xmr-atomic-swaps-and-community-services-2026) :: accessed 2026-05-19
- [Komodo Platform Roadmap](https://roadmap.komodoplatform.com/) :: accessed 2026-05-19
- [BitDegree: AtomicDEX trading data](https://www.bitdegree.org/top-crypto-exchanges/atomicdex) :: accessed 2026-05-19
- [Nomics: AtomicDEX](https://nomics.com/exchanges/atomicdex) :: accessed 2026-05-19
- [Liquality on X: wallet discontinuation notice (2024-05-20)](https://x.com/Liquality_io/status/1792678368694985162) :: accessed 2026-05-19
- [Rootstock Helpdesk: Liquality](https://helpdesk.rootstock.io/solutions/liquality.html) :: accessed 2026-05-19
- [defiprime.com: Liquality cross-chain atomic swaps](https://defiprime.com/liquality) :: accessed 2026-05-19
