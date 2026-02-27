#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TZ="Asia/Seoul"
TODAY="$(TZ="$TZ" date +%F)"
DOW="$(TZ="$TZ" date +%u)"          # 1=Mon .. 7=Sun
TOMORROW_DAY="$(TZ="$TZ" date -d 'tomorrow' +%d)"
RUN_LOG="$ROOT/ops/logs/runs/$TODAY.log"

# cron-safe path (non-login shell)
export PATH="/home/sqwda/.nvm/versions/node/v24.13.1/bin:/home/sqwda/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
LOBSTER_BIN_DEFAULT="/home/sqwda/.nvm/versions/node/v24.13.1/bin/lobster"

mkdir -p "$(dirname "$RUN_LOG")"

log() {
  echo "[$(TZ="$TZ" date '+%F %T %Z')] $*" >> "$RUN_LOG"
}



run_lobster_audit_workflow() {
  local state_file="$ROOT/ops/state/lobster_audit_approval.json"
  mkdir -p "$ROOT/ops/state"

  local lobster_bin="${LOBSTER_BIN:-$LOBSTER_BIN_DEFAULT}"
  if [[ ! -x "$lobster_bin" ]]; then
    lobster_bin="$(command -v lobster 2>/dev/null || true)"
  fi
  if [[ -z "$lobster_bin" || ! -x "$lobster_bin" ]]; then
    log "[lobster] skip: lobster binary not found"
    return 0
  fi

  # Keep existing pending approval until resolved.
  if [[ -f "$state_file" ]]; then
    local pending
    pending=$(python3 - <<'PY2'
import json
from pathlib import Path
p=Path('/home/sqwda/.openclaw/workspace/ops/state/lobster_audit_approval.json')
try:
  o=json.loads(p.read_text())
  print('yes' if o.get('status')=='needs_approval' and (o.get('requiresApproval') or {}).get('resumeToken') else 'no')
except Exception:
  print('no')
PY2
)
    if [[ "$pending" == "yes" ]]; then
      log "[lobster] pending approval exists; skip new candidate run"
      return 0
    fi
  fi

  local tmp
  tmp="$(mktemp)"
  if (cd "$ROOT" && "$lobster_bin" run --mode tool --file ops/workflows/audit-improvement.lobster > "$tmp" 2>>"$RUN_LOG"); then
    mv "$tmp" "$state_file"
    local st tok
    st=$(python3 - <<'PY3'
import json
from pathlib import Path
p=Path('/home/sqwda/.openclaw/workspace/ops/state/lobster_audit_approval.json')
o=json.loads(p.read_text())
print(o.get('status',''))
PY3
)
    tok=$(python3 - <<'PY4'
import json
from pathlib import Path
p=Path('/home/sqwda/.openclaw/workspace/ops/state/lobster_audit_approval.json')
o=json.loads(p.read_text())
print('yes' if (o.get('requiresApproval') or {}).get('resumeToken') else 'no')
PY4
)
    log "[lobster] workflow status=$st token=$tok"
  else
    rm -f "$tmp"
    log "[lobster] workflow run failed"
    return 1
  fi
}

commit_and_push() {
  if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "[git] skip: $ROOT is not a git repository"
    return 0
  fi

  # add only managed paths (avoid accidental add of unrelated untracked files)
  git -C "$ROOT" add -u
  for path in POLICY.md COMMITMENTS.md DECISIONS.md USER.md MEMORY.md TOOLS.md memory ops/scripts ops/policies ops/workflows; do
    if [[ -e "$ROOT/$path" ]]; then
      git -C "$ROOT" add -- "$path" 2>/dev/null || true
    fi
  done

  if git -C "$ROOT" diff --cached --quiet; then
    log "[git] no changes to commit"
    return 0
  fi

  local branch
  branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
  local msg="chore(audit): daily sync $TODAY"

  if git -C "$ROOT" commit -m "$msg" >/dev/null 2>&1; then
    local sha
    sha="$(git -C "$ROOT" rev-parse --short HEAD)"
    log "[git] committed: $sha"
  else
    log "[git] commit failed"
    return 1
  fi

  if git -C "$ROOT" push origin "$branch" >/dev/null 2>&1; then
    log "[git] pushed: origin/$branch"
  else
    log "[git] push failed (hint: run `gh auth setup-git` once in this environment)"
    return 1
  fi

  return 0
}

log "dispatch start"

"$ROOT/ops/scripts/audit_daily.sh" >> "$RUN_LOG" 2>&1

if [[ "$DOW" == "7" ]]; then
  "$ROOT/ops/scripts/audit_weekly.sh" >> "$RUN_LOG" 2>&1
fi

if [[ "$TOMORROW_DAY" == "01" ]]; then
  "$ROOT/ops/scripts/audit_monthly.sh" >> "$RUN_LOG" 2>&1
fi

if [[ "$DOW" == "7" ]]; then
  run_lobster_audit_workflow >> "$RUN_LOG" 2>&1 || true
fi

# Run commit/push after all scheduled audits finish.
if commit_and_push; then
  log "dispatch end"
else
  log "dispatch end (with git warning)"
fi
