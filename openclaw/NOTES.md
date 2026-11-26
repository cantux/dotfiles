# OpenClaw under dotfiles

## Tracked here

- `openclaw/openclaw.json`: redacted snapshot of `~/.openclaw/openclaw.json`, written by `bin/snapshot-openclaw`. The script replaces `gateway.auth.token`, every key named like a credential, and every value matching a known secret pattern with `REDACTED`, then refuses to write if any secret pattern survives. Refresh after configuration changes: `bin/snapshot-openclaw`.
- `openclaw/workspaces/<agent>/SOUL.md` and `IDENTITY.md`: the role file and the identity file of every agent whose workspace lies under `~/.openclaw/workspaces/` (35 agents on 2026-11-06). `bin/sync-openclaw-workspaces apply` (the default mode; `sync.sh` runs it) copies them into the live workspaces, `import` copies the live files into the repository, and `diff` compares the two and names live workspaces the repository lacks. The script writes only these two files per workspace and deletes nothing. The Model, Reasoning and Fallbacks lines of `IDENTITY.md` restate `openclaw.json`; change both together.
- `openclaw/ISSUES.md`: the findings of the 2026-11-06 review of the six-phase pipeline (sections A and B), the suggested fixes (section C) and the record of their implementation in the second pipeline (section D).
- `openclaw/gen_roles.py`: generator of the second pipeline's role files. One table of sixteen agents (identifiers with the suffix `_v2`, three families, model profiles) and one template per role produce `openclaw/workspaces/<agent>_v2/SOUL.md` and `IDENTITY.md`; `gen_roles.py --config` prints the matching `agents.entries.*` objects for `openclaw config set`. Edit the templates, run the generator, then `./sync.sh`. The first pipeline's 35 workspaces are imported files, not generated.

## Deliberately not tracked

1. `~/.openclaw/state/` — auth profiles and session stores (secrets and live data).
2. `~/.openclaw/extensions/` — third-party plugin code. Reinstall: `openclaw plugins install clawhub:@claw0gang/antigravity --accept-capabilities` (v0.3.3 at adoption; npm integrity recorded by `openclaw plugins inspect antigravity`).
3. `~/.openclaw/workspaces/*/AGENTS.md`, `USER.md`, `DREAMS.md` and `memory/` — the baseline section of every `AGENTS.md` regenerates from `bin/sync-openclaw-baseline` (hooked into `sync.sh`); `USER.md` is the unfilled stock template; `DREAMS.md` and `memory/` are written by OpenClaw at run time. Four run artifacts of 2026-10-16 and 17 (`orchestrator/state.md`, `engineer_gemini/coordination-report-v4.md`, `engineer_claude/coordination-report-v4.md`, `reviewer_openai/review-v4.md`) also lie in the workspaces.
4. `~/.openclaw/workspace/` — the workspace of the `main` agent, a git repository of its own.

## Sync direction

`sync.sh` never writes to `~/.openclaw/openclaw.json`: the live file is mutated by the OpenClaw CLI (`config set`, agent creation), and a forward copy would revert live changes. The snapshot is reverse-direction only, run manually.

`sync.sh` does write `SOUL.md` and `IDENTITY.md` into the live workspaces. Edit them under `openclaw/workspaces/`, then run `./sync.sh`. A file edited directly under `~/.openclaw/workspaces/`, by hand or by the agent itself, is overwritten by the next sync unless `bin/sync-openclaw-workspaces import` brings it into the repository first; `bin/sync-openclaw-workspaces diff` shows what a sync would overwrite. After `openclaw agents add` creates a workspace, run `import` once, then edit in the repository. The second pipeline's agents (`*_v2`) were created the other way round: the generator wrote the repository files first, `sync-openclaw-workspaces apply` created the live workspaces, and `sync-openclaw-baseline` wrote their `AGENTS.md`; their `cwd` is `~/Projects/openclaw_pipeline/`, the project that holds the tools and the run directories. The generators that produced the role files (`regen_souls.py` and `setup_agents.py` in `~/Projects/llm_serving`) were deleted on 2026-10-27; the files in the repository are the only source.

## Restore procedure

1. Copy `openclaw/openclaw.json` to `~/.openclaw/openclaw.json`.
2. Set a fresh gateway token: replace the `REDACTED` value of `gateway.auth.token`.
3. Re-authenticate providers (`openclaw models auth ...`, Claude CLI login, agy login).
4. Reinstall the antigravity plugin (command above) and run `openclaw config validate`.
5. Run `./sync.sh`: `bin/sync-openclaw-workspaces` creates every workspace with its role files, then `bin/sync-openclaw-baseline` embeds the baseline into every `AGENTS.md`.
6. The `cwd` of every first-pipeline agent points at `~/Projects/llm_serving`, deleted on 2026-10-27; the second pipeline's agents point at `~/Projects/openclaw_pipeline/`, which must exist (restore it from its own repository) before a run.
7. The `*_v2` configuration entries: `python3 openclaw/gen_roles.py --config` and one `openclaw config set agents.entries.<id> '<json>' --strict-json --replace` per agent.
8. The Antigravity project of the plugin (`plugins.entries.antigravity.config.project`, name `openclaw-pipeline`, record `~/.gemini/config/projects/<id>.json`) must list, as resource roots, every directory an agent runs from and every directory a run writes to: `~/Projects/llm_serving` and `~/.openclaw/workspaces` for the first pipeline, `~/Projects/openclaw_pipeline` and the parent of the run directory (`~/Projects/ai` for the run of 2026-11-06) for the second. The plugin reads the roots once at gateway start and refuses every run after a change until `systemctl --user restart openclaw-gateway.service`. The classifier of the assistant denies this edit as a widening of a trust boundary; the operator makes it.
9. `.config/systemd/user/openclaw-gateway.service.d/override.conf` (tracked) sets `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` for every CLI the gateway launches, so that no agent reads or writes Claude Code's auto-memory of its working folder, which every Claude-runtime agent with the same folder would share. After `./sync.sh`: `systemctl --user daemon-reload && systemctl --user try-restart openclaw-gateway.service` (`try-restart` restarts a running gateway only).
10. Memory flush off: `openclaw config get agents.defaults.compaction.memoryFlush` must print `{"enabled": false}`; otherwise run `openclaw config set agents.defaults.compaction.memoryFlush.enabled false --strict-json` (ISSUES.md section D, 2026-11-07). The flush is a hidden paid turn over the full context before compaction.
11. Skill reviews off while a pipeline run is live: `openclaw config get skills.workshop.autonomous.mode` prints `propose`; `auto` re-enables the weekly system-owned review jobs, which spend the OpenAI windows (ISSUES.md section F item 4).
12. Autostart off: `./sync.sh` runs `systemctl --user disable openclaw-gateway.service` whenever the unit file exists. `openclaw gateway install` enables the unit again, so run `./sync.sh` after every install (section "Gateway on demand").

## Gateway on demand

The gateway runs only while OpenClaw work is in progress: idle, it held 3.4 GiB of RAM (2026-11-10). The unit stays installed and disabled, so neither boot (linger is on) nor login starts it.

1. Start before the work: `systemctl --user start openclaw-gateway.service`.
2. Stop after the work: `systemctl --user stop openclaw-gateway.service`. `Restart=always` does not restart a unit that `systemctl stop` stopped.
3. Restart: `systemctl --user restart openclaw-gateway.service`.

Do not use `openclaw gateway stop` or `openclaw gateway restart`. OpenClaw's Linux adapter counts the service as loaded only while the unit is enabled (`isLoaded: isSystemdServiceEnabled`, `dist/service-C5e3lih7.mjs:479`, OpenClaw 2026.10.4), so on a disabled unit both commands take their not-loaded branch (`dist/lifecycle-core-DKTT_dMI.mjs:400` and `:515`) instead of calling `systemctl` on the unit. `openclaw gateway install`, and the `install --force` that OpenClaw's repair hints suggest, run `daemon-reload`, `enable` and `restart` (`dist/systemd-Ch3siJBj.mjs:370-375`); after either, `./sync.sh` disables the unit again.
