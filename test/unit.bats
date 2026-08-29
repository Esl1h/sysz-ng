#!/usr/bin/env bats
#
# Tests for the functions sysz is built from. Sourcing the script exposes
# them without running the tool, so nothing here needs fzf or a live
# systemd, and nothing here touches unit state.

setup() {
  SYSZ="${BATS_TEST_DIRNAME}/../sysz-ng"
  # shellcheck disable=SC1090
  source "$SYSZ"
  ESC=$'\033'
}

# _sysz_manager

@test "_sysz_manager maps the user tag to a systemctl flag" {
  run _sysz_manager '[user] foo.service'
  [ "$status" -eq 0 ]
  [ "$output" = '--user' ]
}

@test "_sysz_manager maps the system tag to a systemctl flag" {
  run _sysz_manager '[system] foo.service'
  [ "$status" -eq 0 ]
  [ "$output" = '--system' ]
}

@test "_sysz_manager rejects anything else instead of guessing" {
  run _sysz_manager 'foo.service'
  [ "$status" -ne 0 ]
  [[ $output == *'Unknown manager'* ]]
}

# _sysz_colorize

@test "_sysz_colorize paints active units green" {
  run bash -c "source '$SYSZ'; printf 'foo.service loaded active running Foo\n' | _sysz_colorize"
  [ "$output" = "${ESC}[0;32mfoo.service${ESC}[0m" ]
}

@test "_sysz_colorize paints failed units red" {
  run bash -c "source '$SYSZ'; printf 'foo.service loaded failed failed Foo\n' | _sysz_colorize"
  [ "$output" = "${ESC}[0;31mfoo.service${ESC}[0m" ]
}

@test "_sysz_colorize paints not-found units yellow" {
  run bash -c "source '$SYSZ'; printf 'foo.service not-found inactive dead Foo\n' | _sysz_colorize"
  [ "$output" = "${ESC}[1;33mfoo.service${ESC}[0m" ]
}

@test "_sysz_colorize leaves other states uncoloured" {
  run bash -c "source '$SYSZ'; printf 'foo.service loaded inactive dead Foo\n' | _sysz_colorize"
  [ "$output" = 'foo.service' ]
}

@test "_sysz_colorize keeps only the unit name" {
  run bash -c "source '$SYSZ'; printf 'foo.service loaded inactive dead A long description\n' | _sysz_colorize"
  [ "$output" = 'foo.service' ]
}

# _sysz_sort

sort_fixture() {
  cat <<'EOF'
[system] zzz.socket
[user] aaa.timer
[system] mmm.service
[user] bbb.service
[system] ccc.timer
[user] ddd.socket
[system] eee.mount
EOF
}

@test "_sysz_sort groups by type, then puts user units before system ones" {
  run bash -c "source '$SYSZ'; $(declare -f sort_fixture); sort_fixture | _sysz_sort"
  [ "$status" -eq 0 ]
  cat <<'EOF' | diff - <(printf '%s\n' "$output")
[user] bbb.service
[system] mmm.service
[user] aaa.timer
[system] ccc.timer
[user] ddd.socket
[system] zzz.socket
[system] eee.mount
EOF
}

@test "_sysz_sort sorts on the unit name but keeps the colour codes" {
  local input="[system] ${ESC}[0;32mbbb.service${ESC}[0m
[system] ${ESC}[0;31maaa.service${ESC}[0m"
  run bash -c "source '$SYSZ'; printf '%s\n' '$input' | _sysz_sort"
  [ "${lines[0]}" = "[system] ${ESC}[0;31maaa.service${ESC}[0m" ]
  [ "${lines[1]}" = "[system] ${ESC}[0;32mbbb.service${ESC}[0m" ]
}

@test "_sysz_sort ignores dashes when ordering" {
  # "a-c" must sort after "ab", because the dash is not considered.
  run bash -c "source '$SYSZ'; printf '[user] a-c.service\n[user] ab.service\n' | _sysz_sort"
  [ "${lines[0]}" = '[user] ab.service' ]
  [ "${lines[1]}" = '[user] a-c.service' ]
}

@test "_sysz_sort drops duplicates" {
  run bash -c "source '$SYSZ'; printf '[user] foo.service\n[user] foo.service\n' | _sysz_sort"
  [ "${#lines[@]}" -eq 1 ]
}

@test "_sysz_sort accepts empty input" {
  run bash -c "source '$SYSZ'; printf '' | _sysz_sort"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# Header and layout

@test "_sysz_preview_pct gives the preview less room on narrow terminals" {
  [ "$(_sysz_preview_pct 200)" -eq 70 ]
  [ "$(_sysz_preview_pct 160)" -eq 70 ]
  [ "$(_sysz_preview_pct 159)" -eq 60 ]
  [ "$(_sysz_preview_pct 100)" -eq 60 ]
  [ "$(_sysz_preview_pct 99)" -eq 50 ]
  [ "$(_sysz_preview_pct 80)" -eq 50 ]
}

@test "_sysz_header shows more the more room there is" {
  [[ $(_sysz_header 60) == *'tab select'* ]]
  [[ $(_sysz_header 30) == 'esc quit'* ]]
  [[ $(_sysz_header 20) == '^s state'* ]]
  [ "$(_sysz_header 8)" = '? help' ]
}

@test "_sysz_header always mentions how to reach the full list of keys" {
  local w
  for w in 4 8 16 20 26 40 49 60 200; do
    [[ $(_sysz_header "$w") == *'? help'* ]] || {
      echo "no help hint at width $w: $(_sysz_header "$w")"
      return 1
    }
  done
}

# The first version of the header was cut off by fzf, which dropped the
# part that mattered. Whatever is returned has to fit.
@test "_sysz_header never returns more than it was given room for" {
  local w out
  for w in 8 12 16 20 25 26 30 35 43 48 49 55 80 200; do
    out=$(_sysz_header "$w")
    [ "${#out}" -le "$w" ] || {
      echo "width $w got ${#out} chars: $out"
      return 1
    }
  done
}

@test "the header fits at every terminal width the layout picks" {
  local width pct avail out
  for width in 60 70 80 100 120 140 160 200 250; do
    pct=$(_sysz_preview_pct "$width")
    avail=$(_sysz_header_width "$width" "$pct")
    out=$(_sysz_header "$avail")
    [ "${#out}" -le "$avail" ] || {
      echo "terminal $width, preview $pct%, room $avail, header ${#out}: $out"
      return 1
    }
  done
}

@test "_sysz_sort handles units without an extension" {
  run bash -c "source '$SYSZ'; printf '[user] noextension\n' | _sysz_sort"
  [ "$status" -eq 0 ]
  [ "$output" = '[user] noextension' ]
}
