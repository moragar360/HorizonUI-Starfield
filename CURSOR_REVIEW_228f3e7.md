# CURSOR REVIEW 228f3e7

Independent review. This reviewer did not write the code. No product code was edited.

## Verdict

**PASS WITH WARNINGS**

`228f3e7` fixes the `23a3fc3` must-fix. A build-time coverage table (`font_cover.json` + `HZ_FONT_COVER` bitmasks) hides Orbitron for Polish. `Font=Orbitron` is kept in the INI / `hzFontFam`; live draw uses Exo 2 and F11 shows `Not available for this language`. For en/de/fr/es/es-mx (and zh-cn Latin), Orbitron stays offered and set-text substitutes ·→• and „«»→". Independent cmap check: every offered font/language pair has zero leftover glyphs after that substitution. Exo 2 default is unchanged. Coverage is a const table, not a TTF read or poll. Host tests: JS 92/92, `l10n_test` 139, other C++ host suites 0 fail.

No must-fix for coverage, INI rewrite, idle cost, secrets, `.pdb`, or `/tmp`. Open P2s are leftover set-text paths that skip `hzFontText` (classic header `hzApplyFmt` restore, hover ` · ` join), and the FONT FAMILY control showing index 0 while `hzSetPend.Font` is still Orbitron.

## MUST-FIX

None.

## P2

1. **Classic header `hzApplyFmt` can undo substitution.** `hzText` stores pre-sub `o.raw`, then `hzFontText`, then `hzApplyFmt` sets `keepTxt = hzHdrCase(o.raw)` without substituting. Card titles rarely contain middot. `hzSetHdr` now stores the substituted string. F11 goes through `hzWT` / `hzSText`, which substitute and do not restore from `raw`.
2. **A few direct `.text =` assignments still embed middot.** Hover loot footer `fmeta.join("  ·  ")` does not call `hzFontText`. Compass heading uses cached `hzDot` (correct). Numeric vitals/ammo ticks are ASCII.
3. **FONT FAMILY shows EXO 2 when saved Orbitron is hidden.** `hzSetListIdx("Orbitron")` is not in `vals`, so the control paints index 0. `hzSetPend.Font` stays `Orbitron` until the user steps or picks the row; OK then still writes `Font=Orbitron`. A left/right on that row would rewrite to an offered family. The note is the intended signal.

## Nits (release prep)

- `tools/build_font_coverage.js` splices the five block sources, not the eight host copies. This commit copied them; a later regen can drift until `l10n_modules_audit` / coverage tests include those files.
- `font_coverage_test.js` pins `HZ_FONT_COVER` bits to a fresh compute, not `HZ_ORB_FROM` / `HZ_ORB_TO` vs `orb_sub`.
- `HUDMenu_1.as` / `himp1` snapshots were not edited. Pack from `horizon_block.as`.
- Empty-payload stamp consume, dialogue named DFZongYi, and FOMOD-vs-unrebuilt `fonts_horizon.swf` remain from earlier reviews. Not this commit.

---

## Scope

| Item | Value |
|---|---|
| Reviewed commit | `228f3e73bf74d2a0813ddadccb39b62db5ebb699` |
| Parent | `23a3fc319b87f7392c4583e9e8295af15911ca17` |
| Branch / PR | `cursor/l10n-plan-cf98` / [#16](https://github.com/moragar360/HorizonUI-Starfield/pull/16) |

32 files, `+1302 / −245`. Review file only in this commit. No DLL/SWF/gfx. No game.

---

## 1. Coverage table and Polish hide

**PASS.**

`tools/build_font_coverage.js` writes `Interface/HorizonUI/fonts/font_cover.json` and splices `HZ_FONT_COVER` / `HZ_ORB_FROM` / `HZ_ORB_TO` between generated markers. `tests/lib/font_cover.js` is host-only (never loaded by the HUD). Bits: Exo2=1, Saira=2, Orbitron=4, Titillium=8. Polish `bits=11` (Orbitron off). `hz30FontRows` copies only `hzFontCovered` ids into `r.vals` / `r.names`.

`hzFontFamLive` returns Exo 2 when the stored family is uncovered. `hzFontHorizonBase` uses the live family, so Polish Orbitron draws `$Horizon_Font`. `hzFontFam` / `hzSetCurrent().Font` / `hzBuildIniText` still emit the saved token. Uncovered note: `settings.ui.not_available_for_this_language` in all seven JSON files; `hzLt` on the Font row.

Independent cmap (this VM, `cover.compute` on `228f3e7`):

| Face / lang after sub | en | de | fr | es | es-mx | pl | zh-cn Latin |
|---|---|---|---|---|---|---|---|
| Exo 2 / Saira / Titillium | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Orbitron | 0 (raw 1) | 0 (raw 2) | 0 (raw 3) | 0 | 0 | **16 letters, hidden** | 0 (raw 1) |

Orbitron cmap has U+2022 and U+0022, not U+00B7. Subs: ·→•, «»„→". AS chrome U+00B7 / U+00B0 included. CJK still Option A (game FontLib). `font_cover.json` matches a fresh compute. Stale table or an offered pair with holes fails `tests/font_coverage_test.js`.

---

## 2. Substitution at set-text only

**PASS** (P2 #1, #2).

`hzFontText` returns immediately unless `hzFontFamLive() == "Orbitron"`, then walks the string once (four `HZ_ORB_FROM` codepoints). Call sites: `hzText`, `hzSetHdr`, `hzL10nTf`, `hzSText`, `hzWT`, `hzFitText`, `hzT`, plus module `hzc`/`hzd`/`hzs`/`hzq` `*FontText` on their set-text helpers.

`hzFontApply` (INI Font=, F11 live, `hzSetL10n`) caches `hzFontLive` and `hzDot`. Compass heading is `HZ_CARD + hzDot + padded degrees + °` — no per-tick string walk. `hzFontText` is not in vitals/ammo/watch ticks. No new `ENTER_FRAME`, `setInterval`, `Timer`, or TTF parse. HUD does not load `font_cover.json`.

---

## 3. Exo 2 default and INI

**PASS** (P2 #3 on the F11 control paint).

- `hzFontFam = "Exo2"`, `HZ_SET_DEF.Font = "Exo2"`, `HorizonUI.default.ini` `Font=Exo2` (file not in this commit).
- FontFace 1 + Font=Exo2 still `$Horizon_Font`. `hzFontLive` defaults to Exo2. Unknown tokens still normalize to Exo2.
- Language apply does not write INI. OK saves `hzSetPend`, which keeps `Font=Orbitron` unless the user changes FONT FAMILY. `font_family_test.js` pins `!SetPend.Font=` in `hz30FontRows`.

---

## 4. Secrets, PDB, `/tmp`

**PASS.**

No `HUSD`, `SCHROPE`, `rschr`, box paths, bot names, `.pdb`, or `/tmp` in the `228f3e7` hunks. C++ tests still use `HzTestScratch`. JS tests read the repo.

---

## 5. Tests run on this VM

Worktree at `228f3e7`. No DLL/SWF/game.

| Suite | Result |
|---|---|
| Independent cmap (offered pairs after sub) | 0 leftover |
| `tests/*.js` (92 files) | 92 passed, 0 failed |
| `tests/font_coverage_test.js` | 61 passed (stale `font_cover.json` / `HZ_FONT_COVER` or offered holes fail) |
| `tests/font_family_test.js` | 62 passed (hide, INI keep, set-text-only sub, section 13) |
| `tests/l10n_test.cpp` | 139 passed |
| `preset_list_test`, `menu_bits_test`, `perf_diag_test`, `scan_hl_test`, `scan_ol_test`, `scan_reach_test`, `quickslots_test`, `watchlog_fdh_test`, `message_log_test` | 0 fail |

In-game Orbitron glyph check and F11 Polish note remain NOTRUN here.

---

## 13. Performance summary (0.43.4 baseline)

| # | Rule | This commit |
|---|---|---|
| 1 | Insert/draw add no per-frame timers. No new `ENTER_FRAME`, `setInterval`, or language poll. | Pass. Coverage is a const bitmask. `hzFontText` is set-text. Compass uses `hzDot`. |
| 2 | L10n push on movie load / Favorites open / F11 OK language change. | Pass. `hzSetL10n` / module SetL10n call `hzFontApply` once. |
| 3 | No UI-thread file I/O. JSON on the job/load thread. | Pass. No TTF parse, no `font_cover.json` load at runtime. |
| 4 | `hzL` / `hzLt` lookups stay hash table. | Pass. Unchanged. |
| 5 | No extra Invoke on HUD / scanner / QM ticks. | Pass. Stamp path unchanged. Substitution is not an Invoke. |
| 6 | No clip churn for string resolution. | Pass. Walk is once per set-text when live is Orbitron, else return. `hzTW` still keys stored `Font=` plus resolved `hzFontName()` (live face miss on language change). |
| 7 | F11 search index on open / drop on close. | Pass. Font row filter is catalog build, not a tick. |
| 8 | Language override on F11 OK. | Pass. `hzFontApply` then HUD refresh. |
| 9 | CJK probe on set-text only. | Pass. Unchanged Option A. |
| 10 | Quick Menu edge-driven. | Pass. `hzqFontText` on set-text. |
| 11 | Watch / vitals ticks do not call `hzL` or `hzFontText`. | Pass. |

Pass versus 0.43.4. Orbitron set-text walk is bounded (string length × 4) and skipped when live is not Orbitron.
