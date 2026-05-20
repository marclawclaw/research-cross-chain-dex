---
tags: [project, cross-chain-bridge, attestation-bridge, contrast]
ecosystem: Cross-chain (no native chain)
category: Cross-chain messaging and bridge
website: https://wormhole.com
docs: https://docs.wormhole.com
launched: 2021
---

# Wormhole

Wormhole is a guardian-attestation cross-chain messaging protocol, not a middle-chain DEX. It uses 19 reputable infrastructure operators (the Guardian network) signing 13-of-19 multisignature attestations called Verifiable Action Approvals (VAAs) to relay messages across roughly 40 connected chains; token movement uses lock-and-mint (Wrapped Token Transfers) or burn-and-mint (Native Token Transfers), and any cross-asset swap happens on external venues (destination-chain DEXes or solver networks like Mayan Swift) because Wormhole has no native settlement chain and no protocol-owned liquidity.

## Adoption metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| Supported blockchains (platform page) | 46 listed (overlapping mainnets, testnets, deprecated) | 2026-05-19 | [Wormhole supported blockchains](https://wormhole.com/platform/blockchains) :: accessed 2026-05-19 |
| Cumulative messages | 1,094,108,376 (all-time, claimed #1 in industry) | 2025-04-03 | [Connecting the Internet Economy](https://wormhole.com/blog/connecting-the-internet-economy-wormhole-and-the-w-tokens-past-present-and) :: accessed 2026-05-19 |
| Cumulative transfer volume (claim) | $58,946,586,582 (all-time) | 2025-04-03 | [Connecting the Internet Economy](https://wormhole.com/blog/connecting-the-internet-economy-wormhole-and-the-w-tokens-past-present-and) :: accessed 2026-05-19 |
| Portal Bridge TVL (DefiLlama) | $2.269B (mostly Ethereum: $2.104B) | 2026-05-19 | [Portal TVL on DefiLlama](https://defillama.com/protocol/portal) :: accessed 2026-05-19 |
| Portal Bridge 30-day volume | $1.169B | 2026-05-19 | [Portal TVL on DefiLlama](https://defillama.com/protocol/portal) :: accessed 2026-05-19 |
| Portal Bridge cumulative volume (DefiLlama) | $58.19B | 2026-05-19 | [Portal TVL on DefiLlama](https://defillama.com/protocol/portal) :: accessed 2026-05-19 |
| Annualised protocol fees | $189,576 (Wormhole makes no revenue; fees cover operational costs) | 2026-05-19 | [Portal TVL on DefiLlama](https://defillama.com/protocol/portal) :: accessed 2026-05-19 |
| W token market cap | $70.66M (FDV $120.1M, price $0.012) | 2026-05-19 | [Portal TVL on DefiLlama](https://defillama.com/protocol/portal) :: accessed 2026-05-19 |
| Guardian set size | 19 (threshold 13-of-19) | 2026-05-19 | [Wormhole Guardians docs](https://wormhole.com/docs/protocol/infrastructure/guardians/) :: accessed 2026-05-19 |
| Third-party audits | 29 completed (Trail of Bits, Neodyme, Certik, others) | 2026-05-19 | [Wormhole Security docs](https://wormhole.com/docs/protocol/security/) :: accessed 2026-05-19 |
| Bug bounty maximum (Immunefi, 2026) | $1,000,000 (denominated in W or USDC) | 2026-05-19 | [Wormhole Immunefi page](https://immunefi.com/bug-bounty/wormhole/information/) :: accessed 2026-05-19 |

## How it works

### User perspective

A cross-chain swap on Wormhole is a two-step composition, not a single protocol action.

1. The user deposits a token into the Wormhole Core Contract on the source chain (or signs an intent for the Settlement product).
2. Once 13-of-19 Guardians sign the resulting VAA, the user (or an off-chain relayer) submits it on the destination chain to mint a wrapped token (WTT) or release a native token (NTT hub-and-spoke / burn-and-mint).
3. If the user wants asset A on chain X to become asset B on chain Y, they then trade the bridged token on a destination-chain DEX (Uniswap, Jupiter, etc.) or use an intent product like Mayan Swift that combines the Wormhole message with solver-fronted liquidity ([Settlement Overview](https://wormhole.com/docs/products/settlement/overview/) :: accessed 2026-05-19).

This contrasts with [[projects/thorchain]] and [[projects/serai]], where a swap is a single atomic action on a middle chain backed by protocol-owned liquidity.

### Protocol perspective

- A source-chain contract emits a message by calling the Wormhole Core Contract; the event is published in transaction logs ([Architecture](https://wormhole.com/docs/protocol/architecture/) :: accessed 2026-05-19).
- Each of 19 Guardians runs a full node on every connected chain, independently observes the event, then ECDSA-signs `keccak256(keccak256(body))` of the message body ([VAAs docs](https://wormhole.com/docs/protocol/infrastructure/vaas/) :: accessed 2026-05-19).
- Once 13 signatures exist, the body and signatures are combined into a VAA, uniquely indexed by the tuple (emitter_chain, emitter_address, sequence). VAAs are "multicast" with "no destination": they are public artefacts ([VAAs docs](https://wormhole.com/docs/protocol/infrastructure/vaas/) :: accessed 2026-05-19).
- A permissionless relayer (or the Executor framework) submits the VAA on the destination chain, where the Core Contract verifies the signatures against the active Guardian set and the target contract executes the payload.
- There is no Wormhole chain. The protocol has no native consensus and no native settlement; it is a messaging overlay across N independent chains, each of which holds its own Core Contract and per-chain Token Bridge contracts.

### Product surface

Wormhole exposes several products on top of the core messaging layer ([Products Overview](https://wormhole.com/docs/products/overview/) :: accessed 2026-05-19):

- **Wrapped Token Transfers (WTT)**: classic lock-and-mint Token Bridge; the wrapped contracts on each chain are owned by Wormhole Governance (see [[patterns/lock-mint-bridging]]).
- **Native Token Transfers (NTT)**: hub-and-spoke (lock on hub, mint on spokes) or burn-and-mint (destroy on source, mint on destination), letting an issuer keep ownership of the token contract on each chain.
- **Settlement**: intent-based product wrapping Mayan Swift (off-chain solver auctions, ~12s execution, 3 bps fee) and Mayan MCTP (fallback via Circle CCTP). Solvers, not Wormhole, provide the liquidity ([Settlement Overview](https://wormhole.com/docs/products/settlement/overview/) :: accessed 2026-05-19).
- **Connect**: pre-built bridging UI.
- **Queries**: cross-chain read-data service.
- **MultiGov**: cross-chain governance framework used to manage the W token DAO.

## Security model

- 19 Guardians; 13-of-19 quorum for every VAA and every governance action ([Security docs](https://wormhole.com/docs/protocol/security/) :: accessed 2026-05-19).
- Guardians are named professional infrastructure firms, originally including Chorus One, Staked.us, P2P Validator, Triton.one, Certus One, Everstake, Chainode Tech, ChainLayer, Staking Fund, Dokia, 01Node, Moonlet, Inotel, Figment, Staking Facilities, HashQuark, Forbole, Syncnode, and Smith MCF ([Introducing Wormhole, Certus One](https://wormholecrypto.medium.com/introducing-wormhole-32b16d795c01) :: accessed 2026-05-19). The current set is published on the Wormhole Dashboard.
- **No slashing and no bonding.** The Wormhole security documentation explicitly contains no mention of slashing penalties or collateral; the threat model assumes at least 2/3 of Guardians act honestly. Up to 1/3 colluding or offline Guardians can delay or censor messages but cannot forge VAAs ([Guardians docs](https://wormhole.com/docs/protocol/infrastructure/guardians/) :: accessed 2026-05-19).
- Accountability is reputational and governance-driven: the Guardian set can be replaced by a supermajority governance vote, but there is no automated economic punishment.
- 29 third-party audits completed; Immunefi bug bounty up to $1M denominated in W ([Security docs](https://wormhole.com/docs/protocol/security/) :: accessed 2026-05-19; [Wormhole Immunefi page](https://immunefi.com/bug-bounty/wormhole/information/) :: accessed 2026-05-19).

## February 2022 incident

On 2 February 2022, an attacker drained 120,000 wETH (~$326M at the time) from the Solana-side Wormhole Token Bridge: at the time the second-largest DeFi exploit ever ([Halborn analysis](https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022) :: accessed 2026-05-19; [Chainalysis writeup](https://www.chainalysis.com/blog/wormhole-hack-february-2022/) :: accessed 2026-05-19).

Root cause:

- The Solana program's `verify_signatures` instruction used the deprecated `load_instruction_at` (not `load_instruction_at_checked`), which does not verify that the supplied "instructions sysvar" account is actually the canonical `Sysvar1nstructions` ([Halborn analysis](https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022) :: accessed 2026-05-19; [CertiK analysis](https://www.certik.com/blog/wormhole-bridge-exploit-incident-analysis) :: accessed 2026-05-19).
- The attacker passed a fabricated sysvar account containing fake instruction data, bypassing Guardian signature verification entirely, and minted 120k wETH on Solana without locking ETH on Ethereum.

Response:

- Jump Trading (then Wormhole's parent organisation) topped up the 120k ETH on 3 February 2022 to keep the wETH peg solvent, after the attacker ignored a $10M whitehat bounty offer ([Chainalysis](https://www.chainalysis.com/blog/wormhole-hack-february-2022/) :: accessed 2026-05-19).
- Solana issued a postmortem on 8 February 2022.

Aftermath:

- Wormhole expanded audits (to 29 firms as of 2026), formalised the Immunefi bug bounty, and the protocol team separated from Jump Crypto in 2023 to operate independently ([Blockworks](https://blockworks.co/news/wormhole-jump-trading-separate) :: accessed 2026-05-19; HTTP 403 on body fetch, headline-only).
- The W token launched 3 April 2024 with a 617M airdrop and a multichain DAO governance framework ([W launch roadmap](https://wormhole.com/blog/w-launch-roadmap) :: accessed 2026-05-19, secondary corroboration via Unchained and TokenPost search snippets).

## Why this is NOT a middle-chain DEX

- **No native chain.** Wormhole has no L1 of its own; it is a messaging overlay across other chains' Core Contracts.
- **No protocol-owned liquidity.** WTT mints wrapped IOUs, NTT mints native tokens; neither involves a Wormhole-owned reserve. Mayan Swift solvers, not Wormhole, front the capital needed for cross-asset swaps ([Settlement docs](https://wormhole.com/docs/products/settlement/overview/) :: accessed 2026-05-19).
- **No native swap execution.** Cross-asset swaps happen on destination-chain DEXes (Jupiter, Uniswap) or via external solver networks (Mayan, deBridge). The protocol does not match orders, set prices, or hold inventory.
- **Per-chain bridge contracts are the trust root.** Each chain has its own Wormhole Core Contract and Token Bridge; a single buggy contract on one chain can drain assets bound to it (as in February 2022). This is different from a shared TSS vault on a middle chain.
- **No bonded validator set.** Guardians have reputation but no capital at stake. Compare to ~100 Thorchain node operators bonding several million USD each, or Serai's substrate validator economics.

## Privacy properties

- Every VAA is a public artefact, broadcast multicast with "no destination" and indexed by (emitter_chain, emitter_address, sequence) ([VAAs docs](https://wormhole.com/docs/protocol/infrastructure/vaas/) :: accessed 2026-05-19).
- Token transfer payloads include recipient address and amount in cleartext.
- Both the source-chain deposit and the destination-chain redemption are normal on-chain transactions, fully observable on the underlying ledgers.
- No mixing, sealed orderflow, shielded balances, or zk-amount commitments. The protocol design assumes radical transparency.
- A user who routes asset A on chain X to asset B on chain Y via Wormhole + Mayan exposes: source address, source amount, destination address, destination amount, and a clear link through the VAA sequence number.

## Differentiators vs Serai and Thorchain

| Axis | Wormhole | [[projects/serai]] / [[projects/thorchain]] |
|------|----------|---------------------------------------------|
| Native chain | None (overlay) | Yes (Substrate / Cosmos SDK) |
| Settlement venue | External (destination DEX or solver) | On native middle chain |
| Custody | Per-chain bridge contracts | Protocol-owned TSS / FROST vaults |
| Liquidity | None protocol-owned (solvers front capital) | Protocol-owned LP pools |
| Validators | 19 named professional firms, reputation-bonded | Bonded PoS validators (~100, capital-bonded) |
| Slashing | No | Yes |
| Native-asset to native-asset swap | Not in protocol (requires aggregator) | Single atomic action in protocol |
| Privacy primitives | None | None (Thorchain) / minimal (Serai via shielded pools planned) |

## Limitations and criticisms

- **Static reputational trust.** A 13-of-19 multisig of named firms is a known small trust set; collusion of 7 firms (or compromise of 7 keys) forges arbitrary VAAs. Unlike PoS systems this risk cannot be priced or insured via slashing.
- **Per-chain attack surface.** Each integrated chain adds bridge-contract code in a new VM (EVM, Solana SVM, Move on Sui/Aptos, Substrate, Cosmos SDK). The February 2022 incident was a Solana-side bug invisible to the Guardian set itself.
- **No native cross-asset swap primitive.** Composing Wormhole with an external DEX adds slippage, MEV exposure, and a second trust boundary (the destination-chain DEX router). Solver networks reduce latency but introduce solver inventory risk and a curated solver set.
- **Wrapped token fragmentation.** WTT mints chain-specific wrapped representations; canonical token bridges and competing third-party wrappers fragment liquidity across chains.
- **W tokenomics weakness.** As of May 2026 the W token trades at $0.012 with a ~$70M market cap against an FDV of $120M; DAO security thus rests on a relatively small economic base.
- **No protocol revenue.** DefiLlama reports Wormhole "makes no revenue": fees are operational pass-through. Long-term operator funding is therefore tied to W issuance and grants rather than usage fees.

## Sources

- [Wormhole Architecture](https://wormhole.com/docs/protocol/architecture/) :: accessed 2026-05-19
- [Wormhole Guardians docs](https://wormhole.com/docs/protocol/infrastructure/guardians/) :: accessed 2026-05-19
- [Wormhole VAAs docs](https://wormhole.com/docs/protocol/infrastructure/vaas/) :: accessed 2026-05-19
- [Wormhole Security docs](https://wormhole.com/docs/protocol/security/) :: accessed 2026-05-19
- [Wormhole Products Overview](https://wormhole.com/docs/products/overview/) :: accessed 2026-05-19
- [Wormhole Token Transfers Overview](https://wormhole.com/docs/products/token-transfers/overview/) :: accessed 2026-05-19
- [Wormhole Settlement Overview](https://wormhole.com/docs/products/settlement/overview/) :: accessed 2026-05-19
- [Wormhole supported blockchains](https://wormhole.com/platform/blockchains) :: accessed 2026-05-19
- [Connecting the Internet Economy, Wormhole blog](https://wormhole.com/blog/connecting-the-internet-economy-wormhole-and-the-w-tokens-past-present-and) :: accessed 2026-05-19
- [Wormholescan upgrade blog](https://wormhole.com/blog/wormholescan-upgrade-real-time-data-analytics-for-the-wormhole-ecosystem) :: accessed 2026-05-19
- [W launch roadmap](https://wormhole.com/blog/w-launch-roadmap) :: accessed 2026-05-19
- [Introducing Wormhole, Certus One](https://wormholecrypto.medium.com/introducing-wormhole-32b16d795c01) :: accessed 2026-05-19
- [Portal TVL on DefiLlama](https://defillama.com/protocol/portal) :: accessed 2026-05-19
- [Wormhole bridge volume on DefiLlama](https://defillama.com/bridge/wormhole) :: accessed 2026-05-19
- [Halborn: Explained, the Wormhole hack February 2022](https://www.halborn.com/blog/post/explained-the-wormhole-hack-february-2022) :: accessed 2026-05-19
- [CertiK: Wormhole bridge exploit incident analysis](https://www.certik.com/blog/wormhole-bridge-exploit-incident-analysis) :: accessed 2026-05-19
- [Chainalysis: Lessons from the Wormhole exploit](https://www.chainalysis.com/blog/wormhole-hack-february-2022/) :: accessed 2026-05-19
- [Wormhole Immunefi bug bounty page](https://immunefi.com/bug-bounty/wormhole/information/) :: accessed 2026-05-19
- [Blockworks: Wormhole execs depart Jump Trading](https://blockworks.co/news/wormhole-jump-trading-separate) :: accessed 2026-05-19 (headline only, body returned HTTP 403)
- [Everstake: Year of Wormhole](https://everstake.one/blog/the-year-of-wormhole-how-the-project-evolved) :: accessed 2026-05-19
