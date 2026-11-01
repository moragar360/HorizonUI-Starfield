# Horizon UI 0.43.0.8 tester note

Pre-release first pass. Not approved. Debug compile flags stay off (`HZ_HUD_MSG_CAPTURE` 0, `HZ_COMMS_MSG_LOG` 0, `HZC_MSG_LOG` false, `hzcRxDbgOn` false). Settings schema stays 0.42.0.

## What to look at

1. Message Log SETTINGS: HISTORY "500" sits between the arrows, not on top of them. Same in large text.
2. Turning a category off (MEDICAL, CREW, ...) hides that type from the list and hides its pill. It also stops recording that type. ALL still shows the types that are on.
3. Welcome splash after a save load: HORIZON UI, your HUD accent, dark outline, no panel, no pause. F11 > CONTROLS > SHOW WELCOME ON LOAD turns it off.
4. F11 COMMS: full-width SUBTITLES / DIALOGUE switch under the notice. Notices start collapsed (13 px text). A missing module expands the notice.
5. Look at an owned item (Credstik on Akila): E STEAL should be red.
6. Item and key lines (for example "Jacob's office key") should be Horizon KEY/ITEM or GAME cards, not vanilla.
7. Long notices still need a natural in-game look: card ends with "...", Message Log keeps about 256 characters.

## SFSE log

`Data\SFSE\SFSE.ini`: `[Scaleform]` `EnableLog=1` turns on the Scaleform log. Horizon's own `Debug=1` goes in `HorizonUI.user.ini` under `[Debug]`.
