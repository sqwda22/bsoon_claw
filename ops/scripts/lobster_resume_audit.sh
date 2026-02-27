#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECISION="${1:-yes}"   # yes|no
STATE_FILE="$ROOT/ops/state/lobster_audit_approval.json"

if [[ ! -f "$STATE_FILE" ]]; then
  echo '{"ok":false,"error":"state_file_missing"}'
  exit 1
fi

TOKEN=$(python3 - <<'PY'
import json,sys
from pathlib import Path
p=Path('/home/sqwda/.openclaw/workspace/ops/state/lobster_audit_approval.json')
obj=json.loads(p.read_text())
print((obj.get('requiresApproval') or {}).get('resumeToken') or '')
PY
)

if [[ -z "$TOKEN" ]]; then
  echo '{"ok":false,"error":"resume_token_missing"}'
  exit 1
fi

OUT=$(lobster resume --mode tool --token "$TOKEN" --approve "$DECISION")
printf '%s\n' "$OUT" > "$STATE_FILE"
printf '%s\n' "$OUT"

# If approved and workflow applied changes, commit/push docs.
if [[ "$DECISION" == "yes" ]]; then
  STATUS=$(printf '%s' "$OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))')
  if [[ "$STATUS" == "ok" ]]; then
    git -C "$ROOT" add COMMITMENTS.md DECISIONS.md POLICY.md 2>/dev/null || true
    if ! git -C "$ROOT" diff --cached --quiet; then
      git -C "$ROOT" commit -m "Apply approved audit improvements via lobster" >/dev/null 2>&1 || true
      git -C "$ROOT" push origin "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)" >/dev/null 2>&1 || true
    fi
  fi
fi
