# Interface

Quit Starfield before you copy or restore these movies. The probe movies, once the desktop builder has produced them, are installed over:

`<Starfield>\Data\Interface\spaceshipeditormenu.swf`

`<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf`

Keep the vanilla files in this named backup:

`%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup`

Backup:

```
mkdir "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup"
copy /Y "<Starfield>\Data\Interface\spaceshipeditormenu.swf" "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu.swf"
copy /Y "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf" "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu_lrg.swf"
```

Install the builder's two outputs:

```
copy /Y "shipbuilder\Interface\spaceshipeditormenu.swf" "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
copy /Y "shipbuilder\Interface\spaceshipeditormenu_lrg.swf" "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
```

Restore, after quitting the game again:

```
copy /Y "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu.swf" "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
copy /Y "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu_lrg.swf" "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
```

Check that vanilla is back. `fc` prints no differences when the files match:

```
fc /b "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu.swf" "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
fc /b "%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup\spaceshipeditormenu_lrg.swf" "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
```

P0 does not put a from-scratch menu in the game. The full builder steps and the throwaway-save warning are in `shipbuilder/README_P0.md`.
