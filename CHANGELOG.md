# Changelog

All notable changes to Horizon UI are listed here, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Horizon UI is in alpha, so settings and layouts may still change before 1.0.

Only published releases are listed. 0.40.0, 0.40.1 and 0.40.3 were never published; 0.41.0 replaced 0.40.3, and its entry includes the changes prepared for 0.40.3.

## [0.43.1.0-alpha] - unreleased

Not published. No tag. The settings schema stays 0.42.0, so an existing `HorizonUI.user.ini` carries over. `WatchStyle` and `CrosshairRule` stay at their defaults until you change them.

### Added
- **Watch** in F11 > CARDS. `WatchStyle` under `[Cards Extra]`: 0 off (default), 1 the game's watch, 2 the game's watch tinted with your card color and accent, 3 Horizon digital, 4 Horizon analog. Off matches the previous HUD. Every watch face is an Arrange card. Styles 1 and 2 move the game's watch clips only, and leave the rest of the lower-left group where it is. `WatchX` and `WatchY` save the spot (`-1` is the lower-left home). `WatchScale` is the size (`-1` is HudScale). While the Horizon watch is still at the home, a showing card in that corner lifts it 8 px. A saved spot stays put. `hudmenu` and `hudmenu_lrg` share the watch, so both use the same spot.
- **Crosshair visibility** in F11 > RULES. `CrosshairRule` under `[Rules]`: 0 always (default), 1 only with a weapon drawn, 2 off. This hides the aiming dot or reticle only. The center interact ring and its glyph stay. A restore puts back only a hide this rule made, and it leaves an iron-sights hide alone. `CrosshairStyle` is unchanged.

### Changed
- **SFSE plugin** file and product version are 0.43.1.0. This build is not a release download yet.
- **Watch styles 1 and 2** show the game's watch again, as one assembly. Arrange moves that whole watch together, including the top bar, the ring, the face, the heading chevron, and the in-face markers. The character card, alerts, detection, and autopilot stay put. Style 2 still tints that watch and does not add a second planet name.
- **Horizon Digital and Analog** match the round faces: O2 runs clockwise from 7 o'clock, CO2 counter-clockwise from 5 o'clock, and empty segments are gray. Analog keeps the filled day dial at 6 o'clock. Digital has no day dial, and its times sit in the center of the face (local at 16 px, PC at 13 px). Both faces draw the same top-arc compass, with heading ticks and N / NE / E letters. The analog planet name sits below those letters. The local and PC labels sit above their times. Analog hands are white, with a gold hub. The live nearby, mission, and enemy markers stay on these faces. The vanilla chrome stays hidden.
- **Crosshair Off, and Weapon drawn while holstered,** keep the aiming dot hidden when the game shows it again on a target, an NPC, or while you walk. The interact ring and glyph stay while you are looking at something you can use. After you look away, the leftover center circle hides too.
- The watch no longer shows a line that names its place on the screen.

### Fixed
- **Quest tracker:** steps come only from the selected quest's open objectives. Compass markers supply a distance for those steps and do not add another quest's marker. A step update that arrives before the title, or a title that arrives before the steps, still fills that quest's card. A later name-only update still applies. The title and the steps refresh together when the selected quest changes. Sub-lines are 13 px.
- **Afflictions and the detection ring** no longer follow the watch style. The bio popup hides while the afflictions card is on. The red ring hides while the stealth pill, the enemy bar, or the edge pulse is on.
- **Watch PC time** keeps the last good reading when the clock throws, or the planet card's real time when this face has none yet. A failed read does not build a new clock every frame.
- **Watch Off** hides the leftover inner radar, nearby markers, heading outline, and unnamed cap art. The character card stays.
- **Vanilla watch** is a passthrough of the game's watch, including the thick top cap / outer bar. Arrange moves BottomLeftGroup watch siblings together and does not double-write nested `O2Anim_mc`. Off and custom hide the watch assembly with `visible=false` only, so native FadeIn can finish. Styles 1 and 2 undo that visible-hide without writing a stored alpha. Day cycle, off-planet, autopilot, and location name restore from the last LocalEnvironmentData formulas, including boarding, landing, cruise, and language during Off. Temperature, oxygen, and gravity undo Off vis only and keep native FadeInPlanetInfo alpha; vis-true does not display them at alpha 0. Independently hidden health, ammo, and boost are not on the watch hid list and stay hidden through Vanilla, Off, custom, F11, and exitFrame place. Style 2 tints the same face pieces by RGB only, leaves native alpha (including the thin bar at 0), and does not tint those info clips. Horizon does not draw watch text onto that face. Unnamed watch chrome is restored and moved with the named clips.
- **Horizon Digital and Analog** keep live nearby, mission, and enemy markers on the Horizon face. Off still hides those marker widgets with the rest of the watch.
- **Outpost beacon hold:** an enabled Hold key stays in its normal color. The vanilla hold path stays at full alpha so the game receives the hold. Prompt art is still hidden, so a second vanilla bar does not sit on the Horizon card. A filling meter draws on the Horizon keycap. A hold the game marks disabled stays gray.

## [0.43.0.33-alpha] - 2026-11-04

Released as v0.43.0.33-alpha.

### Changed
- **Moragar's Choice** is the author's current in-game layout. The file is `preset/HorizonUI.moragars-choice.ini` (the installer still adds it as `moragars_choice.ini`). `[Comms] HzRev` stays `0`, the default save counter.
- **SFSE plugin** rebuilt for 0.43.0.33 (`HorizonUI.dll`, file and product version 0.43.0.33).

## [0.43.0.32-alpha] - 2026-11-03

Released as v0.43.0.32-alpha.

### Fixed
- **Compact name pill:** every verb shows in full (Use, Recycle, Talk, Trade, Steal, Search, Open, and the rest). A long name is the part that shortens, and the pill grows as needed so verbs are never cut. The name stays in the accent color, and in red on a steal prompt.
- **SCANNER and COMMS:** the module status box starts collapsed every time F11 opens. The chevron still expands it for that visit.

### Added
- **WELCOME INTRO** in F11 > EFFECTS turns the save-load intro on or off. It reads and writes the existing `[UI] StartupIntro` setting (`1` on, `0` off). It saves with the other rows, and it is included in presets and Restore Defaults. The ini key still works. Off still logs that the intro was skipped.

### Changed
- **SFSE plugin** rebuilt for 0.43.0.32 (`HorizonUI.dll`, file and product version 0.43.0.32).

## [0.43.0.31-alpha] - 2026-11-03

Released as v0.43.0.31-alpha.

Alpha pre-release. This entry covers everything since 0.42.0.13-alpha. The settings schema stays 0.42.0, so your `HorizonUI.user.ini` carries over.

### Added
- **Message Log (optional):** a searchable history of the messages Horizon shows on your HUD. Open it from F11 > CONTROLS > MESSAGE LOG > OPEN. It has a log with a time, message and place for each entry, a chip with a count for each message type, a find box (press `/` to jump to it), an ALL TIME switch (off = this play session only), pins (up to 50), CLEAR SESSION with a confirmation, and a SETTINGS page with RECORD MESSAGES, SAVE TO DISK, FOLDER, HISTORY (100 to 1000, 500 by default), a switch for each message type and OLD CHARACTERS.
  - History is saved per character (one file per character, not per save) under `Documents\My Games\Starfield\SFSE\HorizonUI\MessageLog\`. Messages from a later point of an earlier save are kept and shown dimmed as "from a later point".
  - Message types you turn off are never recorded, and they still show on screen.
  - The Message Log starts empty and records messages from the moment it's enabled. Messages from before you installed Horizon UI can't be recovered.
  - Recording is controlled by `Record` under `[MessageLog]` in the ini (`Record=0` stops recording). `Persist=0` keeps the log in memory only. Horizon UI never deletes log files, retries a failed save, and never replaces an existing log with an empty one.
  - Types: Medical, Crew, Reactions, Busy, Crime, Credits, Quest, Location, Game and XP. Quest, Location and XP come from Comms. "CALMED" lines aren't saved. Each message is kept up to about 256 characters.
  - New installer option on the Optional Modules page (ticked by default). Without it, the F11 row is grayed out and reads "needs Notifications".
- **Comms (subtitles and dialogue):** the F11 COMMS tab has a full-width SUBTITLES / DIALOGUE selector at the top. Comms replaces any dialogue menu mod, such as Enhanced Dialogue Interface (uninstall it first), and subtitle mods such as Enhanced Subtitles.
- **Compact vitals card:** new HEALTH AND O2 BARS setting in F11 > CARDS (FULL by default, or COMPACT). COMPACT uses the same merged boost, health and oxygen card as COMPACT MODE. That card follows your jetpack and vitals show rules, and ARRANGE CARDS can move it when either compact setting is on. New setting: `[Cards] VitalsBars`.
- **Compact name hover:** the target card can be one slim line with an icon, the name and the key. The name is drawn in your accent color, and in red when the prompt is for stealing. F11 > CARDS > NAME HOVER switches between COMPACT and FULL. New setting: `[Cards] NameHover`.
- **Welcome intro:** after a save load, Horizon plays the HORIZON UI wordmark, one star sweep of about 2 seconds, then a line with your loaded preset's name, and ends at about 6 seconds. Accent color, no panel; it never pauses the game or takes input. New setting: `[UI] StartupIntro` (`1`; `0` turns it off).
- **Card looks in F11 > STYLE:** CARD BACKGROUND % (`[Style] CardBgOpacity`, 92), CARD SHADOW % (`[Style] CardShadow`, 12) and SETTINGS WINDOW % (`[Style] SettingsOpacity`, 93).
- **GAME and ARTIFACT cards (Comms):** other notices the game shows become a generic GAME card, and a notice that contains Artifact becomes an ARTIFACT card. Notices over 200 characters show shortened with "..." on the card. They use the COMPANION REACTION CARD switch.
- New `[MessageLog]` section: `Record` (`1`), `LogTypes`, `HistorySize` (`500`), `Persist` (`1`) and `MissedBadge` (`1`, reserved; nothing is drawn for it yet).

### Changed
- **Name hover is Compact by default.** Moragar's Choice keeps Compact. The full card is still available in F11 > CARDS > NAME HOVER.
- **Boost row reflow:** when the boost row on the merged card is hidden, the card closes up around the rows that remain.
- **Card background and the F11 window** now map their percent sliders straight to opacity. At the defaults, cards on dark card colors look a little more solid than in 0.42, and cards on light card colors a little lighter.
- **F11 key handling:** one press opens F11 and the next closes it.
- **TAKE card and jetpack card:** the key letter and HOLD text stay at least 13 px, and the jetpack card keeps its gap above Vitals.
- **Moragar's Choice** preset updated for 0.43 (Compact name hover, the card looks at their defaults and the welcome intro on).
- **SFSE plugin** rebuilt for 0.43.0.31 (`HorizonUI.dll`, file and product version 0.43.0.31).

### Fixed
- F11 lets go cleanly when a full-screen menu such as the character screen covers the HUD.

### Known issues
- An arranged compact card near the bottom of the screen can shift when the boost row hides.
- The welcome intro may sit slightly left of center.
- There's no F11 switch for the welcome intro yet. Use `StartupIntro` in the ini.
- Still true from 0.42.0.13: the blue quest diamond in the world and on the HUD compass uses the game's own style; the companion reaction card recognizes only English game text and names of up to 4 words; and the Scope chip's HOLDING BREATH label is inferred from O2 going down.

### Assets
| File | SHA-256 |
| --- | --- |
| `HorizonUI-0.43.0.31-FOMOD.zip` | `154007587aab97d156e0e1922940783c220cff05d06a2c6e011e44e35c1576e3` |

## [0.42.0.13-alpha] - 2026-10-25

### Behavior changes from 0.41.0
- **F11 now opens from the main HUD only (no longer over the scanner).** This is an intended change, not a bug. F11 doesn't open while the hand scanner is open, and opening the scanner closes the settings window. Set up the Scanner in F11 > SCANNER from the main HUD; changes apply the next time you open the scanner.

### Added
- **Vitals layout:** the Vitals card can stack health above O2 (VERTICAL, the default) or put them side by side in one row (HORIZONTAL). Set it with VITALS LAYOUT in F11 > CARDS, or press **L** with the Vitals card selected in Arrange Cards. New setting: `[Cards] VitalsLayout`.
- **Vehicle exit pill:** the hold-to-exit prompt in a vehicle becomes a Horizon pill with a key cap, EXIT and a fill that sweeps while you hold. Turn it off with VEHICLE EXIT PILL in F11 > CARDS. New setting: `[Cards] VehicleExitPill`.
- **Temperature units:** the planet card and the scanner show the temperature in Celsius (default) or Fahrenheit. New setting: `[Style] TempUnit`.
- **HUD Messages box (Comms):** Horizon's message cards share one box you can move in Arrange Cards. New settings: `[Layout] HudMessagesX` and `HudMessagesY`.
- **Companion reaction card (Comms):** a companion's reaction line ("<Name> loved / liked / disliked / hated that.") becomes a Horizon card in the same spot, with the name, the reaction in its own color and an up or down arrow icon. On by default; turn it off with COMPANION REACTION CARD in F11 > COMMS (SUBTITLES page). New setting: `[Comms] ReactionCard`.
- **More message cards (Comms):** crew, companion and follower changes, affinity, busy and calmed, afflictions, crime (CRIME, ALARM, CAUGHT, PICKPOCKET, TRESPASS, WITNESS, BOUNTY, BOUNTY PAID), CREDITS and KID STUFF.
- **Persuasion meter (Comms dialogue):** your score, the highlighted reply's points, the turns left, and a PERSUADED or FAILED title. Turn it off with PERSUASION METER in F11 > COMMS. New setting: `[Comms] DlgPersuasionMeter`.
- **Scope module (optional, new):** the scope's hold-breath prompt becomes a Horizon chip with a target icon, the label and an O2 meter that turns yellow below 35% O2 and red below 15%. Move and resize it in Arrange Cards; turn it on or off, size it and reset it at the bottom of F11 > CARDS (shown when Scope is installed). The game's prompt is only hidden, never removed. Scope is ticked by default; if you use another scope mod, untick it. New `[Scope]` section: `ScopeHoldBreathChip`, `ScopeChipX`, `ScopeChipY`, `ScopeChipScale`.

### Changed
- **F11 stays closed in more menus,** including dialogue, the mission board, pickpocketing, sleeping or waiting, books, data slates, message boxes, favorites, weapon groups, takeoff, ship refueling, the outpost quick menus, videos and the credits, and while you aim down a scope or inspect an item.
- **Stealth pill:** the game's own stealth meter stays hidden while the Horizon pill is showing.
- **Planet card:** the time labels read LOCAL/GAME and PC/REAL.
- **Scanner:** text stays at least 13 px, and YOUR SHIP is recognized only by the game's own marker for your ship.
- **Presets:** each preset shows once in the list, and saved names drop the characters that could break the settings file.
- **Arrange Cards bar:** larger hint line and buttons; the hint line lists the **L** key.
- **F11 header** shows the exact build.
- **Moragar's Choice** updated for 0.42.0.

### Fixed
- Going from Arrange Cards to the scanner no longer leaves cards on screen.
- The game's planet name no longer shows again after you open and close the scanner quickly, or after you land.
- The TAKE card shows weapon or armor rows only for weapons and armor.
- Repeated crime lines no longer show a doubled card.
- The compact bioscan strip no longer cuts its counts short at large text sizes.

### Removed
- F11 over the scanner (see Behavior changes).

### Known issues
- The blue quest diamond in the world and on the HUD compass still uses the game's own style.
- The companion reaction card only recognizes English game text and names of up to 4 words.
- The Scope chip's HOLDING BREATH label is inferred from O2 going down.

## [0.41.0-alpha] - 2026-10-19 - Arrange Scanner

### Added
- **Arrange Scanner** (F11 > SCANNER > LAYOUT): drag the scanner panels, the person card and your kept vitals into place on a mock scanner. Arrow keys nudge, **C** toggles compact, **L** switches the vitals layout, **R** resets, ENTER saves, ESC cancels. Presets carry the layout.
- **Keep vitals while scanning, one by one:** KEEP HEALTH, KEEP O2 and KEEP BOOST keep health, O2 and boost on screen while the scanner hides the HUD, plus COMPACT VITALS and VITALS LAYOUT (stacked or in a row). They sit at the bottom center by default.
- **Signals:** a green row for your companion, a violet **Companion ship** row, and YOUR VEHICLE / VEHICLE rows. Ownership is shown by label and icon as well as color.
- **Fauna tags** show when a creature is dead or diseased.
- **People** get a name-only world tag next to the bounty / social skill strip.
- **F11 over the scanner:** the settings window opens while you scan (replaced in 0.42.0).
- **Moragar's Choice** on its own as a release file (`HorizonUI.moragars-choice-0.41.0.ini`).

### Changed
- **EXPOSURE instead of SOAK** on the scanner's hazard rows, the Afflictions card and F11 (AMBER AT EXPOSURE %, RED AT EXPOSURE %). Your values are unchanged.
- **Quest diamond** is gold in the Signals list and on the scanner's compass.
- **SHOW RESOURCES** makes the Resources card pulse briefly.
- **YOUR SHIP ROW** now covers your vehicle too, and POI MARKERS off also hides the HUD's floating quest markers while you scan.
- The bottom-left planet alert and the game's location banner stay hidden while the scanner is open.
- **F11 stays closed** in full-screen game menus like the inventory, starmap, photo mode and the ship and outpost builders.
- Map-marker world tags use the game's own marker details or type; undiscovered markers show their Signals type plus UNDISCOVERED.
- All scanner panel sizes allow 0.60 to 1.60.
- The compact bioscan strip grows with the text size, so its counts fit at large text sizes.
- Markers within 24 px of the screen edge are hidden.
- **Moragar's Choice** now also turns on POI MARKERS (`ScanWorldMarkers=1`).
- **SFSE plugin** rebuilt for 0.41.0 (FileVersion 0.41.0.0).

### Fixed
- The planet name no longer shows behind the scanner while you switch scanner tools.
- Name tags clear as soon as you aim away, and ships and markers no longer show a leftover character name.
- Kept vitals are no longer covered by the scanner's left column at the default layout.
- On-screen ship markers draw the Horizon ship icon.
- Clipped frame edges in Comms subtitles, the dialogue menu and HUD alerts.

### Removed
- The scanner debug overlay and its `ScanDebug` setting.

### Known issues
- The blue quest diamond in the world and on the HUD compass still uses the game's own style.

## [0.40.2-alpha] - 2026-10-18 - Scanner module

### Added
- **Scanner module (optional):** Horizon's own hand scanner screen, with a planet card, bioscan, signals, traits + resources, compass, a mode pill, a hints bar and world tags with point-of-interest markers.
- **Scanner extras:** a scan-complete flash, "left to find" counts, a resource rarity filter, NEAREST UNDISCOVERED in Signals and compact mode.
- **People:** a strip with your social skills and the bounty prompt for whoever you're aiming at.
- **F11 SCANNER tab:** panels, sizes, look, extras, hazard levels and reset buttons.
- **HIDE HORIZON HUD WHILE SCANNING** (on by default, with Horizon's scanner only). Combat feedback, the item card, container list and activate prompt stay visible.
- **Installer:** a Scanner checkbox on the Optional Modules page, ticked by default. New download: `HorizonUI-Scanner-0.40.2.zip`.

### Changed
- The scanner popup options moved from the COMMS tab to the SCANNER tab (they still need Comms).
- Quest popups stay hidden for the whole scan by default, and with Comms they also wait while the ship scanner is open.
- The F11 key is ignored while the scanner is open.
- With Horizon Font, the game's floating quest-marker labels use the Horizon font.
- The HUD and quest popups always come back when a scan ends, including loading screens, fast travel, death and menus.
- Presets save and restore every Scanner setting.
- **SFSE plugin** rebuilt (FileVersion 0.40.2.0).

### Fixed
- The stealth meter ring and outline-only cards no longer lose part of their border.

### Known issues
- The blue quest diamond in the world still uses the game's own style.

## [0.39.0-alpha] - 2026-10-17 - First public alpha

### Added
- **Card-based HUD:** Planet / Ship with in-game and real PC clocks, Vitals with warnings and edge pulse, Jetpack, Afflictions, Character with XP toast, Equipment with weapon icon, grenades and Starborn power, Quest tracker and Compass.
- **Crosshair & interaction:** a container window with rarity colors, a centered Horizon version of the game's prompt, item, compare and enemy hover cards, a top-of-screen enemy health bar, crosshair styles, hit markers, damage numbers and a damage direction ring.
- **Adaptive:** per-card visibility rules, so cards appear when they matter.
- **Customizable:** the F11 live settings window with more than 100 settings, Arrange Cards, colors, fonts and sizes.
- **Presets:** apply, save, delete and undo presets from F11, including Moragar's Choice.
- **Settings that survive updates:** `HorizonUI.user.ini`, with an automatic backup per update and RESTORE UPDATE BACKUP.
- **Horizon Comms (optional):** subtitles and a dialogue menu in Horizon's own cards; the choices card shows who you're talking to.
- **FOMOD installer** with Font, Settings Preset and optional Comms modules.
- **SFSE plugin** (`HorizonUI.dll`): F11 window input, mouse wheel, settings files and presets.
- **Requirements:** SFSE and Address Library for SFSE Plugins, both required.

[0.43.0.32-alpha]: https://github.com/moragar360/HorizonUI-Starfield/releases/tag/v0.43.0.32-alpha
[0.43.0.31-alpha]: https://github.com/moragar360/HorizonUI-Starfield/releases/tag/v0.43.0.31-alpha
[0.42.0.13-alpha]: https://github.com/moragar360/HorizonUI-Starfield/releases/tag/v0.42.0.13-alpha
[0.41.0-alpha]: https://github.com/moragar360/HorizonUI-Starfield/releases/tag/v0.41.0-alpha
[0.40.2-alpha]: https://github.com/moragar360/HorizonUI-Starfield/releases/tag/v0.40.2-alpha
[0.39.0-alpha]: https://github.com/moragar360/HorizonUI-Starfield/releases/tag/v0.39.0-alpha
