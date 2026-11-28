# CURSOR REVIEW 23a3fc3

Independent review. This reviewer did not write the code. No product code was edited.

## Verdict

**FAIL**

`0500c51` and `23a3fc3` do what they claim for Chinese Option A docs, the F11 STYLE Font picker (aliases only, default Exo 2, OFL sources bundled, FontFace 0/1/2/3 kept), and the three `a0bed1c` warning fixes (pending bits cleared on menu close, stamp consumed after a successful Invoke with one HasMember retry, SETTINGS shrinks then ellipsizes at the 1000 px floor). Idle AdvanceFrame is still one relaxed atomic load. Host tests on this VM: JS 92/92, `l10n_test` 139, other C++ host suites 0 fail.

They fail the font-offer spec. A family is offered for a language only if it covers every glyph in that language’s table, otherwise Exo 2. Orbitron does not cover en / de / fr / es / es-mx / pl (and extra Latin in zh-cn). The picker still always lists it. Fallback is a missing-FontLib probe, not coverage. That is a must-fix.

## MUST-FIX

1. **Orbitron is offered for languages it cannot cover; there is no glyph fallback to Exo 2.** Spec: offer a family for a language only if it covers all of that language’s glyphs; otherwise Exo 2.

   Host cmap vs shipped JSON (`node tests/font_coverage_test.js` on `23a3fc3`):

   | Face | en | de | fr | es | es-mx | pl |
   |---|---|---|---|---|---|---|
   | Exo 2 | 0 | 0 | 0 | 0 | 0 | 0 |
   | Saira | 0 | 0 | 0 | 0 | 0 | 0 |
   | Titillium Web | 0 | 0 | 0 | 0 | 0 | 0 |
   | **Orbitron** | **1** (U+00B7 ·) | **2** (·, U+201E „) | **3** (« · ») | **3** (« · ») | **3** (« · ») | **17** |

   Polish Orbitron misses: U+00B7 · and Ą ą Ć ć Ę ę Ł ł Ń ń Ś ś Ź ź Ż ż. English F11 chrome uses middot in many `settings.ui.*` strings (`Detected language · Override`, section titles). `hz34SemiNote` also injects U+00B7 in ActionScript.

   What the code does instead:

   - `HZ_FONT_FAM_IDS` is always `Exo2 / Saira / Orbitron / Titillium`. No language filter in `hz30FontRows` / `hz51LocOne`.
   - `hzFontFamNorm("orbitron")` always returns `Orbitron`. `hzFontHorizonBase` maps it to `$Horizon_Font_Orbitron`.
   - `hzFontName` falls back to `$Horizon_Font` only when `hzFontProbe(base)` fails (family not in FontLib). A present Orbitron with holes is used as-is. Tofu on Polish letters and on middot in every shipped Latin table.
   - `tests/font_coverage_test.js` records `orbPl >= 0` and does not require hide/fallback. `tests/font_family_test.js` pins Orbitron in the picker.

   Required: do not offer Orbitron for a language whose JSON (and AS-generated chrome) has a hole; if `Font=Orbitron` is stored, live-resolve to Exo 2 for that language. Saira and Titillium cover all non-CJK codepoints in en/de/fr/es/es-mx/pl and may stay. Pin the gate in `font_coverage_test.js` / `font_family_test.js`.

## P2

1. **Empty payload still consumes the stamp with no retry.** `PushL10nPendOne` `ClearL10nPend`s when `payload.empty()`. HasMember miss / failed Invoke retry once; an empty table does not. Language reload re-arms. Same hole as `a0bed1c` P2 #2, narrowed.
2. **Dialogue still does not probe `DFZongYi-GB Otf W5 Regular` by name.** Unchanged from `a0bed1c` P2 #4. Not in this pair’s claimed fixes. CJK codepoints already take the game face (`charCode > 0x52F`).
3. **FOMOD / FONT FAMILY claim the extra faces are in `fonts_horizon.swf`.** This commit adds source OFL TTFs and a comment-only `fontconfig_horizon_families.txt` (“merge when the font SWF is rebuilt”). Until that pack step, `$Horizon_Font_Orbitron` probe-fails and the documented missing-family path keeps Exo 2. That hides Orbitron tofu today and also means Saira / Titillium do not actually switch until rebuild. Not a substitute for must-fix #1 after pack.

## Nits (release prep)

- `font_coverage_test.js` header says Saira / Orbitron / Titillium are “reported, not required.” That matches the hole, not the spec.
- Close-then-HasMember-fail can `L10nPendRetryOnce` a pointer after `ClearL10nPendClosed` already dropped the bit. Idle still returns on the relaxed load (`bits == 0`). Next `ArmL10nPend` overwrites the slot. Harmless; keep claim/retry on one side of close if you touch this.
- `HUDMenu_1.as` / `himp1` snapshots were not edited. Pack from `horizon_block.as`.
- Variable TTFs (Exo 2 / Saira / Orbitron) vs static Titillium weights: pack must emit Regular / SemiBold / Bold instances the fontconfig maps name.
- Tests pin source. They do not execute Scaleform Invoke, live ellipsis, or a real FontLib probe.

---

## Scope

| Item | Value |
|---|---|
| Reviewed commits | `0500c51e667aaa65336591832b992bca573d0fe1`, `23a3fc319b87f7392c4583e9e8295af15911ca17` |
| Against | `a0bed1cea7c1828209f5c82383e94681001680a7` |
| Branch / PR | `cursor/l10n-plan-cf98` / [#16](https://github.com/moragar360/HorizonUI-Starfield/pull/16) |

50 files, `+1546 / −128` (includes OFL TTFs). Review file only in this commit. No DLL/SWF/gfx. No game.

---

## 1. Chinese Option A docs (`0500c51` + follow-through in `23a3fc3`)

**PASS.**

The same sentence is now in README (`## Language`), FOMOD compatibility + Font plugin, `LOCALIZATION_PLAN.md` P3/P4, `fontconfig_horizon_families.txt`, default.ini Language comment, F11 Language help, and all seven JSON `settings.language.help` / `settings.details.Language` strings: Simplified Chinese text requires Starfield itself to be set to Simplified Chinese; otherwise CJK characters cannot render. No FontLib, no embedded CJK, named face remains `DFZongYi-GB Otf W5 Regular`.

---

## 2. F11 STYLE Font picker

**FAIL** (must-fix #1). Default look, INI keys, and alias-only switch **PASS**.

| Claim | Code |
|---|---|
| FontFace 0/1/2/3 stay | `HZ_FONT_IDS = [1,2,0,3]`. FontFace 1 is now “Horizon family via Font=”. Roboto stays FontFace 2 (`$Horizon_Font_Alt*`). |
| `[Style] Font=Exo2\|Saira\|Orbitron\|Titillium`, default Exo2 | `hzFontFam = "Exo2"`, `HZ_SET_DEF.Font = "Exo2"`, `HorizonUI.default.ini` `Font=Exo2`. Unknown tokens → Exo 2 (`hzFontFamNorm`). |
| OFL files bundled | `Interface/HorizonUI/fonts/{exo2,saira,orbitron,titilliumweb}/` plus `OFL.txt`. |
| Aliases only, no extra SWF load | `hzFontHorizonBase` returns `$Horizon_Font` / `_Saira` / `_Orbitron` / `_Titillium`. `fontconfig_horizon_families.txt` is pack-time maps. No `URLLoader`, no runtime FontLib, no new timer on pick. |
| Missing family → Exo 2 → game font | `hzFontName`: if `!hzFontProbe(base)` and `base != "$Horizon_Font"`, probe `$Horizon_Font`, else game. **Install** miss, not **glyph** miss. |
| Exo 2 look unchanged by default | FontFace 1 + Font=Exo2 still uses `$Horizon_Font` / `_Regular` / `_Bold`. No change to the default alias. |
| All previous INI keys preserved | vs `a0bed1c` default.ini: **added** `Font` only. **removed** none. `l10n_test` still pins Hotkeys / Cards / Style / Quick Menu. |
| Modules follow Font= | `hzc` / `hzd` / `hzs` / `hzq` `*FontHorizonBase` plus the eight host copies. |

FONT FAMILY is disabled unless the pack is present and FontFace is 1 (`hz30FontRows`). Live preview is theme/typography (`hz51PvKind`). `hzTW` / `hzQsSame` key on `hzFontFam` so a family change is change-only, not a per-tick remap.

---

## 3. `a0bed1c` warning fixes

**PASS** (P2 #1 empty payload).

### Pending bits on close

`MenuOpenClose` `!opening` calls `ClearL10nPendClosed` for `HUDMessagesMenu` / `DialogueMenu` / `MonocleMenu`. That nulls the slot and clears both `g_l10nPendBits` and `g_l10nPendRetry`. A movie that is created and closed without AdvanceFrame no longer leaves idle AdvanceFrame paying three pointer compares. Event path, not a poll.

### Stamp consumed after successful Invoke, one retry

`PushL10nPendOne` claims the slot (`store nullptr`) but does **not** clear the bit first. `HasMember` miss or `Invoke` returning false → `L10nPendRetryOnce` (re-store `a_this`, set retry bit). A second miss `ClearL10nPend`s so the bit cannot stick as a poll. `Invoke` true → `ClearL10nPend`. Closed / ABA / `!g_l10nReady` / empty payload still consume. Nested AdvanceFrame of the same movie sees `want == nullptr` and returns. `l10n_test` / `l10n_modules_audit_test` pin this.

### SETTINGS shrink then ellipsis at the 1000 px floor

`hz51DrawHead`: if measured SETTINGS overflow, walk `t2` size down to 8, then `hzFitText(t2, setn, tw2 + 4)`. Chip width is still `max(52, tw3 + 28)`. `hz51Fit` still never goes below 1000. Host tests pin the shrink + `hzFitText` calls; live Flash clip/ellipsis remains NOTRUN.

---

## 4. Secrets, PDB, `/tmp`

**PASS.**

- No `HUSD`, `SCHROPE`, `rschr`, box paths, or bot names in the `0500c51` / `23a3fc3` hunks. `l10n_test` still pins `!Has(..., "HUSD")`.
- No `.pdb` in the commits. No new absolute PDB path.
- C++ tests use `HzTestScratch` (`tests/hz_test_scratch.h`), which rejects `/tmp`, `/var/tmp`, and user-profile temp. JS tests read the repo; none of the changed tests write `/tmp`.

---

## 5. Tests run on this VM

Worktree at `23a3fc3` (`/agent/repos/l10n-review-23`). No DLL/SWF/game.

| Suite | Result |
|---|---|
| `tests/*.js` (92 files) | 92 passed, 0 failed |
| `tests/font_coverage_test.js` | 20 passed (Orbitron holes **reported**, not failed) |
| `tests/font_family_test.js` | 49 passed (pins Orbitron always in the picker) |
| `tests/l10n_test.cpp` | 139 passed |
| `preset_list_test`, `menu_bits_test`, `perf_diag_test`, `scan_hl_test`, `scan_ol_test`, `scan_reach_test`, `quickslots_test`, `watchlog_fdh_test`, `message_log_test` | 0 fail |

In-game FontLib switch, Orbitron tofu, and SETTINGS ellipsis at 720p remain NOTRUN here.

---

## 13. Performance summary (0.43.4 baseline)

| # | Rule | These commits |
|---|---|---|
| 1 | Insert/draw add no per-frame timers. No new `ENTER_FRAME`, `setInterval`, or language poll. | Pass. Font row is F11 catalog. SETTINGS shrink/ellipsis runs in `hz51DrawHead` only. Stamp retry is the next AdvanceFrame of that movie, then consume. |
| 2 | L10n push on movie load / Favorites open / F11 OK language change. | Pass. Close now drops a never-advanced stamp. Reload still `ArmL10nPendOpen`. |
| 3 | No UI-thread file I/O. JSON on the job/load thread. | Pass. Font pick is an alias string. `fontconfig_horizon_families.txt` is pack-time. No runtime FontLib. |
| 4 | `hzL` / `hzLt` / `hzqLt` / `hzsLk` are hash lookups on an already-filled table. | Pass. Unchanged. |
| 5 | No extra Invoke on HUD / scanner / QM ticks. One latched payload per movie. Scanner/Dialogue/Comms stamp is one AdvanceFrame Invoke after create, not a poll. | Pass. Idle: one relaxed load. Pending: three pointer compares until that movie advances, close, or one retry. |
| 6 | No clip churn for string resolution. | Pass. Family probe is still `hzFontProbe` (cached). `hzTW` misses when `hzFontFam` changes. |
| 7 | F11 search index still built on open and dropped on close; indexes translated labels. | Pass. `hzSetL10n` still `hz51IndexBuild` when F11 is open. Font labels are catalog names (not slugged). |
| 8 | Language override applies on F11 OK (one JSON reread on the job thread). | Pass. Not a per-frame refresh. Font= is not re-read from disk on language apply. |
| 9 | CJK face probe and skip letter-spacing run on set-text only. | Pass. Option A docs only in this pair; probe path unchanged. |
| 10 | Quick Menu stays edge-driven; chrome on open / data / language push. | Pass. `hzqFontHorizonBase` is set-text / face resolve. |
| 11 | Watch / vitals ticks still do not call `hzL`. | Pass. `l10n_test` still pins `hzVitTick` / `hz19Vit` without `hzL(`. |

Pass versus 0.43.4 for idle cost and Font= switch. Must-fix #1 is coverage/offer, not a hot-path poll.
