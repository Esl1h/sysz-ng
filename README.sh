#!/bin/bash
BLOCK='```'

# $XDG_CACHE_HOME is meant to reach the README as those literal
# characters, so the home directory of whoever generated it does not.
# shellcheck disable=SC2016
USAGE=$(./sysz-ng -h | sed -e 's:/home/[a-z]\+/.cache:$XDG_CACHE_HOME:')

cat <<EOF >README.md
# [sysz-ng](https://github.com/Esl1h/sysz-ng)

A [fzf](https://github.com/junegunn/fzf) terminal UI for systemctl

VERSION: $(cat VERSION)

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
  so \`start\` does not show for something already running.
- Runs \`status\` after anything that changes a unit, so you see the result.
- Preview shows \`status\`, or \`cat\` the unit file with \`ctrl-v\`.
- Reads the journal for a unit, following it if you want.
- Filters by state with \`ctrl-s\` or \`--state\`, and runs \`daemon-reload\`
  with \`ctrl-r\`.
- **Smart filtering** hides generated, transient and boot-time units by
  default (\`.device\`, \`.slice\`, \`session-*.scope\`, \`systemd-fsck@*\`, etc).
  Use \`--all\` or \`ctrl-e\` inside the picker to see everything.
- **Admin-owned mode** (\`--mine\`, \`--etc\`) shows only units with fragments
  or drop-ins under \`/etc/systemd\` or \`~/.config/systemd/user\`. This is the
  default when launching without arguments, so you see what you (or your
  Ansible/Terraform) actually put on the machine. \`ctrl-e\` toggles back to
  the full list.
- Filter by unit type with \`--type\` (e.g. \`--type service,timer\`).
- **Curated mode** (\`--curated\`) hides units that are effectively
  immutable: \`RefuseManualStart/Stop\`, \`Perpetual\`, \`Transient\`, or
  generated from \`SourcePath\`. Use \`ctrl-a\` inside the picker to toggle.
- **Recent-first sort** (\`--recent\`) orders units by
  \`StateChangeTimestampMonotonic\`, so the units that changed state most
  recently appear first. Use \`ctrl-t\` inside the picker to toggle.
- Takes several units, states or commands at once with \`TAB\`.
- Calls \`sudo\` (or \`SYSZ_SUDO\`) only when the unit actually requires it.
- Short aliases for the systemctl commands, to type less.
- Host and machine passthrough: \`-H/--host\` and \`-M/--machine\`.
- Template units list existing instances instead of asking for a parameter.
- Cache for \`list-unit-files\` with mtime-based invalidation.

# Requirements

- systemd, for \`systemctl\` and \`journalctl\`
- [fzf](https://github.com/junegunn/fzf) >= [0.46.0](https://github.com/junegunn/fzf/blob/master/CHANGELOG.md#0460)
- bash >= 4.3
- awk, plus the usual \`sed\`, \`sort\`, \`grep\`, \`cut\` and \`stty\`

# Installation

\`sysz-ng\` is a single bash script, so installing it means putting one file
somewhere on your \`PATH\`.

There is no distribution package yet. The \`sysz\` in the AUR and
in nixpkgs is built from [joehillen/sysz](https://github.com/joehillen/sysz),
which this forked from and which has not changed since 2022, so those
packages do not carry anything described here.

## Install script

${BLOCK}sh
curl -fsSL https://raw.githubusercontent.com/Esl1h/sysz-ng/main/install.sh | bash
${BLOCK}

Installs to \`~/.local/bin\`, so it needs no privileges, and says so if that
directory is not on your \`PATH\`. It checks bash, awk and fzf first and
refuses rather than leaving you with something that will not start.

It reads a few variables:

${BLOCK}sh
# install somewhere else
SYSZ_INSTALL_DIR=/usr/local/bin curl -fsSL .../install.sh | sudo -E bash

# install a particular tag or branch
SYSZ_REF=2.3.0 curl -fsSL .../install.sh | bash
${BLOCK}

Piping a script into a shell is worth being careful about. This one is
[install.sh](install.sh) in this repository if you want to read it first.

## Direct download

${BLOCK}sh
mkdir -p ~/.local/bin
curl -fsSL -o ~/.local/bin/sysz-ng https://raw.githubusercontent.com/Esl1h/sysz-ng/main/sysz-ng
chmod +x ~/.local/bin/sysz-ng
${BLOCK}

## From source

${BLOCK}sh
git clone https://github.com/Esl1h/sysz-ng.git
cd sysz-ng
sudo make install # /usr/local/bin/sysz-ng
${BLOCK}

Running the tests needs [bats](https://github.com/bats-core/bats-core):

${BLOCK}sh
make test
${BLOCK}

# Usage

${BLOCK}text
$USAGE
${BLOCK}

# Alternatives

\`sysz-ng\` is deliberately a single Bash script: no build, no runtime,
no binary — it only needs \`bash\` and \`fzf\`. This makes it trivial to
drop onto any host via \`scp\`. If you want a full TUI (panels, live
logs, auto-refresh), these projects do more:

| Project | Language | Backend | Note |
|---|---|---|---|
| [systemctl-tui](https://github.com/rgwood/systemctl-tui) | Rust / ratatui | D-Bus | Supports remote host via SSH (\`--host\`) |
| [isd](https://github.com/isd-project/isd) | Python / Textual | systemctl | Fuzzy search, auto-refresh preview, smart sudo |
| [systemd-manager-tui](https://github.com/matheus-git/systemd-manager-tui) | Rust | D-Bus | RPM and DEB packages |
| [sdtop](https://github.com/YashSaini99/sdtop) | — | systemctl | Dashboard with process tree |

\`systemctl-tui\` and \`isd\` cite \`sysz\` as inspiration — \`isd\` describes
itself as a more powerful and heavier version of it.

**When to stay with sysz-ng:** ephemeral hosts, environments where installing
a binary is bureaucracy, or when you just want \`sysz-ng restart\` and leave.
**When to migrate:** continuous monitoring, real-time logs, daily use as a
dashboard.

# Acknowledgements

Originally written by [Joe Hillenbrand](https://github.com/joehillen).
This fork began as [joehillen/sysz](https://github.com/joehillen/sysz) but
continues independently as \`sysz-ng\`.

Inspired by [fuzzy-sys](https://github.com/NullSense/fuzzy-sys) by [NullSense](https://github.com/NullSense/)

Thank you for [ShellCheck](https://github.com/koalaman/shellcheck) without which this would be a buggy mess.
EOF
