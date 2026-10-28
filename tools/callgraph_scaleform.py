#!/usr/bin/env python3
"""Scaleform and UI-path file-I/O call-graph for every file under src/.

Poll() (job thread) must not reach any Scaleform site. PollScaleform()
(HUDMenu) and PollMessages() (HUDMessagesMenu) are the UI-thread roots
and must not reach file I/O (ifstream, filesystem
exists/copy/create/rename/remove, CreateFile, LoadLibrary,
GetFileVersionInfo, HzAddrLoad, ReadOwnFileVersion).
A poll root's reachable set must not name another movie's Invoke
literal. PollScaleform / PollMessages bodies must not sample
GetAsyncKeyState (F11 lives on the job latch).

Call-graph nodes come from every src file so a Scaleform or I/O token
in a new .cpp/.h is visible. File I/O on the UI path is decided from
.cpp function bodies only: header methods named Load/Save share those
identifiers with the coordinator, so treating them as callees would
false-fail. A .cpp UI function that names HzAddrLoad or
ReadOwnFileVersion still fails.

No root is exempt from the Scaleform leak check unless it is listed in
SKIP_ROOTS with a reason. That table is empty on purpose: a Scaleform
call inside Poll / FilesPollWork / BannerPollWork / MsglogPoll must fail.

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
IO_RE = re.compile(
    r"\b(?:std::)?ifstream\b|\b(?:std::)?ofstream\b|"
    r"std::filesystem::(?:exists|copy|create|rename|remove|file_size)|"
    r"\bCreateFile(?:W|A)?\b|\bLoadLibrary(?:Ex)?(?:W|A)?\b|"
    r"\bGetFileVersionInfo(?:Size)?W\b|"
    r"\bHzAddrLoad\s*\(|\bReadOwnFileVersion\s*\("
)
CONTROL = {
    "if",
    "for",
    "while",
    "switch",
    "catch",
    "else",
    "return",
    "sizeof",
    "sizeof...",
    "static_assert",
}
FN_RE = re.compile(
    r"^[ \t]*(?:static\s+|inline\s+|constexpr\s+|virtual\s+)*"
    r"(?!if\b|for\b|while\b|switch\b|catch\b|else\b|return\b)"
    r"([\w:<>*&,\s]+?)\s+(\w+)\s*\("
)

# Empty: do not hide Scaleform inside job roots. Add a row only with a
# listed reason if a future root is a documented false positive.
SKIP_ROOTS: dict[str, str] = {}


def strip_line(line: str) -> str:
    if "//" in line:
        line = line[: line.index("//")]
    return line


def parse_functions(src: str) -> dict[str, str]:
    lines = src.splitlines()
    fns: dict[str, str] = {}
    i = 0
    while i < len(lines):
        raw = lines[i]
        if raw.lstrip().startswith(("//", "*", "/*", "#")):
            i += 1
            continue
        m = FN_RE.match(raw)
        if not m:
            i += 1
            continue
        name = m.group(2)
        if name in CONTROL:
            i += 1
            continue
        header = raw
        j = i
        while j + 1 < len(lines) and "{" not in header and ";" not in header:
            j += 1
            header += "\n" + lines[j]
        if ";" in header and ("{" not in header or header.index(";") < header.index("{")):
            i += 1
            continue
        if "{" not in header:
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


def parse_src(root: Path) -> tuple[dict[str, str], dict[str, str], dict[str, Path]]:
    fns: dict[str, str] = {}
    cpp_fns: dict[str, str] = {}
    where: dict[str, Path] = {}
    src_dir = root / "src"
    for path in sorted(src_dir.rglob("*")):
        if path.suffix not in {".cpp", ".h", ".hpp"}:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        parsed = parse_functions(text)
        fns.update(parsed)
        for name in parsed:
            where[name] = path
        if path.suffix == ".cpp":
            cpp_fns.update(parsed)
    return fns, cpp_fns, where


def matching_fns(fns: dict[str, str], pat: re.Pattern[str]) -> list[str]:
    out = []
    for name, body in fns.items():
        text = "\n".join(strip_line(ln) for ln in body.splitlines())
        if pat.search(text):
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
    fns, cpp_fns, _where = parse_src(root)
    if "Poll" not in cpp_fns or "PollScaleform" not in cpp_fns or "PollMessages" not in cpp_fns:
        print("FAIL: Poll / PollScaleform / PollMessages not found in src/*.cpp", file=sys.stderr)
        return 1
    sf = matching_fns(fns, SF_RE)
    io_cpp = matching_fns(cpp_fns, IO_RE)
    cpp_calls = callers_of(cpp_fns)
    from_poll = reachable("Poll", cpp_calls)
    from_hud = reachable("PollScaleform", cpp_calls)
    from_msg = reachable("PollMessages", cpp_calls)
    from_ui = from_hud | from_msg
    leaked = sorted(name for name in sf if name in from_poll and name not in SKIP_ROOTS)
    print("Scaleform-touching functions:")
    for name in sf:
        thread = (
            "UI"
            if name in from_ui
            or name
            in {
                "HookedAdvanceFrame",
                "InstallAdvanceHook",
                "OnMenuMovie",
                "MenuMovie",
                "MenuLive",
                "HzNoteScaleformThread",
            }
            else ("JOB-LEAK" if name in from_poll else "other")
        )
        print(f"  {name:24} {thread}")
    print(f"Poll() reaches: {', '.join(sorted(from_poll))}")
    print(f"PollScaleform() reaches: {', '.join(sorted(from_hud))}")
    print(f"PollMessages() reaches: {', '.join(sorted(from_msg))}")
    print(f"file-I/O .cpp functions: {', '.join(sorted(io_cpp))}")
    if leaked:
        print("FAIL: Scaleform reachable from Poll(): " + ", ".join(leaked), file=sys.stderr)
        return 1
    needed_hud = {"HudInvoke", "HudSafe", "MsglogPollUi"}
    needed_msg = {"MsglogTakeMovie", "BannerPoll", "CommsRxPoll"}
    missing = sorted(n for n in needed_hud if n not in from_hud) + sorted(
        n for n in needed_msg if n not in from_msg
    )
    if missing:
        print("FAIL: movie polls do not reach " + ", ".join(missing), file=sys.stderr)
        return 1
    poll_body = "\n".join(strip_line(ln) for ln in cpp_fns["Poll"].splitlines())
    for token in ("GetMenu", "menuObj", "Invoke(", "HudSafe", "HudInvoke", "MsglogTakeMovie"):
        if token in poll_body:
            print(f"FAIL: Poll() body still mentions {token}", file=sys.stderr)
            return 1
    def reach_text(names: set[str]) -> str:
        parts = []
        for name in sorted(names):
            if name in cpp_fns:
                parts.append("\n".join(strip_line(ln) for ln in cpp_fns[name].splitlines()))
        return "\n".join(parts)

    hud_text = reach_text(from_hud)
    msg_text = reach_text(from_msg)
    scope_text = reach_text(reachable("ScopeClipPoll", cpp_calls)) if "ScopeClipPoll" in cpp_fns else ""
    hud_foreign = [
        t
        for t in (
            'MenuLive(ui, "HUDMessagesMenu"',
            'MenuMovie(ui, "HUDMessagesMenu"',
            'MenuLive(a_ui, "HUDMessagesMenu"',
            'MenuLive(ui, "ScopeMenu"',
            "hzcTakeLog",
            "hzcCardPush",
            'Invoke("hzcDllScan"',
            'HasMember("hzcDllScan"',
        )
        if t in hud_text
    ]
    msg_foreign = [
        t
        for t in (
            'MenuLive(ui, "HUDMenu"',
            'MenuMovie(ui, "HUDMenu"',
            "HudInvoke(",
            'Invoke("hzCrossName"',
            'Invoke("hz41DllScan"',
            'HasMember("hz41DllScan"',
        )
        if t in msg_text
    ]
    scope_foreign = [t for t in ('MenuLive(ui, "HUDMenu"', "HudInvoke(", 'MenuLive(ui, "HUDMessagesMenu"') if t in scope_text]
    if hud_foreign:
        print("FAIL: PollScaleform reaches a foreign movie token: " + ", ".join(hud_foreign), file=sys.stderr)
        return 1
    if msg_foreign:
        print("FAIL: PollMessages reaches a foreign movie token: " + ", ".join(msg_foreign), file=sys.stderr)
        return 1
    if scope_foreign:
        print("FAIL: ScopeClipPoll reaches a foreign movie token: " + ", ".join(scope_foreign), file=sys.stderr)
        return 1
    hud_body = "\n".join(strip_line(ln) for ln in cpp_fns["PollScaleform"].splitlines())
    msg_body = "\n".join(strip_line(ln) for ln in cpp_fns["PollMessages"].splitlines())
    if "GetAsyncKeyState" in hud_body or "GetAsyncKeyState" in msg_body:
        print("FAIL: PollScaleform / PollMessages body samples GetAsyncKeyState", file=sys.stderr)
        return 1
    ui_io = sorted(name for name in io_cpp if name in from_ui)
    if ui_io:
        print("FAIL: file I/O reachable from PollScaleform(): " + ", ".join(ui_io), file=sys.stderr)
        return 1
    if "HzAddrLoad" in from_ui or "ReadOwnFileVersion" in from_ui:
        print("FAIL: HzAddrLoad / ReadOwnFileVersion reachable from PollScaleform()", file=sys.stderr)
        return 1
    print("OK: no Scaleform call is reachable from Poll(); no file I/O on the UI path")
    return 0


if __name__ == "__main__":
    sys.exit(main())
