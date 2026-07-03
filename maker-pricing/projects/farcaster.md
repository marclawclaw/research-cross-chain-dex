---
tags: [atomic-swap, btc-xmr, p2p-protocol]
category: swap-protocol-library
website: https://github.com/farcaster-project
docs: https://github.com/farcaster-project/RFCs
launched: 2021
---

# Farcaster — BTC↔XMR Atomic Swap Protocol

Farcaster is a Rust implementation of the COMIT BTC↔XMR atomic swap protocol, split into two repositories: `farcaster-core` (the protocol library) and `farcaster-node` (the swap daemon). Pricing — meaning the exchange rate between BTC and XMR — is not negotiated at the protocol level. Instead, the maker encodes fixed absolute amounts directly into the deal. The ratio of those two amounts is the implicit rate. There is no spread parameter, no oracle integration, and no dynamic pricing hook in either repository.

## Adoption / usage metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| `farcaster-core` GitHub stars | 39 | 2026-07-03 | [GitHub API](https://api.github.com/repos/farcaster-project/farcaster-core) |
| `farcaster-core` GitHub forks | 12 | 2026-07-03 | [GitHub API](https://api.github.com/repos/farcaster-project/farcaster-core) |
| `farcaster-node` GitHub stars | 109 | 2026-07-03 | [GitHub API](https://api.github.com/repos/farcaster-project/farcaster-node) |
| `farcaster-node` GitHub forks | 16 | 2026-07-03 | [GitHub API](https://api.github.com/repos/farcaster-project/farcaster-node) |
| Last commit to `farcaster-core` | 2 January 2023 | 2026-07-03 | [GitHub](https://github.com/farcaster-project/farcaster-core/commits/main) |
| Last commit to `farcaster-node` | 11 August 2024 (shell.nix maintenance only) | 2026-07-03 | [GitHub](https://github.com/farcaster-project/farcaster-node/commits/main) |
| Last substantive node commit | 23 June 2023 (syncer balance fixes, PR #946) | 2026-07-03 | [GitHub](https://github.com/farcaster-project/farcaster-node/commits/main) |
| Live swap network / active nodes | [NOT FOUND] | — | — |
| Known live swaps count | [NOT FOUND] | — | — |
| Community size (Discord/Matrix) | [NOT FOUND] | — | — |

## What is a "deal" in Farcaster?

A deal is the fundamental unit of trade advertisement in Farcaster. The maker creates a deal, serialises it as a base58-encoded string starting with `Deal:`, and distributes it to potential takers (via any channel — chat, a web board, etc.). The deal encodes everything a taker needs to understand the trade and connect to the maker's node.

### `DealParameters` fields (from `farcaster-core/src/trade.rs`)

```rust
pub struct DealParameters<Amt, Bmt, Ti, F> {
    pub uuid: DealId,                          // unique deal identifier (randomised UUID)
    pub network: Network,                      // Mainnet | Testnet | Local
    pub arbitrating_blockchain: Blockchain,    // always Bitcoin in BTC↔XMR
    pub accordant_blockchain: Blockchain,      // always Monero in BTC↔XMR
    pub arbitrating_amount: Amt,               // BTC amount in satoshis (e.g. bitcoin::Amount)
    pub accordant_amount: Bmt,                 // XMR amount in piconero (e.g. monero::Amount)
    pub cancel_timelock: Ti,                   // CSV blocks before cancel tx is valid
    pub punish_timelock: Ti,                   // CSV blocks before punish tx is valid
    pub fee_strategy: FeeStrategy<F>,          // Fixed(sat/kvB) or Range{min_inc, max_inc}
    pub maker_role: SwapRole,                  // Alice (sells XMR) or Bob (sells BTC)
}
```

A `Deal` wraps `DealParameters` and adds:
- `version: Version` — deal version (currently v1)
- `node_id: PublicKey` — maker's secp256k1 identity key (used for session encryption)
- `peer_address: InetSocketAddr` — IP/port where takers connect

**Source:** [`farcaster-core/src/trade.rs`](https://github.com/farcaster-project/farcaster-core/blob/main/src/trade.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-core-trade-rs.rs)

## Pricing in the deal

### Exchange rate: implicit, encoded as two absolute amounts

Farcaster does **not** have an exchange rate field. The implied rate is:

```
rate = arbitrating_amount (BTC) / accordant_amount (XMR)
     = BTC per XMR
```

The `deal_buy_information()` function in `farcaster-node/src/cli/command.rs` makes this explicit — it computes and displays the rate when the taker previews the deal:

```rust
fn deal_buy_information(deal_parameters: &DealParameters) -> String {
    match deal_parameters.maker_role.other() {
        SwapRole::Alice => format!(
            "{} for {} at {} BTC/XMR",
            deal_parameters.arbitrating_amount,
            deal_parameters.accordant_amount,
            deal_parameters.arbitrating_amount.as_btc()
                / deal_parameters.accordant_amount.as_xmr()
        ),
        SwapRole::Bob => format!(
            "{} for {} at {} XMR/BTC",
            deal_parameters.accordant_amount,
            deal_parameters.arbitrating_amount,
            deal_parameters.accordant_amount.as_xmr()
                / deal_parameters.arbitrating_amount.as_btc()
        ),
    }
}
```

The rate is therefore a quotient of two amounts set freely by the maker and is **fixed at deal creation time**. There is no subsequent renegotiation once the deal is published.

**Source:** [`farcaster-node/src/cli/command.rs`](https://github.com/farcaster-project/farcaster-node/blob/main/src/cli/command.rs) — accessed 2026-07-03

### `FeeStrategy` — the only fee-related pricing field

`FeeStrategy<T>` is defined in `farcaster-core/src/blockchain.rs`:

```rust
pub enum FeeStrategy<T> {
    Fixed(T),
    #[cfg(feature = "fee_range")]
    Range { min_inc: T, max_inc: T },
}
```

For Bitcoin, `T` is `SatPerKvB` (satoshis per kilo-virtual-byte). A `Fixed` strategy requires every Bitcoin transaction in the swap to use exactly that fee rate. A `Range` strategy (behind the `fee_range` feature flag, not enabled by default) sets a minimum and maximum band — either participant can validate that fees fall within the range. This is a **transaction-fee** parameter, not an exchange-rate one.

**Source:** [`farcaster-core/src/blockchain.rs`](https://github.com/farcaster-project/farcaster-core/blob/main/src/blockchain.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-core-blockchain-rs.rs)

## farcaster-node maker interface

### `swap-cli make` command — all pricing parameters

The maker creates a deal by running `swap-cli make` with these arguments (from `farcaster-node/src/cli/opts.rs`):

| Argument | Type | Default | Purpose |
|----------|------|---------|---------|
| `--btc-amount` | `bitcoin::Amount` | (required) | BTC leg of the deal (sets the arbitrating amount) |
| `--xmr-amount` | `monero::Amount` | (required) | XMR leg of the deal (sets the accordant amount) |
| `--maker-role` | `Alice \| Bob` | `Bob` | Which asset the maker sells: Alice sells XMR, Bob sells BTC |
| `--fee-strategy` | `FeeStrategy<SatPerKvB>` | `"1000 satoshi/kvB"` | Bitcoin transaction fee rate for all swap transactions |
| `--cancel-timelock` | `CSVTimelock` | `4` (blocks) | How long until cancel tx becomes valid after lock |
| `--punish-timelock` | `CSVTimelock` | `5` (blocks) | Additional delay before punish tx after cancel |
| `--network` | `Mainnet \| Testnet \| Local` | `testnet` | Network context |
| `--public-ip-addr` | `IpAddr` | `127.0.0.1` | Public IP advertised in the deal |
| `--public-port` | `u16` | `7067` | Port advertised in the deal |

**No `--spread` or `--rate` parameter exists.** The exchange rate is set solely through `--btc-amount` and `--xmr-amount`.

Example from documentation:
```bash
swap-cli make \
  --btc-addr tb1q935eq5fl2a3ajpqp0e3d7z36g7vctcgv05f5lf \
  --xmr-addr 54EYTy2HYFcAXwAbFQ3HmAis8JLNmxRdTC9DwQL7sGJd4CAUYimPxuQHYkMNg1EELNP85YqFwqraLd4ovz6UeeekFLoCKiu \
  --btc-amount "0.0000135 BTC" --xmr-amount "0.001 XMR" \
  --network testnet \
  --maker-role Bob \
  --cancel-timelock 4 --punish-timelock 5 \
  --fee-strategy "1500 satoshi/kvB" \
  --public-ip-addr <your-ip> --public-port 7067
```

**Source:** [`farcaster-node/src/cli/opts.rs`](https://github.com/farcaster-project/farcaster-node/blob/main/src/cli/opts.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-cli-opts-rs.rs); [`docs/Usage.md`](https://github.com/farcaster-project/farcaster-node/blob/main/docs/Usage.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-usage-md.md)

### gRPC `Make` RPC — same fields

The node also exposes a gRPC interface (`farcaster.proto`). The `MakeRequest` message mirrors the CLI exactly:

```proto
message MakeRequest {
    uint32 id = 1;
    Network network = 2;
    Blockchain accordant_blockchain = 3;
    Blockchain arbitrating_blockchain = 4;
    uint64 accordant_amount = 5;    // piconero
    uint64 arbitrating_amount = 6;  // satoshi
    string arbitrating_addr = 7;
    string accordant_addr = 8;
    uint32 cancel_timelock = 9;
    uint32 punish_timelock = 10;
    string fee_strategy = 11;       // "1500 satoshi/kvB" string
    SwapRole maker_role = 12;
    string public_ip_addr = 13;
    uint32 public_port = 14;
}
```

**Source:** [`farcaster-node/src/grpcd/proto/farcaster.proto`](https://github.com/farcaster-project/farcaster-node/blob/main/src/grpcd/proto/farcaster.proto) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-farcaster-proto.proto)

### `farcasterd.toml` — node config (amount guard rails, not pricing)

The config file (`farcasterd.toml`) does **not** set exchange rates. It configures:

- **`bind_port` / `bind_ip`** — where the peer daemon listens
- **`swap.bitcoin.{mainnet,testnet}.{min_amount, max_amount}`** — guard rails on acceptable BTC amounts (the node will refuse to create or accept deals outside these bounds)
- **`swap.monero.{mainnet,testnet}.{min_amount, max_amount}`** — guard rails on acceptable XMR amounts
- **`swap.bitcoin.{mainnet,testnet}.safety` / `finality`** — block confirmation thresholds

Default mainnet bounds (from `config.rs` constants):
- BTC: min `0.00001 BTC`, max `0.01 BTC`
- XMR: min `0.001 XMR`, max `2.0 XMR`

These bounds are **not** a rate. They define the tradeable range for each coin independently. A maker could set BTC at 0.001 and XMR at 999 and the config would allow it if those values fall within each coin's individual range.

**Source:** [`farcaster-node/farcasterd.toml`](https://github.com/farcaster-project/farcaster-node/blob/main/farcasterd.toml) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-farcasterd-toml.toml); [`farcaster-node/src/config.rs`](https://github.com/farcaster-project/farcaster-node/blob/main/src/config.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-config-rs.rs)

## How deal distribution works

Farcaster does **not** have a built-in bulletin board or discovery network. A maker's node spawns a `peerd` listener on `bind_ip:bind_port`. The serialised deal string is printed to the CLI output. Distribution is out-of-protocol — the maker copies and pastes the `Deal:...` string to wherever takers can find it (a forum, a chat room, a custom matching engine).

The RFCs explicitly acknowledge this:
> "The negotiation phase can be done on a forum, with an OTC, within a DEX, etc."

**Source:** [RFC 01 — High Level Overview](https://github.com/farcaster-project/RFCs/blob/main/01-high-level-overview.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-rfcs-01-high-level-overview.md)

A deal is **designed to be used once**. From docs/Usage.md:
> "A deal is designed to be used only once, if you want to trade with two counter-parties you must create two separate deals."

## Protocol mechanics affecting pricing

### Swap roles: Alice and Bob

- **Alice** — holds XMR (accordant chain), exchanges them for BTC. Alice's role: *sells XMR, buys BTC*.
- **Bob** — holds BTC (arbitrating chain), exchanges them for XMR. Bob's role: *sells BTC, buys XMR*.

The `maker_role` field in the deal declares which role the maker will take in the swap. The taker automatically gets the complementary role.

### Locking order: Bob locks first, then Alice

In the Farcaster protocol (per RFC 08 and the transaction graph):

1. **Bob funds first**: Bob sends BTC to a funding address, which creates the `lock (b)` transaction on Bitcoin.
2. **Alice locks second**: Once the Bitcoin lock is confirmed, Alice locks XMR on the Monero chain.
3. **Buy path**: Alice reveals a secret (via adaptor signature decryption) to claim the BTC; Bob then uses the revealed secret to claim the XMR.

This means **Bob (the BTC seller) always moves first**. Alice (the XMR seller) waits to see the BTC lock before committing her XMR.

### Free-option problem: Alice holds the option, Bob bears the risk

RFC 01 explicitly identifies the asymmetry:
> "Due to the protocol's asymmetry, Alice always locks her coins later in the swap process, implying that she gets an option to buy without cost. One way to resolve this issue is to introduce a reputation system between participants, but this is hard in a decentralized setup."
> 
> "The reputation asymmetry is not linked to the negotiation role assumed by Alice's daemon: If she's a Taker she can cancel for free on any prices and if she's a Maker she can propose any prices and cancel for free if someone tries to take it."

Farcaster **acknowledges the free-option problem but does not solve it**. There is no bond, no collateral, and no penalty for Alice backing out before she locks XMR. The timelocks (`cancel_timelock`, `punish_timelock`) protect Bob from losing BTC if Alice disappears *after* she has locked XMR — but they do not protect Bob from Alice walking away *before* she locks.

**Source:** [RFC 01 — Reputation asymmetry section](https://github.com/farcaster-project/RFCs/blob/main/01-high-level-overview.md#reputation-asymmetry) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-rfcs-01-high-level-overview.md)

### ECDSA adaptor signatures and pricing commitment

The cryptographic mechanism (RFC 07, RFC 08) uses ECDSA adaptor signatures to atomically link the revelation of Alice's Monero spend key with Bob's ability to claim the BTC. The key insight for pricing:

- Once both parties have exchanged adaptor signatures during the swap setup phase, **both amounts are locked**. There is no mechanism to renegotiate the amounts mid-swap.
- The adaptor signature construction means Alice's Monero spend key is revealed when the BTC buy transaction appears on-chain. Bob cannot claim the XMR without this key becoming public, and it only becomes public in the act of Alice claiming the BTC.
- **Pricing is committed at deal creation**, not at adaptor signature exchange. The deal's amounts are the binding commitment that both parties validate before they proceed.

### Timelocks and pricing

The `cancel_timelock` and `punish_timelock` values (CSV block counts on Bitcoin) are set by the maker. These have an indirect effect on pricing risk:

- A longer `cancel_timelock` means Alice (or a misbehaving Bob) has more time before the cancel path opens, but it also means Bob's BTC is locked for longer.
- Shorter timelocks reduce the window for aborting, which lowers — but does not eliminate — the cost of the free option.

Default values in the node: `cancel_timelock = 4 blocks`, `punish_timelock = 5 blocks` (testnet values). For mainnet, the docs recommend larger values.

## Architecture decisions relevant to maker pricing

- **Decision: Amounts encoded as absolutes, not as a rate.** The deal contains `arbitrating_amount` and `accordant_amount` as independent fields, not a single `rate` field. The ratio is implicit. This means a maker daemon building on top must compute the rate from an external source and convert it into two amounts before calling `make`. *No oracle, no spread, no dynamic adjustment is possible within a single published deal.*

- **Decision: Deal is a one-shot instrument.** A deal serves one taker exactly. To offer continuous liquidity, the maker must programmatically create new deals at the desired rate. The node provides a `revoke-deal` command to cancel an open deal.

- **Decision: `FeeStrategy` is for Bitcoin tx fees, not the swap rate.** This is a common point of confusion — the `fee_strategy` field controls how Bitcoin transactions inside the swap are fee-rated (e.g. `1500 satoshi/kvB`), not the BTC/XMR exchange rate.

- **Decision: gRPC API mirrors CLI.** The `farcaster.proto` `MakeRequest` message provides a programmatic interface for building maker daemons, with the same fields as the CLI. A maker daemon would POST a new `MakeRequest` to create each deal.

## Differentiators

- Only Farcaster explicitly decouples **TradeRole** (Maker/Taker) from **SwapRole** (Alice/Bob). A maker can choose to be Alice or Bob, allowing it to offer deals on either side of the market.
- The deal serialisation format (`Deal:` + Monero base58check) is self-contained and portable — no order book or matching engine is required; any out-of-band channel works.
- See [[../../research-maker-pricing/metrics/maker-pricing-comparison]] for cross-project comparison.

## Limitations and criticisms

### Maintenance status: effectively abandoned

- `farcaster-core` last substantive commit: **2 January 2023**.
- `farcaster-node` last substantive commit: **23 June 2023** (syncer balance fixes, PR #946); the 24 June 2023 merge is a walletd README fix only; the most recent commit (August 2024) is a `shell.nix` update with no functional change.
- Open issues: 15 on `farcaster-core`, 29 on `farcaster-node`.
- No known production deployments or live swap activity have been found. The project appears to have been abandoned before achieving production maturity.

### No built-in price discovery

There is no oracle, no price feed, no spread parameter, and no orderbook. A maker building on Farcaster must implement all price discovery externally and then manually (or programmatically) create individual deals at the computed amounts. Each deal is one-shot, so a liquid maker must create and manage many deals continuously.

### Free-option problem unresolved

Farcaster's own RFC acknowledges Alice holds a costless option and notes that a reputation system is "hard in a decentralized setup." No solution is implemented. This creates adverse selection risk for Bob (the BTC seller): Alice can monitor the BTC/XMR rate after locking begins and walk away if the rate moves against her, at no cost.

### No spread or percentage-based fee mechanism

Unlike Bisq (which has a `--spread` flag) or Haveno (which expresses price as market price +/- percentage), Farcaster exposes only raw absolute amounts. A maker daemon must implement all spread logic in application code outside of the Farcaster node.

### Single-taker deals only

Each deal can be taken by exactly one taker. Continuous market-making requires programmatic deal creation and management — there is no "standing order" concept.

### Application-layer pricing is fully delegated

Farcaster was explicitly designed as a protocol library. The RFC states the negotiation phase "does not contain any negotiation mechanism, e.g. price, amounts, etc." and that "external matching engines could implement a negotiation protocol." In practice, no such matching engine was built before the project went dormant.

## Sources

- [`farcaster-core` README](https://github.com/farcaster-project/farcaster-core) — accessed 2026-07-03 — [archived](../sources/farcaster_readme.md)
- [`farcaster-core/src/trade.rs`](https://github.com/farcaster-project/farcaster-core/blob/main/src/trade.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-core-trade-rs.rs)
- [`farcaster-core/src/blockchain.rs`](https://github.com/farcaster-project/farcaster-core/blob/main/src/blockchain.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-core-blockchain-rs.rs)
- [`farcaster-node/src/cli/opts.rs`](https://github.com/farcaster-project/farcaster-node/blob/main/src/cli/opts.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-cli-opts-rs.rs)
- [`farcaster-node/src/config.rs`](https://github.com/farcaster-project/farcaster-node/blob/main/src/config.rs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-config-rs.rs)
- [`farcaster-node/farcasterd.toml`](https://github.com/farcaster-project/farcaster-node/blob/main/farcasterd.toml) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-farcasterd-toml.toml)
- [`farcaster-node/docs/Usage.md`](https://github.com/farcaster-project/farcaster-node/blob/main/docs/Usage.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-usage-md.md)
- [`farcaster-node/src/grpcd/proto/farcaster.proto`](https://github.com/farcaster-project/farcaster-node/blob/main/src/grpcd/proto/farcaster.proto) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-node-farcaster-proto.proto)
- [RFC 01 — High-Level Overview](https://github.com/farcaster-project/RFCs/blob/main/01-high-level-overview.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-rfcs-01-high-level-overview.md)
- [RFC 10 — Public Offer](https://github.com/farcaster-project/RFCs/blob/main/10-public-offer.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-farcaster-rfcs-10-public-offer.md)
- [GitHub API — farcaster-core metadata](https://api.github.com/repos/farcaster-project/farcaster-core) — accessed 2026-07-03 — unarchived (API response)
- [GitHub API — farcaster-node metadata](https://api.github.com/repos/farcaster-project/farcaster-node) — accessed 2026-07-03 — unarchived (API response)
