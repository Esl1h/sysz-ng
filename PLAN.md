# Status and Roadmap

## Current State

**Version:** 2.2.0+ (main)  
**Branch:** `main`  
**Open PRs:** none

## What Was Done

### v2.1.0 — Filtering Tiers
- `--type TYPE` passthrough to list-units/list-unit-files
- Static denylist (14 patterns: *.device, *.slice, session-*.scope, systemd-fsck@*, etc.)
- `--all` / `-a` to disable filters
- `--failed` shortcut for `-s failed`
- `--mine` / `--etc` — admin-owned units (fragments under /etc or ~/.config)
- `--mine` as default with fallback to `--all` if < 5 units found
- `ctrl-e` toggle in fzf between mine/all modes
- Dynamic prompt: `Units [etc]:` vs `Units:`

### v2.2.0 — Curated Mode (Tier 3)
- `--curated` flag using `systemctl show` properties:
  - `RefuseManualStart`, `RefuseManualStop`
  - `Perpetual=yes`
  - `Transient=yes`
  - `SourcePath` filled (generated units)
- Lazy evaluation: only triggers with `--curated`
- `ctrl-a` toggle in fzf (curated vs all)

### UI Improvements
- Colorized keybindings help (cyan keys, bold headers)
- Visual markers in fzf: `▸` pointer/multi-select, `─` separator
- Inline info for cleaner layout
- Header in commands picker
- Prompt with badges showing active filters

### Enhanced Header
- Contextual two-line header (terminals >= 80 chars):
  - Line 1: `[user+system] @hostname M:machine`
  - Line 2: all keybindings
- `--header-first` keeps header fixed at top
- Preview layout adapts to terminal width:
  - `< 80 cols`: `bottom:40%` (no log truncation)
  - `80-119 cols`: `right:40%`
  - `>= 120 cols`: `right:50%`

### Rebrand Completion
- Binary renamed from `sysz` to `sysz-ng`
- Makefile, install.sh, PKGBUILD updated
- Tests updated to reference `sysz-ng`
- Shell completions renamed
- README.sh and README.md regenerated

## Pending (Next Steps)

### Fase 3 — Config and Profiles
- Config file: `$XDG_CONFIG_HOME/sysz/filter.conf`
  - One glob per line
  - `!` for exceptions
  - Example: `*.device`, `systemd-fsck@*`, `!systemd-resolved.service`
- Profiles: `SYSZ_PROFILE=server|desktop`
  - Server: hides bluetooth, cups, avahi
  - Desktop: shows everything

### Future Ideas
- Order by `StateChangeTimestamp` ("what changed since boot")
- `--since-reload` — units with mtime > last daemon-reload
- `--type` completion in bash/zsh

## Tests
- 57/57 bats tests passing
- shellcheck clean
- shfmt clean
