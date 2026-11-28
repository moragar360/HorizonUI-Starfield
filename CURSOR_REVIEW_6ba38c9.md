# CURSOR REVIEW 6ba38c9

Independent review. This reviewer did not write the code. No product code was edited.

## Verdict

**PASS WITH WARNINGS**

`6ba38c9` is the correct fix for the l10n_f blank-HUD crash. `228f3e7` added `private var hzDot:String` (compass middot cache) on the same `HUDMenu` class as `private function hzDot(d,col)`. In Scaleform AVM2 that is one ABC trait slot: `this.hzDot` is the string, so `this.hzDot(dot, HZ_GREEN)` inside `hzCard` throws "value is not a function". `hzBuild` has no try around the first `hzCard` (jetpack), so HUD construction aborted and only vanilla chrome remained.

This commit renames the string to `hzMid`, keeps the six painter calls, and adds `tests/as_trait_collision_test.js`. Independent scan of every `.as` file in the tree (24, including `imp/` and `HUDMenu_1*`) found no remaining slot/function collision. Broader throw-risk pass on ActionScript changed since `8c62195` (last known good in-game HUD) found no other host-test-blind Scaleform throw of the same class.

No must-fix. Open P2s are test-coverage gaps (`imp/` skipped; function+getter not flagged; vanilla parent not in the live scan), not a remaining crash on the live HUD.

## MUST-FIX

None.

## P2

1. **`listLiveAs` skips `imp/` and `HUDMenu_1*`.** The host copies are what the pack actually compiles. A collision introduced only in a snapshot would not fail this test. Independent scan of those 14 files on this commit: clean. Pack-from-block remains the rule.
2. **Function vs getter (both methods) is not flagged.** `collisionsOf` only intersects `var`/`const` slots with methods. Fixtures confirm const+function, var+getter, const+getter, var+setter, and override-getter vs var *are* caught. A `function zoom()` next to `function get zoom()` is not. The compiler usually rejects that pair; the 228f3e7 crash was slot vs function.
3. **Inherited vanilla members are not in the live movie concat.** HUD/Comms/Dialogue/Scanner/QM/Scope concatenations are Horizon splice files only. `IMenu` / `DialogueMenuBase` / MovieClip are not in this tree. Feasible stand-in: Flash `DisplayObject`/`TextField` names plus live-slot vs host-getter names in `imp/`. Both were empty on this commit.

## Nits (release prep)

- `HUDMenu_1.as` / `himp1` snapshots never received `var hzDot:String` and do not have `hzMid`. Pack from `horizon_block.as`.
- Prior P2s (classic `hzApplyFmt` restore, hover ` · ` join, FONT FAMILY index 0 while saved Orbitron is hidden) are unchanged.
- Empty-payload stamp consume, dialogue named DFZongYi, and FOMOD-vs-unrebuilt `fonts_horizon.swf` remain from earlier reviews. Not this commit.

---

## Scope

| Item | Value |
|---|---|
| Reviewed commit | `6ba38c96bec1e6f6b608d2f16a65b38255807471` |
| Parent | `228f3e73bf74d2a0813ddadccb39b62db5ebb699` |
| Branch / PR | `cursor/l10n-plan-cf98` / [#16](https://github.com/moragar360/HorizonUI-Starfield/pull/16) |
| Last good in-game HUD | `8c62195` |

3 files, `+206 / −7` (`horizon_block.as`, `tests/as_trait_collision_test.js`, `tests/font_family_test.js`). Review file only in this commit. No DLL/SWF/gfx. No game.

---

## 1. Crash site and rename

**PASS.**

`228f3e7` (`horizon_block.as`):

- `private var hzDot:String = "\u00B7";` (line 187)
- `this.hzDot = … hzFontText("\u00B7") …` in `hzFontApply` (line 1049)
- `private function hzDot(d:Sprite, col:uint)` still at line 672
- first use: `hzBuild` → `this.hzDotJet = this.hzCard(...)` → `this.hzDot(dot,HZ_GREEN)` with no try/catch

`6ba38c9`:

- `private var hzMid:String` at 187. Comment states the painter keeps `hzDot`.
- `hzFontApply` writes `this.hzMid` only.
- Compass heading: `HZ_CARD[idx] + " " + this.hzMid + " " + ds + "°"` (line 1323). No per-tick `hzFontText`.
- No remaining `var hzDot:String` or `this.hzDot=` in live ActionScript.

`hzDotJet` / `hzDotVit` / `hzDotPlan` / `hzDotAff` / `hzDotAmmo` are different identifiers (dot sprites). They do not occupy the `hzDot` slot.

---

## 2. Painter calls intact

**PASS.**

`this.hzDot(` counts: `8c62195` 6, `a0bed1c` 6, `228f3e7` 6, `6ba38c9` 6. Same six sites:

| Line | Call |
|---|---|
| 349 | `hzCard` → `this.hzDot(dot,HZ_GREEN)` |
| 1506 | afflictions |
| 1955 | ammo |
| 2081 | planet |
| 3223 | jetpack (from `hzBuild` after the first `hzCard`) |
| 3251 | vitals |

Painter body is still `private function hzDot(d:Sprite, col:uint)` at 672. No string use of the name `hzDot` remains.

---

## 3. Collision test

**PASS** (P2 #1–#3).

`tests/as_trait_collision_test.js` (196 lines):

- Strips comments and string literals, then matches class-body traits with `DECL`: `public|private|protected|internal` + optional `override`/`static`/`final` + (`var`/`const` NAME) or (`function` optional `get`/`set` NAME `(`).
- `listLiveAs` walks `actionscript/`, skips directory `imp` and files `HUDMenu_1*`.
- Per-file scan of the 10 live hosts, then concatenated movie classes: HUD (`horizon_block.as` alone), HUD F11 insert, HUD F11 draw, Comms, Dialogue, Scanner, Quick Menu (`hzq_main` + `hzq37_reader`), Scope (`hzp_main` + `hzp37_reader`).
- Pins the `228f3e7` HUD via `readBase` so a silent rename of the fixture cannot drop the regression.

Run on this VM (`6ba38c9` worktree): **23 passed**, 0 failed. The pin reports `228f3e7 HUD had the hzDot var/function collision`.

Independent fixtures using the same `collisionsOf` (not in the test file):

| Pair | Caught? |
|---|---|
| var + function (`hzDot`) | yes (in-repo fixture) |
| const + function | yes |
| var + getter | yes |
| const + getter | yes |
| var + setter | yes |
| override getter + var | yes |
| function + getter (both methods) | **no** (P2 #2) |

Independent scan of **all 24** `.as` files including `imp/` and `HUDMenu_1*`: 0 collisions.

Inherited stand-in: Horizon live slots vs vanilla host methods/getters in `imp/` (HUDMenu, HUDMessagesMenu, DialogueMenu, MonocleMenu, FavoritesMenu, ScopeMenu) — no cross hits. Concatenating live splice + host snapshot also produced no slot/function collisions. Flash `DisplayObject` / `TextField` names (`name`, `x`, `text`, `visible`, …) are not used as Horizon slots. `IMenu` source is not in the repo; that parent walk is not feasible here.

The test would have caught the 228f3e7 bug (it does, via `readBase`). It would catch a new `var`/`const` colliding with a function or getter on any live movie class it concatenates. It would not catch a collision that exists only in `imp/`, only on `IMenu`, or a function/getter pair.

---

## 4. Broader in-game throw risk since `8c62195`

**PASS** (static). Host JS/C++ cannot execute Scaleform.

ActionScript touched since `8c62195`: 15 files (`horizon_block.as`, `hz51_insert.as`, `hz51_draw.as`, comms/dialogue/scanner/QM hosts, and their `imp/` copies). Scope splice files were not in that diff.

| Risk | Finding |
|---|---|
| String/function shadowing | Only `hzDot` in `228f3e7`. Gone in `6ba38c9`. Full-tree trait scan clean. |
| Calling undefined members | 53 unique `this.foo(` added since `8c62195`; 0 missing on live hosts. New helpers (`hzFontFamLive`, `hzFontApply`, `hzFontText`, `hzqFace`, `hzcFontProbe`, …) are defined on the same movie class the pack splices. |
| `new TextFormat` null font | Added sites pass `hzCjkFont` / `hzFontName` / `hzqCjkFont` / `hzqFace`. Those return a `String` (`$MAIN_Font`, `$Horizon_Font*`, or a probed CJK face). No `new TextFormat(null,…)`. `hzFont ? hzFont : "$MAIN_Font"` still guards the cached game face. |
| Missing imports | 0 new `import` lines. `Sprite` / `TextField` / `TextFormat` already imported on the vanilla hosts. |
| Uncaught init throw | `hzBuild` still has no try around `hzCard`. That is why one shadowed painter wiped the HUD. After the rename, `this.hzDot` is the function again. |

Vanilla getters on Scope (`ZoomLevel`), Monocle (`doingSocialScan`, button clips), and Favorites (`assignedItem`, `selectedIndex`, …) do not collide with Horizon slots (cross-check above).

This is not an in-game run. Scaleform-only failures still possible: font.marker timing, empty-string `TextFormat`, FOMOD-vs-unrebuilt `fonts_horizon.swf`. None of those are introduced by `6ba38c9`.

---

## 5. Secrets, PDB, `/tmp`

**PASS.**

No `HUSD`, `SCHROPE`, `rschr`, box paths, bot names, `.pdb`, or `/tmp` in the `6ba38c9` hunks.

---

## 6. Tests run on this VM

Worktree at `6ba38c9`. No DLL/SWF/game.

| Suite | Result |
|---|---|
| `tests/as_trait_collision_test.js` | 23 passed |
| Independent `collisionsOf` fixtures + 24-file tree (incl. `imp/`) | 31 passed (6 fixtures + 24 files + 1 count) |
| Live-slot vs vanilla host getter/method | 6 movies, 0 hits |
| `tests/font_family_test.js` | 64 passed (hzMid pins, painter never assigned) |
| `this.hzDot(` painter count | 6, unchanged vs `8c62195` |

Full `tests/*.js` and C++ host suites were not re-run for this rename-only commit. In-game HUD after `6ba38c9` remains NOTRUN here.

---

## 13. Performance summary (0.43.4 baseline)

| # | Rule | This commit |
|---|---|---|
| 1 | Insert/draw add no per-frame timers. No new `ENTER_FRAME`, `setInterval`, or language poll. | Pass. Rename only. Compass still concatenates a cached separator (`hzMid`). |
| 2 | L10n push on movie load / Favorites open / F11 OK language change. | Pass. `hzFontApply` still runs once on those edges; it now writes `hzMid`. |
| 3 | No UI-thread file I/O. JSON on the job/load thread. | Pass. Unchanged. Collision test is host-only. |
| 4 | `hzL` / `hzLt` lookups stay hash table. | Pass. Unchanged. |
| 5 | No extra Invoke on HUD / scanner / QM ticks. | Pass. Unchanged. |
| 6 | No clip churn for string resolution. | Pass. Compass heading does not walk the string. |
| 7 | F11 search index on open / drop on close. | Pass. Unchanged. |
| 8 | Language override on F11 OK. | Pass. Unchanged. |
| 9 | CJK probe on set-text only. | Pass. Unchanged Option A. |
| 10 | Quick Menu edge-driven. | Pass. Unchanged. |
| 11 | Watch / vitals ticks do not call `hzL` or `hzFontText`. | Pass. Unchanged. |

Pass versus 0.43.4. No new idle work. The in-game cost of `228f3e7` was a throw on first `hzCard`, not a poll; `6ba38c9` removes that throw.
