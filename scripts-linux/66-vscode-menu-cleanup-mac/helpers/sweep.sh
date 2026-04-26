#!/usr/bin/env bash
# helpers/sweep.sh -- mode dispatchers used by run.sh.
#
# Every sweep_* function:
#   - reads $DRY_RUN to decide apply-vs-preview
#   - never deletes anything outside the path the caller passed in
#   - emits one row per action via _emit_row (status \t id \t kind \t target \t detail)
#   - logs every file/path failure with exact path + reason (CODE RED rule)
#
# Statuses written to the rows file:
#   removed   -- file/symlink/launch-item actually deleted
#   would     -- dry-run preview entry
#   missing   -- target wasn't present
#   failed    -- delete/unload/unregister attempted but errored
#   skipped   -- prerequisite missing (sudo, tool, etc.)

# The run script sets these. Defaults keep the helpers safe in isolation.
: "${DRY_RUN:=0}"
: "${ROWS_TSV:=/tmp/vscode-menu-cleanup.rows.tsv}"

_emit_row() {
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" >> "$ROWS_TSV"
}

# ---------------------------------------------------------------- shim
# Remove a 'code' / 'code-insiders' shim from one of the supplied roots.
# A shim is removed only if it (a) lives in the configured root AND
# (b) is a regular file or symlink whose target / content references
# Code.app or Code - Insiders.app. We do NOT delete arbitrary files
# named 'code' that happen to sit in /usr/local/bin.
sweep_shim() {
  local cat_id="$1"; local root="$2"; local shim_name="$3"
  local p="$root/$shim_name"
  if [ ! -e "$p" ] && [ ! -L "$p" ]; then
    _emit_row "missing" "$cat_id" "shim" "$p" "absent"
    log_info "  not present: $p"
    return 0
  fi

  # Provenance check: must look like a VS Code shim.
  local hint=""
  if [ -L "$p" ]; then
    hint="$(readlink "$p" 2>/dev/null || true)"
  elif [ -f "$p" ]; then
    hint="$(head -c 4096 "$p" 2>/dev/null || true)"
  fi
  case "$hint" in
    *Code.app*|*"Code - Insiders.app"*|*Visual\ Studio\ Code*) ;;
    *)
      _emit_row "skipped" "$cat_id" "shim" "$p" "not a vscode shim (target=$hint)"
      log_warn "  skipped: $p (target does not reference Code.app -- keeping)"
      return 0
      ;;
  esac

  if [ "$DRY_RUN" -eq 1 ]; then
    _emit_row "would" "$cat_id" "shim" "$p" "$hint"
    log_info "  [dry-run] would remove: $p"
    return 0
  fi

  if rm -f "$p" 2>/dev/null; then
    _emit_row "removed" "$cat_id" "shim" "$p" "$hint"
    log_ok "  removed: $p"
  else
    _emit_row "failed" "$cat_id" "shim" "$p" "rm failed"
    log_file_error "$p" "rm failed (permission? try sudo or --scope user)"
  fi
}

# ---------------------------------------------------------------- glob
# Remove every entry matching a glob under a root directory.
sweep_glob_under() {
  local cat_id="$1"; local root="$2"; local pattern="$3"
  if [ ! -d "$root" ]; then
    _emit_row "missing" "$cat_id" "dir" "$root" "directory absent"
    log_info "  not present: $root"
    return 0
  fi
  local matched=0
  local match
  shopt -s nullglob
  for match in "$root"/$pattern; do
    matched=1
    if [ "$DRY_RUN" -eq 1 ]; then
      _emit_row "would" "$cat_id" "workflow" "$match" "matches '$pattern'"
      log_info "  [dry-run] would remove: $match"
      continue
    fi
    if rm -rf "$match" 2>/dev/null; then
      _emit_row "removed" "$cat_id" "workflow" "$match" "matches '$pattern'"
      log_ok "  removed: $match"
    else
      _emit_row "failed" "$cat_id" "workflow" "$match" "rm -rf failed"
      log_file_error "$match" "rm -rf failed"
    fi
  done
  shopt -u nullglob
  if [ "$matched" -eq 0 ]; then
    _emit_row "missing" "$cat_id" "workflow" "$root/$pattern" "no matches"
    log_info "  no matches under: $root for '$pattern'"
  fi
}

# ---------------------------------------------------------------- launchctl
# Scan a Launch{Agents,Daemons} dir for plists that reference VS Code,
# unload them, then delete the plist file.
sweep_launchctl() {
  local cat_id="$1"; local root="$2"; local domain="${3:-gui}"; shift 3
  local needles=("$@")

  if [ ! -d "$root" ]; then
    _emit_row "missing" "$cat_id" "launchctl" "$root" "directory absent"
    log_info "  not present: $root"
    return 0
  fi

  local p label
  shopt -s nullglob
  local hits=0
  for p in "$root"/*.plist; do
    if ! plist_references_any "$p" "${needles[@]}"; then
      continue
    fi
    hits=$((hits+1))
    label="$(plist_label "$p")"
    [ -z "$label" ] && label="$(basename "$p" .plist)"

    if [ "$DRY_RUN" -eq 1 ]; then
      _emit_row "would" "$cat_id" "launchctl" "$p" "label=$label,domain=$domain"
      log_info "  [dry-run] would unload + delete: $label ($p)"
      continue
    fi

    # Try the modern bootout first (works for both gui and system domains).
    local uid; uid="$(id -u)"
    local target_domain="$domain"
    if [ "$domain" = "gui" ]; then target_domain="gui/$uid"; fi

    local unload_ok=0
    if launchctl bootout "$target_domain" "$p" >/dev/null 2>&1; then
      unload_ok=1
    elif launchctl unload "$p" >/dev/null 2>&1; then
      unload_ok=1
    fi
    if [ "$unload_ok" -eq 1 ]; then
      log_ok "  launchctl unloaded: $label ($p)"
    else
      log_warn "  launchctl could not unload $label -- proceeding to delete plist"
    fi

    if rm -f "$p" 2>/dev/null; then
      _emit_row "removed" "$cat_id" "launchctl" "$p" "label=$label,domain=$domain"
      log_ok "  removed: $p"
    else
      _emit_row "failed" "$cat_id" "launchctl" "$p" "rm failed (perm?)"
      log_file_error "$p" "rm failed (permission? launchd plists in /Library need sudo)"
    fi
  done
  shopt -u nullglob
  if [ "$hits" -eq 0 ]; then
    _emit_row "missing" "$cat_id" "launchctl" "$root" "no plists reference VS Code"
    log_info "  no VS Code references found in: $root"
  fi
}

# ---------------------------------------------------------------- loginitem
# Remove Login Items pointing at "Visual Studio Code" / "...Insiders" using
# osascript (System Events). macOS only -- caller has already gated on $OS.
sweep_loginitem() {
  local cat_id="$1"; shift
  local app_names=("$@")

  if ! command -v osascript >/dev/null 2>&1; then
    _emit_row "skipped" "$cat_id" "loginitem" "(osascript)" "osascript not on PATH"
    log_warn "  skipped: osascript not on PATH"
    return 0
  fi

  local name found
  for name in "${app_names[@]}"; do
    found=$(osascript -e "tell application \"System Events\" to get name of every login item whose name is \"$name\"" 2>/dev/null || true)
    if [ -z "$found" ]; then
      _emit_row "missing" "$cat_id" "loginitem" "$name" "no login item with this name"
      log_info "  not present: login-item '$name'"
      continue
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      _emit_row "would" "$cat_id" "loginitem" "$name" "found: $found"
      log_info "  [dry-run] would remove login-item: $name"
      continue
    fi
    if osascript -e "tell application \"System Events\" to delete every login item whose name is \"$name\"" >/dev/null 2>&1; then
      _emit_row "removed" "$cat_id" "loginitem" "$name" "ok"
      log_ok "  login-item removed: $name"
    else
      _emit_row "failed" "$cat_id" "loginitem" "$name" "osascript delete failed"
      log_file_error "loginitem:$name" "osascript delete failed (Automation permission?)"
    fi
  done
}

# ---------------------------------------------------------------- lsregister
# Unregister LaunchServices handlers for vscode:// schemes that point at
# any *.app whose bundle id matches our editions.
sweep_lsregister() {
  local cat_id="$1"; shift
  local schemes=()    # vscode, vscode-insiders, ...
  local bundles=()    # com.microsoft.VSCode, ...

  # Args come as "schemes:vscode,vscode-insiders bundles:com.foo,com.bar"
  local arg
  for arg in "$@"; do
    case "$arg" in
      schemes:*)
        IFS=',' read -r -a schemes <<<"${arg#schemes:}" ;;
      bundles:*)
        IFS=',' read -r -a bundles <<<"${arg#bundles:}" ;;
    esac
  done

  local lsr="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
  if [ ! -x "$lsr" ]; then
    _emit_row "skipped" "$cat_id" "lsregister" "$lsr" "lsregister not found at expected path"
    log_warn "  skipped: lsregister not found at $lsr"
    return 0
  fi

  # Build a snapshot of the LaunchServices DB and grep for our bundles.
  local dump; dump="$("$lsr" -dump 2>/dev/null || true)"
  if [ -z "$dump" ]; then
    _emit_row "skipped" "$cat_id" "lsregister" "(dump)" "lsregister -dump empty"
    log_warn "  skipped: lsregister -dump returned empty output"
    return 0
  fi

  local bundle scheme app_path hits=0
  for bundle in "${bundles[@]}"; do
    # Find every app path bound to this bundle id.
    local paths
    paths=$(printf '%s\n' "$dump" \
      | awk -v b="$bundle" '
          /^[ \t]*path:/ { last_path=$0 }
          $0 ~ ("bundle id:[ \t]+" b)$ { print last_path }
        ' \
      | sed 's/^[ \t]*path:[ \t]*//' | sort -u)
    if [ -z "$paths" ]; then continue; fi
    while IFS= read -r app_path; do
      [ -z "$app_path" ] && continue
      hits=$((hits+1))
      for scheme in "${schemes[@]}"; do
        if [ "$DRY_RUN" -eq 1 ]; then
          _emit_row "would" "$cat_id" "lsregister" "$app_path" "scheme=$scheme,bundle=$bundle"
          log_info "  [dry-run] would unregister handler for $bundle (scheme $scheme) -> $app_path"
          continue
        fi
        if "$lsr" -u "$app_path" >/dev/null 2>&1; then
          _emit_row "removed" "$cat_id" "lsregister" "$app_path" "scheme=$scheme,bundle=$bundle"
          log_ok "  lsregister: removed handler for $bundle (scheme $scheme)"
        else
          _emit_row "failed" "$cat_id" "lsregister" "$app_path" "lsregister -u failed"
          log_file_error "$app_path" "lsregister -u failed (permission?)"
        fi
      done
    done <<< "$paths"
  done
  if [ "$hits" -eq 0 ]; then
    _emit_row "missing" "$cat_id" "lsregister" "(LaunchServices DB)" "no apps registered for bundles ${bundles[*]}"
    log_info "  no LaunchServices entries found for bundles: ${bundles[*]}"
  fi
}