# Status and Roadmap

## Current State

**Version:** 2.1.0 (released)  
**Branch:** `main`  
**Open PRs:** none

## What Was Done (v2.1.0)

### Fase 1 — Filtering Tiers
- `--type TYPE` passthrough to list-units/list-unit-files
- Static denylist (14 patterns: *.device, *.slice, session-*.scope, systemd-fsck@*, etc.)
- `--all` / `-a` to disable filters
- `--failed` shortcut for `-s failed`
- `--mine` / `--etc` — admin-owned units (fragments under /etc or ~/.config)
- `--mine` as default with fallback to `--all` if < 5 units found
- `ctrl-e` toggle in fzf between mine/all modes
- Dynamic prompt: `Units [etc]:` vs `Units:`

### Rebrand Completion
- Binary renamed from `sysz` to `sysz-ng`
- Makefile, install.sh, PKGBUILD updated
- Tests updated to reference `sysz-ng`
- Shell completions renamed
- README.sh and README.md regenerated
- Release workflow and CONTRIBUTING.md updated

## Pending (Next Steps)

### Fase 2 — Tier 3 Properties (Lazy D-Bus)
- `--curated` flag using `systemctl show` properties:
  - `RefuseManualStart`, `RefuseManualStop`
  - `Perpetual=yes`
  - `Transient=yes`
  - `SourcePath` filled (generated units)
- Lazy evaluation: only triggers with `--curated`
- Result enters same cache as Tier 2
- `ctrl-a` toggle in fzf (curated vs all)

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
- 54/54 bats tests passing
- shellcheck clean
- shfmt clean
