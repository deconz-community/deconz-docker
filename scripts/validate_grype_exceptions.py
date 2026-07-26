#!/usr/bin/env python3
"""Validate and render temporary, tightly scoped Grype exceptions."""
import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "security/bookworm-gosu-go-exceptions.json"
EXPECTED_PACKAGE = {"name": "stdlib", "version": "go1.19.8", "type": "go-module"}
EXPIRY = {"Critical": "2026-08-09", "High": "2026-08-25"}

def fail(message):
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)

parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path, required=True, help="generated Grype config path")
args = parser.parse_args()

data = json.loads(REGISTRY.read_text())
if data.get("package") != EXPECTED_PACKAGE:
    fail("registry package constraint changed")

entries = data.get("exceptions", [])
ids = [entry.get("cve") for entry in entries]
if len(entries) != 49 or len(ids) != len(set(ids)) or any(not item for item in ids):
    fail("registry must contain exactly 49 unique CVEs")

today = dt.date.today()
for entry in entries:
    if not re.fullmatch(r"CVE-\d{4}-\d+", entry.get("cve", "")):
        fail(f"{entry.get('cve')}: invalid CVE syntax")
    severity = entry.get("severity")
    if severity not in EXPIRY or entry.get("expires") != EXPIRY[severity]:
        fail(f"{entry.get('cve')}: invalid severity or expiry")
    if dt.date.fromisoformat(entry["expires"]) < today:
        fail(f"{entry['cve']}: exception expired")

lines = ["only-fixed: true", "ignore:"]
for entry in entries:
    lines.extend((
        f"  - vulnerability: {entry['cve']}",
        "    package:",
        "      name: stdlib",
        "      version: go1.19.8",
        "      type: go-module",
        "    reason: \"Temporary gosu embedded Go stdlib exception\"",
    ))
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text("\n".join(lines) + "\n")

print(f"validated and rendered {len(ids)} temporary Grype exceptions")
