---
name: Remote runner structured logs (script 63)
description: 63-remote-runner per-run log directory layout with session.log, manifest.json, hosts/<name>.log + .meta.json, latest symlink, retain_runs retention, and 'logs' verb for inspection.
type: feature
---
## Layout (per run)

```
scripts-linux/.logs/63/
├── latest -> 20260426-124557-host_web-1/         symlink to newest run
├── <TIMESTAMP>-<target_token>/
│   ├── command.txt            exact command
│   ├── target.txt             original target spec (e.g. "group:web")
│   ├── session.log            combined chronological output
│   ├── manifest.json          schema "63-remote-runner.run/v1"
│   └── hosts/
│       ├── <name>.log         raw stdout+stderr + Exit/Duration footer
│       └── <name>.meta.json   {host, exit, duration_seconds, ts_start, ts_end, status}
```

## manifest.json schema

```json
{
  "schema": "63-remote-runner.run/v1",
  "run_dir": "...",
  "target":  "all",
  "command": "uname -a",
  "ts_start": 1777207555,
  "ts_end":   1777207555,
  "duration_seconds": 0,
  "summary": { "ok": 2, "fail": 1, "total": 3 },
  "hosts": [ { "host":"web-1", "exit":0, "duration_seconds":0, "status":"ok", ... }, ... ]
}
```

`status` ∈ `ok` | `fail` | `auth_fail` | `unreachable`.

## Retention

`config.json:logging.retain_runs` (default 50, 0 = keep forever) prunes
oldest run dirs after every `run`. The `latest` symlink is a symlink, not
a dir, so retention won't delete it.

## 'logs' verb

| Subcommand | Action |
|---|---|
| `logs` (or `logs list`) | newest-first table from each manifest.json |
| `logs show [<run>]` | cat session.log (default: latest) |
| `logs host <name> [<run>]` | cat hosts/<name>.log |
| `logs manifest [<run>]` | jq pretty-print manifest.json |
| `logs clear` | delete ALL runs (asks y/N) |

`<run>` accepts: `latest`, run-dir basename, or absolute path.

## Parallel safety

Per-host writes go to **separate files** so concurrent hosts never collide.
Manifest is built AFTER all hosts finish by slurping `hosts/*.meta.json`
with `jq -s '.'`. Tested with `--parallel 3`.

Built: v0.119.0
Tests: 16 assertions pass (file presence, schema, symlink advance, parallel,
retention, logs verb, clear y/N).
