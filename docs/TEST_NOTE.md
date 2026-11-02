# Horizon UI 0.43.0.15 tester note

Pre-release first pass. Not approved. Debug compile flags stay off (`HZ_HUD_MSG_CAPTURE` 0, `HZ_COMMS_MSG_LOG` 0, `HZC_MSG_LOG` false, `hzcRxDbgOn` false). Settings schema stays 0.42.0.

0.43.0.8 left the HUD vanilla and hid the game's bars (`TypeError #1009`, late instance fields null) and rebuilt the welcome splash every frame. 0.43.0.9 assigns those fields in `hzInitFields` and reuses the splash text. 0.43.0.11 keeps a vitals note and an F11 note in the same log line. 0.43.0.13 drops that F11 note when the settings page finishes drawing. 0.43.0.14 put those tables in one `hzInitStatics` and the HUD never reported a build id. 0.43.0.15 gives each table its own function. The DLL logs `HUD ctor start 0.43.0.15`, then `HUD stage begin` for one table per frame. The startup intro defaults to off (`StartupIntro=0`): the log says `splash skipped` or `splash start`. The log must say `HorizonUI 0.43.0.15 loaded`. An older `HUD 0.43.0.14` line means the new movie is not loaded.

## What to look at

1. Message Log SETTINGS: HISTORY "500" sits between the arrows, not on top of them. Same in large text.
2. Turning a category off (MEDICAL, CREW, ...) hides that type from the list and hides its pill. It also stops recording that type. ALL still shows the types that are on.
3. Startup intro is off for this test (`StartupIntro=0`). The log says `splash skipped`. F11 > CONTROLS > STARTUP INTRO turns it on for a later load; the log then says `splash start`. SHOW WELCOME ON LOAD still has to be on for the splash to play.
4. F11 COMMS: full-width SUBTITLES / DIALOGUE switch under the notice. Notices start collapsed (13 px text). A missing module expands the notice.
5. Look at an owned item (Credstik on Akila): E STEAL should be red.
6. Item and key lines (for example "Jacob's office key") should be Horizon KEY/ITEM or GAME cards, not vanilla.
7. Long notices still need a natural in-game look: card ends with "...", Message Log keeps about 256 characters.

## SFSE log

`Data\SFSE\SFSE.ini`: `[Scaleform]` `EnableLog=1` turns on the Scaleform log. Horizon's own `Debug=1` goes in `HorizonUI.user.ini` under `[Debug]`.
