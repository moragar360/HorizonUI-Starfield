#!/usr/bin/env python3
"""Fail when Horizon text embeds a face this movie does not prove it exports.

The stock spaceship editor bakes glyphs into timeline fields. It does not
export the mapped $ faces. A new TextField with embedFonts set on one of
those names draws missing-glyph boxes, while the timeline text still reads.
HorizonShipBuilder.movieExports asks Font.enumerateFonts(false) before it
accepts an embedded face. This gate fails if that check is missing.

Usage:
  python3 shipbuilder/font_export_gate.py
  python3 shipbuilder/font_export_gate.py --script <file or ffdec export dir>
  python3 shipbuilder/font_export_gate.py --dom <DOMDocument.xml>
"""

import argparse
import sys
from pathlib import Path

MARKERS = (
    "function movieExports(",
    "Font.enumerateFonts(false)",
    "exported.push(this.movieExports(faceName))",
    "var ok:Boolean = measured && allowed",
)
FACES = ("$NB_Grotesk_Semibold", "$MAIN_Font_Bold", "$MAIN_Font")


def find_script(path: Path) -> Path:
    if path.is_file():
        return path
    matches = sorted(path.rglob("HorizonShipBuilder.as"))
    if len(matches) != 1:
        names = ", ".join(str(item) for item in matches) or "(none)"
        raise SystemExit(f"expected one HorizonShipBuilder.as under {path}, found {names}")
    return matches[0]


def check_script(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    missing = [mark for mark in MARKERS if mark not in text]
    if missing:
        joined = "; ".join(missing)
        raise SystemExit(
            f"{path} embeds mapped faces without the export check. Missing: {joined}"
        )
    if "enumerateFonts(true)" in text:
        raise SystemExit(f"{path} asks for device fonts while proving an embedded face")


def linkage_count(dom: str) -> int:
    count = 0
    for face in FACES:
        token = f'linkageClassName="{face}"'
        if token in dom:
            count += 1
    return count


def main() -> int:
    here = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--script", type=Path, default=here / "actionscript" / "HorizonShipBuilder.as")
    parser.add_argument("--dom", type=Path)
    args = parser.parse_args()
    script = find_script(args.script)
    check_script(script)
    if args.dom is not None:
        dom = args.dom.read_text(encoding="utf-8")
        found = linkage_count(dom)
        print(f"mapped faces with linkageClassName in DOM: {found}")
        if found == 0 and "function movieExports(" not in script.read_text(encoding="utf-8"):
            raise SystemExit(
                "stock movie does not export the mapped faces and the movie still embeds them"
            )
    print(f"font export gate passed ({script})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
