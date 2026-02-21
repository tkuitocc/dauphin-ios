#!/usr/bin/env python3

import argparse
import os
import re
import subprocess
import sys


DESTINATION_PATTERN = re.compile(
    r"\{ platform:iOS Simulator, id:([^,}]+), OS:([^,}]+), name:([^}]+) \}"
)


def select_destination(project: str, scheme: str) -> tuple[str, str, str]:
    command = [
        "xcodebuild",
        "-project",
        project,
        "-scheme",
        scheme,
        "-showdestinations",
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    output = f"{result.stdout}\n{result.stderr}"

    for match in DESTINATION_PATTERN.finditer(output):
        destination_id = match.group(1).strip()
        destination_os = match.group(2).strip()
        destination_name = match.group(3).strip()
        if "placeholder" in destination_id:
            continue
        return destination_id, destination_os, destination_name

    print(output)
    raise RuntimeError("No compatible iOS Simulator destination found")


def write_env(
    github_env: str, destination_id: str, destination_os: str, destination_name: str
) -> None:
    with open(github_env, "a", encoding="utf-8") as env_file:
        env_file.write(f"SIMULATOR_DESTINATION_ID={destination_id}\n")
        env_file.write(f"SIMULATOR_DESTINATION_OS={destination_os}\n")
        env_file.write(f"SIMULATOR_DESTINATION_NAME={destination_name}\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--scheme", required=True)
    parser.add_argument("--github-env", default=os.environ.get("GITHUB_ENV"))
    args = parser.parse_args()

    if not args.github_env:
        print("GITHUB_ENV is not set; pass --github-env explicitly", file=sys.stderr)
        return 1

    try:
        destination_id, destination_os, destination_name = select_destination(
            args.project, args.scheme
        )
    except RuntimeError as error:
        print(str(error), file=sys.stderr)
        return 1

    write_env(args.github_env, destination_id, destination_os, destination_name)
    print(
        f"Selected destination: {destination_name} ({destination_os}) [{destination_id}]"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
