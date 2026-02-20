#!/usr/bin/env python3

import json
import sys
from pathlib import Path


LOCALIZATIONS = ("en", "zh-Hant")
XCSTRINGS_PATH = Path("app/dauphin/Localizable.xcstrings")


def read_catalog(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"ERROR: localization catalog not found: {path}")
        sys.exit(1)
    except json.JSONDecodeError as error:
        print(f"ERROR: invalid JSON in {path}: {error}")
        sys.exit(1)


def missing_value(entry: dict, locale: str) -> bool:
    localizations = entry.get("localizations")
    if not isinstance(localizations, dict):
        return True

    locale_entry = localizations.get(locale)
    if not isinstance(locale_entry, dict):
        return True

    string_unit = locale_entry.get("stringUnit")
    if not isinstance(string_unit, dict):
        return True

    value = string_unit.get("value")
    return not isinstance(value, str) or not value.strip()


def main() -> int:
    catalog = read_catalog(XCSTRINGS_PATH)
    if not isinstance(catalog, dict):
        print("ERROR: localization catalog root must be a JSON object")
        return 1

    strings = catalog.get("strings")
    if not isinstance(strings, dict):
        print("ERROR: missing or invalid `strings` object in Localizable.xcstrings")
        return 1

    missing_by_locale = {locale: [] for locale in LOCALIZATIONS}
    stale_keys = []

    for key, entry in strings.items():
        if not isinstance(entry, dict):
            continue

        if entry.get("extractionState") == "stale":
            stale_keys.append(key)

        for locale in LOCALIZATIONS:
            if missing_value(entry, locale):
                missing_by_locale[locale].append(key)

    has_error = False

    for locale in LOCALIZATIONS:
        missing_keys = sorted(missing_by_locale[locale])
        if missing_keys:
            has_error = True
            print(f"ERROR: missing `{locale}` localization values:")
            for key in missing_keys:
                print(f"  - {key}")

    if stale_keys:
        has_error = True
        print("ERROR: stale localization keys present:")
        for key in sorted(stale_keys):
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
