---
tags: [pattern, trust-model, custody, federation, signing]
seen_in: [serai, thorchain, wormhole]
---

# Signer Federation Trust

In every cross-chain swap or bridge architecture researched here, the
*assets being moved* are not natively cross-chain. They live on
heterogeneous L1s that cannot directly verify each other. The only
practical way to move value between them is for a **federation of
signers** to custody assets on each external chain and release them
under some authorisation rule. The differences between Serai,
Thorchain, and Wormhole are differences in:

1. Who is in the federation
2. How a member is added or removed
3. What economic or reputational stake they post
4. How a release is authorised
5. What recourse users have if the federation misbehaves

## Comparison axes

| Axis | [[projects/serai]] | [[projects/thorchain]] | [[projects/wormhole]] |
|------|--------------------|------------------------|-----------------------|
| Set size | Validator set, permissionless PoS (see [[patterns/serai-trust-model]]) | Active node set, ~100 (see [[patterns/thorchain-trust-model]]) | 19 named orgs (see [[patterns/wormhole-trust-model]]) |
| Set membership | Permissionless (bond) | Bond auction (top N by bond) | Permissioned (governance) |
| Stake at risk | SRI bond, slashable | RUNE bond, slashable (3:1 ratio target) | None bonded (reputational only) |
| Threshold scheme | FROST t-of-n per external coin | GG20 / TSS t-of-n per Asgard vault | 13-of-19 independent signatures aggregated on chain |
| Key rotation | Per epoch / tributary | Per churn cycle | Set rotates only via governance |
| Worst-case for user if federation cheats | Threshold corrupted: drain custodied vault for that external coin | Threshold corrupted: drain Asgard vault; bond seized but may be insufficient | Threshold corrupted: forge VAAs, mint or release on any integrated chain |

## Why "federation" describes all three

Despite different terminology (validators, node operators, guardians),
all three pin user funds to a *threshold of a curated group*. The
group's composition rules and stake rules vary, but the cryptographic
core is the same: t-of-n authorisation over external chain transfers.
The user does not gain a non-custodial guarantee; they gain a
*non-individual-custodian* guarantee.

## Implication for the Logos cross-chain DEX

If LEZ takes on the middle-chain role, LEZ inherits the federation
trust pattern. The bonded validator set of LEZ becomes the signer
federation for external chains. The questions then are:

1. What is the bond-to-custodied-value ratio at launch and at scale?
2. Can the federation be made *less* visible to users on chain, even
   while remaining accountable? (See anonymity options in
   [[projects/lez-positioning]].)
3. Can users get cryptographic recourse beyond slashing (e.g. fraud
   proofs, exit windows) that none of Serai, Thorchain, or Wormhole
   offer?

See [[summary]] for the integrated analysis.
