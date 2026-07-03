> ## Documentation Index
> Fetch the complete documentation index at: https://docs.satora.io/llms.txt
> Use this file to discover all available pages before exploring further.

# Security

> Questions about Satora Swaps security and fund safety

<AccordionGroup>
  <Accordion title="What if Satora Swaps goes offline during my swap?">
    Your funds are safe. HTLCs have a built-in timelock - if the service doesn't complete its side, you can refund after the timeout expires. The SDK handles this automatically. For manual refunds, see the [Handle Failures](/handle-failures/refund-onchain-htlc) section.
  </Accordion>

  <Accordion title="Can Satora Swaps steal my funds?">
    No. The HTLC protocol is cryptographically enforced on-chain. Satora Swaps never has unilateral access to your funds. Either the swap completes atomically (both sides succeed) or you can reclaim your funds after the timelock. There is no trust assumption.
  </Accordion>

  <Accordion title="How are smart contracts audited?">
    Satora Swaps' HTLC contracts use deterministic CREATE2 deployment across all chains. The contracts are verified on-chain and their source code can be inspected on block explorers. See the [Smart Contract Interface](/advanced/htlc) for the full contract specification.
  </Accordion>
</AccordionGroup>
