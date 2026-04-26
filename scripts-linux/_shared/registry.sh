#!/usr/bin/env bash
# Read scripts-linux/registry.json and expose helpers.

__REG_FILE="$(dirname "${BASH_SOURCE[0]}")/../registry.json"

registry_list_ids() {
  jq -r '.scripts[].id' "$__REG_FILE" 2>/dev/null
}

registry_get_folder() {
  local id="$1"
  jq -r --arg id "$id" '.scripts[] | select(.id==$id) | .folder' "$__REG_FILE" 2>/dev/null
}

registry_list_all() {
  jq -r '.scripts[] | "\(.id)\t\(.folder)\t\(.title)"' "$__REG_FILE" 2>/dev/null
}

registry_phase_ids() {
  local phase="$1"
  jq -r --arg p "$phase" '.scripts[] | select(.phase==$p) | .id' "$__REG_FILE" 2>/dev/null
}