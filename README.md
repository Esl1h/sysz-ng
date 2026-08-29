# [sysz-ng](https://github.com/Esl1h/sysz-ng)

A [fzf](https://github.com/junegunn/fzf) terminal UI for systemctl

VERSION: 2.0.0

> **Hard fork.** This project was originally forked from
> [joehillen/sysz](https://github.com/joehillen/sysz) but no longer
> rebases on it. Development continues independently here.

# Features

- System and user units in one list, searchable together.
- Opens without waiting: the loaded units appear first and the rest stream
  in behind them.
- The keys that matter are in the header, and the split between the list
  and the preview follows the terminal width, so a narrow ssh session is
  not left with unreadable unit names.
- Units are coloured by state and ordered by type: services, then timers,
  then sockets, then the rest.
- Only offers the commands that make sense for the unit in front of you,
  so `start` does not show for something already running.
- Runs `status` after anything that changes a unit, so you see the result.
- Preview shows `status`, or `cat` the unit file with `ctrl-v`.
- Reads the journal for a unit, following it if you want.
- Filters by state with `ctrl-s` or `--state`, and runs `daemon-reload`
  with `ctrl-r`.
- Takes several units, states or commands at once with `TAB`.
- Calls `sudo` (or `SYSZ_SUDO`) only when the unit actually requires it.
- Short aliases for the systemctl commands, to type less.
- Host and machine passthrough: `-H/--host` and `-M/--machine`.
- Template units list existing instances instead of asking for a parameter.
- Cache for `list-unit-files` with mtime-based invalidation.

# Requirements

- systemd, for `systemctl` and `journalctl`
- [fzf](https://github.com/junegunn/fzf) >= [0.46.0](https://github.com/junegunn/fzf/blob/master/CHANGELOG.md#0460)
- bash >= 4.3
- awk, plus the usual `sed`, `sort`, `grep`, `cut` and `stty`

# Installation

`sysz-ng` is a single bash script, so installing it means putting one file
somewhere on your `PATH`.

There is no distribution package yet. The `sysz` in the AUR and
in nixpkgs is built from [joehillen/sysz](https://github.com/joehillen/sysz),
which this forked from and which has not changed since 2022, so those
packages do not carry anything described here.

## Install script

```sh
curl -fsSL https://raw.githubusercontent.com/Esl1h/sysz-ng/main/install.sh | bash
```

Installs to `~/.local/bin`, so it needs no privileges, and says so if that
directory is not on your `PATH`. It checks bash, awk and fzf first and
refuses rather than leaving you with something that will not start.

It reads a few variables:

```sh
# install somewhere else
SYSZ_INSTALL_DIR=/usr/local/bin curl -fsSL .../install.sh | sudo -E bash

# install a particular tag or branch
SYSZ_REF=2.0.0 curl -fsSL .../install.sh | bash
```

Piping a script into a shell is worth being careful about. This one is
[install.sh](install.sh) in this repository if you want to read it first.

## Direct download

```sh
mkdir -p ~/.local/bin
curl -fsSL -o ~/.local/bin/sysz-ng https://raw.githubusercontent.com/Esl1h/sysz-ng/main/sysz
chmod +x ~/.local/bin/sysz-ng
```

## From source

```sh
git clone https://github.com/Esl1h/sysz-ng.git
cd sysz-ng
sudo make install # /usr/local/bin/sysz-ng
```

Running the tests needs [bats](https://github.com/bats-core/bats-core):

```sh
make test
```

# Usage

```text
Usage: sysz [OPTS...] [CMD] [-- ARGS...]

OPTS:
  -u, --user               Only show --user units
  --sys, --system          Only show --system units
  -s STATE, --state STATE  Only show units in STATE (repeatable)
  -H HOST, --host HOST     Connect to remote host
  -M MACHINE, --machine MACHINE  Operate on local container
  --no-cache               Skip list-unit-files cache
  -V, --verbose            Print the systemctl command
  -v, --version            Print the version
  -h, --help               Print this message

Environment:
  SYSZ_SUDO                Privilege escalation command (default: sudo)
  SYSZ_FZF_OPTS            Extra fzf options
  SYSZ_HISTORY             History file path

CMD:
  start                  systemctl start <unit>
  stop                   systemctl stop <unit>
  r re restart           systemctl restart <unit>
  reload                 systemctl reload <unit>
  s stat status          systemctl status <unit>
  en enable              systemctl enable <unit>
  d dis disable          systemctl disable <unit>
  mask                   systemctl mask <unit>
  unmask                 systemctl unmask <unit>
  c cat                  systemctl cat <unit>
  ed edit                systemctl edit <unit>
  show                   systemctl show <unit>
  j journal              systemctl journal <unit>
  f follow               systemctl follow <unit>

History:  $XDG_CACHE_HOME/sysz/history

Examples:
  sysz -u                      User units
  sysz --sys -s active stop    Stop an active system unit
  sysz s -- -n100             Show status with 100 log lines
```

# Alternatives

`sysz-ng` is deliberately a single Bash script: no build, no runtime,
no binary — it only needs `bash` and `fzf`. This makes it trivial to
drop onto any host via `scp`. If you want a full TUI (panels, live
logs, auto-refresh), these projects do more:

| Project | Language | Backend | Note |
|---|---|---|---|
| [systemctl-tui](https://github.com/rgwood/systemctl-tui) | Rust / ratatui | D-Bus | Supports remote host via SSH (`--host`) |
| [isd](https://github.com/isd-project/isd) | Python / Textual | systemctl | Fuzzy search, auto-refresh preview, smart sudo |
| [systemd-manager-tui](https://github.com/matheus-git/systemd-manager-tui) | Rust | D-Bus | RPM and DEB packages |
| [sdtop](https://github.com/YashSaini99/sdtop) | — | systemctl | Dashboard with process tree |

`systemctl-tui` and `isd` cite `sysz` as inspiration — `isd` describes
itself as a more powerful and heavier version of it.

**When to stay with sysz-ng:** ephemeral hosts, environments where installing
a binary is bureaucracy, or when you just want `sysz-ng restart` and leave.
**When to migrate:** continuous monitoring, real-time logs, daily use as a
dashboard.

# Acknowledgements

Originally written by [Joe Hillenbrand](https://github.com/joehillen).
This fork began as [joehillen/sysz](https://github.com/joehillen/sysz) but
continues independently as `sysz-ng`.

Inspired by [fuzzy-sys](https://github.com/NullSense/fuzzy-sys) by [NullSense](https://github.com/NullSense/)

Thank you for [ShellCheck](https://github.com/koalaman/shellcheck) without which this would be a buggy mess.
