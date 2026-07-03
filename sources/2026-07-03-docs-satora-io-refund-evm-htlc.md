> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Refund EVM HTLC

> Refund tokens locked in an EVM HTLC smart contract when a swap fails or times out.

## When to Refund

Refunds are needed when:

* You deposited tokens but didn't receive BTC
* The swap timed out (service didn't complete)
* Network issues prevented swap completion

***

## Check Swap Status

```ts theme={null}
const swap = await client.getSwap(swapId);
console.log("Status:", swap.status);
// ... "expired"
console.log("Direction:", swap.direction);
// ... "evm_to_lightning"
```

***

## Option 1: Collaborative Refund (Recommended)

No timelock wait required. The server cosigns the refund and submits it on-chain - gasless for you.

<Note>
  This works precisely when you have funded the EVM HTLC but the swap subsequently failed (e.g. the server couldn't pay the Lightning invoice). The server cosigns even before timelock expiry, as long as the swap is in a refundable state.
</Note>

```ts theme={null}
// Collaborative refund: the SDK signs an EIP-712 message and the
// server cosigns + submits the on-chain transaction. No gas needed.
//
// Settlement modes:
// - "swap-back": swap WBTC back to your original token (e.g. USDT) via DEX
// - "direct":    return the locked WBTC/tBTC directly
const result = await client.collabRefundEvmSwap(swapId, "swap-back");

console.log("Refund TX:", result.txHash);
// ... "0xabc123..."
console.log("Message:", result.message);
// ... "Collaborative refund submitted successfully"
```

<Info>
  `refundSwap()` defaults to `swap-back` mode. The lower-level `collabRefundEvmSwap()` defaults to `direct`. Always pass the mode explicitly to be safe.
</Info>

***

## Option 2: Timeout-Based Refund (Fallback)

If the server is unresponsive, you can refund yourself after the HTLC timelock expires (24h on mainnet).
You submit the transaction with your own EVM wallet.

```ts theme={null}
import { type EvmSigner } from "@lendasat/lendaswap-sdk-pure";

// Timeout-based refund: does NOT require server cooperation.
// The user must wait for the HTLC timelock to expire, then submit
// the refund transaction themselves with their EVM wallet.
//
// Build an EvmSigner from your wallet (see funding example for details)
declare const signer: EvmSigner; // your wallet - see EvmSigner docs

// refundEvmWithSigner handles everything: fetches calldata, sends the
// transaction, and waits for the receipt.
//
// Settlement modes:
// - "swap-back": swap WBTC back to your original token (e.g. USDT) via DEX
// - "direct":    return the locked WBTC/tBTC directly
const { txHash } = await client.refundEvmWithSigner(
  swapId,
  signer,
  "swap-back",
);

console.log("Refund TX:", txHash);
// ... "0xabc123..."
```

***

## Refund Methods Summary

| Method                       | When Available         | Server Required | Gas Required |
| ---------------------------- | ---------------------- | --------------- | ------------ |
| **Collaborative** (gasless)  | Anytime                | Yes             | No           |
| **Timeout-based** (fallback) | After timelock expires | No              | Yes          |

***

## Important Notes

<Info>
  **Try collaborative first.** It's instant and gasless. Only fall back to the timeout-based refund if the server is down.
</Info>

1. **Settlement modes** - Both methods support `"swap-back"` (receive your original token) or `"direct"` (receive WBTC/tBTC)
2. **Automatic refunds** - The server also detects expired HTLCs and processes refunds automatically in the background
3. **Gas fees** - Only the timeout-based refund requires gas (ETH/MATIC)
