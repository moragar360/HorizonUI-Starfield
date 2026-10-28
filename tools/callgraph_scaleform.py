#!/usr/bin/env python3
"""Scaleform call-graph for src/main.cpp.

FINDINGS (0.43.0.3) listed 21 Scaleform-touching functions, all reachable
only from Poll() on a BSJobs worker. This script rebuilds that graph after
the 0.43.0.4 split: Poll() must not reach any Scaleform site; PollScaleform()
is the UI-thread root.

Author: Moragar
Last modified: 2026-10-28
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

SF_RE = re.compile(
    r"\bGetMenu\s*\(|->menuObj|\.menuObj|\.Invoke\s*\(|->Invoke\s*\("
    r"|GetMember\s*\(|SetMember\s*\(|asMovieRoot"
    r"|HudInvoke\s*\(|MenuLive\s*\(|MenuMovie\s*\(|HudSafe\s*\("
)
FN_RE = re.compile(
    r"^\t(?:static\s+)?(?:inline\s+)?"
    r"(?:void|bool|int|double|float|std::string|const std::string&|"
    r"RE::Scaleform::Ptr<RE::IMenu>|std::string_view)\s+"
    r"(\w+)\s*\("
)
SKIP_ROOTS = {"Poll", "FilesPollWork", "BannerPollWork", "MsglogPoll"}


def strip_line(line: str) -> str:
    if "//" in line:
        line = line[: line.index("//")]
    return line


def parse_functions(src: str) -> dict[str, str]:
    lines = src.splitlines()
    fns: dict[str, str] = {}
    i = 0
    while i < len(lines):
        m = FN_RE.match(lines[i])
        if not m:
            i += 1
            continue
        name = m.group(1)
        header = lines[i]
        j = i
        while j + 1 < len(lines) and "{" not in header and ";" not in header:
            j += 1
            header += "\n" + lines[j]
        if ";" in header and ("{" not in header or header.index(";") < header.index("{")):
            i += 1
            continue
        body_lines = [lines[i]]
        depth = lines[i].count("{") - lines[i].count("}")
        i += 1
        while i < len(lines) and (depth > 0 or "{" not in "".join(body_lines)):
            body_lines.append(lines[i])
            depth += lines[i].count("{") - lines[i].count("}")
            i += 1
            if depth == 0 and "{" in "".join(body_lines):
                break
        fns[name] = "\n".join(body_lines)
    return fns


def scaleform_fns(fns: dict[str, str]) -> list[str]:
    out = []
    for name, body in fns.items():
        text = "\n".join(strip_line(ln) for ln in body.splitlines())
        if SF_RE.search(text):
            out.append(name)
    return out


def callers_of(fns: dict[str, str]) -> dict[str, set[str]]:
    names = sorted(fns, key=len, reverse=True)
    calls: dict[str, set[str]] = {n: set() for n in fns}
    for caller, body in fns.items():
        text = "\n".join(strip_line(ln) for ln in body.splitlines())
        for callee in names:
            if callee == caller:
                continue
            if re.search(r"\b" + re.escape(callee) + r"\s*\(", text):
                calls[caller].add(callee)
    return calls


def reachable(root: str, calls: dict[str, set[str]]) -> set[str]:
    seen = set()
    stack = [root]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(calls.get(cur, ()))
    return seen


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    src = (root / "src" / "main.cpp").read_text(encoding="utf-8", errors="replace")
    fns = parse_functions(src)
    if "Poll" not in fns or "PollScaleform" not in fns:
        print("FAIL: Poll / PollScaleform not found", file=sys.stderr)
        return 1
    sf = scaleform_fns(fns)
    calls = callers_of(fns)
    from_poll = reachable("Poll", calls)
    from_ui = reachable("PollScaleform", calls)
    leaked = sorted(name for name in sf if name in from_poll and name not in SKIP_ROOTS)
    print("Scaleform-touching functions:")
    for name in sf:
        thread = "UI" if name in from_ui or name in {
            "HookedAdvanceFrame",
            "InstallAdvanceHook",
            "OnMenuMovie",
            "MenuMovie",
            "MenuLive",
            "HzNoteScaleformThread",
        } else ("JOB-LEAK" if name in from_poll else "other")
        print(f"  {name:24} {thread}")
    print(f"Poll() reaches: {', '.join(sorted(from_poll))}")
    print(f"PollScaleform() reaches: {', '.join(sorted(from_ui))}")
    if leaked:
        print("FAIL: Scaleform reachable from Poll(): " + ", ".join(leaked), file=sys.stderr)
        return 1
    needed = {"HudInvoke", "HudSafe", "MsglogTakeMovie", "MsglogPollUi", "BannerPoll", "CommsRxPoll"}
    missing = sorted(n for n in needed if n not in from_ui)
    if missing:
        print("FAIL: PollScaleform does not reach " + ", ".join(missing), file=sys.stderr)
        return 1
    poll_body = "\n".join(strip_line(ln) for ln in fns["Poll"].splitlines())
    for token in ("GetMenu", "menuObj", "Invoke(", "HudSafe", "HudInvoke", "MsglogTakeMovie"):
        if token in poll_body:
            print(f"FAIL: Poll() body still mentions {token}", file=sys.stderr)
            return 1
    print("OK: no Scaleform call is reachable from Poll()")
    return 0


if __name__ == "__main__":
    sys.exit(main())
