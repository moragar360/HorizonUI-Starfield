# CHECKS 0.43.0.8 (first pass, not approved)

An independent review will follow later. Do not treat this as approved.

## 0.43.0.18 — ini on-words and a docs scrub

Not approved. Schema stays `0.42.0`. File version and every movie build id are **0.43.0.18**. `HZ_COMMS_MSG_LOG` and `HZ_HUD_MSG_CAPTURE` stay `0`.

`EnemyCard` and `BuildCards` in `LoadIni` use `HZF::IniFlagOn`. Only `1`, `true`, `on`, and `yes` are on, in any case, with surrounding space ignored. Every other value is off, including `False` and `Off`. `StartupIntro` is not read by the DLL. The movie reads it in `hz34Ini` as a number, so `False` and `Off` already leave the intro off.

The default.ini comment for `EnemyCard=0` names the character card, enemy health, stealth, the XP toast, combat FX, the regen sliver, equipment extras, and personal alerts. Their F11 toggles do nothing while the flag is 0. Shipped default.ini comments and the F11 BUILD CARDS and STARTUP INTRO rows no longer say this is a test.

Card construction is unchanged from 0.43.0.17. Still unverified in game.

## 0.43.0.17 — skip the enemy card unless EnemyCard=1

Not approved. Schema stays `0.42.0`. File version and every movie build id are **0.43.0.17**. `HZ_COMMS_MSG_LOG` and `HZ_HUD_MSG_CAPTURE` stay `0`.

In-game 0.43.0.16 crashed while building cards. The UI thread was 22948. Static stages passed. Cards ran one per frame through `listen`. The last line was `HUD card begin enemy` with no `done`. The dump came about 1.3 seconds later. The first-tid gate did not starve the pump, so it stays.

`[UI] EnemyCard` defaults to `0` in `HorizonUI.default.ini`. The DLL reads it in `LoadIni` and pushes `hzSetEnemyCard` from `PollScaleform` before `HudCtorPump`, because the ini card runs after the enemy card. The movie default is `false`. When the flag is off, `hzEnemyFrame` logs `HUD card skipped enemy` and the pump continues with scan, ini, compact, and show.

When `EnemyCard=1`, the enemy card is 133 frames. `HudCtorPump` logs `HUD enemy step N <what>` before the invoke. `hzEGo` queues the same line before that step's risky call. The builders are the 0.43.0.7 calls, split so one frame creates a child, sets up one text, creates a bar, subscribes, or calls `addChild`.

Compared with 0.43.0.7 (`b4c368d`), `hz26Build` and the enemy-card builders were the same code before this split. 0.43.0.8 (the startup intro) did not change any function in that call set. Later builds only added null guards in `hzT`, `hzApplyFmt`, `hzFontName`, `hzSetSz`, `hzTxtObj`, and `hz34F`, plus `hzVitMark`. Those guards are not a behavior change once `hzInitFields` has run, and the field stage runs before cards. No intro-era edit of the enemy card itself showed up, so this build does not rewrite the card to an older body. The skip and the step log are the safety net.

The startup intro is still in `hzSplashOnLoad` / `hzSplashStart` and still returns on `StartupIntro=0`. F11 COMMS still draws the full-width SUBTITLES / DIALOGUE switch in `hz31DrawPage`, under the install notice from `hz31CommsRows`. COMMS and SCANNER notices still start collapsed (`ModuleNoteCompact=1`, `hz34NoteCmp`).

The tree to build is `cursor/note-sibling-keys-4c32`. Build from `C:\HorizonUI-Agent`. Still unverified in game.

## 0.43.0.16 — HUD invokes stay on the HUD thread, one card per frame

Not approved. Schema stays `0.42.0`. File version and every movie build id are **0.43.0.16**. `HZ_COMMS_MSG_LOG` and `HZ_HUD_MSG_CAPTURE` stay `0`.

In-game 0.43.0.15 (America/Phoenix, 2026-11-01, about 19:59) crashed on save load. The user rolled back to 0.43.0.7. `HorizonUI 0.43.0.15 loaded` and `HUD ctor start 0.43.0.15` were on ui tid 507540. Every static stage from `HZ_TY_SIZE` through `arm` logged `HUD stage begin` and `HUD init` (62 begins, 61 inits). The last line was `HUD stage begin cards` at 19:59:10.131. The dump `Starfield_11-02-02-59.dmp` was written at 19:59:11.513. There was no `HUD ctor error`, no `HUD ctor stages done`, and no `splash skipped`. The stage lines used many movie-advance thread ids, not only 507540. That rules out the single-function size theory. The native crash is inside card build, and the prime suspect is a HUDMenu invoke from another movie's AdvanceFrame.

`PollScaleform`, `HudCtorPump`, `DrainHudDllLog`, and every HUDMenu `Invoke` now run only when the advancing root is the stored HUDMenu root and the thread is the first HUD-root thread (`UiTidAllowsHudWork`). A later thread returns before `PollScaleform`. `MenuMovie` applies the same rule to every HUDMenu invoke, including `hz41DllScan`, `hzSetDllFileVersion`, and `hzCrossName`. The first skip logs once: `hud: skip HUDMenu invoke on tid N (ui tid M)`. HUDMessagesMenu and Scope stay on their own advances.

The `cards` stage is fourteen frames: accent, vitals, jet, compass, planet, quest, target, fonts, listen, enemy, scan, ini, compact, show. The DLL logs `HUD card begin <name>` before the invoke. The movie logs `HUD card done <name>`, or `HUD ctor error card <name>` with the Error text. A stop on `HUD card begin` names the card that faulted.

`BuildCards` defaults to on (`1` in `HorizonUI.default.ini`, `true` on the instance, `1` in `HZ_SET_DEF`). F11 CONTROLS shows BUILD CARDS at 13 px. The DLL reads the merged ini at load and pushes `hzSetBuildCards` before the stage pump. `BuildCards=0` under `[UI]` in `HorizonUI.user.ini`, written before the save load, skips `hzBuildCards`. The movie logs `cards skipped`, then the pump logs `HUD ctor stages done`. `StartupIntro` stays off, so the log also says `splash skipped`. With cards skipped, `hzEnsureHud` and `hzBuild` do not build cards, and the vanilla HUD stays up.

`StartupIntro` still defaults to off. `hzOnFrame` still returns before hiding vanilla when `HorizonVitals_mc` is null. Outline offsets stay `[-2, 2, -2, 2]`. No new glow. No new F key.

The tree to build is `cursor/note-sibling-keys-4c32`. `feature/message-log-p2-ui` is still 0.43.0.10 (`63a10d4`) until that branch is updated. Build from `C:\HorizonUI-Agent`.

Verified on this Linux checkout (no Windows DLL, no SWF, and no game were built here): preset list tests passed; message log tests passed, including the Scaleform call graph; planet alert 939 ok; reaction match 864 ok. Still unverified in game. Only an in-game test can confirm this. A useful A/B is one load with `BuildCards=0` and, if that reaches `HUD ctor stages done` and `splash skipped` without a dump, a second load with `BuildCards=1`.

PC folders: the desktop worker's checkout is `C:\HorizonUI-Agent`. `C:\HorizonUI` is only the SWF compile tools.

## 0.43.0.15 — one small function per static table

Not approved. Schema stays `0.42.0`. File version and every movie build id are **0.43.0.15**. `HZ_COMMS_MSG_LOG` and `HZ_HUD_MSG_CAPTURE` stay `0`.

In-game 0.43.0.14 (America/Phoenix, 2026-11-01, about 19:16) showed only the vanilla HUD. The game crashed about one second after `HUD ready (stable 3s)`. HorizonUI.log ended on the HUD-ready lines. There was no `HUD 0.43.0.14` build id, no TypeError, no `#1009`, and no VerifyError. The minidump is `Starfield_11-02-02-17.dmp`. That matches a Scaleform reject or a native fault inside the single ~28 KB `hzInitStatics`, so the HUD class code never finished starting. The user rolled back to 0.43.0.7.

Each of the 59 `Array` and `Object` tables is now its own function (`hzSt_HZ_TY_SIZE` through `hzSt_HZ41_SA_CMP`). Those functions assign the literal and do not call `names.push`. The declarations stay `private static var` with no initializer. `hzInitStatics` returns immediately until `hzStDone`, so an early `hzEnsureHud` cannot run every literal in one call.

The DLL runs one stage per HUD frame, including during the 3 second wait. It logs `HUD stage begin <name>` before the invoke. The movie then logs `HUD init <name>`, or `HUD ctor error <name>` with the Error name, id, and message. The first Horizon action is `hzCtor`, which only queues `HUD ctor start 0.43.0.15`. After the 59 tables the stages are `fields`, `arm`, and `cards`. `cards` sets `hzStDone` and then calls `hzBuildCards`. The next frame logs `HUD ctor stages done`.

A stop at `HUD stage begin <name>` with no following `HUD init <name>` means that stage faulted. The largest remaining stage is `HZ35_INFO` (about 8 KB of help text). `HZ40_SCAN_CM` is about 4 KB. A stop on either of those names means that function is still too big.

`hzBuild` and `hzEnsureHud` log the error text through `hzDllLog` instead of an empty catch. The decompile snapshots `himp1`, `himp1.07`, `HUDMenu_1.as`, and `HUDMenu_1.07.as` are not the compile source and were not edited. The shell line the PC splices still has `try { this.hzBuild(); } catch(hzBuildErr:Error) { }`. The builder replaces that catch with a `hzDllLog` of the error text. `hzBuild` itself already logs before it rethrows, and it returns after `hzCtor` until the stages finish.

`hzOnJetpack` still returns when `hzJetPct` is null, and it meters only when `hzJetBar` is not null. `hzOnPlayerFrequent` still runs `hz36HideTick`, returns when `hzVitHp` or `hzVitO2` is null, and meters only when `hzVitHpBar` or `hzVitO2Bar` is not null.

`StartupIntro` defaults to off (`0` in `HorizonUI.default.ini`, `false` on the instance, `0` in `HZ_SET_DEF`). It is an F11 CONTROLS bool, label STARTUP INTRO, 13 px. While it is off, `hzSplashOnLoad` logs `splash skipped` and returns, even if an older `user.ini` still has `ShowWelcomeOnLoad=1`. While it is on, and the older welcome, combat, and F11 gates pass, the log says `splash start`. `hzOnFrame` still returns before hiding vanilla when `HorizonVitals_mc` is null. Outline offsets stay `[-2, 2, -2, 2]`. No new glow. No new F key.

The log for a good start: `HorizonUI 0.43.0.15 loaded`, then `HUD ctor start 0.43.0.15`, then `HUD stage begin HZ_TY_SIZE` and `HUD init HZ_TY_SIZE`, through `fields`, `arm`, and `cards`, then `HUD ctor stages done`, and `splash skipped`. An older `HUD 0.43.0.14` line means this movie is not loaded. `HUD no build id` at movie-create time is the default string before `BuildLogHud`. It is not proof the class failed to link. Do not treat a movie id by itself as a built HUD.

The long `"..."` card look is still unverified in game.

The tree to build is `cursor/note-sibling-keys-4c32`. `feature/message-log-p2-ui` is still 0.43.0.10 (`63a10d4`) until that branch is updated.

Verified on this Linux checkout (no Windows DLL, no SWF, and no game were built here): preset list tests passed; message log tests passed, including the Scaleform call graph (`Poll` does not reach `HudInvoke`; `PollScaleform` reaches `HudCtorPump`); planet alert 939 ok; reaction match 864 ok. Still unverified in game: Horizon cards actually up, F11 CARDS page filled, splash skipped by default, a later load with STARTUP INTRO on, and the long `"..."` cards. Only an in-game test can confirm this.

PC folders: compile and run xmake only in `C:\HorizonUI-repo`. `C:\HorizonUI` is only the SWF compile tools.

## 0.43.0.14 — static tables are assigned before use

Not approved. Schema stays `0.42.0`. File version and every movie build id are **0.43.0.14**.

The 0.43.0.13 review failed the TypeError #1009 outage. In-game 0.43.0.9 (America/Phoenix, 2026-11-01, 14:19) already had `hzInitFields` run: there was no `hzBoot null` line, and `hzEnsureHud.hzBuildCards` plus `hzToggleSettings.redraw` still threw #1009. Health, oxygen, compass, and ammo stayed vanilla. F11 showed the window and the version, and the page was blank. 0.43.0.10 through 0.43.0.13 added notes. They did not assign the static tables those paths read.

`hzInitStatics` now assigns all 59 `Array` and `Object` tables before boot, build, F11, or splash use them. The declarations are `private static var` with no initializer, because Scaleform can skip a declaration initializer and a `static const` cannot be assigned later. The literals live in the function body. `hzInitFields` calls it first and writes one note when any of those tables or the instance arrays were null (`hzInitStatics null ...` and, when both happened, `hzBoot null ...`). `hzBuildCards`, `hzSetDraw`, and `hzSplashStart` call `hzUseStatics` before they use a table. A second call after the assignment does not write the note again.

The boot comment no longer says every non-primitive instance field is assigned. Sprites and text fields stay null until their card is built. `hzOnJetpack` returns when `hzJetPct` is null. `hzOnPlayerFrequent` still runs `hz36HideTick`, then returns when `hzVitHp` or `hzVitO2` is null, and it sets label and bar visibility only when that sprite exists.

`hzInitStatics` holds every table in one function, including the long `HZ35_INFO` and scanner tables. A movie that never prints `HUD 0.43.0.14` would mean Scaleform rejected that function. That is still an in-game check.

The local `HZ_SET_TABS` fallback in `hzSetDraw` stays. A healed instance array is still named before `= []`. `hzBuildCards.vitals.hzCard.hzCardBodies` appears only if that push throws. The splash is unchanged: it still returns when `HorizonVitals_mc` is null, welcome is off, the player is in combat, or F11 is open. `hzOnFrame` still returns before hiding vanilla when `HorizonVitals_mc` is null. Outline offsets stay `[-2, 2, -2, 2]`. No new glow. `HZ_COMMS_MSG_LOG` and `HZ_HUD_MSG_CAPTURE` stay `0`.

A one-time `hzInitStatics null` line with no `#1009` means Scaleform left those tables null and this build assigned them. A `#1009` is a remaining throw. Do not treat a movie id by itself as a built HUD. An older `HUD 0.43.0.13` line means this movie is not loaded.

The long `"..."` card look is still unverified in game. The historical "Message Log popup (0.43.0.8)" comment stays.

The tree to build is `cursor/note-sibling-keys-4c32`. `feature/message-log-p2-ui` is still 0.43.0.10 until that branch is updated.

DLL, HUD, Comms, scanner, and scope build strings are `0.43.0.14`.

Verified on this Linux checkout (no Windows DLL, no SWF, and no game were built here): preset list tests passed; message log tests passed, including the Scaleform call graph; planet alert 939 ok; reaction match 864 ok. Still unverified in game: Horizon cards actually up, F11 CARDS page filled, splash, HISTORY / MEDICAL / COMMS / steal / KEY / ITEM, and the long `"..."` cards.

PC folders: compile and run xmake only in `C:\HorizonUI-repo`. `C:\HorizonUI` is only the SWF compile tools.

## 0.43.0.13 — the redraw note drops when the page finishes

Not approved. Schema stays `0.42.0`. File version and every movie build id are **0.43.0.13**.

The 0.43.0.12 review: `hzNoteDrop("hzToggleSettings.redraw")` and the step clear sat at the end of `hzSetPvAfDraw`, the STYLE-tab affliction preview. `hzSetDraw` itself never dropped the note. The test span ran from `hzSetDraw` through `hzSetDrawCursor`, so it included that preview function and stayed green.

Those two lines now sit after the window z-order block at the end of `hzSetDraw`, and ahead of `hzSetListIdx`. The affliction preview no longer contains them. The two early returns clear `hzSetStep` and do not drop the note. The test span for the drop ends at `hzSetListIdx`.

The tree to build is `cursor/note-sibling-keys-4c32`. `feature/message-log-p2-ui` is still 0.43.0.10 until that branch is updated.

DLL, HUD, Comms, scanner, and scope build strings are `0.43.0.13`. `HZ_COMMS_MSG_LOG` and `HZ_HUD_MSG_CAPTURE` stay `0`.

Verified on this Linux checkout (no Windows DLL and no SWF were built here): the four suites. Still unverified in game.

PC folders: compile and run xmake only in `C:\HorizonUI-repo`. `C:\HorizonUI` is only the SWF compile tools.

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

PC folders: compile and run xmake only in `C:\HorizonUI-repo` (the GitHub checkout). `C:\HorizonUI` is the old tree and is only the SWF compile tools. A text search of `hudmenu.gfx` cannot see `[-2,2,-2,2]`; the compiler stores those offsets as numbers. The decompile of `%USERPROFILE%\build\out_v043009\swf\hudmenu.gfx` containing `var ox:Array = [-2,2,-2,2]` is the offset check. `hzInitFields`, `hzBoot null`, and `0.43.0.9` are present in that movie, and `0.43.0.8` is absent. The DLL and eight movies are already built. The next PC step is the FOMOD zip only. Do not rebuild.

The sections below are the earlier 0.43.0.8 pass. They are history. The install to test now is 0.43.0.9, staged under `%USERPROFILE%\build`.

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
   Put the DLL, SWFs, and FOMOD in %USERPROFILE%\build the same way as 0.43.0.7.
   Do not copy into the live Vortex staging folder or Data\SFSE\Plugins.
2. Compile the SWFs and their _lrg twins from the AS sources using the existing C:\HorizonUI SWF import steps:
   - HUDMenu and HUDMenu_lrg from actionscript/horizon_block.as (this is the important one)
   - HUDMessagesMenu and HUDMessagesMenu_lrg (version pin)
   - MonocleMenu and MonocleMenu_lrg (version pin)
   - ScopeMenu and ScopeMenu_lrg (version pin)
3. Package the FOMOD the same way you packaged 0.43.0.7, into %USERPROFILE%\build.
4. Do not launch Starfield. Do not git commit or git push. Author stays Moragar. Move files; never delete.

When done, tell me the DLL path, the SWF paths, the FOMOD zip path, and the backup folder paths. All of those should be under %USERPROFILE%\build.
```

3. House rules the local agent must follow: move, never delete; no git commit or push from the PC; DLL author is Moragar; do not launch the game.
4. After it finishes, check: backups exist; `HorizonUI.log` is not written yet (game was not launched); the new DLL, SWFs, and FOMOD zip are under `%USERPROFILE%\build`; version strings say 0.43.0.8. Then you install that FOMOD in Vortex when you are ready. Leave 0.43.0.7 deployed until then.

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
2. The DLL author in `xmake.lua` is Moragar.
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
