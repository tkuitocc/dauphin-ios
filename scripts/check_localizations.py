#!/usr/bin/env python3

import json
import sys
from pathlib import Path


LOCALIZATIONS = ("en", "zh-Hant")
XCSTRINGS_PATH = Path("app/dauphin/Localizable.xcstrings")


def read_catalog(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"ERROR: localization catalog not found: {path}")
        sys.exit(1)
    except json.JSONDecodeError as error:
        print(f"ERROR: invalid JSON in {path}: {error}")
        sys.exit(1)


def missing_value(entry: dict, locale: str) -> bool:
    localizations = entry.get("localizations", {})
    locale_entry = localizations.get(locale, {})
    string_unit = locale_entry.get("stringUnit", {})
    value = string_unit.get("value")
    return not isinstance(value, str) or not value.strip()


def main() -> int:
    catalog = read_catalog(XCSTRINGS_PATH)
    strings = catalog.get("strings")
    if not isinstance(strings, dict):
        print("ERROR: missing or invalid `strings` object in Localizable.xcstrings")
        return 1

    missing_en = []
    missing_zh_hant = []
    stale_keys = []

    for key, entry in strings.items():
        if not isinstance(entry, dict):
            continue

        if entry.get("extractionState") == "stale":
            stale_keys.append(key)

        if missing_value(entry, "en"):
            missing_en.append(key)
        if missing_value(entry, "zh-Hant"):
            missing_zh_hant.append(key)

    has_error = False

    if missing_en:
        has_error = True
        print("ERROR: missing `en` localization values:")
        for key in missing_en:
            print(f"  - {key}")

    if missing_zh_hant:
        has_error = True
        print("ERROR: missing `zh-Hant` localization values:")
        for key in missing_zh_hant:
            print(f"  - {key}")

    if stale_keys:
        has_error = True
        print("ERROR: stale localization keys present:")
        for key in stale_keys:
            print(f"  - {key}")

    if has_error:
        print(
            "\nLocalization check failed. Fill both locales and remove stale keys in "
            "app/dauphin/Localizable.xcstrings."
        )
        return 1

    print("Localization check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
