> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Collaboratively refund spendable VTXOs.

> The client builds an offchain transaction (ark_tx + checkpoints) spending the VHTLC
via the `refund_script` leaf, signs as sender, and sends the partially-signed PSBTs here.
The server cosigns as receiver and returns the countersigned PSBTs.
The client then submits to Arkade for the server (3rd) signature.



## OpenAPI

````yaml POST /api/swap/arkade-evm/{id}/collab-refund
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
  /api/swap/arkade-evm/{id}/collab-refund:
    post:
      tags:
        - swap-btc-evm
      summary: Collaboratively refund spendable VTXOs.
      description: >-
        The client builds an offchain transaction (ark_tx + checkpoints)
        spending the VHTLC

        via the `refund_script` leaf, signs as sender, and sends the
        partially-signed PSBTs here.

        The server cosigns as receiver and returns the countersigned PSBTs.

        The client then submits to Arkade for the server (3rd) signature.
      operationId: collab_refund
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
              $ref: '#/components/schemas/CollabRefundRequest'
        required: true
      responses:
        '200':
          description: Countersigned PSBTs
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CollabRefundResponse'
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
    CollabRefundRequest:
      type: object
      description: >-
        Request for collaborative refund of spendable VTXOs (offchain send
        flow).
      required:
        - ark_tx
        - checkpoint_txs
      properties:
        ark_tx:
          type: string
          description: >-
            Base64-encoded ark transaction PSBT (partially signed by the
            sender/client).
        checkpoint_txs:
          type: array
          items:
            type: string
          description: Base64-encoded checkpoint PSBTs.
    CollabRefundResponse:
      type: object
      description: Response with countersigned PSBTs.
      required:
        - ark_tx
        - checkpoint_txs
      properties:
        ark_tx:
          type: string
          description: Base64-encoded countersigned ark transaction PSBT.
        checkpoint_txs:
          type: array
          items:
            type: string
          description: Base64-encoded countersigned checkpoint PSBTs.
    ErrorResponse:
      type: object
      required:
        - error
      properties:
        error:
          type: string

````