#!/bin/bash
set -euo pipefail

OWNER='quarto-dev'
REPO='quarto-cli'
OUTPUT_FILE="releases.csv"

# Use the REST releases endpoint: assets are nested per release in the
# response, and there's no GraphQL-style complexity limit, so a single
# `--paginate` call captures every release (~18 pages of 100).
echo "created,name,download_count" > "${OUTPUT_FILE}"

gh api "repos/${OWNER}/${REPO}/releases" --paginate \
  --jq '.[] | .created_at as $date | .assets[] | [$date, .name, .download_count] | @csv' \
  >> "${OUTPUT_FILE}"

ROWS=$(($(wc -l < "${OUTPUT_FILE}") - 1))
echo "Wrote ${ROWS} asset rows to ${OUTPUT_FILE}"
