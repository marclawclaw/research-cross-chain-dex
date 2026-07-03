> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Gasless & Fees

> Questions about gasless execution and fee structure

<AccordionGroup>
  <Accordion title="What does 'gasless' mean?">
    When claiming EVM tokens (BTC → EVM swaps), you don't need to hold ETH/MATIC for gas. Instead, you sign an EIP-712 message and Satora Swaps' server submits the transaction on your behalf. A small gas fee is deducted from the swap amount. See [HTLC docs](/advanced/htlc) for the technical details.
  </Accordion>

  <Accordion title="Can I pay gas myself instead of using gasless?">
    Yes. You can claim manually by calling the HTLC contract directly with your own wallet. This requires holding native gas tokens (ETH/MATIC/ARB) but avoids the gasless fee deduction.
  </Accordion>

  <Accordion title="How is the exchange rate determined?">
    Rates are sourced from DEX liquidity at the time of the swap. Use the [/quote endpoint](/api-reference/quote) to get a real-time quote before creating a swap. Quotes include all fees and slippage estimates.
  </Accordion>
</AccordionGroup>
