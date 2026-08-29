#!/usr/bin/env bats
#
# What sysz reports back to the shell after running a command.
#
# This drives the whole program, so both fzf and systemctl are faked: the
# fake fzf picks a unit without a tty, and the fake systemctl decides what
# the command and the status call return.

setup() {
  SYSZ="${BATS_TEST_DIRNAME}/../sysz-ng"
  BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$BIN"

  cat >"$BIN/fzf" <<'MOCK'
#!/usr/bin/env bash
for arg; do
  [ "$arg" = --version ] && { echo '0.46.0 (mock)'; exit 0; }
done
cat >/dev/null
# --expect prints the pressed key first; empty means plain Enter.
printf '\n[user] test.service\n'
MOCK

  cat >"$BIN/systemctl" <<'MOCK'
#!/usr/bin/env bash
for arg; do
  case $arg in
  list-units | list-unit-files)
    echo 'test.service loaded active running Test'
    exit 0
    ;;
  status)
    # A stopped unit reports 3, which is the whole point of these tests.
    exit "${MOCK_STATUS_RC:-3}"
    ;;
  stop | start | restart)
    exit "${MOCK_CMD_RC:-0}"
    ;;
  esac
done
exit 0
MOCK

  chmod +x "$BIN/fzf" "$BIN/systemctl"
  PATH="$BIN:$PATH"
}

@test "a command that succeeds exits 0 even when status reports the unit inactive" {
  MOCK_CMD_RC=0 MOCK_STATUS_RC=3 run "$SYSZ" -u stop
  [ "$status" -eq 0 ]
}

@test "a command that fails reports its own exit code" {
  MOCK_CMD_RC=5 MOCK_STATUS_RC=3 run "$SYSZ" -u stop
  [ "$status" -eq 5 ]
}

@test "the exit code comes from the command, not from the status call" {
  MOCK_CMD_RC=0 MOCK_STATUS_RC=4 run "$SYSZ" -u start
  [ "$status" -eq 0 ]
}

@test "a successful command after status succeeds still exits 0" {
  MOCK_CMD_RC=0 MOCK_STATUS_RC=0 run "$SYSZ" -u restart
  [ "$status" -eq 0 ]
}
