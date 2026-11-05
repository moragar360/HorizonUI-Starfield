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

The watch is not an Arrange card. Saved positions are not rewritten.

Its home is the lower-left corner, inside the screen margin, where the game's watch sits. If a showing character, vitals, jetpack, or compact card overlaps that circle, the watch moves up and sits 8 px above the card. The card stays put. On Moragar's Choice the character card is the lower-left card and the vitals card is centered, so the watch sits above the character card. On the stock layout the vitals card is lower-left, so the watch sits above that stack instead of covering it.

## Data feeds

| Element | Feed | Fallback |
| --- | --- | --- |
| Local / game time and analog hands | `LocalEnvData_Frequent.fLocalPlanetTime` (0 to 1 of the local day), same clock as the planet card | Galactic standard time `fGalacticStandardTime` when the local day is missing (flying ship, or hours-per-day is 0). Hands sit at 12 and the local line is `--` when both are missing. |
| PC / real time | `Date` hours and minutes, same formatter as the planet card (`ClockFormat`) | `--` if the clock throws |
| Day sub-dial | Same local-day fraction. Dawn is 0.25 and dusk is 0.75, the split the planet disc already uses for sun versus moon. The marker rides the top arc between those two and the lower arc at night. | Galactic time divided by 24 when the local fraction is missing. No marker when both are missing. There is no sun-altitude feed. |
| Planet name | `LocalEnvironmentData` body name, already stored as `hzPpBodyName` | `--` |
| Temperature | `LocalEnvironmentData.fTemperature` in Celsius, through `hzTempText` so `TempUnit` still applies | `--` in a flying ship or when the value is missing |
| O2 | `PlayerFrequentData.fOxygen / fMaxO2CO2` (`hz26O2F`). Blue `#4DB6FF`, left half | Empty (dim) arc before the first reading. The stored value starts at 1, so it does not flash LOW O2 at startup. |
| CO2 | `PlayerFrequentData.fCarbonDioxide / fMaxO2CO2` (`hz26Co2F`). Gold `#E8C547`, right half | Dim arc when the value is missing (stored as 0) |
| Heading | `HudCompassData.fDirection`, already `hzCmpDeg` | Diamond stays at the top. Letters wait until a heading arrives (0 until then). |
| Accent | The player's accent (`HZ_ACCENT`): digital heading diamond, analog 12 o'clock diamond and minute hand | Card color is used only for style 2 (vanilla tint), not as a Horizon card panel |
| Attention | O2 below 0.35 or CO2 above 0.35. Orange `#F28A4F`, a triangle, and the words LOW O2 or HIGH CO2. LOW O2 wins when both are true. | Hidden when neither threshold is crossed |

Analog seconds are not drawn. The game-time feed is hours and minutes.

Style 0 keeps the vanilla watch hidden, which is today's behavior. Styles 1 and 2 show `BottomLeftGroup`. Style 2 tints the watch clips with the card color and the pointer / O2 clips with the accent. No new glow. Styles 3 and 4 hide that group again and draw the Horizon face. The Horizon face is a round disc so the type can be read. It is not a card panel and it has no planet art.

## Weapon drawn

`CrosshairRule` 1 calls `hzWeaponOut()`, the same function as Equipment rule 3 (WEAPON DRAWN ONLY).

`hzSetWeaponDrawn` exists on the movie, but this plugin never calls it, so `hzPlugActive` stays false. The fallback is `WeaponData.bDisplayAmmo` and `HudCrosshairData.bEnabled` and crosshair type not 2 (unarmed). Type 7 (interact) still counts as drawn when ammo is showing, so looking at something you can use does not hide the reticle if the weapon is out.

Third person uses that same test. `bIn3rdPerson` is stored for the existing interact-reticle rule and is not a separate branch here. An idle third-person dot is hidden when ammo is not displayed or the type is unarmed. Drawing a gun that sets `bDisplayAmmo` shows the center reticle again, in third person and in first person. Iron sights are left to the game once the rule says the reticle may show. The rule does not hide prompts, target cards, hit markers, the kill X, the damage ring, or the stealth pill. `CrosshairStyle` is unchanged.

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
5. With the character card in the lower-left, the watch sits above it and the card does not jump. Move the card in Arrange, save, and confirm the card's saved spot is unchanged.
6. Drop O2 or raise CO2. The orange LOW O2 or HIGH CO2 line appears. Restore them and it leaves.
7. F11 > RULES > CROSSHAIR. Always matches today. Weapon drawn hides the center dot while the weapon is holstered, including in third person, and shows it when the weapon is out. Prompts, the target card, a hit marker, a kill X, the damage ring, and the stealth pill still appear. Off hides only the center reticle. Crosshair Style still switches the interact glyph when the reticle is allowed.
