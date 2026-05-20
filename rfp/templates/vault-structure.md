# Obsidian Vault Template for Research Repos

This template describes the structure for research vaults created at
`~/src/marclawclaw/research-<topic>`.

## Directory structure

```
research-<topic>/
├── .obsidian/
│   └── app.json             # Minimal Obsidian config
├── README.md                # Vault overview (also GitHub landing page)
├── _index.md                # Research index with project list and status
├── summary.md               # Final synthesis (created on synthesis branch)
├── projects/
│   ├── <project-a>.md       # One atomic note per project
│   ├── <project-b>.md
│   └── ...
├── metrics/
│   ├── tvl-comparison.md    # Cross-project metric comparisons
│   ├── volume-comparison.md
│   └── ...
├── patterns/
│   ├── <behaviour-a>.md     # Shared design patterns / behaviours
│   ├── <behaviour-b>.md
│   └── ...
└── sources.md               # Master source list (optional)
```

## Conventions

- **File names:** kebab-case, no spaces (e.g. `uniswap-v3.md`)
- **Cross-references:** use `[[wikilinks]]` (e.g. `[[projects/aave]]`)
- **Frontmatter:** YAML with tags, ecosystem, category
- **One concept per note:** link rather than duplicate
- **Australian English spelling** throughout
