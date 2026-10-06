<picture>
  <source media="(prefers-color-scheme: light)" srcset="./docs/assets/hero-light.svg">
  <img src="./docs/assets/hero-dark.svg" width="100%" alt="Server Cleaner — Less clutter. More control.">
</picture>

Linux, macOS and BSD maintenance. **One command, configured with flags.** [Русский](./README.md)

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/server-cleaner.sh | sh -s -- --install
```

Installs to `~/.local/bin/server-cleaner`, or `/usr/local/bin/server-cleaner` for root.
If the command is not on `PATH`, use the full path printed by the installer.

## Run

```sh
server-cleaner --help                  # All flags and examples
server-cleaner --dry-run               # Preview the plan
server-cleaner --apply                 # Confirm and clean
server-cleaner --apply --yes --only packages,journal --keep-days 30
```

System tasks require root. Running without arguments opens a menu.

## Autostart

```sh
server-cleaner --autostart daily --at 04:00 --only packages,journal --keep-days 30
server-cleaner --autostart status      # Inspect the schedule
server-cleaner --autostart off         # Disable it
```

Modes: `daily`, `weekly`, `boot`, `off`, `status`. A running cron daemon is required.
The job preserves your selected tasks, retention and language.
Combine these flags with `--install` to set everything up in one command.

```sh
server-cleaner --update                # Update
server-cleaner --agents                # List guest / cloud packages
server-cleaner --uninstall --yes       # Remove the program and autostart
```

[Reference](./docs/USAGE.md) · [CI checks](https://github.com/HVHBIGNAME/server-cleaner/actions/workflows/ci.yml) · [MIT](./LICENSE)
