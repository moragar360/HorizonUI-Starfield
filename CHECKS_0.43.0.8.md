# CHECKS 0.43.0.8 (first pass, not approved)

An independent review will follow later. Do not treat this as approved.

## Building on your PC with Cursor

1. On the Windows PC, open the Cursor app. Use File > Open Folder and open `C:\HorizonUI` (or the folder that already has this repo / `sfse-plugin`). If the Cursor CLI is not installed, install it from Cursor: Command Palette > "Install cursor command".
2. Open a new Agent chat in that folder. Paste this prompt as-is:

```
Pull the latest feature/message-log-p2-ui from origin (fetch, checkout, fast-forward only; no commit, no push).

Before you touch any install or settings files, back them up by copying or moving (never delete):
- HorizonUI.user.ini
- HorizonUI.default.ini in the game Data tree
- presets/user
- Message Log folder under Documents\My Games\Starfield\SFSE\HorizonUI

Then:
1. In C:\HorizonUI\sfse-plugin (or this repo if that is the plugin tree), run:
   xmake f -c -y -m releasedbg
   xmake build -y
   Put the DLL, SWFs, and FOMOD in C:\Users\rschr\build the same way as 0.43.0.7.
   Do not copy into the live Vortex staging folder or Data\SFSE\Plugins.
2. Compile the SWFs and their _lrg twins from the AS sources using the existing C:\HorizonUI SWF import steps:
   - HUDMenu and HUDMenu_lrg from actionscript/horizon_block.as (this is the important one)
   - HUDMessagesMenu and HUDMessagesMenu_lrg (version pin)
   - MonocleMenu and MonocleMenu_lrg (version pin)
   - ScopeMenu and ScopeMenu_lrg (version pin)
3. Package the FOMOD the same way you packaged 0.43.0.7, into C:\Users\rschr\build.
4. Do not launch Starfield. Do not git commit or git push. Author stays Moragar. Never write HUSD. Move files; never delete.

When done, tell me the DLL path, the SWF paths, the FOMOD zip path, and the backup folder paths. All of those should be under C:\Users\rschr\build.
```

3. House rules the local agent must follow: move, never delete; no git commit or push from the PC; DLL author Moragar, never HUSD; do not launch the game.
4. After it finishes, check: backups exist; `HorizonUI.log` is not written yet (game was not launched); the new DLL, SWFs, and FOMOD zip are under `C:\Users\rschr\build`; version strings say 0.43.0.8. Then you install that FOMOD in Vortex when you are ready. Leave 0.43.0.7 deployed until then.

## (a) Repo tests (this cloud run)

All four suites were compiled/run on this Linux checkout. Exit 0. No Windows DLL or SWF was built here.

1. `g++ -std=c++20 -Wall -Wextra -I src tests/preset_list_test.cpp -o /tmp/preset_list_test` then `/tmp/preset_list_test` — 127 ok lines, 0 FAIL. First compile failed one pin (`HzRxEnqueue` now passes `snap.artifact`); pin updated; rerun passed.
2. `g++ -std=c++20 -Wall -Wextra -pthread -I src -DMSGLOG_REPO_ROOT="$PWD" tests/message_log_test.cpp -o /tmp/message_log_test` then `/tmp/message_log_test` — passed, including the Scaleform/file-I/O callgraph (`OK: no Scaleform call is reachable from Poll(); no file I/O on the UI path`).
3. `node tests/planet_alert_test.js` — 939 ok lines, 0 FAIL.
4. `node tests/reaction_match_test.js` — 864 ok lines, 0 FAIL (63 matcher cases plus lifetime/pairing/miss harnesses).

E2E / mutation pins that would fail if the 0.43.0.8 fixes were reverted:

1. HISTORY `cx + cw - 58` present and `cx + cw - 78` absent.
2. `hzMsglogShown` / `hzMsglogChipCount` call `hzMsglogTypeOn`; `hzMsglogChipClamp` exists.
3. `a_out->artifact = hzrx::LineHasArtifact(a_ev->text.c_str())` and `HzRxEnqueue(..., snap.artifact)`.
4. `char show[201]` and `RxNote` / snap `text[257]`.
5. `GameNotice("Jacob's office key")` is KEY; `"Jacob's office key Added."` is KEY/ITEM; `"Digipick Added."` is ITEM; artifact after byte 256 still titles ARTIFACT via `a_artifact`.
6. Splash: `hzSplashOnLoad` / `hzSplashLead` / `SHOW WELCOME ON LOAD`; no `GlowFilter` inside `hzSplashOnLoad`.
7. Steal: `hzT19IsSteal` and `steal ? HZ_RED : HZ_ACCENT`.
8. COMMS: `hz31DrawPage` and compact expand `hz34NoteCmp && on`.
9. Settings-saved log includes LogTypes (`message log settings saved {}`).
10. `ModuleNoteCompact=1`, `ShowWelcomeOnLoad=1`, `CommsPage=0` in `HorizonUI.default.ini`.
11. File version / movie build / xmake / preset / default.ini header all `0.43.0.8`. Schema pin stays `0.42.0`. Flags stay 0.

Pin-kill score for this pass: the one stale enqueue pin was a real kill (test failed, pin fixed). The HISTORY / TypeOn / artifact / splash / steal / COMMS / default.ini pins are present. No mutation runner beyond these source pins.

## (b) House rules

1. American spelling. `greyed` is absent in the HUD source; `grayed` stays.
2. `HUSD` does not appear in `src/`. Author in `xmake.lua` is Moragar.
3. New F11 copy uses 13 px (`HISTORY`, COMMS page labels, compact module titles). Compact notices stay at least 13 px.
4. HUD `_lrg` shares `actionscript/horizon_block.as`. COMMS / scanner / scope / monocle twins only got the version pin. `himp1`, `himp1.07`, `HUDMenu_1.as`, and `HUDMenu_1.07.as` were not edited.
5. No new glow. Splash uses an 8-offset 2 px dark outline. Existing `GlowFilter` on other HUD chrome is unchanged.
6. No new F key. Welcome is F11 > CONTROLS > SHOW WELCOME ON LOAD.
7. SEH snap still copies through `HzHudMsgReadSEH`. Artifact is read from `a_ev->text` inside that copy. Empty / newline / 257-char GameNotice miss. ItemNotice misses credits, artifact, and newlines.
8. No delete/rm tooling. Release flags stay 0. Settings schema stays `0.42.0`.
9. This cloud run did not launch the game, merge, tag, or publish.

## (c) Self-review / risks

This is a first pass. Not approved.

Works in repo:

1. HISTORY value is centered between the arrows (`cx + cw - 58` is the field center; hzWT `center` places `t.x = x - w/2`).
2. Off LogTypes hide list rows and pills, and C++ Offer already stops recording them.
3. Welcome splash arms on LoadingMenu and starts on the first hud-safe HUD tick (`hzSplashOnLoad`). Skips if already in combat or F11. Cancels in 0.15 s on F11 / combat / target prompt / ARRANGE. About 5.6 s, HUD accent, no panel, no glow, never pauses. `_lrg` is `TextScale >= 1.14` -> 1.3x on the same HUD source.
4. COMMS Option A: full-width SUBTITLES / DIALOGUE switch. Notices start collapsed; a missing module expands. One `ModuleNoteCompact` for both. `CommsPage` is remembered.
5. Owned-item steal prompts are red via `bStealing` or button text STEAL (kind is `prompt`, not `item`).
6. More vanilla lines become Horizon cards: Added./Removed. -> ITEM (or KEY if the line contains "key"); a key name without Added. -> KEY; artifact in the full `a_ev->text` still titles ARTIFACT after a 256-byte cut.

Vanilla HUD / blank F11 (11:21 and 11:33 local, 2026-11-01): the live movie was 0.43.0.8. The first `hzBuildId` / `hzToggleSettings` can fail while `hzSetDllFileVersion` succeeds (GFx Invoke is false if the method throws). `hzBuild` is swallowed by the wrapper constructor; if it throws before ENTER_FRAME, vanilla stays up. Fix: arm the frame hook first, `hzEnsureHud` when the movie identifies as Horizon, guard F11 open, retry a failed toggle on the HUD tick. Needs a PC rebuild of HUDMenu + DLL.

Unverified on Windows / in game:

1. DLL / SWF / FOMOD. This environment cannot build the Windows plugin or compile movies.
2. Long `"..."` notices still need a natural in-game look.
3. Splash vs the `_accent2` mockup (outline vs any extra shadow in the frames). Mid-combat save load: splash is skipped at start; if combat starts after it begins, it fades in 0.15 s.
4. Splash starts on first hud-safe tick, not after the 3 s "HUD ready" wait. If that is too early (fader still up), it may need a later arm.
5. Category hide is movie-side. Old rows of an off type stay on disk and come back if the type is turned on again.
6. ItemNotice only matches Added./Removed. A bare item name with no "key" stays a generic GAME card.

Heartbeat gaps while `hudSafe=0` (F11 or a full-screen menu) are expected. `Poll()` returns before the HUD tick; the hook still heartbeats. Documented, not changed.

## (d) In-game checklist

Leave 0.43.0.7 in Vortex until you install this 0.43.0.8 FOMOD. Back up settings first.

### Sitting 1 — Message Log SETTINGS

1. Open F11 > MESSAGE LOG > SETTINGS.
2. HISTORY "500" sits between the arrows, not on the right arrow. Same in large text.
3. Turn MEDICAL off. MEDICAL rows and the MEDICAL pill hide. ALL still shows the types that are on. New MEDICAL lines are not recorded.
4. Turn MEDICAL on again. Old MEDICAL rows return if they were already saved.

### Sitting 2 — Welcome splash

1. Load a save. After the load screen, a short HORIZON UI splash should play (accent color, dark outline, no panel, no pause, about 5.6 s). End line is "Loading preset: <name>" or "Loading default settings".
2. Large text: the splash is a bit bigger.
3. F11 > CONTROLS > SHOW WELCOME ON LOAD off, load again: no splash.
4. Turn it back on. Open F11 during a splash: it should fade in about 0.15 s.

### Sitting 3 — COMMS

1. F11 > COMMS. Full-width SUBTITLES / DIALOGUE switch under the install notice.
2. Notices start collapsed at 13 px. A missing module expands the notice.
3. Switch pages with L/R or by clicking a half. Close F11 and reopen: last page is remembered.

### Sitting 4 — Steal

1. Look at an owned item (Credstik on Akila). E STEAL should be red.
2. A normal take / activate prompt should stay the HUD accent.

### Sitting 5 — New cards

1. Pick up a key (for example "Jacob's office key"): Horizon KEY card, not vanilla.
2. Pick up a normal item ("Digipick Added."): Horizon ITEM card.
3. If you see a long notice: card ends with "..."; Message Log keeps about 256 characters.

### Sitting 6 — Log only

1. `HorizonUI.log` says `HorizonUI 0.43.0.8 loaded`.
2. After a Message Log settings save, the log includes the LogTypes list.
3. Opening F11 can make `lastHudAge` grow. That gap is expected.
