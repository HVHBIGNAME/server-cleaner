# Contributing

Keep `server-cleaner.sh` standalone and compatible with POSIX `sh`. Expose user actions as flags
of the installed `server-cleaner` command. New cleanup actions
must have a read-only plan, explicit execution, actionable failures and an isolated regression test.

## Local checks

Use a POSIX environment with Python 3.9+ and ShellCheck:

```sh
for script in *.sh; do sh -n "$script"; done
shellcheck --shell=sh --severity=warning ./*.sh
python3 -B -m unittest discover -s tests -v
```

`tests/helpers.py` provides a private HOME and an allow-listed command path. Package managers,
Docker and crontab are faked. Do not add the host's `/usr/bin` to the test PATH or run unscoped
system cleanup in tests. `tests/smoke_platform.py --apply` is reserved for disposable machines.

To exercise another shell:

```sh
SHELL_UNDER_TEST=/bin/dash python3 -B -m unittest discover -s tests -v
```

The CI matrix runs Linux container tests, a macOS job and a FreeBSD VM. It tests real native
package-cache commands separately from regression fixtures. Add a matching matrix job when
claiming a new natively tested platform.

## Runtime bundle integrity

After editing `server-cleaner.sh`, regenerate `SHA256SUMS`:

```sh
sha256sum server-cleaner.sh > SHA256SUMS
# macOS alternative:
shasum -a 256 server-cleaner.sh > SHA256SUMS
```

Use LF line endings. `--install` verifies exact contents, shell syntax and the managed-file
marker before replacing the program. Keep exactly one `server-cleaner.sh` entry; the integrity test
checks it against the current source. Test offline installation with
`sh server-cleaner.sh --install --from "$PWD" --prefix /absolute/test/prefix`.

## Report graphics

The SVG tool uses only Python's standard library. Text is escaped, schema versions and
numeric measurements are validated, and task counts must agree with the actual results.

```sh
python3 tools/render_report.py docs/example-report.json --title "EXAMPLE DATA / NOT A BENCHMARK" > docs/assets/report-dark.svg
python3 tools/render_report.py docs/example-report.json --theme light --title "EXAMPLE DATA / NOT A BENCHMARK" > docs/assets/report-light.svg
```

The checked-in example uses **illustrative values**. Do not turn it into a performance claim.
Keep the dark / light graphics readable and provide meaningful image descriptions.

## Pull requests

Describe user-visible behavior changes, platforms exercised and remaining limitations.
Prefer small commits. Never include credentials, real shell histories or unredacted server logs.
