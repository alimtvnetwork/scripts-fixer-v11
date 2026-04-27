#!/usr/bin/env bash
# 06-sqlite-audit.sh -- thin wrappers over sqlite3 CLI for the audit DB.

DB_PATH="${DB_PATH:-$HOME/.local/share/ssh-orchestrator/orchestrator.sqlite}"

ensure_db() {
  local dir
  dir="$(dirname "$DB_PATH")"
  if ! mkdir -p "$dir" 2>/dev/null; then
    log_file_error "$dir" "audit: mkdir for sqlite failed"
    return 1
  fi
  if ! command -v sqlite3 >/dev/null 2>&1; then
    log_error "audit: sqlite3 CLI not installed (apt-get install -y sqlite3)"
    return 1
  fi
  sqlite3 "$DB_PATH" <<'SQL' || { log_file_error "$DB_PATH" "audit: schema bootstrap failed"; return 1; }
CREATE TABLE IF NOT EXISTS Hosts          (Id TEXT PRIMARY KEY, Alias TEXT UNIQUE, Hostname TEXT, Port INTEGER, "User" TEXT, Os TEXT, Role TEXT, GroupId TEXT, CreatedAt TEXT);
CREATE TABLE IF NOT EXISTS HostGroups     (Id TEXT PRIMARY KEY, Name TEXT UNIQUE, KeyStrategy TEXT, CreatedAt TEXT);
CREATE TABLE IF NOT EXISTS Credentials    (Id TEXT PRIMARY KEY, HostId TEXT, AuthMethod TEXT, EncryptedSecret BLOB, CreatedAt TEXT);
CREATE TABLE IF NOT EXISTS SshKeys        (Id TEXT PRIMARY KEY, GroupId TEXT, HostId TEXT, KeyType TEXT, PublicKeyPath TEXT, PrivateKeyPath TEXT, Fingerprint TEXT, CreatedAt TEXT);
CREATE TABLE IF NOT EXISTS Scripts        (Id TEXT PRIMARY KEY, Name TEXT, Version TEXT, OsCompatibility TEXT, Path TEXT, Sha256 TEXT, CreatedAt TEXT);
CREATE TABLE IF NOT EXISTS RunProfiles    (Id TEXT PRIMARY KEY, Name TEXT, Mode TEXT, MaxConcurrency INTEGER, OnError TEXT, CreatedAt TEXT);
CREATE TABLE IF NOT EXISTS Executions     (Id TEXT PRIMARY KEY, RunProfileId TEXT, ScriptId TEXT, Inline TEXT, StartedAt TEXT, FinishedAt TEXT, Status TEXT);
CREATE TABLE IF NOT EXISTS ExecutionResults(Id TEXT PRIMARY KEY, ExecutionId TEXT, HostId TEXT, ExitCode INTEGER, StdoutSha256 TEXT, StderrSha256 TEXT, DurationMs INTEGER);
CREATE TABLE IF NOT EXISTS AuditLogs      (Id TEXT PRIMARY KEY, ActorId TEXT, At TEXT, Event TEXT, HostId TEXT, ExecutionId TEXT, Detail TEXT);
SQL
}

audit_log() {
  # audit_log <event> <host-id> <execution-id> <detail>
  ensure_db || return 1
  local id ts
  id="$(date +%s%N)-$$"
  ts="$(_ts)"
  sqlite3 "$DB_PATH" \
    "INSERT INTO AuditLogs(Id,ActorId,At,Event,HostId,ExecutionId,Detail) VALUES('$id','${USER:-unknown}','$ts','$1','$2','$3','$(printf %s "$4" | sed "s/'/''/g")');"
}
