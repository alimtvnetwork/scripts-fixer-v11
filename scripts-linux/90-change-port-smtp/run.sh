#!/usr/bin/env bash
# scripts-linux/90-change-port-smtp/run.sh
# Change the listening port for Postfix SMTP. Powered by _shared/port-change.sh.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export SCRIPT_ID="90"
. "$ROOT/_shared/logger.sh"
. "$ROOT/_shared/file-error.sh"
. "$ROOT/_shared/pkg-detect.sh"
. "$ROOT/_shared/port-change.sh"

PC_SERVICE_ID="90"
PC_SERVICE_NAME="Postfix SMTP"
PC_DEFAULT_PORT="25"
PC_CONFIG_JSON="$SCRIPT_DIR/config.json"
PC_SYSTEMD_UNIT=""
PC_VALIDATE_CMD=''
PC_FIREWALL_PROTO="tcp"
PC_EDIT_SPECS=(
    "/etc/postfix/master.cf|||SMTP_GUARD_DISABLED|||SMTP_GUARD_DISABLED"
)
pc_run "$@"
