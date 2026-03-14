#!/bin/bash
# ace-learn — Learn from OpenClaw session transcripts using ACE framework
#
# Reads JSONL session files, extracts patterns (what worked, what failed),
# and updates a skillbook of reusable strategies.
#
# Usage:
#   ace-learn                          # Process all new sessions
#   ace-learn --dry-run                # Parse only, no LLM calls
#   ace-learn --reprocess              # Reprocess all sessions
#   ace-learn <file.jsonl> [...]       # Process specific files
#
# Configuration (env vars):
#   ACE_MODEL          LLM model for reflection (default: bedrock/us.anthropic.claude-sonnet-4-20250514-v1:0)
#   OPENCLAW_AGENT_ID  Agent ID for session discovery (default: main)
#
# The script auto-detects available API keys (AWS Bedrock, Anthropic,
# OpenRouter, LiteLLM, OpenAI) and routes through whichever is configured.
#
# Output is written to $OPENCLAW_HOME/workspace/skills/kayba-ace/:
#   ace_skillbook.json   Machine-readable skillbook
#   ace_skillbook.md     Human-readable strategies (loaded by agent)
#   ace_processed.txt    Tracks already-processed sessions

set -euo pipefail

export OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OUTPUT_DIR="$OPENCLAW_HOME/workspace/skills/kayba-ace"
mkdir -p "$OUTPUT_DIR"

cd /opt/ace
exec .venv/bin/python examples/openclaw/kayba-ace/learn_from_traces.py \
    --output "$OUTPUT_DIR" \
    "$@"
