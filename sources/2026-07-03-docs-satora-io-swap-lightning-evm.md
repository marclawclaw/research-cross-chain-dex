> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Create a chain-agnostic Lightning-to-EVM swap.



## OpenAPI

````yaml POST /swap/lightning/evm
openapi: 3.1.0
info:
  title: Lendaswap API
  description: Seamlessly swap between BTC and Stables on Ethereum/Polygon/etc
  license:
    name: ''
  version: 0.2.39
servers:
  - url: https://api.satora.io
security: []
tags:
  - name: version
    description: Check API version information.
  - name: tokens
    description: Get available tokens for swaps.
  - name: quote
    description: Get quotes for token swaps.
  - name: swap-btc-evm
    description: Create chain-agnostic BTC to EVM swaps.
  - name: swap-evm-btc
    description: Create chain-agnostic EVM to BTC swaps.
  - name: swap-btc-arkade
    description: Create Arkade to BTC swaps.
  - name: swaps
    description: Get swap details and status.
  - name: recovery
    description: Recover swaps from extended public key.
  - name: evm-tokens
    description: Get available EVM tokens from 1inch.
  - name: health
    description: Health check endpoint.
  - name: status
    description: Aggregated health of external dependencies.
  - name: mtp
    description: Bitcoin Median Time Past (MTP) information.
  - name: support
    description: Support agent configuration.
  - name: swap-pairs
    description: Supported swap pairs with limits and fees.
paths:
  /swap/lightning/evm:
    post:
      tags:
        - swap-btc-evm
      summary: Create a chain-agnostic Lightning-to-EVM swap.
      operationId: create_lightning_evm_swap
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/LightningToEvmSwapRequest'
        required: true
      responses:
        '200':
          description: Swap created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/LightningToEvmSwapResponse'
        '400':
          description: Bad request - invalid parameters
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '409':
          description: Conflict - a swap with this preimage hash exists already
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
components:
  schemas:
    LightningToEvmSwapRequest:
      type: object
      description: >-
        Chain-agnostic request for Lightning-to-EVM swaps.


        The caller specifies the target chain via `evm_chain_id` and the token

        via its ERC-20 contract `token_address`. This endpoint supports any
        token

        reachable through 1inch aggregation.
      required:
        - claiming_address
        - target_address
        - evm_chain_id
        - token_address
        - hash_lock
        - refund_pk
        - user_id
      properties:
        amount_in:
          type:
            - integer
            - 'null'
          format: int64
          description: >-
            How many sats the user wants to send (mutually exclusive with
            `amount_out`).

            Value is in satoshis (smallest BTC unit).
          minimum: 0
        amount_out:
          type:
            - integer
            - 'null'
          format: int64
          description: >-
            How much target token the user wants to receive (mutually exclusive
            with `amount_in`).

            Value is in the target token's smallest unit (e.g. for USDC with 6
            decimals, 1000000 = 1

            USDC).
          minimum: 0
        bridge_recipient_setup:
          type: boolean
          description: |-
            ATA-existence flag for non-EVM CCTP destinations (Solana).
            See `BitcoinToEvmSwapRequest::bridge_recipient_setup`.
        bridge_target_chain:
          type:
            - string
            - 'null'
          description: >-
            Optional: CCTP bridge destination chain (e.g., "Ethereum",
            "Arbitrum"). When set,

            USDC will be bridged to this chain after the DEX swap.
        bridge_target_token_address:
          type:
            - string
            - 'null'
          description: 'Optional: USDC address on the bridge destination chain.'
        claiming_address:
          type: string
          description: >-
            EVM address that will sign the HTLC claim (SDK-derived for gasless
            claims).
        evm_chain_id:
          type: integer
          format: int64
          description: 'Numeric EVM chain ID: 1 (Ethereum), 137 (Polygon), 42161 (Arbitrum).'
          minimum: 0
        extra_fees:
          type:
            - integer
            - 'null'
          format: int32
          description: >-
            Optional per-swap fee surcharge in basis points
            (0..=max_extra_fee_bps

            configured on the matching developer key). Rejected with 400 if it

            exceeds the per-key cap.
          minimum: 0
        gasless:
          type: boolean
          description: >-
            Whether the server should execute the DEX swap on behalf of the user
            (gasless claim).

            When true, the gasless network fee is added to the total fee
            charged.

            Defaults to true.
        hash_lock:
          type: string
          description: >-
            Hash lock provided by the client (32-byte hex string with 0x
            prefix).
        referral_code:
          type:
            - string
            - 'null'
          description: >-
            Optional referral code for tracking. Matches a developer's API key

            (`referral_id` on `developer_api_keys`) and is persisted for
            attribution.
        refund_pk:
          type: string
          description: Refund public key used to generate the Arkade VHTLC.
        target_address:
          type: string
          description: >-
            EVM address where tokens are swept after the claim (user's final
            destination).
        token_address:
          type: string
          description: ERC-20 contract address of the desired token on the target chain.
        user_id:
          type: string
          description: User ID derived from wallet for recovery purposes.
    LightningToEvmSwapResponse:
      type: object
      description: Lightning → EVM swap response
      required:
        - id
        - status
        - fee_sats
        - hash_lock
        - source_token
        - target_token
        - created_at
        - chain
        - evm_chain_id
        - evm_expected_sats
        - source_amount
        - target_amount
        - boltz_invoice
        - bolt11_invoice
        - boltz_swap_id
        - evm_htlc_address
        - evm_coordinator_address
        - wbtc_address
        - client_evm_address
        - server_evm_address
        - evm_refund_locktime
        - sender_pk
        - receiver_pk
        - arkade_server_pk
        - vhtlc_refund_locktime
        - unilateral_claim_delay
        - unilateral_refund_delay
        - unilateral_refund_without_receiver_delay
        - network
      properties:
        arkade_server_pk:
          type: string
        bolt11_invoice:
          type: string
          description: Lightning invoice to pay
        boltz_invoice:
          type: string
          description: |-
            Lightning invoice to pay
            DEPRECATED: use [`bolt11_invoice`] instead
        boltz_swap_id:
          type: string
          description: Boltz swap ID
        bridge_target_chain:
          type:
            - string
            - 'null'
          description: >-
            CCTP bridge destination chain. When set, USDC is bridged cross-chain
            after the swap.
        bridge_target_token_address:
          type:
            - string
            - 'null'
          description: USDC address on the bridge destination chain.
        btc_claim_txid:
          type:
            - string
            - 'null'
          description: Server's claim transaction ID on Arkade (Boltz VHTLC claim)
        chain:
          type: string
        client_evm_address:
          type: string
          description: EVM address that will sign the HTLC claim
        created_at:
          type: string
          format: date-time
        evm_chain_id:
          type: integer
          format: int64
        evm_claim_txid:
          type:
            - string
            - 'null'
        evm_coordinator_address:
          type: string
        evm_expected_sats:
          type: string
        evm_fund_txid:
          type:
            - string
            - 'null'
        evm_htlc_address:
          type: string
        evm_refund_locktime:
          type: integer
          format: int64
        fee_sats:
          type: integer
          format: int64
        hash_lock:
          type: string
        id:
          type: string
        network:
          type: string
        receiver_pk:
          type: string
        sender_pk:
          type: string
        server_evm_address:
          type: string
        source_amount:
          type: string
        source_token:
          $ref: '#/components/schemas/TokenInfo'
        status:
          $ref: '#/components/schemas/SwapStatus'
        target_amount:
          type: string
        target_evm_address:
          type:
            - string
            - 'null'
          description: EVM address where tokens are swept after the claim
        target_token:
          $ref: '#/components/schemas/TokenInfo'
        unilateral_claim_delay:
          type: integer
          format: int64
        unilateral_refund_delay:
          type: integer
          format: int64
        unilateral_refund_without_receiver_delay:
          type: integer
          format: int64
        vhtlc_refund_locktime:
          type: integer
          format: int64
        wbtc_address:
          type: string
          description: WBTC token contract address on the target EVM chain
    ErrorResponse:
      type: object
      required:
        - error
      properties:
        error:
          type: string
    TokenInfo:
      type: object
      required:
        - token_id
        - symbol
        - chain
        - name
        - decimals
      properties:
        chain:
          $ref: '#/components/schemas/Chain'
        decimals:
          type: integer
          format: int32
          minimum: 0
        name:
          type: string
        symbol:
          type: string
        token_id:
          $ref: '#/components/schemas/TokenId'
    SwapStatus:
      type: string
      description: >-
        Atomic swap state machine for BTC --> Target Asset swaps using HTLCs.


        # Overview


        This enum tracks the state of an atomic swap between Bitcoin (via
        Lightning/Arkade)

        and Target Asset (on Polygon, Ethereum, etc). The swap uses Hash
        Time-Locked Contracts (HTLCs)

        to ensure atomicity without requiring trust.


        # Normal Flow


        ```text

        Pending → ClientFunded → ServerFunded → ClientRedeemed → ServerRedeemed

        ```


        1. Client creates swap request → `Pending`

        2. Client sends BTC → `ClientFunded`

        3. Server locks WBTC in Polygon HTLC → `ServerFunded`

        4. Client reveals secret to claim Target Asset → `ClientRedeemed`

        5. Server uses secret to claim BTC → `ServerRedeemed` (terminal)


        # Refund Flows


        ```text

        Pending → Expired (no funding)

        ClientFunded → ClientRefunded (client refunds before server funds)

        ServerFunded → ClientFundedServerRefunded (HTLC timeout)

        ```


        # State Diagram


        See `swap_states.md` for a complete state diagram and detailed
        documentation.


        # Security


        - Bitcoin HTLC timeout must be longer than Polygon HTLC timeout

        - Secret becomes public when client claims TargetAsset on Polygon

        - `ClientRefundedServerFunded` is an error state that should never occur
      enum:
        - pending
        - clientfundingseen
        - clientfunded
        - clientrefunded
        - serverfunded
        - clientredeeming
        - clientredeemed
        - serverredeemed
        - clientfundedserverrefunded
        - clientrefundedserverfunded
        - clientrefundedserverrefunded
        - expired
        - clientinvalidfunded
        - clientfundedtoolate
        - serverwontfund
        - clientredeemedandclientrefunded
    Chain:
      type: string
      description: >-
        Supported blockchain networks.

        EVM chains serialize to their chain ID as a string (e.g. "137" for
        Polygon).
      enum:
        - Arkade
        - Lightning
        - Bitcoin
        - '137'
        - '1'
        - '42161'
    TokenId:
      oneOf:
        - type: string
          enum:
            - btc
        - type: string
      description: 'Token identifier. Known values: btc, 0x123456'

````