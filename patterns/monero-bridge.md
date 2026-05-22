---
tags: [pattern, privacy, bridge, monero]
seen_in: [secret-network]
---

# Monero Bridge

A Monero bridge connects the Monero blockchain (the strongest privacy-focused L1, using ring signatures and stealth addresses) to another chain or ecosystem, enabling XMR holders to access DeFi, smart contracts, or other programmable features while preserving as much privacy as possible.

## Implementations

- **[[projects/secret-network]]:** The Secret Monero Bridge (launched August 2021) converts XMR into sXMR, a SNIP-20 token on Secret Network. It uses a multi-signature Monero wallet controlled by consensus node operators who communicate over the I2P anonymous network. The bridge was controversial due to its trusted operator model, poor UX (email/Discord required), and scepticism from the Monero community. Its current operational status is unclear.

## Relevance to Logos

A Monero bridge represents the frontier of privacy interoperability: connecting the most private L1 to a programmable privacy ecosystem. For LEZ, a Monero bridge could enable:
- Private cross-chain swaps where XMR is one leg
- Shielded liquidity from Monero holders entering LEZ DeFi
- A private store of value that users can swap into and out of without revealing amounts or counterparties

Key requirements for a LEZ Monero bridge:
- **Trust minimisation:** Unlike Secret's trusted operator set, LEZ should use threshold signatures, bonded collateral, or ZK proofs to reduce trust assumptions.
- **UX parity with Monero:** No email, Discord, or KYC requirements. Bridge interactions should be as private as Monero itself.
- **Economic security:** Operators should post collateral that can be slashed for misbehaviour, similar to Thorchain or Serai models.
- **Privacy preservation:** Bridge deposits/withdrawals should not create linkable transaction graphs. Decoy transactions, delayed finality, or mixing could help.
