# Contributing

This is a maintained fork of [joehillen/sysz](https://github.com/joehillen/sysz),
which stopped receiving changes. Patches are welcome, including ones that
were opened against the original project and never merged.

## Running the tests

```sh
make test
```

Needs [bats](https://github.com/bats-core/bats-core). The tests never
touch a unit on your machine: the ones that need `systemctl` or `fzf`
supply their own.

## Before opening a pull request

```sh
shellcheck sysz-ng
shfmt -d sysz-ng
make test
```

The linters run in CI as well, and `shfmt` picks up its settings from
`.editorconfig`, so run it without flags.

Two things are easy to miss:

- `README.md` is generated. Edit `README.sh` and run `./README.sh`, then
  commit both.
- The help text in `sysz-ng` and the command parser have drifted apart before.
  If you add a command, add it to both, and there is a test that checks
  they agree.

## Adding a test

`test/unit.bats` covers the functions the unit list is built from.
Sourcing `sysz-ng` gives you them without running the tool, so those tests
need neither fzf nor systemd.

`test/list.bats` and `test/exit.bats` fake `systemctl`, and `test/exit.bats`
fakes `fzf` too, which is what makes it possible to assert the exit code
of a full run without a terminal.

If you fix a bug, a test that fails without the fix is the most useful
part of the patch.

## Supported fzf

`MIN_FZF` in the script is the floor, and CI runs the suite against
exactly that version as well as the latest one. If you use something that
needs a newer fzf, raise `MIN_FZF` in the same change and say why.

## Commits

One change per commit, and a message that says why rather than what. The
diff already says what.
