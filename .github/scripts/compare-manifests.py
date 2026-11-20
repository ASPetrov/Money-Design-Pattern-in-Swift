"""Check that both SwiftPM entry points describe the same package."""

import argparse
import difflib
import json
from pathlib import Path
import subprocess


def normalized_manifest(directory):
    directory = directory.resolve()
    output = subprocess.check_output(
        ["swift", "package", "--package-path", str(directory), "dump-package"],
        text=True,
    )
    manifest = json.loads(output)

    root = manifest["packageKind"]["root"]
    manifest["packageKind"]["root"] = [
        "." if Path(path).resolve() == directory else path for path in root
    ]
    for target in manifest["targets"]:
        if "path" in target:
            target["path"] = str((directory / target["path"]).resolve())

    return json.dumps(manifest, indent=2, sort_keys=True).splitlines()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("nested", type=Path)
    args = parser.parse_args()

    root_manifest = normalized_manifest(args.root)
    nested_manifest = normalized_manifest(args.nested)
    if root_manifest == nested_manifest:
        print("Swift package manifests agree.")
        return 0

    print("Swift package manifests differ:")
    print("\n".join(difflib.unified_diff(
        root_manifest,
        nested_manifest,
        fromfile=str(args.root / "Package.swift"),
        tofile=str(args.nested / "Package.swift"),
        lineterm="",
    )))
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
