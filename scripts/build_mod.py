#!/usr/bin/env python3
"""Package the Factorio mod into a versioned .zip archive.

The archive will be saved to the ``dist`` directory in the repository root
using the ``<name>_<version>.zip`` naming convention required by the game.
"""
from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent

    info_candidates = []
    root_info = repo_root / "info.json"
    if root_info.exists():
        info_candidates.append(root_info)

    info_candidates.extend(
        candidate
        for candidate in repo_root.glob("*/info.json")
        if candidate.is_file()
    )

    if not info_candidates:
        raise SystemExit("Could not locate info.json in the repository")

    # If multiple info.json files exist we require the project to disambiguate.
    if len(info_candidates) > 1:
        raise SystemExit(
            "Multiple info.json files found; remove the extras to continue"
        )

    info_path = info_candidates[0]
    mod_root = info_path.parent

    with info_path.open("r", encoding="utf-8") as fp:
        info = json.load(fp)

    mod_name = info.get("name")
    mod_version = info.get("version")
    if not mod_name or not mod_version:
        raise SystemExit("info.json must define both 'name' and 'version'")

    if mod_root.name != mod_name:
        raise SystemExit(
            f"The mod directory should be named '{mod_name}', not '{mod_root.name}'"
        )

    package_name = f"{mod_name}_{mod_version}"
    folder_name = mod_name
    dist_dir = repo_root / "dist"
    dist_dir.mkdir(exist_ok=True)
    output_zip = dist_dir / f"{package_name}.zip"

    excluded = {
        ".git",
        "__pycache__",
        ".pytest_cache",
        ".mypy_cache",
    }

    with tempfile.TemporaryDirectory() as tmpdir:
        staging_root = Path(tmpdir) / folder_name
        shutil.copytree(
            mod_root,
            staging_root,
            ignore=shutil.ignore_patterns(*excluded, "*.zip"),
        )

        shutil.make_archive(
            output_zip.with_suffix("").as_posix(), "zip", tmpdir, folder_name
        )

    print(f"Created {output_zip.relative_to(repo_root)}")


if __name__ == "__main__":
    main()
