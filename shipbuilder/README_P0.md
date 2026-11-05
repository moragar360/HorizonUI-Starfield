# Horizon Ship Builder, phase P0

Read-only probe. Version 0.0.1.0. It answers the live tests in spec F.1 as far as a log can, including Arrange tests #16, #17, and #18.

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

## Compile the two movies

This repo does not contain a compiled menu. A from-scratch SWF would replace the builder, so do not make one.

1. Copy the game's `spaceshipeditormenu.swf` and `spaceshipeditormenu_lrg.swf` to a work folder. Leave the copies in the game untouched until the work copies compile.
2. Add `shipbuilder/actionscript/HorizonShipBuilderProbe.as` to the ActionScript sources for those movies. The same class goes in both.
3. Follow `shipbuilder/actionscript/document_splice.as`. Add the member, the two methods, the `onAddedToStage` lines, and the first lines of `ProcessUserEvent`. Do not return early from `ProcessUserEvent`.
4. Compile both movies with the desktop builder.
5. When you are ready to test, put the two results where the game loads those menu names. Keep the vanilla files so you can put them back yourself. The probe never deletes or moves them.

The DLL still answers the menu, window, form, and HUD-message checks if the movie is not spliced yet. Movie lines stay empty until the splice is in the loaded SWF.

## In the game

Launch Starfield with SFSE. Open the ship builder. A panel sits at the top left. Its text is 13 px. Capture is off. The log grows while the builder is open.

Each step says what you do, then which log line to read. Lines look like `FACT F19 | ...`. Visual answers (the camera, a placed part, the cursor) are what you see. The log cannot see the 3D view.

### #1 Movie and menu

Open the builder. Read `FACT F19`. It records the menu name `SpaceshipEditorMenu`, whether the menu object exists, and whether `hsbProbePing` invoked. A ping of `0.0.1.0` means the splice is live. `invoke=0` means the loaded movie does not have the splice yet.

`FACT movie | MOVIE url=` names the SWF that loaded. `SUBSCRIBE ok` and `DATA` lines list provider keys for PartEntries, ModuleInfo, ShipStats, CostSummaryData, ShipBuilderHelpList, and the Color providers. `CLIPS` lists which document clips are present and their sizes. Satellite movies that are not separate menus show up only as clips or as the document URL. `movie created` lines name ship-related menus SFSE reports.

### #2 Keys and a text field

With capture off, press H and the slash key. Read `FACT F16` for the window (`key=H`, `key=Slash`) and `FACT movie | KEY` if the movie heard them. Then click the type-in box and type letters, a hex word, Backspace, and Delete. The box line is `field=true`. `AFTER key` says whether ModuleInfo, ShipStats, color, or the exit data changed in the next half second. Watch the ship: if a part vanishes, the game still treated Delete as a delete. This probe does not swallow, so it does not answer "can a later build swallow" by doing it. The log says `swallowed=0`.

### #3 Colors

Press Mark colors and read `FACT movie | MARK`. Change the game's color sliders. Press Mark colors again. Cancel, then press Mark colors again. The `COLOR` and `MARK` lines are the HSB values the providers sent. Do this with one part selected, then two, then the whole ship. Accept only on a ship you are willing to repaint. The probe never sends a color event. Unset colors show up as empty HSB fields if the provider omits them.

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

Close the builder once. The probe posts one message, one time per launch: "Horizon Ship Builder probe: this line is only a test. Nothing was changed." Read `FACT F31`. `notify=1` means the call returned. `GetEventSource faulted` means the address lookup failed and the on-screen line was not sent. The close event's opening flag is `FACT F19 | closeEvent`.

### #14 Hex field

Use the same type-in box as #2. Type a hex value such as `A1B2C3`. Read `KEY` with `field=true`. Watch whether G, J, or another builder hotkey also fires as a `USER` line while the box is focused.

### #15 FOMOD

Not in this probe. Packaging is a later branch.

### #16 Arrange input

Capture stays off. Move the mouse over the 3D view, click, drag, and use the wheel. A `FACT movie | STAGE` line means the movie received that event. No STAGE line for a click on the ship means the movie did not see it. `FACT F17` is the same event at the game window (`msg` is the Windows message, `swallowed=0`). `FACT F16 | open cursorQuery` records whether Windows reported the cursor as showing. That is the native cursor check.

Press L, then Ctrl+L, with capture off and with no text box focused. `FACT F16` shows `key=L` and `ctrl=0` or `ctrl=1`. Watch the builder. A window line proves the key reached the probe. It does not prove the builder ignored it. Write down what the builder and any other mod did.

### #17 Arrange capture

Turn on Capture layer. The stage gets a light blue wash. The panel stays on top so you can turn it off. The hook still does not swallow.

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

## What the log is for

Bring the probe log back with a note of what you saw the ship do on #16 and #17. Those two together decide whether a later Arrange mode can rely on a full-stage layer, and whether the window hook can sit beside Horizon UI.
