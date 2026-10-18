# Horizon UI for Starfield

![Status: alpha](https://img.shields.io/badge/status-alpha-orange) ![Game: Starfield PC](https://img.shields.io/badge/game-Starfield%20PC-blue) ![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-green)

> **Alpha:** Horizon UI is in public testing before 1.0. Things may still change between builds. Your settings carry over in `HorizonUI.user.ini`.

Horizon UI is an adaptive, dynamic, customizable and modular HUD replacement for Starfield. It uses translucent pill cards in Exo 2, with a cyan accent by default, and you set everything up live in game with F11.

This repository holds the source of **`HorizonUI.dll`**, the SFSE plugin that powers the mod. The HUD itself ships as interface files in the release downloads.

## Features at a glance
- **Adaptive:** every card has its own visibility rule, so cards appear when they matter. Warnings react to your health and oxygen, and the Planet card lights up in hazards.
- **Dynamic:** cards update live, including XP, carry weight, ammo, the Starborn power meter, and two clocks (in-game time and your real PC time). You also get combat feedback and live previews in F11.
- **Customizable:** more than 100 settings, Arrange Cards to move anything, colors, fonts, sizes, and presets you can save and switch.
- **Modular:** a core HUD plus optional **Horizon Font** and **Comms** (subtitles and dialogue) modules, with a **Scanner** module planned. The FOMOD installer lets you pick what you want.

## Requirements
- **Starfield** (PC). Tested on game version 1.16.244.
- **[Starfield Script Extender (SFSE)](https://sfse.silverlock.org/)** for that game version. SFSE isn't included, so install it separately and launch with `sfse_loader.exe`.
- **[Address Library for SFSE Plugins](https://www.nexusmods.com/starfield/mods/3256)** for that game version (required). It isn't included; `HorizonUI.dll` needs it to load.
- **Loose files enabled** in `Documents\My Games\Starfield\StarfieldCustom.ini` (create it if missing):

  ```ini
  [Archive]
  bInvalidateOlderFiles=1
  sResourceDataDirsFinal=
  ```

  Without this, Starfield ignores loose interface files and you'll see the vanilla HUD.

## Install
Most players should use the **FOMOD installer** from [Releases](https://github.com/moragar360/HorizonUI-Starfield/releases) or from Nexus (link coming with the Nexus release), installed with Vortex or Mod Organizer 2. The installer walks you through Font, Settings Preset, and the optional Comms modules. The release notes cover manual installs from the separate zips.

## What the plugin does
`HorizonUI.dll` is a small SFSE plugin that runs alongside the HUD's interface files:
- **F11 live settings window:** opens the settings menu from your key (F11 by default, rebindable) and handles its input.
- **Mouse wheel** support in Horizon's menus.
- **Settings files:** reads the shipped `HorizonUI.default.ini` and your `HorizonUI.user.ini`, saves changes safely, and keeps one backup per update (`HorizonUI.user.bak.ini`).
- **Presets:** lists, applies, saves, deletes and undoes presets in `Interface\HorizonUI\presets\` (your own go in `presets\user\`).

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
   xmake build -y
   ```

3. The plugin is written to `build\windows\x64\releasedbg\HorizonUI.dll`.

Copy it to `Data\SFSE\Plugins\` and check the log for `HorizonUI 0.39.0 loaded`.

## Repository layout
```
src/main.cpp      plugin source
src/pch.h         precompiled header
lib/commonlibsf   CommonLibSF (git submodule)
xmake.lua         build script
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
- **AEGIS** by [Jaderay](https://www.nexusmods.com/profile/jaderay?gameId=4187) inspired the planned Scanner module's concept. Horizon UI is its own code and original art; no AEGIS code or assets are included.
- Game icons (weapon outlines, Starborn powers) are loaded from your game at runtime and aren't bundled.

## Links
- Nexus: link coming with the Nexus release. Author profile: [moragar](https://www.nexusmods.com/profile/moragar)
- Bugs and feedback: [GitHub Issues](https://github.com/moragar360/HorizonUI-Starfield/issues)
