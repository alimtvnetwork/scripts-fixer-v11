#!/usr/bin/env bash
# 68-user-mgmt/edit-user-from-json.sh -- bulk user edits from JSON.
#
# Input shapes (auto-detected, same as add-user-from-json.sh):
#   1) Single object:  { "name": "alice", "rename": "alyssa", "promote": true }
#   2) Array:          [ { ... }, { ... }, ... ]
#   3) Wrapped:        { "users": [ ... ] }   <- also accepted
#
# Each record is dispatched to edit-user.sh so we get identical idempotency,
# password masking, and CODE RED file/path error reporting.
#
# Per-record schema (every field optional except `name`):
#
#   { "name":           "alice",          # REQUIRED -- account to edit
#     "rename":         "alyssa",         # --rename
#     "password":       "newpw",          # --reset-password (visible in PS)
#     "passwordFile":   "/etc/secrets/x", # --password-file (mode <= 0600)
#     "promote":        true,             # --promote (add to sudo/admin)
#     "demote":         true,             # --demote (remove from sudo/admin)
#     "addGroups":      ["docker","dev"], # --add-group (one per array entry)
#     "removeGroups":   ["video"],        # --remove-group
#     "shell":          "/bin/zsh",       # --shell
#     "comment":        "Alice (ops)",    # --comment (may be empty string)
#     "enable":         true,             # --enable
#     "disable":        true              # --disable
#   }
#
# Usage:
#   ./edit-user-from-json.sh <file.json> [--dry-run]

set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/helpers/_common.sh"

# As of v0.203.0 this loader applies each record IN-PROCESS via the shared
# um_user_modify helper rather than forking `bash edit-user.sh` per row.
# This drops ~50ms of bash startup per record and gives every record access
# to the same UM_SUMMARY_FILE without env-passing gymnastics.

# Allowed top-level fields per record. Anything outside this set triggers
# a "schemaUnknownField" warning (typo guard) but does NOT reject the
# record on its own.
UM_ALLOWED_FIELDS="name rename password passwordFile promote demote addGroups removeGroups shell comment enable disable"

# Validate one record's schema. Emits TSV rows on stdout:
#   ERROR<TAB>field<TAB>reason
#   WARN <TAB>field<TAB>reason
_validate_edit_record() {
    local rec="$1"
    local toptype
    toptype=$(jq -r 'type' <<< "$rec")
    if [ "$toptype" != "object" ]; then
        printf 'ERROR\t<root>\tnot an object (got %s)\n' "$toptype"
        return 0
    fi
    jq -r --arg allowed "$UM_ALLOWED_FIELDS" '
        def expect(field; want):
            if has(field) then
                (.[field] | type) as $t
                | if $t != want then "ERROR\t\(field)\twrong type: expected \(want), got \($t)"
                  else empty end
            else empty end;

        def expect_nonempty_string(field):
            if has(field) then
                (.[field]) as $v | ($v | type) as $t
                | if $t == "null" then "ERROR\t\(field)\tnull value"
                  elif $t != "string" then "ERROR\t\(field)\twrong type: expected string, got \($t)"
                  elif ($v | length) == 0 then "ERROR\t\(field)\tempty string"
                  else empty end
            else empty end;

        def expect_str_array(field):
            if has(field) then
                (.[field]) as $arr | ($arr | type) as $t
                | if $t != "array" then "ERROR\t\(field)\twrong type: expected array, got \($t) -- did you forget the [...] brackets?"
                  else
                      $arr | to_entries | map(
                          (.value | type) as $vt
                          | if $vt != "string" then "ERROR\t\(field)[\(.key)]\twrong type: expected non-empty string, got \($vt) (value=\(.value | tostring | .[0:80]))"
                            elif (.value | length) == 0 then "ERROR\t\(field)[\(.key)]\tempty string"
                            else empty end
                      ) | .[]
                  end
            else empty end;

        # Required: name.
        ( if has("name") | not then "ERROR\tname\tmissing required field" else empty end ),
        expect_nonempty_string("name"),

        # Optional scalars.
        expect_nonempty_string("rename"),
        expect_nonempty_string("password"),
        expect_nonempty_string("passwordFile"),
        expect_nonempty_string("shell"),
        expect("comment"; "string"),
        expect("promote"; "boolean"),
        expect("demote"; "boolean"),
        expect("enable"; "boolean"),
        expect("disable"; "boolean"),

        # Arrays.
        expect_str_array("addGroups"),
        expect_str_array("removeGroups"),

        # Mutually-exclusive intent check.
        ( if (.promote == true) and (.demote == true) then
              "ERROR\tpromote\tcannot be true while demote is also true"
          else empty end ),
        ( if (.enable == true) and (.disable == true) then
              "ERROR\tenable\tcannot be true while disable is also true"
          else empty end ),

        # Unknown-field warnings (typo guard).
        ( ($allowed | split(" ")) as $known
          | keys[]
          | select(. as $k | ($known | index($k)) | not)
          | "WARN\t\(.)\tunknown field (allowed: \($allowed))"
        )
    ' <<< "$rec" 2>/dev/null
}

um_usage() {
  cat <<EOF
Usage: edit-user-from-json.sh <file.json> [--dry-run]

Accepts a JSON file containing one user-edit object, an array of edit
objects, or { "users": [ ... ] }. Each record fans out to edit-user.sh.

Per-record schema (every field optional except 'name'):
  name, rename, password, passwordFile, promote, demote,
  addGroups[], removeGroups[], shell, comment, enable, disable.

Records with zero applicable changes are skipped with a [WARN] line --
still exit 0 if every other record succeeded.
EOF
}

UM_FILE=""
UM_DRY_RUN="${UM_DRY_RUN:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) um_usage; exit 0 ;;
    --dry-run) UM_DRY_RUN=1; shift ;;
    --) shift; break ;;
    -*) log_err "unknown option: '$1' (failure: see --help)"; exit 64 ;;
    *)
      if [ -z "$UM_FILE" ]; then UM_FILE="$1"; shift
      else log_err "unexpected positional: '$1' (failure: only <file.json> is positional)"; exit 64; fi
      ;;
  esac
done

if [ -z "$UM_FILE" ]; then
  log_err "missing required <file.json> (failure: nothing to read)"
  um_usage; exit 64
fi
if [ ! -f "$UM_FILE" ]; then
  log_file_error "$UM_FILE" "JSON input not found"
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  log_err "$(um_msg missingTool "jq" 2>/dev/null || echo "required tool 'jq' not found on PATH (failure: install jq)")"
  exit 127
fi

um_detect_os || exit $?
um_require_root || exit $?
if [ "$UM_DRY_RUN" = "1" ]; then log_warn "$(um_msg dryRunBanner 2>/dev/null || echo "[dry-run] no host mutation will occur")"; fi

# Normalise into an array on stdout.
normalised=$(jq -c '
  if   type == "object" and has("users") and (.users|type=="array") then .users
  elif type == "array"  then .
  elif type == "object" then [ . ]
  else error("top-level must be object or array")
  end
' "$UM_FILE" 2>/tmp/68-jq-err.$$)
jq_rc=$?
if [ "$jq_rc" -ne 0 ]; then
  err_text=$(cat /tmp/68-jq-err.$$ 2>/dev/null); rm -f /tmp/68-jq-err.$$
  log_err "JSON parse failed for exact path: '$UM_FILE' (failure: $err_text)"
  exit 2
fi
rm -f /tmp/68-jq-err.$$

count=$(jq 'length' <<< "$normalised")
log_info "loaded $count user-edit record(s) from '$UM_FILE'"

# In-process applicator. Mirrors the orchestration that edit-user.sh does
# for a single record: plan banner, existence probe, password resolution,
# then a sequence of um_user_modify calls (rename last). Returns 0/1.
_apply_edit_record() {
  local name="$1" rec="$2"
  local rename pw pwfile shell_v has_comment comment
  local is_promote is_demote is_enable is_disable
  local sudo_group rc=0

  rename=$(jq -r       '.rename // empty'       <<< "$rec")
  pw=$(jq -r           '.password // empty'     <<< "$rec")
  pwfile=$(jq -r       '.passwordFile // empty' <<< "$rec")
  shell_v=$(jq -r      '.shell // empty'        <<< "$rec")
  has_comment=$(jq -r  'if has("comment") then "1" else "" end' <<< "$rec")
  comment=$(jq -r      '.comment // ""'         <<< "$rec")
  is_promote=$(jq -r   'if .promote == true then "1" else "" end' <<< "$rec")
  is_demote=$(jq -r    'if .demote  == true then "1" else "" end' <<< "$rec")
  is_enable=$(jq -r    'if .enable  == true then "1" else "" end' <<< "$rec")
  is_disable=$(jq -r   'if .disable == true then "1" else "" end' <<< "$rec")

  if [ "$UM_OS" = "macos" ]; then sudo_group="admin"; else sudo_group="sudo"; fi

  # Build add/remove group lists (comma-joined for the plan banner).
  local add_groups="" rm_groups=""
  if jq -e 'has("addGroups")' <<< "$rec" >/dev/null 2>&1; then
    add_groups=$(jq -r '.addGroups | join(",")' <<< "$rec")
  fi
  if jq -e 'has("removeGroups")' <<< "$rec" >/dev/null 2>&1; then
    rm_groups=$(jq -r '.removeGroups | join(",")' <<< "$rec")
  fi
  [ "$is_promote" = "1" ] && add_groups="${add_groups:+$add_groups,}$sudo_group"
  [ "$is_demote"  = "1" ] && rm_groups="${rm_groups:+$rm_groups,}$sudo_group"

  # Plan banner (matches edit-user.sh wording exactly).
  local plan=()
  [ -n "$rename" ]       && plan+=("rename '$name' -> '$rename'")
  { [ -n "$pw" ] || [ -n "$pwfile" ]; } && plan+=("reset password")
  [ "$is_promote" = "1" ] && plan+=("promote (add to '$sudo_group')")
  [ "$is_demote"  = "1" ] && plan+=("demote (remove from '$sudo_group')")
  [ -n "$add_groups" ]    && plan+=("add groups: $add_groups")
  [ -n "$rm_groups" ]     && plan+=("remove groups: $rm_groups")
  [ -n "$shell_v" ]       && plan+=("set shell: $shell_v")
  [ "$has_comment" = "1" ] && plan+=("set comment: '$comment'")
  [ "$is_enable"  = "1" ] && plan+=("enable account")
  [ "$is_disable" = "1" ] && plan+=("disable account")

  if [ "${#plan[@]}" -eq 0 ]; then
    log_warn "no changes requested for '$name' -- skipping (record has only 'name')"
    return 0
  fi

  log_info "$(um_msg editPlanHeader "$name" 2>/dev/null || echo "edit-user plan for '$name':")"
  for p in "${plan[@]}"; do log_info "  - $p"; done

  if ! um_user_exists "$name"; then
    log_err "$(um_msg editUserMissing "$name" 2>/dev/null || echo "user '$name' does not exist -- nothing to edit (failure: create it first with add-user)")"
    um_summary_add "fail" "user" "$name" "missing"
    return 1
  fi

  # Resolve password (file or plain). Empty -> no password change.
  local resolved_pw=""
  if [ -n "$pw" ] || [ -n "$pwfile" ]; then
    UM_PASSWORD="$pw" UM_PASSWORD_FILE="$pwfile" UM_PASSWORD_CLI="" \
      um_resolve_password || return $?
    resolved_pw="$UM_RESOLVED_PASSWORD"
  fi

  [ -n "$resolved_pw" ]     && { um_user_modify "$name" password "$resolved_pw" || rc=1; }
  [ -n "$shell_v" ]         && { um_user_modify "$name" shell    "$shell_v"     || rc=1; }
  [ "$has_comment" = "1" ]  && { um_user_modify "$name" comment  "$comment"     || rc=1; }
  [ "$is_enable"  = "1" ]   && { um_user_modify "$name" enable                  || rc=1; }
  [ "$is_disable" = "1" ]   && { um_user_modify "$name" disable                 || rc=1; }

  if [ -n "$add_groups" ]; then
    IFS=',' read -ra _ag <<< "$add_groups"
    for g in "${_ag[@]}"; do
      g="${g// /}"; [ -z "$g" ] && continue
      um_user_modify "$name" add-group "$g" || rc=1
    done
  fi
  if [ -n "$rm_groups" ]; then
    IFS=',' read -ra _rg <<< "$rm_groups"
    for g in "${_rg[@]}"; do
      g="${g// /}"; [ -z "$g" ] && continue
      um_user_modify "$name" rm-group "$g" || rc=1
    done
  fi

  # Rename LAST so all prior ops referenced the original name.
  [ -n "$rename" ] && { um_user_modify "$name" rename "$rename" || rc=1; }

  if [ "$rc" -eq 0 ]; then
    um_summary_add "ok"   "edit-user" "$name" "${#plan[@]} change(s) applied"
  else
    um_summary_add "fail" "edit-user" "$name" "one or more changes failed"
  fi
  return $rc
}

rc_total=0
i=0
while [ "$i" -lt "$count" ]; do
  rec=$(jq -c ".[$i]" <<< "$normalised")

  # ---- Strict schema validation ----
  validation_out=$(_validate_edit_record "$rec")
  err_count=0
  if [ -n "$validation_out" ]; then
    while IFS=$'\t' read -r severity field reason; do
      [ -z "$severity" ] && continue
      case "$severity" in
        ERROR)
          err_count=$((err_count+1))
          log_err "JSON record #$i in '$UM_FILE' field '$field': $reason (failure: rejecting record)"
          ;;
        WARN)
          log_warn "JSON record #$i in '$UM_FILE' field '$field': $reason"
          ;;
      esac
    done <<< "$validation_out"
  fi

  if [ "$(jq -r 'type' <<< "$rec")" = "object" ]; then
    name=$(jq -r '.name // "<missing>"' <<< "$rec")
  else
    name="<not-an-object>"
  fi

  if [ "$err_count" -gt 0 ]; then
    log_err "rejected record #$i in '$UM_FILE' for user='$name' ($err_count schema error(s))"
    rc_total=1
    i=$((i+1)); continue
  fi

  log_info "--- record $((i+1))/$count: edit user='$name' ---"
  _apply_edit_record "$name" "$rec" || rc_total=1
  i=$((i+1))
done

exit $rc_total