This PR introduces a change in the atomic swap protocol to discourage spam. It does so by attaching a fee to refunds. This fee will be burnt.

# Current situation

The exchange rate of each swap is set at the start and can't be changed.
A swap either completes within 12 hours (this requires cooperation by both parties), or be cancelled. 
A swap might still be cancelled after both parties lock their respective currency.

In that case the taker ("Bob") can issue a refund within a 24 hours window. He will get his Bitcoin back and the maker ("Alice") will get her Monero back. 

# The problem 

This can be abused by malicious takers in two ways:
 1. A maker with significantly higher reserves than other makes might use part of it to block other maker's reserves. 
    This is possible by initiating a swap and waiting for the maker to lock the Monero. 
    Then not continue the swap and wait for a refund. 
    This will only cost the malicious actor transaction fees for 3 Bitcoin transactions, while preventing the "small maker" from competing in the market for trading volume.
2. A malicous actor might start a swap and decide only to complete it when the exchange rates change in their favor enough. 
    If that doesn't happen they can refund for the low cost of 3 Bitcoin transactions. 
    This allows the malicious actor to treat the swap like a (bascially) free Monero call option. 

# The solution

The root problem causing both these issues is that refunds are free (for the taker). 
By attaching a cost to refunds (only refunding a part of the Bitcoin) this is no longer the case.
Thus both tactics are no longer profitable. 

Makers will be able to set the extend of the refund fee. Takers will know the refund fee prior to starting a swap and decide whether to trade or not.

The refund fee does _not_ go to the maker. That would create skewed incentives. The refund fee will be "burnt". The only way to retrieve it is for the maker to sign a transaction giving it back to the taker. 

```
                                ┌─────────────────────────────────┐
                                │            TxLock               │
                                │             (Bob)               │
                                ├─────────────────────────────────┤
                                │             [A+B]               │
                                └───────────────┬─────────────────┘
                                                │
                          ┌─────────────────────┴─────────────────────┐
                          │                                           │
                          │                              timelock 12h │
                          ▼                                           ▼
          ┌───────────────────────────────┐           ┌───────────────────────────────┐
          │           TxRedeem            │           │          TxCancel             │
          │           (Alice)             │           │         (Alice/Bob)           │
          ├───────────────────────────────┤           ├───────────────────────────────┤
          │        to Alice [A]           │           │             [A+B]             │
          └───────────────────────────────┘           └───────────────┬───────────────┘
                                                                      │
                                  ┌───────────────────────────────────┼───────────────────────────────────┐
                                  │                                   │                                   │
                     timelock 24h │                                   │                                   │
                                  ▼                                   ▼                                   ▼
          ┌───────────────────────────────┐   ┌───────────────────────────────┐   ┌───────────────────────────────┐
          │          TxPunish             │   │        TxFullRefund           │   │       TxPartialRefund         │
          │           (Alice)             │   │            (Bob)              │   │            (Bob)              │
          ├───────────────────────────────┤   ├───────────────────────────────┤   ├───────────────────────────────┤
          │        to Alice [A]           │   │         to Bob [B]            │   │  to Bob [B] | Deposit [A+B]   │
          └───────────────────────────────┘   └───────────────────────────────┘   └────────────────────┬──────────┘
                                                                                                       │
                                                                            ┌──────────────────────────┴──────────────────────────┐
                                                                            │                                                     │
                                                             timelock 30min │                                                     │
                                                                            ▼                                                     ▼
                                                              ┌───────────────────────────────┐               ┌───────────────────────────────┐
                                                              │          TxReclaim            │               │         TxWithhold            │
                                                              │            (Bob)              │               │           (Alice)             │
                                                              ├───────────────────────────────┤               ├───────────────────────────────┤
                                                              │         to Bob [B]            │               │            [A+B]              │
                                                              └───────────────────────────────┘               └───────────────┬───────────────┘
                                                                                                                              │
                                                                                                                              ▼
                                                                                                              ┌───────────────────────────────┐
                                                                                                              │           TxMercy             │
                                                                                                              │           (Alice)             │
                                                                                                              ├───────────────────────────────┤
                                                                                                              │         to Bob [B]            │
                                                                                                              └───────────────────────────────┘
```

<!-- Reviewable:start -->
- - -
This change is [<img src="https://reviewable.io/review_button.svg" height="34" align="absmiddle" alt="Reviewable"/>](https://reviewable.io/reviews/eigenwallet/core/675)
<!-- Reviewable:end -->

