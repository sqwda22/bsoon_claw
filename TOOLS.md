# TOOLS.md - Local Notes

이 파일은 "도구가 무엇인지" 설명하는 문서가 아니라,
내 환경에서 **어떻게 쓰는지**를 적는 운영 메모다.

## Runtime / Host

- Host: WSL2 (`bsoon`)
- Node: `v24.13.1` (nvm)
- OpenClaw CLI wrapper: `~/.local/bin/openclaw`
- Gateway service: `openclaw-gateway.service` (systemd user)
- Node host service: `openclaw-node.service`
- Local node name: `local-node`

## Gateway / Access

- Gateway WS: `ws://127.0.0.1:18789` (loopback)
- Dashboard: `http://127.0.0.1:18789/`
- Auth: token mode

## Web Search

- Provider: `grok`
- Model: `grok-4-1-fast`
- Inline citations: `true`
- API key source: `~/.openclaw/.env` (`~/.openclaw/secrets.env` 링크)

## Telegram Channel

- Enabled: `true`
- DM policy: `pairing`
- Group policy: `allowlist`
- Streaming: `partial`

## Agent Defaults (current)

- Main model: `openai-codex/gpt-5.3-codex`
- Heartbeat: `0m` (off, intentional)
- Tool deny list: `[]` (웹/파일/런타임 차단 없음)
- Exec routing: `host=node`, `node=local-node`, `security=full`, `ask=off`

## Quick Checks

```bash
openclaw status --deep
openclaw gateway status
openclaw channels status --json
openclaw config get tools.web.search
```
