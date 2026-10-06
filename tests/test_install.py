from pathlib import Path

from helpers import REPO, ShellTestCase


class InstallTests(ShellTestCase):
    def test_offline_install_is_executable_and_does_not_clean_or_schedule(self):
        self.native("apt-get")
        self.cron()
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        path = self.prefix / "bin" / "server-cleaner"
        self.assertEqual(list(path.parent.iterdir()), [path])
        self.assertEqual(path.stat().st_mode & 0o777, 0o755)
        version = self.run_script(self.prefix / "bin" / "server-cleaner", "--version")
        self.assertEqual(version.stdout.strip(), "2.0.0")
        self.assertEqual(self.calls(), [])
        self.assertFalse(self.cron_store.exists())

    def test_quiet_is_not_consent_to_scheduling(self):
        self.cron()
        result = self.install("--silent")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertFalse(self.cron_store.exists())

    def test_corrupted_download_preserves_existing_installation(self):
        source = self.bundle()
        self.assertEqual(self.install(source=source).returncode, 0)
        installed = self.prefix / "bin" / "server-cleaner"
        before = installed.read_bytes()
        (source / "clean.sh").write_text("#!/bin/sh\necho corrupt\n")
        result = self.install(source=source)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SHA-256", result.stderr)
        self.assertEqual(installed.read_bytes(), before)
        self.assertFalse(list(self.prefix.glob("bin/.server-cleaner*")))

    def test_bad_syntax_is_rejected_even_if_hash_matches(self):
        source = self.bundle()
        (source / "clean.sh").write_text("#!/bin/sh\nif then\n")
        self.write_checksums(source)
        result = self.install(source=source)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.prefix.exists())

    def test_duplicate_or_missing_manifest_entries_are_rejected(self):
        source = self.bundle()
        manifest = source / "SHA256SUMS"
        lines = manifest.read_text().splitlines(keepends=True)
        for contents in ("".join(lines + [lines[0]]), "".join(lines[1:])):
            with self.subTest(contents=contents):
                manifest.write_text(contents)
                result = self.install(source=source)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.prefix.exists())

    def test_missing_download_never_creates_installation(self):
        source = self.bundle()
        (source / "clean.sh").unlink()
        result = self.install(source=source)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.prefix.exists())

    def test_unrelated_file_cannot_be_overwritten(self):
        target = self.prefix / "bin" / "server-cleaner"
        target.parent.mkdir(parents=True)
        target.write_text("a different application")
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_text(), "a different application")

    def test_symlink_target_cannot_be_overwritten(self):
        other = self.root / "other"
        other.write_text("unchanged")
        target = self.prefix / "bin" / "server-cleaner"
        target.parent.mkdir(parents=True)
        target.symlink_to(other)
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(target.is_symlink())
        self.assertEqual(other.read_text(), "unchanged")

    def test_reinstall_and_uninstall_are_idempotent(self):
        source = self.bundle()
        self.assertEqual(self.install(source=source).returncode, 0)
        self.assertEqual(self.install(source=source).returncode, 0)
        keep = self.prefix / "bin" / "other-command"
        keep.write_text("keep")
        for _ in range(2):
            result = self.run_script("clean.sh", "--uninstall", "--prefix", self.prefix, "--yes")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(keep.exists())
        self.assertFalse((self.prefix / "bin" / "server-cleaner").exists())

    def test_installed_uninstaller_infers_prefix(self):
        self.assertEqual(self.install().returncode, 0)
        result = self.run_script(self.prefix / "bin" / "server-cleaner", "--uninstall", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.prefix / "bin" / "server-cleaner").exists())

    def test_uninstall_without_tty_requires_yes(self):
        self.assertEqual(self.install().returncode, 0)
        result = self.run_script("clean.sh", "--uninstall", "--prefix", self.prefix)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.prefix / "bin" / "server-cleaner").exists())

    def test_schedule_updates_only_its_marker_and_is_idempotent(self):
        self.as_root()
        self.cron()
        source = self.bundle()
        unrelated = '# user jobs\n5 * * * * echo "server-cleaner notes"\n'
        self.cron_store.write_text(unrelated)
        for _ in range(2):
            result = self.install("--autostart", "daily", source=source)
            self.assertEqual(result.returncode, 0, result.stderr)
        contents = self.cron_store.read_text()
        self.assertTrue(contents.startswith(unrelated))
        self.assertEqual(contents.count("# BEGIN server-cleaner"), 1)
        self.assertIn(f"/bin/sh '{self.prefix}/bin/server-cleaner' --apply --yes", contents)
        result = self.run_script("clean.sh", "--uninstall", "--prefix", self.prefix, "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.cron_store.read_text(), unrelated)

    def test_schedule_quotes_apostrophes(self):
        self.as_root()
        self.cron()
        self.prefix = self.root / "it's a path"
        result = self.install("--autostart", "daily")
        self.assertEqual(result.returncode, 0, result.stderr)
        line = self.cron_store.read_text().splitlines()[1]
        # Execute the generated shell fragment with --version instead of cleanup.
        shell_fragment = line.split(" ", 5)[5].replace("--apply --yes --no-color", "--version")
        check = self.run_script(Path(self.bin / "sh"), "-c", shell_fragment)
        self.assertEqual(check.returncode, 0, check.stderr)
        self.assertEqual(check.stdout.strip(), "2.0.0")

    def test_crontab_permission_error_is_not_treated_as_an_empty_table(self):
        self.as_root()
        self.cron()
        self.cron_store.write_text("important schedule\n")
        self.env["CRON_ERROR"] = "crontab: permission denied"
        result = self.install("--autostart", "daily")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.cron_store.read_text(), "important schedule\n")

    def test_uninstall_keeps_files_when_cron_update_fails(self):
        self.as_root()
        self.cron()
        self.assertEqual(self.install("--autostart", "daily").returncode, 0)
        self.env["CRON_WRITE_FAIL"] = "1"
        result = self.run_script("clean.sh", "--uninstall", "--prefix", self.prefix, "--yes")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.prefix / "bin" / "server-cleaner").exists())

    def test_malformed_cron_block_does_not_delete_other_jobs(self):
        self.as_root()
        self.cron()
        original = f"# BEGIN server-cleaner {self.prefix}\n0 * * * * important-job\n"
        self.cron_store.write_text(original)
        result = self.install("--autostart", "daily")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.cron_store.read_text(), original)
        result = self.run_script("clean.sh", "--uninstall", "--prefix", self.prefix, "--yes")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.cron_store.read_text(), original)

    def test_non_root_schedule_is_rejected_before_installing(self):
        self.env["TEST_UID"] = "1000"
        self.env["STAT_OWNER_OVERRIDE"] = "1000"
        self.native("apt-get")
        self.cron()
        result = self.install("--autostart", "daily")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.prefix.exists())

    def test_legacy_migration_removes_only_the_exact_old_job(self):
        legacy = self.home / ".cache" / "system" / ".sysupdate"
        legacy.parent.mkdir(parents=True)
        legacy.write_text("#!/bin/bash\ncat /dev/null > ~/.bash_history\nsudo truncate -s 0 /var/log/auth.log\n")
        keep = legacy.parent / "other"
        keep.write_text("keep")
        self.cron()
        unrelated = "# .sysupdate documentation\n0 1 * * * other-job\n"
        self.cron_store.write_text(unrelated + f"0 0 * * * /bin/bash {legacy} >/dev/null 2>&1\n")
        source = self.bundle()
        result = self.install(source=source)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(legacy.exists())
        result = self.install("--migrate-legacy", "--yes", source=source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(legacy.exists())
        self.assertEqual(keep.read_text(), "keep")
        self.assertEqual(self.cron_store.read_text(), unrelated)

    def test_installer_reads_code_from_pipe_without_consuming_it_as_answers(self):
        source = self.bundle()
        result = self.run_script(
            self.bin / "sh", "-s", "--", "--install", "--from", source, "--prefix", self.prefix,
            input_text=(REPO / "clean.sh").read_text(),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.prefix / "bin" / "server-cleaner").is_file())

    def test_bad_prefix_is_rejected(self):
        source = self.bundle()
        for prefix in ("relative", "/", "/tmp/..", "/tmp/a%name", "/tmp/a\nname"):
            with self.subTest(prefix=prefix):
                result = self.run_script("clean.sh", "--install", "--from", source, "--prefix", prefix)
                self.assertNotEqual(result.returncode, 0)

    def test_remote_install_uses_the_selected_ref(self):
        source = self.bundle()
        self.env["DOWNLOAD_SOURCE"] = str(source)
        self.command("curl", '''
url='' destination=''
while [ "$#" -gt 0 ]; do
    case $1 in
        https://*) url=$1 ;;
        -o) destination=$2; shift ;;
    esac
    shift
done
printf '%s\n' "$url" >> "$CALL_LOG"
cp "$DOWNLOAD_SOURCE/${url##*/}" "$destination"
''')
        result = self.run_script("clean.sh", "--install", "--prefix", self.prefix, "--ref", "v2-test")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 2)
        for call in self.calls():
            self.assertIn("/server-cleaner/v2-test/", call[0])
        self.assertEqual((self.prefix / "bin" / "server-cleaner").read_bytes(), (source / "clean.sh").read_bytes())

    def test_wget_works_without_curl(self):
        source = self.bundle()
        self.env["DOWNLOAD_SOURCE"] = str(source)
        self.command("wget", '''
destination='' url=''
while [ "$#" -gt 0 ]; do
    case $1 in
        -O) destination=$2; shift ;;
        https://*) url=$1 ;;
    esac
    shift
done
cp "$DOWNLOAD_SOURCE/${url##*/}" "$destination"
''')
        result = self.run_script("clean.sh", "--install", "--prefix", self.prefix)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.prefix / "bin" / "server-cleaner").is_file())

    def test_remote_network_failure_preserves_installed_command(self):
        self.assertEqual(self.install().returncode, 0)
        installed = self.prefix / "bin" / "server-cleaner"
        before = installed.read_bytes()
        self.command("curl", "exit 22")
        result = self.run_script("clean.sh", "--install", "--prefix", self.prefix)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Download failed", result.stderr)
        self.assertEqual(installed.read_bytes(), before)

    def test_cron_concurrent_change_is_preserved(self):
        self.as_root()
        self.cron_store.write_text("0 1 * * * original-job\n")
        self.command("crontab", '''
if [ "$1" = -l ]; then
    cat "$CRON_STORE"
    if [ ! -f "$CRON_STORE.read" ]; then
        printf '5 2 * * * concurrent-job\n' >> "$CRON_STORE"
        : > "$CRON_STORE.read"
    fi
else
    cp "$1" "$CRON_STORE"
fi
''')
        result = self.install("--autostart", "daily")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("changed concurrently", result.stderr)
        self.assertEqual(self.cron_store.read_text(), "0 1 * * * original-job\n5 2 * * * concurrent-job\n")

    def test_agents_report_a_missing_query_tool(self):
        result = self.run_script("clean.sh", "--agents")
        self.assertEqual(result.returncode, 3)
        self.assertIn("No supported package database", result.stderr)

    def test_agents_check_exact_packages_without_mutating(self):
        self.command("dpkg-query", '''
case "$3" in
    qemu-guest-agent|cloud-init) printf installed; exit 0 ;;
    *) exit 1 ;;
esac
''')
        self.native("apt-get")
        self.native("systemctl")
        self.native("pkill")
        result = self.run_script("clean.sh", "--agents")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("qemu-guest-agent", result.stdout)
        self.assertIn("Found / Найдено: 2", result.stdout)
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.run_script("clean.sh", "--agents", "--force").returncode, 2)

    def test_help_describes_the_unified_interface(self):
        for language in ("en", "ru"):
            with self.subTest(language=language):
                result = self.run_script("clean.sh", "--lang", language, "--help")
                self.assertEqual(result.returncode, 0)
                for option in ("--install", "--update", "--uninstall", "--autostart", "--at", "--only", "--keep-days", "--agents", "--help"):
                    self.assertIn(option, result.stdout)

    def test_invalid_management_flags_do_not_install_or_schedule(self):
        self.cron()
        invalid = [
            ("--install", "--uninstall"), ("--agents", "--apply"),
            ("--install", "--json"), ("--uninstall", "--dry-run"),
            ("--autostart",), ("--autostart", "invalid"),
            ("--autostart", "daily", "--at", "24:00"),
            ("--autostart", "daily", "--at", "12:60"),
            ("--autostart", "daily", "--at", "3:17"),
            ("--autostart", "boot", "--at", "04:00"),
            ("--autostart", "off", "--only", "history"),
            ("--at", "04:00"), ("--ref", "main"), ("--migrate-legacy",),
            ("--install", "--only", "packages"), ("--prefix", str(self.prefix)),
        ]
        for args in invalid:
            with self.subTest(args=args):
                result = self.run_script("clean.sh", *args)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertFalse(self.prefix.exists())
                self.assertFalse(self.cron_store.exists())

    def test_autostart_can_be_changed_and_disabled_from_installed_command(self):
        self.as_root()
        self.native("apt-get")
        self.native("journalctl")
        self.cron()
        self.assertEqual(self.install().returncode, 0)
        program = self.prefix / "bin" / "server-cleaner"
        result = self.run_script(program, "--autostart", "daily", "--at", "04:05", "--only", "packages,journal", "--keep-days", "30", "--lang", "ru", "--quiet")
        self.assertEqual(result.returncode, 0, result.stderr)
        entry = self.cron_store.read_text()
        self.assertIn("5 4 * * * ", entry)
        self.assertIn("--only packages,journal --keep-days 30 --lang ru --quiet", entry)
        self.assertEqual(self.calls(), [])
        status = self.run_script(program, "--autostart", "status")
        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertIn("5 4 * * *", status.stdout)
        for _ in range(2):
            result = self.run_script(program, "--autostart", "off")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.cron_store.read_text(), "")
        self.assertIn("off", self.run_script(program, "--autostart", "status").stdout)
        self.assertTrue(program.is_file())

    def test_boot_and_weekly_schedules(self):
        self.as_root()
        self.cron()
        self.assertEqual(self.install().returncode, 0)
        program = self.prefix / "bin" / "server-cleaner"
        for args, prefix in [(("--autostart", "boot"), "@reboot "), (("--autostart", "weekly", "--at", "23:59"), "59 23 * * 0 ")]:
            with self.subTest(args=args):
                result = self.run_script(program, *args)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(self.cron_store.read_text().splitlines()[1].startswith(prefix))
                self.assertEqual(self.cron_store.read_text().count("# BEGIN server-cleaner"), 1)

    def test_user_can_schedule_their_own_history(self):
        self.env["TEST_UID"] = "1000"
        self.env["STAT_OWNER_OVERRIDE"] = "1000"
        self.cron()
        result = self.install("--autostart", "daily", "--only", "history")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--only history", self.cron_store.read_text())

    def test_autostart_requires_an_installed_program(self):
        self.cron()
        result = self.run_script("clean.sh", "--prefix", self.prefix, "--autostart", "daily")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.cron_store.exists())

    def test_install_and_apply_preserve_cleanup_arguments(self):
        self.as_root()
        self.native("apt-get")
        self.native("journalctl")
        result = self.install("--apply", "--yes", "--only", "journal", "--keep-days", "30")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [["journalctl", "--vacuum-time=30d"]])

    def test_install_consolidates_owned_old_helpers(self):
        self.prefix.joinpath("bin").mkdir(parents=True)
        for kind in ("agents", "uninstall"):
            self.prefix.joinpath("bin", "server-cleaner-" + kind).write_text("#!/bin/sh\n# server-cleaner:managed:" + kind + "\n")
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([path.name for path in self.prefix.joinpath("bin").iterdir()], ["server-cleaner"])

    def test_update_uses_the_current_prefix(self):
        source = self.bundle()
        self.assertEqual(self.install(source=source).returncode, 0)
        result = self.run_script(self.prefix / "bin/server-cleaner", "--update", "--from", source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.prefix.joinpath("bin/server-cleaner").exists())
