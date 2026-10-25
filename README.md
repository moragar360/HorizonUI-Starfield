# Horizon UI for Starfield

![Status: alpha](https://img.shields.io/badge/status-alpha-orange) ![Game: Starfield PC](https://img.shields.io/badge/game-Starfield%20PC-blue) ![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-green)

> **Alpha:** Horizon UI is in public testing before 1.0. Things may still change between builds. Your settings carry over in `HorizonUI.user.ini`.

Horizon UI is an adaptive, dynamic, customizable and modular HUD replacement for Starfield. It uses translucent pill cards in Exo 2, with a cyan accent by default, and you set everything up live in game with F11.

This repository holds the source of **`HorizonUI.dll`**, the SFSE plugin that powers the mod. The HUD itself ships as interface files in the release downloads.

## Features at a glance
- **Adaptive:** every card has its own visibility rule, so cards appear when they matter. Warnings react to your health and oxygen, and the Planet card lights up in hazards.
- **Dynamic:** cards update live, including XP, carry weight, ammo, the Starborn power meter, and two clocks (in-game time and your real PC time). You also get combat feedback and live previews in F11.
- **Customizable:** more than 100 settings, Arrange Cards and Arrange Scanner to move anything (the scope's hold-breath chip included), a vertical or horizontal Vitals card, colors, fonts, sizes, and presets you can save and switch.
- **Modular:** a core HUD plus optional **Horizon Font** and **Comms** (subtitles, dialogue and companion reactions) modules, the optional **Scanner**, Horizon's own hand scanner screen, and the optional **Scope** module, a Horizon hold-breath chip for weapon scopes. Core is always installed; the modules are optional parts of the same FOMOD installer and need Core.

## New in 0.42.0 (alpha)
- **Vitals layout:** the Vitals card can stack health above O2 (VERTICAL, as before) or put them side by side in one row (HORIZONTAL). Set it with **VITALS LAYOUT** in F11 > CARDS, or press **L** with the Vitals card selected in Arrange Cards. Small vitals readouts (healing % and CO2) raised to 13 px.
- **Companion reaction card (Comms):** a companion's reaction line (for example, "Sarah liked that.") becomes a Horizon card in the same spot, with the companion's name, the reaction in its own color and a small up or down arrow icon. With card backgrounds off (**CARD BACKGROUND** off, as in Moragar's Choice), it shows as outlined text with the arrow icon and no pill. It's on by default; turn it off with **COMPANION REACTION CARD** in F11 > COMMS (SUBTITLES page). It only recognizes the English game text for now, and only names written as Capitalized Names of up to 4 words; any other line stays the game's own.
- **Scope (new optional module):** the scope's hold-breath prompt becomes a Horizon chip with a target icon, the label and an O2 meter; the key is no longer shown. The meter turns yellow (amber) below 35% O2 and red below 15%, the same levels as the Vitals card. Move it and change its size in Arrange Cards (drag, arrow keys, **-** / **+**). At the bottom of F11 > CARDS, under SCOPE (shown when Scope is installed), **SCOPE: HOLD-BREATH CHIP** turns it on or off, **CHIP SIZE** sets its size and **RESET** puts it back at the game's spot and size. If you use another scope mod, leave Scope unticked.
- **Behavior change from 0.41.0: F11 now opens from the main HUD only (no longer over the scanner).** This is an intended change, not a bug: it doesn't open while the scanner is open, and opening the scanner closes the settings window. It also stays closed in more menus, including dialogue, the mission board, books, waiting, while you aim down a scope and while you inspect an item.
- **Fixes:** going from Arrange Cards to the scanner no longer leaves cards on screen; the Scanner recognizes your parked ship more reliably; the compact bioscan strip no longer cuts its counts short at large text sizes.
- **New settings** (all start at their defaults when you update): `[Cards] VitalsLayout` (`0`), `[Comms] ReactionCard` (`1`), and the new `[Scope]` section with `ScopeHoldBreathChip` (`1`), `ScopeChipX` (`0`), `ScopeChipY` (`0`) and `ScopeChipScale` (`1`). The full list is in the release notes.

## Requirements
- **Starfield** (PC). Tested on game version 1.16.244.
- **[Starfield Script Extender (SFSE)](https://sfse.silverlock.org/)** for that game version. SFSE isn't included, so install it separately and launch with `sfse_loader.exe`.
- **[Address Library for SFSE Plugins](https://www.nexusmods.com/starfield/mods/3256)** for that game version (required). It isn't included; `HorizonUI.dll` needs it to load.
- **Horizon UI Core**, always required. The FOMOD (`HorizonUI-0.42.0-FOMOD.zip`) installs it automatically; Comms, the Scanner and Scope are optional modules inside it, not separate mods. Comms and the Scanner need Core's `HorizonUI.dll`, settings files, F11 menu and HUD, and Scope takes its settings and style from Core's settings files and is set up in Core's F11 menu.
- **Loose files enabled** in `Documents\My Games\Starfield\StarfieldCustom.ini` (create it if missing):

  ```ini
  [Archive]
  bInvalidateOlderFiles=1
  sResourceDataDirsFinal=
  ```

  Without this, Starfield ignores loose interface files and you'll see the vanilla HUD.

## Install
Download the one **FOMOD installer**, `HorizonUI-0.42.0-FOMOD.zip`, from [Releases](https://github.com/moragar360/HorizonUI-Starfield/releases) or from Nexus (link coming with the Nexus release), and install it with Vortex or Mod Organizer 2. **Core** (the HUD, the settings files, the F11 menu and `HorizonUI.dll`) is always required and installs automatically. The installer then walks you through Font, Settings Preset and the optional Comms, Scanner and Scope modules. Those modules are part of the same download, not separate mods, and they need Core.

**Scope and other scope mods:** Scope changes the scope view. If you use another scope mod, leave Scope unticked. It's unticked by default, but anyone can tick it.

The other files on the Releases page are the individual parts of the same build (including Moragar's Choice on its own, `HorizonUI.moragars-choice-0.42.0.ini`, which will also be offered as its own optional file when Horizon UI comes to Nexus), for manual installs or reference. For a manual install, the release notes explain how to copy the FOMOD zip's folders into `Data\`, starting with `00 Core`.

## Tip: the COMMS tab in F11
Subtitles and dialogue share one tab in F11. At the top of the **COMMS** tab, the **PAGE** selector switches between **SUBTITLES** and **DIALOGUE**. The settings below it change only the page you've picked, so check which one is selected before you edit.

## Accessibility: ships in the scanner
In the Horizon Scanner's Signals list, ship ownership is shown by the row label and icon as well as color (YOUR SHIP, YOUR VEHICLE, Companion ship), so colorblind players can tell them apart.

## What the plugin does
`HorizonUI.dll` is a small SFSE plugin that runs alongside the HUD's interface files:
- **F11 live settings window:** opens the settings menu from your key (F11 by default, rebindable) and handles its input. It opens from the main HUD only (not inside the hand scanner, and pulling out the scanner closes it) and stays closed in full-screen game menus like the inventory, starmap, builders, dialogue, the mission board and books, and while you aim down a scope or inspect an item. It also passes the **+** key on to Arrange Cards, for the scope chip's size.
- **Mouse wheel** support in Horizon's menus.
- **Settings files:** reads the shipped `HorizonUI.default.ini` and your `HorizonUI.user.ini`, saves changes safely, and keeps one backup per update (`HorizonUI.user.bak.ini`).
- **Presets:** lists, applies, saves, deletes and undoes presets in `Interface\HorizonUI\presets\` (your own go in `presets\user\`).
- **Scanner state:** tells the HUD and Comms while the hand scanner is open, so they stay hidden for the whole scan, even while you switch scanner tools.

Log file: `Documents\My Games\Starfield\SFSE\Logs\HorizonUI.log`

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

Copy it to `Data\SFSE\Plugins\` and check the log for `HorizonUI 0.43.0.1 loaded`.

### Release checklist: companion reaction log

0.43.0.1 is a pre-release dev build (Message Log P1: capture and storage, no log UI). `HZ_HUD_MSG_CAPTURE` is `0`, `HZ_COMMS_MSG_LOG` is `0`, `HZC_MSG_LOG` is `false`, and `hzcRxDbgOn` defaults to `false`. The card backup stays compiled: the queue, Poll, `hzcCardPush`, and the one-line `comms reaction:` status (including `hzcRxWhy`). The one-time `comms reaction selftest:` lines are not part of that trace. They stay on when `Debug=0`. The settings schema stays `0.42.0`.

To turn the traces back on for an in-game check:

1. `src/hz_version.h`: set `HZ_HUD_MSG_CAPTURE` to `1` for the unfiltered `hud capture:` line.
2. `src/hz_version.h`: set `HZ_COMMS_MSG_LOG` to `1` for the `hud message:` line and `CommsDbgPoll` (the `comms msg:` lines). It does not compile out the backup.
3. `actionscript/comms/hzc_block.as`: set `HZC_MSG_LOG` to `true` for the movie's verbose queue.
4. In that same file, change the `hzcRxDbgOn` default from `false` to `true`.
5. Update the test pins that expect the traces to be off: `tests/reaction_match_test.js` (`HZC_MSG_LOG` is `false`) and `tests/preset_list_test.cpp` (`HZ_COMMS_MSG_LOG == 0` and `HZ_HUD_MSG_CAPTURE == 0`).

`Debug=0` in the ini only stops the movie queue. It does not replace this list, and it does not turn off the one-line status. The settings schema stays `0.42.0`.

## Message Log (planned, not released)

0.43.0.1 is Message Log P1: capture and storage only. There is no log popup yet.

- The log starts empty. It records only while `Record=1` and only the types in `LogTypes`.
- It cannot recover messages from before install, or from while Record was off.
- One file per character (not per save) under `Documents\My Games\Starfield\SFSE\HorizonUI\MessageLog\`. NG+ that changes the character key starts a new log.
- `Persist=0` keeps the log in memory only: no folder, no file, no `.tmp`, no `.bak`. Nothing survives a restart.
- Location and real time are stored locally only.
- F11 (and later the log) opens from the keyboard only. A controller can navigate after F11 is already open. Find stays keyboard-only.
- Without the Notifications module marker, the later F11 row shows "needs Notifications". P1 ships the backend in this build behind `Record`.

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

This repository contains only the plugin source. It doesn't include any game files or decompiled game interface code.

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
