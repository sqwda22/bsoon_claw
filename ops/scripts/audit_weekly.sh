#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TZ="Asia/Seoul"
TODAY="$(TZ="$TZ" date +%F)"
WEEK_ID="$(TZ="$TZ" date +%G-W%V)"
NOW="$(TZ="$TZ" date '+%F %T %Z')"
OUT="$ROOT/ops/audits/weekly/$WEEK_ID.md"

mkdir -p "$(dirname "$OUT")"

# last 7 days event count
sum_events=0
for i in {0..6}; do
  d=$(TZ="$TZ" date -d "-$i day" +%F)
  f="$ROOT/ops/logs/events/$d.jsonl"
  c=$(wc -l < "$f" 2>/dev/null || echo 0)
  sum_events=$((sum_events + c))
done

daily_reports=$(find "$ROOT/ops/audits/daily" -maxdepth 1 -type f -name '*.md' | sort | tail -n 7 | wc -l)

{
  echo "# Weekly Audit - $WEEK_ID"
  echo
  echo "- 실행시각: $NOW"
  echo "- 최근 7일 이벤트 총 라인수: $sum_events"
  echo "- 최근 7일 일일 감사 리포트 수: $daily_reports"
  echo
  echo "## 1) 주간 종합 (daily + events)"
  echo "- 요약:"
  echo
  echo "## 2) 정책/약속 문서 점검"
  echo "- 누수(빠진 규칙/약속):"
  echo "- 중복:"
  echo "- 사문화(실행되지 않는 규칙):"
  echo "- 경량화 대상:"
  echo
  echo "## 3) 개선안 우선순위"
  echo "- 즉시:"
  echo "- 보류:"
  echo "- 폐기:"
  echo
  echo "## 4) COMMITMENTS 반영 항목"
  echo "- [ ]"
} > "$OUT"

echo "[weekly] wrote $OUT"
