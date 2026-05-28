#!/usr/bin/env bash
# Parse every entity in entity.datadog.yaml and verify each has the v3 required fields.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 <<'PY'
import sys
import yaml

path = "entity.datadog.yaml"
with open(path) as fh:
    docs = list(yaml.safe_load_all(fh))

ok = 0
fail = 0
seen_names = {}
known_kinds = {"system", "service", "datastore", "queue", "api"}

for i, doc in enumerate(docs):
    if doc is None:
        continue
    label = f"doc#{i}"
    try:
        assert doc.get("apiVersion") == "v3", "apiVersion must be v3"
        kind = doc.get("kind")
        assert kind in known_kinds, f"kind must be one of {sorted(known_kinds)}, got {kind!r}"
        name = doc.get("metadata", {}).get("name")
        assert name, "metadata.name is required"
        label = f"{kind}:{name}"
        prior = seen_names.get(label)
        assert prior is None, f"duplicate {label} (first seen at doc#{prior})"
        seen_names[label] = i
        print(f"OK     {label}")
        ok += 1
    except AssertionError as e:
        print(f"FAIL   {label}: {e}")
        fail += 1

# Cross-check: system.components references must point to entities defined in this file.
system_doc = next((d for d in docs if d and d.get("kind") == "system"), None)
if system_doc:
    refs = system_doc.get("spec", {}).get("components", []) or []
    missing = [r for r in refs if r not in seen_names]
    if missing:
        print(f"FAIL   system.components references not defined in this file: {missing}")
        fail += len(missing)
    else:
        print(f"OK     system.components — all {len(refs)} references resolve locally")

print()
print(f"Validated {ok} entity/entities, {fail} failure(s).")
sys.exit(0 if fail == 0 else 1)
PY
