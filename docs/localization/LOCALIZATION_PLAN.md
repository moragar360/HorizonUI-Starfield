# Horizon UI — centralized localization plan

Author: Moragar. Last modified: 2026-11-27.
Status: research and planning only. No gameplay source in this pass.
Baseline: **0.43.4 performance**. Settings 2.0 (`feature/settings-2.0`) and Quick Menu (`wip/0.43.5-quickmenu-fix`) are in scope so F11 and the favorites menu are covered.

American English is the source language. Horizon-owned copy stays American English in `en.json`. Game item names, quest text, and `$TOKEN` strings stay with Starfield.

---

## In one sentence (non-technical)

Horizon will learn the game’s language once when it starts, read a small English file plus an optional translation file, remember every label in memory, and stamp those labels onto Settings, HUD cards, and the Quick Menu the next time each menu is built. Nothing extra runs every frame. Adding German or Japanese later is a file drop, not a new SWF.

---

## 0. Absolute performance rule

**Zero performance hit versus 0.43.4.** That release is the one players liked. Localization that cannot match it stays **off by default** or **out**.

Forbidden in the hot path (HUD frame, scanner frame, Quick Menu idle, Comms line fade):

- Polling
- Per-frame translation lookups
- Recurring or UI-thread file I/O
- Clip churn (creating/destroying TextFields to resolve strings)
- Extra Scaleform `Invoke` in hot paths
- Extra GC pressure (building throwaway strings or objects every frame)

Allowed, once:

- File read on the plugin task thread at init (same class as today’s GMST phrase read)
- One batch `Invoke` per movie load or per menu open
- Object-property reads of an already-filled cache when a card or the F11 list is **built**, not when it ticks

Every recommendation below states its cost versus 0.43.4.

---

## 1. Architecture overview

```
Starfield sLanguage (INI + LocalEnvironmentData)
        │
        ▼
HorizonUI.dll  [init, task thread, once]
  1. Read [General] Language (auto | en | de | …)
  2. Map game code → file code (jp/ja, zhhans/zh-cn)
  3. Load en.json (UTF-8)
  4. Overlay <lang>.json if present
  5. Keep unordered_map / frozen GFx object in memory
        │
        │  one string payload, one Invoke
        ▼
HUDMenu / FavoritesMenu / MonocleMenu / HUDMessages / Dialogue / Scope
  hzSetL10n(table)   // movie load or F11 open, never per string
        │
        ▼
ActionScript hzL10n["hud.health"] → "HEALTH"
  resolved when the card / row / menu is built
  TextField.text = cached string
  game $ tokens still go through GlobalFunc.SetText (already memoized)
```

**Who owns what**

| Kind of text | Owner | How it is shown |
|---|---|---|
| Horizon labels (HEALTH, CARDS, Setting Details, Quick Menu header) | Horizon JSON | DLL cache → one batch push → AS property |
| Settings 2.0 help and row labels | Horizon JSON | Same cache; F11 copies them when the window opens |
| Game item names, quest objectives, bioscan types, `$EMPTY SLOT`, `$Hold Breath`, `$HARVEST` | Starfield `translate_<lang>.txt` + strings files | Existing `$` TextField lookup, already cached per scanner open |
| Companion “liked that.” matching | Game GMSTs, read once in the DLL | Matcher only; the card title (LIKED) is Horizon JSON |
| FOMOD installer pages | Separate (Mod Organizer / Vortex UI language) | Not in the in-game table; optional later |
| INI comments in `HorizonUI.default.ini` | Same English as today for v1 | Optional `ini.*` keys later; not on the HUD |

**Layout on disk (shipped, UTF-8, no BOM):**

```
Data/SFSE/Plugins/HorizonUI/Localization/
  en.json
  de.json
  es.json
  es-mx.json
  fr.json
  zh-cn.json
  (it, ja, pl, pt-br fall back to English until a translator ships them)
```

The DLL is already the file owner for Message Log JSON and Quick Slots JSON. Localization is the same idea: read once, off the UI thread, cache forever.

Alternate path `Data/Interface/HorizonUI/Localization/` would match StarUI/Astral drop-in habits. Do **not** use both. Pick the SFSE plugin folder so Vortex/MO2 cannot fight `Interface\translate_en.txt` and so the DLL can resolve the path next to itself without a Scaleform `URLLoader` (URLLoader is UI-thread I/O; that is how 0.43.4 killed scanner/Comms settings re-reads).

**INI override**

```
[General]
; Horizon UI language. auto = follow the game. en, de, fr, it, es, es-mx, ja, pl, pt-br, zh-cn
; take effect after you restart the game. Default auto.
Language=auto
```

Settings 2.0: SYSTEM → CONTROLS & WINDOW → LANGUAGE, same options as the INI, copy “Takes effect after you restart the game.” That is the same rule as `SettingsKey`.

**Restart:** yes, for the override. Auto-detect needs no extra restart; the game already launched in that language. A live mid-session switch would mean a second batch push into every loaded movie and a rebuild of every HUD label. That is doable without polling, but it is new machinery on a path 0.43.4 does not have. v1 requires a restart so the hot path stays identical.

---

## 2. Research: Starfield native translation first

### What the game already does

Starfield’s UI is Scaleform GFx. Interface language is `sLanguage` under `[General]` in `Starfield.ini` / `StarfieldPrefs.ini` / `StarfieldCustom.ini`. Official codes:

| Language | INI `sLanguage` / HUD | Horizon file stem | Notes |
|---|---|---|---|
| English | `en` | `en` | |
| German | `de` | `de` | |
| French | `fr` | `fr` | |
| Italian | `it` | `it` | |
| Spanish (Spain) | `es` | `es` | |
| Spanish (Latin America) | Steam `latam`; game INI is `es` (LOOT). Horizon also accepts `esmx`, `latam`, `es-mx` | `es-mx` | Own stem. Overlay: `es-mx.json` → `es.json` → `en.json`. Auto+`es` uses Spain. |
| Japanese | `jp` (INI), `ja` (`LocalEnvironmentData`) | `ja` | |
| Polish | `pl` | `pl` | |
| Portuguese (Brazil) | `ptbr` | `pt-br` | |
| Chinese (Simplified) | `zhhans` | `zh-cn` | Horizon already branches on this for the watch location name |

Korean and Greek are not Starfield Steam interface languages and are not in v1.

Sources:

- [PCGamingWiki — Starfield localizations and `sLanguage`](https://www.pcgamingwiki.com/wiki/Starfield)
- [STEP — Starfield INI, including `sLanguage=en`](https://stepmodifications.org/forum/topic/19019-starfield-default-values-for-all-known-valid-ini-settings/)
- [Game8 — language codes and `Starfield.ini`](https://game8.co/games/Starfield/archives/424186)

Interface string tables are loose (or BA2) files named `Data/Interface/translate_<lang>.txt` (community dumps and rusifikator notes use `translate_en.txt` / `translate_ru.txt`, not Skyrim’s `Translate_ENGLISH.txt`). Encoding in the wild is UTF-16 LE with BOM, tab-separated `$Key<TAB>value`. A Scaleform TextField whose **entire** contents equal `$Key` is replaced with the translated value.

Related game files, same language suffix:

- `Data/Interface/fontconfig_<lang>.txt` — font name map (`$MAIN_Font`, `$Controller_Buttons`, …)
- `Data/strings/starfield_<lang>.STRINGS` / `.DLSTRINGS` / `.ILSTRINGS` — item names, books, dialogue

Sources:

- Zone of Games install notes: `translate_en.txt`, `fontconfig_en.txt`, `sLanguage=en` ([thread](https://forum.zoneofgames.ru/topic/72991-starfield/?page=227))
- [Nexus bilingual localization posts](https://www.nexusmods.com/starfield/mods/1380?tab=posts) — `translate_en.txt` lives under `Data\Interface`; strings files are a separate pipeline
- [bethesda-strings-editor](https://github.com/0xra0/bethesda-strings-editor) — treats `translate_en.txt` as Starfield interface TXT

Skyrim/Fallout SKSE extra files (`Data/Interface/Translations/<plugin>_ENGLISH.txt`) are documented for **SKSE**, not SFSE:

- [MCM Helper wiki — Scaleform translations](https://github-wiki-see.page/m/Exit-9B/MCM-Helper/wiki/Localization)

A GitHub code search of `ianpatt/sfse` for translation loaders returned **no hits**. Horizon must not assume SFSE merges extra `$` tables the way SKSE did.

### What Horizon already does with `$` (keep this)

**PROVEN in source.**

1. Scanner `hzsTr`: `$KEY` goes through `GlobalFunc.SetText` on a throwaway TextField. Since 0.43.3.2 the result is memoized in `hzsTrC` **once per scanner open**, because creating a field per marker per frame was a frame-time bug. Changelog: scanner names and bioscan types “are translated once per scanner open instead of creating a text field for every discovered marker every frame.”
2. Target-card button labels: `$` keys are handed to a TextField the same way vanilla `GlobalFunc.SetText` does; anything still holding `$` is dropped.
3. Quick Menu empty extras: `GlobalFunc.SetText(nt, empty ? "$EMPTY SLOT" : o.sName)`. The game’s translation of `$EMPTY SLOT` is kept. Item names are the game’s `sName`.
4. Vanilla scanner buttons in the decompiled twins (`$HARVEST`, `$BIOSCAN`, `$Hold Breath`, `$TAKE`, …) stay vanilla.
5. DLL message matcher reads localized GMSTs once on the task thread after data load (`HzMsgPrepare`). English is the fallback. That path is matching, not drawing Horizon chrome.
6. `LocalEnvironmentData.sLanguage` is already cached as `hz43EnvLang` (watch location name hides on `ja` / `zhhans`).

**Do not replace any of those with Horizon JSON.** Game names stay game names.

### Can Horizon-owned strings use native `$` tokens?

**No, not as the system.** Reasons, with cost:

| Issue | Why it blocks native `$` for Horizon chrome | vs 0.43.4 |
|---|---|---|
| No SFSE extra table | Shipping `$HZ_HEALTH` means patching `translate_en.txt` (last-write-wins with every other UI mod) | Conflict, not CPU |
| No English fallback | SKSE/MCM wiki: only the current language file loads | German player with a partial `translate_de.txt` sees raw `$HZ_HEALTH` |
| Exact-match only | `"$HZ_HEALTH 12"` does not translate. Settings help, `{0}` counts, and concatenated labels fail | Would force extra AS string builds |
| Lookup cost | Uncached `$` lookup = new TextField. Horizon already had to memoize this on the scanner | Repeating that on HUD ticks would **fail** the 0.43.4 bar |
| Encoding | UTF-16 LE BOM is hostile to git and to community editors | Maintainability |
| SWF recompile | Static FLA text fields would still need a rebuild to change keys; Horizon draws TextFields in AS anyway | Misses the “no SWF recompile” rule |

Native `$` stays the path for **Starfield** strings. Horizon chrome uses the DLL JSON cache.

---

## 3. Other Starfield UI mods

### StarUI Inventory / StarUI HUD (m8r98a4f2)

- Translator file: `Data/Interface/Translation/StarUI_Inventory_<lang>.txt` (and `StarUI_HUD_<lang>.txt`)
- English fallback is implemented **in the SWF**, not by the game
- Community is large (many Nexus translation mods)
- Format is Bethesda-style `$KEY<TAB>value` (UTF-16 in practice)
- [StarUI Inventory](https://www.nexusmods.com/starfield/mods/773) — translator rules
- [StarUI HUD](https://www.nexusmods.com/starfield/mods/3444)

Horizon should **not** copy the SWF file read. StarUI has no SFSE DLL. Horizon does, and 0.43.4 already forbids UI-thread file I/O (Comms hover hitch was “reads its settings files during HUD mode changes”).

### Astral UI (cybernav)

- `Data/Interface/AstralUI_Translations/AstralUILang_xx.ini`
- `AstralUICustom.ini` with `sLanguage=xx`
- English fallback per key
- UTF-8 INI, ~52 keys
- Reopen the menu to apply; no restart
- [Astral UI](https://www.nexusmods.com/starfield/mods/16405)

Closer to what Horizon needs (central table, fallback, no SWF rebuild). Horizon has more strings (Settings 2.0 help alone is hundreds of sentences) and a harder performance bar, so JSON in the DLL beats INI parsed in ActionScript.

### Lesson

| Mod | Format | Who loads | Fallback | Restart |
|---|---|---|---|---|
| Starfield | `translate_<lang>.txt` UTF-16 | Engine | none | launch |
| StarUI | `Translation/*_<lang>.txt` | SWF | English | reopen menu |
| Astral UI | language INI | SWF/plugin | English | reopen menu |
| **Horizon (this plan)** | UTF-8 JSON | **DLL at init** | English per key | **restart for override**; movies get one push at load |

---

## 4. JSON versus Bethesda Translate.txt

| | Horizon JSON (chosen) | `translate_*.txt` / StarUI txt |
|---|---|---|
| Encoding | UTF-8, no BOM, git-friendly | UTF-16 LE BOM |
| Comments / context | `_meta` and `_comment` keys, plus this plan | none |
| Nested keys | `settings.QuickMenuHorizon.label` | flat `$HZ_…` |
| English fallback | load en, overlay lang | not in the engine |
| Placeholders | `{0}`, `{count}` | `{}` only if you invent a parser |
| Community editors | VS Code, Notepad, GitHub PRs | Notepad++ encoding pitfalls |
| Conflicts | own folder | fights `translate_en.txt` |
| DLL fit | already has a JSON tokenizer (`hz_msglog.h` `JsonTok` / `FromJson`) | would add a UTF-16 parser |
| SWF recompile | none | none if TextFields are AS-created (they are) |

**Chosen:** JSON. Reuse the existing small JSON tokenizer; do not add a new library. Tables are a nested object of strings only (no arrays of mixed types) so the parser stays dumb and the AS side is `hzL10n.settings.tabs.cards`.

A **read-only export** to StarUI-style `$HZ_…` UTF-16 can be a tools extra later for translators who already have that workflow. It is not the runtime format.

---

## 5. DLL as central provider

### Load (once, task thread, after SFSE init / data loaded)

1. Resolve plugin directory; append `HorizonUI/Localization/`.
2. Read `en.json` whole (cap file size, e.g. 512 KiB, same spirit as Message Log’s 4 MiB cap).
3. Parse into `std::unordered_map<std::string, std::string>` (dotted keys) or keep a JSON object and flatten once.
4. Detect language (below).
5. If not English and `<lang>.json` exists, overlay values per key. Missing keys keep English. Empty values keep English.
6. Freeze. No reload. Log once: `l10n: en+de, 842 keys` (no string contents, no paths under Users).

**Cost vs 0.43.4:** one extra init read, same class as `HzMsgPrepare` GMST read. Not on the HUD thread. **Pass.**

### Detect language

Order:

1. `HorizonUI.user.ini` `[General] Language` if set and not `auto`
2. Else `sLanguage` from the game INI stack (Custom / Prefs / Starfield.ini). The DLL already reads Horizon INI files; add one `GetPrivateProfileString` (or the existing INI helper) at init, not per frame.
3. Else, when HUD first delivers `LocalEnvironmentData.sLanguage`, if the DLL still has `auto` and the codes differ, log once. Do **not** reload files on that event in v1 (would be late I/O). The INI is the source of truth for v1.

Map:

| File | Accept from INI / HUD / Steam |
|---|---|
| `en.json` | `en`, `english` |
| `de.json` | `de`, `german` |
| `fr.json` | `fr`, `french` |
| `it.json` | `it`, `italian` |
| `es.json` | `es`, `spanish`, `es-es` |
| `es-mx.json` | `esmx`, `es-mx`, `latam`, `esla` (then `es.json`, then English) |
| `ja.json` | `ja`, `jp`, `japanese` |
| `pl.json` | `pl`, `polish` |
| `pt-br.json` | `ptbr`, `pt-br`, `brazilian` |
| `zh-cn.json` | `zh-cn`, `zhhans`, `zh`, `schinese` |

Missing overlay → English. Unknown token stays as a lowercased community stem. Korean and Greek are not listed. Dropdown labels are native names with English in parentheses (`Deutsch (German)`). The Language list is the ten Steam stems even when only `en` / `de` / `zh-cn` files exist. `fr.json` is shipped.

**Cost vs 0.43.4:** a few INI string reads at init. **Pass.**

### Push (one batch per movie)

Pattern already in the DLL: `PushDllFileVersion` → `hzSetDllFileVersion(string)` when HUDMenu exists. Localization is the same, with a larger string.

- `hzSetL10n(jsonText)` on HUDMenu when it becomes live (once; latch)
- `hzqSetL10n` on FavoritesMenu when the Quick Menu opens (Favorites is not always loaded)
- `hzsSetL10n` / `hzcSetL10n` / `hzdSetL10n` / `hzpSetL10n` on those movies’ first live tick, latched

AS stores one Object, e.g. `this.hzL10n`. Lookup helper:

```
private function hzL(key:String, fb:String) : String
{
   if(this.hzL10n != null)
   {
      var v:* = this.hzL10n[key];   // dotted keys flattened on the C++ side
      if(v != null && String(v).length > 0) { return String(v); }
   }
   return fb;
}
```

Flatten on the C++ side so AS does not walk nested objects on F11 draw. F11 already rebuilds rows while open; an extra property read per **row build** is the same order as today’s `r.l` copy. It is **not** per HUD frame.

**Cost vs 0.43.4:** one extra `Invoke` per movie lifetime (Favorites: once per Quick Menu session if the movie unloads — still an edge, which is how Quick Menu already works). Payload size ~50–150 KB once. **Pass**, if and only if it is latched.

**Fail / out:** calling `hzL()` inside `ENTER_FRAME`, scanner marker move, compass tick, or hover-follow. Those paths must use strings already sitting on the TextField or on the card object from the last build.

---

## 6. No SWF recompile when a translation is added

Horizon HUD, Settings, Quick Menu, scanner overlay, Comms, and Scope create TextFields in ActionScript. They do not bake English into FLA static text for those labels. A new `de.json` is a loose file. FOMOD/Vortex copies it. No `hudmenu.gfx` rebuild.

Vanilla twins still contain `$HARVEST` and friends; those stay.

Shipped movies are not in git (binary gfx/swf). This inventory is from ActionScript, INI, FOMOD, and C++. That is the right source: those files are what a translator would change today if there were no table.

---

## 7. Preserve Starfield-localized strings

Rules for implementers:

1. If the game already gave a display string (`sName`, quest `strText`, GMST phrase, `$TOKEN`), **draw that**. Do not look it up in Horizon JSON.
2. Horizon JSON is only for chrome Horizon invented: card headers, Settings copy, “NO AFFLICTIONS”, “EXTENDED FAVORITES”, reaction titles LIKED/BUSY, F11 tabs.
3. Keep `GlobalFunc.SetText` + `hzsTrC` memoization. Do not add a second translator.
4. Header style (`hzHdrCase` / `hzUC`) still runs on Horizon chrome **after** lookup, so German translators can ship already-cased strings and we document whether the movie will upper-case them. **Recommendation:** do not `toUpperCase()` translator strings in v1 for CJK; keep the current caps style for Latin only (`hz43EnvLang` already knows `ja`/`zhhans`). Cost: a language branch at **build** time, not per frame.

---

## 8. Fonts, Exo 2, CJK

### Exo 2 stays for Latin

FOMOD default: `fonts_horizon.swf` + `fontconfig_en.txt`. FontFace 1 is Exo 2 (`$Horizon_Font`). That must remain the look for `en`, `de`, `fr`, `es`, `it`, `pl`.

Coverage (Google Fonts / Glyph Sleuth / Everything Fonts):

- Latin-1 + Latin Extended-A: 126/128. Missing `ŉ` and long s — unused in de/fr/es/it/pl.
- Polish ą ć ę ł ń ś ź ż: present (~99.5%).
- German ä ö ü ß: present.
- French/Spanish/Italian diacritics: present.
- Greek: essentially absent (2%).
- Cyrillic: present (not a v1 target).
- CJK / Hangul: not in Exo 2.

Sources:

- [Exo 2 language checker (Polish)](https://everythingfonts.com/font-language-checker/exo-2/polish)
- [Exo 2 — Everything Fonts](https://everythingfonts.com/font/exo-2)
- [Exo 2 · Glyph Sleuth](https://beniza.github.io/glyph-sleuth/font/exo-2/)
- [Fontsource Exo 2](https://fontsource.org/fonts/exo-2/about)

**Do not embed CJK or Hangul into `fonts_horizon.swf`.** That would bloat every Latin player’s load and fight the FOMOD “Keep my current font” path.

### Existing fallback (keep, extend)

Comms `hzcFits`: if any character code is `> 0x52F` (beyond Cyrillic), except a few punctuation marks, that line uses `$MAIN_Font` (the game face from `fontconfig_<lang>`). HUDMessages comment: “a line with characters the Horizon faces don't carry (CJK, Greek in Exo 2...) uses the game font.”

Greek is **below** `0x52F`, so Greek still hits Exo 2 and can tofu. P4 may tighten `hzcFits` (and a shared HUD helper) to treat Greek and Hangul/CJK the same. That check already runs when a **subtitle line is shown**, not per frame of an idle HUD.

**Cost vs 0.43.4:** same as today for Comms. Extending the helper to HUD/QM is one extra scan of a string **when the field is set**. **Pass** if it stays on set, not on tick.

### CJK

- Japanese / Simplified Chinese: official Steam UI languages. Game fontconfig and `fonts_<lang>` already carry the glyphs. Horizon must use `$MAIN_Font` (or `$NB_Grotesk_*`) for those languages’ Horizon chrome **or** per-string `hzcFits`.
- Per-string is better: a Japanese install still shows Exo 2 for ASCII “12:00” and game font for 日本語. That is what Comms already does.
- Korean is not a Starfield Steam interface language. v1 does not ship `ko.json`.

**P4 ships `fontconfig_de.txt` (and the other official suffixes) only if research confirms the game does not read `fontconfig_en.txt` when `sLanguage=de`.** Today the FOMOD installs **only** `fontconfig_en.txt`. That is an existing Latin-language risk, not introduced by l10n. P4 is the place to copy Horizon’s `$Horizon_Font*` mappings into each `fontconfig_<lang>.txt` (merge, do not replace the whole vanilla file blindly). Until that is proven, Exo 2 on a German install may already be falling back to the game font. **Gate:** one in-game check on `sLanguage=de` with FontFace=1 before writing extra fontconfig files.

CJK extra fonts: **off by default / out** of the core SWF.

---

## 9. Text expansion, truncation, autosize

German HUD strings run ~30% longer. Horizon already measures `textWidth` in many places. Localization must not add a per-frame measure pass.

### Policy

- Prefer wrap at the same font size (quest tracker already does this).
- Ellipsis only where the layout already ellipsizes (`hzsTrunc`, equipment name, compact pill third line).
- Do **not** shrink font on the HUD to fit German; that fights the “text size” setting.
- Settings 2.0: allow **two lines** on a row label; keep the 1260×726 cap so side HUD cards stay visible. Do not grow the window.
- Quick Menu 58 px slots: no room for words. Keep `$EMPTY SLOT` on the **info card**, plus-mark on empty extras, key chips as today (they already shrink to 8 px). Do not put “LEER” on the tile.

### Fixed-width hotspots

| Surface | Size (stage units, 1080p family) | Today | German / long-text plan |
|---|---|---|---|
| Settings 2.0 window | cap 1260 × 726 | `hz51Fit` never grows past cap | keep cap; wrap labels; 11 px help already wraps |
| Settings sidebar | 248 wide, 11 px | one-line labels | wrap or shorten keys; do not slim below 248 |
| Settings control column | `HZ51_CTRL_W` 148, dropdown 28 h | options in English caps | measure option text **when the menu opens**; widen control up to a max, then ellipsis |
| Settings compact pill in header | ~78 × 24 | “v0.43.5” | keep version ASCII |
| Vitals cards | 330 × 58 each | labels HEALTH / OXYGEN | wrap or allow the label field (150 wide) to ellipsis; bar stays |
| Horizontal vitals | 668 × 58 | same labels | more room |
| Jetpack | 330 × 72 | JETPACK / BOOST n% | same as vitals |
| Planet pill | 336 × 84 (compact 36 h) | name from game; LOCAL / GAME | LOCAL/GAME are Horizon; keep short keys |
| Compass strip | 640 × 58 + heading pill 72 × 26 | N/NE/E… | keep compass abbreviations; translators get 2-letter keys |
| Quest tracker | width 380–660, max height 100–300 | wrap on | already the right pattern |
| Character card | chips MASS / OVERWEIGHT / TO NEXT | Horizon chrome | JSON; chips grow with `textWidth` on **build** |
| Message / reaction card | 460 × 88 (compact 56) | LIKED, BUSY | titles stay short; body is game text |
| Name-hover compact pill | grows to 640, then wrap 3 lines | already wraps | game names; Horizon verbs (ACTIVATE) may be `$` already — keep |
| Vehicle exit pill | key + EXIT + hold sweep | EXIT is Horizon | short verb; pill already measures key `textWidth` on change only |
| Stealth pill | above crosshair | DETECTION n% | JSON for DETECTION |
| Watch digital / analog | lower left | digits; no words | almost nothing to translate |
| Quick Menu slot | 58 × 58 at scale 1.0 | key chip; no name on tile | no extra words |
| Quick Menu extra window | title EXTENDED FAVORITES | Horizon | JSON; title field already 13 px |
| Scope hold-breath chip | game `$Hold Breath` or Horizon chip | native token when vanilla | Horizon chip uses the game’s label when possible |

**Cost vs 0.43.4:** German will make some **build** measures return larger widths (cards grow the way the compact hover pill already grows on a long name). That is content, not a new tick. **Pass** if no new `ENTER_FRAME` measure is added. A “shrink every vitals label every frame until it fits” helper is **out**.

---

## 10. Community contributor workflow

1. Copy `docs/localization/en.template.json` (and later the full generated `en.json`) to `de.json` in `Data/SFSE/Plugins/HorizonUI/Localization/`.
2. Keep every key. Translate values only. American English source remains `en.json`.
3. Keep `{0}`, `{count}`, `{name}`.
4. Do not add `$` in front of Horizon keys.
5. Do not translate `Moragar`, product name **Horizon UI** in FOMOD branding unless the translator’s language normally localizes product names; in-game, “Horizon” in HORIZON STYLE can stay.
6. Open a PR with **only** the language file. No SWF.
7. Run `node tests/l10n_check_test.js` (P0) — missing / extra / placeholder / duplicate keys.
8. Screenshot Settings 2.0 (CARDS + SYSTEM), one HUD cluster, and Quick Menu if those keys changed.

Context for translators lives in:

- `_meta.notes` in the JSON
- optional `_comment` sibling keys (stripped by the loader)
- this plan’s hotspot table

No usernames, machine paths, or bot names in shipped files.

---

## 11. Automated checker

Match existing tests: Node, `expect()`, repo-relative paths, never the system temp folder.

**P0 file:** `tests/l10n_check_test.js`.

Checks:

| Check | How |
|---|---|
| Missing keys | every English key present in `de.json` (etc.) when that file exists |
| Duplicate keys | flatten; fail on collisions |
| Obsolete keys | keys not in English |
| Placeholder mismatch | `{…}` set must match English |
| Untranslated hardcoded strings | after P1+, Settings tabs array must not be the English literal if `hzL10n` exists; a small allowlist for `$` tokens and font names |
| JSON parse / UTF-8 | `JSON.parse` on the file bytes; reject BOM |
| File size cap | fail over the DLL cap |
| No `$HZ_` in JSON values | those are not native tokens |

Scanner draft (uncommitted): `tools/scan_l10n_strings.js` → `docs/localization/STRING_INVENTORY.csv`.

---

## 12. String inventory (this pass)

Generated from Settings 2.0 + Quick Menu sources. Canonical ActionScript only for Horizon copy; vanilla twins scanned for `$` tokens and font names.

| Kind | Count (approx.) | Notes |
|---|---|---|
| HUD / Settings labels | ~1250 | includes Settings 2.0 catalog caps, HUD chrome, some duplicates across helpers |
| Help / Setting Details | ~318 | `hz51Help` / `hz51Line` sentences |
| INI comments | ~228 | player-facing for people who edit the file; v1 optional |
| Font names | ~333 | `$Horizon_Font*`, `$MAIN_Font` — **do not translate** |
| Native `$` tokens | ~89 | keep game translation |
| Enum / dropdown options | ~94 | ALWAYS, VANILLA, CROSS + BARS, … |
| FOMOD | ~44 | installer; separate from in-game |
| DLL card titles / GMST fallbacks | ~114 | LIKED/BUSY vs matcher phrases |
| **Total rows** | **~2355** | CSV: `docs/localization/STRING_INVENTORY.csv` |

Deduped unique Horizon chrome for v1 is smaller (roughly 400–700 keys once Settings catalog `k` is the key and HUD labels are unique). P0 should generate `en.json` from the CSV with a human pass, not ship 2355 noisy keys.

**Not in repo:** Papyrus (none). Binary gfx/swf (Horizon text is AS-created).

**Quick Menu extras already in the inventory:** `Quick Menu`, `EXTENDED FAVORITES`, `$EMPTY SLOT`, `SLOT`, `EMPTY`, refuse lines (`POWERS: USE SLOTS 1-12 FOR NOW`, …), F11 rows HORIZON STYLE / EXTENDED MODE / SLOT COUNT / SLOTS PER ROW / EXTENDED LAYOUT / EMPTY SLOTS / PANEL OPACITY / SLOT SCALE / EXTENDED SLOT KEYS.

---

## 13. Performance implications (Settings 2.0 “section 13” style)

This is the bar. If a phase misses it, that phase does not ship.

1. **Insert/draw add no per-frame timers.** No `ENTER_FRAME`, `setInterval`, or 100 ms poll for language.
2. **Preset / l10n push runs only while the movie is loading or F11 is open.** Same as “preset push runs only while F11 is open.”
3. **No UI-thread file I/O.** Comms 0.43.4 hitch was file reads on hover. Localization files are read on the task thread at init only.
4. **No TextField-per-lookup.** Scanner `hzsTrC` already taught this. `hzL()` is a hash lookup on a frozen object.
5. **No extra `Invoke` on HUD/scanner/QM ticks.** One latched push per movie.
6. **No clip churn.** Do not create throwaway fields to resolve Horizon keys.
7. **F11 search index** is still built on open and dropped on close. It indexes translated labels. Cost is the same class as today, slightly more UTF-8 bytes for German.
8. **Language change** is not live. Restart. No dirty-flag refresh storm.
9. **CJK `hzcFits`** stays a per-**setText** scan, never per frame of a static card.
10. **Quick Menu** stays edge-driven (open, data, selection, assign, device). Extended window title is set on that edge.
11. **Watch** still writes on minute change / style change only. No new words every frame.
12. **Anything that cannot meet 1–11 is off by default or out.**

---

## 14. Phased plan

### P0 — Infrastructure

**Goal:** load, cache, push, check. English-only behavior identical to today if overlay files are missing.

**Work**

- `src/hz_l10n.h` (new): file load, flatten, overlay, language map, size cap, one log line
- `src/main.cpp`: call from the existing post-load task path next to `HzMsgPrepare`; `PushL10n` next to `PushDllFileVersion`
- AS: `hzSetL10n` / `hzL()` on HUDMenu (`horizon_block.as`); stubs that no-op if the payload is empty
- `Interface/HorizonUI/HorizonUI.default.ini`: `[General] Language=auto` comment
- Ship `en.json` (full) and empty overlays or omit overlays until translators arrive (missing file = English)
- `tests/l10n_check_test.js` + a small C++ unit test of overlay/fallback (same harness style as `tests/preset_list_test.cpp`)
- FOMOD: install the Localization folder with Core

**Affected files:** `src/main.cpp`, new `src/hz_l10n.h`, `actionscript/horizon_block.as` (and splice sources `hz51_insert.as` / `hz51_draw.as` if those remain the edit surface), `actionscript/HUDMenu_1.as` twins only after the block splice, `xmake.lua` only if a new cpp is added (prefer a header-only helper like other `hz_*.h`), `fomod/ModuleConfig.xml` (Core folder list), `Interface/HorizonUI/HorizonUI.default.ini`, `tests/*`, `Data/SFSE/Plugins/HorizonUI/Localization/en.json`

**Performance vs 0.43.4:** init read + one latched Invoke. HUD ticks unchanged if `hzL()` is not called from them yet. **Pass.**

**Risks:** JSON tokenizer bugs; pushing a huge string into Scaleform (keep flat, cap size); path resolution on Vortex vs portable installs (resolve relative to the DLL, not a user home path).

**Effort:** one new header, one push site, one AS receiver, tests, English table scaffolding. Medium.

---

### P1 — Settings 2.0

**Goal:** every F11 string players read comes from the table. Language dropdown. Search indexes translated labels.

**Work**

- Catalog `l`, `h`, `g`, `s`, `opts`, `btn` through `hzL("settings.<k>.label")` with English fallback argument equal to today’s literal (so a missing key still draws)
- `hz51Help` / `hz51Line` / `hz51HelpMore` return `hzL("settings.<k>.help")`
- Tabs `HZ_SET_TABS` from the table
- Footer KEYBOARD / CONTROLLER hints
- SYSTEM → LANGUAGE row; writes `Language=`; note restart; do not call PushL10n again
- Live Preview sample strings (“Ask about the job”, FLORA, EXO 2) in the table
- Tests: `tests/settings2_test.js` and friends assert keys exist, not English-only literals; keep “section 13” expects (`!ENTER_FRAME`, search index dropped on close)

**Affected files:** `actionscript/horizon_block.as`, `actionscript/hz51_insert.as`, `actionscript/hz51_draw.as`, `tools/patch_settings2.js` / `.py` if those still splice, `tests/settings2_*.js`, `en.json`

**Performance vs 0.43.4:** F11 is not the HUD hot path. Extra property reads while the window is open only. Search index still on open/close. **Pass.** German two-line labels: measure on F11 draw only (already draws on input). **Pass.**

**Risks:** help strings with quotes/newlines; search matching German case; sidebar 248 px overflow. Mitigate with wrap, not a wider window.

**Effort:** large string move, small logic. The catalog is data; keep `k` as the stable id.

---

### P2 — HUD cards

**Goal:** Horizon chrome on vitals, compass letters, planet LOCAL/GAME, character chips, stealth, vehicle EXIT, watch (if any words), XP toast, mission toast header, reaction titles.

**Work**

- Replace literals at **card build** (`hzBuildVitNew`, planet pill, compass `HZ_CARD`, character chips, stealth, vehicle pill, message card titles)
- Cache the resolved string on the card object (`this.hzVnLab[0] = hzL("hud.health","HEALTH")`) so ticks only assign `tf.text = cached` when the value changes (health numbers stay numbers)
- Keep game names and `$` prompt verbs
- Tests: `tests/pill_wrap_test.js`, `quest_wrap_test.js`, `lock_label_test.js` still pass; add “build uses hzL, tick does not call hzL”

**Affected files:** `actionscript/horizon_block.as` (large but localized to build functions), `src/hz_msg_match.h` / `hz_msglog.h` only for LIKED/BUSY **display** titles if those are still hardcoded in C++ — prefer AS-side titles from JSON so the DLL keeps matching English/GMST phrases

**Performance vs 0.43.4:** **Fail if** `hzL` is called from vitals/compass ticks. **Pass if** lookup is in `hzBuild*` / first show. Compass letters are eight strings; resolve once when the compass is built.

**Risks:** 330 px vitals; compact strips; German HEALTH. Use the existing label field width and ellipsis helper already used for equipment names, on build.

**Effort:** medium–large (many build sites, each must be proven tick-free).

---

### P3 — Modules (Quick Menu, scanner Horizon copy, Comms chrome, Scope)

**Quick Menu (covers `wip/0.43.5-quickmenu-fix`)**

- Header “Quick Menu”, “EXTENDED FAVORITES”, refuse toasts, info-card row tags SLOT / AMMO / DAMAGE if Horizon-owned (item name stays `$EMPTY SLOT` / `sName`)
- Push `hzqSetL10n` on FavoritesMenu open (movie load edge)
- Extra chip / window title stay edge-drawn
- Tests: `tests/quickmenu_*.js`, `quickmenu_qmfix_test.js` — no per-frame lookup; Extended window still edge-only

**Scanner**

- Horizon words: UNKNOWN SIGNAL, YOUR SHIP, YOUR VEHICLE, FLORA (preview), mode pill labels Horizon added
- Bioscan types and marker names stay `hzsTr` / `$`
- `hzsTrC` unchanged

**Comms / Dialogue**

- SAID chip, persuasion chip text Horizon added, N MORE, button-bar restyle labels
- Subtitle **body** and speaker **names** stay game-localized
- `hzcFits` still chooses the face per line

**Scope**

- Prefer the game `$Hold Breath` when showing vanilla; Horizon chip should display the **already translated** vanilla label, not a new English “HOLD BREATH”

**Affected files:** `actionscript/favorites/hzq_main.as` (+ `pimp_favoritesmenu*.as` after splice), `actionscript/scanner/hzs_block.as` (+ Monocle twins after splice), `actionscript/comms/hzc_block.as`, `hzd_block.as`, `actionscript/scope/hzp_main.as`, matching tests, FOMOD unchanged except Localization already in Core

**Performance vs 0.43.4:** Quick Menu is already “updated only on an edge.” Adding a latched table push on open is the same class as reading INI on open today. Scanner must not resolve Horizon keys in the marker-move path. **Pass** with the same edge/build split as P2.

**Risks:** Favorites movie unload/reload — latch per instance, not process-wide, or push every open (still once per open, no file I/O). Conflict with other favorites mods: if Quick Menu is not installed, no push.

**Effort:** medium per module; Quick Menu is the one that must land with Settings 2.0.

---

### P4 — Fonts / CJK / expansion pass

**Goal:** Latin keeps Exo 2; Japanese/Simplified Chinese readable without SWF bloat; German layouts signed off.

**Work**

- Shared `hzFitsFace(s)` (today’s `hzcFits`) on HUD and Quick Menu set-text helpers
- Optional: skip `toUpperCase` for `ja`/`zhhans`
- Research gate: `fontconfig_<lang>.txt` for official languages (merge `$Horizon_Font*` only)
- No CJK glyphs in `fonts_horizon.swf`
- Layout pass on the hotspot table with German `de.json` (can be a stub 30% longer English for tests)
- Do not ship Korean or Greek tables; they are not Steam interface languages for Starfield

**Affected files:** font helpers in each movie, FOMOD font optional files, tests for `hzFitsFace`, maybe `planet_alert_test.js` font-face expects

**Performance vs 0.43.4:** per-set character scan is already on Comms. Extending it is **Pass** on set-text. Embedding CJK in the SWF is **out**. A per-frame glyph probe is **out**.

**Risks:** `fontconfig_de.txt` overwrite fights other font mods (same as today’s `fontconfig_en.txt` warning). Document it. Greek tofu until `hzFitsFace` treats Greek as fallback.

**Effort:** medium, gated on one in-game German fontconfig check.

---

### Out of v1 / later

- FOMOD installer localization (Vortex/MO2 language)
- Full INI comment translation
- Shipping `it.json` / `ja.json` / `pl.json` / `pt-br.json` when translators arrive (stems and fallback already exist; missing file is English). `es.json`, `es-mx.json`, and `fr.json` are shipped.
- Live language switch without restart
- Native `$HZ_` export
- Papyrus (none)

---

## 15. Security review

| Risk | Severity | Notes | Fixed in this plan? |
|---|---|---|---|
| JSON file from another mod, huge or hostile | Medium | Size cap, UTF-8, no eval, existing `JsonTok` (no comments that execute) | Design: cap + flatten strings only |
| Path traversal in Language= | Low | Allowlist of codes; no user path concatenated from the INI value | Design: allowlist |
| XSS-like Scaleform htmlText | Low | Horizon uses `.text`, not untrusted HTML | Keep `.text` |
| Logging PII / full translated lines | Low | Log key counts and language code, not values | Design |
| Overwriting `translate_en.txt` | High if we had chosen native tables | Would fight other UI mods | **Avoided** by JSON in the plugin folder |

No administrative surface is added. Language is a cosmetic INI key.

---

## 16. Test impact analysis

**Systems:** SFSE plugin init, HUDMenu, Settings 2.0, FavoritesMenu, scanner overlay, Comms, Scope, FOMOD Core files.

**Not affected if P0–P3 stay off the tick:** compass heading math, hover follow, scanner marker move, watch second hand, message fade.

**Recommended tests**

- `node tests/settings2_test.js` and `settings2_round_h_test.js` (section 13)
- `node tests/quickmenu_test.js`, `quickmenu_qmfix_test.js`, `quickmenu_ext_window_test.js`
- `node tests/scanner_perf_0434_test.js`, `scanner_safe_set_test.js` (translation cache still once per open)
- `node tests/lock_label_test.js` (`$` keys still resolved by the game)
- `node tests/pill_wrap_test.js`, `quest_wrap_test.js`
- New: `node tests/l10n_check_test.js`
- In-game: English unchanged; `Language=de` with a stub file; `Language=auto` on a Japanese install for `$` item names + Horizon fallback font; Quick Menu `$EMPTY SLOT`; F11 search in German

**Regression risks**

- Accidental `hzL` on a HUD tick
- Double `toUpperCase` on CJK
- Replacing `$EMPTY SLOT` with English EMPTY
- Settings window growing past 1260
- Fontconfig fights
- Vortex missing the Localization folder

---

## 17. Rollback

- Remove `Localization/*.json` except `en.json`, or set `Language=en` and restart → English chrome, game language still used for items.
- Revert the DLL/AS push sites; literals remain as fallback arguments to `hzL(key, "HEALTH")` so a bad table never blanks the HUD.
- Font changes (P4) roll back by using FOMOD “Keep my current font.”

---

## 18. What this planning pass is

Worktree on `feature/settings-2.0` with Quick Menu strings included from that tree’s `hzq_main.as` (Extended Mode + extra window), which matches the Quick Menu fix branch’s player-facing copy.

Delivered here:

- `docs/localization/LOCALIZATION_PLAN.md` (this file)
- `docs/localization/STRING_INVENTORY.csv`
- `docs/localization/en.template.json`
- Uncommitted drafts: `tools/scan_l10n_strings.js`, `tools/l10n_check_test.draft.js`

No ActionScript, C++, SWF, or INI gameplay defaults were changed in the mainline branches.

---

## 19. Recommendation (short)

Use the **DLL JSON cache**, not native `translate_*.txt`, for Horizon chrome. Keep native `$` and GMSTs for the game. One init read, one batch push per movie, lookups only when UI is built. Language follows the game, with an F11/INI override that **reloads the table once**. Exo 2 stays for Latin; CJK uses the game font per line; do not bloat SWFs. Settings 2.0 first (most strings, not the HUD tick), then HUD chrome, then Quick Menu and other modules, then fonts. Starfield Steam languages only (no Korean, no Greek).
