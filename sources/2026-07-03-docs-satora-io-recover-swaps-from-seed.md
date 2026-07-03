> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Recover Swaps from Seed

> Restore and recover pending swaps using your mnemonic seed phrase.

<Warning>
  **Backup Your Mnemonic:** Always store your mnemonic seed phrase securely.
  It's the only way to recover funds if you lose access to your device.
</Warning>

## When to Use Recovery

Recovery is needed when:

* You cleared browser data (IndexedDB) or app storage
* You're moving to a new device
* App reinstallation cleared local storage
* You want to check for missed swaps
* Testing or debugging swap issues

***

## Recover Swaps

Use the xpub derived from your mnemonic to query the API for associated swaps:

```ts theme={null}
import {
  Client,
  IdbSwapStorage,
  IdbWalletStorage,
} from "@lendasat/lendaswap-sdk-pure";

// Initialize client with your mnemonic
const client = await Client.builder()
  .withSignerStorage(new IdbWalletStorage())
  .withSwapStorage(new IdbSwapStorage())
  .withMnemonic("your twelve word mnemonic phrase ...")
  .build();

// Recover all swaps from the server
const recovery = await client.recoverAllSwaps();
console.log(`Recovered ${recovery.swaps.length} swaps`);

if (!recovery.complete) {
  console.warn("Recovery stopped before completion:", recovery.errorMessage);
  console.warn("Successful scans:", recovery.scans);
  console.warn("Scanned until:", recovery.scannedUntil);
}
```

***

## Best Practices

<Info>
  **Regular Backups:** While recovery from seed works, having regular exports of your swap data can speed up the recovery process.
</Info>

1. **Secure your mnemonic** - Store it offline in multiple secure locations
2. **Test recovery** - Periodically verify you can recover with your seed
3. **Act quickly** - Recovered swaps may have time-sensitive actions
4. **Check all statuses** - Don't assume swaps are complete without verifying
5. **Keep records** - Export swap data periodically for faster recovery
