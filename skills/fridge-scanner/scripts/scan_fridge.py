#!/usr/bin/env python3
"""
Fridge Scanner - Vision analysis using Featherless AI (OpenAI-compatible)
Identifies ingredients in a fridge/pantry photo and saves results as JSON.
"""

import argparse
import base64
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    from openai import OpenAI
except ImportError:
    print("Error: openai package not installed. Run: python3 -m pip install openai --break-system-packages")
    sys.exit(1)

VISION_MODEL = "Qwen/Qwen3-VL-30B-A3B-Instruct"
FEATHERLESS_BASE_URL = "https://api.featherless.ai/v1"

SYSTEM_PROMPT = """You are an expert kitchen assistant. Analyze photos of fridges,
pantries, and groceries, then return a precise structured inventory of everything visible."""

VISION_PROMPT = """Analyze this image and identify all visible food ingredients and items.

Return ONLY valid JSON (no markdown, no explanation) in this exact format:
{
  "ingredients": [
    {
      "name": "ingredient name (lowercase)",
      "category": "one of: dairy, produce, protein, grains, condiments, beverages, frozen, snacks, other",
      "quantity": "estimated quantity (e.g. '1 carton', '3 apples', 'half full bottle')",
      "condition": "one of: good, used, low, expired, unknown",
      "confidence": "one of: high, medium, low",
      "notes": "optional extra detail"
    }
  ],
  "summary": "1-2 sentence friendly summary of the fridge contents",
  "scan_notes": "any image quality issues or scanning limitations"
}

Be thorough — identify every visible item, even partially visible ones."""


def load_image_as_base64(image_path: str) -> tuple:
    """Load an image file and return base64 data URI."""
    path = Path(image_path)
    ext = path.suffix.lower()
    media_types = {
        ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
        ".png": "image/png", ".webp": "image/webp", ".gif": "image/gif",
    }
    media_type = media_types.get(ext)
    if not media_type:
        print(f"Error: Unsupported format '{ext}'. Use JPG, PNG, WEBP, or GIF.")
        sys.exit(1)

    with open(path, "rb") as f:
        data = base64.standard_b64encode(f.read()).decode("utf-8")

    return f"data:{media_type};base64,{data}"


def scan_fridge(image_path: str, output_path: str = None) -> dict:
    api_key = os.environ.get("FEATHERLESS_API_KEY") or os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("Error: FEATHERLESS_API_KEY environment variable not set.")
        sys.exit(1)

    client = OpenAI(api_key=api_key, base_url=FEATHERLESS_BASE_URL)

    print(f"Loading image: {image_path}")
    image_data_uri = load_image_as_base64(image_path)

    print(f"Analyzing with {VISION_MODEL}...")

    response = None
    for attempt in range(2):
        try:
            response = client.chat.completions.create(
                model=VISION_MODEL,
                max_tokens=2000,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": [
                            {"type": "image_url", "image_url": {"url": image_data_uri}},
                            {"type": "text", "text": VISION_PROMPT},
                        ],
                    },
                ],
            )
            break
        except Exception as e:
            if attempt == 0:
                print(f"Retrying after error: {e}")
            else:
                print(f"Error: API call failed: {e}")
                sys.exit(1)

    raw_text = response.choices[0].message.content.strip()

    # Strip markdown fences if present
    if raw_text.startswith("```"):
        parts = raw_text.split("```")
        raw_text = parts[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
        raw_text = raw_text.strip()

    try:
        vision_result = json.loads(raw_text)
    except json.JSONDecodeError as e:
        print(f"Error: Could not parse response as JSON: {e}")
        print(f"Raw: {raw_text[:500]}")
        sys.exit(1)

    scan_result = {
        "scan_date": datetime.now(timezone.utc).isoformat(),
        "image_source": Path(image_path).name,
        "model": VISION_MODEL,
        "ingredient_count": len(vision_result.get("ingredients", [])),
        "ingredients": vision_result.get("ingredients", []),
        "summary": vision_result.get("summary", ""),
        "scan_notes": vision_result.get("scan_notes", ""),
    }

    if not output_path:
        date_str = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        output_path = f"/data/workspace/fridge_scan_{date_str}.json"

    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(scan_result, f, indent=2, ensure_ascii=False)

    # Sync to pantry.db using Python sqlite3
    try:
        import sqlite3 as _sqlite3
        db = _sqlite3.connect("/data/workspace/pantry.db")
        db.execute("CREATE TABLE IF NOT EXISTS fridge (item TEXT PRIMARY KEY, quantity TEXT, updated_at TEXT)")
        for item in scan_result["ingredients"]:
            db.execute(
                "INSERT OR REPLACE INTO fridge (item,quantity,updated_at) VALUES (?,?,datetime('now'))",
                (item["name"], item.get("quantity", "detected"))
            )
        db.commit()
        db.close()
        print(f"Synced {scan_result['ingredient_count']} items to pantry.db")
    except Exception as e:
        print(f"Warning: Could not sync to pantry.db: {e}")

    print(f"✅ Found {scan_result['ingredient_count']} ingredients.")
    print(f"💾 Saved to: {output_file}")
    return scan_result


def main():
    parser = argparse.ArgumentParser(description="Scan a fridge photo using Featherless AI vision")
    parser.add_argument("--image", required=True, help="Path to image file")
    parser.add_argument("--output", help="Output JSON path (optional)")
    parser.add_argument("--print", action="store_true", help="Print results to stdout")
    args = parser.parse_args()

    if not Path(args.image).exists():
        print(f"Error: Image not found: {args.image}")
        sys.exit(1)

    result = scan_fridge(args.image, args.output)
    if args.print:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
