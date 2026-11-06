#!/usr/bin/env python3
"""Publish only a validated supporter feed to an independent data branch."""

import argparse
import base64
from datetime import date
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from sync_patreon_supporters import SyncError, avatar_url, feed_bytes, supporter_sort_key


BRANCH = "patreon-data"


def publish(feed, remote, environment=None):
    payload = feed.read_bytes()
    try:
        document = json.loads(payload)
        supporters = document["supporters"]
        if set(document) != {"version", "supporters"}:
            raise ValueError
        if type(document["version"]) is not int or document["version"] != 1 or not isinstance(supporters, list):
            raise ValueError
        for item in supporters:
            if (not isinstance(item, dict) or set(item) != {"name", "avatar_url", "since"}
                    or not isinstance(item["name"], str) or not item["name"].strip()
                    or item["name"] != item["name"].strip()
                    or (item["avatar_url"] is not None and avatar_url(item["avatar_url"]) is None)
                    or (item["since"] is not None and
                        (not isinstance(item["since"], str) or date.fromisoformat(item["since"]).isoformat() != item["since"]))):
                raise ValueError
        if (supporters != sorted(supporters, key=supporter_sort_key)
                or len({(s["name"], s["avatar_url"], s["since"]) for s in supporters}) != len(supporters)
                or payload != feed_bytes(supporters)):
            raise ValueError
    except (KeyError, TypeError, ValueError):
        raise SyncError("Refusing to publish an invalid or noncanonical supporter feed.") from None
    with tempfile.TemporaryDirectory(prefix="itorrent-supporters-") as directory:
        def git(*args, allowed=(0,)):
            result = subprocess.run(["git", *args], cwd=directory, env=environment,
                                    capture_output=True, text=True, timeout=120)
            if result.returncode not in allowed:
                raise SyncError(f"Git {args[0]} failed; the data branch was not overwritten.")
            return result

        git("init", "--quiet", f"--initial-branch={BRANCH}")
        git("remote", "add", "origin", remote)
        exists = git("ls-remote", "--exit-code", "--heads", "origin", f"refs/heads/{BRANCH}", allowed=(0, 2)).returncode == 0
        if exists:
            git("fetch", "--quiet", "--depth=1", "origin", f"refs/heads/{BRANCH}")
            git("checkout", "--quiet", "-B", BRANCH, "FETCH_HEAD")
            if set(git("ls-files").stdout.splitlines()) != {"supporters.json"}:
                raise SyncError("Data branch must contain only supporters.json; refusing to modify other files.")
            if Path(directory, "supporters.json").is_symlink():
                raise SyncError("Refusing to publish over a symbolic link.")
            if Path(directory, "supporters.json").read_bytes() == payload:
                return False
        Path(directory, "supporters.json").write_bytes(payload)
        git("add", "--", "supporters.json")
        git("-c", "user.name=github-actions[bot]", "-c", "user.email=41898282+github-actions[bot]@users.noreply.github.com",
            "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "Update Patreon supporters")
        git("push", "--quiet", "origin", f"HEAD:refs/heads/{BRANCH}")
        return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("feed", type=Path)
    args = parser.parse_args()
    try:
        repository = os.environ.get("GITHUB_REPOSITORY", "")
        token = os.environ.get("GITHUB_TOKEN", "")
        if not re.fullmatch(r"[\w.-]+/[\w.-]+", repository) or not token:
            raise SyncError("GITHUB_REPOSITORY and GITHUB_TOKEN are required for publishing.")
        authorization = base64.b64encode(f"x-access-token:{token}".encode()).decode()
        environment = dict(os.environ, GIT_TERMINAL_PROMPT="0", GIT_CONFIG_COUNT="1",
                           GIT_CONFIG_KEY_0="http.https://github.com/.extraheader",
                           GIT_CONFIG_VALUE_0=f"AUTHORIZATION: basic {authorization}")
        changed = publish(args.feed, f"https://github.com/{repository}.git", environment)
        print("Published updated supporter feed." if changed else "Supporter feed unchanged; no commit needed.")
    except (SyncError, OSError, subprocess.TimeoutExpired) as error:
        print(str(error) if isinstance(error, SyncError) else "Publishing failed.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
