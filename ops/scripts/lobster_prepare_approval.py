#!/usr/bin/env python3
import json, sys

raw = sys.stdin.read().strip()
items = json.loads(raw) if raw else []
preview = []
for c in items[:3]:
    preview.append(f"[{c.get('id')}] {c.get('title')} | 근거: {c.get('evidence')}")

obj = {
    "prompt": "감사 기반 개선 후보 3개를 COMMITMENTS/DECISIONS에 반영할까요?",
    "items": items[:3],
    "preview": "\n".join(preview)
}
print(json.dumps(obj, ensure_ascii=False))
