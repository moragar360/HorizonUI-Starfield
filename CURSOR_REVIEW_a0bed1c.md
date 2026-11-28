# CURSOR REVIEW a0bed1c

Independent review. This reviewer did not write the code. No product code was edited.

## Verdict

**PASS WITH WARNINGS**

`a0bed1c` does what the PR claims for the scanner CTD, the F11 header chip, the German leftovers, and the CJK face probe. Create-time `Invoke("hzsSetL10n")` is gone. The stamp is one-shot, after `orig()`, with a live `GetMenu` check before Invoke. Idle AdvanceFrame cost is one relaxed atomic load. Host tests on this VM: JS 90/90, `l10n_test` 135, other C++ host suites 0 fail.

No must-fix for crash, secrets, `.pdb`, `/tmp`, or a 0.43.4 hot-path poll. Open P2s are a sticky pending bit if a movie is created and never advances, consume-before-success (a failed first stamp is not retried), SETTINGS clipping without ellipsis on the 1000 px F11 floor, and dialogue chrome not taking the named DFZongYi path (CJK codepoints already fall back to the game face).

## MUST-FIX

None.

## P2

1. **Pending bit is not cleared on menu close.** `PushL10nForMenu` / `ArmL10nPend` store a raw `ASMovieRootBase*` and a bit. Nothing in `MenuOpenClose` nulls `g_l10nPendScan` / `Dlg` / `Comms`. The pointer is never dereferenced (compare only), and `PushL10nPendOne` re-fetches `GetMenu` and refuses a reused address, so a freed movie is not Invoked. If that movie is destroyed before its first AdvanceFrame, `g_l10nPendBits` stays nonzero and every hooked AdvanceFrame pays three acquire loads until an ABA match consumes the bit. Idle is then not “one relaxed load.” Normal scanner / dialogue / comms opens do advance at least once, so this is a hole, not the common path.
2. **Stamp is consumed before success.** `PushL10nPendOne` stores `nullptr` and clears the bit, then checks `g_l10nReady`, `IsMenuOpen`, live root, `HasMember`, and a non-empty payload. A miss (function not on `menuObj` yet, empty payload) does not re-arm. The create-time CTD was Invoke of an existing `hzsSetL10n`, so `HasMember` should be true after `orig()`. Language reload re-arms. Still: at most one try per arm, not “retry until it lands.”
3. **SETTINGS clips without ellipsis when the window is at the 1000 px floor.** `hz51Fit` never goes below 1000. At 1260, German `EINSTELLUNGEN` plus a measured `v0.43.5.0` chip fits left of compact/search (`maxR ≈ 644`). At `W=1000` with the Arrange control (`arrW=150`), `maxR ≈ 366` and German SETTINGS needs ~115 px, so the field shrinks to ~68 px and Flash clips the glyphs. The chip keeps its measured width. No `...`. 1080p F11 is fine; 720p HUD is the squeeze.
4. **Dialogue does not probe `DFZongYi-GB Otf W5 Regular` by name.** `hzdFont` already returns the game face for CJK codepoints (`charCode > 0x52F`). When the game language is Chinese that face is DFZongYi. Horizon zh-cn with the game still on English stays tofu, same documented FontLib gate as HUD. Comms only probes DFZongYi on the `hzcFits` overflow path, not on `used=zh-cn`; Latin overflow caches a failed probe and keeps the game font, so Exo 2 is unchanged.

## Nits (release prep)

- `hzCjkFont(face)` ignores `face`; CJK headers and body share Regular. Fine for one game face; Bold Exo 2 titles will not have a CJK bold twin.
- Font probe text is still `"WMW"`. A CJK face with no Latin would fail the probe and fall back to `hzFont` / `$MAIN_Font`. When the game language is Chinese that fallback is already DFZongYi. Not a ship blocker.
- `hzTW` cache keys go through `hzFontName`, which can disagree with the `hzCjkFont` draw face when the probe fails. Same-text hits still store the field’s real `textWidth`.
- `HUDMenu_1.as` / `himp1` snapshots were not edited. That matches the existing “not this build” rule; pack from `horizon_block.as`.
- Japanese `JP_NB Architekt Light Regular` is probed in `hzCjkFont` though `ja` is not a shipped table. Harmless; drop or keep for a later JA file.
- `de.json` `settings.line._goto_margin` and `settings.details._goto_margin` are both German but not the same sentence. Intentional length split; translators may want them aligned later.
- Tests pin source. They do not execute Scaleform Invoke or a live DFZongYi probe.

---

## Scope

| Item | Value |
|---|---|
| Reviewed commit | `a0bed1cea7c1828209f5c82383e94681001680a7` |
| Parent | `1a7a87496942ea225c415380a67d848e567639d1` |
| After a0bed1c | none (no docs-only follow-up) |
| In range, not this stamp | `8c62195` French LOOK/PLACE wording (`fr.json`, `tools/fill_module_l10n_keys.js`); merge `1468bab` / `c4dea71` already on the branch |
| Branch / PR | `cursor/l10n-plan-cf98` / [#16](https://github.com/moragar360/HorizonUI-Starfield/pull/16) |

24 files in `a0bed1c` itself (`+360 / −89`). Review file only in this commit. No DLL/SWF/gfx. No game.

---

## 1. Scanner / comms / dialogue stamp

**PASS** (P2 #1 and #2).

| Claim | Code |
|---|---|
| No create-time `Invoke("hzsSetL10n")` | `PushL10nForMenu` only `ArmL10nPend`. Tests pin `!Has(create, "Invoke(")`. |
| MenuMovieCreated arms a pending stamp | Bits `kL10nPendComms=1`, `Dlg=2`, `Scan=4`. Slots are `std::atomic<ASMovieRootBase*>`. |
| Invoke once after `orig()` | `HookedAdvanceFrame`: `orig(a_this, a_next)` then `PushL10nOnAdvance(a_this)`. |
| Exactly once per arm | `PushL10nPendOne` compares `a_this == want`, then nulls the slot and `fetch_and(~bit)` before Invoke. Nested advance cannot re-enter. Language reload (`PushL10nModules` → `ArmL10nPendOpen`) is a second arm, on purpose. |
| No Invoke of a freed / ABA movie | Pointer is compare-only. Invoke only if `IsMenuOpen`, `GetMenu` live root `== a_this`, `menuObj` is object and `HasMember(fn)`. |
| Idle = one relaxed load | `if (g_l10nPendBits.load(relaxed) == 0) return;` on the existing AdvanceFrame vtable hook. No new poll, timer, or per-frame Invoke. |
| Same path for comms and dialogue | `HUDMessagesMenu` / `hzcSetL10n`, `DialogueMenu` / `hzdSetL10n`, `MonocleMenu` / `hzsSetL10n`. Favorites still uses `MenuLive` (`PushL10nNamed`) because its AdvanceFrame already runs. |
| Threading | Arm is `store(release)` then `fetch_or(acq_rel)`. Consume is `load(acquire)` then `store(nullptr, release)`. Payload copy is under `g_l10nMu`; Invoke is after the lock. Scaleform create and AdvanceFrame are the UI path (`OnMenuMovie` / `HookedAdvanceFrame`). Job-thread `L10nApply` only bumps `g_l10nGen`; `PushL10n` runs later from HUD poll / F11. |

`PushL10nOnAdvance` cannot use `MenuLive`: after `orig()` `g_advancingRoot` is still null (HUD poll sets it later). Direct `GetMenu` is required so the stamp is not refused as a foreign-movie Invoke.

While a bit is set (the frame between create and that movie’s own AdvanceFrame), every hooked movie pays three pointer compares. That is a one-frame blip, not a poll.

---

## 2. F11 header (`hz51DrawHead`)

**PASS** (P2 #3).

Version chip: `t3` is created with `"v" + hv`, `tw3 = ceil(hzTW(t3))`, `pillW = max(52, tw3 + 28)`. Overflow shrinks `tw2` (SETTINGS), then `pillX = sx + tw2 + gap`. HORIZON UI (`t1`) is not shortened. `hzWT` is fixed-width (no autoSize), so a short `t2.width` clips SETTINGS instead of drawing through the chip.

Longest Latin SETTINGS (from `hud.hud_label.settings` / `settings.ui.settings`):

| Lang | String | Chars vs English |
|---|---|---|
| de | EINSTELLUNGEN | 13 (longest) |
| pl | USTAWIENIA | 10 |
| es / es-mx | AJUSTES | 7 |
| fr | RÉGLAGES | 8 |
| en | SETTINGS | 8 |
| zh-cn | 设置 | CJK; short in pixels once DFZongYi is used |

`HORIZON UI` is unchanged in all seven tables. At the 1260 cap, `cx ≈ 652`, `maxR ≈ 644`. Cluster estimate: HORIZON UI ~134 px + EINSTELLUNGEN ~115 px + gap + `v0.43.5.0` pill ~94 px ≈ 379 px, well under 644. Polish / French / Spanish are shorter than German. The chip follows measured text; SETTINGS gives way first.

---

## 3. German leftovers

**PASS.**

- `settings.ui.compact_strips_size` is present in en, de, es, es-mx, zh-cn, pl, fr. German is `KOMPAKTE LEISTEN: GRÖSSE` (no English `COMPACT STRIPS`). The F11 row still builds with English `cs.l = "COMPACT STRIPS: SIZE"`; `hz51LocOne` → `hzLt` slugs to `settings.ui.compact_strips_size`.
- `settings.line._goto_margin` is looked up by key in `hz51Line` before the English help fallback. de: `Öffnet Größe und Position…`; zh-cn translated; es/fr/pl too. English `Opens Size` remains only in `en.json` and the AS fallback string.
- Section headers: `hz51DrawList` builds `ht` at `boxW` (not `min(240, boxW*0.45)`), `wordWrap` / `multiline`, draws the hairline only when `shTw + 28 < boxW`, and adds `shExtra` from `textHeight`. German `VERWANDTE DARSTELLUNGSEINSTELLUNGEN` can wrap at full group width instead of colliding with the rule.

---

## 4. CJK face probe

**PASS** (P2 #4, nits on WMW / weight).

- Named face is `DFZongYi-GB Otf W5 Regular` only. No Noto, no `fontlib "fonts_zhcn"` in Horizon sources.
- HUD: `hzL10nCjk` is set once in `hzSetL10n` from `used`. `hzWT` / `hzApplyFmt19` use `hzCjkFont` when `hzL10nCjk \|\| hzHasCjk`. `hzFontName` short-circuits to that face only if `hzFontProbe` says it renders.
- Probe is `hzFontProbe` / `hzsProbe` / `hzqProbe` / `hzcFontProbe`: one TextField, cached in `hzFontOkMap` (and module maps). Called from set-text / face resolve, not from ticks.
- Latin languages: `hzL10nCjk` is false. `hzHasCjk` is false for de/pl/fr/es. Exo 2 path is the old `hzFontName` chain. Comms overflow probe fails and is cached; face stays `hzcGameFont`.
- Scanner / Quick Menu gate on `hzsL10nCjk` / `hzqL10nCjk`. Host copies (`MonocleMenu.as`, `FavoritesMenu.as`, `HUDMessagesMenu.as`) match the blocks (`l10n_modules_audit_test`).
- Documented limit stands: game English + Horizon zh-cn does not load `fonts_zhcn`, so Chinese F11 text stays tofu until the game language is Chinese (or a later font picker).

---

## 5. Secrets, PDB, `/tmp`

**PASS.**

- No `HUSD`, `SCHROPE`, `rschr`, box paths, or bot names in the `a0bed1c` hunks. `l10n_test.cpp` still pins `!Has(..., "HUSD")`.
- No `.pdb` in the commit. No new absolute PDB path.
- C++ tests use `HzTestScratch` (`tests/hz_test_scratch.h`), which rejects `/tmp`, `/var/tmp`, and user-profile temp. JS tests read the repo; none of the changed tests write `/tmp`.

---

## 6. Tests run on this VM

| Suite | Result |
|---|---|
| `tests/*.js` (90 files) | 90 passed, 0 failed |
| `tests/l10n_test.cpp` | 135 passed |
| `preset_list_test`, `menu_bits_test`, `perf_diag_test`, `scan_hl_test`, `scan_ol_test`, `scan_reach_test`, `quickslots_test`, `watchlog_fdh_test`, `message_log_test` | 0 fail |

No Windows DLL, no SWF, no Starfield. In-game scanner CTD / DFZongYi glyph check remains NOTRUN here.

---

## 13. Performance summary (0.43.4 baseline)

| # | Rule | This commit |
|---|---|---|
| 1 | Insert/draw add no per-frame timers. No new `ENTER_FRAME`, `setInterval`, or language poll. | Pass. Stamp is the existing AdvanceFrame hook. |
| 2 | L10n push on movie load / Favorites open / F11 OK language change. | Pass. Create arms; first matching AdvanceFrame Invokes. Reload arms open movies. |
| 3 | No UI-thread file I/O. JSON on the job/load thread. | Pass. `L10nApply` stays in `FilesJobPreload`. Stamp copies `g_l10n.payload` under mutex. |
| 4 | `hzL` / `hzLt` / `hzqLt` / `hzsLk` are hash lookups on an already-filled table. | Pass. Unchanged. |
| 5 | No extra Invoke on HUD / scanner / QM ticks. One latched payload per movie. Scanner/Dialogue/Comms stamp is one AdvanceFrame Invoke after create, not a poll. | Pass. Idle: one relaxed load. Pending: three pointer compares until that movie advances (typically one frame). P2 if the bit sticks. |
| 6 | No clip churn for string resolution. | Pass. Font probe allocates one or two TextFields **once per face name**, cached. |
| 7 | F11 search index still built on open and dropped on close; indexes translated labels. | Pass. `hzSetL10n` still `hz51IndexBuild` when F11 is open. |
| 8 | Language override applies on F11 OK (one JSON reread on the job thread). | Pass. Not a per-frame refresh. |
| 9 | CJK face probe and skip letter-spacing run on set-text only. | Pass. `letterSpacing = 0` when `cjk`. Probe is cached. |
| 10 | Quick Menu stays edge-driven; chrome on open / data / language push. | Pass. `hzqSetL10n` still header/data refresh; `hzqFace` CJK branch is set-text. |
| 11 | Watch / vitals ticks still do not call `hzL`. | Pass. `l10n_test` still pins `hzVitTick` / `hz19Vit` without `hzL(`. CJK format uses the cached probe on set-text, not a new lookup API. |

Pass versus 0.43.4 for this stamp, with P2 #1 as the only idle-invariant caveat.
