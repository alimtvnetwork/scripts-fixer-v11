#!/usr/bin/env bash
# doctor.sh — system-wide health-check helpers.
# Provides:
#   doctor_state <id>     -> emits TSV: id<TAB>folder<TAB>state<TAB>marker_age<TAB>detail
#                            state in: ok | drift | broken | uninstalled | missing_script
#   doctor_run_all        -> runs doctor_state for every registered id
#   doctor_age_seconds <path>  -> seconds since file mtime, or "-" if missing
#
# State definitions:
#   ok              -> .installed/<id>.ok exists  AND  bash run.sh check exits 0
#   drift           -> .installed/<id>.ok exists  AND  bash run.sh check exits non-zero  (was installed, now broken)
#   broken          -> .installed/<id>.ok MISSING AND  bash run.sh check exits 0         (installed out-of-band, marker not set)
#   uninstalled     -> .installed/<id>.ok MISSING AND  bash run.sh check exits non-zero  (clean: never installed)
#   missing_script  -> registry has id but folder/run.sh does not exist
#
# CODE RED: every file/path miss is reported via log_file_error with exact path.

doctor_age_seconds() {
  local p="$1"
  if [ ! -e "$p" ]; then echo "-"; return 0; fi
  local mtime now
  mtime=$(stat -c %Y "$p" 2>/dev/null || stat -f %m "$p" 2>/dev/null || echo 0)
  now=$(date +%s)
  echo $(( now - mtime ))
}

doctor_state() {
  local id="$1"
  local folder script marker age check_rc state detail
  folder=$(registry_get_folder "$id")
  if [ -z "$folder" ]; then
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "?" "missing_script" "-" "id not in registry"
    return 0
  fi
  script="$DOCTOR_ROOT/$folder/run.sh"
  marker="$DOCTOR_ROOT/.installed/$id.ok"
  if [ ! -f "$script" ]; then
    log_file_error "$script" "doctor: run.sh missing for id=$id (registry says folder=$folder)"
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$folder" "missing_script" "-" "run.sh not found"
    return 0
  fi
  age=$(doctor_age_seconds "$marker")
  if bash "$script" check >/dev/null 2>&1; then check_rc=0; else check_rc=1; fi
  if [ -f "$marker" ] && [ "$check_rc" -eq 0 ]; then
    state="ok";          detail="installed + verify OK"
  elif [ -f "$marker" ] && [ "$check_rc" -ne 0 ]; then
    state="drift";       detail="marker present but verify FAILED — likely broken/removed externally"
  elif [ ! -f "$marker" ] && [ "$check_rc" -eq 0 ]; then
    state="broken";      detail="verify OK but no install marker — installed out-of-band"
  else
    state="uninstalled"; detail="not installed (clean)"
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$folder" "$state" "$age" "$detail"
}

doctor_run_all() {
  local ids
  ids=$(registry_list_ids | grep -v '^12$' | sort -n)
  for id in $ids; do
    doctor_state "$id"
  done
}

# Format helper for the human table.
doctor_age_human() {
  local s="$1"
  if [ "$s" = "-" ]; then echo "-"; return 0; fi
  if [ "$s" -lt 60 ]; then echo "${s}s"; return 0; fi
  if [ "$s" -lt 3600 ]; then echo "$((s/60))m"; return 0; fi
  if [ "$s" -lt 86400 ]; then echo "$((s/3600))h"; return 0; fi
  echo "$((s/86400))d"
}
