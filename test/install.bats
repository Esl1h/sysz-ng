#!/usr/bin/env bats
#
# Tests for the install script. SYSZ_URL points at a local file, so nothing
# here reaches the network, and SYSZ_INSTALL_DIR keeps it out of $HOME.

setup() {
  INSTALL="${BATS_TEST_DIRNAME}/../install.sh"
  SRC="${BATS_TEST_DIRNAME}/../sysz-ng"
  DIR="$BATS_TEST_TMPDIR/bin"
  export SYSZ_INSTALL_DIR="$DIR"
  export SYSZ_URL="file://$SRC"
}

@test "it installs the script and makes it executable" {
  run bash "$INSTALL"
  [ "$status" -eq 0 ]
  [ -x "$DIR/sysz-ng" ]
}

@test "what it installs is what it fetched" {
  bash "$INSTALL"
  cmp "$SRC" "$DIR/sysz-ng"
}

@test "it reports the version it installed" {
  run bash "$INSTALL"
  [[ $output == *"sysz-ng $(sed -n 's/^SYSZ_VERSION=//p' "$SRC")"* ]]
}

@test "running it twice is fine and says what it replaced" {
  bash "$INSTALL"
  run bash "$INSTALL"
  [ "$status" -eq 0 ]
  [[ $output == *replacing* ]]
}

@test "it works when piped to bash, which is how it is documented" {
  run bash -c "cat '$INSTALL' | bash"
  [ "$status" -eq 0 ]
  [ -x "$DIR/sysz-ng" ]
}

@test "it says so when the target is not on PATH" {
  run bash "$INSTALL"
  [[ $output == *'not on your PATH'* ]]
}

@test "it stays quiet about PATH when the target is on it" {
  PATH="$DIR:$PATH" run bash "$INSTALL"
  [[ $output != *'not on your PATH'* ]]
}

# A download cut short must not end up installed, because a truncated sysz
# would still be executable and would misbehave in ways that look like bugs.
@test "it refuses a truncated download" {
  head -c 300 "$SRC" >"$BATS_TEST_TMPDIR/partial"
  SYSZ_URL="file://$BATS_TEST_TMPDIR/partial" run bash "$INSTALL"
  [ "$status" -ne 0 ]
  [ ! -e "$DIR/sysz-ng" ]
}

@test "it refuses something that is not a shell script" {
  printf '<html>404</html>\n' >"$BATS_TEST_TMPDIR/page"
  SYSZ_URL="file://$BATS_TEST_TMPDIR/page" run bash "$INSTALL"
  [ "$status" -ne 0 ]
  [ ! -e "$DIR/sysz-ng" ]
}

@test "it refuses an empty download" {
  : >"$BATS_TEST_TMPDIR/empty"
  SYSZ_URL="file://$BATS_TEST_TMPDIR/empty" run bash "$INSTALL"
  [ "$status" -ne 0 ]
  [ ! -e "$DIR/sysz-ng" ]
}

@test "it refuses to install when fzf is too old" {
  mkdir -p "$BATS_TEST_TMPDIR/oldfzf"
  printf '#!/bin/sh\necho "0.30.0 (fake)"\n' >"$BATS_TEST_TMPDIR/oldfzf/fzf"
  chmod +x "$BATS_TEST_TMPDIR/oldfzf/fzf"
  PATH="$BATS_TEST_TMPDIR/oldfzf:$PATH" run bash "$INSTALL"
  [ "$status" -ne 0 ]
  [[ $output == *'0.46.0 or newer'* ]]
  [ ! -e "$DIR/sysz-ng" ]
}

@test "SYSZ_SKIP_FZF_CHECK gets past the fzf requirement" {
  mkdir -p "$BATS_TEST_TMPDIR/oldfzf"
  printf '#!/bin/sh\necho "0.30.0 (fake)"\n' >"$BATS_TEST_TMPDIR/oldfzf/fzf"
  chmod +x "$BATS_TEST_TMPDIR/oldfzf/fzf"
  PATH="$BATS_TEST_TMPDIR/oldfzf:$PATH" SYSZ_SKIP_FZF_CHECK=1 run bash "$INSTALL"
  [ "$status" -eq 0 ]
  [ -x "$DIR/sysz-ng" ]
}

@test "it fails when the download cannot be reached" {
  SYSZ_URL="file://$BATS_TEST_TMPDIR/does-not-exist" run bash "$INSTALL"
  [ "$status" -ne 0 ]
  [ ! -e "$DIR/sysz-ng" ]
}
