# Horizon UI 0.42.0.13 tester note

Pre-release. Debug compile flags stay off (`HZ_HUD_MSG_CAPTURE` 0, `HZ_COMMS_MSG_LOG` 0, `HZC_MSG_LOG` false, `hzcRxDbgOn` false). Settings schema stays 0.42.0.

## SFSE log

`Data\SFSE\SFSE.ini`: `[Scaleform]` `EnableLog=1` turns on the Scaleform log. Horizon's own `Debug=1` goes in `HorizonUI.user.ini` under `[Debug]`.

## Stealth meter

No change in 0.42.0.13. The Horizon stealth pill hides the vanilla `StealthMeter_mc` (alpha only, never removed) only while the pill is actually active. A character without Stealth rank 1 has `bShowMeter` false, so neither indicator shows. That matches vanilla.

## Afflictions after a save load

Personal alerts (`hz27Alerts`) and seen keys (`hzAfSeen`) are still cleared on load, so a stale alert cannot keep last session's name. After that clear, a remaining personal effect has no real name: the chip title is **INJURY** and the sub line is the body system in readable words (for example `Cardio Respiratory Circulatory`). When a PersonalAlertsData line arrives this session (for example `Contusions`), that name becomes the title. The body-system sub line may stay. Both lines are at least 13 px. The 0.42.0.12 title-fit retry is unchanged.

## In-game checks

1. Stealth rank 1: sneak with StealthMeter on. Horizon pill shows and vanilla is hidden. StealthMeter off: vanilla meter, no pill.
2. Save with an affliction (for example Contusions). Load. The chip should read INJURY over the body system, not CARDIO RESPIRATORY CIRCULATORY as the title. Get injured again this session: the real name returns.
