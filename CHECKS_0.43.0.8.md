# CHECKS 0.43.0.8 (first pass, not approved)

An independent review will follow later. Do not treat this as approved.

## 0.43.0.12 — the F11 step is this press

Not approved. Schema stays `0.42.0`. File version and every movie build id are **0.43.0.12**.

The 0.43.0.11 review: `hzSetStep` kept the last step of the previous draw, so a throw before the next draw was labeled `hzToggleSettings.redraw.rows`. `hzSetMark("place")` was never called. A redraw note stayed after a later draw succeeded. A skipped null bar (`hzMeter.b`, `hzSetSz.c`) stayed the vitals step until the next mark.

`hzToggleSettings` now sets `hzSetStep` to empty on entry and marks `place` before `hzSetPlace`. A finished `hzSetDraw` drops the `hzToggleSettings.redraw` note and clears the step. A throw still keeps the step that was running. A null meter or a null size card returns without writing a step name. The splash is unchanged.

A healed array is still quiet when the push succeeds. `hzBuildCards.vitals.hzCard.hzCardBodies` appears only if that push throws. This pass still does not name the 0.43.0.9 in-game object.

The tree to build is `cursor/note-sibling-keys-4c32`. `feature/message-log-p2-ui` is still 0.43.0.10 until that branch is updated.

DLL, HUD, Comms, scanner, and scope build strings are `0.43.0.12`. `HZ_COMMS_MSG_LOG` and `HZ_HUD_MSG_CAPTURE` stay `0`.

Verified on this Linux checkout (no Windows DLL and no SWF were built here): the four suites. Still unverified in game.

PC folders: compile and run xmake only in `C:\HorizonUI-repo`. `C:\HorizonUI` is only the SWF compile tools.

## 0.43.0.11 — both diagnoses, and a real null name

Not approved. Schema stays `0.42.0`. File version and every movie build id are **0.43.0.11**.

The 0.43.0.10 review: a standing `hzBuildCards.vitals` note made `hzNoteKeep` drop `hzToggleSettings.redraw.HZ_SET_TABS`, so the F11 page could stay blank with no F11 name in the log. The `hzCardBodies` / `hzTiles` / `hzIcons` / `hzTexts` / `hzBars` / `hzVnBodies` / `hzSz` marks sat after `= []`, so they could not fire. `hzVit@` also replaced any note already stored.

`hzNoteErr` now keeps a wrapper off a protected note, and appends a different protected key after ` | `. A longer phase of the same key still wins. The vitals try writes `hzVitStep` and does not assign `hzLastErr` until the catch. A null array is named, then set to `[]`. F11 draw marks `body`, `version`, `HZ_SET_TABS`, `hzSetRows`, and `rows`. Tab previous / next uses a local count when `HZ_SET_TABS` is null. The splash is unchanged.

DLL, HUD, Comms, scanner, and scope build strings are `0.43.0.11`. `HorizonUI.default.ini` header and the Moragar preset `Version=` match that. `HZ_COMMS_MSG_LOG` and `HZ_HUD_MSG_CAPTURE` stay `0`.

If the HUD is still vanilla and F11 is still blank, the log should show both, for example:

`hud: movie error hzBuildCards.vitals.hzCard.HZ_TY_SIZE: TypeError #1009 Error #1009 | hzToggleSettings.redraw.rows: TypeError #1009 Error #1009`

`rows` is the last F11 step that started. `HZ_SET_TABS` there means the throw was the tab list. This pass still does not know which object was null in the 0.43.0.9 game log. Do not treat it as approved.

Verified on this Linux checkout (no Windows DLL and no SWF were built here): the four suites. Still unverified in game.

PC folders: compile and run xmake only in `C:\HorizonUI-repo`. `C:\HorizonUI` is only the SWF compile tools.

## 0.43.0.10 — the vitals card and the F11 page

Not approved. Schema stays `0.42.0`. File version and the HUD movie id are **0.43.0.10**.

In-game 0.43.0.9 (America/Phoenix, 2026-11-01, 14:19): the DLL and the HUD movie both loaded as 0.43.0.9. Health, oxygen, compass, and ammo stayed vanilla. F11 showed the window and the version, and the settings page was blank. The log was `hzToggleSettings.redraw: TypeError #1009` on the first key, then `hzEnsureHud.hzBuildCards: TypeError #1009` on the second. There was no `hzBoot null` line. `hzInitFields` had already assigned the instance arrays, and that did not stop the throw.

The vitals try calls `hzCard` first. `hzCard` pushes `hzCardBodies`, then `hzText` formats through `hzApplyFmt`, which indexes `HZ_TY_SIZE`. The F11 chrome and the version are drawn with `hzWT` before that table is used. The next object on the F11 path is `HZ_SET_TABS`. A null there leaves the window and the version up and the page blank. `HZ35_INFO` and `HZ_SET_DEF` are the next statics on that page.

`hzNoteErr` now leaves a note that already says `hzBuildCards.vitals`, `hzBuildCards.jet`, `hzBuildCards.rest`, or `hzToggleSettings.redraw` when a wrapper catch tries to replace it. The vitals try marks the step (`hzCard`, `hzBuildVitNew`, `hzMeter`, `hzSetSz`) and, when the object is null, the object name. The splash is unchanged: `hzSplashOnLoad` still returns when `HorizonVitals_mc` is null.

The next log, if a build still throws, should show one of:

`hud: movie error hzBuildCards.vitals.hzCard.hzCardBodies: TypeError #1009 Error #1009`

`hud: movie error hzBuildCards.vitals.hzCard.HZ_TY_SIZE: TypeError #1009 Error #1009`

`hud: movie error hzToggleSettings.redraw.HZ_SET_TABS: TypeError #1009 Error #1009`

A finished vitals sprite is added only after those steps return, and it stays non-null so the next frame can hide the vanilla bars.

Verified on this Linux checkout (no Windows DLL and no SWF were built here): the four suites below. Still unverified in game.

## 0.43.0.9 — null fields, splash lag, new file version

Not approved. Schema stays `0.42.0`. File version and movie build ids are **0.43.0.9** so a log can be told apart from every earlier 0.43.0.8 SWF.

In-game 0.43.0.8 (America/Phoenix, 2026-11-01): the live HUDMenu was this tree (`has hzLastError`, hash matched the build) and then threw `TypeError #1009` in `hzBuildCards` and `hzToggleSettings.redraw`. Vanilla bars were hidden, F11 was empty, and the game lagged. Bot 2: HUDMenu has hundreds of instance fields; `hzBoot` only recreated 13; `hzFontName` reads `hz30Mod` and F11 draw reads `hzSetKeyOv`. The splash rebuilt about 100 TextFields every frame for 5.6 s.

Fix in `actionscript/horizon_block.as`:

1. Removed `= []`, `= {}`, and `= new Sprite()` from 59 instance fields. `hzInitFields()` assigns each one if it is null, then `hzNoteErr("hzBoot null " + names)` with the late names first (the note is capped at 240 characters). `hzBoot()`, `hzBuild()`, and `hzEnsureHud()` call `hzInitFields()` before card work.
2. `hzSplashTick` returns immediately when `HorizonVitals_mc == null`. Text is built once in `hzSplashMake` (four 2 px outline offsets, no new GlowFilter). The tick only changes alpha, x, and visible.
3. DLL, HUD, Comms, scanner, and scope build strings are `0.43.0.9`.

Verified on this Linux checkout (no Windows DLL and no SWF were built here):

| Suite | Exit |
|---|---|
| `preset_list_test` | 0 |
| `message_log_test` | 0 (callgraph OK: no Scaleform from `Poll()`, no file I/O on the UI path) |
| `planet_alert_test.js` | 0 |
| `reaction_match_test.js` | 0 |

Pins that fail if this fix is reverted: `hzInitFields` assigns `hz30Mod` and `hzSetKeyOv` and logs `hzBoot null`; those declarations have no object initializer; `hzBoot` / `hzEnsureHud` / `hzBuild` call `hzInitFields`; `hzSplashTick` checks `HorizonVitals_mc == null` and does not `removeChildAt`; the outline offsets are `[-2,2,-2,2]`; `HZ_BUILD` and `HZ_FILE_VERSION_STR` are `0.43.0.9`; schema pin stays `0.42.0`.

Still unverified in game. After the PC rebuild, `HorizonUI.log` must show `HorizonUI 0.43.0.9 loaded` and `movie builds: HUD 0.43.0.9`. Then either Horizon cards are up, or `hud: movie error hzBoot null ...` / `hzBuildCards.vitals` names the next failure. Do not treat a `HUD 0.43.0.8` line as this build.

PC folders: compile and run xmake only in `C:\HorizonUI-repo` (the GitHub checkout). `C:\HorizonUI` is the old tree and is only the SWF compile tools. A text search of `hudmenu.gfx` cannot see `[-2,2,-2,2]`; the compiler stores those offsets as numbers. The decompile of `C:\Users\rschr\build\out_v043009\swf\hudmenu.gfx` containing `var ox:Array = [-2,2,-2,2]` is the offset check. `hzInitFields`, `hzBoot null`, and `0.43.0.9` are present in that movie, and `0.43.0.8` is absent. The DLL and eight movies are already built. The next PC step is the FOMOD zip only. Do not rebuild.

The sections below are the earlier 0.43.0.8 pass. They are history. The install to test now is 0.43.0.9, staged under `C:\Users\rschr\build`.

## Building on your PC with Cursor

Superseded for 0.43.0.9. Do not paste the prompt in this section. It points at `C:\HorizonUI`, which is not the GitHub checkout.

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
