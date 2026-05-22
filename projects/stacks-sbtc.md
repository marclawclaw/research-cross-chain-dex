---
tags: [project, bitcoin-l2, sbtc, two-way-peg, signer-federation]
ecosystem: Bitcoin + Stacks L2
category: Bitcoin-pegged asset on Stacks
website: https://www.stacks.co/sbtc
docs: https://docs.stacks.co/concepts/sbtc
launched: Mainnet deposits 2024-12-17; withdrawals planned for March 2025 (per stacks.co)
---

# sBTC (Stacks)

sBTC is a 1:1 Bitcoin-backed asset on the Stacks L2, used in DeFi and dApps on Stacks. Custody of the underlying BTC sits with a multi-signer federation; users mint sBTC by sending BTC into the federation-controlled UTXO and redeem sBTC by burning it and triggering a peg-out signed by the federation. This note exists to source the bundle's claim that sBTC is *"redeem-to-underlying with custody"*.

## Custody arrangement

- **Phase 1 (current, since 2024-12-17 mainnet deposit launch)**: 15 community-elected independent signing entities form the sBTC Signer Set. **70% threshold** (11 of 15) required to sign sBTC operations (peg-in / peg-out). Signers include Figment, Blockdaemon, Kiln, Chorus One, Asymmetric Research and others ([Hiro blog: Who are the sBTC signers, breaking down SIP-028](https://www.hiro.so/blog/who-are-the-sbtc-signers-breaking-down-sip-028) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-hiro-so-sbtc-signers-sip-028.html)).
- **Note on current operating count**: as of 2025, the elected operating set is 14 signers (still 70% threshold = 10 of 14) — same source. Treat 15/11 as the SIP-028 design and 14/10 as the current operating reality.
- **Phase 3 (planned)**: signer set becomes open, permissionless, rotating, and integrated with Stacks Proof-of-Transfer (PoX) consensus. The 70% threshold remains; the set size is variable.
- **Custody mechanism**: each signer holds one key to a multisig UTXO address on Bitcoin. The sBTC docs link to a "signer wallet rotation" mechanism but the public docs (as of 2026-05-22) do not specify the exact cryptographic primitive (FROST vs simple multisig); the Hiro blog phrasing is "each holds one key to the multisig UTXO address", suggesting Bitcoin script multisig rather than a single Schnorr threshold key.

## Redemption / peg-out

- **Withdrawal latency**: 6 Bitcoin blocks (~1 hour) per Hiro blog citing SIP-028. This is the minimum wait to release BTC back to the requester.
- **Queue / market-clearing shape**: the public docs (as of 2026-05-22) do not state explicitly whether peg-outs are FIFO, batched, or market-clearing. The mechanism is "the requester burns sBTC on Stacks, the signers detect the burn event, the signers collectively sign a BTC release transaction from the multisig UTXO". There is no public statement of an SLA, but a 6-block confirmation requirement implies a per-block batching window.
- **Bundle citation is correct in shape**: sBTC IS redeem-to-underlying with custody. The custody is a 15-signer (operating 14) federation with 70% threshold, not a single custodian.

## BTC-side privacy property

- **No specific privacy property**: peg-out releases BTC from a publicly-known multisig UTXO address to the requester's address. The destination address is therefore on-chain-visible at peg-out time. There is no mixing layer, no routing, no shielded address. This is the same shape as Wormhole TBTC or any other federation-multisig bridge.
- **The privacy ceiling is the requester's destination address choice** — if the requester uses a fresh address generated only for this peg-out, transaction-graph analysis still links the federation UTXO to the redeemed address. There is no protocol-level privacy claim from sBTC.

## Mechanism (brief)

### User perspective (peg-in / mint sBTC)
1. Send BTC to the sBTC signer multisig UTXO address with an OP_RETURN payload identifying the destination Stacks address.
2. Wait for 6 Bitcoin confirmations.
3. The Stacks chain mints 1:1 sBTC at the destination address once the signers attest the deposit.

### User perspective (peg-out / burn sBTC)
1. Initiate a withdrawal on Stacks, specifying the BTC destination address.
2. Burn sBTC on Stacks (locks it in the protocol).
3. Wait for the signer set to sign the BTC release transaction from the multisig UTXO.
4. Receive BTC after ~6 Bitcoin blocks.

### Protocol perspective
- The signer set runs nodes on both Stacks and Bitcoin; they detect peg-in events on Bitcoin and peg-out events on Stacks.
- Coordinated signing uses Bitcoin's standard multisig (15-of-15 script with 11 signatures required, per the 70% rule).
- Liveness: if more than 30% (5 of 15) signers go offline simultaneously, peg-outs halt. This is the standard signer-federation failure mode (see [[patterns/signer-federation-trust]]).

## Differentiators

- **vs [[projects/wormhole]]**: Wormhole is a 19-of-19 (originally 13/19 majority) guardian attestation bridge for arbitrary message passing; sBTC is a 15-signer (11/15) custody federation for BTC ↔ sBTC specifically. Same family of trust assumption; different signer-count and scope.
- **vs Thorchain BTC custody ([[projects/thorchain]])**: Thorchain uses TSS with 67% threshold of the global RUNE-bonded validator set, currently ~150 validators; sBTC uses a curated 15-signer multisig at 70% threshold. Thorchain's vault is much larger and slashable via bonded stake; sBTC signers are reputation-bonded rather than stake-bonded (no on-chain bond slashed for signer misbehaviour, though SIP-028 election criteria provide governance-side filtering).
- **vs adaptor-signature swaps ([[projects/eigenwallet]])**: sBTC has BTC custody and a fixed signer set; eigenwallet has no custody at all and matches per-swap peer-to-peer. Different family; sBTC is a peg-asset bridge, eigenwallet is a swap primitive.

## Limitations and criticisms

- **Custody risk**: a 30%+ collusion or compromise of the signer set can move all BTC out of the multisig UTXO. Mitigated by the diversity of signer organisations.
- **Phase-3 dependency**: full decentralisation depends on Phase 3 (open permissionless signer set tied to PoX). As of 2026-05-22, the phase rollout is still in progress; deposits are live (since 2024-12-17), withdrawals are reported as planned for March 2025.
- **No protocol-level privacy**: same as any other custody-federation bridge.

## Sources

- [Stacks: sBTC product page](https://www.stacks.co/sbtc) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-stacks-co-sbtc.html)
- [Hiro blog: Who are the sBTC signers, breaking down SIP-028](https://www.hiro.so/blog/who-are-the-sbtc-signers-breaking-down-sip-028) :: accessed 2026-05-22 :: [archived](../sources/2026-05-22-hiro-so-sbtc-signers-sip-028.html)
- [sBTC: Design of a Trustless Two-way Peg for Bitcoin (Stacks design doc)](https://stacks-network.github.io/stacks/sbtc.html) :: accessed 2026-05-22 (not separately archived — Stacks-hosted GitHub Pages)
- [SIP-028: sBTC Signer Criteria](https://github.com/stacksgov/sips/blob/master/sips/sip-028/sip-028-sbtc_peg.md) :: accessed 2026-05-22 (not separately archived — repo readme)
