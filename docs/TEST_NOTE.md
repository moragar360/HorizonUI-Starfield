# Horizon UI 0.42.0.14 tester note

Pre-release. Debug compile flags stay off (`HZ_HUD_MSG_CAPTURE` 0, `HZ_COMMS_MSG_LOG` 0, `HZC_MSG_LOG` false, `hzcRxDbgOn` false). Settings schema stays 0.42.0.

## SFSE log

`Data\SFSE\SFSE.ini`: `[Scaleform]` `EnableLog=1` turns on the Scaleform log. Horizon's own `Debug=1` goes in `HorizonUI.user.ini` under `[Debug]`.

## Stealth meter

No change in 0.42.0.14. The Horizon stealth pill hides the vanilla `StealthMeter_mc` (alpha only, never removed) only while the pill is actually active. A character without Stealth rank 1 has `bShowMeter` false, so neither indicator shows. That matches vanilla.

## Affliction chip typography

The title and body-system line now use the same fonts_horizon path as the other Horizon chips: SemiBold (`$Horizon_Font`), HeaderStyle on the title (AFFLICTION / real name), muted SemiBold 1.2 tracking on the sub line. Size is the shared chip formula `max(9, round(design * TextScale))`, then the 13 px on-screen floor through `hz34S` (HZ_SCALE * HudScale or AfflictionsScale), including Moragar's Choice. Changing HUD SCALE or AfflictionsScale in F11 still reformats those lines. Env-chip bar math is unchanged. After a load, a nameless effect is still **AFFLICTION** over the body system.

## In-game checks

1. Stealth rank 1: sneak with StealthMeter on. Horizon pill shows and vanilla is hidden. StealthMeter off: vanilla meter, no pill.
2. Save with an affliction (for example Contusions). Load. The chip should read AFFLICTION over the body system, not CARDIO RESPIRATORY CIRCULATORY as the title. Get injured again this session: the real name returns.
3. Compare the affliction title and sub line to the stealth pill and jetpack status lines at your TextScale / HudScale. Weight, case, and tracking should match that family. Apply Moragar's Choice: type stays at least 13 px on screen.
