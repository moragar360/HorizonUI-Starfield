# Horizon UI 0.42.0.12 tester note

Pre-release. Debug compile flags stay off (`HZ_HUD_MSG_CAPTURE` 0, `HZ_COMMS_MSG_LOG` 0, `HZC_MSG_LOG` false, `hzcRxDbgOn` false). Settings schema stays 0.42.0.

## SFSE log

`sfse.ini` uses `EnableLog=`, not `Debug=`. HorizonUI.ini still uses `Debug=` for the in-game overlay and the movie queue.

## Stealth meter

The Horizon stealth pill hides the vanilla `StealthMeter_mc` (alpha only, never removed) only while the pill is actually active: StealthMeter is on in F11, the pill clip exists, stealth data is present, and the player is sneaking with the meter shown (`bShowMeter`). If StealthMeter is off, vanilla stays visible. A character without Stealth rank 1 has `bShowMeter` false, so neither indicator shows. That matches vanilla.

## Afflictions after a save load

If the title text is present but measures under about 4 px (font not ready), the title field keeps its last good width or stays wide instead of collapsing to about 8 px. Layout runs again when the font probe first succeeds, and about 30 and 120 frames after the loading screen closes. Personal alerts (`hz27Alerts`) and seen keys (`hzAfSeen`) are cleared on load so a stale alert cannot keep the expanded chip.

## In-game checks

1. Stealth rank 1: sneak with StealthMeter on. Horizon pill shows and vanilla is hidden. StealthMeter off: vanilla meter, no pill.
2. Save with an affliction (for example Contusions). Load 5 to 10 times. The title should stay readable. The chip should not stay expanded from a previous session's alert.
