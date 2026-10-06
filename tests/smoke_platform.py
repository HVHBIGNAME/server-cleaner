"""Exercise the real package-cache adapter only inside disposable CI machines."""

import argparse
import json
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expect-manager", required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    command = ["/bin/sh", str(Path(__file__).resolve().parents[1] / "clean.sh"), "--only", "packages", "--json"]
    if args.apply:
        command.extend(["--apply", "--yes"])
    result = subprocess.run(command, text=True, capture_output=True, check=False, timeout=120)
    print(result.stdout)
    print(result.stderr)
    if result.returncode:
        raise SystemExit(result.returncode)
    report = json.loads(result.stdout)
    if report["package_manager"] not in args.expect_manager.split(","):
        raise SystemExit(f"Wrong adapter: {report['package_manager']}; expected {args.expect_manager}")
    if args.apply and report["summary"]["completed"] != 1:
        raise SystemExit("The native package-cache task did not complete")


if __name__ == "__main__":
    main()
