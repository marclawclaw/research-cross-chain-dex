---
tags: [pattern, privacy, hardware]
seen_in: [secret-network]
---

# TEE-Based Privacy

Trusted execution environments (TEEs) are hardware-isolated processor regions (e.g., Intel SGX, ARM TrustZone) that protect code and data from the host operating system, hypervisor, and even physical attackers. In blockchain contexts, TEEs enable private smart contract execution: contract state is encrypted outside the enclave and decrypted only inside, where computation occurs.

## Implementations

- **[[projects/secret-network]]:** Uses Intel SGX enclaves on validator nodes. Contract code and state are encrypted on-chain; validators run SGX hardware to decrypt and execute inside the enclave. A distributed key generation protocol shares the master key among validators.
- **Oasis Network:** Also uses Intel SGX for its "ParaTime" execution layer, separating consensus from private computation.
- **Phala Network:** A Polkadot parachain using SGX for confidential computing, with a stronger focus on off-chain computation.

## Relevance to Logos

TEE-based privacy offers general-purpose programmable privacy with relatively low computational overhead compared to ZK proofs. However, it introduces significant trust assumptions: Intel's supply chain, SGX vulnerability history, and the limited validator set that can afford SGX hardware. For LEZ, TEEs could be one layer of a defence-in-depth strategy (e.g., encrypting state at rest) but should not be the sole privacy mechanism. Combining TEEs with cryptographic privacy (zkVM, MPC) could provide stronger guarantees.
