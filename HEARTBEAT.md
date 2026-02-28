# HEARTBEAT.md

## Heartbeat Checklist (every 120m)

1) 최근 2시간 대화를 보고 누락된 작업 이벤트가 있으면 `ops/logs/events/YYYY-MM-DD.jsonl`에 1줄 추가
   - 스키마: `ops/policies/event-schema.md`
   - 중복이면 스킵
2) 합의했으나 미확정 사항이 있으면 1줄 제안
   - 대화가 바쁘면 제안 생략
3) 승인 대기건 중 후속이 필요하면 1회 알림
   - 이미 알린 건 반복 금지

### Rules
- 기계적 정시 작업은 처리하지 않는다 (cron 담당)
- 동일 내용 반복 보고 금지
- 할 일이 없으면 반드시 `HEARTBEAT_OK`로 응답
