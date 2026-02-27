#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parents[2]
COM = ROOT / 'COMMITMENTS.md'
DEC = ROOT / 'DECISIONS.md'

today = datetime.now().strftime('%Y-%m-%d')

raw = sys.stdin.read().strip()
candidates = json.loads(raw) if raw else []

com_text = COM.read_text(encoding='utf-8') if COM.exists() else ''
dec_text = DEC.read_text(encoding='utf-8') if DEC.exists() else ''

applied = []
skipped = []

# find next ids
c_nums = [int(x) for x in re.findall(r'\|\s*C-(\d+)\s*\|', com_text)]
d_nums = [int(x) for x in re.findall(r'^###\s+D-(\d+)', dec_text, flags=re.M)]
next_c = (max(c_nums) + 1) if c_nums else 1
next_d = (max(d_nums) + 1) if d_nums else 1

for c in candidates:
    key = c.get('key') or c.get('id')
    marker = f"[lobster-key:{key}]"
    if marker in dec_text:
        skipped.append({'id': c.get('id'), 'reason': 'already-applied'})
        continue

    commitment_text = c.get('apply', {}).get('commitment') or c.get('title', '개선 항목')
    decision_text = c.get('apply', {}).get('decision') or c.get('title', '개선 항목 적용')

    row = f"| C-{next_c:03d} | doing | {commitment_text} | {today} | 상시 | lobster 승인 반영 |\n"
    if '## 운영 메모\n' in com_text:
        com_text = com_text.replace('## 운영 메모\n', row + '\n## 운영 메모\n', 1)
    else:
        com_text += '\n' + row

    dec_entry = (
        f"\n\n### D-{next_d:03d} ({today})\n"
        f"- 결정: {decision_text}.\n"
        f"- 이유: {c.get('evidence','감사 로그 기반')}.\n"
        f"- 영향: COMMITMENTS/DECISIONS에 개선 루틴 반영. {marker}\n"
    )
    dec_text += dec_entry

    applied.append({'id': c.get('id'), 'commitmentId': f"C-{next_c:03d}", 'decisionId': f"D-{next_d:03d}"})
    next_c += 1
    next_d += 1

COM.write_text(com_text, encoding='utf-8')
DEC.write_text(dec_text, encoding='utf-8')

print(json.dumps({'applied': applied, 'skipped': skipped, 'total': len(candidates)}, ensure_ascii=False))
