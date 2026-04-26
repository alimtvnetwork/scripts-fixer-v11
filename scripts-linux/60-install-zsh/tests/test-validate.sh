#!/usr/bin/env bash
# Regression test for script 60 validate_zshrc()
# Sets up synthetic HOME fixtures and runs `60 validate` against each.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SCRIPT="$ROOT/scripts-linux/60-install-zsh/run.sh"

PASS=0; FAIL=0
note() { printf '\n=== %s ===\n' "$*"; }
ok()   { PASS=$((PASS+1)); echo "  PASS: $*"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $*"; }

mkfix() {
  # $1=label  builds: $TMP/<label>/{home, oh-my-zsh, .zshrc as needed}
  local d="$1"
  rm -rf "$TMP/$d"
  mkdir -p "$TMP/$d/home/.oh-my-zsh/themes" \
           "$TMP/$d/home/.oh-my-zsh/custom/plugins" \
           "$TMP/$d/home/.oh-my-zsh/custom/themes" \
           "$TMP/$d/home/.oh-my-zsh/plugins/git"
  touch "$TMP/$d/home/.oh-my-zsh/oh-my-zsh.sh"
  touch "$TMP/$d/home/.oh-my-zsh/themes/robbyrussell.zsh-theme"
  # Pretend zsh-autosuggestions plugin exists (config.json declares it)
  mkdir -p "$TMP/$d/home/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
}

run_validate() {
  HOME="$TMP/$1/home" bash "$SCRIPT" validate 2>&1
}

write_good_zshrc() {
  cat > "$TMP/$1/home/.zshrc" << EOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions)
source \$ZSH/oh-my-zsh.sh

# >>> lovable zsh extras >>>
alias foo=bar
# <<< lovable zsh extras <<<
EOF
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---- Case A: fully-good fixture should PASS ----
note "Case A: complete fixture"
mkfix A
write_good_zshrc A
out=$(run_validate A); ec=$?
echo "$out" | tail -20
[ $ec -eq 0 ] && ok "exit 0 on good fixture" || bad "expected exit 0, got $ec"
echo "$out" | grep -q "validation OK" && ok "report says OK" || bad "missing OK summary"
echo "$out" | grep -q "\[FAIL\]"      && bad "unexpected FAIL row" || ok "no FAIL rows"

# ---- Case B: missing ~/.zshrc ----
note "Case B: missing ~/.zshrc"
mkfix B
out=$(run_validate B); ec=$?
[ $ec -eq 1 ] && ok "exit 1 when zshrc missing" || bad "expected 1, got $ec"
echo "$out" | grep -q "~/.zshrc deployed.*missing" && ok "flags missing zshrc" || bad "did not flag missing zshrc"

# ---- Case C: missing extras END marker ----
note "Case C: missing extras END marker"
mkfix C
cat > "$TMP/C/home/.zshrc" << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# >>> lovable zsh extras >>>
alias foo=bar
EOF
out=$(run_validate C); ec=$?
[ $ec -eq 1 ] && ok "exit 1 when END marker missing" || bad "expected 1, got $ec"
echo "$out" | grep -q "extras markers.*BEGIN=1 END=0" && ok "flags missing END marker" || bad "did not flag END marker"

# ---- Case D: theme mismatch (warn, still passes) ----
note "Case D: ZSH_THEME wired to non-default theme"
mkfix D
cat > "$TMP/D/home/.zshrc" << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

# >>> lovable zsh extras >>>
alias foo=bar
# <<< lovable zsh extras <<<
EOF
out=$(run_validate D); ec=$?
[ $ec -eq 0 ] && ok "exit 0 (theme mismatch is WARN not FAIL)" || bad "expected 0, got $ec"
echo "$out" | grep -q "\[WARN\] active ZSH_THEME wired" && ok "WARNs on theme mismatch" || bad "did not WARN"

# ---- Case E: missing custom plugin dir from config.json ----
note "Case E: missing zsh-autosuggestions clone"
mkfix E
rm -rf "$TMP/E/home/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
write_good_zshrc E
out=$(run_validate E); ec=$?
[ $ec -eq 1 ] && ok "exit 1 when declared custom plugin missing" || bad "expected 1, got $ec"
echo "$out" | grep -q "custom plugin 'zsh-autosuggestions'.*missing" && ok "flags missing plugin clone" || bad "did not flag plugin"

# ---- Case F: missing OMZ entrypoint ----
note "Case F: missing oh-my-zsh.sh entrypoint"
mkfix F
rm -f "$TMP/F/home/.oh-my-zsh/oh-my-zsh.sh"
write_good_zshrc F
out=$(run_validate F); ec=$?
[ $ec -eq 1 ] && ok "exit 1 when entrypoint missing" || bad "expected 1, got $ec"
echo "$out" | grep -q "OMZ entrypoint.*missing" && ok "flags missing entrypoint" || bad "did not flag entrypoint"

echo
echo "============================="
echo "Total: PASS=$PASS  FAIL=$FAIL"
echo "============================="
[ $FAIL -eq 0 ]
