#!/usr/bin/env python3
"""
DCC-B AI Helper — OpenAI / ChatGPT integration utility.

Uses the OpenAI chat completions API to assist with content generation
for the DCC-B dungeon crawler mod (floor rules, NPC archetypes, region
profiles, reward tables, etc.).

Setup
-----
1. Copy .env.example to .env and add your OpenAI API key:

       cp .env.example .env
       # then edit .env and set OPENAI_API_KEY=sk-...

2. Install the dependency:

       pip install openai

3. Run:

       python ai_helper.py "Design a volcanic region profile for DCC-B"
"""

import os
import sys
import json

# ---------------------------------------------------------------------------
# API key configuration
# ---------------------------------------------------------------------------
# The key is read from the OPENAI_API_KEY environment variable.
# You can set it in a .env file (see .env.example) or export it directly:
#
#   export OPENAI_API_KEY="sk-..."
#
# ---------------------------------------------------------------------------

def _load_dotenv() -> None:
    """Load variables from a .env file in the repo root, if present."""
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if not os.path.isfile(env_path):
        return
    with open(env_path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip("\"'")
            if not os.environ.get(key):
                os.environ[key] = value


_load_dotenv()


def _get_api_key() -> str:
    """Return the OpenAI API key or exit with a helpful message."""
    key = os.environ.get("OPENAI_API_KEY", "")
    if not key or key == "your-api-key-here":
        print(
            "ERROR: OPENAI_API_KEY is not set.\n"
            "\n"
            "1. Copy .env.example to .env:\n"
            "       cp .env.example .env\n"
            "\n"
            "2. Open .env and replace 'your-api-key-here' with your real key.\n"
            "   Get one at https://platform.openai.com/api-keys\n",
            file=sys.stderr,
        )
        sys.exit(1)
    return key


# ---------------------------------------------------------------------------
# System prompt — gives ChatGPT context about the DCC-B project
# ---------------------------------------------------------------------------
SYSTEM_PROMPT = """\
You are a senior gameplay systems engineer working on DCC-B, a modular
dungeon crawler framework inspired by Dungeon Crawler Carl.

The project targets Tales of Maj'Eyal (ToME / T-Engine4) as its engine
integration layer. It is data-driven: regions, floor rules, NPC
archetypes, reward tables, and mutations are all defined as JSON files.

When generating content, follow these rules:
- Output valid JSON unless asked otherwise.
- Respect the data schemas defined in DCC-DataSchemas.md.
- Keep designs modular and engine-agnostic in the core layer.
- Engine-specific code belongs only in the integration layer.
- All randomness must be seed-deterministic.

Provide clean, concise output suitable for direct use or light editing.\
"""

# ---------------------------------------------------------------------------
# Model configuration
# ---------------------------------------------------------------------------
# Change this to use a different OpenAI model (e.g. "gpt-4o", "gpt-4",
# "gpt-3.5-turbo").
DEFAULT_MODEL = "gpt-4o"


def chat(prompt: str, *, model: str = DEFAULT_MODEL) -> str:
    """Send a prompt to OpenAI and return the assistant's reply.

    Parameters
    ----------
    prompt : str
        The user message to send.
    model : str
        The OpenAI model to use (default: gpt-4o).

    Returns
    -------
    str
        The text content of the assistant's response.
    """
    try:
        from openai import OpenAI  # noqa: E402
    except ImportError:
        print(
            "ERROR: the 'openai' package is not installed.\n"
            "       Install it with:  pip install openai",
            file=sys.stderr,
        )
        sys.exit(1)

    api_key = _get_api_key()
    client = OpenAI(api_key=api_key)

    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
        )
    except Exception as exc:
        print(f"ERROR: OpenAI API call failed: {exc}", file=sys.stderr)
        sys.exit(1)

    return response.choices[0].message.content


def generate_json(prompt: str, *, model: str = DEFAULT_MODEL) -> dict:
    """Send a prompt and parse the response as JSON.

    Useful for generating data files (regions, floor rules, etc.).
    """
    raw = chat(prompt, model=model)

    # Strip markdown code fences if the model wraps its answer
    text = raw.strip()
    if text.startswith("```"):
        # Remove opening fence (possibly ```json)
        text = text.split("\n", 1)[1] if "\n" in text else text[3:]
    if text.endswith("```"):
        text = text[:-3]

    try:
        return json.loads(text.strip())
    except json.JSONDecodeError as exc:
        print(
            f"ERROR: Failed to parse model response as JSON: {exc}\n"
            f"Raw response:\n{raw}",
            file=sys.stderr,
        )
        sys.exit(1)


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------
def main() -> None:
    if len(sys.argv) < 2:
        print(
            "Usage: python ai_helper.py <prompt>\n"
            "\n"
            "Examples:\n"
            '  python ai_helper.py "Design a volcanic region profile"\n'
            '  python ai_helper.py "Generate a reward table for floor 5"',
            file=sys.stderr,
        )
        sys.exit(1)

    prompt = " ".join(sys.argv[1:])
    result = chat(prompt)
    print(result)


if __name__ == "__main__":
    main()
