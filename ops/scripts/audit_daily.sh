#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TZ="Asia/Seoul"
TODAY="$(TZ="$TZ" date +%F)"
YDAY="$(TZ="$TZ" date -d 'yesterday' +%F)"
NOW="$(TZ="$TZ" date '+%F %T %Z')"
OUT="$ROOT/ops/audits/daily/$TODAY.md"
EVENT_LOG="$ROOT/ops/logs/events/$TODAY.jsonl"

mkdir -p "$(dirname "$OUT")" "$(dirname "$EVENT_LOG")"
touch "$EVENT_LOG"

required_files=(
  "$ROOT/POLICY.md"
  "$ROOT/COMMITMENTS.md"
  "$ROOT/DECISIONS.md"
  "$ROOT/USER.md"
)

missing=()
for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || missing+=("$f")
done

count_events=$(wc -l < "$EVENT_LOG" 2>/dev/null || echo 0)

dup_policy_ids=$(grep -oE '^### P-[0-9]+' "$ROOT/POLICY.md" 2>/dev/null | awk '{print $2}' | sort | uniq -d || true)
dup_commit_ids=$(grep -oE '^\| C-[0-9]+' "$ROOT/COMMITMENTS.md" 2>/dev/null | awk '{print $2}' | sort | uniq -d || true)
dup_decision_ids=$(grep -oE '^### D-[0-9]+' "$ROOT/DECISIONS.md" 2>/dev/null | awk '{print $2}' | sort | uniq -d || true)

# simple todo extraction
commit_todos=$(awk -F'\|' '/^\| C-[0-9]+/ {gsub(/^[ \t]+|[ \t]+$/, "", $3); gsub(/^[ \t]+|[ \t]+$/, "", $4); if($3 !~ /done|dropped/) print "- " $4}' "$ROOT/COMMITMENTS.md" 2>/dev/null | head -n 5 || true)

# derive issue counters (fact-only)
issues=0
[[ ${#missing[@]} -gt 0 ]] && issues=$((issues+${#missing[@]}))
[[ -n "$dup_policy_ids" ]] && issues=$((issues+1))
[[ -n "$dup_commit_ids" ]] && issues=$((issues+1))
[[ -n "$dup_decision_ids" ]] && issues=$((issues+1))

# L3 inference confidence (rule-based)
if [[ "$issues" -eq 0 ]]; then
  conf="high"
  health="정상"
else
  conf="medium"
  health="주의"
fi

{
  echo "# Daily Audit - $TODAY"
  echo
  echo "- 실행시각: $NOW"
  echo "- 전일 기준일: $YDAY"
  echo
  echo "## L3 Summary"
  echo "- 상태: $health"
  echo "- 근거 기반 이슈 수: $issues"
  echo "- 자동추론 신뢰도: $conf"
  echo
  echo "## FACT (로그/문서 근거)"
  echo "- 이벤트 로그 라인수: $count_events (근거: ops/logs/events/$TODAY.jsonl)"
  if ((${#missing[@]}==0)); then
    echo "- 필수 문서 존재: 이상 없음 (근거: POLICY/COMMITMENTS/DECISIONS/USER 파일 검사)"
  else
    echo "- 필수 문서 누락:"
    for m in "${missing[@]}"; do echo "  - $m"; done
  fi
  [[ -z "$dup_policy_ids" ]] && echo "- POLICY 중복 ID: 없음" || echo "- POLICY 중복 ID: $dup_policy_ids"
  [[ -z "$dup_commit_ids" ]] && echo "- COMMITMENTS 중복 ID: 없음" || echo "- COMMITMENTS 중복 ID: $dup_commit_ids"
  [[ -z "$dup_decision_ids" ]] && echo "- DECISIONS 중복 ID: 없음" || echo "- DECISIONS 중복 ID: $dup_decision_ids"
  echo
  echo "## INFERENCE (사실 기반 해석)"
  if [[ "$issues" -eq 0 ]]; then
    echo "- 현재 문서 정합성 기준으로 즉시 위험 징후 없음."
  else
    echo "- 누락/중복으로 인해 향후 적용 누수 가능성이 있음."
  fi
  echo "- 이벤트 로그가 낮은 경우(또는 0) 관측 기반 개선이 제한될 수 있음."
  echo
  echo "## ACTION (실행 항목)"
  if [[ "$issues" -eq 0 ]]; then
    echo "- 유지: 현재 정책/약속 문서 구조 유지"
  else
    echo "- 수정: 누락/중복 항목 우선 정리"
  fi
  echo "- 다음 실행 전 이벤트 로그 입력 경로 점검"
  echo
  echo "## 다음날/이월 TODO"
  if [[ -n "$commit_todos" ]]; then
    echo "$commit_todos"
  else
    echo "- (추출된 TODO 없음)"
  fi
  echo
  echo "## COMMITMENTS 반영 필요 항목"
  echo "- [ ]"
} > "$OUT"

echo "[daily] wrote $OUT"
