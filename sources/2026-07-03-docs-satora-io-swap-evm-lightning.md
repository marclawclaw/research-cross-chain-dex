> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Create a chain-agnostic EVM-to-Lightning swap.

> Flow:
1. User provides their Lightning invoice (they want to receive BTC)
2. Server prepares Boltz submarine swap to pay the invoice
3. User funds EVM HTLCErc20 with tokens
4. Server pays Lightning invoice via Boltz (gets preimage)
5. Server claims EVM HTLCErc20 using preimage



## OpenAPI

````yaml POST /swap/evm/lightning
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
  /swap/evm/lightning:
    post:
      tags:
        - swap-evm-btc
      summary: Create a chain-agnostic EVM-to-Lightning swap.
      description: |-
        Flow:
        1. User provides their Lightning invoice (they want to receive BTC)
        2. Server prepares Boltz submarine swap to pay the invoice
        3. User funds EVM HTLCErc20 with tokens
        4. Server pays Lightning invoice via Boltz (gets preimage)
        5. Server claims EVM HTLCErc20 using preimage
      operationId: create_evm_to_lightning_swap_generic
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/EvmToLightningSwapRequest'
        required: true
      responses:
        '200':
          description: Swap created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EvmToLightningSwapResponse'
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
    EvmToLightningSwapRequest:
      type: object
      description: >-
        Request to create an EVM-to-Lightning swap.


        User sends any ERC-20 token on EVM, receives BTC via Lightning.

        The hash_lock is derived from the Lightning invoice's payment hash.


        Provide **one of**:

        - `lightning_invoice` — a BOLT11 invoice

        - `lightning_address` + `amount_sats` — a Lightning address resolved via
        LNURL-pay

        - `lnurl` + `amount_sats` — a raw LNURL string (bech32-encoded URL)
        resolved via LNURL-pay
      required:
        - evm_chain_id
        - token_address
        - user_address
        - user_id
      properties:
        amount_sats:
          type:
            - integer
            - 'null'
          format: int64
          description: >-
            Amount in satoshis the recipient should receive on Lightning.

            Required when `lightning_address` or `lnurl` is provided; ignored
            when

            `lightning_invoice` is provided (amount is read from the invoice).
          minimum: 0
        bridge_source_chain:
          type:
            - string
            - 'null'
          description: >-
            Optional: CCTP bridge source chain (e.g., "Ethereum", "Optimism").
            When set,

            the user's source USDC originates on this chain and hops through
            CCTPv2 to

            Arbitrum before the HTLC is created. The backend pads
            `deposit_amount` by

            the fast-transfer fee at UserOp-calldata time.
        bridge_source_token_address:
          type:
            - string
            - 'null'
          description: 'Optional: USDC address on the bridge source chain.'
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
          description: |-
            Optional per-swap fee surcharge in basis points
            (0..=max_extra_fee_bps configured on the matching developer key).
          minimum: 0
        gasless:
          type: boolean
          description: >-
            Whether to use gasless relay for funding (server submits tx on
            behalf of user).
        lightning_address:
          type:
            - string
            - 'null'
          description: >-
            Lightning address (e.g. `user@speed.app`) to resolve via LNURL-pay.

            Mutually exclusive with `lightning_invoice` and `lnurl`. Requires
            `amount_sats`.
        lightning_invoice:
          type:
            - string
            - 'null'
          description: |-
            User's Lightning BOLT11 invoice to receive payment.
            Mutually exclusive with `lightning_address` and `lnurl`.
        lnurl:
          type:
            - string
            - 'null'
          description: >-
            Raw LNURL string (e.g. `lnurl1...`) to resolve via LNURL-pay.

            Mutually exclusive with `lightning_invoice` and `lightning_address`.
            Requires

            `amount_sats`.
        referral_code:
          type:
            - string
            - 'null'
          description: Optional referral code for tracking.
        token_address:
          type: string
          description: ERC-20 contract address of the source token on the EVM chain.
        user_address:
          type: string
          description: User's EVM address (sender of the ERC-20 token).
        user_id:
          type: string
          description: User ID derived from wallet for recovery purposes.
    EvmToLightningSwapResponse:
      type: object
      description: EVM → Lightning swap response
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
        - source_amount
        - target_amount
        - evm_expected_sats
        - evm_htlc_address
        - client_evm_address
        - server_evm_address
        - evm_refund_locktime
        - client_lightning_invoice
        - lightning_paid
        - sender_pk
        - receiver_pk
        - arkade_server_pk
        - vhtlc_refund_locktime
        - unilateral_claim_delay
        - unilateral_refund_delay
        - unilateral_refund_without_receiver_delay
        - network
        - gasless
      properties:
        arkade_server_pk:
          type: string
        bridge_source_chain:
          type:
            - string
            - 'null'
          description: |-
            CCTP bridge source chain. Set when the source USDC originated on
            another CCTP chain and hopped to Arbitrum via CCTPv2 before the
            HTLC was created. `source_token` still reports the post-hop
            Arbitrum USDC; this field tells the SDK what chain the user is
            expected to burn from.
        bridge_source_token_address:
          type:
            - string
            - 'null'
          description: Native USDC address on the bridge source chain.
        chain:
          type: string
        client_evm_address:
          type: string
        client_lightning_invoice:
          type: string
          description: User's Lightning invoice to receive payment
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
        gasless:
          type: boolean
          description: Whether this swap was created with gasless relay (Permit2)
        hash_lock:
          type: string
        id:
          type: string
        lightning_paid:
          type: boolean
          description: Whether the Lightning payment has been made
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