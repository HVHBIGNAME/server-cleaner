"""Private process fixtures. Real package managers and the host crontab are unreachable."""

import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SHELL = os.environ.get("SHELL_UNDER_TEST", "/bin/sh")
RUNTIME_FILES = ("server-cleaner.sh",)


class ShellTestCase(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="server-cleaner-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.bin = self.root / "commands"
        self.home = self.root / "home"
        self.state = self.home / ".local" / "state"
        self.prefix = self.root / "install space"
        self.call_log = self.root / "commands.log"
        self.cron_store = self.root / "crontab"
        self.bin.mkdir()
        self.home.mkdir(mode=0o700)
        for name in (
            "awk", "tr", "stat", "rm", "mkdir", "rmdir", "chmod", "cp", "mv",
            "mktemp", "grep", "sed", "cat", "dirname", "env", "sleep",
            "sha256sum", "shasum", "sha256",
        ):
            executable = shutil.which(name)
            if executable:
                (self.bin / name).symlink_to(executable)
        (self.bin / "sh").symlink_to(SHELL)
        self.env = {
            "PATH": str(self.bin),
            "HOME": str(self.home),
            "XDG_STATE_HOME": str(self.state),
            "TMPDIR": str(self.root),
            "LC_ALL": "C",
            "TERM": "dumb",
            "CALL_LOG": str(self.call_log),
            "CRON_STORE": str(self.cron_store),
            "TEST_OS": "Linux",
            "TEST_UID": str(os.geteuid()),
            "REAL_STAT": shutil.which("stat"),
        }
        self.command("uname", 'printf "%s\\n" "$TEST_OS"')
        self.command("id", 'printf "%s\\n" "$TEST_UID"')
        self.command("df", '''
if [ "${DF_FAIL:-0}" = 1 ]; then exit 1; fi
printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
printf 'disk 100000 40000 60000 40%% /\n'
''')
        (self.bin / "stat").unlink()
        self.command("stat", '''
metadata=$("$REAL_STAT" "$@") || exit $?
if [ -n "${STAT_OWNER_OVERRIDE:-}" ]; then
    printf '%s %s\n' "$STAT_OWNER_OVERRIDE" "${metadata#* }"
else
    printf '%s\n' "$metadata"
fi
''')

    def command(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body.strip() + "\n", encoding="utf-8")
        path.chmod(0o755)
        return path

    def native(self, name, exit_code=0):
        return self.command(name, f'''
printf '%s' '{name}' >> "$CALL_LOG"
for arg do printf '\\t%s' "$arg" >> "$CALL_LOG"; done
printf '\\n' >> "$CALL_LOG"
printf '%s\\n' 'native output: {name}'
exit {exit_code}
''')

    def as_root(self):
        self.env["TEST_UID"] = "0"
        self.env["STAT_OWNER_OVERRIDE"] = "0"

    def cron(self):
        self.command("crontab", '''
if [ "$1" = -l ]; then
    if [ -n "${CRON_ERROR:-}" ]; then printf '%s\n' "$CRON_ERROR" >&2; exit 2; fi
    if [ -f "$CRON_STORE" ]; then cat "$CRON_STORE"; else
        printf 'no crontab for test\n' >&2
        exit 1
    fi
elif [ "${CRON_WRITE_FAIL:-0}" = 1 ]; then
    printf 'crontab write failed\n' >&2
    exit 1
else
    cp "$1" "$CRON_STORE"
fi
''')

    def run_script(self, script="server-cleaner.sh", *args, input_text=None, timeout=20):
        path = Path(script)
        if not path.is_absolute():
            path = REPO / path
        command = [str(path)] if path == self.bin / "sh" else [SHELL, str(path)]
        return subprocess.run(
            [*command, *map(str, args)],
            cwd=self.root,
            env=self.env,
            input=input_text,
            stdin=subprocess.DEVNULL if input_text is None else None,
            capture_output=True,
            text=True,
            encoding="utf-8",
            start_new_session=True,
            timeout=timeout,
            check=False,
        )

    def calls(self):
        if not self.call_log.exists():
            return []
        return [line.split("\t") for line in self.call_log.read_text().splitlines()]

    def bundle(self):
        source = self.root / "source"
        source.mkdir()
        for name in RUNTIME_FILES:
            shutil.copyfile(REPO / name, source / name)
        self.write_checksums(source)
        return source

    @staticmethod
    def write_checksums(source):
        lines = []
        for name in RUNTIME_FILES:
            digest = hashlib.sha256((source / name).read_bytes()).hexdigest()
            lines.append(f"{digest}  {name}\n")
        (source / "SHA256SUMS").write_text("".join(lines), encoding="ascii")

    def install(self, *args, source=None):
        if source is None:
            source = self.bundle()
        return self.run_script("server-cleaner.sh", "--install", "--from", source, "--prefix", self.prefix, *args)
