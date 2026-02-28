# 이벤트 로그 스키마

파일 위치: `ops/logs/events/YYYY-MM-DD.jsonl` (1줄 = 1이벤트)

## 필수 필드
| 필드 | 타입 | 값 |
|------|------|-----|
| ts | ISO8601 | 이벤트 발생 시각 |
| event_id | string | 중복 방지용 고유 ID (`{date}-{seq}` 또는 UUID) |
| type | enum | task / cron / config / external / heartbeat |
| scope | enum | coding / research / ops / comms / creative / config |
| action | string | 수행한 작업 (한 줄) |
| result | enum | done / partial / failed / skipped |

## 선택 필드
| 필드 | 설명 |
|------|------|
| satisfaction | positive / neutral / negative |
| notes | 특이사항 (에러, 우회 등) |
| policy_ref | 적용된 정책 ID (예: P-001) |
| skill_ref | 사용된 스킬명 |
| source | self / external-agent |

## 동시성 규칙
- 이벤트 파일은 append-only. 기존 줄을 수정/삭제하지 않는다.
- Heartbeat와 수동 기록이 겹치면 `event_id`로 중복 식별한다.
- lock 파일은 사용하지 않는다. 누락 방지 우선, 사후 dedup 허용.

## 예시
```json
{"event_id":"2026-02-28-001","ts":"2026-02-28T14:30:00+09:00","type":"task","scope":"research","action":"grok API 키 발급 가이드 작성","result":"done"}
{"event_id":"2026-02-28-002","ts":"2026-02-28T15:00:00+09:00","type":"external","scope":"config","action":"LanceDB 설치","result":"done","source":"external-agent","notes":"coding-agent 수행"}
{"event_id":"2026-02-28-003","ts":"2026-02-28T18:20:00+09:00","type":"task","scope":"comms","action":"텔레그램 테스트 전송","result":"failed","notes":"봇 토큰 만료"}
```
