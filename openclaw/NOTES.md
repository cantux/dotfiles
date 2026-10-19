# OpenClaw under dotfiles

## Tracked here

- `openclaw/openclaw.json`: redacted snapshot of `~/.openclaw/openclaw.json`, written by `bin/snapshot-openclaw`. The script replaces `gateway.auth.token`, every key named like a credential, and every value matching a known secret pattern with `REDACTED`, then refuses to write if any secret pattern survives. Refresh after configuration changes: `bin/snapshot-openclaw`.

## Deliberately not tracked

1. `~/.openclaw/state/` — auth profiles and session stores (secrets and live data).
2. `~/.openclaw/extensions/` — third-party plugin code. Reinstall: `openclaw plugins install clawhub:@claw0gang/antigravity --accept-capabilities` (v0.3.3 at adoption; npm integrity recorded by `openclaw plugins inspect antigravity`).
3. `~/.openclaw/workspaces/` — derived artifacts: `SOUL.md`/`IDENTITY.md` regenerate from `~/Projects/llm_serving/pipeline/regen_souls.py`; the baseline section of every `AGENTS.md` regenerates from `bin/sync-openclaw-baseline` (hooked into `sync.sh`).

## Sync direction

`sync.sh` never writes to `~/.openclaw/openclaw.json`: the live file is mutated by the OpenClaw CLI (`config set`, agent creation), and a forward copy would revert live changes. The snapshot is reverse-direction only, run manually.

## Restore procedure

1. Copy `openclaw/openclaw.json` to `~/.openclaw/openclaw.json`.
2. Set a fresh gateway token: replace the `REDACTED` value of `gateway.auth.token`.
3. Re-authenticate providers (`openclaw models auth ...`, Claude CLI login, agy login).
4. Reinstall the antigravity plugin (command above) and run `openclaw config validate`.
5. Run `~/Projects/llm_serving/pipeline/regen_souls.py` and `bin/sync-openclaw-baseline`.
