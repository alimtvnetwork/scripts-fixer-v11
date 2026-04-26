60-install-zsh
==============

Installs the full Oh-My-Zsh stack on Ubuntu/Debian:
  1. apt installs zsh + git + curl + wget
  2. Backs up any existing ~/.zshrc and ~/.oh-my-zsh/custom to
     ~/.zsh-backups/<TIMESTAMP>/
  3. Runs the official Oh-My-Zsh installer non-interactively
     (RUNZSH=no CHSH=no KEEP_ZSHRC=yes) so it never overwrites your
     ~/.zshrc and never silently changes your default shell.
  4. Clones custom plugins (default: zsh-autosuggestions) into
     $ZSH_CUSTOM/plugins/.
  5. Deploys payload/zshrc-base -> ~/.zshrc and pins ZSH_THEME from
     config.default_theme.
  6. Appends payload/zshrc-extras (your aliases) inside marker comments
     so re-running the installer is idempotent and uninstall is clean.

Quick start
-----------
  scripts-linux/run.sh -I 60 install
  exec zsh                # or open a new terminal

Verbs
-----
  install     Full install + deploy (idempotent)
  check       Verify zsh + ~/.oh-my-zsh + ~/.zshrc all present
  repair      Re-deploy payloads + re-clone plugins; keeps OMZ install
  uninstall   Clears install marker only -- use script 62 for full removal

Files
-----
  run.sh                       Main entry
  config.json                  apt pkg list, default_theme, plugins[],
                               custom_plugins[], deploy/backup flags,
                               omz_install_url
  log-messages.json            Centralised log strings
  payload/zshrc-base           Curated ~/.zshrc base (128 lines)
                               -- 2 bugs fixed vs the original repo:
                                  * `export ZSH="~/..."` (~ unquoted)
                                  * unconditional kubectl completion
  payload/zshrc-extras         User aliases appended between markers:
                                  # >>> lovable zsh extras >>>
                                  # <<< lovable zsh extras <<<

Backup behaviour
----------------
Every install + repair runs `backup_existing_config` first:
  - ~/.zshrc        -> ~/.zsh-backups/<TS>/.zshrc
  - ~/.oh-my-zsh/custom -> ~/.zsh-backups/<TS>/oh-my-zsh-custom/
  - ~/.oh-my-zsh HEAD commit (if a git checkout) -> oh-my-zsh.HEAD
If nothing exists to back up, the empty <TS>/ dir is removed silently.
Set `backup_existing_zshrc: false` in config.json to opt out.

Default-shell behaviour
-----------------------
By default `set_default_shell` is FALSE. The installer never runs `chsh`
behind your back. Flip it to true in config.json if you want the script
to switch your login shell to zsh.

Companion scripts (per spec 01)
-------------------------------
  60-install-zsh                        THIS SCRIPT (built v0.116.0)
  61-install-zsh-theme-switcher         Wires `zsh-theme` command (built v0.115.0)
  62-install-zsh-clear                  Destructive reset (not yet built)
  63-remote-runner                      Multi-host SSH executor (not yet built)

Spec: .lovable/specs/01-zsh-and-remote-runner-spec.md

let's start now 2026-04-26 18:05 (UTC+8)
