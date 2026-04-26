---
name: ZSH + Oh-My-Zsh installer (script 60)
description: 60-install-zsh installs zsh + Oh-My-Zsh, deploys curated payload/zshrc-base + payload/zshrc-extras between markers, auto-backs up existing config to ~/.zsh-backups/<TS>/
type: feature
---
## scripts-linux/60-install-zsh/

apt installs zsh + git + curl + wget; runs OMZ unattended (RUNZSH=no
CHSH=no KEEP_ZSHRC=yes); clones custom plugins (zsh-autosuggestions);
deploys `payload/zshrc-base` -> `~/.zshrc`; appends `payload/zshrc-extras`
between markers `# >>> lovable zsh extras >>>` / `# <<< lovable zsh extras <<<`.

## Backup contract

Always (when `backup_existing_zshrc=true`, default):
- `~/.zshrc`           -> `~/.zsh-backups/<TS>/.zshrc`
- `~/.oh-my-zsh/custom`-> `~/.zsh-backups/<TS>/oh-my-zsh-custom/`
- `~/.oh-my-zsh` HEAD  -> `~/.zsh-backups/<TS>/oh-my-zsh.HEAD`
Empty `<TS>/` removed if nothing existed.

## Payload bug fixes vs source repo

`payload/zshrc-base` fixes 2 real bugs from the original `02-ubuntu-install/.zshrc-base`:
1. `export ZSH="~/.oh-my-zsh"` -> `$HOME/.oh-my-zsh` (~ doesn't expand inside double quotes)
2. unconditional `source <(kubectl completion zsh)` -> guarded with `command -v kubectl`

Both payload files MUST end in a trailing newline (otherwise the end-marker
glues onto the last content line). `append_extras_zshrc` also defensively
emits a blank line before the end marker (belt + suspenders).

## Verbs

- `install`   full install + deploy (idempotent via marker check)
- `check`     zsh in PATH AND ~/.oh-my-zsh exists AND ~/.zshrc exists
- `repair`    re-deploy payload + re-clone plugins; preserves OMZ
- `uninstall` clears install marker only; for full removal use script 62

`set_default_shell=false` by default -- never runs `chsh` silently.

## Cross-script composition (verified)

60-install-zsh + 61-install-zsh-theme-switcher coexist cleanly:
60's `# >>> lovable zsh extras >>>` block and 61's
`# >>> lovable zsh-theme switcher >>>` block use distinct marker pairs.
Uninstalling 61 leaves 60 intact and vice-versa.

Spec: `.lovable/specs/01-zsh-and-remote-runner-spec.md`
Built: v0.116.0
