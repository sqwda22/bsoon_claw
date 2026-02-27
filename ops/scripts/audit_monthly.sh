#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TZ="Asia/Seoul"
MONTH_ID="$(TZ="$TZ" date +%Y-%m)"
NOW="$(TZ="$TZ" date '+%F %T %Z')"
OUT="$ROOT/ops/audits/monthly/$MONTH_ID.md"

mkdir -p "$(dirname "$OUT")"

weekly_reports=$(find "$ROOT/ops/audits/weekly" -maxdepth 1 -type f -name "${MONTH_ID}*.md" | wc -l)
monthly_event_sum=$(find "$ROOT/ops/logs/events" -maxdepth 1 -type f -name "${MONTH_ID}-*.jsonl" -print0 | xargs -0 -r wc -l | awk 'END{print ($1+0)}')

{
  echo "# Monthly Audit - $MONTH_ID"
  echo
  echo "- 실행시각: $NOW"
  echo "- 월간 이벤트 총 라인수: ${monthly_event_sum:-0}"
  echo "- 월간 주간 감사 리포트 수: $weekly_reports"
  echo
  echo "## 1) 월간 종합 (weekly + events)"
  echo "- 요약:"
  echo
  echo "## 2) 정책 체계 점검"
  echo "- 구조 누수/중복/사문화:"
  echo "- 운영 비용(시간/복잡도) 평가:"
  echo "- 경량화/개편 필요 사항:"
  echo
  echo "## 3) 다음 달 개선 계획"
  echo "- 최우선 3개:"
  echo
  echo "## 4) COMMITMENTS 반영 항목"
  echo "- [ ]"
} > "$OUT"

echo "[monthly] wrote $OUT"
