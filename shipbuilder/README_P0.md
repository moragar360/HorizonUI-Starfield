# Horizon Ship Builder, phase P0

Read-only probe. Version 0.0.2.0. It answers the live tests in spec F.1 as far as a log can, including Arrange tests #16, #17, and #18.

Plugin 0.1.1.0 draws the gold screens and Arrange on the default path. The probe overlay and the F7, F8, and F6=dump keys stay off unless the user file sets Probe=1. Button prompts stay icons. The parts list stays the game's list. Ctrl+L and the gear button open Arrange. The user file is `Documents\My Games\Starfield\Data\Interface\HorizonUI\shipbuilder\HorizonShipBuilder.user.ini`. A ping of 0.1.1.0 means the gold splice is live. The P0.1 steps below still describe the probe when Probe=1.

The probe writes one file:

`Documents\My Games\Starfield\SFSE\Logs\HorizonShipBuilder_probe.log`

It does not change the ship, a save, or the game folder. It does not swallow keys or mouse buttons. A window message is logged and then passed on. The full-stage layer starts off. Turn it on only for the steps that say so. Use a ship you can spare if you try color Accept or a delete, because those are the game's own actions, not the probe's.

SFSE also writes its usual plugin log when the DLL loads. The facts for these tests are the probe log above.

## Build the plugin

On the HorizonUI-Desktop builder, from the repo root:

```
xmake f -c -y -m releasedbg
xmake build -y HorizonShipBuilder
```

The target is `HorizonShipBuilder`. It does not link Horizon UI. Copy `build\windows\x64\releasedbg\HorizonShipBuilder.dll` to `Data\SFSE\Plugins\`. Leave the game's menu files alone until the movie steps below.

## Desktop builder: produce the two probe movies

The player does not compile these. Quit Starfield first. A stock install keeps `spaceshipeditormenu.swf` and `spaceshipeditormenu_lrg.swf` inside `Data\Starfield - Interface.ba2`, not as loose files. The builder extracts those two movies from the archive, splices the probe, and writes loose probe SWFs under `shipbuilder\Interface`. A from-scratch SWF would replace the builder, so do not make one. Compile against the classes already inside each vanilla movie. `HorizonShipBuilderProbe.as` imports `Shared.AS3.Data.BSUIDataManager`, which the vanilla movie already contains.

`<Starfield>` below is the game folder, for example `C:\Program Files (x86)\Steam\steamapps\common\Starfield`.

If a loose movie is already in `Data\Interface`, check it against the stock SHA-256 values below. A stock copy can be spliced. Anything else came from another mod: stop and report it. Check the `Data\Interface` folder under `Documents\My Games\Starfield` too.

A plugin can also carry these movies in its own `.ba2`, and a Creation is a plugin. A Creation's files may sit in the `Data` folder under `Documents\My Games\Starfield` rather than the game folder. Before you splice, open or unpack each enabled plugin's `.ba2` with the archive tool below and look for `interface/spaceshipeditormenu.swf` and `interface/spaceshipeditormenu_lrg.swf`, and for the game card's library, `interface/spaceshipeditormenu_assetlibrary2.swf` and `interface/spaceshipeditormenu_assetlibrary2_lrg.swf`. A loose movie made from the game's archive would cover that plugin's menu movie, and the gold card would hide that plugin's card. If one has any of them, stop and report which plugin. Do not change the other plugin's files.

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

The `dir` line above also lists the builder's libraries. A loose library is stock only with these values:

- `spaceshipeditormenu_assetlibrary2.swf`, 151358 bytes: `2B6D854C3C66973C2948246D1D1DA21A3ADA314B5FDD1899DA375FBCCB8052BC`
- `spaceshipeditormenu_assetlibrary2_lrg.swf`, 152427 bytes: `4793E8C3D710647D53D0C91333162E158DE7E1F70D1671A28A53F27A67F5370B`
- `spaceshipeditormenu_assetlibrary.swf`, 8335 bytes: `9352241D92EE288D6F4D1457E82F2F2CCD842CF9D4F1353EFD29DC38471DF624`

A different value means another mod's movie or another game version. Stop and report it rather than splicing.

```
ffdec -export script shipbuilder\work\normal shipbuilder\work\ba2\spaceshipeditormenu.swf
ffdec -export script shipbuilder\work\lrg shipbuilder\work\ba2\spaceshipeditormenu_lrg.swf
copy /Y shipbuilder\actionscript\HorizonShipBuilder.as shipbuilder\work\normal\HorizonShipBuilder.as
copy /Y shipbuilder\actionscript\HorizonShipBuilder.as shipbuilder\work\lrg\HorizonShipBuilder.as
copy /Y shipbuilder\actionscript\HorizonShipBuilderProbe.as shipbuilder\work\normal\HorizonShipBuilderProbe.as
copy /Y shipbuilder\actionscript\HorizonShipBuilderProbe.as shipbuilder\work\lrg\HorizonShipBuilderProbe.as
```

When the source was a loose file, point ffdec at that loose path instead of `shipbuilder\work\ba2\...`.

Edit the exported `SpaceshipEditorMenu.as` in both work folders using `shipbuilder/actionscript/document_splice.as`. Add both imports, the member, and the methods in those notes. If that decompile already has `onAddedToStage`, append the gold lines at the end of it. If it has no `onAddedToStage`, add the override from the splice notes. Return early from `ProcessUserEvent` only when Arrange or Settings wants the key.

```
ffdec -importScript shipbuilder\work\ba2\spaceshipeditormenu.swf shipbuilder\Interface\spaceshipeditormenu.swf shipbuilder\work\normal
ffdec -importScript shipbuilder\work\ba2\spaceshipeditormenu_lrg.swf shipbuilder\Interface\spaceshipeditormenu_lrg.swf shipbuilder\work\lrg
```

Those two outputs are the probe movies.

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

Skip a `copy` whose source is missing. Then install the DLL and the loose probe movies:

```
copy /Y "build\windows\x64\releasedbg\HorizonShipBuilder.dll" "<Starfield>\Data\SFSE\Plugins\HorizonShipBuilder.dll"
mkdir "<Starfield>\Data\Interface"
copy /Y "shipbuilder\Interface\spaceshipeditormenu.swf" "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
copy /Y "shipbuilder\Interface\spaceshipeditormenu_lrg.swf" "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
```

The DLL still answers the menu, window, form, and HUD-message checks if the movie is not spliced yet. Movie lines stay empty until the splice is in the loaded SWF.

Restore, after you quit the game.

Stock archive install: delete the loose probe movies so the archive copies load again. Move them out instead of deleting if you want to keep the probe files:

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

You can leave `HorizonShipBuilder.dll` in `Data\SFSE\Plugins` or remove that one file yourself. The probe does not delete it.

## In the game

Launch Starfield with SFSE. Open the ship builder. A panel sits at the top left. Its text is 13 px. Capture is off. The log grows while the builder is open.

Each step says what you do, then which log line to read. Lines look like `FACT F19 | ...`. Visual answers (the camera, a placed part, the cursor) are what you see. The log cannot see the 3D view.

### #1 Movie and menu

Open the builder. Read `FACT F19`. It records the menu name `SpaceshipEditorMenu`, whether the menu object exists, and whether `hsbProbePing` invoked. A ping of `0.0.2.0` means the splice is live. `invoke=0` means the loaded movie does not have the splice yet.

`FACT movie | MOVIE url=` names the SWF that loaded. `SUBSCRIBE ok` and `DATA` lines list provider keys for PartEntries, ModuleInfo, ShipStats, CostSummaryData, ShipBuilderHelpList, and the Color providers. `CLIPS` lists which document clips are present and their sizes. Satellite movies that are not separate menus show up only as clips or as the document URL. `movie created` lines name ship-related menus SFSE reports.

### #2 Keys and a text field

With capture off, press H and the slash key. Read `FACT F16` for the window (`key=H`, `key=Slash`) and `FACT movie | KEY` if the movie heard them. Then click the type-in box and type letters, a hex word, Backspace, and Delete. The box line is `field=true`. `AFTER key` says whether ModuleInfo, ShipStats, color, or the exit data changed in the next half second. Watch the ship: if a part vanishes, the game still treated Delete as a delete. This probe does not swallow, so it does not answer "can a later build swallow" by doing it. The log says `swallowed=0`.

### #3 Colors

Press F7 and read `FACT movie | MARK`. The panel button is only a label. Clicks may never reach it. Change the game's color sliders. Press Mark colors again. Cancel, then press Mark colors again. The `COLOR` and `MARK` lines are the HSB values the providers sent. Do this with one part selected, then two, then the whole ship. Accept only on a ship you are willing to repaint. The probe never sends a color event. Unset colors show up as empty HSB fields if the provider omits them.

### #4 Category jump

Not run. Sending a category offset can change the builder. The probe does not send one.

### #5 Variants

Not run as a write. Left and Right are observed in #17. The probe does not pick a variant by form id.

### #6 One category through the DLL

Select a category. `FACT movie | PARTS` is the category name, index, stat name, and row fields. `FACT F2a` is a read-only lookup of up to 24 form ids from that category: editor id and form type. Maker, class, and size are logged as `not-exposed` because this probe does not invent them from the name. Change category to record another set. The lookup cap is 40 per category burst.

### #7 Costs

`FACT movie | COST` logs `uTotalCredits` when that provider exists, in the builder and at a vendor if you open one. The probe does not perform a swap.

### #8 Files

Not run. The probe refuses every path except its own log. It does not write under Steam `Data` or under saves.

### #9 Scale

`FACT movie | RECT` is `visibleRect` when the movie exposes it, and `stage=` is the stage size. `CLIPS` is the panel sizes in the loaded movie. Repeat on the normal movie and on `spaceshipeditormenu_lrg.swf`. This one session records one resolution. #18 is the full set.

### #10 Conflicts

Install StarUI Ship Builder, the Free Lanes patch, Compact Ship Builder UI, or UIPlayNice only if you already want that test. The probe does not detect them. Compare `MOVIE url` and whether the vanilla clips are present. Try each load order yourself. The probe still only writes its log.

### #11 Freeze

Not provoked. Do not open the HUD arrange screen from inside the builder for this probe. The old freeze is out of scope here.

### #12 Controller

If you use a pad, press the sticks, the d-pad, and the face buttons in the builder. The window hook may not see pad input. Record what the builder did, and any `USER` or `KEY` line that appears. A pad-only pass is still yours to watch.

### #13 HUD message

Close the builder once. The probe posts one message, one time per launch: "Horizon Ship Builder probe: this line is only a test. Nothing was changed." By design that post runs on the ship builder movie's AdvanceFrame when that movie advances after it closes. HUDMenu's AdvanceFrame posts it when the ship movie is not the one advancing. Read `FACT F31`. `thread=ship-advance` or `thread=hud-advance` names which one ran. `notify=1` means the call returned. `GetEventSource faulted` means the address lookup failed and the on-screen line was not sent. The close event's opening flag is `FACT F19 | closeEvent`.

### #14 Hex field

Use the same type-in box as #2. Type a hex value such as `A1B2C3`. Read `KEY` with `field=true`. Watch whether G, J, or another builder hotkey also fires as a `USER` line while the box is focused.

### #15 FOMOD

Not in this probe. Packaging is a later branch.

### #16 Arrange input

Capture stays off. Move the mouse over the 3D view, click, drag, and use the wheel. A `FACT movie | STAGE` line means the movie received that event. No STAGE line for a click on the ship means the movie did not see it. `FACT F17` is the same event at the game window (`msg` is the Windows message, `swallowed=0`). `FACT F16 | open cursorQuery` records whether Windows reported the cursor as showing. That is the native cursor check.

Press L, then Ctrl+L, with capture off and with no text box focused. `FACT F16` shows `key=L` and `ctrl=0` or `ctrl=1`. Watch the builder. A window line proves the key reached the probe. It does not prove the builder ignored it. Write down what the builder and any other mod did.

### #17 Arrange capture

Use a throwaway save for this test. With the capture layer on, the game can still delete a part, change a variant, move the floor, undo, or open the exit confirm. Those are the game's own actions. The probe only records them.

Press F8 to turn on Capture layer. The stage gets a light blue wash. The panel stays on top. Press F8 again, after a short pause, to turn it off. The hook still forwards every message.

- Drag across the 3D view. Read `LAYER` for down, move, and up. Watch the camera. In Add mode, with a ghost part, click the view and watch whether a part is selected or placed. `AFTER layer down` compares the data feeds. A camera move may leave `same=1`.
- Press Left and Right. Watch the variant. Read `USER` if the splice logged the event, and `AFTER`.
- Press Delete and Backspace. Watch whether a piece is removed.
- Press R and F. Watch the floor.
- Press Z and Ctrl+Z. Watch for a flip or an undo.
- Press Esc. `EXIT` changes if the exit confirmation data changed. Watch the confirm dialog.
- Repeat the same pass with Horizon UI installed, then with `HorizonUI.dll` removed. `FACT F37` says whether that DLL was loaded, whether the probe installed its procedure, and on close whether it restored the previous procedure. If a newer procedure is on top, the probe leaves it there, stays behind it, and stops logging until the builder opens again. Run the Core-present pass and the Core-absent pass in two launches so the HUD-message test and the hook each start clean.

### #18 Arrange layout

The probe does not save a layout and does not write an ini. Restart survival is not tested.

At each of 1080p, 1440p, 3440x1440, and 1280x720, open the builder once on the normal movie and once on the large-font movie. Read `RECT`, `stage=`, and `CLIPS` for that session. Those are the measurements a later layout can clamp to. Changing resolution during one visit also logs `RESIZE` and a new `RECT`.

## P0.1

Version 0.0.2.0, after the first in-game run. Rebuild both probe movies from the updated script and the splice notes (`hsbProbeHotkey` and `hsbProbeStage`), and copy the new DLL, before this pass. The panel copies its text face and embed flag from a vanilla text field in the loaded movie. If that copy misses, the fallback is an embedded face only. The face name is not printed. Clicks still may not reach the movie, so the actions are keys. `FACT boot` records `F7=mark`, `F8=capture`, and `F6=dump`. The panel shows the same three. Dump is F6, not F9. F9 is Quickload, and the probe does not swallow, so that key would load a save. F6 is not a default gameplay bind and it is not one of the builder keys already in use.

Enter build mode. Select a part and a category. Press F7, then F8, then F8 again after a short pause, then F6. Read `HOTKEY`, `MARK`, `CAPTURE`, and `DUMP`. `DUMP` is the current PartEntries, ModuleInfo, and ShipStats snapshot. An empty hangar list is still a useful dump: it should say the count is 0 until a category has rows.

Then repeat #16 and #17. `FACT movie | STAGE` is a mouseDown, mouseUp, mouseWheel, or click the stage heard. `FACT movie | PANEL` is the same event on the panel. No PANEL line and no STAGE line for a click means the movie never got it. `FACT map` is once per open: the window client size next to the stage size. `FACT movie | HELP` is the vanilla ShipBuilderHelpList keys, once per open. The probe still does not swallow. `swallowed=0` stays on the window lines.

## What the log is for

Bring the probe log back with a note of what you saw the ship do on #16 and #17. Those two together decide whether a later Arrange mode can rely on a full-stage layer, and whether the window hook can sit beside Horizon UI.

## 0.1.1.0 FONT PROBE + one-card candidate

This pass is a font probe and one Selected Module card candidate. Neither is proven in game. The probe reports whether Horizon text can use a game face that has the glyphs, and the card stays a candidate until the checks below pass. The parts list, categories, scrolling, keyboard, pad, and mouse stay the game's. The movie does not read or send category data, so categories, including ones another mod adds, come from the game as before. Power, credits, stats, and the hangar overview are unchanged.

The builder movies embed no fonts. Their text names a font such as `$MAIN_Font_Bold`, and each language's `fontconfig` maps that name to a face in the game's font library (`fonts_en.swf`, `fonts_ja.swf`, or `fonts_zhcn.swf`). The three candidates are those names: `$NB_Grotesk_Semibold` (the game card's title), `$MAIN_Font_Bold` (the menu's own text), and `$MAIN_Font`. Every stock language config maps all three. The movie does not use the Horizon font names that the HUD package adds to the English config, so it needs no other Horizon mod. A mapped name only means the face is there to try. Whether it passes in game is what `FONT` reports.

The face test runs when the builder opens. `FONT try=` lists each candidate by index as wide/narrow/tall widths and a `+` or `-`: `e1` to `e3` are the mapped names as embedded text, `n4` is the face of the game's module name field (`n4=na` when that field was not found), and `d1` to `d3` are the mapped names as device text. `n=` and `nd=` are the same widths for a name that cannot exist, embedded and device. `pick=` names the first candidate that passed. `pick=0` means none passed. The movie then tries again at frames 30 and 120, three tries in all. `FONTSRC` codes the face of five game text fields: `f1` to `f3` match a mapped candidate, `x$` is another mapped name, `x` is a plain face, `x0` has none, and `na` means the field was not found. Each code but `na` ends in `e` for embedded text or `d` for device text, as in `f1e`. Face names are not printed.

The face test measures Latin letters. Every stock language config maps the candidates, but whether a face has another script's glyphs, and how it draws them, is untested. In a language that does not use Latin letters, check the card for boxes before relying on it. `FONTSRC name=` with `f1` to `f3` means the game's own module name uses a mapped candidate.

`MODCARD listen ok` means the movie subscribed to ModuleInfo, the same data the game card reads. `MODCARD listen miss` means it could not, and the game card stays. With a face picked, select a part. The gold card takes the game card's place. The game card is not drawn by the menu movie: the menu places `ModuleInfoCard_mc`, an instance of `ModuleInfoCard` from `spaceshipeditormenu_assetlibrary2.swf` (`_lrg` for the large menu). The gold card sits just above that instance. The game card stays on the menu at alpha 0, so the menu keeps filling, sizing, and showing it. `MODCARD on` adds `rows=` (stats shown, at most 10), `skills=` (at most 2), `keys=` (fields that kept a `$` key, so translation did not run on the new text), `inb=` (the build mode flag), and `w=` (card width). A new `MODCARD on` line is written when those counts change. Any other `MODCARD` state names why the game card shows instead: `face`, `conflict`, `map`, `clip`, `data`, `paint` (drawing the card failed; the next payload tries again), `hidden`, `hangar`, or `arrange` (Arrange was open when the card would have come up).

The card shows what ModuleInfo sends: name, up to 10 stats, description, up to 2 required skills, value, and mass. Numbers follow the game card: two places cut, not rounded, percent as a whole number, a class stat as a letter, and no thousands separator (1560, not 1,560). A changed stat gets a green or red chip with the size of the change. The chip rounds away float noise at six places before it cuts, so it can read +0.29 beside a value the game cut to 0.28. A change too small to show at those places gets no chip. A chip too wide for its room drops its places, or shows only its sign. The mock's subtitle, mass chip, and swap cost line are not drawn, because ModuleInfo does not carry them. The maker logo and the skill badge art are drawn by the game card, so they are hidden with it. A card taller than the room below its spot is lifted to stay on screen. In Arrange it sits exactly on the game card's spot.

Check on the normal movie, then on `spaceshipeditormenu_lrg.swf`:

- A hab, a weapon, and a reactor or shield, from whichever category holds each. Compare each with a screenshot of the same part taken with this mod removed and every other mod, Creations included, left as it is. `MODVALS` lines put each payload number next to the text the card showed: `cost=` and `mass=`, then `s1=` to `s10=` as value/diff/percent flag, `>`, then the shown value and chip. They are written when a module's values change, for up to 24 modules per visit. A class stat is a letter.
- Text is readable, with no boxes. Small card text is 13 px on the normal movie and 16 px on the large movie.
- The parts list, categories, scrolling, keyboard, pad, and mouse work as before. That includes categories another mod adds: the same tab names, order, and parts as with this mod removed.
- The hangar overview keeps the game card.
- Arrange, from Ctrl+L or the gear: the outline is the gold card. Move it and Save. Close and reopen the builder, and it is in the same spot. Reset puts it home. Cancel undoes a move.
- Settings and keyboard focus, in build mode with the parts list showing. Click the hex field: the log shows `SETTINGS hex focus=` with the holder before and after `>`, here `list>hex`, and the code is selected. Each click selects the whole code again. Type six characters, then CUSTOM: the log shows `SETTINGS custom focus=hex length=6`, then `HEX` and the code, and the gold changes to it. Typing that leaves the code unchanged is a failure even when the log reads `hex`. Close Settings four ways, reopening between them: DONE, Esc, a swatch, and ARRANGE PANELS followed by Cancel. Each close writes `SETTINGS close focus=` with the holder before and after `>`. When before is `hex` or `ours`, after must read the holder the hex click read before `>`, here `list`. Otherwise after equals before. Then the arrow keys still move the parts list, and Enter does what it does with this mod removed. After reading `hex` or `ours`, or arrows that stop, is a failure: bring back the log. A first hex click that reads `hex>hex` or `ours>hex` means the game moved focus before the mod could note the holder. Report it, because then the close falls back to the parts list while it shows, or to nothing.
- Repeat one hex click and one close wherever the gear shows: in the hangar overview, in Flight Check, in paint mode, and while renaming the ship. The close's after must read what that hex click read before `>`, and that screen's keys work as before.
- Esc and the pad's B button close Settings and Arrange and do nothing else: no exit prompt, no part deselected, and build mode stays. Check Esc tapped and held for about a second, and B the same, in Settings and in Arrange. Settings and Arrange act when the key or button is released, as the game's buttons do, and neither half should reach the game. Enter in Arrange acts as OK, also on release. Arrange's arrow keys act on the press and repeat while held. Click OK and CANCEL in Arrange with the mouse: the click does not reach the parts list or the game's buttons.

Bring back the log and a screenshot of the card for each part type on both movies.

## Vortex zip

This package is Horizon Ship Builder alone. It is not the HUD installer and it has no component picker. Quit the game first. The two movies in the zip must be the spliced movies, not stock archive copies, so neither matches a stock SHA-256 value above. The default ini ships with the mod. The plugin still reads the player file under Documents when that file exists.

StarUI Ship Builder ships its own `spaceshipeditormenu.swf`, `spaceshipeditormenu_lrg.swf`, and game card library. With both mods enabled, Vortex reports a file conflict, and either winner leaves a mix the checks above did not cover. Do not enable StarUI Ship Builder with this mod. The mod's own StarUI checks look for a `StarUIShipBuilder.dll` module and a menu clip named for StarUI. StarUI Ship Builder 1.4 ships only Interface files, so neither check is known to fire for it, and the gold card can cover its card. This rule is the guard.

From the repo root, after the desktop builder has produced the DLL and both movies:

```
sh shipbuilder/package_vortex.sh build\windows\x64\releasedbg\HorizonShipBuilder.dll shipbuilder\Interface\spaceshipeditormenu.swf shipbuilder\Interface\spaceshipeditormenu_lrg.swf HorizonShipBuilder-0.1.1.0.zip
```

The zip contains only:

```
Data/SFSE/Plugins/HorizonShipBuilder.dll
Data/Interface/spaceshipeditormenu.swf
Data/Interface/spaceshipeditormenu_lrg.swf
Data/Interface/HorizonUI/shipbuilder/HorizonShipBuilder.default.ini
```

In Vortex, install that zip from file. The deployment root is the game root (.). The archive contains one Data folder, so the install yields Data/SFSE/Plugins and Data/Interface. It does not nest another Data folder. Do not merge this zip with the HUD package.
