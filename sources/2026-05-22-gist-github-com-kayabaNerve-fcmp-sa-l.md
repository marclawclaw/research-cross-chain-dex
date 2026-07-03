# Full-Chain Membership Proofs + Spend Authorization + Linkability

This proposes an extension to FCMPs to make them a drop-in replacement for the exsting CLSAG. In order to be such a replacement, the proof must handle membership (inherent to FCMPs), spend authorization, and linkability.

### Terminology

- FCMP: Full Chain Membership Proof
- GBP: Generalized Bulletproof, a modified Bulletproof supporting Pedersen Vector Commitments in its arithmetic circuit proof. Security proofs are [currently being worked on by Cypher Stack](https://ccs.getmonero.org/proposals/cypherstack-gbp-security-proofs.html).
- GSP: [Generalized Schnorr Protocol](https://eprint.iacr.org/2009/050.pdf), a proven protocol for 2009 for proving:
    For a m\*n matrix
    ```
    [
        [A, B, C],
        [D, E, F]
    ]`
    ```
    And a n-length row
    ```
    [x, y, z]
    ```
    The m-length output column:
    ```
    [
      T,
      U,
    ]
    ```
    is
    ```
    [
      xA + yB + zC,
      xD + yE + zF,
    ]
    ```
    This is useful to prove knowledge of the opening of a vector commitment and consistency between vector commitments.
- BP+: [Bulletproof+](https://eprint.iacr.org/2020/735). A weighted-inner-product proof currently in use in Monero.
- F-S: Forward secret. An adversary who can solve for the elliptic curve discrete log problem cannot find the spent output.

### Recap

FCMPs, when instantiated with GBPs, are a `O(n)` proof of an `O(log m)` program (where `m` is the amount of members in the set). The program is a Merkle tree proof, where the same layer program is executed multiple times. The layer program is summarizable as follows:

1) Unblind the Pedersen Commitment input.
2) Verify the unblinded variable is present in the layer being hashed.
3) Hash the layer, outputting a new Pedersen Vector Commitment (blinding the hash for the layer).

For the first layer, under Seraphis, the input would be the re-randomized squashed-enote (effectively a Pedersen Vector Commitment). The "unblinding" would remove the re-randomization and continue.

The final layer would use randomness = 0 such that the output Pedersen Vector Commitment *is* the tree root (or the protocol would take the difference and require a discrete log PoK, forcing the user ).

### Difficulty

The naive solution would be to open `K`, the output key, inside the proof, then prove for the key-image inside the proof. This would require hardware wallets perform the FCMP proof, which is extremely undesirable/entirely unacceptable. Accordingly, the goal is for the membership proof to perform re-randomization without knowledge of `x`, letting a second proof prove for spend authorization and the key image.

### Solution

Instead of building a Merkle tree of squashed enotes, we build a Merkle tree with elements `(K, hash_to_point(K), C)` where `C` is the amount commitment. We output re-randomized versions of all three and then prove the key image correctly formed.

### Originally Proposed Modifications for Deployment During RingCT

EDIT: These should not be moved forward with. The alternative modifications in the next section achieve much better properties and are the basis of the forward-secret variant posted below. This is only present as it was discussed below and therefore would be confusing to remove entirely.

For the first layer, we don't take in the re-randomized squashed-enote (as this is pre-Seraphis), yet `(r K, r**-1 H(K), C + a G)`. We denote this `(K', H', C')`.

The first layer does not perform the traditional unblinding (addition of `a G` for a known `a`) for `K', H'`. Instead, it multiplies `K` by `r` (checking it's equal to `K'`) and `H'` by `r` (checking it's equal to `H(K)`). We then perform the traditional unblinding of `C'` and check membership of `(K, H(K), C)`.

This does not prove the spend is authorized nor that any claimed linking tag is correctly formed. It solely shows that the `K', H'` are derived as expected from a member of the tree.

We then extend this with a Discrete Log Equality proof for `K', I` over `G, H'`. The discrete logarithm of `K'` is `r x`, which we notate `x'`. `x' H'`  expands to `r x r**-1 H(K)`, with the `r` terms cancelling out for `x H(K)`, the expected key image. This introduces linkability into the proof. By having the DLEq proof's transcript be over the message signed, spend authorization as well.

### Proposed Modifications

With newly introduced generators `T, U, V`, and ignoring the amount commitment for now:

- `K' = K + aT`
- `I' = hash_to_point(K) + bU`
- `B = bV`

The FCMP would only perform three standard unblinds (the third being `C'`, ignored here), and show consistency between the `bU` term in `I'` with `B`. Instead of performing a DLEq proof after, we'd provide a proof of the following.

For matrix:

```
[
  [G,  T,  0], // Open K'
  [0,  0,  V], // Open B
  [U,  0,  0], // Create xU as a hint, Z, to prove for bxU without revealing bU
  [I', 0, -Z]  // x (H(k) + bU) + -bxU = x H(k)
]
```

The multi-scalar-multiplication by the consistent row of scalars:
```
[x, a, b]
```

The output is:
```
[
  K',
  B,
  Z,
  I
]
```

where `Z` is part of the proof data (formed as `x U`) and `I` is the key image.

This proves linkability, and again performs spend-authorization so long as the message is part of the proof's transcript.

### Integrity

Obviously, implementation must be done correctly, and the proving system (GBPs) must be proven secure. Forging a member requires breaking the Merkle tree OR `r, r**-1` consistency (for the original proposal) or `bU, bV` consistency (for the current proposal). The original proposal also assumes the trivial `r = 0` case is banned, which it already should be by the rule against key images of identity (though we'd still explicitly prevent it).

### Privacy

The privacy of the originally proposed scheme relies on it being infeasible to link `K', H'` to `K, H(K)`. The most trivial way to solve this is by checking if `DH(K, H(K)) == DH(K', H')`, which is presumably reducible to the Decisional Diffie-Hellman. The Decisional Diffie-Hellman game asks if `DH(A, B) == C`. One who can check if two Diffie-Hellmans would be equivalent can check if a single Diffie-Hellman is equivalent via `DH(A, B) == DH(C, G)`.

The second scheme's privacy is much more clear-cut. Given the commitment `bV`, one must calculate `bU`, which is the Computational Diffie-Hellman (with the caveat Monero key images are currently considered private under the weaker Decisional Diffie-Hellman problem, so this being stronger is irrelevant).

### Features

Not only would this introduce FCMPs to Monero, it would also enable transaction chaining and post-proved membership if we don't bind the membership proof into the secondary proof's (whether DLEq or GSP) transcript.

### Relation to Seraphis

Seraphis offers more efficient FCMPs, should provide forward privacy, and moves from hacked-together formal properties inherent to RingCT to formalized-from-the-start properties.

Unfortunately, Seraphis has been estimated as 2 to 5 years out by UkoeHB, with inclusion of FCMPs making it closer to 5 years. I disagree with that estimate, yet jberman estimated 3 years themselves. The goal of this is to solve the privacy issues solvable under RingCT, buying time to do better regarding design, performance/scalability, and the unsolvable issues (forward privacy). This may also be of indepedent merit.

### Performance

I prior estimated Full-Chain Membership Proofs to be 35ms in a batch of 10. This was evaluated over the "pasta curves" with Bulletproofs+. The arithmetic-circuit argument for Bulletproofs, which we are currently using (or rather, Generalized Bulletproofs, a derivative of), should be twice as fast due to the relation to the underlying proof. This would mean ~18ms within a batch of 10.

Generalized Bulletproofs also notably reduces the amount of gates we use in circuit. Prior, we spent several gates entering the divisor into the circuit (a bunch of numbers which had to be entered *somehow*). Now, with Generalized Bulletproofs, we can simply provide an additional Pedersen Vector Commitment (32 bytes) to enter the divisor. This slashes the size of the circuit.

By adding SA+L, we'll have the additional performance costs within the first layer of:
1) Proving for a tri-set membership.
2) Doing multiple unblinds.
3) Proving consistency of `bH, bG` or `r, r**-1`.

I'm expecting this makes the first layer ~3x more expensive.

So from for 1+1+1+1 at 35ms, to 1+1+1+1 at 18ms, to 3+1+1+1 (~31ms). That's ignoring the reduction in gates offered by GBPs.

### Steps and Timeline

There are several different tracks along which we can move, and we should move along in parallel.

#### Implementation

1) Implement GBPs.

This has already been done and solely needs optimizations performed.

2) Implement an amenable framework for building arithmetic circuits.

This has technically been done, yet needs some love.

3) Implement a library for elliptic curve divisors.

Technically done, yet with an edge case that should be fixed.

4) Implement the various gadgets (set membership, index within set, PoK of DLog, proof of DLog).

This was done as needed for FCMPs, not as needed for FCMP+SA+L which has some distinctions (multi-set membership, which is done via getting the index of each item within each set and checking equality, and proof of DLog).

5) Implement the FCMP+SA+L circuit.

This was done for FCMPs yet not FCMP+SA+L.

6) Implement the secondary proof.

This isn't too notable, with a polished implementation hopefully being within a few days of work for the second case. The first case is prior implemented.

7) Implement the necessary towering curves.

This is trivial to do over a generic integer library, yet performance effectively requires a dedicated implementation be done.

8) Integrate into Monero.

#### Formal Security

1) Formally prove the soundness, completeness, and zero-knowledge properties of GBPs.

We can do this now. Diego claimed a deliverable, or lack thereof if a failure occurs, could happen in one month.

2) Have the divisor-technique reviewed, having been prior published by Eagen.

This is possible now.

3) Formally prove the correctness of the "gadgets", as logical.

This is possible with just a formal description of the circuit, and the gadgets contained within. The Curve Trees paper did specify their gadgets, yet we have a notably different construction due to the usage of divisors and the extensions proposed here.

4) Formally prove the correctness of the secondary proof.

The first proposal uses a DLEq which has existed since Chaum-Pedersen's 1993 work. The second uses a proof I frequently see referred to as a "Generalized Schnorr Protocol", despite my personal dislike for the ascription. I wouldn't be surprised if it was already proven.

#### Practical Secrity

1) Audit the implementation of GBPs.

This is possible once the further optimizations are done, and the formal proofs exist.

2) Audit the circuit framework.

This is possible once the framework is cleaned to a point we're happy with.

3) Audit the EC divisor library.

This is possible as soon as the standing edge case is resolved.

4) Audit the implementation of the gadgets.

This should be trivial and possible as soon as the gadgets are formally proven.

5) Audit the implementations of the towering curves.

This is possible as soon as the curves are implemented. If we implement them with a constant-time integer library, we'd solely audit that.

6) Audit the circuit.

7) Audit the secondary proof.

This could be audited as soon as it's implemented, which again, should be trivial to implement.

8) Audit the integration.

### Contribution to Seraphis

Creation of FCMP+SA+L effectively does all the work necessary for FCMPs with Seraphis with regards to FCMPs themselves. It'd provide the proving system, gadgets, review/audits, and most of the composition work. The only additions would be the curve cycle libraries (if we switched curves), the cross-group DLEq we'd move commitments with, and the new integration (into Seraphis instead of into RingCT).

### Steps Forward

We'd have to agree on which proposal to move forward with, if we were to move forward.

While the first proposal was the one originally posited, it remains here solely for historic reasons. It appears to perform one less PoK of DLog, making it faster, yet it requires using two private points as generators within Proof of (Knowledge of) DLog statements. Such proofs are much more performant when the generator being used is public.

The second proposal also has the benefit of a much stronger argument for privacy, and uses additive randomness (instead of multiplicative).

We'd then need various implementation work done. I can personally implement the curve libraries using crypto-bigint, yet I cannot implement tailored implementations as likely needed to maintain the performance target. Someone else would need to step up.

I believe I can have all the implementation done, besides integration into Monero, within a few months. The actual integration into Monero would be:

1) Having Monero build the tree.
2) Having wallet2 call prove via the Rust library.
3) Adding RPC routes to get the current tree root and the path of a member of the tree (where the DSA would be used to request multiple paths as to not reveal the output being spent).
4) Having monerod call verify via the Rust library.

There'd be no wallet/address/privacy set migration. All of the additional curves would be contained within the proof.

I cannot estimate/guarantee the timeline for the formal analysis side of things. I'd hope by clearly defining components, the rate at which review occurs is not bottlenecked by the rate at which development occurs. That doesn't change we'd have to efficiently manage the timeline and definition of components. I'd hope for, in the best case, development + review/audits of the building blocks in 3-6 months, targeting deployment in ~12 months. Beyond myself, the only development necessary is of dedicated curve implementations (towering curves having already been found by tevador) and the integration into Monero (which jberman already started for FCMPs into Seraphis).