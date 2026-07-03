---
tags: [project, atomic-swaps, bitcoin, evm, btc-stablecoin, lightning, ark, browser-swap, active]
ecosystem: Bitcoin (Lightning / Arkade / on-chain) ↔ EVM stablecoins (cross-chain primitive, no own chain)
category: Browser-based BTC↔EVM HTLC atomic-swap app (Ark-mediated, gasless EVM leg)
website: https://app.satora.io/
docs: https://docs.satora.io/
github: https://github.com/satorahq (mirrors https://github.com/lendasat)
launched: Lendaswap announced 2025-11-14 (Lendasat press release / Bitcoin Magazine); Satora is the consumer-facing deployment of the same protocol
---

# Satora (Lendaswap)

**Satora** ([app.satora.io](https://app.satora.io/)) is a non-custodial, no-KYC **browser app** that atomically swaps Bitcoin — via **Lightning, Arkade, or on-chain** — for ERC-20 stablecoins on EVM chains (USDC/USDT/WBTC/tBTC on Ethereum, Polygon, Arbitrum), and back. It is the consumer-facing front-end for **Lendasat's "Lendaswap"** protocol: the `github.com/satorahq` repos mirror `github.com/lendasat`, the API self-identifies as `Lendaswap API` and the SDK package is `@lendasat/lendaswap-sdk-pure`. The app generates a local 12-word BIP39 wallet in the browser — no accounts, no email — and all swap state is recoverable from that mnemonic ([docs.satora.io/index](https://docs.satora.io/index.md) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-docs-satora-io-index.md)).

The URL pattern the user asked about — `app.satora.io/lightning:BTC/42161:USDC` — is a **Lightning-BTC → Arbitrum(42161)-USDC** swap: the hardest direction, because Lightning and EVM HTLCs cannot share a preimage lock directly. Satora bridges them through an **Arkade VHTLC** intermediary. See the mechanics and refund sections below.

## Relationship to the rest of this vault

Unlike [[projects/eigenwallet]] (BTC↔XMR, adaptor signatures, no shared hash) or [[projects/zwap]] (ECDH key aggregation, no shared hash), Satora is a **classic shared-hash HTLC** design — the same 32-byte secret unlocks both legs, so the swap is on-chain-linkable by hash. Its novelty is not privacy but (a) doing browser-side atomic swaps with **no server custody**, (b) making the EVM leg **gasless** via Permit2 + EIP-712 relaying, and (c) using **Arkade (Ark protocol)** as an instant, low-fee Bitcoin-side venue that also bridges Lightning. Contrast with [[projects/comit]]'s HTLC lineage and [[projects/baltex]]'s custodial instant-swap model.

## Adoption / usage metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| Lendaswap public announcement | 2025-11-14 | 2025-11-14 | [Bitcoin Magazine](https://bitcoinmagazine.com/business/lendaswap-non-custodial-btc-stablecoin-swap-exchange-built-on-arkade) — "announced today the launch of Lendaswap" |
| Supported EVM chains | Ethereum (1), Polygon (137), Arbitrum (42161) | 2026-07-03 | [api.satora.io/evm-tokens/chains](https://api.satora.io/evm-tokens/chains) ([archived](../sources/2026-07-03-api-satora-io-chains.json)) |
| Bitcoin-side venues | Lightning, Arkade (VTXOs), on-chain (P2TR) | 2026-07-03 | [docs HTLC](https://docs.satora.io/advanced/htlc.md) ([archived](../sources/2026-07-03-docs-satora-io-htlc.md)) |
| Base protocol fee | 0.25% (BTC↔EVM); 0.10% (BTC↔Arkade) | 2026-07-03 | [api.satora.io/swap-pairs](https://api.satora.io/swap-pairs) ([archived](../sources/2026-07-03-api-satora-io-swap-pairs.json)) |
| Swap size limits | min 10,000 sats; max 13,000,000 sats (≈0.13 BTC) for BTC↔EVM; max 2,000,000 sats for Arkade legs | 2026-07-03 | same swap-pairs endpoint |
| API/build version | `developer-portal-v0.1.12` / OpenAPI `0.2.39` | 2026-07-03 | [api.satora.io/version](https://api.satora.io/version) |
| Cumulative swap volume / count | [NOT FOUND] — no public dashboard or on-chain aggregator | — | — |
| Third-party audit | [NOT FOUND] — no published audit located | — | — |

Volume/count and audit status are unverified; the marketing site and docs report neither. Flagged for the fact-check pass.

## How it works

### User perspective (Lightning BTC → Arbitrum USDC)

1. Open the app; a local wallet is derived from a 12-word seed (browser-only, no signup).
2. Pick the pair (`lightning:BTC` → `42161:USDC`), enter an amount, get a quote (base fee + network + gasless fee, all shown before confirming).
3. The app shows a **Lightning invoice** to pay. You pay it from any Lightning wallet.
4. The swap auto-progresses; USDC lands at your signed Arbitrum destination address. **You never pay EVM gas** — the server relays the claim.
5. If anything stalls, the swap-detail page exposes a **Refund** button (see below); funds are always recoverable from the seed even if the server disappears.

### System perspective — the shared-hash HTLC

The client generates a random 32-byte secret `S` and derives **two** hash locks because the two chains use different hash primitives ([docs HTLC](https://docs.satora.io/advanced/htlc.md) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-docs-satora-io-htlc.md)):

```
S         = random 32 bytes
evm_hash  = SHA256(S)                       // EVM HTLCErc20 checks sha256(preimage)
btc_hash  = HASH160(S) = RIPEMD160(SHA256(S)) // Bitcoin P2TR HTLC + Arkade VHTLC (OP_HASH160)
```

The Bitcoin-side Taproot output commits to `<server_pk> OP_CHECKSIGVERIFY OP_HASH160 <btc_hash> OP_EQUAL`. The **same `S` unlocks both legs**; only the hash function differs.

**Lightning → EVM is a three-leg chain** bridged by Arkade + Boltz ([swap/lightning/evm](https://docs.satora.io/api-reference/swap/lightning/evm.md) :: [archived](../sources/2026-07-03-docs-satora-io-swap-lightning-evm.md); flow steps quoted verbatim in [llms.txt](../sources/2026-07-03-docs-satora-io-llms.txt) lines 19, 24, 33):

1. Client provides a Lightning invoice / pays one; a **Boltz submarine swap** moves the BTC into an **Arkade VHTLC** locked under `btc_hash`.
2. Server claims the Arkade VHTLC and funds the **EVM `HTLCErc20`** on Arbitrum under `evm_hash` (locking WBTC, then DEX-routed to USDC via 1inch inside the coordinator).
3. Server pays the Lightning invoice via Boltz to obtain `S`, then uses `S` to claim the EVM HTLC. Revealing `S` on-chain is what lets the client's USDC be swept out. Atomic: the server cannot take the tokens without producing `S`, which is exactly what pays the client.

**The EVM leg is gasless.** Funding uses `HTLCCoordinator.executeAndCreateWithPermit2` (server pulls tokens via the client's **Permit2** signature, runs the DEX swap, locks the result). Claiming uses `redeemAndExecute` driven by the client's **EIP-712** signature — the server submits and pays gas, but the signature binds the claim to the coordinator as `msg.sender` and to a signed destination address, so it is front-run-safe and cannot redirect funds ([docs HTLC](../sources/2026-07-03-docs-satora-io-htlc.md), Gasless Execution section). Contracts are deployed at identical addresses on all three chains via **CREATE2**.

For **on-chain BTC ↔ EVM** (e.g. the `usdc-arbitrum-to-bitcoin-onchain-sample` CLI PoC), it collapses to two legs: EVM `HTLCErc20` ↔ Bitcoin **P2TR HTLC**, same shared `S`, BTC claimable at 0-conf ([github readme](../sources/2026-07-03-github-satorahq-usdc-arbitrum-to-bitcoin-onchain-sample-readme.md)).

### Timelocks (hardcoded, not server-configurable)

```
client-funded HTLC: current_time + 24h   (long)
server-funded HTLC: current_time + 12h   (short)
```

The client always gets the **longer** window on the leg it funds, because the client holds `S`: after the client reveals `S` to claim the server's leg, the server still has ≥12h to sweep the client's leg with the revealed secret. Which chain is "client-funded" flips by direction (BTC→EVM ⇒ BTC is client-funded; EVM→BTC ⇒ EVM is client-funded). Values come from `HtlcRefundTimeouts::new` in the SDK; only regtest can override them ([docs HTLC](../sources/2026-07-03-docs-satora-io-htlc.md), Time Lock section). Bitcoin-side expiry is evaluated against **Median Time Past (MTP)**, which the API exposes at `/mtp`.

## The refund path (the user's question)

There are **two refund routes on each leg**: a fast collaborative one (needs a cooperative-but-not-trusted server) and a unilateral timelocked fallback (needs only clock expiry). The safety guarantee rests entirely on the fallback — the collaborative path is an optimisation.

### EVM leg

- **Collaborative gasless refund (default, no wait).** The client signs a coordinator-level **`CollabRefund` EIP-712** message; the server cosigns with an HTLC-level `Refund` signature *as the `claimAddress`, waiving the timelock*, and submits on-chain. Works "precisely when you have funded the EVM HTLC but the swap subsequently failed" — even before expiry, as long as the swap is in a refundable state. Two settlement modes: `swap-back` (DEX-route WBTC back to your original token, e.g. USDT) or `direct` (return the locked WBTC/tBTC). SDK: `client.collabRefundEvmSwap(swapId, mode)` ([collab-refund-evm](https://docs.satora.io/api-reference/swap/id/collab-refund-evm.md) :: [archived](../sources/2026-07-03-docs-satora-io-collab-refund-evm.md); [Refund EVM HTLC](https://docs.satora.io/handle-failures/refund-evm-htlc.md) :: [archived](../sources/2026-07-03-docs-satora-io-refund-evm-htlc.md)).
- **Timeout-based refund (fallback, no server).** After the 24h HTLC timelock expires, the client submits `HTLCErc20.refund` / coordinator `refundAndExecute` **themselves with their own EVM wallet** (pays gas). SDK: `client.refundEvmWithSigner(swapId, signer, mode)`.

> **Refunds return to the internal wallet, not the origin.** Refunded EVM funds go to the **`client_evm_address` derived from the mnemonic**, not the address that originally sent the tokens. The user must sweep them out manually ([github readme](../sources/2026-07-03-github-satorahq-usdc-arbitrum-to-bitcoin-onchain-sample-readme.md), Refunds section).

### Arkade VHTLC leg

The client builds an **off-chain Ark transaction (`ark_tx` + checkpoints) spending the VHTLC via its `refund_script` leaf**, signs as sender, POSTs the partially-signed PSBTs; the server cosigns as receiver; the client then submits to Arkade for the third signature. There is also a `collab-refund-delegate` variant that routes through the Ark batch ceremony via `/api/delegate/settle` for recoverable (non-directly-spendable) VTXOs ([collab-refund](https://docs.satora.io/api-reference/swap/arkade-evm/id/collab-refund.md) :: [archived](../sources/2026-07-03-docs-satora-io-collab-refund-vhtlc.md); endpoint descriptions in [llms.txt](../sources/2026-07-03-docs-satora-io-llms.txt) lines 16-17).

### On-chain Bitcoin leg

Refund is only possible **after the P2TR HTLC locktime expires (24h mainnet)**. The SDK signs with the stored secret key and spends the **timelock script path** of the Taproot output to a user-supplied BTC address, minus mining fee. SDK: `client.refundSwap(swapId, { destinationAddress, feeRateSatPerVb })` ([Refund Onchain HTLC](https://docs.satora.io/handle-failures/refund-onchain-htlc.md) :: [archived](../sources/2026-07-03-docs-satora-io-refund-onchain-htlc.md)).

### Why the browser can always refund

Every refund path is signable from the **mnemonic alone** — the secret key, the VHTLC refund script, and the EVM refund authority all derive from the seed. The server being online only makes refunds *faster and gasless*; it is never *required*. If the local SQLite/state DB is lost, `/swap/recover` re-derives swap history from the wallet's Xpub (`m/9419/121923/<index>`) so the refundable swaps can be found again ([recover-swaps-from-seed](../sources/2026-07-03-docs-satora-io-recover-swaps-from-seed.md); [llms.txt](../sources/2026-07-03-docs-satora-io-llms.txt) line 35). The server additionally auto-processes expired HTLCs in the background as a convenience.

## Swap state machine

Direction-agnostic; the difference is which address each party funds. Happy path: `Pending → ClientFundingSeen → ClientFunded → ServerFunded → ClientRedeeming → ClientRedeemed → ServerRedeemed`. Note `ServerRedeemed` — not `ClientRedeemed` — is the true success terminal ([state-machine](https://docs.satora.io/advanced/state-machine.md) :: accessed 2026-07-03 :: [archived](../sources/2026-07-03-docs-satora-io-state-machine.md)).

Refund-relevant states: `Expired` (never funded, ~30 min pending timeout), `ClientRefunded` (early exit before server funded — allowed without waiting for timelock), `ClientFundedServerRefunded` (HTLC timed out, server reclaimed, client still refunds its side), `ClientRefundedServerRefunded` (both refunded, terminal). The docs also enumerate **critical edge-case states** the state machine explicitly guards — `ClientRefundedServerFunded` (client refunded but server had already funded) and `ClientRedeemedAndClientRefunded` (client both redeemed *and* refunded) — which are the atomicity-violation races an HTLC design must prevent.

## Key behaviours

- [[patterns/atomic-swaps-vs-middle-chain]] — Satora is pure peer HTLC, no middle-chain settlement; Arkade is a Bitcoin-side *venue*, not a settlement chain like [[projects/serai]]/[[projects/thorchain]].
- Shared-hash HTLC (SHA256 on EVM, HASH160 on Bitcoin/Ark) — on-chain-linkable, unlike the no-shared-hash designs in [[projects/eigenwallet]] and [[projects/zwap]].
- Gasless EVM execution via Permit2 funding + EIP-712 relayed claim/refund (server pays gas, cannot redirect funds).
- Ark/VHTLC as a Lightning bridge — Boltz submarine swaps move BTC into an Arkade VHTLC so a Lightning payment can settle an EVM HTLC.

## Architecture decisions

- **No custody, browser wallet from seed:** every leg's refund authority derives from the mnemonic, so trust in the server is bounded to liveness/speed, not fund safety.
- **Asymmetric 24h/12h timelocks:** guarantees the secret-holder (client) always has the longer window; hardcoded to remove a server-griefing vector.
- **Coordinator + Permit2 + 1inch:** lets a single gasless transaction pull tokens, DEX-route (e.g. USDC↔WBTC), and lock/redeem/refund the HTLC — this is why arbitrary EVM stablecoins are supported even though the HTLC itself holds WBTC/tBTC.
- **CREATE2 deterministic addresses:** identical contract addresses across Ethereum/Polygon/Arbitrum.

## Limitations and criticisms

- **Not private / linkable.** Shared-hash HTLC means both legs carry the same secret; amount, timing, and hash correlate the two chains. This is a different design goal from the anonymity-focused projects in this vault ([[projects/zwap]], [[projects/eigenwallet]]).
- **Server liveness still matters in practice.** Trustless refunds require *waiting out* 12–24h timelocks and *paying your own gas* (EVM) or BTC fees. The pleasant path (instant, gasless collaborative refund) needs a cooperating server; a down or adversarial server degrades UX to the slow path.
- **Mempool-congestion race (inherent to HTLCs).** Security depends on the claiming party confirming before the counterparty's refund timelock. Severe on-chain congestion on the BTC or EVM legs is the classic edge where a refunder could reclaim funds the claimer believed were theirs. The Arkade/VHTLC legs are off-chain and less exposed; the on-chain BTC and EVM legs are.
- **Refund funds land in the derived internal wallet**, not the origin address — a UX footgun requiring a manual sweep.
- **Small max size (~0.13 BTC per swap)** and reliance on **Boltz** (Lightning) and **1inch** (DEX routing) as external dependencies — availability of either affects the corresponding leg.
- **No public volume data or third-party audit located** (2026-07-03). Claims of trustlessness rest on the docs/code, not an external review.

## Sources

- [Satora app](https://app.satora.io/) — accessed 2026-07-03 — JS-rendered SPA, no static content archivable
- [docs.satora.io — Welcome / index](https://docs.satora.io/index.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-index.md)
- [docs.satora.io — HTLC](https://docs.satora.io/advanced/htlc.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-htlc.md)
- [docs.satora.io — Swap State Machine](https://docs.satora.io/advanced/state-machine.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-state-machine.md)
- [docs.satora.io — Refund EVM HTLC](https://docs.satora.io/handle-failures/refund-evm-htlc.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-refund-evm-htlc.md)
- [docs.satora.io — Refund Onchain HTLC](https://docs.satora.io/handle-failures/refund-onchain-htlc.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-refund-onchain-htlc.md)
- [docs.satora.io — Recover Swaps from Seed](https://docs.satora.io/handle-failures/recover-swaps-from-seed.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-recover-swaps-from-seed.md)
- [docs.satora.io — collab-refund-evm (API)](https://docs.satora.io/api-reference/swap/id/collab-refund-evm.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-collab-refund-evm.md)
- [docs.satora.io — collab-refund VHTLC (API)](https://docs.satora.io/api-reference/swap/arkade-evm/id/collab-refund.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-collab-refund-vhtlc.md)
- [docs.satora.io — Lightning→EVM swap (API)](https://docs.satora.io/api-reference/swap/lightning/evm.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-swap-lightning-evm.md)
- [docs.satora.io — EVM→Lightning swap (API)](https://docs.satora.io/api-reference/swap/evm/lightning.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-swap-evm-lightning.md)
- [docs.satora.io — llms.txt (full page index + flow descriptions)](https://docs.satora.io/llms.txt) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-llms.txt)
- [docs.satora.io — Security / Gasless-Fees / General FAQ](https://docs.satora.io/faq/security.md) — accessed 2026-07-03 — [archived](../sources/2026-07-03-docs-satora-io-security-faq.md), [gasless](../sources/2026-07-03-docs-satora-io-gasless-and-fees-faq.md), [general](../sources/2026-07-03-docs-satora-io-general-faq.md)
- [github.com/satorahq — usdc-arbitrum-to-bitcoin-onchain-sample README](https://github.com/satorahq/usdc-arbitrum-to-bitcoin-onchain-sample) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-satorahq-usdc-arbitrum-to-bitcoin-onchain-sample-readme.md)
- [github.com/satorahq — lendaswap-contracts README](https://github.com/satorahq/lendaswap-contracts) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-satorahq-lendaswap-contracts-readme.md)
- [github.com/satorahq — lendaswap-sdk README](https://github.com/satorahq/lendaswap-sdk) — accessed 2026-07-03 — [archived](../sources/2026-07-03-github-satorahq-lendaswap-sdk-readme.md)
- [api.satora.io/evm-tokens/chains](https://api.satora.io/evm-tokens/chains) — accessed 2026-07-03 — [archived](../sources/2026-07-03-api-satora-io-chains.json)
- [api.satora.io/swap-pairs](https://api.satora.io/swap-pairs) — accessed 2026-07-03 — [archived](../sources/2026-07-03-api-satora-io-swap-pairs.json)
- [Lendasat whitepaper (PDF)](https://whitepaper.lendasat.com/lendasat-whitepaper.pdf) — accessed 2026-07-03 — [archived](../sources/2026-07-03-whitepaper-lendasat-com-lendasat-whitepaper.pdf) — covers the Lendasat lending protocol; Lendaswap is the swap spin-out
- [Bitcoin Magazine — Lendaswap launch](https://bitcoinmagazine.com/business/lendaswap-non-custodial-btc-stablecoin-swap-exchange-built-on-arkade) — published 2025-11-14, accessed 2026-07-03 — [archived](../sources/2026-07-03-bitcoinmagazine-com-lendaswap-launch.html)
