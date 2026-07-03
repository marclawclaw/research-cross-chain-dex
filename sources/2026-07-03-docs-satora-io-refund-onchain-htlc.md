> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Refund Onchain HTLC

> Refund funds locked in an onchain Bitcoin HTLC when a swap fails or times out.

<Warning>
  **Locktime Required:** Refunds are only possible AFTER the HTLC locktime expires. This is typically 24 hours after swap creation on mainnet.
</Warning>

## When to Refund

Refunds are typically needed when:

* The swap status is `expired` (no funding was received before timeout)
* The service didn't respond to your BTC payment
* You want to recover funds from an incomplete swap

***

## Check Swap Status

```ts theme={null}
const swap = await client.getSwap(swapId);
console.log("Status:", swap.status);
// ... "expired"
```

***

## Refund Onchain HTLC

```ts theme={null}
// Build and broadcast the refund transaction.
// The SDK signs with the stored secret key and spends from
// the timelock path of the Taproot HTLC.
const result = await client.refundSwap(swapId, {
  destinationAddress: "bc1q...", // Your Bitcoin address to receive the refund
  feeRateSatPerVb: 5, // Fee rate
});

if (!result.success) {
  throw new Error(`Refund failed: ${result.message}`);
}

console.log("Refund TX broadcast:", result.broadcast);
// ... true
console.log("Transaction ID:", result.txId);
// ... "a1b2c3..."
console.log("Refund amount:", result.refundAmount, "sats");
// ... 99500n sats (original minus mining fee)
console.log("Mining fee:", result.fee, "sats");
// ... 500n sats
```

***

## Important Notes

<Info>
  **Onchain Fees:** Refunding an onchain HTLC requires paying Bitcoin network fees.
</Info>

1. **Longer locktimes** - Onchain HTLCs have longer locktimes (24h on mainnet) than VHTLCs
2. **Network fees** - You'll pay standard BTC transaction fees for the refund
