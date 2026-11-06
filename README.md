# Horizon UI for Starfield

![Status: alpha](https://img.shields.io/badge/status-alpha-orange) ![Game: Starfield PC](https://img.shields.io/badge/game-Starfield%20PC-blue) ![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-green)

> **Alpha:** Horizon UI is in public testing before 1.0. Things may still change between builds. Your settings carry over in `HorizonUI.user.ini`.

Horizon UI is an adaptive, dynamic, customizable and modular HUD replacement for Starfield. It uses translucent pill cards in Exo 2, with a cyan accent by default, and you set everything up live in game with F11.

This repository holds the source of **`HorizonUI.dll`**, the SFSE plugin that powers the mod. The HUD itself ships as interface files in the release downloads.

## Features at a glance
- **Adaptive:** every card has its own visibility rule, so cards appear when they matter. Warnings react to your health and oxygen, and the Planet card lights up in hazards.
- **Dynamic:** cards update live, including XP, carry weight, ammo, the Starborn power meter, and two clocks (in-game time and your real PC time). You also get combat feedback and live previews in F11.
- **Customizable:** more than 100 settings, Arrange Cards and Arrange Scanner to move anything (the scope's hold-breath chip included), a vertical or horizontal Vitals card, colors, fonts, sizes, and presets you can save and switch.
- **Modular:** a core HUD plus optional **Horizon Font**, **Comms** (subtitles, dialogue and companion reactions), the **Message Log** (a searchable history of your HUD messages), the optional **Scanner**, Horizon's own hand scanner screen, and the optional **Scope** module, a Horizon hold-breath chip for weapon scopes. Core is always installed; the modules are optional parts of the same FOMOD installer and need Core.

## New in 0.43.1.0 (alpha, unreleased)

This build is not published and has no release tag. Install steps below still describe the published 0.43.0.33 download.

- **Watch** (F11 > CARDS > WATCH): Off (default, same as today), Vanilla, Vanilla + Horizon (your card color and accent), Horizon Digital, or Horizon Analog. Vanilla is the game's watch. Vanilla + Horizon tints that same watch and does not add a second planet name. Both Horizon faces are round, with no card behind them and no planet art. Digital is a segmented O2 / CO2 ring (O2 clockwise from 7 o'clock, CO2 counter-clockwise from 5 o'clock, empty segments gray), a top compass arc, local and PC time in the center with the labels above the times, and the planet name and temperature. It has no day dial. Analog uses those arcs flush on the rim, the same top-arc compass as digital, white hour and minute hands, a gold hub, and the day dial at 6 o'clock. Move any watch face in Arrange Cards. Styles 1 and 2 move the game's watch as one piece, including the top bar, and leave the character card and the other lower-left alerts where they are. Horizon Digital and Analog keep the live nearby markers on the Horizon face. `WatchX` and `WatchY` save that spot, and `-1` is the lower-left home. `WatchScale` sets the size. Until you save a spot, a showing card in that corner lifts the watch above the card. A saved spot stays put. The face does not label its own place on the screen.
- **Crosshair** (F11 > RULES > CROSSHAIR): Always (default), Weapon drawn, or Off. Only the aiming dot or reticle is gated, and it stays gated when you look at a person or a target. The center interact ring and its glyph stay, including while the weapon is holstered and while the rule is Off. Iron sights are left to the game. Prompts, target cards, hit markers, the kill X, the damage ring, and the stealth pill stay. Crosshair Style is a separate setting.

## New in 0.43.0.33 (alpha)
- **Moragar's Choice** matches the author's current in-game layout, including the scanner card positions. The source file is `preset/HorizonUI.moragars-choice.ini`. The installer still places it at `Interface\HorizonUI\presets\moragars_choice.ini`.

## New in 0.43.0.32 (alpha)
- **Compact name pill:** verbs such as Use and Recycle always show in full. A long name is the part that shortens, and the pill grows as needed so verbs are never cut. The accent name and the red steal name are unchanged.
- **SCANNER and COMMS:** the module status box starts collapsed every time F11 opens. The chevron still expands it.
- **Welcome intro switch:** F11 > EFFECTS > **WELCOME INTRO** turns the save-load intro on or off. It uses the existing `[UI] StartupIntro` setting (`1` on, `0` off). The ini key still works, and off still logs that the intro was skipped.

## New in 0.43.0.31 (alpha)
This covers everything since 0.42.0.13. The full list is in [CHANGELOG.md](CHANGELOG.md).

- **Message Log (new, optional):** a searchable history of the messages Horizon shows on your HUD. Open it from **F11 > CONTROLS > MESSAGE LOG > OPEN**. See [Message Log](#message-log) below.
- **Comms module (subtitles and dialogue):** Comms gives you Horizon subtitles and the Horizon dialogue menu together. It replaces any dialogue menu mod, such as Enhanced Dialogue Interface, so uninstall that mod first. In F11, the **COMMS** tab now has a full-width **SUBTITLES / DIALOGUE** selector at the very top. Pick the one you want to edit; the settings under it change only that page.
- **Compact vitals card:** the new **HEALTH AND O2 BARS** setting (F11 > CARDS) can be **FULL** (the separate cards, still the default) or **COMPACT**. COMPACT shows boost, health and oxygen together on the same merged card that **COMPACT MODE** uses. That card follows your jetpack and vitals show rules, and **ARRANGE CARDS** can move it whenever either compact setting is on.
- **Compact name hover (now the default):** the name you look at shows as a slim one-line card with an icon, the name and the key. The name is drawn in your accent color, and in red when the prompt is for stealing. The taller card is still there: F11 > CARDS > **NAME HOVER** > **FULL**. Moragar's Choice uses Compact.
- **Welcome intro:** after you load a save, Horizon plays a short welcome: the HORIZON UI wordmark, one star sweep of about 2 seconds, then a line with the name of your loaded preset. It's drawn in your accent color with no panel, ends at about 6 seconds, never pauses the game and never takes input. It plays after a save load only, not on fast travel. Turn it off with **WELCOME INTRO** in F11 > EFFECTS, or with `StartupIntro=0` under `[UI]` in `HorizonUI.user.ini`.
- **Boost row reflow:** when the boost row on the merged card is hidden (for example, when boost is full under the default jetpack rule), the card closes up around the rows that remain.
- **More card looks in F11 > STYLE:** **CARD BACKGROUND %** (0 is clear, 100 is solid), **CARD SHADOW %** and **SETTINGS WINDOW %** (how see-through the F11 window is). These settings map straight to opacity. At the defaults, cards on dark card colors look a little more solid than in 0.42, and cards on light card colors a little lighter.
- **More messages become cards (Comms):** other notices the game shows get a generic **GAME** card, and a notice that contains Artifact gets an **ARTIFACT** card. A notice longer than 200 characters shows shortened with "..." on the card; the Message Log keeps up to about 256 characters of it. These use the same **COMPANION REACTION CARD** switch in F11 > COMMS (SUBTITLES page).
- **Other fixes:**
  - F11 opens and closes more reliably (one press opens it, the next closes it), and it lets go cleanly when a full-screen menu such as the character screen covers the HUD.
  - The TAKE card's key letter and HOLD text stay at least 13 px, and the jetpack card keeps its gap above Vitals.
  - The Message Log never deletes files, retries a failed save, and never replaces an existing log with an empty one.
- **New settings** (all start at their defaults when you update): `[Cards]` `NameHover` (`0` = compact, `1` = full) and `VitalsBars` (`0` = full, `1` = compact); `[Style]` `CardBgOpacity` (`92`), `CardShadow` (`12`) and `SettingsOpacity` (`93`); `[UI]` `StartupIntro` (`1`); and the new `[MessageLog]` section with `Record` (`1`), `LogTypes`, `HistorySize` (`500`), `Persist` (`1`) and `MissedBadge` (`1`, reserved: nothing is drawn for it yet).

### Known issues
- An arranged compact card near the bottom of the screen can shift when the boost row hides.
- The welcome intro may sit slightly left of center.
- Still true from 0.42.0.13: the blue quest diamond in the world and on the HUD compass uses the game's own style; the companion reaction card recognizes only English game text and names of up to 4 words; and the Scope chip's HOLDING BREATH label is inferred from your O2 going down, so it can show whenever O2 is draining.

### Planned (not released)
Inventory and Ship UI modules are planned. They aren't in this build or in any release yet.

## Message Log
The Message Log is a history of the messages Horizon shows on your HUD, so you can read one again after it fades.

- **Open it:** F11 > CONTROLS > **MESSAGE LOG** > **OPEN**. It opens from the keyboard only; a controller can move around once it's open. If the row is grayed out and reads "needs Notifications", the installer's Message Log option isn't installed.
- **Start empty:** The Message Log starts empty and records messages from the moment it's enabled. Messages from before you installed Horizon UI can't be recovered.
- **Message types:** Medical, Crew, Reactions (companion reactions), Busy, Crime, Credits, Quest, Location, Game and XP. Quest, Location and XP messages come from the Comms module, so they're recorded only when Comms is installed. "CALMED" lines aren't saved.
- **Filters:** a chip for each type, with a count, shows or hides that type in the log. Hiding a type this way doesn't delete anything.
- **Search:** the find box at the top filters the log as you type. Press **/** to jump to it.
- **ALL TIME:** on shows everything stored for the character; off shows only this play session.
- **Pins:** **PIN** (or **UNPIN**) keeps the selected message at the top, up to 50 pins. Pins sit on top of your history size, so history never pushes them out.
- **CLEAR SESSION:** removes the unpinned messages of this play session that are showing, after you confirm.
- **SETTINGS** (inside the log): **RECORD MESSAGES**, **SAVE TO DISK**, **FOLDER** (shown when SAVE TO DISK is off), **HISTORY** (100 to 1000 messages, in steps of 100, 500 by default), a switch for each message type, and **OLD CHARACTERS** (the log files of other characters).
- **Recording:** message types you turn off are never recorded. They still show on screen as usual. To stop recording completely, turn off **RECORD MESSAGES** or set `Record=0` under `[MessageLog]` in `HorizonUI.user.ini`.
- **History per character:** one file per character (not per save) in `Documents\My Games\Starfield\SFSE\HorizonUI\MessageLog\`, named `MessageLog_<character>.json`. The character is a hex ID, not your character's name. A new game plus that changes the character ID starts a new log.
- **Save to disk off:** `Persist=0` keeps the log in memory only, so nothing survives a restart. It only stops writing; Horizon UI never deletes files, and existing log files stay where they are.
- **Earlier saves:** if you load an earlier save, the messages from the later point are kept and shown dimmed, with "from a later point". The history size still drops the oldest unpinned messages.
- **Privacy:** the places and real-world times saved with each message stay on your PC.

## Requirements
- **Starfield** (PC). Tested on game version 1.16.244.
- **[Starfield Script Extender (SFSE)](https://sfse.silverlock.org/)** for that game version. SFSE isn't included, so install it separately and launch with `sfse_loader.exe`.
- **[Address Library for SFSE Plugins](https://www.nexusmods.com/starfield/mods/3256)** for that game version (required). It isn't included; `HorizonUI.dll` needs it to load.
- **Horizon UI Core**, always required. The FOMOD (`HorizonUI-0.43.0.33-FOMOD.zip`) installs it automatically; Comms, the Message Log, the Scanner and Scope are optional modules inside it, not separate mods. They all need Core's `HorizonUI.dll`, settings files, F11 menu and HUD.
- **Loose files enabled** in `Documents\My Games\Starfield\StarfieldCustom.ini` (create it if missing):

  ```ini
  [Archive]
  bInvalidateOlderFiles=1
  sResourceDataDirsFinal=
  ```

  Without this, Starfield ignores loose interface files and you'll see the vanilla HUD.

## Install
Download the one **FOMOD installer**, `HorizonUI-0.43.0.33-FOMOD.zip`, from [Releases](https://github.com/moragar360/HorizonUI-Starfield/releases), and install it with Vortex or Mod Organizer 2. **Core** (the HUD, the settings files, the F11 menu and `HorizonUI.dll`) is always required and installs automatically. The installer then walks you through Font, Settings Preset and the optional modules: Comms (subtitles and dialogue), Scanner, Scope and Message Log. Those modules are part of the same download, not separate mods, and they need Core.

**Scope:** the Scope module changes the scope view and is ticked by default. If you use another scope mod, untick Scope.

**Comms:** Comms replaces subtitle mods (such as Enhanced Subtitles) and dialogue menu mods (such as Enhanced Dialogue Interface). Uninstall yours first. **StarUI HUD** replaces the same HUD file as Horizon UI, so uninstall it too.

**Updating from 0.42.x:** install 0.43.0.33 over your existing Horizon UI. Your `HorizonUI.user.ini` and saved presets are kept, and the new settings start at their defaults. The name hover is now Compact by default; to get the taller card back, choose **FULL** under NAME HOVER in F11 > CARDS. In Vortex, an update reuses your earlier installer choices; to change them, right-click the mod and choose Reinstall.

For a manual install, extract the zip and copy the contents of its `00 Core` folder into `Data\`, then the folders of any parts you want (`01 Horizon Font`, `02 Preset - Moragars Choice`, `10 Comms`, `11 Comms Dialogue`, `20 Scanner`, `30 Scope`, `40 Notifications` for the Message Log). Skip the `fomod` folder, and don't create `HorizonUI.user.ini` yourself; F11 makes it.

## Tip: the COMMS tab in F11
Subtitles and dialogue share one tab in F11. At the top of the **COMMS** tab, a full-width **SUBTITLES / DIALOGUE** selector switches between the two pages. The settings below it change only the page you've picked, so check which one is selected before you edit.

## Accessibility: ships in the scanner
In the Horizon Scanner's Signals list, ship ownership is shown by the row label and icon as well as color (YOUR SHIP, YOUR VEHICLE, Companion ship), so colorblind players can tell them apart.

## What the plugin does
`HorizonUI.dll` is a small SFSE plugin that runs alongside the HUD's interface files:
- **F11 live settings window:** opens the settings menu from your key (F11 by default, rebindable) and handles its input. It opens from the main HUD only (not inside the hand scanner, and pulling out the scanner closes it) and stays closed in full-screen game menus like the inventory, starmap, builders, dialogue, the mission board and books, and while you aim down a scope or inspect an item. It also passes the **+** key on to Arrange Cards, for the scope chip's size.
- **Mouse wheel** support in Horizon's menus.
- **Settings files:** reads the shipped `HorizonUI.default.ini` and your `HorizonUI.user.ini`, saves changes safely, and keeps one backup per update (`HorizonUI.user.bak.ini`).
- **Presets:** lists, applies, saves, hides, and undoes presets in `Interface\HorizonUI\presets\` (your own go in `presets\user\`). Remove from list hides a saved preset; the file stays in `Data\Interface\HorizonUI\presets\user\`. Horizon UI never deletes files.
- **Message Log:** records your HUD messages per character, keeps the history and your pins, and writes them to disk safely. It never deletes files.
- **Welcome intro:** tells the HUD when a save is loading so the intro can play after the load. Turn it off with WELCOME INTRO in F11 > EFFECTS, or with `StartupIntro=0` under `[UI]`. Off still logs that the intro was skipped.
- **Scanner state:** tells the HUD and Comms while the hand scanner is open, so they stay hidden for the whole scan, even while you switch scanner tools.

Plugin log file: `Documents\My Games\Starfield\SFSE\Logs\HorizonUI.log`

## Building from source
**Requirements**
- Windows with **Visual Studio 2022** (MSVC, C++23)
- **[xmake](https://xmake.io)** 3.0.0 or newer
- **[CommonLibSF](https://github.com/libxse/commonlibsf)** (libxse), built against commit `9d090c4`, included as a git submodule in `lib/commonlibsf`. Clone with `git clone --recurse-submodules https://github.com/moragar360/HorizonUI-Starfield`

**Build**
1. Open a **Developer PowerShell for VS 2022** in the repo folder.
2. Run:

   ```powershell
   xmake f -c -y -m releasedbg
   xmake build -y
   ```

3. The plugin is written to `build\windows\x64\releasedbg\HorizonUI.dll`.

Copy it to `Data\SFSE\Plugins\` and check the log for `HorizonUI 0.43.0.33 loaded`.

### Debug traces (developers)
Release builds keep the extra debug traces off: `HZ_HUD_MSG_CAPTURE` is `0`, `HZ_COMMS_MSG_LOG` is `0`, `HZC_MSG_LOG` is `false` and `hzcRxDbgOn` defaults to `false`. The one-line `comms reaction:` status and the one-time `comms reaction selftest:` lines stay on. To turn the traces back on for an in-game check:

1. `src/hz_version.h`: set `HZ_HUD_MSG_CAPTURE` to `1` for the unfiltered `hud capture:` line.
2. `src/hz_version.h`: set `HZ_COMMS_MSG_LOG` to `1` for the `hud message:` line and the `comms msg:` lines.
3. `actionscript/comms/hzc_block.as`: set `HZC_MSG_LOG` to `true` for the movie's verbose queue.
4. In that same file, change the `hzcRxDbgOn` default from `false` to `true`.
5. Update the test pins that expect the traces to be off: `tests/reaction_match_test.js` (`HZC_MSG_LOG` is `false`) and `tests/preset_list_test.cpp` (`HZ_COMMS_MSG_LOG == 0` and `HZ_HUD_MSG_CAPTURE == 0`).

`Debug=0` in the ini only stops the movie queue. It doesn't turn off the one-line status. The settings schema stays `0.42.0`.

## Repository layout
```
src/main.cpp      plugin source
src/pch.h         precompiled header
lib/commonlibsf   CommonLibSF (git submodule)
xmake.lua         build script
res/HorizonUI.rc.in  version resource template (file version, company and copyright)
LICENSE           GPL-3.0
EXCEPTIONS        modding exception to the GPL
```

The `actionscript/` folder includes Horizon's own scripts and, under `actionscript/imp/` and `actionscript/scope/imp/`, decompiled ActionScript from Starfield's interface menus (HUDMenu, DialogueMenu, HUDMessagesMenu, MonocleMenu and ScopeMenu) that Horizon builds on. Those game scripts belong to their owners and aren't covered by this repository's license. The repository doesn't include any other game files.

## License
The plugin source is licensed under the **GNU General Public License v3.0** (see `LICENSE`). Like CommonLibSF, it includes the modding exception in `EXCEPTIONS`.

## Credits
- **Author:** [moragar](https://www.nexusmods.com/profile/moragar)
- **Exo 2** by Natanael Gama, and **Roboto** by Christian Robertson (with ParaType and Font Bureau). Both are licensed under the SIL Open Font License 1.1 and ship in the Font package.
- **SFSE team**, for the Starfield Script Extender
- **CommonLibSF** contributors ([libxse/commonlibsf](https://github.com/libxse/commonlibsf))
- **AEGIS** by [Jaderay](https://www.nexusmods.com/profile/jaderay?gameId=4187) (no longer publicly listed): thanks for showing how the scanner's data works. Horizon includes none of its code or art.
- **HONKCORE** by beepcmyk: thanks for showing how the scanner's data works. Horizon includes none of its code or art.
- Game icons (weapon outlines, Starborn powers) are loaded from your game at runtime and aren't bundled.

## Links
- Nexus: link coming with the Nexus release. Author profile: [moragar](https://www.nexusmods.com/profile/moragar)
- Bugs and feedback: [GitHub Issues](https://github.com/moragar360/HorizonUI-Starfield/issues)
