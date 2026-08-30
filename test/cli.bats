#!/usr/bin/env bats
#
# Tests for the command line surface: the paths that answer and exit
# without ever opening the picker. These do run the script, so fzf has to
# be installed, but no unit is touched.

setup() {
  SYSZ="${BATS_TEST_DIRNAME}/../sysz-ng"
  REPO="${BATS_TEST_DIRNAME}/.."
}

@test "--version reports the version recorded in VERSION" {
  run "$SYSZ" --version
  [ "$status" -eq 0 ]
  [ "$output" = "sysz-ng $(cat "$REPO/VERSION")" ]
}

@test "-v is the short form of --version" {
  run "$SYSZ" -v
  [ "$status" -eq 0 ]
  [ "$output" = "$("$SYSZ" --version)" ]
}

@test "--help succeeds" {
  run "$SYSZ" --help
  [ "$status" -eq 0 ]
  [[ $output == *'A utility for using systemctl interactively via fzf.'* ]]
}

@test "--help writes to stdout so it can be piped" {
  run bash -c "'$SYSZ' --help 2>/dev/null | wc -l"
  [ "$output" -gt 0 ]
}

@test "--help writes nothing to stderr" {
  local err="$BATS_TEST_TMPDIR/err"
  "$SYSZ" --help >/dev/null 2>"$err"
  [ ! -s "$err" ]
}

@test "-h and help are the same as --help" {
  [ "$("$SYSZ" -h)" = "$("$SYSZ" --help)" ]
  [ "$("$SYSZ" help)" = "$("$SYSZ" --help)" ]
}

# Every command the parser accepts used to have to be found by reading the
# source, because the help only listed some of them. Keep them listed.
@test "--help documents every command the parser accepts" {
  local help
  help=$("$SYSZ" --help)
  for cmd in start stop restart reload status enable disable \
    mask unmask cat edit show journal follow; do
    [[ $help == *"$cmd"* ]] || {
      echo "command not documented: $cmd"
      return 1
    }
  done
}

@test "--help documents the short aliases the parser accepts" {
  local help
  help=$("$SYSZ" --help)
  for alias in 'r, re, restart' 's, stat, status' 'ed, edit' 'en, enable' \
    'd, dis, disable' 'c, cat' 'j, journal' 'f, follow'; do
    [[ $help == *"$alias"* ]] || {
      echo "alias not documented: $alias"
      return 1
    }
  done
}

@test "an unknown option is rejected" {
  run "$SYSZ" --definitely-not-an-option
  [ "$status" -ne 0 ]
  [[ $output == *'Unknown option'* ]]
}

@test "an unknown state is rejected" {
  run "$SYSZ" --state=definitely-not-a-state
  [ "$status" -ne 0 ]
  [[ $output == *'Invalid state'* ]]
}

@test "a valid state is accepted by the parser" {
  # Reaching the picker means the state passed validation. There is no tty
  # here, so fzf exits on its own and the exit code is not what is checked.
  run "$SYSZ" --state=failed --user
  [[ $output != *'Invalid state'* ]]
}

@test "--recent is accepted by the parser" {
  run "$SYSZ" --recent --user
  [[ $output != *'Unknown option'* ]]
}
