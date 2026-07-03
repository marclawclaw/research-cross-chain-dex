> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Hash Time-Locked Contracts (HTLC)

> How HTLCs enable trustless atomic swaps

Hash Time-Locked Contracts (HTLCs) are the foundation of Satora Swaps' atomic swap protocol. They enable trustless, conditional payments across blockchains.

## What is an HTLC?

An HTLC is a smart contract that locks funds with two conditions:

1. **Hash Lock**: Funds can be claimed by revealing a secret (preimage)
2. **Time Lock**: Funds are automatically refunded after a timeout

This combination enables atomic swaps without requiring trust between parties.

***

## How It Works

### Hash Lock

```
secret    = random 32 bytes
evm_hash  = SHA256(secret)                  // EVM HTLC (HTLCErc20)
btc_hash  = HASH160(secret)                 // = RIPEMD160(SHA256(secret))
                                            // on-chain BTC HTLC + Arkade VHTLC
```

* Only the party with the secret can claim funds
* The same 32-byte secret unlocks both sides; only the hash function differs:
  * **EVM HTLC** verifies `sha256(preimage) == preimageHash` (32-byte digest)
  * **Bitcoin on-chain HTLC and Arkade VHTLC** use `OP_HASH160`, i.e. `RIPEMD160(SHA256(preimage)) == hashLock` (20-byte digest)
* 32-byte secret = 2^256 possible values (cryptographically secure)

### Time Lock

```
timelock_client = current_time + 24 hours  // client-funded HTLC (long)
timelock_server = current_time + 12 hours  // server-funded HTLC (short)
```

* **Before timeout:** Only recipient can claim with secret
* **After timeout:** Sender can refund (no secret needed)

The long timeout always applies to the chain the **client** funds, because the client holds the secret and must always have a longer refund window than the server. The mapping depends on the swap direction:

| Direction  | Client funds (locks \~24h) | Server funds (locks \~12h) |
| ---------- | -------------------------- | -------------------------- |
| BTC -> EVM | BTC HTLC                   | EVM HTLC                   |
| EVM -> BTC | EVM HTLC                   | BTC HTLC                   |

These values are hardcoded per network in the SDK (`HtlcRefundTimeouts::new`): 24h client / 12h server on Bitcoin mainnet. Regtest can override via `LENDASWAP_REGTEST_CLIENT_TIMEOUT_SECS` / `LENDASWAP_REGTEST_SERVER_TIMEOUT_SECS`. They are not server-configurable in production.

***

## Contract Architecture

Satora Swaps uses a two-contract architecture on each EVM chain (Polygon, Ethereum, Arbitrum):

**HTLCErc20** - The core HTLC contract that holds ERC-20 tokens. Supports:

* Direct claiming by the designated claim address
* EIP-712 signature-based claiming for gasless execution (`redeemBySig`)
* Refund to sender or explicit destination after timelock

**HTLCCoordinator** - An orchestration layer that combines DEX swaps with HTLC operations in a single atomic transaction:

* `executeAndCreateWithPermit2` - Pull tokens via Permit2, execute DEX swap calls, then lock the result in an HTLC
* `redeemAndExecute` - Redeem an HTLC via EIP-712 signature, execute DEX swap, sweep tokens to destination
* `refundAndExecute` - Refund an expired HTLC, optionally swap tokens back, sweep to destination
* `refundTo` - Simple refund of an expired HTLC directly to the original depositor or a specified address

<Info>
  **DEX-agnostic design:** The coordinator accepts arbitrary call arrays for DEX aggregation.
</Info>

***

## Satora Swaps HTLC Flow (BTC → EVM)

<Steps>
  <Step title="Client Generates Secret">
    Client generates a random 32-byte preimage S. From it the client derives both hash locks the swap needs: `H_evm = SHA256(S)` for the EVM HTLC and `H_btc = HASH160(S) = RIPEMD160(SHA256(S))` for the Bitcoin / Arkade side. The client shares the hashes with the service - never the preimage itself. This ensures only the client can initiate the claim.
  </Step>

  <Step title="Client Pays BTC">
    Client pays via a Boltz reverse swap (Lightning), sends to an Arkade VHTLC, or sends to an on-chain Bitcoin **P2TR (Taproot) HTLC**. The Taproot output commits to a script of the form `<server_pk> OP_CHECKSIGVERIFY OP_HASH160 <H_btc> OP_EQUAL`, so the same `OP_HASH160` rule covers the on-chain HTLC and Arkade VHTLC. For Lightning, Boltz locks BTC in an Arkade VHTLC using `H_btc`.
  </Step>

  <Step title="Service Creates EVM HTLC">
    Service locks tokens in the EVM smart contract (HTLCErc20) using the same hash H:

    * Claim address (user or coordinator)
    * Hash lock H
    * Timelock (24 hours for client, 12 hours for server on mainnet)
    * Token address and amount

    For BTC → EVM swaps, the service uses `executeAndCreateWithPermit2` on the coordinator. The depositor authorizes the input-token transfer with a Permit2 signature; the coordinator pulls the tokens via Permit2, runs the DEX swap calls, and locks the resulting balance in the HTLC - all in a single transaction.
  </Step>

  <Step title="Client Claims Tokens">
    Client reveals the preimage S to claim their tokens:

    * **Gasless (recommended):** Client signs an EIP-712 message. Server calls `redeemAndExecute` on the coordinator, which redeems the HTLC, optionally swaps tokens via DEX routing, and sweeps to the client's destination.
    * **Manual:** Client calls `redeem` directly on HTLCErc20 with the preimage (requires signer + gas).
  </Step>

  <Step title="Service Settles BTC">
    Service extracts S from the EVM chain and claims the Arkade VHTLC via Boltz (or spends the on-chain P2TR HTLC by revealing the hashlock script path with S).
  </Step>
</Steps>

***

## Gasless Execution

Satora Swaps uses **EIP-712 typed data signatures** so users never need to pay gas:

1. User signs an EIP-712 message binding: preimage, destination address, sweep token, and minimum output amount
2. Server submits `redeemAndExecute` on the HTLCCoordinator (server pays gas)
3. The coordinator redeems the HTLC, executes any DEX swap calls, and sweeps tokens to the user's signed destination
4. User receives tokens with **zero gas cost**

The EIP-712 signature cryptographically binds the claim to the coordinator contract as `msg.sender`, preventing front-running. The signed destination address ensures tokens can only go to the address the user specified.

**Gasless fee:** A small gas fee is deducted from the swap amount depending on network conditions. This fee is included in the quote. Alternatively, you can claim manually with your own signer and pay gas yourself.

***

## Security

| Protection              | How                                                        |
| ----------------------- | ---------------------------------------------------------- |
| **Atomic**              | Either both parties get funds, or neither does             |
| **Trustless**           | No third party controls funds                              |
| **Time-bounded**        | Automatic refund if unclaimed                              |
| **Slippage protection** | Minimum output amount enforced in coordinator calls        |
| **Front-running safe**  | EIP-712 signature binds claim to coordinator as msg.sender |
| **Destination binding** | Signed destination prevents token redirection              |
| **Reentrancy safe**     | Transient storage (EIP-1153) for reentrancy protection     |

### Timelock Safety

```
Client-side HTLC timeout: 24 hours   // chain the client funds
Server-side HTLC timeout: 12 hours   // chain the server funds
```

The client always gets the **longer** timeout on the HTLC they fund, because the client holds the secret. After the client reveals the preimage to claim the server-funded side, the server still has enough time to claim the client-funded side using the revealed secret. For BTC -> EVM swaps, the client-funded HTLC is the BTC one; for EVM -> BTC swaps, it's the EVM one.

***

## Smart Contract Interface

```solidity theme={null}
// ── HTLCErc20 ──────────────────────────────────────

// Create HTLC (5-param: service locks tokens)
function create(
    bytes32 preimageHash, uint256 amount, address token,
    address claimAddress, uint256 timelock
) external;

// Create HTLC (6-param: with explicit refund address)
function create(
    bytes32 preimageHash, uint256 amount, address token,
    address refundAddress, address claimAddress, uint256 timelock
) external;

// Direct redeem (claimAddress must be msg.sender)
function redeem(
    bytes32 preimage, uint256 amount, address token,
    address sender, uint256 timelock
) external;

// Gasless redeem via EIP-712 signature
// callsHash binds the signature to a specific calls array (set to keccak256
// of the encoded calls when redeeming through HTLCCoordinator; bytes32(0)
// when calling HTLCErc20 directly without a coordinator calls array).
function redeemBySig(
    bytes32 preimage, uint256 amount, address token,
    address sender, uint256 timelock, address destination,
    address sweepToken, uint256 minAmountOut,
    bytes32 callsHash,
    uint8 v, bytes32 r, bytes32 s
) external returns (address);

// Refund after timelock expires (5-param)
function refund(
    bytes32 preimageHash, uint256 amount, address token,
    address claimAddress, uint256 timelock
) external;

// Refund after timelock expires (6-param: with destination)
function refund(
    bytes32 preimageHash, uint256 amount, address token,
    address claimAddress, uint256 timelock, address destination
) external;

// ── HTLCCoordinator ────────────────────────────────

// DEX swap + HTLC create, funded via Permit2.
// The depositor signs a Permit2 PermitTransferFrom for the input token; the
// coordinator pulls the tokens, runs `calls` (e.g. a DEX swap), then locks the
// resulting `token` balance in HTLCErc20 under (preimageHash, claimAddress,
// timelock). The depositor is recorded so refunds can be returned to them.
function executeAndCreateWithPermit2(
    Call[] calls,
    bytes32 preimageHash,
    address token,
    address claimAddress,
    uint256 timelock,
    address depositor,
    ISignatureTransfer.PermitTransferFrom permit,
    bytes signature
) external;

// HTLC redeem + DEX swap + sweep (gasless claiming)
function redeemAndExecute(
    bytes32 preimage, uint256 amount, address token,
    address htlcSender, uint256 timelock, Call[] calls,
    address sweepToken, uint256 minAmountOut,
    address destination, uint8 v, bytes32 r, bytes32 s
) external;

// HTLC refund + DEX swap-back + sweep
function refundAndExecute(
    bytes32 preimageHash, uint256 amount, address token,
    address claimAddress, uint256 timelock,
    Call[] calls, address sweepToken, uint256 minAmountOut
) external;

// Simple refund to original depositor or specified address
function refundTo(
    bytes32 preimageHash, uint256 amount, address token,
    address claimAddress, uint256 timelock
) external;
```

***

## Deterministic Deployment

Satora Swaps uses **CREATE2** for deterministic contract addresses across all chains. This means the HTLCErc20 and HTLCCoordinator contracts have the same address on Polygon, Ethereum, and Arbitrum.

***

## Resources

* [State Machine](/advanced/state-machine)
* [Bitcoin HTLCs](https://en.bitcoin.it/wiki/Hash_Time_Locked_Contracts)
* [EIP-712 Typed Data Signing](https://eips.ethereum.org/EIPS/eip-712)
