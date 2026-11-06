# Checks for 0.43.1.0-alpha

Unreleased first pass. No tag, no publish, no merge. Starfield was not launched. `hudmenu` and `hudmenu_lrg` share `actionscript/horizon_block.as`, so the watch and the reticle rule are the same in both movies.

## What was checked here

- `message_log_test`, `preset_list_test`, `planet_alert_test.js`, `reaction_match_test.js`, and `watch_crosshair_test.js` passed.
- File version is 0.43.1.0 in `src/hz_version.h`, both `set_version` lines, `HZ_BUILD`, and the module build constants. The settings schema stays `0.42.0`.
- `WatchStyle=0` and `CrosshairRule=0` are the defaults. Existing installs that omit the keys keep today's HUD and today's reticle.
- The new watch block has no `getTimer` and no new glow. No new F key. Watch text is created at 13 px or larger, then held to a 13 px on-screen floor at the HUD scale.
- The game font is not named in the new player-facing strings.
- `staruihudmenu` was not edited. No Ship Builder files are on this branch.

## Watch layout

Arrange lists the watch when Horizon Digital or Analog is on. `WatchX` and `WatchY` use the same edge anchors as the other cards (`L` / `R` / `C` and `T` / `B` / `C`, plus an offset). `-1` is the lower-left home. `WatchScale` is the size entry (`-1` means HudScale, or 0.60 to 1.60 for this face). `hudmenu` and `hudmenu_lrg` share this block, so both use the same saved spot. Existing `HorizonUI.user.ini` files are not rewritten. A missing `WatchX` stays at the home. Other cards' saved positions are left as they are.

The home is the lower-left corner, inside the screen margin, where the game's watch sits. While the watch is still at that home, a showing character, vitals, jetpack, or compact card that overlaps it lifts the watch 8 px above the card. The card stays put. Once `WatchX` / `WatchY` is a saved spot, the lift stops and the saved spot is used. On Moragar's Choice the character card is the lower-left card and the vitals card is centered, and the preset does not set `WatchX`, so the watch still sits above the character card until you move the watch itself. On the stock layout the vitals card is lower-left, so the watch sits above that stack instead of covering it.

Styles 1 and 2 are the game's own watch. Arrange does not drag that clip.

## Data feeds

| Element | Feed | Fallback |
| --- | --- | --- |
| Local / game time and analog hands | `LocalEnvData_Frequent.fLocalPlanetTime` (0 to 1 of the local day), same clock as the planet card | Galactic standard time `fGalacticStandardTime` when the local day is missing (flying ship, or hours-per-day is 0). Hands sit at 12 and the local line is `--` when both are missing. |
| PC / real time | `Date` hours and minutes, same formatter as the planet card (`ClockFormat`) | `--` if the clock throws |
| Day sub-dial | Same local-day fraction. Dawn is 0.25 and dusk is 0.75, the split the planet disc already uses for sun versus moon. The marker rides the top arc between those two and the lower arc at night. | Galactic time divided by 24 when the local fraction is missing. No marker when both are missing. There is no sun-altitude feed. |
| Planet name | `LocalEnvironmentData` body name, already stored as `hzPpBodyName` | `--` |
| Temperature | `LocalEnvironmentData.fTemperature` in Celsius, through `hzTempText` so `TempUnit` still applies | `--` in a flying ship or when the value is missing |
| O2 | `PlayerFrequentData.fOxygen / fMaxO2CO2` (`hz26O2F`). Blue `#4DB6FF`, clockwise from 7 o'clock, at most to 1 o'clock | Empty gray segments before a reading. The stored value starts at 1, so it does not flash LOW O2 at startup. |
| CO2 | `PlayerFrequentData.fCarbonDioxide / fMaxO2CO2` (`hz26Co2F`). Gold `#E8C547`, counter-clockwise from 5 o'clock, at most to 11 o'clock | Gray segments when the value is missing (stored as 0) |
| Heading | `HudCompassData.fDirection`, already `hzCmpDeg` | Diamond stays at the top. Letters wait until a heading arrives (0 until then). |
| Accent | The player's accent (`HZ_ACCENT`): digital heading diamond, analog 12 o'clock diamond, and the analog hub. Hour and minute hands are white. | Card color is used only for style 2 (vanilla tint), not as a Horizon card panel |
| Attention | O2 below 0.35 or CO2 above 0.35. Orange `#F28A4F`, a triangle, and the words LOW O2 or HIGH CO2. LOW O2 wins when both are true. | Hidden when neither threshold is crossed |

Analog seconds are not drawn. The game-time feed is hours and minutes.

Style 0 keeps the vanilla watch hidden, which is today's behavior. Styles 1 and 2 show `BottomLeftGroup`. The older hide set those clips to `visible = false` and `alpha = 0` and never put them back, so choosing Vanilla after Off left a blank corner. Styles 1 and 2 restore that group once (a single trace lists the clip names) and then leave the game's own show and hide alone. Style 1 is the stock watch. Style 2 tints the watch clips with the card color and the pointer / O2 clips with the accent, and it does not add a second planet name. No new glow. Styles 3 and 4 hide that group again and draw the Horizon face. The Horizon face is a round disc so the type can be read. It is not a card panel and it has no planet art. Nothing under the face names its position.

## Weapon drawn

`CrosshairRule` 1 calls `hzWeaponOut()`, the same function as Equipment rule 3 (WEAPON DRAWN ONLY).

`hzSetWeaponDrawn` exists on the movie, but this plugin never calls it, so `hzPlugActive` stays false. The fallback is `WeaponData.bDisplayAmmo` and `HudCrosshairData.bEnabled` and crosshair type not 2 (unarmed). Type 7 (interact) still counts as drawn when ammo is showing, so looking at something you can use does not hide the reticle if the weapon is out.

Third person uses that same test. `bIn3rdPerson` is stored for the existing interact-reticle rule and is not a separate branch here. An idle third-person dot is hidden when ammo is not displayed or the type is unarmed. Drawing a gun that sets `bDisplayAmmo` shows the aiming reticle again, in third person and in first person.

The rule hides only that aiming dot or reticle. Hovering a person switches the crosshair to type 7 and the game often shows `ReticleBase_mc` again, or swaps in a new instance. The old ownership check treated type 7 as "stop hiding" and also gave up when the new instance was not the one it had hidden, so the dot came back. While the rule wants the dot hidden, a visible aiming clip is hidden again, including after that swap. Type 7 keeps `ReticleBase_mc` itself visible so the interact ring and the glyph still draw. Other children of that clip are hidden, and `Player_Interaction_ReticleAnim_mc` is not one of them. Restore still puts back only a hide this rule made, and only when the game still wants the reticle, including the iron-sights check. A hide from iron sights is not forced back on. The rule does not hide prompts, target cards, hit markers, the kill X, the damage ring, or the stealth pill. `CrosshairStyle` is unchanged.

While styles 1 to 4 are on, the watch frame does not build a clock object, a signature string, placement points, or a style-2 color transform every frame. Those are cached and rebuilt when a number changes: the minute, the day-fraction bucket, O2, CO2, temperature, heading, card rects, and the accent or card color. The PC clock reads the time at most once a second from the frame counter. The vanilla-watch hide runs once per frame.

## Risks

- Style 2 tints named clips on `BottomLeftGroup`. A clip the game renamed will stay untinted. The watch shape is still the game's.
- The Horizon face is large (132 px radius before HUD scale). On a crowded lower-left it stacks above the cards and can sit high.
- Compass letters on the digital face are 13 px, so the top of the face is busier than the mock.
- A holstered weapon that still reports `bDisplayAmmo` will keep the reticle. A drawn melee weapon that does not report ammo will hide it.
- The movies in this repo are the ActionScript sources. The shipped `.gfx` still has to be rebuilt before an in-game check.

## In-game checklist

1. Update over 0.43.0.33 without touching `HorizonUI.user.ini`. The watch stays off and the reticle stays as it is.
2. F11 > CARDS > WATCH. Step Off, Vanilla, Vanilla + Horizon, Horizon Digital, Horizon Analog. Save, reload, and confirm the ini key.
3. Digital: O2 left, CO2 right, compass diamond, day sub-dial, both clocks, planet and temperature. No planet picture and no rectangular card.
4. Analog: flush rim arcs, hands on game time, diamond at 12, day sub-dial at 6, planet and temperature at the top.
5. With the character card in the lower-left, the watch sits above it and the card does not jump. Move the watch in Arrange, save, reload, and confirm `WatchX` / `WatchY` hold the spot and the watch no longer lifts for the card. Reset puts it back on the lower-left home, and the lift returns. Move a card, save, and confirm that card's saved spot is unchanged.
6. Drop O2 or raise CO2. The orange LOW O2 or HIGH CO2 line appears. Restore them and it leaves.
7. F11 > RULES > CROSSHAIR. Always matches today. Weapon drawn hides the aiming dot while the weapon is holstered, including in third person, and shows it when the weapon is out. Looking at something you can use still shows the center ring and the interact glyph, with the weapon holstered and with the rule Off. Iron sights still hide the reticle. Prompts, the target card, a hit marker, a kill X, the damage ring, and the stealth pill still appear. Crosshair Style still switches the interact glyph.
