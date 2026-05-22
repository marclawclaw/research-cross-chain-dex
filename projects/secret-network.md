---
tags: [project, cosmos, privacy, smart-contracts, tee]
ecosystem: Cosmos SDK
category: Privacy/Smart Contracts
website: https://scrt.network
docs: https://docs.scrt.network
launched: 2020
---

# Secret Network

Secret Network is a Cosmos SDK-based L1 that enables programmable privacy for smart contracts via trusted execution environments (TEEs). Contracts run inside Intel SGX enclaves, where computation occurs on encrypted data that remains hidden from validators and the public. Users interact with "secret contracts" using viewing keys for selective disclosure.

## Adoption metrics

| Metric | Value | Date | Source |
|--------|-------|------|--------|
| TVL (total) | ~$8M | 2026-05-22 | [DeFiLlama: Secret](https://defillama.com/chain/Secret) |
| Daily transactions | ~2,000-5,000 | 2026-05-22 | [Mintscan Secret](https://www.mintscan.io/secret) |
| Active addresses | ~1,500-3,000 | 2026-05-22 | [Mintscan Secret](https://www.mintscan.io/secret) |
| SCRT price | ~$0.15 | 2026-05-22 | [CoinGecko](https://www.coingecko.com/en/coins/secret) |
| Market cap | ~$45M | 2026-05-22 | [CoinGecko](https://www.coingecko.com/en/coins/secret) |
| Validator count | ~70 | 2026-05-22 | [Mintscan Secret](https://www.mintscan.io/secret) |
| SNIP-20 tokens | 50+ | 2026-05-22 | [Secret Dashboard](https://dashboard.scrt.network) |

## How it works

### User perspective

1. User holds SCRT (the public gas token) and optionally wrapped assets via IBC or bridges.
2. User interacts with a secret contract (e.g., Shade Swap, Sienna Lending) by sending encrypted inputs.
3. The contract executes inside a TEE enclave on the validator node; inputs are decrypted only inside the enclave.
4. Contract state is stored encrypted on-chain; only the contract's enclave can decrypt it.
5. User can generate a viewing key to share selective disclosure of their balances or transaction history with third parties.

### Protocol perspective

- **TEE enclaves (Intel SGX):** Validators run SGX-enabled hardware. Contract code and data are encrypted outside the enclave and decrypted only inside.
- **Key management:** A distributed key generation protocol (shared among validators) creates the master encryption key for contract state. Key shares are stored inside enclaves.
- **Encrypted state:** All contract state is stored as ciphertext on-chain. The enclave decrypts state on read, computes, and re-encrypts on write.
- **Viewing keys:** Users derive keys from their wallet seed to decrypt their own data. These can be shared for selective transparency (e.g., tax reporting, auditing).
- **SNIP-20 standard:** A privacy-preserving token standard (analogous to ERC-20) where balances and transfers are encrypted by default.
- **IBC integration:** Secret Network connects to the Cosmos ecosystem via IBC, enabling private cross-chain messaging and asset transfers.
- **Ethereum bridge:** A bidirectional bridge (Secret Ethereum Bridge) allows ERC-20 assets to be wrapped as privacy-preserving SNIP-20 tokens on Secret.

## Key behaviours

- [[patterns/tee-based-privacy]] — computation inside hardware enclaves
- [[patterns/encrypted-smart-contracts]] — contract state encrypted by default
- [[patterns/viewing-keys]] — selective disclosure via user-derived keys
- [[patterns/private-tokens]] — SNIP-20 privacy-preserving token standard
- [[patterns/cross-chain-privacy]] — IBC and bridge-based private asset wrapping

## Architecture decisions

- **TEE over ZK/cryptography:** Chose hardware-based privacy (SGX) rather than zero-knowledge proofs or MPC. This enables general-purpose programmable privacy but introduces hardware trust assumptions.
- **Cosmos SDK:** Benefits from IBC interoperability and the Cosmos validator set model, but inherits Cosmos governance and upgrade patterns.
- **Public gas token (SCRT):** Gas fees are paid in a public token, while contract interactions are private. This creates a metadata leak (who pays gas for what contract).
- **Viewing key opt-in:** Privacy is default but reversible via viewing keys, balancing privacy with compliance/auditability.
- **SGX dependency:** Requires validators to run Intel SGX hardware, limiting validator diversity and creating a supply-chain centralisation risk.

## Differentiators

- **General-purpose private smart contracts:** Unlike Zcash or Monero (private transfers only), Secret enables private DeFi: private AMMs, private lending, private NFTs.
- **Composable privacy:** Secret contracts can call each other while maintaining privacy, enabling complex private DeFi strategies.
- **Cosmos ecosystem integration:** IBC connectivity means Secret can provide privacy as a service to other Cosmos chains (e.g., private Osmosis swaps via IBC).
- **Viewing key flexibility:** Users control disclosure granularity, a feature most privacy chains lack.
- **Ethereum asset privacy:** The Secret Ethereum Bridge brings privacy to existing ERC-20 assets without migrating liquidity.

## Limitations and criticisms

- **TEE trust assumptions:** Intel SGX has suffered multiple vulnerabilities (Foreshadow, Plundervolt, SGAxe). A compromised enclave breaks the entire privacy model.
- **Centralisation risk:** SGX hardware is manufactured by Intel, creating a supply-chain dependency. Only ~70 validators run the network, and SGX requirements limit participation.
- **Performance overhead:** Enclave context switches and encryption/decryption add latency. Contract execution is slower than on non-TEE chains.
- **Gas metadata leak:** While contract state is private, gas payments in public SCRT reveal which user interacted with which contract and when.
- **Bridge risk:** The Secret Ethereum Bridge and IBC connections introduce bridge vulnerabilities (the Wormhole exploit demonstrated this class of risk).
- **Low DeFi traction:** Despite being live since 2020, TVL remains low (~$8M) compared to mainstream DeFi protocols. Privacy DeFi has not found product-market fit at scale.
- **Regulatory uncertainty:** Privacy-preserving smart contracts face the same regulatory headwinds as privacy coins; exchanges have delisted SCRT in some jurisdictions.
- **Upgrade complexity:** TEE-based systems require remote attestation and key rotation on upgrades, adding operational complexity.

## Sources

- [Secret Network Documentation](https://docs.scrt.network) — accessed 2026-05-22
- [Secret Network Whitepaper](https://scrt.network/whitepaper) — accessed 2026-05-22
- [DeFiLlama: Secret](https://defillama.com/chain/Secret) — accessed 2026-05-22
- [Mintscan: Secret Network](https://www.mintscan.io/secret) — accessed 2026-05-22
- [CoinGecko: Secret (SCRT)](https://www.coingecko.com/en/coins/secret) — accessed 2026-05-22
- [Secret Network Blog: TEE Security](https://scrt.network/blog) — accessed 2026-05-22
- [Sienna Network Documentation](https://docs.sienna.network) — accessed 2026-05-22
- [Shade Protocol Documentation](https://docs.shadeprotocol.io) — accessed 2026-05-22
