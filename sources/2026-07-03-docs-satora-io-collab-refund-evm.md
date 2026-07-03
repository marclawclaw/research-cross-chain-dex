> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Collaboratively refund an EVM HTLC before timelock expiry.

> The client signs a coordinator-level `CollabRefund` EIP-712 message authorizing
the refund parameters. The server cosigns with an HTLC-level `Refund` signature
(as claimAddress, waiving the timelock) and submits the transaction on-chain.

Supports EVM-to-Arkade, EVM-to-Bitcoin, and EVM-to-Lightning swaps.



## OpenAPI

````yaml POST /api/swap/{id}/collab-refund-evm
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
  /api/swap/{id}/collab-refund-evm:
    post:
      tags:
        - swap-evm-btc
      summary: Collaboratively refund an EVM HTLC before timelock expiry.
      description: >-
        The client signs a coordinator-level `CollabRefund` EIP-712 message
        authorizing

        the refund parameters. The server cosigns with an HTLC-level `Refund`
        signature

        (as claimAddress, waiving the timelock) and submits the transaction
        on-chain.


        Supports EVM-to-Arkade, EVM-to-Bitcoin, and EVM-to-Lightning swaps.
      operationId: collab_refund_evm
      parameters:
        - name: id
          in: path
          description: Swap ID
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CollabRefundEvmRequest'
        required: true
      responses:
        '200':
          description: EVM HTLC refunded successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CollabRefundEvmResponse'
        '400':
          description: Bad request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Refund not allowed in current swap state
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '404':
          description: Swap not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
components:
  schemas:
    CollabRefundEvmRequest:
      type: object
      description: Request for collaborative refund of an EVM HTLC.
      required:
        - v
        - r
        - s
        - depositor_address
      properties:
        depositor_address:
          type: string
          description: >-
            On-chain depositor address (the address that funded the HTLC via the
            coordinator).

            In the Permit2 flow this is a derived key, not the user's wallet
            address.

            Required so the server can sign the correct HTLC refund digest.
        min_amount_out:
          type: string
          description: Minimum amount out for the sweep (0 = no minimum). Defaults to 0.
        mode:
          $ref: '#/components/schemas/RefundMode'
          description: >-
            Refund mode: "direct" (WBTC back to depositor) or "swap"/"swap-back"
            (DEX swap-back to

            original token)
        r:
          type: string
          description: EIP-712 signature r (32-byte hex string, with or without 0x prefix)
        s:
          type: string
          description: EIP-712 signature s (32-byte hex string, with or without 0x prefix)
        sweep_token:
          type:
            - string
            - 'null'
          description: |-
            Token to sweep to depositor after refund. Required for "swap" mode.
            For "direct" mode, defaults to WBTC.
        v:
          type: integer
          format: int32
          description: EIP-712 signature v (depositor's coordinator-level signature)
          minimum: 0
    CollabRefundEvmResponse:
      type: object
      description: Response for collaborative refund of an EVM HTLC.
      required:
        - id
        - tx_hash
        - message
      properties:
        id:
          type: string
          description: Swap ID
        message:
          type: string
          description: Success message
        tx_hash:
          type: string
          description: Transaction hash of the on-chain refund
    ErrorResponse:
      type: object
      required:
        - error
      properties:
        error:
          type: string
    RefundMode:
      type: string
      description: Settlement mode for collaborative refund.
      enum:
        - direct
        - swap-back

````