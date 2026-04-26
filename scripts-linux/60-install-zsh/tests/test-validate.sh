#!/usr/bin/env bash
# Regression test for script 60 validate_zshrc()
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="${PROJECT_ROOT:-/dev-server}"
SCRIPT="$ROOT/scripts-linux/60-install-zsh/run.sh"

PASS=0; FAIL=0
note() { printf '\n=== %s ===\n' "$*"; }
ok()   { PASS=$((PASS+1)); echo "  PASS: $*"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $*"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Provide a stub zsh on PATH so the "zsh in PATH" check passes in CI sandboxes
mkdir -p "$TMP/bin"
cat > "$TMP/bin/zsh" << 'EOF'
#!/usr/bin/env bash
echo "stub zsh"
EOF
chmod +x "$TMP/bin/zsh"

mkfix() {
  local d="$1"
  rm -rf "$TMP/$d"
  mkdir -p "$TMP/$d/home/.oh-my-zsh/themes" \
           "$TMP/$d/home/.oh-my-zsh/custom/plugins" \
           "$TMP/$d/home/.oh-my-zsh/custom/themes" \
           "$TMP/$d/home/.oh-my-zsh/plugins/git"
  touch "$TMP/$d/home/.oh-my-zsh/oh-my-zsh.sh"
  touch "$TMP/$d/home/.oh-my-zsh/themes/robbyrussell.zsh-theme"
  mkdir -p "$TMP/$d/home/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
}
run_validate() { HOME="$TMP/$1/home" PATH="$TMP/bin:$PATH" bash "$SCRIPT" validate 2>&1; }
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

# Case A: complete fixture passes cleanly
note "Case A: complete fixture"
mkfix A; write_good_zshrc A
out=$(run_validate A); ec=$?
[ $ec -eq 0 ] && ok "exit 0 on good fixture" || bad "expected 0, got $ec"
echo "$out" | grep -q "validation OK"  && ok "report says OK"   || bad "missing OK summary"
echo "$out" | grep -q "\[FAIL\]"       && bad "unexpected FAIL" || ok "no FAIL rows"
echo "$out" | grep -q "\[WARN\]"       && bad "unexpected WARN" || ok "no WARN rows"

# Case B: missing ~/.zshrc
note "Case B: missing ~/.zshrc"
mkfix B
out=$(run_validate B); ec=$?
[ $ec -eq 1 ] && ok "exit 1 when zshrc missing" || bad "expected 1, got $ec"
echo "$out" | grep -q "~/.zshrc deployed.*missing" && ok "flags missing zshrc" || bad "did not flag"

# Case C: missing END marker
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
echo "$out" | grep -q "extras markers.*BEGIN=1 END=0" && ok "flags missing END marker" || bad "did not flag"

# Case D: theme mismatch -> WARN, exit 0
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
[ $ec -eq 0 ] && ok "exit 0 (mismatch is WARN)" || bad "expected 0, got $ec"
echo "$out" | grep -q "\[WARN\] active ZSH_THEME wired" && ok "WARNs on mismatch" || bad "no WARN"

# Case E: missing custom plugin clone
note "Case E: missing zsh-autosuggestions clone"
mkfix E
rm -rf "$TMP/E/home/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
write_good_zshrc E
out=$(run_validate E); ec=$?
[ $ec -eq 1 ] && ok "exit 1 when plugin missing" || bad "expected 1, got $ec"
echo "$out" | grep -q "custom plugin 'zsh-autosuggestions'.*missing" && ok "flags plugin" || bad "no flag"

# Case F: missing OMZ entrypoint
note "Case F: missing oh-my-zsh.sh entrypoint"
mkfix F
rm -f "$TMP/F/home/.oh-my-zsh/oh-my-zsh.sh"
write_good_zshrc F
out=$(run_validate F); ec=$?
[ $ec -eq 1 ] && ok "exit 1 when entrypoint missing" || bad "expected 1, got $ec"
echo "$out" | grep -q "OMZ entrypoint.*missing" && ok "flags entrypoint" || bad "no flag"

# Case G: zsh missing from PATH -> FAIL
note "Case G: zsh not in PATH"
mkfix G; write_good_zshrc G
out=$(HOME="$TMP/G/home" PATH="/usr/bin:/bin" bash "$SCRIPT" validate 2>&1); ec=$?
[ $ec -eq 1 ] && ok "exit 1 when zsh missing" || bad "expected 1, got $ec"
echo "$out" | grep -q "zsh in PATH.*not found" && ok "flags missing zsh" || bad "did not flag"

echo
echo "============================="
echo "Total: PASS=$PASS  FAIL=$FAIL"
echo "============================="
[ $FAIL -eq 0 ]
