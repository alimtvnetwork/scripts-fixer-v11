---
name: SSH orchestration spec
description: Multi-OS SSH orchestrator (scripts-orchestrator/) -- bash CLI, password->key bootstrap, parallel dispatch, kubeadm v1.31 playbook ported from aukgit/kubernetes-training-v1
type: feature
---
# SSH Orchestration Spec

## Confirmed decisions (locked)

| Area | Decision |
|---|---|
| Controller runtime | **Bash + POSIX sh** (no Node, no Python). SQLite via `sqlite3` CLI. |
| Targets in scope | Ubuntu, Debian, RHEL, CentOS, Fedora, Alpine, Arch, macOS. **Windows excluded.** |
| Privilege model | Sudo escalation OR direct root, declared per host. |
| Sudo password storage | AES-256-GCM via `openssl enc`, key from passphrase prompted once per session. Never written plaintext. |
| Bootstrap flow | password login -> ssh-keygen (if missing) -> ssh-copy-id -> write `~/.ssh/config` HostAlias -> verify keyauth -> optional `PasswordAuthentication no` (per-host opt-in). |
| Key strategy | **Configurable per HostGroup** (default = one common ed25519 key per controller; opt-in per-host keys). |
| Key type | Ed25519 default, RSA-4096 fallback flag. |
| Dispatch mode | Configurable per RunProfile: `sequential | parallel`, default parallel concurrency 8. |
| Error mode | Configurable: `failFast | continue | failAfterAll`, default `failAfterAll`. |
| K8s distribution | **kubeadm + CRI-O + Kubernetes v1.31** (ported from `aukgit/kubernetes-training-v1/03-kube-Installer`). Weave CNI, Helm v3.16.2. |
| Role assignment | Declared in inventory: `role: control-plane | worker | etcd`. |
| Inline commands | Allowed only with `--allow-inline` flag, audited verbatim. |
| Logging | `/var/log/ssh-orchestrator/sessions.log` + sqlite at `~/.local/share/ssh-orchestrator/orchestrator.sqlite`. |
| UI | **None** (CLI only). |

## Layout

```
scripts-orchestrator/
  run.sh                     # root dispatcher, subcommands: bootstrap, run, playbook, inventory, log
  lib/
    01-logger.sh             # colored + structured logging
    02-os-detect.sh          # remote OS detect via /etc/os-release
    03-ssh-exec.sh           # ssh wrapper with multiplexing (ControlMaster auto)
    04-parallel.sh           # bounded parallel job runner (xargs -P + named pipe FIFO)
    05-vault.sh              # AES-256-GCM secret store (openssl)
    06-sqlite-audit.sh       # sqlite3 CLI wrappers for audit log
    07-inventory.sh          # YAML-ish inventory parser (POSIX, no external dep)
    08-bootstrap.sh          # password->key flow
  playbooks/
    _meta/playbook.schema.md # contract every playbook must satisfy
    k8s-kubeadm/
      01-prereq.sh           # apt deps, kernel modules, sysctl
      02-install.sh          # CRI-O + kubeadm/kubelet/kubectl v1.31
      03-init-control.sh     # kubeadm init + admin.conf
      04-join-worker.sh      # token-based join
      05-cni-weave.sh        # weave net via reweave.azurewebsites.net
      06-helm.sh             # Helm v3.16.2
      playbook.json          # ordered steps, role gates, OS gates
  inventory.example/
    hosts.conf               # sample 1 control-plane + 2 workers
    groups.conf              # sample HostGroup definitions
  readme.md
```

## CLI surface (root level)

```sh
./scripts-orchestrator/run.sh bootstrap <host-alias> [--user u] [--port 22] [--ask-password]
./scripts-orchestrator/run.sh run <inline-cmd> --group <group> [--parallel N] [--on-error mode]
./scripts-orchestrator/run.sh playbook <name> --group <group> [--role control-plane|worker]
./scripts-orchestrator/run.sh inventory list|add|remove|show
./scripts-orchestrator/run.sh log tail|show <execution-id>
```

## Acceptance criteria

1. `bootstrap fresh-host` completes start-to-finish given only the password; subsequent `run` calls use key auth only.
2. `run "uptime" --group all --parallel 16` runs concurrently across mixed OS hosts and returns a per-host summary table.
3. `playbook k8s-kubeadm --group cluster` provisions control-plane on the `control-plane`-roled host(s) and joins workers, ending with `kubectl get nodes` showing `Ready` for every node.
4. Every execution writes one row to `Executions` and N rows to `ExecutionResults` (one per host), plus a CODE-RED file-error log line if any path fails.

## Database schema (PascalCase)

```sql
CREATE TABLE Hosts          (Id TEXT PRIMARY KEY, Alias TEXT UNIQUE, Hostname TEXT, Port INT, "User" TEXT, Os TEXT, Role TEXT, GroupId TEXT, CreatedAt TEXT);
CREATE TABLE HostGroups     (Id TEXT PRIMARY KEY, Name TEXT UNIQUE, KeyStrategy TEXT, CreatedAt TEXT);
CREATE TABLE Credentials    (Id TEXT PRIMARY KEY, HostId TEXT, AuthMethod TEXT, EncryptedSecret BLOB, CreatedAt TEXT);
CREATE TABLE SshKeys        (Id TEXT PRIMARY KEY, GroupId TEXT, HostId TEXT, KeyType TEXT, PublicKeyPath TEXT, PrivateKeyPath TEXT, Fingerprint TEXT, CreatedAt TEXT);
CREATE TABLE Scripts        (Id TEXT PRIMARY KEY, Name TEXT, Version TEXT, OsCompatibility TEXT, Path TEXT, Sha256 TEXT, CreatedAt TEXT);
CREATE TABLE RunProfiles    (Id TEXT PRIMARY KEY, Name TEXT, Mode TEXT, MaxConcurrency INT, OnError TEXT, CreatedAt TEXT);
CREATE TABLE Executions     (Id TEXT PRIMARY KEY, RunProfileId TEXT, ScriptId TEXT, Inline TEXT, StartedAt TEXT, FinishedAt TEXT, Status TEXT);
CREATE TABLE ExecutionResults(Id TEXT PRIMARY KEY, ExecutionId TEXT, HostId TEXT, ExitCode INT, StdoutSha256 TEXT, StderrSha256 TEXT, DurationMs INT);
CREATE TABLE AuditLogs      (Id TEXT PRIMARY KEY, ActorId TEXT, At TEXT, Event TEXT, HostId TEXT, ExecutionId TEXT, Detail TEXT);
```

## Reference repo

K8s playbook ported from: `https://github.com/aukgit/kubernetes-training-v1/tree/main/03-kube-Installer`
- `01-ubuntu-prereq.sh` -> our `playbooks/k8s-kubeadm/01-prereq.sh`
- `02-kube-Install.sh` -> our `02-install.sh` (extracted hostname change to inventory)
- `03-kube-init.sh`    -> our `03-init-control.sh`
- `05-helm.install.sh` -> our `06-helm.sh` (decoupled from `01-base-shell-scripts/00-import-all.sh`)
