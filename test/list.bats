#!/usr/bin/env bats
#
# Tests for the two-pass unit listing, driven by a fake systemctl so the
# result does not depend on what the host happens to have installed.
#
# The split matters: the first pass has to carry the loaded units on its
# own, and the second has to add only what the first did not already show.

setup() {
  SYSZ="${BATS_TEST_DIRNAME}/../sysz-ng"
  ESC=$'\033'

  # A fake systemctl answering both listing calls from fixtures.
  # running.service is loaded and also has a unit file, so it must be
  # reported once, by the pass that knows its runtime state.
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat >"$BATS_TEST_TMPDIR/bin/systemctl" <<'MOCK'
#!/usr/bin/env bash
case $1 in
list-units)
  cat <<'EOF'
running.service loaded active running A running service
broken.service loaded failed failed A failed service
ghost.service not-found inactive dead A missing service
EOF
  ;;
list-unit-files)
  cat <<'EOF'
running.service enabled enabled
dormant.service disabled disabled
dormant.service disabled disabled
template@.service static -
EOF
  ;;
esac
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/systemctl"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

list() {
  # shellcheck disable=SC1090
  source "$SYSZ"
  # Read by _sysz_list when it builds the systemctl arguments.
  # shellcheck disable=SC2034
  declare -a STATES=()
  _sysz_list "$1" --system
}

@test "the first pass reports exactly the loaded units" {
  run list loaded
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 3 ]
  [[ ${lines[0]} == *'running.service'* ]]
  [[ ${lines[1]} == *'broken.service'* ]]
  [[ ${lines[2]} == *'ghost.service'* ]]
}

@test "the first pass colours units by their runtime state" {
  run list loaded
  [ "${lines[0]}" = "${ESC}[0;32mrunning.service${ESC}[0m" ]
  [ "${lines[1]}" = "${ESC}[0;31mbroken.service${ESC}[0m" ]
  [ "${lines[2]}" = "${ESC}[1;33mghost.service${ESC}[0m" ]
}

@test "the second pass leaves out units the first one already showed" {
  run list unloaded
  [ "$status" -eq 0 ]
  [[ $output != *'running.service'* ]]
}

@test "the second pass reports the units that are not loaded" {
  run list unloaded
  [[ $output == *'dormant.service'* ]]
  [[ $output == *'template@.service'* ]]
}

@test "the second pass drops repeated unit files" {
  run list unloaded
  [ "$(grep -c 'dormant.service' <<<"$output")" -eq 1 ]
}

@test "the two passes together cover every unit exactly once" {
  local loaded unloaded all
  loaded=$(list loaded)
  unloaded=$(list unloaded)
  all=$(printf '%s\n%s\n' "$loaded" "$unloaded" | sed "s/${ESC}\[[0-9;]*m//g" | sort)
  [ "$all" = "$(printf 'broken.service\ndormant.service\nghost.service\nrunning.service\ntemplate@.service\n' | sort)" ]
}

@test "a unit in both listings keeps its runtime colour" {
  # If the unit-file line ever won, running.service would come out plain.
  run list loaded
  [[ $output == *"${ESC}[0;32mrunning.service"* ]]
}
