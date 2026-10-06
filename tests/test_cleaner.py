import json
import os
import signal
import subprocess
import time

from helpers import REPO, SHELL, ShellTestCase


class CleanerTests(ShellTestCase):
    def report(self, *args, code=0):
        result = self.run_script("clean.sh", "--json", *args)
        self.assertEqual(result.returncode, code, result.stderr + result.stdout)
        self.assertNotIn("\x1b", result.stdout)
        return json.loads(result.stdout)

    def test_default_is_read_only_and_does_not_create_state(self):
        self.native("apt-get")
        self.native("journalctl")
        self.native("systemd-tmpfiles")
        history = self.home / ".bash_history"
        history.write_text("important history\n")
        report = self.report()
        self.assertEqual(report["mode"], "preview")
        self.assertGreater(report["summary"]["planned"], 0)
        self.assertEqual(self.calls(), [])
        self.assertFalse(self.state.exists())
        self.assertEqual(history.read_text(), "important history\n")
        self.assertIsNone(report["disk"]["after"])
        self.assertIsNone(report["disk"]["available_delta_kib"])

    def test_invalid_arguments_fail_before_any_work(self):
        invalid = [
            ("--wat",), ("--only",), ("--only", "packages,wat"),
            ("--only", "packages,,journal"), ("--only", ",history"),
            ("--only", "history,"), ("--only", "*"), ("--only", ""),
            ("--keep-days",), ("--keep-days", "0"), ("--keep-days", "-1"),
            ("--keep-days", "08"), ("--keep-days", "1;id"),
            ("--keep-days", "999999999999999999999999"),
            ("--keep-days", "3651"), ("--lang", "fr"), ("--lang",),
            ("--list", "--apply"),
        ]
        for args in invalid:
            with self.subTest(args=args):
                result = self.run_script("clean.sh", *args)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertFalse(self.state.exists())

    def test_unknown_operating_system_fails_without_changes(self):
        self.env["TEST_OS"] = "MSYS_NT-10.0"
        result = self.run_script("clean.sh", "--apply", "--yes")
        self.assertEqual(result.returncode, 3)
        self.assertIn("WSL", result.stderr)
        self.assertFalse(self.state.exists())

    def test_help_and_version_work_without_a_supported_os(self):
        self.env["TEST_OS"] = "Windows"
        self.assertEqual(self.run_script("clean.sh", "--version").stdout.strip(), "2.0.0")
        result = self.run_script("clean.sh", "--lang", "ru", "--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("Использование", result.stdout)

    def test_locale_can_be_overridden(self):
        self.env["LC_ALL"] = "ru_RU.UTF-8"
        result = self.run_script("clean.sh", "--only", "packages")
        self.assertIn("Предварительный", result.stdout)
        result = self.run_script("clean.sh", "--lang", "en", "--only", "packages")
        self.assertIn("Preview:", result.stdout)

    def test_apply_requires_explicit_confirmation_without_a_terminal(self):
        self.native("apt-get")
        self.as_root()
        result = self.run_script("clean.sh", "--apply", "--only", "packages")
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.calls(), [])
        self.assertFalse(self.state.exists())

    def test_yes_alone_does_not_enable_cleanup(self):
        self.native("apt-get")
        self.report("--yes", "--only", "packages")
        self.assertEqual(self.calls(), [])

    def test_permission_failure_stops_the_whole_preflight(self):
        self.env["TEST_UID"] = "99999"
        self.native("apt-get")
        self.native("journalctl")
        report = self.report("--only", "packages,journal", "--apply", "--yes", code=1)
        self.assertEqual(report["summary"]["failed"], 2)
        self.assertEqual(self.calls(), [])
        self.assertFalse(self.state.exists())

    def test_native_error_is_reported_and_other_tasks_finish(self):
        self.as_root()
        self.native("apt-get", 42)
        self.native("journalctl")
        result = self.run_script("clean.sh", "--json", "--apply", "--yes", "--only", "packages,journal")
        report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(report["summary"]["failed"], 1)
        self.assertEqual(report["summary"]["completed"], 1)
        self.assertIn("42", report["tasks"][0]["detail"])
        self.assertIn("native output", result.stderr)
        self.assertNotIn("native output", result.stdout)
        self.assertFalse((self.state / "server-cleaner" / "lock").exists())

    def test_unsupported_features_are_explicit_skips(self):
        report = self.report("--only", "packages,journal,temp,logs,coredumps")
        self.assertEqual(report["summary"]["skipped"], 5)
        self.assertEqual(report["summary"]["failed"], 0)

    def test_package_manager_adapters(self):
        adapters = {
            "apt-get": ["apt-get", "clean"],
            "dnf5": ["dnf5", "clean", "packages"],
            "dnf": ["dnf", "clean", "packages"],
            "microdnf": ["microdnf", "clean", "packages"],
            "yum": ["yum", "clean", "packages"],
            "zypper": ["zypper", "--non-interactive", "clean"],
            "paccache": ["paccache", "-r", "-k", "2"],
            "pacman": ["pacman", "--sync", "--clean", "--noconfirm"],
            "apk": ["apk", "cache", "clean"],
            "xbps-remove": ["xbps-remove", "-O"],
            "eclean-pkg": ["eclean-pkg"],
            "eopkg": ["eopkg", "delete-cache"],
        }
        self.as_root()
        for manager, expected in adapters.items():
            with self.subTest(manager=manager):
                stub = self.native(manager)
                report = self.report("--only", "packages", "--apply", "--yes")
                self.assertEqual(report["package_manager"], manager)
                self.assertEqual(self.calls()[-1], expected)
                self.assertEqual(report["summary"]["completed"], 1)
                stub.unlink()

    def test_dnf5_is_preferred_to_yum_and_paccache_to_pacman(self):
        paths = [self.native(name) for name in ("yum", "dnf", "dnf5")]
        self.assertEqual(self.report("--only", "packages")["package_manager"], "dnf5")
        for path in paths:
            path.unlink()
        self.native("paccache")
        self.native("pacman")
        self.assertEqual(self.report("--only", "packages")["package_manager"], "paccache")

    def test_bsd_pkg_and_macos_brew_selection(self):
        self.native("pkg")
        self.env["TEST_OS"] = "FreeBSD"
        self.assertEqual(self.report("--only", "packages")["tasks"][0]["command"], ["pkg", "clean", "-y"])
        self.env["TEST_OS"] = "Darwin"
        self.env["TEST_UID"] = "1000"
        self.native("brew")
        command = self.report("--only", "packages")["tasks"][0]["command"]
        self.assertEqual(command[-3:], ["brew", "cleanup", "--prune=14"])
        self.env["TEST_UID"] = "0"
        self.assertEqual(self.report("--only", "packages")["tasks"][0]["status"], "skipped")

    def test_retention_and_tmpfiles_use_native_policies(self):
        self.as_root()
        self.native("journalctl")
        self.native("systemd-tmpfiles")
        report = self.report("--only", "journal,temp,coredumps", "--keep-days", "30", "--apply", "--yes")
        self.assertEqual(report["summary"]["completed"], 3)
        self.assertEqual(self.calls(), [
            ["journalctl", "--vacuum-time=30d"],
            ["systemd-tmpfiles", "--clean", "--prefix=/tmp", "--prefix=/var/tmp"],
            ["systemd-tmpfiles", "--clean", "--prefix=/var/lib/systemd/coredump"],
        ])

    def test_duplicate_task_is_not_executed_twice(self):
        self.as_root()
        self.native("apt-get")
        report = self.report("--only", "packages,packages", "--apply", "--yes")
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(len(report["tasks"]), 1)

    def test_docker_requires_opt_in_and_refuses_remote_contexts(self):
        self.native("docker")
        self.assertNotIn("docker", [task["id"] for task in self.report()["tasks"]])
        self.assertEqual(self.calls(), [])
        self.env["DOCKER_HOST"] = "ssh://production.example"
        report = self.report("--only", "docker", "--apply", "--yes")
        self.assertEqual(report["tasks"][0]["status"], "skipped")
        self.assertEqual(self.calls(), [])

    def test_local_docker_only_prunes_build_cache(self):
        self.env["DOCKER_HOST"] = "unix:///var/run/docker.sock"
        self.native("docker")
        report = self.report("--only", "docker", "--keep-days", "7", "--apply", "--yes")
        self.assertEqual(report["summary"]["completed"], 1)
        self.assertEqual(self.calls(), [["docker", "builder", "prune", "--force", "--filter", "until=168h"]])

    def test_docker_context_overrides_docker_host(self):
        self.env["DOCKER_HOST"] = "unix:///var/run/docker.sock"
        self.env["DOCKER_CONTEXT"] = "remote"
        self.command("docker", "printf 'tcp://remote.example:2376\\n'")
        report = self.report("--only", "docker")
        self.assertEqual(report["tasks"][0]["status"], "skipped")

    def test_history_only_unlinks_saved_files_and_handles_spaces(self):
        paths = [self.home / ".bash_history", self.home / ".zsh_history"]
        for path in paths:
            path.write_text("history\n")
        keep = self.home / "notes"
        keep.write_text("keep me")
        self.report("--only", "history")
        self.assertTrue(all(path.exists() for path in paths))
        report = self.report("--only", "history", "--apply", "--yes")
        self.assertEqual(report["summary"]["completed"], 1)
        self.assertTrue(all(not path.exists() for path in paths))
        self.assertEqual(keep.read_text(), "keep me")

    def test_history_symlink_is_rejected_and_target_survives(self):
        target = self.root / "important"
        target.write_text("unchanged")
        history = self.home / ".bash_history"
        history.symlink_to(target)
        report = self.report("--only", "history", "--apply", "--yes", code=1)
        self.assertEqual(report["summary"]["failed"], 1)
        self.assertEqual(target.read_text(), "unchanged")
        self.assertTrue(history.is_symlink())

    def test_history_parent_symlink_is_rejected(self):
        outside = self.root / "outside"
        (outside / "fish").mkdir(parents=True)
        (outside / "fish" / "fish_history").write_text("keep")
        (self.home / ".local").mkdir()
        (self.home / ".local" / "share").symlink_to(outside, target_is_directory=True)
        self.report("--only", "history", "--apply", "--yes", code=1)
        self.assertEqual((outside / "fish" / "fish_history").read_text(), "keep")

    def test_shared_history_path_is_rejected(self):
        history = self.home / ".bash_history"
        history.write_text("keep")
        history.chmod(0o666)
        self.report("--only", "history", "--apply", "--yes", code=1)
        self.assertTrue(history.exists())

    def test_hardlinked_history_does_not_truncate_other_link(self):
        target = self.root / "important"
        target.write_text("unchanged")
        os.link(target, self.home / ".bash_history")
        self.report("--only", "history", "--apply", "--yes")
        self.assertEqual(target.read_text(), "unchanged")

    def test_json_escapes_paths_and_reports_real_disk_fields(self):
        odd_home = self.root / 'home "quoted"\tline\nend'
        odd_home.mkdir(mode=0o700)
        (odd_home / ".bash_history").write_text("saved")
        self.env["HOME"] = str(odd_home)
        report = self.report("--only", "history")
        self.assertIn(str(odd_home / ".bash_history"), report["tasks"][0]["command"])
        self.assertEqual(report["disk"]["before"]["available_kib"], 60000)
        self.env["DF_FAIL"] = "1"
        self.assertIsNone(self.report("--only", "history")["disk"]["before"])

    def test_active_lock_blocks_mutation(self):
        self.as_root()
        self.native("apt-get")
        lock = self.state / "server-cleaner" / "lock"
        lock.mkdir(parents=True, mode=0o700)
        (lock / "pid").write_text(str(os.getpid()))
        result = self.run_script("clean.sh", "--only", "packages", "--apply", "--yes")
        self.assertEqual(result.returncode, 75, result.stderr)
        self.assertEqual(self.calls(), [])
        self.assertTrue(lock.exists())

    def test_termination_releases_own_lock(self):
        self.as_root()
        self.command("apt-get", 'printf "started\\n" > "$CALL_LOG"; sleep 30')
        process = subprocess.Popen(
            [SHELL, str(REPO / "clean.sh"), "--only", "packages", "--apply", "--yes"],
            cwd=self.root, env=self.env, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True,
        )
        try:
            deadline = time.monotonic() + 10
            while not self.call_log.exists() and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue(self.call_log.exists(), "native task did not start")
            os.killpg(process.pid, signal.SIGTERM)
            process.communicate(timeout=5)
            self.assertEqual(process.returncode, 143)
            self.assertFalse((self.state / "server-cleaner" / "lock").exists())
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate(timeout=5)
