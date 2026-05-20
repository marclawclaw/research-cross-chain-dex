---
tags: [project, middle-chain, cross-chain-dex, cosmos-sdk]
ecosystem: Standalone (Cosmos SDK)
category: Cross-chain DEX
website: https://thorchain.org
docs: https://docs.thorchain.org
launched: 2021 (multichain mainnet)
---

# Thorchain

Thorchain is a standalone Cosmos SDK / CometBFT Layer 1 that operates as a cross-chain decentralised exchange, settling native asset to native asset swaps (for example BTC to ETH) without wrapped or pegged tokens. It works by having validators run an off-chain observer / signer daemon called Bifrost that watches connected chains and co-signs outbound transactions from Threshold Signature Scheme (TSS) vaults that custody all liquidity. The protocol uses RUNE as the universal pairing asset in continuous liquidity pools (CLPs) and as the bonded collateral that secures vault custody.

## Adoption metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| TVL (DEX) | $70.24M | 2026-05-19 | [DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex) |
| Cumulative swap volume | $112.201B | 2026-05-19 | [DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex) |
| 30 day volume | $1.632B | 2026-05-19 | [DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex) |
| Monthly swap volume (Feb 2026) | $882M | 2026-02 | [State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) |
| Annualised fees | $29.76M | 2026-05-19 | [DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex) |
| Active node count | 103 (cap 120) | 2026-02 | [State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) |
| Total bonded RUNE | 97.13M (~$38.62M) | 2026-02 | [State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) |
| Average bond per node | ~$374.96K | 2026-02 | [State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) |
| Minimum bond requirement | 400,020 RUNE | 2026-02 | [State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) |
| Q1 2025 quarterly volume | $19.62B | 2025-Q1 | [THORChain Q1 2025 Report](https://medium.com/thorchain/thorchain-q1-2025-report-q2-roadmap-ffdb9e303c74) |
| Supported external chains | 11 | 2026-02 | [State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) |
| RUNE max supply | 500M | 2026-05-19 | [Economic Model docs](https://docs.thorchain.org/technical-documentation/technical-deep-dive/economic-model.md) |

## How it works

### User perspective

1. User selects a swap on a front-end (THORSwap, Asgardex, ShapeShift, Trust Wallet, etc.) which constructs a memo such as `SWAP:ETH.ETH:0xDest:LIM:AFFILIATE:FEE` ([memos](https://dev.thorchain.org/concepts/memos.html)).
2. User sends an inbound transaction on the source chain (for example Bitcoin) to the current active Asgard vault address, embedding the memo in the chain native field (`OP_RETURN` for Bitcoin, calldata for EVM, etc.). UTXO memos are constrained to 80 bytes by `OP_RETURN`, extended via multi-output reassembly on recent versions ([memos](https://dev.thorchain.org/concepts/memos.html)).
3. Inbound is observed by Bifrost daemons on every active node, confirmation counted (chain dependent), and once 67 percent of nodes agree, the inbound is finalised on Thorchain ([Bifrost](https://dev.thorchain.org/bifrost/how-bifrost-works.html)).
4. CLP math executes against the source pool, routes through RUNE, and credits the destination pool. A slip-based fee scales with the swap size relative to pool depth ([CLP docs](https://docs.thorchain.org/technical-documentation/thorchain-finance/continuous-liquidity-pools.md)).
5. An outbound `TxOut` is queued, optionally delayed up to ~720 blocks (~1 hour) by Swapper Clout, then TSS signed by the assigned vault and broadcast on the destination chain ([delays](https://dev.thorchain.org/concepts/delays.html)).

### Protocol perspective

- **Bifrost observer**: each node scans every connected chain for transactions to active vault addresses, normalises them into witness messages (`MsgObservedTxIn`), and gossips to the Thorchain mempool ([Bifrost](https://dev.thorchain.org/bifrost/how-bifrost-works.html)).
- **Consensus on observations**: requires 67 percent supermajority before the inbound is admitted to the state machine ([Bifrost](https://dev.thorchain.org/bifrost/how-bifrost-works.html)).
- **Confirmation counting**: instant finality chains (BFT) are accepted immediately; UTXO and EVM chains require `min((TxValue / BlockReward) * ConfMultiplier, MAXCONFIRMATIONS)` ([delays](https://dev.thorchain.org/concepts/delays.html)).
- **Outbound signing**: state machine assigns the outbound to a vault; vault members run a multi-round GG20 TSS keysign ceremony, then broadcast to the destination chain ([TSS](https://dev.thorchain.org/bifrost/tss.html)).
- **Errata**: re-orgs on UTXO and EVM chains are reversed via errata transactions ([Bifrost](https://dev.thorchain.org/bifrost/how-bifrost-works.html)).

See also [[../patterns/middle-chain-swap-settlement]] and [[../patterns/slip-based-fees]].

## Why not atomic swaps?

Thorchain has the most explicit written rejection of any project surveyed: a 2019-07-02 Medium post titled "Why Cross-Chain bridges are superior to Atomic Swaps" ([Thorchain Medium](https://medium.com/thorchain/why-cross-chain-bridges-are-superior-to-atomic-swaps-aebde263103c), accessed 2026-05-19), arguing that "at present major limitations (mostly at the cryptography level) are proving to be an enormous impediment to this solution" and that "bridges between chains, monitored and mandated by validators, is not only a simpler solution to cross-chain transfer, but a solution that is safer and has greater access to instant liquidity". The 2018 whitepaper does not engage with HTLC; the 2019 post is the load-bearing design-time statement. See [[patterns/atomic-swaps-vs-middle-chain]] for full context.

## Architecture decisions

- **Consensus**: Cosmos SDK state machine on CometBFT (formerly Tendermint), ~6 second block time, near instant finality on the home chain ([technology overview](https://docs.thorchain.org/technical-documentation/technology.md), [delays](https://dev.thorchain.org/concepts/delays.html)).
- **No smart contract bridges on the home chain**: external assets are not wrapped or minted as IOUs; the home chain just records pool balances and signs outbounds against TSS controlled vaults on the foreign chains ([introduction](https://docs.thorchain.org/)).
- **One pairing asset (RUNE)**: all pools are `RUNE / X`. Two side swaps route through RUNE in a single internal transaction, which concentrates liquidity and simplifies pricing ([CLP docs](https://docs.thorchain.org/technical-documentation/thorchain-finance/continuous-liquidity-pools.md)).
- **App layer (CosmWasm and Rujira)**: Thorchain now exposes CosmWasm so contract apps can be deployed natively on the chain ([technology](https://docs.thorchain.org/technical-documentation/technology.md)).

## Custody model: TSS vaults

- **Scheme**: GG20 (Gennaro and Goldfeder 2020) ECDSA TSS, plus EdDSA support added in 2025 for chains like Solana. Implementation is a Thorchain fork of Binance `tss-lib`, upgraded from GG18 to GG20 ([TSS](https://dev.thorchain.org/bifrost/tss.html)).
- **Threshold**: at least `ceil(n*2/3)` parties (a two thirds supermajority) must cooperate for valid signing ([TSS](https://dev.thorchain.org/bifrost/tss.html)).
- **Asgard vaults**: TSS multisig accounts controlled by the active validator set. Each logical vault is sharded into multiple physical vaults; the `asgardsize` Mimir parameter caps members per shard at 20 by default, so 120 active nodes produce 6 physical shards ([Bifrost, TSS and Vaults](https://docs.thorchain.org/technical-documentation/technology/bifrost-tss-and-vaults.md)).
- **Yggdrasil vaults (deprecated)**: previously, each node held a per node hot vault containing up to 50 percent of network funds, signed unilaterally to speed up small outbounds. These were deprecated under ADR 002; nodes leaving must drain Yggdrasil balances before unbonding ([Leaving docs](https://docs.thorchain.org/thornodes/leaving)).
- **Lifecycle**: vaults proceed `InitVault` -> `Active` -> `Retiring` -> `Inactive`. On churn, a fresh keygen creates new vaults; old vaults migrate funds in rounds every 30 minutes, gas asset last ([vault behaviours](https://dev.thorchain.org/bifrost/vault-behaviors.html)).
- **Churn cadence**: every 3 days the oldest, slowest, and lowest bonded active node is rotated out ([State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) and [under the hood: Asgard vaults](https://thorchain-community.medium.com/under-the-hood-asgard-vaults-tss-and-node-churns-4767f3a5624b)).
- **Slashing**: nodes that fail or sabotage keygen / keysign ceremonies are blamed and slashed via consensus ([TSS](https://dev.thorchain.org/bifrost/tss.html)).

See also [[../patterns/tss-custody-vault]].

## Economic security

- **RUNE bonding**: each node operator must bond at least the dynamic minimum (400,020 RUNE in February 2026, around $159K) to enter the active set; the effective cap was ~1.01M RUNE per node ([State of the Network Feb 2026](https://blog.thorchain.org/state-of-the-network-february-2026/)).
- **Three to one invariant**: the protocol targets $3 of RUNE locked for every $1 of non RUNE assets ($1 of RUNE pooled plus $2 of RUNE bonded). This is the basis of RUNE's deterministic value ([Incentive Pendulum (Medium)](https://medium.com/thorchain/the-incentive-pendulum-848f3c3e4d1d), [Tokenomics](https://medium.com/thorchain/thorchain-tokenomics-what-is-rune-52d339633260)).
- **Incentive pendulum**: rewards are shifted between bonders and LPs to keep the 2:1 bond to pooled ratio. Excess pooling tilts rewards to nodes (network is unsafe); excess bonding tilts rewards to LPs (network is inefficient) ([Economic Model](https://docs.thorchain.org/technical-documentation/technical-deep-dive/economic-model.md)).
- **Cost to attack (in theory)**: to capture two thirds of an Asgard vault an attacker must accumulate two thirds of bonded RUNE; under the 2:1 invariant this should always exceed the value of pooled assets. In practice the May 2026 incident shows the invariant is a necessary but not sufficient condition (see [[#Incidents]]).
- **Solvency monitoring**: if 66 percent of nodes report an insolvency for a chain, trading for that chain auto halts; any node can call `make halt` once per 3 day churn cycle ([security docs](https://docs.thorchain.org/technical-documentation/technical-deep-dive/security.md)).

## Privacy properties

- **All swap intent on chain**: the memo carrying destination address, slippage limit, affiliate, etc. is broadcast on the source chain (`OP_RETURN`, calldata, or memo field) before Thorchain even sees it; this links source and destination chain identities publicly ([memos](https://dev.thorchain.org/concepts/memos.html)).
- **Pool state and outbound public**: outbound transactions on the destination chain are public and signature scheme is on chain; chain analysis can trivially link inbound to outbound by time, value, and memo ([THORChain privacy guide](https://xgram.io/blog/thorchain-privacy-guide)).
- **No first class privacy**: Thorchain itself is described in third party guides as `decentralised but not private`. Privacy on Thorchain swaps requires external mixing on the source or destination side (for example arriving from Monero, sending to a fresh wallet) ([Baltex privacy guide](https://baltex.io/blog/ecosystem/thorchain-private-swaps-anonymous-btc-2026-guide)).
- **MEV exposure**: pool state changes are public and observable in mempool, so toxic ordering is possible. Slip based fees damp profitable sandwiches (see [[../patterns/slip-based-fees]]). Streaming swaps split large orders into many sub swaps over many blocks, further raising the cost of MEV ([Streaming Swaps](https://dev.thorchain.org/swap-guide/streaming-swaps.html)).
- **Note**: contrast with [[serai]] (encrypted multisig assignments, but txns still public) and [[wormhole]] (attestation only, no swap matching).

## Incidents

### July 2021: ETH Router exploits

- **Exploit 1 (15 July 2021)**: attacker wrapped the ETH Router with a malicious contract and used the override function to spoof `msg.value` in Bifrost observations, fooling the network into believing deposits occurred. Around 4,200 ETH (then ~$8M; ~$4.9M post slippage on the pool) drained ([Halborn writeup](https://www.halborn.com/blog/post/explained-the-thorchain-hack-july-2021), [postmortem](https://medium.com/thorchain/post-mortem-eth-router-exploits-1-2-and-premature-return-to-trading-incident-2908928c5fb)).
- **Premature return to trading**: in recovery, the network re-enabled trading at 67 percent upgrade completion; old logic on remaining nodes let LPs withdraw asymmetrically, nearly causing insolvency ([postmortem](https://medium.com/thorchain/post-mortem-eth-router-exploits-1-2-and-premature-return-to-trading-incident-2908928c5fb)).
- **Exploit 2 (~23 July 2021)**: a second attacker used a fake router with manipulated deposit events to drain economically significant ERC20s including ALCX, XRUNE, USDC, SUSHI, YFI, USDT, totalling around $8M of losses ([postmortem](https://medium.com/thorchain/post-mortem-eth-router-exploits-1-2-and-premature-return-to-trading-incident-2908928c5fb), [Coindesk](https://www.coindesk.com/markets/2021/07/23/blockchain-protocol-thorchain-suffers-8m-hack)).
- **Combined losses**: about $16M; treasury covered LP losses ([postmortem](https://medium.com/thorchain/post-mortem-eth-router-exploits-1-2-and-premature-return-to-trading-incident-2908928c5fb)).
- **Root cause**: Bifrost trusted smart contract emitted events instead of canonical transfer data, and the upgraded MCCN Bifrost had not been audited by Trail of Bits at the time ([postmortem](https://medium.com/thorchain/post-mortem-eth-router-exploits-1-2-and-premature-return-to-trading-incident-2908928c5fb)).
- **Response**: network halted via `make halt` quorum, hardened, then audited by Halborn and Trail of Bits ([Halborn audits](https://www.halborn.com/audits/thorchain)).

### January 2024: lending and savers wind down

- On 23 January 2024 node operators voted to suspend lending and savers programs for at least 90 days to address an insolvency exposure of around $200M (~$97M lending, ~$102M savers) ([Cointelegraph](https://cointelegraph.com/news/thorchain-pauses-bitcoin-ether-lending-amid-insolvency-risks), [Decrypt](https://decrypt.co/302688/defi-network-thorchain-200-million-debt-whats-going-on)).
- The community voted to convert the debt into equity tokens (TCY), permanently freeze remaining lending and savers positions, and burn Protocol Owned Liquidity (POL) keys to reduce centralisation risk ([Bitget News](https://www.bitget.com/news/detail/12560604523558)).
- Core DEX functionality remained operational, but RUNE fell ~32 percent on the announcement ([Cointelegraph](https://cointelegraph.com/news/thorchain-pauses-bitcoin-ether-lending-amid-insolvency-risks)).

### May 2026: GG20 TSS exploit

- On 15 May 2026 an Asgard vault was drained of around $10.8M across Ethereum (3,443 ETH), Bitcoin (36.85 BTC), BNB, and Base. The leading theory is a GG20 TSS vulnerability in the TSSHOCK class of CVEs, exploited by a recently churned validator node (`thor16ucjv3v695mq283me7esh0wdhajjalengcn84q`) that leaked key material across keygen or signing rounds ([Crypto Times](https://www.cryptotimes.io/2026/05/17/10-8-million-drained-inside-the-thorchain-exploit-that-froze-cross-chain-defi-for-13-hours/), [Coindesk](https://www.coindesk.com/tech/2026/05/15/thorchain-halts-trading-after-usd10-million-cross-chain-exploit-rune-token-drops-12), [AMBCrypto](https://ambcrypto.com/thorchain-exploit-raises-fresh-concerns-over-mpc-wallet-security/)).
- The network auto paused signing for ~13 hours via `make pause` at block 26190429 ([Crypto Times](https://www.cryptotimes.io/2026/05/17/10-8-million-drained-inside-the-thorchain-exploit-that-froze-cross-chain-defi-for-13-hours/)).
- Attacker funded the malicious node via Hyperliquid and Monero in the weeks before the attack ([Crypto Times pre-attack trail](https://www.cryptotimes.io/2026/05/16/chainalysis-traces-thorchain-hackers-pre-attack-monero-hyperliquid-trail/)).
- Only protocol owned liquidity was hit; user wallets and LP positions were not touched ([Crypto Times](https://www.cryptotimes.io/2026/05/17/10-8-million-drained-inside-the-thorchain-exploit-that-froze-cross-chain-defi-for-13-hours/)).

## Differentiators vs [[serai]] and [[wormhole]]

- vs [[serai]]: Thorchain and Serai share the middle chain plus TSS multisig pattern. Thorchain is live, has 11 chain integrations, and over $112B cumulative volume, but uses pseudo random GG20 with documented exploit class. Serai is in testnet and uses FROST EdDSA with encrypted next set assignment, oriented around privacy native settlement.
- vs [[wormhole]]: Wormhole is an attestation bridge that emits signed messages for external apps to mint or release wrapped assets; it does not host pools or run swaps. Thorchain is the opposite: a settlement chain that runs the AMM and custodies native assets in its own TSS vaults. Wormhole therefore enables but does not provide a DEX, whereas Thorchain bundles bridge plus DEX into one validator set.

## Limitations and criticisms

- **Repeated solvency surfaces**: 2021 router bugs and 2024 lending insolvency show that the protocol level economic security argument (2:1 bond to pooled ratio) does not by itself protect against bridge code bugs, complex new product launches, or TSS implementation flaws.
- **GG20 fragility**: the May 2026 incident points to known TSS vulnerability classes (TSSHOCK / malformed proofs). Replacing GG20 with a hardened scheme is an open work item ([AMBCrypto](https://ambcrypto.com/thorchain-exploit-raises-fresh-concerns-over-mpc-wallet-security/)).
- **Centralisation pressures**: only 103 to 120 active nodes; high minimum bond (~$159K) creates a small operator set. Churn helps but the set is small relative to L1s.
- **Privacy gap**: memos make every cross chain swap publicly correlatable; no first class privacy. This is the gap [[../patterns/middle-chain-swap-settlement|the LEZ middle chain pattern]] could fill.
- **External chain dependency**: Bifrost confirmation counting depends on per chain finality assumptions; large UTXO re-orgs are handled by errata transactions but introduce complexity.
- **Single pairing asset risk**: every pool is RUNE paired, so RUNE price shocks propagate to all swap pricing simultaneously.

## Sources

- [Bifrost, TSS and Vaults | THORChain Docs](https://docs.thorchain.org/technical-documentation/technology/bifrost-tss-and-vaults.md) :: accessed 2026-05-19
- [Bifrost - THORChain Dev Docs](https://dev.thorchain.org/bifrost/how-bifrost-works.html) :: accessed 2026-05-19
- [TSS - THORChain Dev Docs](https://dev.thorchain.org/bifrost/tss.html) :: accessed 2026-05-19
- [Vault Behaviors - THORChain Dev Docs](https://dev.thorchain.org/bifrost/vault-behaviors.html) :: accessed 2026-05-19
- [Delays - THORChain Dev Docs](https://dev.thorchain.org/concepts/delays.html) :: accessed 2026-05-19
- [Transaction Memos - THORChain Dev Docs](https://dev.thorchain.org/concepts/memos.html) :: accessed 2026-05-19
- [Streaming Swaps - THORChain Dev Docs](https://dev.thorchain.org/swap-guide/streaming-swaps.html) :: accessed 2026-05-19
- [Continuous Liquidity Pools | THORChain Docs](https://docs.thorchain.org/technical-documentation/thorchain-finance/continuous-liquidity-pools.md) :: accessed 2026-05-19
- [Economic Model | THORChain Docs](https://docs.thorchain.org/technical-documentation/technical-deep-dive/economic-model.md) :: accessed 2026-05-19
- [Security | THORChain Docs](https://docs.thorchain.org/technical-documentation/technical-deep-dive/security.md) :: accessed 2026-05-19
- [The Incentive Pendulum (Medium)](https://medium.com/thorchain/the-incentive-pendulum-848f3c3e4d1d) :: accessed 2026-05-19
- [THORChain Tokenomics (Medium)](https://medium.com/thorchain/thorchain-tokenomics-what-is-rune-52d339633260) :: accessed 2026-05-19
- [Under the Hood: Asgard Vaults (Medium)](https://thorchain-community.medium.com/under-the-hood-asgard-vaults-tss-and-node-churns-4767f3a5624b) :: accessed 2026-05-19
- [Leaving | THORChain Docs](https://docs.thorchain.org/thornodes/leaving) :: accessed 2026-05-19
- [DefiLlama Thorchain DEX](https://defillama.com/protocol/thorchain-dex) :: accessed 2026-05-19
- [State of the Network February 2026](https://blog.thorchain.org/state-of-the-network-february-2026/) :: accessed 2026-05-19
- [THORChain Q1 2025 Report](https://medium.com/thorchain/thorchain-q1-2025-report-q2-roadmap-ffdb9e303c74) :: accessed 2026-05-19
- [Post mortem: ETH Router Exploits 1 and 2](https://medium.com/thorchain/post-mortem-eth-router-exploits-1-2-and-premature-return-to-trading-incident-2908928c5fb) :: accessed 2026-05-19
- [Explained: the THORChain Hack July 2021 (Halborn)](https://www.halborn.com/blog/post/explained-the-thorchain-hack-july-2021) :: accessed 2026-05-19
- [Halborn THORChain Audits](https://www.halborn.com/audits/thorchain) :: accessed 2026-05-19
- [THORChain Coindesk July 2021](https://www.coindesk.com/markets/2021/07/23/blockchain-protocol-thorchain-suffers-8m-hack) :: accessed 2026-05-19
- [Cointelegraph: Thorchain pauses lending January 2024](https://cointelegraph.com/news/thorchain-pauses-bitcoin-ether-lending-amid-insolvency-risks) :: accessed 2026-05-19
- [Decrypt: THORChain $200M toxic debt](https://decrypt.co/302688/defi-network-thorchain-200-million-debt-whats-going-on) :: accessed 2026-05-19
- [Bitget News: Thorchain debt restructure](https://www.bitget.com/news/detail/12560604523558) :: accessed 2026-05-19
- [Crypto Times: $10.8M Drained (May 2026)](https://www.cryptotimes.io/2026/05/17/10-8-million-drained-inside-the-thorchain-exploit-that-froze-cross-chain-defi-for-13-hours/) :: accessed 2026-05-19
- [Coindesk: Thorchain halts trading May 2026](https://www.coindesk.com/tech/2026/05/15/thorchain-halts-trading-after-usd10-million-cross-chain-exploit-rune-token-drops-12) :: accessed 2026-05-19
- [Crypto Times: Chainalysis traces hacker (May 2026)](https://www.cryptotimes.io/2026/05/16/chainalysis-traces-thorchain-hackers-pre-attack-monero-hyperliquid-trail/) :: accessed 2026-05-19
- [AMBCrypto: MPC wallet security concerns](https://ambcrypto.com/thorchain-exploit-raises-fresh-concerns-over-mpc-wallet-security/) :: accessed 2026-05-19
- [THORChain privacy guide (xgram)](https://xgram.io/blog/thorchain-privacy-guide) :: accessed 2026-05-19
- [Baltex private swaps guide](https://baltex.io/blog/ecosystem/thorchain-private-swaps-anonymous-btc-2026-guide) :: accessed 2026-05-19
