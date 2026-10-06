# Changelog

## 2.0.0 — unreleased

### Changed

- Replaced unconditional wiping with a plan-first maintenance CLI and native cleanup policies.
- Switched all entry points from Bash-specific syntax to POSIX `sh`.
- Installed commands now have descriptive names in `PREFIX/bin`, replacing the hidden v1 path.
- Active logs, audit / login databases and Docker log files are no longer manually truncated.
- Temporary files and core dumps use OS tmpfiles age rules; text logs use normal rotation.
- `anti-monitoring.sh` now inventories guest / cloud packages instead of removing integrations.
- Installer `--silent` no longer enables cron or dependency installation.

### Added

- English / Russian UI, interactive menu, `--dry-run`, task selection, retention and JSON reports.
- APT, DNF5, DNF, microdnf, YUM, Zypper, paccache/Pacman, APK, XBPS, Gentoo, Solus,
  Homebrew and FreeBSD pkg cache adapters.
- Explicit opt-in cleanup of local Docker build cache and the current user's saved history.
- Private run locks, permission preflight, path checks and nonzero failure statuses.
- Verified downloads, local installation, pinned refs, staged file replacement and explicit v1 migration.
- Idempotent, marked cron configuration with concurrent-change checks and reversible uninstallation.
- Dependency-free SVG report renderer, profile-style graphics and English documentation.
- Regression tests and Linux / ARM64 / macOS / FreeBSD CI.
- MIT license file matching the previously documented license.

### Migration

Run the installer with `--migrate-legacy --yes` as the original installing account.
This removes the recognized v1 script and its exact original cron line. Custom cron commands
must be reviewed manually. Add `--schedule daily` explicitly to schedule v2 maintenance.

Do not source `clean.sh`: a child process cannot clear an interactive parent's in-memory history.
