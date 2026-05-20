---
tags: [pattern, cross-chain-dex, settlement, architecture]
status: established
---

# Pattern: Middle-chain swap settlement

A purpose built Layer 1 sits between two or more external blockchains that cannot communicate with each other. The middle chain runs the order matching / AMM logic, custodies external assets in TSS vaults on each foreign chain, and broadcasts outbounds back. Users send a native asset on chain A with a memo, receive a native asset on chain B. The middle chain never mints wrapped or pegged tokens.

## Core components

1. **Settlement chain**: a Cosmos SDK / Substrate / custom L1 with its own validator set and consensus (Tendermint/CometBFT, BABE+GRANDPA, etc.).
2. **Cross chain daemon per validator**: an off-chain process per node that watches every external chain for inbounds to the active vault address(es) and gossips observations into consensus.
3. **Confirmation policy**: per chain finality assumptions; UTXO and EVM chains use value scaled confirmation counts to bound re-org risk.
4. **TSS vaults**: see [[tss-custody-vault]]. Custody one shared public key per foreign chain, sharded if needed.
5. **AMM or order book**: pool state lives on the middle chain; pricing math runs in deterministic state transitions; see [[slip-based-fees]] for the slip-based fee variant.
6. **Outbound queue and signer**: the state machine produces TxOut messages, assigns them to vaults, the assigned members run a TSS keysign ceremony, the resulting standard signature is broadcast to the destination chain.
7. **Churn or rotation**: periodic validator set changes trigger fresh keygens and full migrations between vault addresses.

## Reference: Thorchain end to end flow

1. User front end produces a memo `SWAP:ETH.ETH:0xDest:LIM:AFFILIATE:FEE` ([memos](https://dev.thorchain.org/concepts/memos.html)).
2. User broadcasts an inbound on the source chain (Bitcoin OP_RETURN, Ethereum calldata, etc.) addressed to the active Asgard vault.
3. Each node's Bifrost observer ([Bifrost](https://dev.thorchain.org/bifrost/how-bifrost-works.html)) sees the transaction, applies confirmation counting if the chain has delayed finality, and posts a `MsgObservedTxIn`.
4. 67 percent of observations must agree before the state machine accepts the inbound.
5. CLP math executes against the source pool, routes through RUNE, credits the destination pool. Fee is slip-based ([CLP docs](https://docs.thorchain.org/technical-documentation/thorchain-finance/continuous-liquidity-pools.md)).
6. State machine queues a `TxOut`. Outbound may sit up to 720 blocks (~1 hour) unless Swapper Clout reduces the delay ([delays](https://dev.thorchain.org/concepts/delays.html)).
7. Assigned vault members run a GG20 keysign and broadcast the outbound on the destination chain.

## Why a middle chain rather than direct bridge plus DEX

- Single validator set is on the hook for both bridge security and DEX correctness; bond can be jointly slashed.
- Native asset to native asset: no wrapped IOU representations propagate to downstream protocols (a Wormhole BTC.b is not Bitcoin; a Thorchain BTC outbound is real BTC).
- Pool state and inbound observations are both on the same chain, so atomic execution is straightforward.
- Foreign chains see only standard transactions; no contract deployments required (Bitcoin, Litecoin, Dogecoin, XRP all supported by Thorchain because the chain just needs to accept arbitrary signed transactions).

## Constraints

- **Latency floor**: bounded by the slower foreign chain's confirmation requirements. BTC->ETH on Thorchain is dominated by ~10 minute Bitcoin confirmations plus outbound delay.
- **Liquidity gravity**: pools must be funded on the middle chain, which means LPs must trust the middle chain consensus and TSS implementation.
- **Single chain of failure**: middle chain bug halts the entire DEX, but a Wormhole style attestation bug only affects bridged tokens.
- **Privacy**: memos make every cross chain swap publicly traceable end to end. This is the gap an anonymity oriented middle chain (LEZ) could address.

## Reference: Serai end-to-end flow

1. User encodes an In Instruction in a SCALE-Shorthand form, embedded in the source-chain transaction (Bitcoin `OP_RETURN` up to 80 bytes; Ethereum router calldata or ERC20 calldata; Monero `tx.extra` with `TX_EXTRA_NONCE` up to 254 bytes). Source: [Serai integration specs](https://github.com/serai-dex/serai/tree/develop/spec/integrations) (accessed 2026-05-19).
2. Each validator's per-network Processor scans finalised blocks for outputs to the active multisig key. Only blocks with at least `CONFIRMATIONS` confirmations are operated upon. Source: [Scanning spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Scanning.md) (accessed 2026-05-19).
3. Processors build a Batch, threshold-sign it with the network's Ristretto reporting key, and the Coordinator publishes it as an unsigned Serai transaction. Substrate verifies the threshold signature in O(1). Source: [In Instructions spec](https://github.com/serai-dex/serai/blob/develop/spec/protocol/In%20Instructions.md), [Coordinator spec](https://github.com/serai-dex/serai/blob/develop/spec/coordinator/Coordinator.md) (accessed 2026-05-19).
4. The Shorthand expands into a Dex instruction; Serai's xy=k AMM (all pools paired against SRI) executes the swap. Source: [AMM docs](https://docs.serai.exchange/amm/) (accessed 2026-05-19).
5. An Out Instruction emits a Burn; the destination-network Processor schedules a payment, FROST threshold-signs it, and broadcasts it to the destination chain. Source: [Processor spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/Processor.md) (accessed 2026-05-19).
6. UTXO chains: outbound bundling uses logarithmic-tree amortised fees; outputs from one tick all become spendable in the next tick. Source: [UTXO Management spec](https://github.com/serai-dex/serai/blob/develop/spec/processor/UTXO%20Management.md) (accessed 2026-05-19).

Notable differences vs Thorchain: separate per-network keys (not a single Asgard); per-network staking; FROST rather than GG20; xy=k rather than slip-based CLP pricing; consensus is Substrate (BABE+GRANDPA family) rather than CometBFT.

## Used by

- [[../projects/thorchain]] (Cosmos SDK, GG20 TSS)
- [[../projects/serai]] (Substrate, FROST across Secp256k1/Ed25519/Ristretto, pre-mainnet as of mid-2026)

## Contrast with

- [[../projects/wormhole]]: attestation bridge only; emits signed messages but does not match swaps or host pools.

## See also

- [[tss-custody-vault]]
- [[slip-based-fees]]
