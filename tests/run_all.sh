#!/usr/bin/env bash
set -euo pipefail

echo "== Parse ==" && uv run python tools/compile.py parse --in scheme.yaml --ast ast.json
echo "== OPA ==" && opa test policy -v && opa build -b policy -o policy.tar.gz
echo "== OpenAPI ==" && uv run python tools/compile.py openapi --ast ast.json --out dist/openapi.yaml --target 3.2.0
echo "== Validate ==" && uv run python tools/compile.py validate --in dist/openapi.yaml --fallback 3.1 --report docs/validator_report.md
echo "== Deno ==" && uv run python tools/compile.py deno --ast ast.json --out dist/deno_playground.ts --bundle onefile
echo "== Docs ==" && uv run python tools/diag.py --graph ast.json --out docs
echo "== Coverage ==" && opa test policy --coverage --format=json > docs/opa_coverage.txt

echo "== Budsjett =="
ENDPOINTS=$(grep -R "\"operationId\":" -n dist/openapi.yaml | wc -l | tr -d ' ')
TSKB=$(( $(wc -c < dist/deno_playground.ts) / 1024 ))
[[ $ENDPOINTS -le 30 && $TSKB -le 500 ]] && echo "PASS (endpoints=$ENDPOINTS, ts_kb=$TSKB)" || { echo "FAIL (endpoints=$ENDPOINTS, ts_kb=$TSKB)"; exit 1; }

echo "OK"