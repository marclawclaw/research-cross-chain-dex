#!/usr/bin/env bash
# new-rfp.sh — Bootstrap research repo + RFP branch, then print launch command.
#
# Usage:
#   ./scripts/new-rfp.sh <topic> <slug> "<brief>"
#
# Example:
#   ./scripts/new-rfp.sh privacy-dex privacy-preserving-dex \
#     "Privacy-preserving DEX on LEZ with shielded swaps"

set -euo pipefail

TOPIC="${1:?Usage: $0 <topic> <slug> \"<brief>\"}"
SLUG="${2:?Usage: $0 <topic> <slug> \"<brief>\"}"
BRIEF="${3:?Usage: $0 <topic> <slug> \"<brief>\"}"

RESEARCH_DIR="$HOME/src/marclawclaw/research-${TOPIC}"
RFP_REPO="$HOME/src/logos-co/rfp"

# ── 1. Create research Obsidian vault ────────────────────────────────
if [[ -d "${RESEARCH_DIR}" ]]; then
  echo "Research repo already exists: ${RESEARCH_DIR}" >&2
else
  echo "==> Creating research vault: ${RESEARCH_DIR}"
  mkdir -p "${RESEARCH_DIR}"/{.obsidian,projects,metrics,patterns}

  cat > "${RESEARCH_DIR}/.obsidian/app.json" << 'OBCFG'
{
  "showLineNumber": true,
  "strictLineBreaks": true,
  "useMarkdownLinks": false
}
OBCFG

  cat > "${RESEARCH_DIR}/README.md" << EOF
# Research: ${TOPIC}

Obsidian vault containing ecosystem research for RFP \`${SLUG}\`.

## Structure
- \`projects/\` — one atomic note per comparable project
- \`metrics/\` — cross-project metric comparisons
- \`patterns/\` — common design patterns and behaviours
- \`summary.md\` — synthesis for the RFP writer

Open this folder in Obsidian for full graph and backlink support.
EOF

  cd "${RESEARCH_DIR}"
  git init
  git add -A
  git commit -m "init: obsidian vault for ${TOPIC} research"
  gh repo create "marclawclaw/research-${TOPIC}" --public --push --source=.
  echo "==> Research repo: https://github.com/marclawclaw/research-${TOPIC}"
fi

# ── 2. Create RFP branch ────────────────────────────────────────────
cd "${RFP_REPO}"
git fetch origin

if git rev-parse --verify "rfp/${SLUG}" >/dev/null 2>&1; then
  echo "Branch rfp/${SLUG} already exists" >&2
else
  echo "==> Creating branch: rfp/${SLUG}"
  git branch "rfp/${SLUG}" origin/master
  echo "==> Branch ready: rfp/${SLUG}"
fi

# ── 3. Print launch command ──────────────────────────────────────────
cat << EOF

==========================================
 Ready. Launch the orchestrator:
==========================================

  claude "New RFP: ${BRIEF}
    TOPIC=${TOPIC}
    SLUG=${SLUG}
    RESEARCH_DIR=${RESEARCH_DIR}
    RFP_REPO=${RFP_REPO}
    BRANCH=rfp/${SLUG}"

EOF
