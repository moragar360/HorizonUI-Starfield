# Checks for 0.43.1.0-alpha

Unreleased first pass. No tag, no publish, no merge. Starfield was not launched. `hudmenu` and `hudmenu_lrg` share `actionscript/horizon_block.as`, so the watch and the reticle rule are the same in both movies.

## What was checked here

- `message_log_test`, `preset_list_test`, `planet_alert_test.js`, `reaction_match_test.js`, `watch_crosshair_test.js`, and `quest_tracker_test.js` passed.
- File version is 0.43.1.0 in `src/hz_version.h`, both `set_version` lines, `HZ_BUILD`, and the module build constants. The settings schema stays `0.42.0`.
- `WatchStyle=0` and `CrosshairRule=0` are the defaults. Existing installs that omit the keys keep today's HUD and today's reticle.
- The new watch block has no `getTimer` and no new glow. No new F key. Watch text is created at 13 px or larger, then held to a 13 px on-screen floor at the HUD scale.
- The game font is not named in the new player-facing strings.
- `staruihudmenu` was not edited. No Ship Builder files are on this branch.

## Watch layout

Arrange lists the watch for styles 1 through 4. Styles 1 and 2 move the game watch as one assembly, not the whole lower-left group, and style 2's tint follows that same watch. `WatchX` and `WatchY` use the same edge anchors as the other cards (`L` / `R` / `C` and `T` / `B` / `C`, plus an offset). `-1` is the lower-left home. `WatchScale` is the size entry (`-1` means HudScale, or 0.60 to 1.60 for this face). `hudmenu` and `hudmenu_lrg` share this block, so both use the same saved spot. Existing `HorizonUI.user.ini` files are not rewritten. A missing `WatchX` stays at the home. Other cards' saved positions are left as they are.

The home is the lower-left corner, inside the screen margin, where the game's watch sits. While the watch is still at that home, a showing character, vitals, jetpack, or compact card that overlaps it lifts the watch 8 px above the card. The card stays put. Once `WatchX` / `WatchY` is a saved spot, the lift stops and the saved spot is used. On Moragar's Choice the character card is the lower-left card and the vitals card is centered, and the preset does not set `WatchX`, so the watch still sits above the character card until you move the watch itself. On the stock layout the vitals card is lower-left, so the watch sits above that stack instead of covering it.

Styles 1 and 2 are the game's own watch, shown as one assembly and tinted for style 2. Arrange moves that whole watch together, including the top bar, the outer ring, the face, the heading chevron, and the in-face markers, with the same `WatchX` / `WatchY` / `WatchScale` spot. The character card, bio alerts, env alerts, detection ring, location alert, and autopilot stay put.

## Data feeds

| Element | Feed | Fallback |
| --- | --- | --- |
| Local / game time and analog hands | `LocalEnvData_Frequent.fLocalPlanetTime` (0 to 1 of the local day), same clock as the planet card | Galactic standard time `fGalacticStandardTime` when the local day is missing (flying ship, or hours-per-day is 0). Hands sit at 12 and the local line is `--` when both are missing. |
| PC / real time | `Date` hours and minutes, same formatter as the planet card (`ClockFormat`) | The last good reading if the clock throws. With none yet, the planet card's real minutes. `--` only when both are missing. A failed read still waits a second. |
| Day sub-dial | Same local-day fraction. Dawn is 0.25 and dusk is 0.75, the split the planet disc already uses for sun versus moon. The marker rides the top arc between those two and the lower arc at night. | Galactic time divided by 24 when the local fraction is missing. No marker when both are missing. There is no sun-altitude feed. |
| Planet name | `LocalEnvironmentData` body name, already stored as `hzPpBodyName` | `--` |
| Temperature | `LocalEnvironmentData.fTemperature` in Celsius, through `hzTempText` so `TempUnit` still applies | `--` in a flying ship or when the value is missing |
| O2 | `PlayerFrequentData.fOxygen / fMaxO2CO2` (`hz26O2F`). Blue `#4DB6FF`, clockwise from 7 o'clock, at most to 1 o'clock | Empty gray segments before a reading. The stored value starts at 1, so it does not flash LOW O2 at startup. |
| CO2 | `PlayerFrequentData.fCarbonDioxide / fMaxO2CO2` (`hz26Co2F`). Gold `#E8C547`, counter-clockwise from 5 o'clock, at most to 11 o'clock | Gray segments when the value is missing (stored as 0) |
| Heading | `HudCompassData.fDirection`, already `hzCmpDeg` | Diamond stays at the top. Letters wait until a heading arrives (0 until then). |
| Accent | The player's accent (`HZ_ACCENT`): digital heading diamond, analog 12 o'clock diamond, and the analog hub. Hour and minute hands are white. | Card color is used only for style 2 (vanilla tint), not as a Horizon card panel |
| Attention | O2 below 0.35 or CO2 above 0.35. Orange `#F28A4F`, a triangle, and the words LOW O2 or HIGH CO2. LOW O2 wins when both are true. | Hidden when neither threshold is crossed |

Analog seconds are not drawn. The game-time feed is hours and minutes.

The afflictions card hides the vanilla bio popup on its own, including while styles 1 and 2 show the game's watch. The red detection ring follows the stealth pill, the enemy bar, and the edge pulse, not the watch style. It comes back when those cues are off, or when this HUD is hidden.

Style 0 keeps the vanilla watch hidden, including the inner radar, nearby markers, heading outline, and unnamed cap art. The character card stays. Styles 1 and 2 are a passthrough of the game's watch on `BottomLeftGroup`. The older hide set those clips to `visible = false` and `alpha = 0` and never put them back, so choosing Vanilla after Off left a blank corner. Styles 1 and 2 restore the watch face once (a single trace lists the clip names), including unnamed BottomLeftGroup chrome that sits outside the named watch clips, and then leave the game's own show and hide alone. They do not force `Temperature_mc`, `Oxygen_mc`, `Grav_mc`, or `OffPlanet_mc` on, and they do not draw Horizon watch text onto that face. Style 1 is the stock watch. Style 2 tints that same watch with the card color and the pointer / O2 clips with the accent. No new glow. Styles 3 and 4 hide the vanilla chrome and draw the Horizon face, and they keep the live nearby object and character markers on that face. The Horizon face is a round disc so the type can be read. It is not a card panel and it has no planet art. Nothing under the face names its position.

## Weapon drawn

`CrosshairRule` 1 calls `hzWeaponOut()`, the same function as Equipment rule 3 (WEAPON DRAWN ONLY).

`hzSetWeaponDrawn` exists on the movie, but this plugin never calls it, so `hzPlugActive` stays false. The fallback is `WeaponData.bDisplayAmmo` and `HudCrosshairData.bEnabled` and crosshair type not 2 (unarmed). Type 7 (interact) still counts as drawn when ammo is showing, so looking at something you can use does not hide the reticle if the weapon is out.

Third person uses that same test. `bIn3rdPerson` is stored for the existing interact-reticle rule and is not a separate branch here. An idle third-person dot is hidden when ammo is not displayed or the type is unarmed. Drawing a gun that sets `bDisplayAmmo` shows the aiming reticle again, in third person and in first person.

The rule hides only that aiming dot or reticle. Hovering a person switches the crosshair to type 7 and the game often shows `ReticleBase_mc` again, or swaps in a new instance. The old ownership check treated type 7 as "stop hiding" and also gave up when the new instance was not the one it had hidden, so the dot came back. While the rule wants the dot hidden, a visible aiming clip is hidden again, including after that swap and when walking shows it. The hide runs again after the timeline. Type 7 keeps `ReticleBase_mc` itself visible so the interact ring and the glyph still draw. Other children of that clip are hidden, and `Player_Interaction_ReticleAnim_mc` is not one of them while you are looking at something you can use. After you look away, that leftover circle is hidden too. Restore still puts back only a hide this rule made, and only when the game still wants the reticle, including the iron-sights check. A hide from iron sights is not forced back on. The rule does not hide prompts, target cards, hit markers, the kill X, the damage ring, or the stealth pill. `CrosshairStyle` is unchanged.

While styles 1 to 4 are on, the watch frame does not build a clock object, a signature string, placement points, or a style-2 color transform every frame. Those are cached and rebuilt when a number changes: the minute, the day-fraction bucket, O2, CO2, temperature, heading, card rects, and the accent or card color. The PC clock reads the time at most once a second from the frame counter. The vanilla-watch hide runs once per frame.

## Risks

- Style 2 tints the game watch. A clip the game renamed can stay untinted. The watch shape is still the game's. Vanilla does not force native temperature / oxygen / gravity / off-planet readouts on; if the game later shows those clips, they appear. Unnamed BottomLeftGroup chrome is part of the vanilla show and Arrange assembly. If the top cap lives outside BottomLeftGroup, the `HZ43 blg=` and `HZ43 watch unit=` traces still list what moved.
- The outpost hold no longer alpha-hides the activation widget. Prompt art is alpha-hidden off the hold path, and hold ancestors are restored to alpha 1. If the game still keys the hold to a clip this hide treats as art, the hold can fail without showing a second bar.
- The Horizon face is large (132 px radius before HUD scale). On a crowded lower-left it stacks above the cards and can sit high.
- Compass letters on the digital face are 13 px, so the top of the face is busier than the mock.
- A holstered weapon that still reports `bDisplayAmmo` will keep the reticle. A drawn melee weapon that does not report ammo will hide it.
- The movies in this repo are the ActionScript sources. The shipped `.gfx` still has to be rebuilt before an in-game check.

## In-game checklist

1. Update over 0.43.0.33 without touching `HorizonUI.user.ini`. The watch stays off and the reticle stays as it is.
2. F11 > CARDS > WATCH. Step Off, Vanilla, Vanilla + Horizon, Horizon Digital, Horizon Analog. Save, reload, and confirm the ini key.
3. Digital: O2 fills from 7 o'clock, CO2 from 5 o'clock. Compass diamond, both clocks (local at 16 px, PC at 13 px) in the center, planet and temperature. No day sub-dial on this face, no planet picture, and no rectangular card.
4. Analog: flush rim arcs, the same top-arc compass as digital, hands on game time, day sub-dial at 6, planet name and temperature below the compass letters.
5. With the character card in the lower-left, the watch sits above it and the card does not jump. Move the watch in Arrange, save, reload, and confirm `WatchX` / `WatchY` hold the spot and the watch no longer lifts for the card. Reset puts it back on the lower-left home, and the lift returns. Move a card, save, and confirm that card's saved spot is unchanged.
6. Drop O2 or raise CO2. The orange LOW O2 or HIGH CO2 line appears. Restore them and it leaves.
7. F11 > RULES > CROSSHAIR. Always matches today. Weapon drawn hides the aiming dot while the weapon is holstered, including in third person, and shows it when the weapon is out. Looking at something you can use still shows the center ring and the interact glyph, with the weapon holstered and with the rule Off. Iron sights still hide the reticle. Prompts, the target card, a hit marker, a kill X, the damage ring, and the stealth pill still appear. Crosshair Style still switches the interact glyph.
8. Watch Off: the character card stays. No inner radar, nearby markers, heading chevron, or top cap.
9. Vanilla and Vanilla + Horizon: the complete game watch, including the thick white top cap and outer ring. Arrange moves that whole assembly. Digital and Analog keep nearby markers on the Horizon face and do not show a second vanilla cap.
10. Outpost beacon: Hold R to Delete is not gray when enabled, and holding R runs the game's delete. No second vanilla prompt bar on the Horizon card.
