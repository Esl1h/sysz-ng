#!/usr/bin/env bash
#
#   curl -fsSL https://raw.githubusercontent.com/Esl1h/sysz/main/install.sh | bash
#
# Environment:
#   SYSZ_INSTALL_DIR  where to put the script  (default ~/.local/bin)
#   SYSZ_REF          branch or tag to install (default main)
#   SYSZ_REPO         owner/name to install from
#   SYSZ_URL          fetch from here instead, whatever curl accepts
#
# Everything lives inside a function that is called on the last line, so a
# download cut short cannot run half an installer.

set -euo pipefail

_sysz_install() {
  local repo=${SYSZ_REPO:-Esl1h/sysz-ng}
  local ref=${SYSZ_REF:-main}
  local dir=${SYSZ_INSTALL_DIR:-${XDG_BIN_HOME:-$HOME/.local/bin}}
  local url=${SYSZ_URL:-"https://raw.githubusercontent.com/${repo}/${ref}/sysz"}
  local min_fzf=0.46.0
  local target=$dir/sysz
  local tmp

  local red='' green='' yellow='' plain=''
  if [[ -t 2 ]]; then
    red=$'\033[0;31m' green=$'\033[0;32m' yellow=$'\033[1;33m' plain=$'\033[0m'
  fi

  say() { printf '%s\n' "$*" >&2; }
  ok() { printf '%s%s%s\n' "$green" "$*" "$plain" >&2; }
  warn() { printf '%swarning:%s %s\n' "$yellow" "$plain" "$*" >&2; }
  die() {
    printf '%serror:%s %s\n' "$red" "$plain" "$*" >&2
    exit 1
  }

  # Same comparison sysz itself uses, so the two agree on what is too old.
  older_than() {
    [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]]
  }

  # Requirements

  if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3))); then
    die "bash 4.3 or newer is required, this is ${BASH_VERSION}"
  fi

  command -v awk >/dev/null || die 'awk is required'

  local fetch
  if command -v curl >/dev/null; then
    fetch='curl -fsSL --retry 3 --retry-delay 2 -o'
  elif command -v wget >/dev/null; then
    fetch='wget -qO'
  else
    die 'either curl or wget is required'
  fi

  if [[ -n ${SYSZ_SKIP_FZF_CHECK:-} ]]; then
    warn 'not checking fzf, because SYSZ_SKIP_FZF_CHECK is set'
  elif command -v fzf >/dev/null; then
    local have
    have=$(fzf --version | cut -d' ' -f1)
    if older_than "$have" "$min_fzf"; then
      die "fzf $min_fzf or newer is required, found $have
  see https://github.com/junegunn/fzf#installation
  set SYSZ_SKIP_FZF_CHECK=1 to install anyway"
    fi
  else
    die "fzf is required and was not found
  see https://github.com/junegunn/fzf#installation
  set SYSZ_SKIP_FZF_CHECK=1 to install anyway"
  fi

  command -v systemctl >/dev/null ||
    warn 'systemctl was not found, so sysz will not have anything to talk to'

  # Download

  tmp=$(mktemp) || die 'could not create a temporary file'
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" EXIT

  if [[ -n ${SYSZ_URL:-} ]]; then
    say "fetching $url"
  else
    say "fetching ${repo}@${ref}"
  fi
  $fetch "$tmp" "$url" || die "could not download $url"
  [[ -s $tmp ]] || die 'the download was empty'

  # Check what arrived is the script and not an error page or half a file.
  head -n1 "$tmp" | grep -q '^#!.*bash' ||
    die 'what came back does not look like a shell script'
  grep -q '^SYSZ_VERSION=' "$tmp" || die 'the downloaded script looks incomplete'
  bash -n "$tmp" || die 'the downloaded script does not parse'
  [[ $(wc -c <"$tmp") -ge 5000 ]] || die 'the downloaded script looks truncated'

  local version
  version=$(sed -n 's/^SYSZ_VERSION=//p' "$tmp")

  # Install

  mkdir -p "$dir" || die "could not create $dir"
  [[ -w $dir ]] || die "$dir is not writable
  set SYSZ_INSTALL_DIR to somewhere else, or run this with sudo"

  local previous=''
  if [[ -e $target ]]; then
    previous=$("$target" --version 2>/dev/null | cut -d' ' -f2) || previous='unknown'
  fi

  install -m755 "$tmp" "$target" || die "could not write $target"

  if [[ -n $previous ]]; then
    ok "sysz $version installed to $target, replacing $previous"
  else
    ok "sysz $version installed to $target"
  fi

  # Tell them if it will not be found

  case ":$PATH:" in
  *":$dir:"*) ;;
  *)
    warn "$dir is not on your PATH. Add this to your shell startup file:

  export PATH=\"$dir:\$PATH\""
    ;;
  esac

  local found
  found=$(command -v sysz 2>/dev/null) || found=''
  if [[ -n $found && $found != "$target" ]]; then
    warn "another sysz comes first on your PATH: $found"
  fi
}

_sysz_install "$@"
