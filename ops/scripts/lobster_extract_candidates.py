#!/usr/bin/env python3
import json
import re
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parents[2]
AUD = ROOT / 'ops' / 'audits'
LOG = ROOT / 'ops' / 'logs' / 'runs'
COM = ROOT / 'COMMITMENTS.md'


def latest_file(glob_pat):
    files = sorted((ROOT / glob_pat).parent.glob((ROOT / glob_pat).name))
    if not files:
        return None
    return max(files, key=lambda p: p.stat().st_mtime)


def read_text(p):
    try:
        return p.read_text(encoding='utf-8')
    except Exception:
        return ''


today = datetime.now().strftime('%Y-%m-%d')

daily = latest_file('ops/audits/daily/*.md')
weekly = latest_file('ops/audits/weekly/*.md')
monthly = latest_file('ops/audits/monthly/*.md')
runlog = latest_file('ops/logs/runs/*.log')

daily_txt = read_text(daily) if daily else ''
weekly_txt = read_text(weekly) if weekly else ''
monthly_txt = read_text(monthly) if monthly else ''
run_txt = read_text(runlog) if runlog else ''
com_txt = read_text(COM) if COM.exists() else ''

unchecked = len(re.findall(r'^- \[ \]', daily_txt, flags=re.M))
run_fail = len(re.findall(r'failed|error|warning', run_txt, flags=re.I))
doing_count = len(re.findall(r'^\|\s*C-\d+\s*\|\s*doing\s*\|', com_txt, flags=re.M))

candidates = [
    {
        'id': 'A1',
        'key': 'audit-template-completeness',
        'title': '일일 감사 템플릿 미기입 항목 축소',
        'evidence': f"daily={daily.name if daily else 'none'} / 미기입 체크박스 {unchecked}개",
        'apply': {
            'targetFiles': ['COMMITMENTS.md', 'DECISIONS.md'],
            'commitment': '일일 감사 리포트의 미기입 체크박스 수를 다음 7일간 감소시키는 점검 루틴 운영',
            'decision': '일일 감사 템플릿의 미기입 항목을 줄이기 위한 보완 루틴을 1주간 적용'
        }
    },
    {
        'id': 'A2',
        'key': 'audit-runlog-error-tracking',
        'title': '감사 런로그 실패/경고 집계 루틴 추가',
        'evidence': f"runlog={runlog.name if runlog else 'none'} / 실패·경고 키워드 {run_fail}건",
        'apply': {
            'targetFiles': ['COMMITMENTS.md', 'DECISIONS.md'],
            'commitment': 'ops/logs/runs의 실패/경고를 일일 감사 요약에 집계해 재발 방지에 반영',
            'decision': '런로그 오류 지표를 감사 개선 입력으로 사용'
        }
    },
    {
        'id': 'A3',
        'key': 'commitments-priority-trim',
        'title': 'COMMITMENTS doing 항목 우선순위 정리',
        'evidence': f"doing 항목 {doing_count}개 / weekly={weekly.name if weekly else 'none'} / monthly={monthly.name if monthly else 'none'}",
        'apply': {
            'targetFiles': ['COMMITMENTS.md', 'DECISIONS.md'],
            'commitment': 'doing 항목을 매주 상위 5개 우선순위로 정렬하고 나머지는 backlog로 분류',
            'decision': '과도한 doing 누적을 줄이기 위해 주간 우선순위 트림 규칙 채택'
        }
    }
]

print(json.dumps(candidates, ensure_ascii=False))
