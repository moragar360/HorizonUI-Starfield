# Interface

Quit Starfield before you copy, delete, or restore these movies.

A stock install keeps the menus inside `Data\Starfield - Interface.ba2`. The desktop builder extracts `spaceshipeditormenu.swf` and `spaceshipeditormenu_lrg.swf` from that archive, splices the probe, and writes loose probe movies. Installing adds these loose files, which the game loads instead of the archive:

`<Starfield>\Data\Interface\spaceshipeditormenu.swf`

`<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf`

```
mkdir "<Starfield>\Data\Interface"
copy /Y "shipbuilder\Interface\spaceshipeditormenu.swf" "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
copy /Y "shipbuilder\Interface\spaceshipeditormenu_lrg.swf" "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
```

If `dir /b "<Starfield>\Data\Interface\spaceshipeditormenu*.swf"` already lists a file before that copy, it is a loose vanilla or another mod. Back it up in `%USERPROFILE%\Documents\My Games\Starfield\HorizonShipBuilder_vanilla_backup` and copy it back when you are done. `fc /b` against that backup confirms the restore.

On a stock install, restore by deleting the loose probe movies so the archive loads again (or move them out of `Data\Interface`):

```
del "<Starfield>\Data\Interface\spaceshipeditormenu.swf"
del "<Starfield>\Data\Interface\spaceshipeditormenu_lrg.swf"
dir /b "<Starfield>\Data\Interface\spaceshipeditormenu*.swf"
```

The check passes when that `dir` prints no file name. The full steps and the throwaway-save warning are in `shipbuilder/README_P0.md`.
