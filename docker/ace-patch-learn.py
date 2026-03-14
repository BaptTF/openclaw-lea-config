"""Patch learn_from_traces.py for LiteLLM proxy compatibility.

Applies two fixes:
1. Wraps LiteLLMClient with InstructorClient (MD_JSON mode) for reliable
   structured output parsing through LiteLLM proxies.
2. Adds ACE_MAX_TOKENS env var support (default 16384) to avoid truncated
   responses on large session traces.
"""

from pathlib import Path
import re

script = Path("examples/openclaw/kayba-ace/learn_from_traces.py")
content = script.read_text()

# Patch 1: Replace bare LiteLLMClient with InstructorClient wrapper
old = '''    client = LiteLLMClient(
        model=MODEL,
        api_key=api_key,
    )'''

new = '''    max_tokens = int(os.getenv("ACE_MAX_TOKENS", "16384"))
    base_client = LiteLLMClient(
        model=MODEL,
        api_key=api_key,
        max_tokens=max_tokens,
    )

    # Wrap with InstructorClient for robust structured output parsing.
    # MD_JSON mode works reliably through LiteLLM proxies (including Bedrock).
    try:
        from ace_next.providers.instructor import InstructorClient
        import instructor as _instructor

        client = InstructorClient(base_client, mode=_instructor.Mode.MD_JSON)
        print(f"  Using InstructorClient (mode=MD_JSON, max_tokens={max_tokens})")
    except ImportError:
        client = base_client
        print(f"  Using LiteLLMClient (max_tokens={max_tokens})")'''

if old in content:
    content = content.replace(old, new)
    script.write_text(content)
    print("✓ Patched learn_from_traces.py (InstructorClient + max_tokens)")
else:
    print("⚠ Patch target not found — script may already be patched or has changed")
