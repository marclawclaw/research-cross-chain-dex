---
id: RFP-[NUMBER]
title: [Project Title]
tier: XS/S/M/L/XL
funding: $XXXXX
status: open
category: Developer Tooling & Infrastructure / Applications & Integrations / Ecosystem & Community Enablement
---

# RFP-[NUMBER] — [Project Title]

## Overview

[4-6 sentences. What to build, why it matters, ecosystem data with numbers,
team profile hint.]

## Why This Matters

[4-6 sentences. Ecosystem criticality, what happens without it, problem data,
LEZ structural advantage.]

## Scope of Work

### Hard Requirements

#### Functionality

1. [Testable statement]

#### Usability

1. Provide an SDK that can be used to build Logos modules for
   interacting with the program.
2. Provide a Logos mini-app GUI with local build instructions,
   downloadable assets, and loadable in Logos app (Basecamp) via
   git repo.
3. Provide a CLI that covers core functionality of the program.
4. Provide an IDL for the LEZ program, preferably using the
   [SPEL framework](https://github.com/logos-co/spel).
5. [Domain-specific documentation and UX requirements]

#### Reliability

1. [Testable statement]

#### Performance

1. [Measurable criteria]

#### Supportability

1. The program is deployed and tested on LEZ devnet/testnet.
2. End-to-end integration tests run against a LEZ sequencer (standalone
   mode) and are included in CI; CI must be green on the default branch.
3. Every hard requirement in Functionality, Usability, Reliability,
   and Performance has at least one corresponding test.
4. A README documents end-to-end usage: deployment steps, program
   addresses, and step-by-step instructions for interacting via CLI
   and front-end.

#### + [Domain extension]

1. [Testable statement]

## Recommended Team Profile

Team experienced with:

- [Skill]

## Timeline Expectations

Estimated duration: **[X] weeks** ([justification]).

## Open Source Requirement

All code must be released under the **MIT+Apache2.0 dual License**.

## Resources

- [Logos Documentation](https://github.com/logos-co/logos-docs)

## How to Apply

Submit a proposal using the Issue form:

**[Submit Proposal](https://github.com/logos-co/rfp/issues/new?template=proposal.yml)**

We typically respond within **14 days**. For clarification questions,
please use **Discussions**.
