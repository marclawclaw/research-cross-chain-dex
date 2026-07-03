> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# General

> General questions about Satora Swaps

<AccordionGroup>
  <Accordion title="What is Satora Swaps?">
    Satora Swaps enables instant, trustless swaps between Bitcoin (Lightning, Arkade, or on-chain) and EVM tokens (USDC, USDT, etc.) on Polygon, Ethereum, and Arbitrum. All swaps are non-custodial using Hash Time-Locked Contracts (HTLCs).
  </Accordion>

  <Accordion title="Is Satora Swaps custodial?">
    No. Satora Swaps is fully non-custodial. Swaps use atomic HTLCs - either both sides complete, or neither does. At no point does Satora Swaps hold your funds without a cryptographic guarantee that you can reclaim them.
  </Accordion>

  <Accordion title="Which chains and tokens are supported?">
    **Bitcoin side:** Lightning Network, Arkade (off-chain), and on-chain BTC.

    **EVM side:** Polygon, Ethereum, and Arbitrum. Supported tokens include USDC, USDT, and other ERC-20 tokens routed via DEX aggregation.

    Use the [/tokens endpoint](/api-reference/tokens) or [Supported Tokens](/quotes-rates/supported-tokens) page to see the full list.
  </Accordion>

  <Accordion title="What are the fees?">
    Satora Swaps charges a small percentage fee on each swap, plus network fees. Use the [/quote endpoint](/api-reference/quote) to get an exact fee breakdown before creating a swap. Gasless claiming on EVM chains deducts a small gas fee from the swap amount.
  </Accordion>
</AccordionGroup>
