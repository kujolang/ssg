#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$repo_root" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
catalog = json.loads((root / "abilities/registry.json").read_text())
assert catalog["schema"] == "kujo.ssg.ability-catalog/v1"
assert catalog["ability_version"] == "1.0.1"
ids = []
for entry in catalog["entries"]:
    definition = json.loads((root / "abilities" / entry["definition"]).read_text())
    assert definition["schema"] == "kujo.ability/v1"
    assert definition["version"] == "1.0.0"
    assert definition["input_schema"]["type"] == "object"
    assert definition["output_schema"]["type"] == "object"
    assert definition["effects"]
    ids.append(definition["id"])
assert len(ids) == len(set(ids)) == 3
assert "kujo.ssg.site.build" in ids
print("SSG Ability catalog contract passed")
PY
