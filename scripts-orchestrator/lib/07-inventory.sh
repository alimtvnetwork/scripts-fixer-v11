#!/usr/bin/env bash
# 07-inventory.sh -- POSIX inventory parser.
# Format: hosts.conf and groups.conf use "key=value" lines, [section] headers per host or group.
# Avoids YAML so we have zero deps.
#
# hosts.conf example:
#   [k8s-master]
#   hostname=192.168.0.20
#   user=alim
#   port=22
#   role=control-plane
#   group=cluster
#
# groups.conf example:
#   [cluster]
#   key_strategy=common      ; or 'per-host'

INVENTORY_DIR="${INVENTORY_DIR:-$PWD/scripts-orchestrator/inventory}"

inventory_hosts_in_group() {
  local group="$1"
  local file="$INVENTORY_DIR/hosts.conf"
  if [ ! -f "$file" ]; then
    log_file_error "$file" "inventory: hosts.conf not found (set INVENTORY_DIR or create it)"
    return 1
  fi
  awk -v target="$group" '
    /^\[.*\]$/ { gsub(/^\[|\]$/,"",$0); current=$0; group=""; next }
    /^[ \t]*group[ \t]*=/ {
      sub(/^[^=]*=[ \t]*/,"",$0); group=$0;
      if (group==target) print current
    }
  ' "$file"
}

inventory_get_field() {
  # inventory_get_field <host-alias> <field>
  local alias="$1" field="$2"
  local file="$INVENTORY_DIR/hosts.conf"
  if [ ! -f "$file" ]; then
    log_file_error "$file" "inventory: hosts.conf not found"
    return 1
  fi
  awk -v target="$alias" -v key="$field" '
    /^\[.*\]$/ { gsub(/^\[|\]$/,"",$0); current=$0; next }
    current==target {
      line=$0; sub(/^[ \t]+/,"",line)
      n=index(line,"=")
      if (n>0) {
        k=substr(line,1,n-1); gsub(/[ \t]+$/,"",k)
        v=substr(line,n+1);   sub(/^[ \t]+/,"",v)
        if (k==key) { print v; exit }
      }
    }
  ' "$file"
}
