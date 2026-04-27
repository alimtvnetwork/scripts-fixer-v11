#!/usr/bin/env bash
# 02-os-detect.sh -- detect remote OS over an existing SSH connection.
# Usage: detect_remote_os <host-alias>
# Echoes one of: ubuntu | debian | rhel | centos | fedora | alpine | arch | macos | unknown

detect_remote_os() {
  local alias="$1"
  if [ -z "$alias" ]; then
    log_error "detect_remote_os: missing host alias"
    return 2
  fi
  # Try /etc/os-release first (Linux). Fall back to uname for macOS.
  local raw
  raw="$(ssh -o BatchMode=yes "$alias" '
    if [ -r /etc/os-release ]; then
      . /etc/os-release; printf "linux:%s" "${ID:-unknown}"
    elif [ "$(uname)" = "Darwin" ]; then
      printf "macos:darwin"
    else
      printf "unknown:%s" "$(uname)"
    fi
  ' 2>/dev/null)" || {
    log_warn "detect_remote_os: ssh probe failed for alias=$alias"
    echo unknown
    return 1
  }
  case "$raw" in
    linux:ubuntu) echo ubuntu ;;
    linux:debian) echo debian ;;
    linux:rhel)   echo rhel   ;;
    linux:centos) echo centos ;;
    linux:fedora) echo fedora ;;
    linux:alpine) echo alpine ;;
    linux:arch)   echo arch   ;;
    macos:*)      echo macos  ;;
    *)            echo unknown ;;
  esac
}
