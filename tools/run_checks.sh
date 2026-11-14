#!/usr/bin/env bash
# Every machine check of GDD section 18, in one command. Used by CI and before each commit.
# Usage: tools/run_checks.sh [path-to-godot]     (Godot 4.7.x; skipped with a warning if absent)
set -u
cd "$(dirname "$0")/.."
GODOT="${1:-$(command -v godot || true)}"
fail=0
step() { echo; echo "== $1"; shift; "$@" || fail=1; }

step "data validator (schema, registry, references, formulas, exploit, reachability)" python3 tools/validate_data.py
step "validator negative tests" python3 -m unittest -q qa/tests/test_validator.py
step "game/data is in sync with data" python3 tools/sync_data.py --check
step "asset lint" python3 tools/asset_lint.py
if [ -n "$GODOT" ]; then
  "$GODOT" --headless --path game --import >/dev/null 2>&1
  step "engine and gameplay tests" timeout 900 "$GODOT" --headless --path game -s res://tests/run_tests.gd
  step "scripted playthrough of the first loop" timeout 240 "$GODOT" --headless --path game -s res://tests/run_playthrough.gd -- --seed=4 --new --nosave
  echo; echo "== performance bench (information)"; timeout 120 "$GODOT" --headless --path game -s res://tests/run_bench.gd -- --new --nosave 2>&1 | grep BENCH
else
  echo; echo "WARNING: Godot not found; engine tests skipped"; fail=1
fi
echo
[ $fail -eq 0 ] && echo "ALL CHECKS PASS" || echo "SOME CHECKS FAILED"
exit $fail
