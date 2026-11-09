# Horizon Ship Builder 0.2.0.0

Horizon Ship Builder is a standalone SFSE plugin and a pair of spliced menu movies. It needs no other Horizon mod. Version 0.2.0.0 draws the whole ship builder from the approved gold mocks 1 to 17: power, the selected module card, credits, the parts browser with makers, variants, find, pills, sort and columns, the pill editor, pill import and export, the category grid, collapsed panels, colours with schemes, Flight Check, Settings, the More menu, the StarUI notice, and Arrange. The game's own builder keeps running underneath: its panels stay on the menu at alpha 0, so their data, focus, controller routing and engine events keep working, and every ship action is the game's own event.

The player file is `Documents\My Games\Starfield\Data\Interface\HorizonUI\shipbuilder\HorizonShipBuilder.user.ini`. The log is `Documents\My Games\Starfield\SFSE\Logs\HorizonShipBuilder_probe.log`. A ping of 0.2.0.0 in the log means the 0.2 splice is live.

## Why the 0.1 buttons were dead (p5)

In the p5 session (0.1.1.0, game 1.16.244) Settings opened from the gear, and then 23 left-button press and release pairs reached the plugin's window procedure (`WM_LBUTTONDOWN` and `WM_LBUTTONUP`, `swallowed=0`). None of them produced a Horizon note: no swatch, CUSTOM, ARRANGE or key line. The 0.1 Settings buttons were Scaleform sprites waiting for `MouseEvent.CLICK`. The plugin passed every click on to the game, and the ship editor consumed the press for the 3D view before Scaleform raised a mouse event for the sprite under the cursor. So the window saw the click, the game saw the click, and no Horizon control ever did. The hook only ate mouse input while Arrange was open.

0.2 stops depending on Scaleform mouse events:

- The movie publishes the rectangles of its visible panels each frame (`HOT x,y,w,h;...`), or `HOT all` while a popup, dialog, text field, the category grid or Arrange is open.
- The plugin converts every left press, release and move to stage units and feeds it to the movie (`M D`, `M U`, `M M`), with the wheel as `W`. A press inside a published rectangle is swallowed, and its release goes with it, so the game gets both halves of a click or neither.
- The movie hit-tests the fed point against its own boxes and runs the control. No Horizon class adds a `MouseEvent` listener.
- Keys follow the same rule. While a popup, text field, the category grid or Arrange is open, the plugin swallows keys and feeds navigation tokens (`K ok`, `K cancel`, arrows, Tab, Page Up and Down, Backspace, Delete) and typed characters (`C`). Otherwise it takes only Horizon's own keys: Ctrl+L for Arrange, and the Hide all and Find keys from Settings. Alt combinations, the Windows keys and Print Screen always reach the game and Windows.
- Controller buttons still arrive through `ProcessUserEvent`. While Horizon captures input it consumes them; Accept and Cancel act on release, and a cancel that arrives both as a key token and as the game's event acts once. The left stick arrives through `OnLeftStickInput`; while Horizon captures input it is consumed too, so it does not scroll the hidden lists.

What a log cannot prove yet: whether a swallowed window message is enough to keep a click from the 3D editor. If the game reads buttons through raw input or DirectInput instead of window messages, the editor could still react under a Horizon panel, while the Horizon control still works. The close line `FACT input | ... raw=` counts `WM_INPUT` messages so the desktop run shows whether the raw input path exists. This is the first desktop gate below.

## What the panels read and send

| Panel | Game data | Game action |
| --- | --- | --- |
| Power (mock 1) | `PowerAllocation`, `ShipStats` | none; pips show the game's values |
| Selected module (mock 1) | `ModuleInfo`, `ModuleVariant`, `CostSummaryData` | none |
| Credits (mock 1) | `CostSummaryData` | none |
| Parts browser (mocks 1, 4, 5) | `PartEntries`, `UpgradeEntries`, `ModuleInfo` | `ShipEditor_PreviewShipPart`, `ShipEditor_SelectedShipPart`, `ShipEditor_ChangeModuleCategory` |
| Hints (mock 1) | `ShipBuilderHelpList`, `ControlMapData` | `ShipEditor_OnHintButtonActivated` with the hint's own event |
| Stats footer (mock 1) | `ShipStats` | none |
| Colours (mocks 6, 7) | `ColorInitializationData`, `ColorSelectionData`, `ColorSwatchesHue`, `ColorSwatchesSaturation`, `ColorSwatchesBrightness`, `ColorSwatchesRecentUI` | `ShipEditor_OnColorPickerTabChanged`, `ShipEditor_OnColorPickerControlChanged`, `ShipEditor_OnColorSliderMouseInput`, `ShipEditor_OnRecentColorSwatchClicked`, and the hint event for accept |
| Flight Check (mock 13) | `FlightCheckData` | `ShipEditor_OnFlightCheckTabChanged` |

Every event name is one the vanilla menu sends, with the same parameters. The movie never writes the parts array or category data, so categories another mod adds, such as ShipBuilderCategories (ESM only), come from the game as before.

The game panels the Horizon panels stand in for are hidden with alpha 0 and `mouseChildren = false`, never with `visible = false` and never moved or reparented. No plate is drawn behind a game panel. Arrow keys still move the game's hidden parts list; the browser re-feeds it in Horizon's filtered and sorted order. Flight Check's Weapons tab shows the game's own weapon groups panel, because Horizon has no data for it.

## Backend gaps, shown in the UI

These mock features have no game data or action. Each is drawn as in the mock and marked in place, never faked:

- Colours: the game applies colours to the parts selected before colour mode, so there is no "apply to" choice (`Not in the game: colors go to the parts you selected before Colors`). There is no "take from a part". A hex code is worked out from the game's hue, saturation and brightness, so it is shown with `~`.
- Pills: `Fits reactor` and `On my ship` have no game data (`No game data`), so pills with those rules match nothing. Value, class and card stats are known only for parts already previewed this visit.
- Settings: `Open Flight Check on errors` has no game signal (`No game signal`) and stays off.
- Flight Check messages have no fix actions in the game, so none are drawn.

## Files

The plugin reads and writes only these, all under `Documents\My Games\Starfield\Data\Interface\HorizonUI\shipbuilder\`:

- `HorizonShipBuilder.user.ini`: settings and Arrange spots. A value equal to its default is removed. Unknown lines and comments are kept.
- `ShipBuilderPills.json`: the pill profile. Each save first copies the old profile, read back in full, to `ShipBuilderPills.bak`, unless the old profile is empty or blank.
  - A profile that is not valid pill JSON, or holds NUL bytes, is renamed to `ShipBuilderPills.bad.json` and kept, and pill saves wait for the rename. The rename never replaces an existing `ShipBuilderPills.bad.json`: when one is there, or the rename fails, pill saves stay off until the builder is reopened, and the browser says why.
  - A profile that cannot be read (locked, a read error, or over 256 KiB), is too long for the movie, comes from a newer version or that the movie fails to take in stays as it is, and pill saves stay off with a line in the browser.
  - A pill change made before the profile has loaded waits for it. It is saved when there is no profile, an empty one or one just renamed. When a profile loads, its pills replace the change, and the browser says the change was not kept.
  - A visit that starts without a loaded profile (none, an empty or blank one, or one just renamed) keeps `ShipBuilderPills.bak` as it was until the builder closes, because it may hold the last good pills. After an empty or renamed profile the browser says so and names `ShipBuilderPills.bak`.
  - To go back to the pills in `ShipBuilderPills.bak`, close the builder, keep a copy of `ShipBuilderPills.json` if you want it, then copy `ShipBuilderPills.bak` over it. The backup is one copy deep: the first save of the next visit that loads a profile replaces it.
- `pills\user\*.json` and `schemes\user\*.ini`: exported pills and colour schemes. A file already there is never replaced. An export or a saved scheme whose name is taken gets the next free number, up to 9 (`Desert 2.ini`, holding `Name=Desert 2`), and the builder shows the name it wrote. When all nine names are taken, nothing is written and the builder says so. Exporting a scheme from `schemes\user` writes nothing and names its file.

It reads, and never writes, `pills\packs\*.json` and `schemes\packs\*.ini` in that folder and in `<Starfield>\Data\Interface\HorizonUI\shipbuilder\`, where a mod manager installs packs. It reads the HUD's `HorizonUI.user.ini` and `HorizonUI.default.ini` in `<Starfield>\Data\Interface\HorizonUI\`, read-only and only for "follow the HUD accent": the user file wins key by key, and a missing key takes the HUD's own default, cyan. With neither file, Settings shows `HUD not found` and following falls back to gold. File names are letters, digits, space, dash and underscore. Shared files are capped at 64 KiB and the profile at 256 KiB. Nothing is deleted, and `ShipBuilderPills.bad.json` is never replaced. Every write goes to a `.tmp` file that is flushed to disk and then renamed: over the old file for the settings and the profile, and never over any file for an export or a scheme. A settings save waits, and is retried, while the player file exists but cannot be read in full. A pill profile save is skipped, and the browser says so, when the old profile cannot be read in full, holds a NUL byte, or cannot be copied to `.bak`.

The movie shows these paths relative to `Documents\My Games\Starfield`, for example `Data\Interface\HorizonUI\shipbuilder\schemes\user\`. Mock 7 shows `shipschemes`; the real folder is `shipbuilder\schemes`, next to the pills.

The log holds counts, ids and tokens only. It never holds key names, typed characters, pill or scheme names, or file contents.

## Build the plugin

On the HorizonUI-Desktop builder, from the repo root:

```
xmake f -c -y -m releasedbg
xmake build -y HorizonShipBuilder
```

The target is `HorizonShipBuilder`. It does not link Horizon UI. The host logic test is `xmake build probe_logic_test`; on Linux, `g++ -std=c++20 -Ishipbuilder/src -DHSB_REPO_ROOT='"<repo>"' shipbuilder/tests/probe_logic_test.cpp -o plt && ./plt`. The Windows disk test, `xmake build profile_disk_test`, runs the plugin's own file code on a temp folder: real renames, sharing locks, read-only files and folders in a file's place. It must print `profile_disk_test passed`.

## Desktop builder: produce the two movies

The player does not compile these. Quit Starfield first. A stock install keeps `spaceshipeditormenu.swf` and `spaceshipeditormenu_lrg.swf` inside `Data\Starfield - Interface.ba2`, not as loose files. The builder extracts those two movies from the archive, splices the Horizon classes, and writes loose movies under `shipbuilder\Interface`. A from-scratch SWF would replace the builder, so do not make one. Compile against the classes already inside each vanilla movie: the Horizon classes import `Shared.AS3.Data.BSUIDataManager`, `Shared.AS3.Events.CustomEvent` and `Shared.GlobalFunc`, which the vanilla movie already contains.

`<Starfield>` below is the game folder, for example `C:\Program Files (x86)\Steam\steamapps\common\Starfield`.

If a loose movie is already in `Data\Interface`, check it against the stock SHA-256 values below. A stock copy can be spliced. Anything else came from another mod: stop and report it. Check the `Data\Interface` folder under `Documents\My Games\Starfield` too.

A plugin can also carry these movies in its own `.ba2`, and a Creation is a plugin. A Creation's files may sit in the `Data` folder under `Documents\My Games\Starfield` rather than the game folder. Before you splice, open or unpack each enabled plugin's `.ba2` with the archive tool below and look for `interface/spaceshipeditormenu.swf` and `interface/spaceshipeditormenu_lrg.swf`, and for the game card's library, `interface/spaceshipeditormenu_assetlibrary2.swf` and `interface/spaceshipeditormenu_assetlibrary2_lrg.swf`. A loose movie made from the game's archive would cover that plugin's menu movie. If one has any of them, stop and report which plugin. Do not change the other plugin's files.

If `dir` lists nothing and no plugin archive has the movies, extract from the game's archive:

```
dir /b "<Starfield>\Data\Interface\spaceshipeditormenu*.swf"
mkdir shipbuilder\work\ba2 shipbuilder\work\normal shipbuilder\work\lrg shipbuilder\Interface
bsarch unpack "<Starfield>\Data\Starfield - Interface.ba2" shipbuilder\work\ba2
```

`bsarch` may be `Archive2` with `-extract=shipbuilder\work\ba2` instead. Copy `spaceshipeditormenu.swf` and `spaceshipeditormenu_lrg.swf` out of the extract folder. Those copies are the ffdec inputs below. Do not write back into the `.ba2`.

For game version 1.16.244 the stock movies have these SHA-256 values. Check both copies before ffdec, for example with `certutil -hashfile shipbuilder\work\ba2\spaceshipeditormenu.swf SHA256`. `certutil` prints lower case, so compare without regard to case:

- `spaceshipeditormenu.swf`, 260994 bytes: `6A66089EE9410ECB126B4BEDE8BED81551E5661555AA1F50FA217C495404C2EC`
- `spaceshipeditormenu_lrg.swf`, 260965 bytes: `3457A49CF9B79A346C4B3FCFA7EF360B10CCC86D41899B6D8004DF12E90F2C67`

The `dir` line above also lists the builder's libraries. For game version 1.16.244, from one extract, a loose library is stock only with these values:

- `spaceshipeditormenu_assetlibrary2.swf`, 151358 bytes: `2B6D854C3C66973C2948246D1D1DA21A3ADA314B5FDD1899DA375FBCCB8052BC`
- `spaceshipeditormenu_assetlibrary2_lrg.swf`, 152427 bytes: `4793E8C3D710647D53D0C91333162E158DE7E1F70D1671A28A53F27A67F5370B`
- `spaceshipeditormenu_assetlibrary.swf`, 8335 bytes: `9352241D92EE288D6F4D1457E82F2F2CCD842CF9D4F1353EFD29DC38471DF624`

A different value means another mod's movie or another game version. Stop and report it rather than splicing.

```
ffdec -export script shipbuilder\work\normal shipbuilder\work\ba2\spaceshipeditormenu.swf
ffdec -export script shipbuilder\work\lrg shipbuilder\work\ba2\spaceshipeditormenu_lrg.swf
copy /Y shipbuilder\actionscript\HorizonShipBuilder.as shipbuilder\work\normal\
copy /Y shipbuilder\actionscript\HorizonShipBuilderProbe.as shipbuilder\work\normal\
copy /Y shipbuilder\actionscript\Hsb*.as shipbuilder\work\normal\
copy /Y shipbuilder\actionscript\HorizonShipBuilder.as shipbuilder\work\lrg\
copy /Y shipbuilder\actionscript\HorizonShipBuilderProbe.as shipbuilder\work\lrg\
copy /Y shipbuilder\actionscript\Hsb*.as shipbuilder\work\lrg\
```

When the source was a loose file, point ffdec at that loose path instead of `shipbuilder\work\ba2\...`.

Edit the exported `SpaceshipEditorMenu.as` in both work folders using `shipbuilder/actionscript/document_splice.as`: both imports, the member, the `onAddedToStage` lines (or the override when the decompile has none), the `hsb*` methods, the `ProcessUserEvent` early return, and the `OnLeftStickInput` early return. Every one of those methods must be present: the plugin calls `hsbProbePing`, `hsbTakeLines`, `hsbProbeStage`, `hsbSetDebug`, `hsbApply`, `hsbFeed`, `hsbSaved`, `hsbTakeFiles` and `hsbFiles`.

```
ffdec -importScript shipbuilder\work\ba2\spaceshipeditormenu.swf shipbuilder\Interface\spaceshipeditormenu.swf shipbuilder\work\normal
ffdec -importScript shipbuilder\work\ba2\spaceshipeditormenu_lrg.swf shipbuilder\Interface\spaceshipeditormenu_lrg.swf shipbuilder\work\lrg
```

Those two outputs are the movies. Before you package them, export each spliced movie's script and run the font gate. It fails if `HorizonShipBuilder` embeds a mapped face without checking that this movie exports it. That is the check for labels that draw as boxes while the stock timeline text still reads.

```
ffdec -export script shipbuilder\work\check-normal shipbuilder\Interface\spaceshipeditormenu.swf
ffdec -export script shipbuilder\work\check-lrg shipbuilder\Interface\spaceshipeditormenu_lrg.swf
python shipbuilder\font_export_gate.py --script shipbuilder\work\check-normal
python shipbuilder\font_export_gate.py --script shipbuilder\work\check-lrg
```

The same command with no `--script` checks the source in this repo. Pass `--dom` with the stock movie's `DOMDocument.xml` when you have the decompile: the gate then also reports that the stock movie does not export the mapped faces. Do not add a font import to either movie to satisfy the gate.

## Install and restore

Quit Starfield before every copy, delete, or move.

Loose paths the game prefers over the archive:

`<Starfield>\Data\Interface\spaceshipeditormenu.swf`

`<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf`

Named backup, used only when a loose movie is already there:

`%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup`

See whether loose movies exist:

```
dir /b "<Starfield>\Data\Interface\spaceshipeditormenu*.swf"
```

No file name means a stock archive install. Back up nothing. A listed name means a loose vanilla or another mod. Back that file up before you replace it:

```
mkdir "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup"
copy /Y "<Starfield>\Data\Interface\spaceshipeditormenu.swf" "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu.swf"
copy /Y "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf" "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu_lrg.swf"
```

Skip a `copy` whose source is missing. Then install the DLL and the loose movies:

```
copy /Y "build\windows\x64\releasedbg\HorizonShipBuilder.dll" "<Starfield>\Data\SFSE\Plugins\HorizonShipBuilder.dll"
mkdir "<Starfield>\Data\Interface"
copy /Y "shipbuilder\Interface\spaceshipeditormenu.swf" "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
copy /Y "shipbuilder\Interface\spaceshipeditormenu_lrg.swf" "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
```

With an older movie, or none, the plugin feeds no input and swallows nothing: it only logs the menu, window and HUD-message checks.

Restore, after you quit the game.

Stock archive install: delete the loose movies so the archive copies load again. Move them out instead of deleting if you want to keep them:

```
del "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
del "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
dir /b "<Starfield>\Data\Interface\spaceshipeditormenu*.swf"
```

The check passes when that `dir` prints no file name.

Loose movie that you backed up: put those files back, then confirm they match the backup:

```
copy /Y "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu.swf" "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
copy /Y "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu_lrg.swf" "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
fc /b "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu.swf" "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
fc /b "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu_lrg.swf" "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
```

`fc` prints no differences when the pair matches.

You can leave `HorizonShipBuilder.dll` in `Data\SFSE\Plugins` or remove that one file yourself. The plugin does not delete it.

## Desktop gates

Use a throwaway save: every ship action here is the game's own action. Run each gate on the normal movie, then on `spaceshipeditormenu_lrg.swf`. Log lines look like `FACT movie | ...`.

1. Clicks stay with Horizon. Open the builder: `FACT F19 | invoke=1 ping=0.2.0.0`, then `FACT movie | BUILDER 0.2.0.0`. Click a parts browser row, a pill, the gear, and a Settings switch with a part selected on the ship. Each control acts, and the ship does not deselect, select, or place anything under the panel. On close, `FACT input | presses=N eaten=M ... raw=R`: `eaten` counts presses inside Horizon panels. If the 3D editor still reacts to clicks on panels, the game reads the mouse another way (raw input when `raw` is above 0, otherwise likely DirectInput), and swallowing window messages is not enough. Report it with the log.
2. Clicks over the ship still build. Outside the panels, click, drag and use the wheel on the ship: the camera, selection and placement work as with this mod removed.
3. Keys. With nothing open, H folds every panel to its tab and the header button reads SHOW ALL (mock 12); H, or opening any tab, brings them all back. `/` opens Find in the browser. Type in Find: the letters go to the field and no builder hotkey fires. Esc closes the innermost thing first (Find, then a dialog, then Settings), one step per press, and never opens the exit prompt while Horizon has something open. Alt+Tab and Alt+F4 still work with a popup open.
4. Controller. With the pad, open Settings from the gear: Up and Down move the focus ring, A activates, B closes. With nothing open, every pad button does what it does with this mod removed.
5. Text. Faces: `FONT try=... pick=` names the face by index. `pick=0` means text uses the default face. `e1` to `e3` are the mapped names drawn as embedded text, and they count only when this movie exports that face (`Font.enumerateFonts(false)`). A `!` after a measure means the advances looked real and the movie does not export the face, so it was not used. On the stock editor that mark is expected on `e1` to `e3`, and the pick is `d1`, `d2` or `d3` (the same names through the font library). `n4` is the module-name field. Category tabs are turned. When the pick is a device face they are a picture of the label, so the words still read upward. If a tab is upright, the picture draw failed and the words are still the thing to read. Report the `pick` line with a screenshot of the power card, the module card, the parts list and Settings. Every custom label is a word. A box, dot or dash in place of a letter is a miss. Body text is 13 px on the normal movie and 16 px on the large movie, and captions are 12 px and 15 px. Check every language you use.
6. Data. A hab, a weapon and a reactor or shield: the Selected Module card matches the game's card with this mod removed and every other mod, Creations included, left as it is. Power pips, credits, and the stats footer match the game's numbers.
7. Categories. The browser's category tabs and the grid (mock 4) list the same categories, in the same order, as with this mod removed, including ones another mod adds. Opening the grid steps once around the categories to learn their names and counts (`CATEGORIES read total=`), and ends on the category it started from.
8. Colours (mocks 6, 7). Select parts, enter colour mode, move a slot's sliders, pick a recent swatch, preview a scheme and accept or cancel. Export a scheme and find it in `schemes\user`. Save a scheme under the name of one already in `schemes\user`: a new `<name> 2.ini` appears, and the first file is unchanged. The applied colours match the game's own picker.
9. Pills (mocks 2, 3, 5, 14, 15, 16). Make a pill, edit it, export it (`pills\user`) and export it again: the second export is `<name> 2.json`, and the first file is unchanged. Import a pack, delete a pill. Close and reopen the builder: pills are kept, and `ShipBuilderPills.bak` exists after the second save. Close the builder, note the size of `ShipBuilderPills.bak`, delete the last `}` of `ShipBuilderPills.json` and reopen: the browser says `The damaged pills file is kept as ShipBuilderPills.bad.json` and `An older copy may be in ShipBuilderPills.bak`, and that file holds the broken text. Edit a pill twice: `ShipBuilderPills.bak` keeps its size. Edit a pill, close, break the new `ShipBuilderPills.json` the same way and reopen: the browser says `Move ShipBuilderPills.bad.json away, then reopen the builder`, pill edits are not saved, and none of the three pill files changes. Close the builder, move `ShipBuilderPills.bad.json` away, empty `ShipBuilderPills.json` (0 bytes) and reopen: the browser says `The pills file was empty, so the starter pills are shown`, and two pill edits leave `ShipBuilderPills.bak` as it was.
10. Columns, sort, density, group by maker (mocks 5, 8): each survives a reopen.
11. Arrange (mock 17), from Ctrl+L or the gear: drag panels, arrows nudge, Shift+arrows nudge further, Enter saves, Esc cancels, Reset puts panels home. Saved spots survive a reopen and a resolution change.
12. Flight Check (mock 13): the browser list turns read-only as soon as Flight Check opens; tabs switch with the mouse and with the game's keys; the Weapons tab shows the game's own panel.
13. Settings (mock 9): every switch and slider changes the builder at once and survives a reopen.
14. HUD message. Close the builder once with `Probe=1` in the player file: `FACT F31 | ... thread=ship-advance` or `thread=hud-advance`.

Bring back the log and a screenshot of each mock's screen on both movies.

## Unknowns

- Whether swallowed window messages keep clicks from the 3D editor (gate 1).
- Whether a device-face category tab stays sharp after it is drawn into a picture (gate 5). The words have to be there either way.
- StarUI detection is by file name only. `StarUIShipBuilder.dll` loaded means Horizon stands down (mock 10). A file named `StarUI*` in `Data\SFSE\Plugins` or `Data\Interface`, or `StarUI*Ship*` in `Data`, shows the notice (mock 11). The StarUI Ship Builder 1.4 copy checked for this work is staged in Vortex, not deployed, and only its `Interface` movies were listed. So neither check is known to fire for it. Do not enable StarUI Ship Builder with this mod.
- Colour slider steps are sent one per frame; whether the game applies each step before the next is untested.
- How fonts draw other scripts' glyphs is untested. Every stock language config maps all three face candidates (`$NB_Grotesk_Semibold`, `$MAIN_Font_Bold`, `$MAIN_Font`). The stock editor does not export those faces for a new text field. Timeline labels keep the glyphs baked into the movie. Horizon text uses an embedded face only when the movie exports it, and otherwise uses the font library.

## Vortex FOMOD

This package is Horizon Ship Builder alone. It is a FOMOD installer, the same kind of installer as Horizon UI, and it has no component picker. It does not install any HUD files. Quit the game first. The two movies in the zip must be the spliced movies, not stock archive copies, so neither matches a stock SHA-256 value above. The default ini ships with the mod and documents every key. The plugin reads the player file under Documents when that file exists.

StarUI Ship Builder ships its own `spaceshipeditormenu.swf`, `spaceshipeditormenu_lrg.swf`, and game card library. With both mods enabled, Vortex reports a file conflict, and either winner leaves a mix the checks above did not cover. Do not enable StarUI Ship Builder with this mod.

From the repo root, after the desktop builder has produced the DLL and both movies, and after `font_export_gate.py` has passed on both spliced movies:

```
sh shipbuilder/package_vortex.sh build\windows\x64\releasedbg\HorizonShipBuilder.dll shipbuilder\Interface\spaceshipeditormenu.swf shipbuilder\Interface\spaceshipeditormenu_lrg.swf HorizonShipBuilder-0.2.0.0.zip
```

The script writes `fomod/info.xml` and `fomod/ModuleConfig.xml` into the zip. The author in `fomod/info.xml` is Moragar. The version is the plugin version. The script refuses to write the zip if those two files are missing, if the author or version does not match, or if the staged tree is anything other than the four install files plus those two FOMOD files.

The zip contains only:

```
fomod/info.xml
fomod/ModuleConfig.xml
00 Ship Builder/SFSE/Plugins/HorizonShipBuilder.dll
00 Ship Builder/Interface/spaceshipeditormenu.swf
00 Ship Builder/Interface/spaceshipeditormenu_lrg.swf
00 Ship Builder/Interface/HorizonUI/shipbuilder/HorizonShipBuilder.default.ini
```

`ModuleConfig.xml` installs the `00 Ship Builder` folder into the Data folder of the game root. That is the builder DLL, both editor movies, and the default ini. There is no HUD plugin and no HUD movie. In Vortex, install that zip from file. Do not merge this zip with the HUD package.
