
      // ===================== Horizon UI (HUD module) =====================
      // v0.40: Scanner module support (SCANNER tab, [Scanner] keys, HideMainHudWhileScanning); quest popups hide for the
      // whole scan (Comms); the three scanner popup rows moved from the COMMS tab to the SCANNER tab.
      // Settings flags (to be driven by the upcoming settings menu).
      public var hzShowJetpack:Boolean = true;
      public var hzJetpackAutoHide:Boolean = true;
      public var hzShowVitals:Boolean = true;
      public var hzShowHealth:Boolean = true;
      public var hzShowOxygen:Boolean = true;
      public var hzHideVanillaBoost:Boolean = true;
      public var hzHideVanillaHealth:Boolean = true;

      public var HorizonCard_mc:Sprite = null;
      public var HorizonVitals_mc:Sprite = null;
      private var hzFont:String = null;
      private var hzTexts:Array = [];
      private var hzJetPct:TextField = null;
      private var hzJetBar:Sprite = null;
      private var hzJetCharge:Number = 1;
      private var hzVitHp:TextField = null;
      private var hzVitO2:TextField = null;
      private var hzVitHpLbl:TextField = null;
      private var hzVitO2Lbl:TextField = null;
      private var hzVitHpBar:Sprite = null;
      private var hzVitO2Bar:Sprite = null;
      private var hzGroupVisible:Boolean = true;
      private var hzHideCache:Array = null;
      private var hzHideTries:int = 0;
      public var hzShowCompass:Boolean = true;
      public var hzShowEnvironment:Boolean = true;
      public var hzHideVanillaCompass:Boolean = true;
      public var HorizonCompass_mc:Sprite = null;
      public var HorizonEnv_mc:Sprite = null;
      private var hzVitBg:Sprite = null;
      private var hzLowHealth:Boolean = false;
      private var hzPulseT:Number = 0;
      private var hzJetIconVec:Sprite = null;
      private var hzCmpLabels:Array = [];
      private var hzCmpCenter:TextField = null;
      private var hzEnvLoc:TextField = null;
      private var hzEnvStats:TextField = null;
      private var hzEnvHaz:TextField = null;
      private var hzEnvAff:TextField = null;
      private var hzEnvSoak:Sprite = null;
      private var hzEnvHazards:Array = [];
      private var hzEnvAffl:Array = [];
      private static const HZ_CMP_W:Number = 420;
      public var hzShowPlanet:Boolean = true;
      public var hzShowAfflictions:Boolean = true;
      public var hzAfflAutoHide:Boolean = true;
      public var hzShowAmmo:Boolean = true;
      public var hzAmmoOnlyWhenDrawn:Boolean = true;
      public var hzHideVanillaAmmo:Boolean = true;
      public var hzHideVanillaWatch:Boolean = true;
      public var HorizonAffl_mc:Sprite = null;
      public var HorizonAmmo_mc:Sprite = null;
      private var hzAfflCount:int = 0;
      private var hzAmmoDrawn:Boolean = false;
      private var hzAmmoCount:TextField = null;
      private var hzAmmoType:TextField = null;
      private var hzAmmoWeapon:TextField = null;
      private var hzBlg:DisplayObjectContainer = null;
      private var hzFrameN:int = 0;
      private static const HZ_ICON_HEX:String = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000e12122400000000010000000000000000000000000000000000000000000000020000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000001000000118796a58b3c4049d858585ae26362645c5b5b610001010105cc999904bfbf7f03aaaaaa027f7f7f010000000000000000010101027f7f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000003ffffffbf1a1c20ff30323aff555558ff494747ff4b4a4c180a0a150000000000000000000000000000000000030303193d3d4703000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000241c1c23ff060606fb0c0c0efb706f72fa6f6d6cfe2e2f35a066666a9ec9c4be9ba19f9d63a4a4a72d999ea4b1191c22f135383fc6616061296f6f7600000000027f7f7f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003555555000000005052525cff626367fa3b3b3dfd44454afdaca8a4fb2c2c30ff8d8c8fe2868687b45a5a5cd7737171f7706e6dff6e6a66fd515053ff565353c965646404ffffff027f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000027f7f7f05000033d1787a82ff828289fb504e51fd49484afd5e5b58fd605e5efba6a19ff25b6472e74d596de0384050f9373f4dfb41464dfa7b7978fd3a393bdd4e4d4d09c6c6c60100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003aaaaaa00000000885f5f63ffb3b4b6fa8d8e91fd8c8a89fd545354fd323232fd9f9ea0fdd4cdc8ffccc8c4ff838c9bff697181fd4a4e5bfd474d5ffb6d7788ff47474cd58f8c8900020202000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000103000000e65c626efe8995a7fb425062fd424c5bfd292c33fd252424fd525152fd979594fdf6f0e8fd85878bfc5e6471fd596668fd4a6065fc797e8afe8e8f92e168635f585f5c5c09ffffff01ffffff01ffffff000000000000000000000000000000000000000000000000000000000000000000000000027f7f7f000101018d3b414dfe687487fa9bacc3fd4a5b72fd434f5efd38414dfd2e2e31fd353435fd7d7977fdccc3b8fd717273fd3d3e49fd65979bfd6eb7bcfd4a4c52fdbab7b5fc5a5857ff444449946367730000000003555555000000000000000000000000000000000000000000000000000000000000000002007f7f0000000019475b70fa41454ffe797a7dfc5b5f65fd383f51fd588693fd4a6c78fd211c20fd262627fd878380fdcac2b9fd737170fd393a43fd6ea2a7fd76bcc2fd464951fda5a09cfb5a5a5afb777576f298969717c7c7c70000000001ffffff00000000000000000000000000000000000000000000000000000000043f3f3f00000000563e444aff959395faece7e1fd9e9891fd2c2a32fd609ba6fd4f707cfd090608fd494a4cfda39d97fdaba49cfd8b857efd3c3a3ffd6ea5abfd70b2b8fd494a50fda7a29cfd333233f93b3f49ff7e81886b93939300000000047f7f7f0000000000000000000000000000000000000000000000000000000004bfbfbf0000000074868891ffc6c4c5f9e8e3defd8d8782fd30333cfd62a8b2fd41545ffd0a0709fd3d414afd7c7b7dfd948e86fd8c877efd433f42fd73b0b6fd68a7aefd666161fdaca69ffd24252afa353f4bff515e6fc17a8699062a2a55027f7f7f0000000000000000000000000000000000000000000000000000000003aaaaaa00010101a4909296ffd3d0cdf9e9e4ddfd726c68fd2d343efd5c8592fd38404afd080708fd2c2f36fd40454ffd797470fd89837afd433f41fd5c898efd527b80fd776f6cfd9f9a93fd181419fd4d7c88fc608896ff838ca339435062000000000355555500000000000000000000000000000000000000000100000000000000081f3f3fe254555affc8c2bdfbb7b2acfd505053fd353941fd5f6371fd2e333bfd000102fd363940fd3e434efd4a4b4ffd898279fd3a3c3ffd3a3d44fd424348fd827d78fd838281fd110f17fd53828ef9598d9bfe6f6d766f65676900000000047f7f7f00000000000000000000000000000000000000000355555500000000343f3f49fe3f4147fc737982fd616873fd30343cfd363a42fd616772fd24262cfd4c4a48fd39393cfd2f333cfd494a4ffd888178fd3a3a3dfd252c36fd33373dfd87827bfd484b51fd0a060bfd577d89f94c8491ff9c929086cfc9c20000000004bfbfbf0000000000000000000000000000000000000000043f3f3f000000008c333438ff434955f98896acfd606671fd2f3238fd3d4149fd5d626ffd181b20fd7b7674fd7c7773fd1a1b21fd4f4f51fd847c74fd3b3a3bfd25292ffd434345fd7b7774fd1e2229fd0d0c10fd4c5d6bf93a5361ff8f8b8ca7d4cec40000000003ffffff0000000000000000000000000000000000000000027f7f7f00000000c3343840ff464c57fa4f5661fd2d3239fd25292efd3e434cfd616773fc111317fd292625fd78736efd19191cfd4c4948fd67625cfd3a3837fd333233fd5c5753fd5e5d5efd3a3b3efd16171afd4f5461fb373b48ff7d7d7fcad2c9c20000000001ffffff00000000000000000000000000000000000000000100000000000000c91f2329ff191c20fa414246fd3b4046fd171e24fd1e2022fd30343bfe12151bfc343736fd4f4b47fc131317fd585655fd54504cfd0e0f11fd151619fd595551fd474646fd888480fd1a1b1ffd525865fc3a404aff5f6674e49a989809aa8d71000000000100000000000000000000000000000000000000043f3f3f000000008633353cff4a4954f99597a1fd5c606cfd343239fd6c696ffc1b1d21f9192128ff45575ffc282a2cfd191c21fd515b6cfd484749fd484542fd4b4949fb464647fa43403efd2a2827fd181a20fd585f6cfc424751fd535966f86067762833333300000000027f7f7f00000000000000000000000000000000027f7f7f05666666b1333840ff478391fa55b5c9fd67b9c2fb438999ff627a85d03d3f483124292eec1e2126fb0e181ff92f3f50fd4b576afd262b36fc33373dfb393e46ff2b3039ff3f3f3dfd101216fd292d35fd444b58fd31373ffa272a2eff4f55615442485800000000043f3f3f00000000000000000000000002000000000000001b382525ff133340ff35a7c9fca3fafffdebfffffa85f6fffe2f95aade202a3100000000831b1b21ff262e39ff39536dfd2d343efb272b33ff252c37ff2c3947ce263138ba323a40fe151d26fc1a1d21fd333538fd28282df9353a41ff1e21255a2a2d3500000000043f3f3f00000000000000000000000000000000027f7f7f01000000691f5977f760c1e6fcd9fcfffbfbfdf9fc83e2faff1b7194a9182b33027f7f7f07242448682c3849d6202832fa1e1f23ff25262be723262d88272e380000010136212a3dff1b212afb2f2e34fd888892fc3d4955fe727480eb5c5a6218000000000101010100000000000000000000000000000000000000027fffff000000002789d1fff297e8fbfddafcfbfddcfffdeb84dff9502c75a20355aaaa01ffffff000000000000000003000000291f1f25401b1f230e243636000000000200000005330000c1333b49fe406b78fa5eb4c4fc70c9d3fc49aec1f541636e3337282d00000000027f7f7f00000000000000000000000000000000027fffff00000000507cbff2fe8ee6faf9cafbfbffb8fdffc47ad4f800010000000000000100ffff000000000355555500000000000000000000000000000000030000550100000003ffffffe217262fff2996b1faa0fcfffdf6fffff969e3ffff0f546b5d1b181b0000000004003f3f00000000000000000000000000000000027fffff000000004581c0f3f086d9fafab3fcfbfd93e5fb757ac4f602007f7f027fffff00000000000000000000000001000000020000000300000001000000000000000200007f027f7f7f7817333de7308eb3fbb3f6fffafdfffbfe91e4f88b24759d05333333027fffff000000000000000000000000000000000000000001ffffff000000001673ade7b98bd4faff9bf5ffa180caf81178a5e1000000000100ffff00000000000000000000000000000000010000000000000000000000000000000000000003aaffff000000007278cdf8ffa8f9fff7dcfffbff99ecfd417dd3ff000000000355aaff000000000000000000000000000000000000000000000000027fffff000000007c85cbf6cc85cff8197aadea000000000100ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000355aaff03005555497dc0f4fd8adefafbb8fbfafb8bdefa4f70b7ee000000000355aaff00000000000000000000000000000000000000000000000001ffffff000000002c79b3e2327ab2e5000000000100ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100ffff00000000106f9fdfb282ccf9ff9dfaffd384d7fa1e6eaaee0000000001ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000001ffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000027f7fff000000002e7fb6eef489ddfb9083d0f70000000001ffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000101ffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ffffff00000000797ec3f4457dc3f300000000027fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100ffff076d91b6076d91b600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
      private static const HZ_CARD:Array = ["N","NE","E","SE","S","SW","W","NW"];
      private static const HZ_W:Number = 260;
      private var hzEnvTemp:TextField = null;
      private var hzEnvTempC:Number = NaN;
      private var hzEnvGrav:TextField = null;
      private var hzEnvAir:TextField = null;
      private var hzDotJet:Sprite = null;
      private var hzDotVit:Sprite = null;
      private var hzDotPlan:Sprite = null;
      private var hzDotAff:Sprite = null;
      private var hzDotAmmo:Sprite = null;
      private static const HZ_HDR:Number = 28;
      public var hzShowQuests:Boolean = true;
      public var hzQuestMode:int = 0; // 0 = active + this planet, 1 = active only, 2 = this planet only
      public var hzShowCompassMarkers:Boolean = true;
      public var HorizonQuest_mc:Sprite = null;
      private var hzQActive:TextField = null;
      private var hzQActiveSub:TextField = null;
      private var hzQRows:Array = [];
      private var hzQPlanetHdr:TextField = null;
      private var hzQFooter:TextField = null;
      private var hzQHasAny:Boolean = false;
      private var hzPlanTitle:TextField = null;
      private var hzCmpMarks:Sprite = null;
      private var hzCmpDeg:Number = 0;
      private var hzCmpData:Object = null;
      private static const HZ_GREEN:uint = 0x5EE3A1;
      private static const HZ_YELLOW:uint = 0xF2D35F;
      private static const HZ_RED:uint = 0xFF5B5B;
      // Crosshair.as: HCT_PISTOL = EnumHelper.GetEnum(0), then PISTOL 0, CUTTER 1, UNARMED 2, SHOTGUN 3, RIFLE 4,
      // LASER 5, TOOL 6, INTERACT 7, COMMAND 8, NONE 9 (Crosshair gotoAndStop(uType + 1))
      private static const HZ_HCT_COMMAND:int = 8;
      private var HZ_ACCENT:uint = 0x3FD0E0;
      public var hzAccentChoice:int = 0; // 0 cyan, 1 teal, 2 amber, 3 violet, 4 lime, 5 white
      private static const HZ_ACCENTS:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      public var hzSmoothBars:Boolean = true;
      public var hzCardOpacity:Number = 1;
      public var hzContOpacity:Number = 1;   // v0.25 ContainerOpacity: crosshair target / container / item cards only
      public var hzCardColor:int = 0; // 0 slate, 1 graphite, 2 navy, 3 deep teal, 4 plum, 5 crimson
      public var hzHudScale:Number = 1;
      public var hzMagBar:Boolean = true;
      private var hzMagSp:Sprite = null;
      private var hzMagWeap:String = null;
      private var hzMagMax:Number = 0;
      private var hzMagCap:Number = 0;
      private var hzMagClip:Number = -1;
      public var hzAutoCenterVitals:Boolean = true;
      private var hzVitCX:Number = NaN;
      private var hzVitOff:Number = 0;
      private var hzInShip:Boolean = false;
      // Show-when rules: 0 always, 1 combat only, 2 hide in ship
      public var hzRuleJetpack:int = 4;
      public var hzRuleVitals:int = 0;
      public var hzRulePlanet:int = 0;
      public var hzRuleAffl:int = 6;
      public var hzRuleAmmo:int = 3;
      public var hzRuleQuests:int = 0;
      public var hzRuleCompass:int = 0;
      // Visibility rule ids (one rule per card): 0 always, 1 combat only, 2 hide in ship, 3 weapon drawn only,
      // 4 jetpack in use / not full, 5 vitals below 100%, 6 only when afflicted
      private static const HZ_RULE_NAMES:Array = ["ALWAYS","COMBAT ONLY","HIDE IN SHIP","WEAPON DRAWN ONLY","IN USE / NOT FULL","WHEN NOT FULL (HP/O2)","ONLY WHEN AFFLICTED","ON XP / LEVEL / CREDITS","WHEN OVERWEIGHT","XP / LEVEL OR OVERWEIGHT"];
      private var hzCardBodies:Array = [];
      private static const HZ_CARDCOLS:Array = [0x0B1218,0x16181C,0x0B1630,0x0A2226,0x1E1328,0x2A1014,0x3A4652,0xD5DBE0,0xF2F4F6,0xCCDFEE,0xF0E0C2,0xD2ECDF];
      private static const HZ_CARDNAMES:Array = ["SLATE","GRAPHITE","NAVY","DEEP TEAL","PLUM","CRIMSON","STORM GRAY","LIGHT GRAY","WHITE","PALE BLUE","PALE AMBER","PALE MINT"];
      public var hzAccentHex:int = -1; // AccentHex=#RRGGBB in ini adds a CUSTOM accent (last palette entry)
      public var hzCardHex:int = -1;   // CardHex=#RRGGBB in ini adds a CUSTOM card color
      private var hzTiles:Array = [];
      // v0.27: EquipmentStyle removed - the Equipment card is always the new layout (A, C in compact mode)
      private var hzEqOld:Sprite = null;
      private var hzEqNew:Sprite = null;
      private var hzEqWeap:TextField = null;
      private var hzEqCount:TextField = null;
      private var hzEqType:TextField = null;
      private var hzEqWIcon:Sprite = null;
      private var hzEqTicks:Sprite = null;
      private var hzEqKind:String = "";
      private var hzEqShown:Number = -1;
      private var hzEqFlash:Number = 0;
      private var hzEqFlashFrom:Number = 0;
      private var hzEqLastClip:Number = -1;
      private var hzCAmmoRow:Array = [];
      private var hzTypoKey:String = "";
      // v0.17
      private static const HZ_EQ_W:Number = 280;
      private static const HZ_EQ_P:Number = 12;
      private var hzEqBody:Sprite = null;
      private var hzEqBodyRec:Object = null;
      private var hzEqReserve:TextField = null;
      private var hzEqFullName:String = "";
      private var hzEqExpandUntil:int = 0;
      private var hzEqExpanded:Boolean = false;
      private var hzEqClip:Number = NaN;
      private var hzEqTot:Number = NaN;
      private var hzEqPct:Boolean = false;
      private var hzEqHasAmmo:Boolean = false;
      private var hzInvWeapName:String = "";
      // v0.18
      public var hzTextTone:int = 0; // 0 auto (from card color), 1 light text, 2 dark text
      private static const HZ_TONE_NAMES:Array = ["AUTO","LIGHT TEXT","DARK TEXT"];
      public var hzFontFace:int = 1; // 0 game font, 1 Exo 2 via $Horizon_Font, 2 Roboto via $Horizon_Font_Alt (v0.29; needs fonts_horizon.swf + fontconfig)
      // v0.29: shown in this order; the stored ini values stay 0 = game, 1 = Exo 2 (unchanged meaning), 2 = Roboto (new)
      // v0.34: 3 = the game's own semibold face (run-time name only, never bundled; falls back to the game font)
      private static const HZ_FONT_NAMES:Array = ["EXO 2","ROBOTO","GAME FONT","GAME FONT (SEMIBOLD)"];
      private static const HZ_FONT_IDS:Array = [1,2,0,3];
      private var hzFontOk:int = -1; // -1 unknown, 0 missing, 1 available
      public var hzPlanDetails:Boolean = false;
      public var hzShowTarget:Boolean = true;
      public var hzTgAnchor:int = 0; // 0 crosshair (frames the vanilla button bar), 1 follow fScreenX/Y
      public var hzTgShowValue:Boolean = true;
      public var HorizonTarget_mc:Sprite = null;
      private var hzTgBody:Sprite = null;
      private var hzTgChipBg:Sprite = null;
      private var hzTgName:TextField = null;
      private var hzTgChip:TextField = null;
      private var hzTgInfo:TextField = null;
      private var hzTgAct:Object = null;
      private var hzTgSX:Number = NaN;
      private var hzTgSY:Number = NaN;
      private var hzTgHpV:Number = -1;
      private var hzTgLeg:Boolean = false;
      private var hzTgDirty:Boolean = true;
      private var hzTgLastMode:int = -2;
      private var hzTgHidden:Array = [];
      private var hzTgTextH:Number = 40;
      private var hzTgW:Number = 0;
      private var hzTgH:Number = 0;
      private var hzTgFramed:Boolean = false;
      private static const HZ_TG_W:Number = 260;
      private static const HZ_TGANCHOR_NAMES:Array = ["CROSSHAIR","FOLLOW TARGET"];
      private var hzIcons:Array = [];
      private var hzEqLow:Boolean = false;
      private var hzEqPulse:Number = 0;
      private var hzEqAmmoIcon:Sprite = null;
      private var hzPlanOld:Sprite = null;
      private var hzPlanPill:Sprite = null;
      private var hzPpBody:Sprite = null;
      private var hzPpIcon:Sprite = null;
      private var hzPpName:TextField = null;
      private var hzPpTemp:TextField = null;
      private var hzPpHaz:TextField = null;
      private var hzPpDet:TextField = null;
      private var hzPpH:Number = 84;
      private var hzPpKind:String = "planet";
      private var hzPpBodyName:String = "--";
      private var hzPpSys:String = "";
      private var hzPpStatus:String = "SAFE"; // SAFE / THERMAL / RADIATION / CORROSIVE / AIRBORNE / HAZARD / DANGER
      private var hzPpStatusCol:int = 0;      // 0 accent, 1 amber, 2 red
      private var hzDbgEnv:String = "";
      private var hzDbgSubbed:Boolean = false;
      private static const HZ_PP_W:Number = 392;   // v0.31: was 336 (+16.7 %, longer planet / moon / station names)
      private var hzVitOld:Sprite = null;
      private var hzVitNew:Sprite = null;
      private var hzVnBodies:Array = [];
      private var hzVnHp:TextField = null;
      private var hzVnO2:TextField = null;
      private var hzVnHpBar:Sprite = null;
      private var hzVnO2Bar:Sprite = null;
      private static const HZ_O2_BLUE:uint = 0x4DB6FF;
      private var hzVitHpF:Number = 1;
      private var hzVitO2F:Number = 1;
      private var hzRulesV2:Boolean = false;
      // compass marker filters
      public var hzCmpFollowers:Boolean = true;
      public var hzCmpLocations:Boolean = true;
      public var hzCmpShip:Boolean = true;
      public var hzCmpEnemies:Boolean = true;
      public var hzCmpPlayerMark:Boolean = true;
      private var hzDbgCmp:String = "";
      // layout edit (ARRANGE CARDS)
      private static const HZ_LAY_KEYS:Array = ["Jetpack","Vitals","Planet","Afflictions","Ammo","Quests","Compass","Compact","Character","Enemy","Stealth","XpToast","Subtitle","Speaker","Dialogue","MissionToast","HudMessages"];
      private static const HZ_LAY_NAMES:Array = ["JETPACK","VITALS","PLANET","AFFLICTIONS","EQUIPMENT","QUEST TRACKER","COMPASS","COMPACT STRIPS","CHARACTER","ENEMY HEALTH","STEALTH METER","XP TOAST","SUBTITLES","SPEAKER CARD","DIALOGUE","MISSION TOAST","HUD MESSAGES"];
      public var hzLay:Object = {};
      private var hzLayOrig:Object = null;
      private var hzArrange:Boolean = false;
      private var hzArr_mc:Sprite = null;
      private var hzArrCursor:Sprite = null;
      private var hzArrDrag:String = null;
      private var hzArrSel:String = null;
      private var hzArrDX:Number = 0;
      private var hzArrDY:Number = 0;
      private var hzArrHits:Array = [];
      private var hzArrPrev:Boolean = false;
      private var hzArrHover:String = "";
      // v0.33: the ARRANGE toolbar can be dragged (empty area / grip); offset from its default spot, kept in [Layout]
      private var hzArrTbDX:Number = 0;
      private var hzArrTbDY:Number = 0;
      private var hzArrTbDrag:Boolean = false;
      private var hzArrTbGX:Number = 0;
      private var hzArrTbGY:Number = 0;
      public var HorizonCompactQuest_mc:Sprite = null;
      private var hzCQText:TextField = null;
      private var hzCQDist:TextField = null;
      public var hzMargin:Number = 40;
      private var hzLaidOut:Boolean = false;
      private var hzCrossOn:Boolean = true;
      private var hzCrossIron:Boolean = false;   // HudCrosshairData.bIronSights
      private var hzCross3rd:Boolean = false;    // HudCrosshairData.bIn3rdPerson
      private var hzCrossTool:Boolean = false;   // HudCrosshairData.bIsToolGrip
      private var hzXhStyle:int = 1;             // CrosshairStyle: 0 vanilla, 1 Horizon dot, 2 Horizon cross, 3 none (interact reticle only)
      private var hzObjRing:int = 0;             // ObjectRing: 0 off, 1 container lists only, 2 vanilla
      private var hzXh:Sprite = null;
      private var hzXhSig:String = "";
      private var hzXhHid:Array = [];
      private var hzIniLoader:URLLoader = null;
      public var hzFadeCards:Boolean = true;
      public var hzCombatDim:Boolean = true;
      public var hzDimAlpha:Number = 0.6;
      public var hzCompact:Boolean = false;
      public var hzHazardAlert:Boolean = true;
      private var hzBars:Array = [];
      private var hzFades:Array = [];
      private var hzInCombat:Boolean = false;
      private var hzPlanAlert:Sprite = null;
      private var hzPlanAlertOn:Boolean = false;
      private var hzPlanPulse:Number = 0;
      public var HorizonCompact_mc:Sprite = null;
      private var hzCHp:TextField = null;
      private var hzCO2:TextField = null;
      private var hzCJet:TextField = null;
      private var hzCAmmo:TextField = null;
      private var hzCHpBar:Sprite = null;
      private var hzCO2Bar:Sprite = null;
      private var hzCJetBar:Sprite = null;
      private static const HZ_LABEL:uint = 0xB4CAD4;
      private static const HZ_VALUE:uint = 0xF2FBFD;
      private static const HZ_SCALE:Number = __HZ_SCALE__;
      // ---- v0.14 typography: type scale roles (base px, before TextScale) ----
      // hdr = card header caps (accent, dimmed, letter-spaced), val = primary value (largest, white),
      // valS = primary value in tiles/strips, lbl = labels/units (small, ~60% alpha), sec = secondary info (medium, muted)
      private static const HZ_TY_SIZE:Object = {"hdr":10,"val":16,"valS":14,"lbl":9,"sec":12,"big":24};
      private static const HZ_TY_ALPHA:Object = {"hdr":0.85,"val":1,"valS":1,"lbl":0.6,"sec":0.78,"big":1};
      private static const HZ_TY_WHITE:uint = 0xFFFFFF;
      private static const HZ_TY_MUTED:uint = 0xE2EDF2;
      private static const HZ_HDRSTYLE_NAMES:Array = ["CAPS + SPACED","TITLE CASE"];
      public var hzTextScale:Number = 1;
      public var hzHeaderStyle:int = 0; // 0 caps + letter-spaced, 1 normal (title case)
      public var hzTextShadow:Boolean = false; // v0.24: default off (crisp hard 1px drop when on)

      // Modern card: soft shadow, glass body, darker header strip, cyan divider, top highlight, status dot.
      private function hzCard(p:Sprite, w:Number, h:Number, icon:String, title:String) : Sprite
      {
         var body:Sprite = new Sprite();
         body.name = "hzBody";
         p.addChild(body);
         this.hzCardBodies.push({"s":body,"w":w,"h":h,"k":"card"});
         this.hzDrawBody(body,w,h);
         if(icon != null) { this.hzIcon(p,icon,11,8,HZ_ACCENT); }
         if(title != null) { this.hzText(p,title,icon != null ? 29 : 12,7,150,12,HZ_LABEL,false,"hdr"); }
         var dot:Sprite = new Sprite();
         dot.x = w - 12; dot.y = HZ_HDR / 2;
         p.addChild(dot);
         this.hzDot(dot,HZ_GREEN);
         return dot;
      }

      // Card body (shadow, tinted glass, header cap, accent divider). Redrawn live for CardColor / AccentColor.
      private function hzDrawBody(s:Sprite, w:Number, h:Number) : void
      {
         var g:* = s.graphics;
         g.clear();
         // borderless: one clean translucent panel, no outline / header cap / divider (the only frame since v0.24)
         g.beginFill(0x000000,0.1 + 0.2 * this.hzOpExtra());
         g.drawRoundRect(-1,1,w + 2,h + 2,20,20);
         g.endFill();
         g.beginFill(this.hzPanelFill(),this.hzPanelA(this.hzLight() ? 0.9 : 0.8));
         g.drawRoundRect(0,0,w,h,18,18);
         g.endFill();
         g.lineStyle(1,0xFFFFFF,this.hzLight() ? 0.25 : 0.06);
         g.moveTo(12,1); g.lineTo(w - 12,1);
         g.lineStyle();
      }

      private function hzDrawCmpBody(s:Sprite) : void
      {
         var g:* = s.graphics;
         g.clear();
         g.lineStyle();
         g.beginFill(this.hzPanelFill(),this.hzPanelA(0.74));
         g.drawRoundRect(0,0,HZ_CMP_W,36,16,16);
         g.endFill();
         g.lineStyle(1,0xFFFFFF,0.08);
         g.moveTo(10,1.5); g.lineTo(HZ_CMP_W - 10,1.5);
         g.lineStyle(1.5,HZ_ACCENT,0.9);
         g.moveTo(HZ_CMP_W / 2 - 22,35); g.lineTo(HZ_CMP_W / 2 + 22,35);
         g.lineStyle();
      }

      private function hzCardPal() : Array
      {
         var a:Array = HZ_CARDCOLS.concat();
         if(this.hzCardHex >= 0) { a.push(uint(this.hzCardHex)); }
         return a;
      }

      private function hzCardNames() : Array
      {
         var a:Array = HZ_CARDNAMES.concat();
         if(this.hzCardHex >= 0) { a.push("CUSTOM"); }
         return a;
      }

      private function hzAccPal() : Array
      {
         var a:Array = HZ_ACCENTS.concat();
         if(this.hzAccentHex >= 0) { a.push(uint(this.hzAccentHex)); }
         return a;
      }

      private function hzAccNames() : Array
      {
         var a:Array = HZ_SET_ACCNAMES.concat();
         if(this.hzAccentHex >= 0) { a.push("CUSTOM"); }
         return a;
      }

      private function hzAccentOf(i:int) : uint
      {
         var a:Array = this.hzAccPal();
         return uint(a[Math.max(0,Math.min(a.length - 1,i))]);
      }

      private function hzCardFill() : uint
      {
         var a:Array = this.hzCardPal();
         return uint(a[Math.max(0,Math.min(a.length - 1,this.hzCardColor))]);
      }

      // Relative luminance 0..1 (sRGB approx).
      private function hzLum(c:uint) : Number
      {
         return (0.2126 * ((c >> 16) & 0xFF) + 0.7152 * ((c >> 8) & 0xFF) + 0.0722 * (c & 0xFF)) / 255;
      }

      private function hzLight() : Boolean
      {
         return this.hzLum(this.hzCardFill()) > 0.55;
      }

      // Text tone actually used: TextTone override, else from the card color.
      private function hzDarkText() : Boolean
      {
         if(this.hzTextTone == 1) { return false; }
         if(this.hzTextTone == 2) { return true; }
         return this.hzLight();
      }

      // Opacity > 1: alpha clamps at 1, the rest pushes the panel color further (darker / brighter) + stronger shadow.
      private function hzOpExtra() : Number
      {
         return Math.max(0,Math.min(1,(this.hzCardOpacity - 1) / 0.6));
      }

      private function hzPanelA(base:Number) : Number
      {
         return Math.max(0,Math.min(1,base * Math.min(1,this.hzCardOpacity) + (1 - base) * this.hzOpExtra()));
      }

      private function hzPanelFill() : uint
      {
         var x:Number = this.hzOpExtra();
         var f:uint = this.hzCardFill();
         if(x <= 0) { return f; }
         return this.hzMix(f,this.hzLight() ? 0xFFFFFF : 0x000000,x * 0.6);
      }

      // Icon color with contrast on light cards (light accents are darkened).
      private function hzIconCol(c:uint) : uint
      {
         if(this.hzDarkText() && this.hzLum(c) > 0.4) { return this.hzMix(c,0x000000,0.58); }
         return c;
      }

      // Current text colors
      private function hzTxtMain() : uint { return this.hzDarkText() ? 0x0E151B : HZ_TY_WHITE; }

      private function hzMix(a:uint, b:uint, t:Number) : uint
      {
         var r:int = int(((a >> 16) & 0xFF) * (1 - t) + ((b >> 16) & 0xFF) * t);
         var g2:int = int(((a >> 8) & 0xFF) * (1 - t) + ((b >> 8) & 0xFF) * t);
         var bl:int = int((a & 0xFF) * (1 - t) + (b & 0xFF) * t);
         return uint((r << 16) | (g2 << 8) | bl);
      }

      // Accent used for text on the current card color: darkened on light cards when the accent itself is light.
      private function hzTextAccent() : uint
      {
         if(this.hzDarkText() && this.hzLum(HZ_ACCENT) > 0.45) { return this.hzMix(HZ_ACCENT,0x000000,0.55); }
         return HZ_ACCENT;
      }

      private function hzParseHex(v:String) : int
      {
         if(v == null) { return -1; }
         v = v.replace(/^\s+|\s+$/g,"").replace("#","").replace("0x","").replace("0X","");
         if(v.length != 6) { return -1; }
         var n:Number = parseInt(v,16);
         return isNaN(n) ? -1 : int(n);
      }

      private function hzHex(c:int) : String
      {
         var h:String = uint(c).toString(16).toUpperCase();
         while(h.length < 6) { h = "0" + h; }
         return "#" + h;
      }

      private function hzRedrawBodies() : void
      {
         for each(var o:Object in this.hzCardBodies)
         {
            try
            {
               if(o.k == "cmp") { this.hzDrawCmpBody(Sprite(o.s)); }
               else { this.hzDrawBody(Sprite(o.s),o.w,o.h); }
            }
            catch(err:Error) { }
         }
         for each(var tl:Object in this.hzTiles) { try { this.hzDrawTile(Sprite(tl.s),tl.w,tl.h,tl.inner == true); } catch(err2:Error) { } }
         try { this.hzEqDrawBody(); } catch(err3:Error) { }
         for each(var ic:Object in this.hzIcons) { try { if(ic.acc) { ic.c = HZ_ACCENT; } this.hzIconDraw(Sprite(ic.s),String(ic.k),uint(ic.c)); } catch(err4:Error) { } }
         try { this.hzFrameApply(); } catch(err5:Error) { }
         this.hzApplyTypo();
         this.hzEqDrawTicks();
      }

      // HudScale: multiply HZ_SCALE on every Horizon card, then re-anchor.
      private function hzApplyScale() : void
      {
         // v0.34: each card has its own factor ([Cards] <Card>Scale, -1 = HudScale)
         var m:Array = [[this.HorizonCard_mc,"Jetpack"],[this.HorizonVitals_mc,"Vitals"],[this.HorizonEnv_mc,"Planet"],[this.HorizonAffl_mc,"Afflictions"],[this.HorizonAmmo_mc,"Equipment"],[this.HorizonQuest_mc,"Quests"],[this.HorizonCompass_mc,"Compass"],[this.HorizonCompact_mc,"Compact"],[this.HorizonCompactQuest_mc,"Quests"],[this.HorizonChar_mc,"Character"],[this.HorizonEnemy_mc,"Enemy"],[this.HorizonStealth_mc,"Stealth"],[this.HorizonXp_mc,"XpToast"]];
         for each(var e:Array in m)
         {
            var c:Sprite = e[0] as Sprite;
            if(c) { c.scaleX = c.scaleY = this.hz34S(String(e[1])); }
         }
         this.hzT19Sig = "";   // hover / container cards on GLOBAL follow HudScale
         try { this.hzAfFmt13(); } catch(errAfF:Error) { }
         try { this.hzJ19Draw(); } catch(errJ13:Error) { }
         try { this.hz26StDraw(this.hz26Now()); } catch(errSt13:Error) { }
         try { this.hzAfRetryLayout(); } catch(errAfS:Error) { }
         this.hzLaidOut = this.hzLayout();
      }

      // Affliction + chip-family 13 px floor. Re-run after HudScale / per-card scale so F11
      // live changes (including Moragar's Choice) do not keep the previous font size.
      // hzTxtTint skips when the tint is unchanged, and hzAfRetryLayout does not touch the F11 preview chips.
      private function hzAfFmt13() : void
      {
         for each(var o:Object in this.hzTexts)
         {
            if(o != null && (o.af13 || o.vit13 || o.chipMin)) { try { this.hzApplyFmt(o); } catch(errAf13:Error) { } }
         }
      }

      // Shared v0.19 size: max(9, round(design * TextScale)). hzBuildVitNew HEALTH / OXYGEN
      // (fs 13) and hzVnHp / hzVnO2 (fs 20) use this before the card sprite scale
      // (hz34S = HZ_SCALE * HudScale or the card's own scale).
      private function hzChipSz(fs:Number) : int
      {
         var ts:Number = Math.max(0.8,Math.min(1.3,this.hzTextScale));
         return int(Math.max(9,Math.round(Number(fs) * ts)));
      }

      // Affliction type: identical Vitals size path. HEALTH / OXYGEN and hz26Co2T use
      // hzChipSz only (max(9, round(design * TextScale))), then the card sprite scale
      // (hz34S). No 13 px floor: the chip matches Vitals below 13 px.
      // Title: hzBuildVitNew HEALTH / OXYGEN, hzT(...,13,"sb","acc",2) + hzHdr19.
      // Sub: hz26Co2T, hzT(...,13,"sb","col",0.6). TAKE / stealth / jetpack still use hzChipSzOn.
      private function hzVitTextSz(fs:Number) : int
      {
         return this.hzChipSz(fs);
      }

      // Same formula, then the 13 px on-screen floor using the card's real scale path (hz34S),
      // not hz34F alone. TAKE uses HoverScale (hz34Eff), falling back to HudScale. Moragar's
      // Choice (HudScale 0.8) still stays at least 13 px on screen.
      private function hzChipSzOn(fs:Number, card:String, minPx:Number) : int
      {
         var sz:int = this.hzChipSz(fs);
         if(minPx > 0)
         {
            var sc:Number = this.hz34S(card);
            if(card == "Hover")
            {
               var hv:Number = this.hz34Eff(this.hz30Hover);
               if(this.hz30TgSc > 0.01) { hv = this.hz30TgSc; }
               sc = HZ_SCALE * hv;
            }
            if(!(sc > 0.01)) { sc = 1; }
            var fl:int = int(Math.ceil(minPx / sc));
            if(sz < fl) { sz = fl; }
         }
         return sz;
      }

      private function hzAf13Sz() : int
      {
         return this.hzVitTextSz(13);
      }

      // Size for a v0.19 field: vitals-copied affliction lines, then chip-family, then plain hzChipSz.
      private function hzTextSz19(o:Object, fs:Number) : int
      {
         if(o != null && o.vit13) { return this.hzVitTextSz(fs); }
         var card:String = o != null && o.chipCard != null && String(o.chipCard).length > 0 ? String(o.chipCard) : (o != null && o.af13 ? "Afflictions" : "");
         if(card.length > 0) { return this.hzChipSzOn(fs,card,o.chipMin > 0 ? Number(o.chipMin) : 13); }
         return this.hzChipSz(fs);
      }

      // Mark a chip-family line so hzApplyFmt19 uses hzChipSzOn + the 13 px floor on that card's scale.
      private function hzChip13(tf:TextField, card:String) : void
      {
         var o:Object = this.hzTxtObj(tf);
         if(!o) { return; }
         o.chipCard = card;
         o.chipMin = 13;
         try { this.hzApplyFmt(o); } catch(errChip13:Error) { }
      }

      // Mark an affliction line so it uses hzVitTextSz (HEALTH / OXYGEN / hz26Co2T, hzChipSz only).
      private function hzVit13(tf:TextField) : void
      {
         var o:Object = this.hzTxtObj(tf);
         if(!o) { return; }
         o.vit13 = true;
         o.af13 = true;
         try { this.hzApplyFmt(o); } catch(errVit13:Error) { }
      }

      private function hzDot(d:Sprite, col:uint) : void
      {
         if(!d) { return; }
         d.graphics.clear();
         d.graphics.beginFill(col,0.25);
         d.graphics.drawCircle(0,0,5);
         d.graphics.beginFill(col,1);
         d.graphics.drawCircle(0,0,2.5);
         d.graphics.endFill();
      }

      // Mini card (tile) inside a card: slightly lighter offset color.
      private function hzTile(p:Sprite, x:Number, y:Number, w:Number, h:Number) : void
      {
         var t:Sprite = new Sprite();
         t.x = x; t.y = y;
         p.addChild(t);
         var inner:Boolean = p.getChildByName("hzBody") != null;
         this.hzTiles.push({"s":t,"w":w,"h":h,"inner":inner});
         this.hzDrawTile(t,w,h,inner);
      }

      private function hzDrawTile(t:Sprite, w:Number, h:Number, inner:Boolean = false) : void
      {
         var lt:Boolean = this.hzLight();
         var g:* = t.graphics;
         g.clear();
         if(inner) { return; } // borderless: no boxes inside the panel
         g.beginFill(this.hzPanelFill(),this.hzPanelA(lt ? 0.9 : 0.78));
         g.drawRoundRect(0,0,w,h,12,12);
         g.endFill();
      }

      private function hzCardBg(p:Sprite, w:Number, h:Number) : void
      {
         p.graphics.lineStyle(1,HZ_ACCENT,0.55);
         p.graphics.beginFill(0x0B1620,0.62);
         p.graphics.drawRoundRect(0,0,w,h,18,18);
         p.graphics.endFill();
      }

      // Small original line icons for labels (12x12 box at x,y).
      private function hzIcon(p:Sprite, kind:String, x:Number, y:Number, col:uint) : void
      {
         var s:Sprite = new Sprite();
         s.x = x; s.y = y;
         p.addChild(s);
         this.hzIcons.push({"s":s,"k":kind,"c":col});
         this.hzIconDraw(s,kind,col);
      }

      private function hzIconDraw(s:Sprite, kind:String, col:uint) : void
      {
         var g:* = s.graphics;
         g.clear();
         col = this.hzIconCol(col);
         g.lineStyle(1.3,col,1);
         if(kind == "vnheart")
         {
            g.lineStyle();
            g.beginFill(col,1);
            g.moveTo(10,19); g.curveTo(0,11,1.5,6); g.curveTo(4,0,10,5); g.curveTo(16,0,18.5,6); g.curveTo(20,11,10,19);
            g.endFill();
            return;
         }
         if(kind == "vno2")
         {
            g.lineStyle(2,col,1,true);
            g.drawEllipse(0,0,13,16);
            g.lineStyle(1.5,col,1,true);
            g.moveTo(14,13); g.curveTo(19,10,19,14); g.lineTo(14,19); g.lineTo(20,19);
            return;
         }
         if(kind == "heart")
         {
            g.beginFill(col,0.9);
            g.moveTo(6,11); g.curveTo(0,6,1,3.5); g.curveTo(3,0,6,3); g.curveTo(9,0,11,3.5); g.curveTo(12,6,6,11);
            g.endFill();
         }
         else if(kind == "o2")
         {
            g.drawCircle(5,7,4.5); g.drawCircle(10,2.5,2);
         }
         else if(kind == "vitals")
         {
            g.moveTo(0,6); g.lineTo(3,6); g.lineTo(5,1); g.lineTo(7,11); g.lineTo(9,6); g.lineTo(12,6);
         }
         else if(kind == "planet")
         {
            g.drawCircle(6,6,4); g.drawEllipse(-1,4,14,4);
         }
         else if(kind == "hazard")
         {
            g.moveTo(6,0); g.lineTo(12,11); g.lineTo(0,11); g.lineTo(6,0);
            g.moveTo(6,4); g.lineTo(6,7.5); g.moveTo(6,9); g.lineTo(6,9.8);
         }
         else if(kind == "medic")
         {
            g.beginFill(col,0.9);
            g.drawRect(4,0,4,12); g.drawRect(0,4,12,4);
            g.endFill();
         }
         else if(kind == "ammo")
         {
            g.drawRect(1,5,3,7); g.moveTo(1,5); g.curveTo(2.5,0,4,5);
            g.drawRect(7,5,3,7); g.moveTo(7,5); g.curveTo(8.5,0,10,5);
         }
         else if(kind == "flag")
         {
            g.moveTo(1,12); g.lineTo(1,0); g.lineTo(11,0); g.lineTo(8,3.5); g.lineTo(11,7); g.lineTo(1,7);
         }
         else if(kind == "gun")
         {
            g.moveTo(0,3); g.lineTo(12,3); g.lineTo(12,6); g.lineTo(5,6); g.lineTo(4,11); g.lineTo(1,11); g.lineTo(2,6); g.lineTo(0,6); g.lineTo(0,3);
         }
      }

      // Boostpack art baked in as 32x32 ARGB pixels (from HorizonUI_boostpack_3D_concept.png).
      // Draws the baked 32x32 art as filled vector squares (works without BitmapData support).
      private function hzBoostVector(size:Number) : Sprite
      {
         var s:Sprite = new Sprite();
         var px:Number = size / 32;
         var i:int = 0;
         while(i < 1024)
         {
            var argb:uint = uint(parseInt(HZ_ICON_HEX.substr(i * 8,8),16));
            var a:Number = (argb >>> 24) / 255;
            if(a > 0.04)
            {
               s.graphics.beginFill(argb & 0xFFFFFF,a);
               s.graphics.drawRect((i % 32) * px,int(i / 32) * px,px + 0.15,px + 0.15);
               s.graphics.endFill();
            }
            i++;
         }
         return s;
      }

      private function hzBoostBitmap() : Bitmap
      {
         var bd:BitmapData = new BitmapData(32,32,true,0);
         var i:int = 0;
         while(i < 1024)
         {
            bd.setPixel32(i % 32,int(i / 32),uint(parseInt(HZ_ICON_HEX.substr(i * 8,8),16)));
            i++;
         }
         var bm:Bitmap = new Bitmap(bd);
         bm.smoothing = true;
         return bm;
      }

      private function hzDrawVitBg(alert:Number) : void
      {
         var g:Sprite = this.hzVitBg;
         g.graphics.clear();
         if(alert > 0)
         {
            g.graphics.lineStyle(1.5 + alert,HZ_RED,0.35 + 0.6 * alert);
            g.graphics.beginFill(HZ_RED,0.004); g.graphics.drawRoundRect(0,0,HZ_W,128,18,18); g.graphics.endFill();   // v0.40.3: the fill closes the path
         }
      }

      private function hzText(p:Sprite, txt:String, x:Number, y:Number, w:Number, size:int, col:uint, right:Boolean, role:String = null, keepCol:Boolean = false) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.width = w; t.height = size + 10; t.x = x; t.y = y;
         p.addChild(t);
         var o:Object = {"tf":t,"size":size,"col":col,"right":right,"role":role,"keep":keepCol,"y0":y,"raw":null};
         if(role == "hdr") { o.raw = txt; }
         this.hzTexts.push(o);
         t.text = role == "hdr" ? this.hzHdrCase(txt) : txt;
         this.hzApplyFmt(o);
         return t;
      }

      // Header text casing for HeaderStyle (0 CAPS, 1 Title Case).
      private function hzHdrCase(s:String) : String
      {
         if(s == null) { return ""; }
         if(this.hzHeaderStyle == 0) { return s.toUpperCase(); }
         var w:Array = s.toLowerCase().split(" ");
         var i:int = 0;
         while(i < w.length)
         {
            var ws:String = String(w[i]);
            if(ws.length > 0)
            {
               var c0:int = (ws.charAt(0) == "(" && ws.length > 1) ? 1 : 0;
               w[i] = ws.substr(0,c0) + ws.charAt(c0).toUpperCase() + ws.substr(c0 + 1);
            }
            i++;
         }
         return w.join(" ");
      }

      // Set the text of a registered header field (keeps HeaderStyle casing live).
      private function hzSetHdr(tf:TextField, s:String) : void
      {
         if(!tf) { return; }
         for each(var o:Object in this.hzTexts)
         {
            if(o.tf == tf) { o.raw = s; break; }
         }
         tf.text = this.hzHdrCase(s);
      }

      private function hzTyFilters() : Array
      {
         return this.hz35Shadow(this.hzDarkText());   // v0.35: visible shadow (see hz35Shadow)
      }

      private function hzApplyFmt(o:Object) : void
      {
         if(o.tone != undefined && o.tone !== null) { this.hzApplyFmt19(o); return; }
         var role:String = o.role;
         var ts:Number = Math.max(0.8,Math.min(1.3,this.hzTextScale));
         var base:Number = (role != null && HZ_TY_SIZE[role] != undefined) ? Number(HZ_TY_SIZE[role]) : Number(o.size);
         var sz:int = int(Math.round(base * ts));
         var col:uint = uint(o.col);
         var al:Number = 1;
         if(role != null)
         {
            var lt:Boolean = this.hzDarkText();
            if(!o.keep)
            {
               if(role == "hdr") { col = this.hzTextAccent(); }
               else if(role == "val" || role == "valS" || role == "big") { col = lt ? 0x0E151B : HZ_TY_WHITE; }
               else { col = lt ? 0x1C262E : HZ_TY_MUTED; }
            }
            else if(col == HZ_ACCENT) { col = this.hzTextAccent(); }
            // Mute by color, not alpha: alpha-muted text inherits the card fade and loses contrast (worst on light cards).
            var ra:Number = Number(HZ_TY_ALPHA[role]);
            if(ra < 1) { col = this.hzMix(col,this.hzPanelFill(),(1 - ra) * (lt ? 0.75 : 1)); }
            al = 1;
         }
         if(o.tint != undefined && o.tint !== null) { col = uint(o.tint); }
         var f:TextFormat = new TextFormat(this.hzFontName(),sz,col);
         if(o.right) { f.align = "right"; }
         if(o.center) { f.align = "center"; }
         f.letterSpacing = (o.ls != undefined && o.ls !== null) ? Number(o.ls) : ((role == "hdr" && this.hzHeaderStyle == 0) ? 1.6 : (role == "lbl" ? 0.6 : 0));
         var tf:TextField = TextField(o.tf);
         var keepTxt:String = (role == "hdr" && o.raw != null) ? this.hzHdrCase(String(o.raw)) : tf.text;
         // Scaleform keeps the color of existing glyph runs; clear, set format, re-set text, then color.
         tf.filters = [];
         tf.text = "";
         tf.defaultTextFormat = f;
         tf.text = keepTxt;
         tf.setTextFormat(f);
         tf.textColor = col;
         o.cc = col;
         tf.alpha = al;
         var nl:int = (o.lines != undefined && int(o.lines) > 1) ? int(o.lines) : 1;
         tf.height = (sz + 4) * nl + 6;
         // grow/shrink around the original vertical center so rows stay aligned
         if(o.y0 != undefined && o.y0 != null) { tf.y = Number(o.y0) - (sz - base) / 2; }
         tf.filters = this.hzTyFilters();
         o.sh = this.hzTextShadow;   // v0.36: applied shadow state (hzTypoGuard)
      }

      // Every ~0.5 s: re-apply format to any field whose color no longer matches (Scaleform can drop it on .text writes).
      private function hzTypoGuard() : void
      {
         for each(var o:Object in this.hzTexts)
         {
            try
            {
               if(o.cc == undefined || TextField(o.tf).textColor != uint(o.cc)) { this.hzApplyFmt(o); }
               else if(o.sh !== this.hzTextShadow) { this.hzApplyFmt(o); }   // v0.36: shadow setting changed since this field was formatted
            }
            catch(err:Error) { }
         }
      }

      // FontFace 1: Exo 2 faces from fonts_horizon.swf ($Horizon_Font = SemiBold, _Regular, _Bold); each face falls
      // back to SemiBold, then to the game font, so a missing / partial install never shows empty text.
      // v0.29 FontFace 2: Roboto ($Horizon_Font_Alt = Medium, _Alt_Regular, _Alt_Bold); falls back to Medium, then to
      // the matching Exo 2 face (older fonts_horizon.swf / fontconfig without Roboto), then to the game font.
      private function hzFontName(face:String = null) : String
      {
         var game:String = this.hzFont ? this.hzFont : "$MAIN_Font";
         if(this.hzFontFace == 3) { return this.hzFontProbe(HZ34_SEMI) ? HZ34_SEMI : game; }   // v0.34: one weight for every face
         if(this.hzFontFace != 1 && this.hzFontFace != 2) { return game; }
         // font.marker still loading or absent: game font, and no $Horizon_ lookup yet (that logs a missing face)
         if(this.hz30Mod["font"] !== 1) { return game; }
         var want:String;
         if(this.hzFontFace == 2 && this.hzFontProbe("$Horizon_Font_Alt"))
         {
            want = face == "rg" ? "$Horizon_Font_Alt_Regular" : (face == "bd" ? "$Horizon_Font_Alt_Bold" : "$Horizon_Font_Alt");
            if(want == "$Horizon_Font_Alt" || this.hzFontProbe(want)) { this.hzFontOk = 1; return want; }
            this.hzFontOk = 1;
            return "$Horizon_Font_Alt";
         }
         // Bold and Regular wait until the base face really renders, so they are not looked up before the library is ready
         if(!this.hzFontProbe("$Horizon_Font")) { return game; }
         want = face == "rg" ? "$Horizon_Font_Regular" : (face == "bd" ? "$Horizon_Font_Bold" : "$Horizon_Font");
         if(want == "$Horizon_Font" || this.hzFontProbe(want)) { this.hzFontOk = 1; return want; }
         this.hzFontOk = 1;
         return "$Horizon_Font";
      }

      // Live typography update (TextScale / HeaderStyle / TextShadow / card color).
      private function hzApplyTypo() : void
      {
         for each(var o:Object in this.hzTexts)
         {
            try { this.hzApplyFmt(o); } catch(err:Error) { }
         }
         try { this.hzEqLayout(); } catch(err2:Error) { }
         try { this.hzPpLayout(); this.hzV19Redraw(); } catch(err3:Error) { }
         try { this.hz26StDraw(this.hz26Now()); } catch(errStT:Error) { }
         try { if(this.hzAfNew && this.hz31AfLast != null) { this.hzAfLayoutChips(this.hz31AfLast); } } catch(err31:Error) { }
         if(this.hzSetIsOpen) { this.hzSetDraw(); }
      }

      private function hzFindFont(c:DisplayObjectContainer, depth:int) : String
      {
         var i:int = 0;
         var r:String = null;
         var ch:* = null;
         if(depth > 12) { return null; }
         while(i < c.numChildren)
         {
            ch = c.getChildAt(i);
            if(ch is TextField && TextField(ch).embedFonts && ch.parent != this.HorizonCard_mc && ch.parent != this.HorizonVitals_mc && ch.parent != this.HorizonEnv_mc && ch.parent != this.HorizonCompass_mc)
            {
               r = TextField(ch).getTextFormat().font;
               if(r && r.indexOf("$Horizon") != 0) { return r; }
            }
            else if(ch is DisplayObjectContainer && ch != this.HorizonCard_mc && ch != this.HorizonVitals_mc && ch != this.HorizonEnv_mc && ch != this.HorizonCompass_mc && ch != this.HorizonAffl_mc && ch != this.HorizonAmmo_mc && ch != this.HorizonQuest_mc && ch != this.HorizonCompact_mc && ch != this.HorizonSettings_mc && ch != this.HorizonTarget_mc && ch != this.HorizonCompactQuest_mc)
            {
               r = this.hzFindFont(DisplayObjectContainer(ch),depth + 1);
               if(r) { return r; }
            }
            i++;
         }
         return null;
      }

      private function hzFixFonts() : void
      {
         if(this.hzFont) { return; }
         this.hzFont = this.hzFindFont(this,0);
         if(!this.hzFont) { return; }
         for each(var o:Object in this.hzTexts)
         {
            var s:String = TextField(o.tf).text;
            this.hzApplyFmt(o);
            if(o.role != "hdr") { TextField(o.tf).text = s; }
         }
      }

      // Sets a bar's target; hzTickBars glides it there. Health bar keeps a fading damage ghost.
      private function hzMeter(b:Sprite, w:Number, f:Number, col:uint) : void
      {
         var e:Object = null;
         for each(var o:Object in this.hzBars) { if(o.b == b) { e = o; break; } }
         f = Math.max(0,Math.min(1,f));
         if(e == null)
         {
            e = {"b":b,"w":w,"cur":f,"t":f,"col":col,"ghost":f};
            this.hzBars.push(e);
            this.hzMeterDraw(b,w,f,col,f);
            return;
         }
         e.w = w; e.t = f; e.col = col;
         if(!this.hzSmoothBars) { e.cur = f; e.ghost = f; this.hzMeterDraw(b,w,f,col,f); }
      }

      private function hzTickBars() : void
      {
         for each(var e:Object in this.hzBars)
         {
            var d:Number = e.t - e.cur;
            var moved:Boolean = Math.abs(d) > 0.001;
            if(moved) { e.cur += d * 0.18; } else { e.cur = e.t; }
            var gh:Number = e.ghost;
            if(e.b == this.hzVitHpBar || e.b == this.hzCHpBar || e.b == this.hzVnHpBar)
            {
               if(e.ghost > e.cur) { e.ghost = Math.max(e.cur,e.ghost - 0.004); } else { e.ghost = e.cur; }
            }
            else { e.ghost = e.cur; }
            if(moved || gh != e.ghost || e.lastCol != e.col) { this.hzMeterDraw(e.b,e.w,e.cur,e.col,e.ghost); e.lastCol = e.col; }
         }
      }

      private function hzMeterDraw(b:Sprite, w:Number, f:Number, col:uint, ghost:Number) : void
      {
         var fw:Number = w * Math.max(0,Math.min(1,f));
         if(b.name == "hzThick8")
         {
            // v0.19 vitals bar: 8px, track white 30a (dark on light cards), ghost = bar color ~37%
            var vg:* = b.graphics;
            var bc:uint = this.hzDarkText() ? this.hzIconCol(col) : col;
            vg.clear();
            vg.beginFill(this.hzDarkText() ? 0x000000 : 0xFFFFFF,this.hzDarkText() ? 0.14 : 0.12);
            vg.drawRoundRect(0,0,w,8,8,8);
            vg.endFill();
            if(ghost > f + 0.002) { vg.beginFill(bc,0.37); vg.drawRoundRect(0,0,Math.max(8,w * Math.min(1,ghost)),8,8,8); vg.endFill(); }
            if(fw > 0) { vg.beginFill(bc,1); vg.drawRoundRect(0,0,Math.max(8,fw),8,8,8); vg.endFill(); }
            return;
         }
         if(b.name == "hzThick")
         {
            var tg:* = b.graphics;
            tg.clear();
            tg.beginFill(this.hzDarkText() ? 0x000000 : 0xFFFFFF,this.hzDarkText() ? 0.14 : 0.1);
            tg.drawRoundRect(0,0,w,7,7,7);
            if(ghost > f + 0.002)
            {
               tg.beginFill(0xF2A08F,0.55);
               tg.drawRoundRect(0,0,w * ghost,7,7,7);
            }
            if(fw > 0)
            {
               tg.beginFill(this.hzDarkText() ? this.hzIconCol(col) : col,0.98);
               tg.drawRoundRect(0,0,Math.max(7,fw),7,7,7);
            }
            tg.endFill();
            return;
         }
         b.graphics.clear();
         b.graphics.beginFill(0x24414D,0.7);
         b.graphics.drawRoundRect(0,0,w,3,3,3);
         if(ghost > f + 0.002)
         {
            b.graphics.beginFill(0xF2A08F,0.55);
            b.graphics.drawRoundRect(0,0,w * ghost,3,3,3);
         }
         if(col != HZ_ACCENT && col != HZ_GREEN && fw > 0)
         {
            b.graphics.beginFill(col,0.25);
            b.graphics.drawRoundRect(-1,-2,fw + 2,7,7,7);
         }
         b.graphics.beginFill(col,0.95);
         b.graphics.drawRoundRect(0,0,fw,3,3,3);
         b.graphics.endFill();
      }

      // Original outline icon: twin-tank thruster pack with exhaust lines.
      private function hzJetIcon(p:Sprite, x:Number, y:Number) : void
      {
         var g:Sprite = new Sprite();
         this.hzJetIconVec = g;
         g.graphics.lineStyle(1.5,HZ_ACCENT,1);
         g.graphics.drawRoundRect(0,0,7,13,6,6);
         g.graphics.drawRoundRect(9,0,7,13,6,6);
         g.graphics.moveTo(4,2); g.graphics.lineTo(12,2);
         g.graphics.moveTo(2,15); g.graphics.lineTo(3.5,19);
         g.graphics.moveTo(5,15); g.graphics.lineTo(3.5,19);
         g.graphics.moveTo(11,15); g.graphics.lineTo(12.5,19);
         g.graphics.moveTo(14,15); g.graphics.lineTo(12.5,19);
         g.x = x; g.y = y;
         p.addChild(g);
      }

      private function hzOnIconError(e:IOErrorEvent) : void
      {
      }

      // ---- Compass (top center): style per user reference, data from HudCompassData.fDirection ----
      private function hzBuildCompass() : void
      {
         this.HorizonCompass_mc = new Sprite();
         var g:Sprite = new Sprite();
         this.hzCardBodies.push({"s":g,"w":HZ_CMP_W,"h":36,"k":"cmp"});
         this.hzDrawCmpBody(g);
         var sh:Sprite = new Sprite();
         sh.graphics.beginFill(0x000000,0.22);
         sh.graphics.drawRoundRect(2,4,HZ_CMP_W,36,16,16);
         sh.graphics.endFill();
         this.HorizonCompass_mc.addChild(sh);
         this.HorizonCompass_mc.addChild(g);
         for each(var n:String in HZ_CARD)
         {
            this.hzCmpLabels.push(this.hzText(this.HorizonCompass_mc,n,0,9,40,12,0x9FC7D4,false,"lbl"));
         }
         this.hzCmpMarks = new Sprite();
         this.HorizonCompass_mc.addChild(this.hzCmpMarks);
         this.hzCmpCenter = this.hzText(this.HorizonCompass_mc,"N · 000°",HZ_CMP_W / 2 - 60,7,120,14,HZ_ACCENT,false,"valS",true);
         var cf:TextFormat = TextField(this.hzCmpCenter).defaultTextFormat;
         cf.align = "center";
         this.hzTexts[this.hzTexts.length - 1].center = true;
         this.HorizonCompass_mc.scaleX = this.HorizonCompass_mc.scaleY = HZ_SCALE;
         this.HorizonCompass_mc.x = 960 - HZ_CMP_W * HZ_SCALE / 2;
         this.HorizonCompass_mc.y = 28;
         addChild(this.HorizonCompass_mc);
         this.hzBuildCmp19();
         BSUIDataManager.Subscribe("HudCompassData",this.hzOnCompass);
      }

      private function hzOnCompass(e:FromClientDataEvent) : *
      {
         try { this.hz40OnCmp(e.data); } catch(err40c:Error) { }   // v0.40: before the heading check (the flag comes without one)
         var r:Number = Number(e.data.fDirection);
         if(isNaN(r)) { return; }
         this.hzFixFonts();
         var deg:Number = (r * 180 / Math.PI) % 360;
         if(deg < 0) { deg += 360; }
         var i:int = 0;
         var ppd:Number = (HZ_CMP_W - 40) / 180;
         while(i < HZ_CARD.length)
         {
            var t:TextField = this.hzCmpLabels[i];
            var d:Number = i * 45 - deg;
            while(d > 180) { d -= 360; }
            while(d < -180) { d += 360; }
            t.visible = Math.abs(d) <= 90 && Math.abs(d) > 14;
            t.x = HZ_CMP_W / 2 + d * ppd - t.textWidth / 2 - 2;
            i++;
         }
         var idx:int = int(Math.round(deg / 45)) % 8;
         var ds:String = String(int(Math.round(deg)) % 360);
         while(ds.length < 3) { ds = "0" + ds; }
         this.hzCmpCenter.text = HZ_CARD[idx] + " · " + ds + "°";
         this.hzCmpDeg = deg;
         this.hzCmpTick19();
         this.hzCmpData = e.data;
         this.hzDrawCompassMarkers();
         if(this.HorizonQuest_mc)
         {
            this.hzUpdateQuests(e.data.aMissionMarkers as Array);
            this.hzRefreshVisibility();
         }
      }

      // ---- Planet card: body, temp/grav/air, hazards (EnvironmentEffectsData) ----
      // ---- Afflictions card: injuries & illnesses (PersonalEffectsData) ----
      // ---- Ammo card: WeaponData ----
      private function hzBuildEnv() : void
      {
         var tw:Number = (HZ_W - 16 - 12) / 3;
         var names:Array = ["TEMP","GRAVITY","AIR"];
         var vals:Array = [];
         var i:int = 0;
         this.HorizonEnv_mc = new Sprite();
         this.hzPlanOld = new Sprite();
         this.HorizonEnv_mc.addChild(this.hzPlanOld);
         this.hzDotPlan = this.hzCard(this.hzPlanOld,HZ_W,128,"planet",null);
         this.hzPlanTitle = this.hzText(this.hzPlanOld,"--",29,7,HZ_W - 52,12,HZ_VALUE,false,"hdr");
         this.hzEnvLoc = this.hzPlanTitle;
         while(i < 3)
         {
            var tx:Number = 8 + i * (tw + 6);
            this.hzTile(this.hzPlanOld,tx,HZ_HDR + 6,tw,40);
            this.hzText(this.hzPlanOld,names[i],tx + 8,HZ_HDR + 9,tw - 12,9,HZ_LABEL,false,"lbl");
            vals.push(this.hzText(this.hzPlanOld,"--",tx + 8,HZ_HDR + 22,tw - 12,14,HZ_VALUE,false,"valS"));
            i++;
         }
         this.hzEnvTemp = vals[0]; this.hzEnvGrav = vals[1]; this.hzEnvAir = vals[2];
         this.hzEnvStats = this.hzEnvTemp;
         this.hzTile(this.hzPlanOld,8,HZ_HDR + 52,HZ_W - 16,42);
         this.hzIcon(this.hzPlanOld,"hazard",16,HZ_HDR + 58,HZ_YELLOW);
         this.hzEnvHaz = this.hzText(this.hzPlanOld,"No hazards",33,HZ_HDR + 56,HZ_W - 50,11,HZ_VALUE,false,"sec");
         this.hzEnvSoak = new Sprite(); this.hzEnvSoak.x = 16; this.hzEnvSoak.y = HZ_HDR + 80;
         this.hzPlanOld.addChild(this.hzEnvSoak);
         this.hzMeter(this.hzEnvSoak,HZ_W - 32,0,HZ_YELLOW);
         this.hzPlanAlert = new Sprite();
         this.hzPlanOld.addChild(this.hzPlanAlert);
         this.hzBuildPlanPill();
         this.HorizonEnv_mc.scaleX = this.HorizonEnv_mc.scaleY = HZ_SCALE;
         this.HorizonEnv_mc.x = 80;
         this.HorizonEnv_mc.y = 746 - 128 * HZ_SCALE;
         addChild(this.HorizonEnv_mc);
         this.HorizonAffl_mc = new Sprite();
         this.hzDotAff = this.hzCard(this.HorizonAffl_mc,HZ_W,68,"medic","AFFLICTIONS");
         this.hzDot(this.hzDotAff,HZ_RED);
         this.hzTile(this.HorizonAffl_mc,8,HZ_HDR + 6,HZ_W - 16,28);
         this.hzEnvAff = this.hzText(this.HorizonAffl_mc,"None",16,HZ_HDR + 11,HZ_W - 32,11,HZ_VALUE,false,"sec");
         this.hzBuildAffl19();
         this.HorizonAffl_mc.scaleX = this.HorizonAffl_mc.scaleY = HZ_SCALE;
         this.HorizonAffl_mc.x = 80;
         this.HorizonAffl_mc.y = this.HorizonCard_mc.y - (68 + 10) * HZ_SCALE;
         addChild(this.HorizonAffl_mc);
         this.HorizonAmmo_mc = new Sprite();
         this.hzEqOld = new Sprite();   // v0.27: legacy classic card, detached (never shown)
         this.hzDotAmmo = this.hzCard(this.hzEqOld,HZ_W,100,"ammo","EQUIPMENT");
         this.hzAmmoCount = this.hzText(this.hzEqOld,"--",HZ_W - 128,4,104,15,HZ_VALUE,true,"val");
         this.hzMagSp = new Sprite();
         this.hzMagSp.x = HZ_W - 92; this.hzMagSp.y = 22;
         this.hzEqOld.addChild(this.hzMagSp);
         this.hzTile(this.hzEqOld,8,HZ_HDR + 6,HZ_W - 16,28);
         this.hzIcon(this.hzEqOld,"gun",16,HZ_HDR + 14,HZ_LABEL);
         this.hzAmmoWeapon = this.hzText(this.hzEqOld,"",34,HZ_HDR + 11,HZ_W - 50,11,HZ_VALUE,false,"sec");
         this.hzTile(this.hzEqOld,8,HZ_HDR + 38,HZ_W - 16,28);
         this.hzIcon(this.hzEqOld,"ammo",16,HZ_HDR + 46,HZ_LABEL);
         this.hzAmmoType = this.hzText(this.hzEqOld,"--",34,HZ_HDR + 43,HZ_W - 50,11,HZ_VALUE,false,"sec");
         this.hzBuildEqNew();
         this.HorizonAmmo_mc.scaleX = this.HorizonAmmo_mc.scaleY = HZ_SCALE;
         this.HorizonAmmo_mc.x = 1920 - 80 - HZ_W * HZ_SCALE;
         this.HorizonAmmo_mc.y = 786 - 100 * HZ_SCALE;
         addChild(this.HorizonAmmo_mc);
         BSUIDataManager.Subscribe("LocalEnvironmentData",this.hzOnLocalEnv);
         BSUIDataManager.Subscribe("EnvironmentEffectsData",this.hzOnEnvEffects);
         BSUIDataManager.Subscribe("PersonalEffectsData",this.hzOnPersonalEffects);
         BSUIDataManager.Subscribe("WeaponData",this.hzOnWeapon);
         BSUIDataManager.Subscribe("QuestData",this.hzOnQuestData);
         BSUIDataManager.Subscribe("QuestUpdateData",this.hzOnQuestUpdate);
         BSUIDataManager.Subscribe("PlayerInventoryData",this.hzOnInventory);
      }

      // ---- Quest Tracker card: built from the HUD's mission markers (HudCompassData.aMissionMarkers) ----
      private function hzBuildQuest() : void
      {
         this.HorizonQuest_mc = new Sprite();
         this.hzCard(this.HorizonQuest_mc,HZ_W,94,"flag","QUEST TRACKER");
         this.hzTile(this.HorizonQuest_mc,8,HZ_HDR + 6,HZ_W - 16,52);
         this.hzQTitle = this.hzText(this.HorizonQuest_mc,"ACTIVE OBJECTIVE",16,HZ_HDR + 9,HZ_W - 136,9,HZ_LABEL,false,"lbl");
         this.hzQActiveSub = this.hzText(this.HorizonQuest_mc,"",HZ_W - 116,HZ_HDR + 9,100,9,HZ_ACCENT,true,"lbl",true);
         var bar:Sprite = new Sprite();
         bar.graphics.beginFill(HZ_ACCENT,0.9);
         bar.graphics.drawRect(0,0,2,22);
         bar.graphics.endFill();
         bar.x = 16; bar.y = HZ_HDR + 27;
         this.HorizonQuest_mc.addChild(bar);
         this.hzQActive = this.hzText(this.HorizonQuest_mc,"No active objective",24,HZ_HDR + 27,HZ_W - 40,13,HZ_VALUE,false,"sec");
         this.hzBuildQuest19();
         this.HorizonQuest_mc.scaleX = this.HorizonQuest_mc.scaleY = HZ_SCALE;
         this.HorizonQuest_mc.x = 1920 - 80 - HZ_W * HZ_SCALE;
         this.HorizonQuest_mc.y = 300;
         addChild(this.HorizonQuest_mc);
      }

      private function hzIsQuestType(t:uint) : Boolean
      {
         return t == MapMarkerUtils.MIT_MARKER_QUEST || t == MapMarkerUtils.MIT_MARKER_QUEST_DOOR || t == MapMarkerUtils.MIT_MARKER_QUEST_OFFPLANET;
      }

      private function hzFmtDist(m:Number) : String
      {
         if(isNaN(m) || m <= 0) { return ""; }
         return m >= 1000 ? GlobalFunc.FormatNumberToString(m / 1000,1,true) + " km" : Math.round(m) + " m";
      }

      private function hzUpdateQuests(mm:Array) : void
      {
         // v0.27: the first marker in aMissionMarkers is not stable (the game re-orders main / optional objectives),
         // which made the tracker flip between them. Sticky main objective + the others as sub-lines.
         var seen:Array = [];
         var active:Object = null;
         var list:Array = [];
         for each(var o:Object in mm)
         {
            if(!o || !this.hzIsQuestType(uint(o.uiMarkerIconType))) { continue; }
            var t:String = o.strText ? String(o.strText) : "";
            if(t == "" || seen.indexOf(t) >= 0) { continue; }
            seen.push(t);
            list.push(o);
         }
         try { active = this.hz27PickMain(list); } catch(errQ:Error) { active = list.length > 0 ? list[0] : null; }
         try { this.hz27QBuildSubs(list,active); } catch(errQ2:Error) { this.hz27QSubs = []; }
         this.hzQHasAny = seen.length > 0;
         this.hzQActive.text = active ? String(active.strText) : "No active objective";
         this.hzQActiveSub.text = active ? (uint(active.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_QUEST_OFFPLANET ? "OFF PLANET" : this.hzFmtDist(Number(active.fDistanceToPlayer))) : "";
         if(this.hzCQText) { this.hzCQText.text = this.hzQActive.text; }
         if(this.hzCQDist) { this.hzCQDist.text = this.hzQActiveSub.text; }
         this.hzQObjStr = active ? String(active.strText) : "";
         this.hzQDistStr = this.hzQActiveSub.text;
         this.hzQSync();
      }

      // Compass markers: quest = gold diamond, enemy = red dot, others = small gray tick.
      // Compass markers from HudCompassData: aMissionMarkers (quests), aMarkers (followers, ship, locations,
      // outposts, custom marker...), aEnemyMarkers, plus any other array of objects with fHeading (future-proof).
      // De-duplicated by uiHandle; filtered per type by the COMPASS settings tab.
      private function hzDrawCompassMarkers() : void
      {
         if(!this.hzCmpMarks || !this.hzCmpData) { return; }
         var v19:Boolean = this.hzV19() && this.hzCmpMarks19 != null;
         this.hzCmpMarks.graphics.clear();
         if(this.hzCmpMarks19) { this.hzCmpMarks19.graphics.clear(); }
         var g:* = v19 ? this.hzCmpMarks19.graphics : this.hzCmpMarks.graphics;
         var cmw:Number = v19 ? this.hzCmpW19 : HZ_CMP_W;
         var ppd:Number = (cmw - 40) / 180;
         var lists:Array = [];
         var lnames:Array = [];
         var dk:String = null;
         for each(dk in ["aMissionMarkers","aMarkers","aEnemyMarkers"])
         {
            if(this.hzCmpData[dk] is Array) { lists.push(this.hzCmpData[dk]); lnames.push(dk); }
         }
         for(dk in this.hzCmpData)
         {
            if(lnames.indexOf(dk) >= 0) { continue; }
            var av:* = this.hzCmpData[dk];
            if(av is Array && (av as Array).length > 0 && (av as Array)[0] != null && (av as Array)[0].fHeading != undefined)
            {
               lists.push(av); lnames.push(dk);
            }
         }
         var seen:Object = {};
         var dbg:Object = {};
         var dlines:Array = [];
         this.hzCmpDbgClear();
         var li:int = 0;
         while(li < lists.length)
         {
            var arr:Array = lists[li] as Array;
            var enemyList:Boolean = String(lnames[li]).toLowerCase().indexOf("enemy") >= 0;
            for each(var o:Object in arr)
            {
               if(!o || o.fHeading == undefined) { continue; }
               var mt:uint = uint(o.uiMarkerIconType);
               var mmt:int = (o.uMapMarkerType != undefined && o.uMapMarkerType !== null) ? int(o.uMapMarkerType) : -1;
               // The game draws MIT_MARKER_COMPANION with the generic "Location" frame. r4: followers, ships and vehicles by the
               // icon type only (the compass map type is not the scripts' MARKER_* table: the player ship arrives as 83).
               var isFolMark:Boolean = mt == MapMarkerUtils.MIT_MARKER_COMPANION;
               var isShip:Boolean = !isFolMark && (mt == MapMarkerUtils.MIT_MARKER_SHIP_PARKED || mt == MapMarkerUtils.MIT_MARKER_VEHICLE);
               dbg[lnames[li] + ":" + mt] = int(dbg[lnames[li] + ":" + mt]) + 1;
               if(this.hzDebug && dlines.length < 14)
               {
                  var rel:Number = Number(o.fHeading) * 180 / Math.PI - this.hzCmpDeg;
                  while(rel > 180) { rel -= 360; }
                  while(rel < -180) { rel += 360; }
                  dlines.push(String(lnames[li]) + " type=" + mt + " map=" + mmt + " head=" + Math.round(Number(o.fHeading) * 180 / Math.PI) + " rel=" + Math.round(rel) + " a=" + (o.fDistanceAlpha != undefined ? Math.round(Number(o.fDistanceAlpha) * 100) / 100 : "-") + " near=" + o.bIsNear + (isFolMark ? " FOL" : (isShip ? " SHIP" : "")));
               }
               if(!this.hzShowCompassMarkers) { continue; }
               if(o.uiHandle != undefined && uint(o.uiHandle) != 0)
               {
                  // v0.30: a companion that is also a quest target keeps its own follower marker (own de-dup key)
                  var sk:String = (isFolMark ? "f" : "m") + String(o.uiHandle);
                  if(seen[sk]) { continue; }
                  seen[sk] = true;
               }
               var md:Number = Number(o.fHeading) * 180 / Math.PI - this.hzCmpDeg;
               while(md > 180) { md -= 360; }
               while(md < -180) { md += 360; }
               var edgeF:int = 0;
               if(Math.abs(md) > 90)
               {
                  // v0.30: a following companion walks behind the player (outside the 180 deg strip): pin it to the strip end
                  if(!(isFolMark && this.hzCmpFollowers)) { continue; }
                  edgeF = md > 0 ? 1 : -1;
                  md = edgeF * 90;
               }
               var mx:Number = cmw / 2 + md * ppd;
               var fa:Number = (o.fDistanceAlpha != undefined && o.fDistanceAlpha !== null) ? Math.max(0.35,Math.min(1,Number(o.fDistanceAlpha))) : 1;
               if(this.hzDebug) { this.hzCmpDbgLabel(mx,String(mt) + (mmt >= 0 ? "/" + mmt : "")); }
               if(this.hzIsQuestType(mt) && !isFolMark)
               {
                  if(v19) { this.hzCmpMark19(g,"quest",mx,fa); continue; }
                  g.beginFill(0xF2D35F,fa);
                  g.moveTo(mx,-2); g.lineTo(mx + 5,3); g.lineTo(mx,8); g.lineTo(mx - 5,3); g.lineTo(mx,-2);
                  g.endFill();
               }
               else if(isFolMark)
               {
                  if(!this.hzCmpFollowers) { continue; }
                  if(v19)
                  {
                     try { this.hzCmpMark19(g,"follower",mx,edgeF != 0 ? Math.max(0.55,fa * 0.8) : fa); if(edgeF != 0) { this.hz30FolEdge(g,mx,edgeF); } } catch(errF:Error) { }
                     continue;
                  }
                  g.lineStyle(1,0x0B1620,0.8);
                  g.beginFill(this.hz27FolCol(),fa);
                  g.drawCircle(mx,22,3);
                  g.endFill();
                  g.beginFill(this.hz27FolCol(),fa);
                  g.moveTo(mx - 5,33); g.curveTo(mx,24,mx + 5,33); g.lineTo(mx - 5,33);
                  g.endFill();
                  g.lineStyle();
               }
               else if(isShip)
               {
                  if(!this.hzCmpShip) { continue; }
                  if(v19) { this.hzCmpMark19(g,"ship",mx,fa); continue; }
                  g.beginFill(0x8FD3F2,fa);
                  g.moveTo(mx,23); g.lineTo(mx + 6,33); g.lineTo(mx,30); g.lineTo(mx - 6,33); g.lineTo(mx,23);
                  g.endFill();
               }
               else if(enemyList || mt == MapMarkerUtils.MIT_MARKER_ENEMY || mt == MapMarkerUtils.MIT_MARKER_ENEMY_TARGETED)
               {
                  if(!this.hzCmpEnemies) { continue; }
                  if(v19) { this.hzCmpMark19(g,mt == MapMarkerUtils.MIT_MARKER_ENEMY_TARGETED ? "enemyT" : "enemy",mx,fa); continue; }
                  g.beginFill(HZ_RED,0.95 * fa);
                  g.drawCircle(mx,29,mt == MapMarkerUtils.MIT_MARKER_ENEMY_TARGETED ? 3.5 : 2.5);
                  g.endFill();
               }
               else if(mt == MapMarkerUtils.MIT_MARKER_PLAYERSET || mt == MapMarkerUtils.MIT_MARKER_POSITION)
               {
                  if(!this.hzCmpPlayerMark) { continue; }
                  if(v19) { this.hzCmpMark19(g,"player",mx,fa); continue; }
                  g.beginFill(0xF2F4F6,fa);
                  g.drawRect(mx - 1,22,2,11);
                  g.moveTo(mx + 1,22); g.lineTo(mx + 7,25); g.lineTo(mx + 1,28); g.lineTo(mx + 1,22);
                  g.endFill();
               }
               else if(mt == MapMarkerUtils.MIT_MARKER_HAZARD)
               {
                  continue; // hazards are on the planet card
               }
               else
               {
                  // locations, POIs, outposts, recon, anything unknown
                  if(!this.hzCmpLocations) { continue; }
                  if(v19) { this.hzCmpMark19(g,mt == MapMarkerUtils.MIT_MARKER_OUTPOST ? "outpost" : "loc",mx,fa); continue; }
                  g.lineStyle(1.2,0xD8E4EA,0.85 * fa);
                  if(mt == MapMarkerUtils.MIT_MARKER_OUTPOST) { g.drawRect(mx - 3,25,6,6); }
                  else { g.moveTo(mx,24); g.lineTo(mx + 4,28); g.lineTo(mx,32); g.lineTo(mx - 4,28); g.lineTo(mx,24); }
                  g.lineStyle();
               }
            }
            li++;
         }
         if(this.hzDebug)
         {
            var ds:Array = [];
            for(var dkey:String in dbg) { ds.push(dkey + "x" + dbg[dkey]); }
            this.hzDbgCmp = ds.join("  ") + "\n" + dlines.join("\n");
            if(this.hzFrameN % 10 == 0) { this.hzDbgShow(); }
         }
      }

      private var hzCmpDbgSp:Sprite = null;
      private var hzCmpDbgPool:Array = [];
      private var hzCmpDbgUsed:int = 0;

      private function hzKeys(o:Object) : String
      {
         var a:Array = [];
         for(var k:String in o) { a.push(k + "=" + String(o[k]).substr(0,24)); }
         a.sort();
         return a.join(", ");
      }

      private function hzDbgEnvSub() : void
      {
         if(this.hzDbgSubbed || !this.hzDebug) { return; }
         this.hzDbgSubbed = true;
         try { BSUIDataManager.Subscribe("LocalEnvData_Frequent",this.hzOnDbgEnvFreq); } catch(e1:Error) { }
         try { BSUIDataManager.Subscribe("HUDLocationData",this.hzOnDbgLoc); } catch(e2:Error) { }
      }

      private function hzOnDbgEnvFreq(e:FromClientDataEvent) : *
      {
         this.hzDbgEnvLine(1,"LocalEnvData_Frequent: " + this.hzKeys(e.data));
      }

      private function hzOnDbgLoc(e:FromClientDataEvent) : *
      {
         this.hzDbgEnvLine(2,"HUDLocationData: " + this.hzKeys(e.data));
      }

      private function hzDbgEnvLine(i:int, t:String) : void
      {
         var a:Array = this.hzDbgEnv.split("\n");
         while(a.length < 3) { a.push(""); }
         a[i] = t;
         this.hzDbgEnv = a.join("\n");
      }

      private function hzCmpDbgClear() : void
      {
         this.hzCmpDbgUsed = 0;
         for each(var t:TextField in this.hzCmpDbgPool) { t.visible = false; }
      }

      // Debug=1: numeric "iconType/mapMarkerType" label under each compass marker
      private function hzCmpDbgLabel(x:Number, txt:String) : void
      {
         if(!this.HorizonCompass_mc) { return; }
         if(!this.hzCmpDbgSp) { this.hzCmpDbgSp = new Sprite(); this.HorizonCompass_mc.addChild(this.hzCmpDbgSp); }
         var t:TextField = null;
         if(this.hzCmpDbgUsed < this.hzCmpDbgPool.length) { t = this.hzCmpDbgPool[this.hzCmpDbgUsed]; }
         else
         {
            if(this.hzCmpDbgPool.length >= 24) { return; }
            t = new TextField();
            t.embedFonts = true; t.selectable = false; t.width = 60; t.height = 16;
            var f:TextFormat = new TextFormat(this.hzFont ? this.hzFont : "$MAIN_Font",9,0xFFFF66);
            f.align = "center";
            t.defaultTextFormat = f;
            this.hzCmpDbgSp.addChild(t);
            this.hzCmpDbgPool.push(t);
         }
         this.hzCmpDbgUsed++;
         t.text = txt;
         t.textColor = 0xFFFF66;
         t.x = x - 30; t.y = 36;
         t.visible = true;
      }

      private function hzPick(d:Object, keys:Array) : String
      {
         for each(var k:String in keys)
         {
            if(d[k] != undefined && d[k] != null && String(d[k]) != "") { return String(d[k]); }
         }
         return null;
      }

      private function hzOnWeapon(e:FromClientDataEvent) : *
      {
         var d:Object = e.data;
         this.hzFixFonts();
         this.hzAmmoDrawn = d.bDisplayAmmo === true;
         this.hzDbgWeap = this.hzDump(d);
         this.hzDbgShow();
         var clip:Number = Number(d.uClipAmmo);
         var tot:Number = Number(d.uTotalAmmo);
         this.hzEqClip = clip;
         this.hzEqTot = tot;
         this.hzEqPct = d.bShowAmmoAsPercent === true;
         this.hzEqHasAmmo = d.bDisplayAmmo === true && !isNaN(clip);
         if(d.bShowAmmoAsPercent === true && tot > 0)
         {
            this.hzAmmoCount.text = Math.floor(clip / tot * 100) + "%";
         }
         else
         {
            var rest:Number = tot <= clip ? 0 : tot - clip;
            this.hzAmmoCount.text = clip + " / " + (rest > 9999 ? "9999+" : String(rest));
         }
         // per-model outline: WeaponData.sIconLinkageName (vanilla BottomRightGroup loads it from WeaponIcons.swf)
         var icn:String = d.sIconLinkageName != undefined && d.sIconLinkageName != null ? String(d.sIconLinkageName) : "";
         this.hzDbgWeap = "sIconLinkageName=" + icn + " | " + this.hzDbgWeap;
         try { this.hzE19SetSym(icn); } catch(errSym:Error) { }
         this.hzDbgShow();
         var wn:String = this.hzPick(d,["sWeaponName","sName","sEquippedWeaponName","sItemName","WeaponName"]);
         this.hzAmmoWeapon.text = wn != null ? wn : "";
         this.hzWeapName = wn != null ? wn : "";
         if(this.hzMagWeap != this.hzWeapName)
         {
            this.hzMagWeap = this.hzWeapName;
            this.hzMagMax = 0;
            this.hzMagCap = 0;
         }
         if(!isNaN(clip)) { this.hzMagClip = clip; if(clip > this.hzMagMax) { this.hzMagMax = clip; } }
         this.hzResolveAmmoType();
         this.hzDrawMag();
         if(this.hzCAmmo) { this.hzCAmmo.text = this.hzAmmoCount.text; }
         this.hzEqSync();
         this.hzDot(this.hzDotAmmo,clip <= 0 ? HZ_RED : (tot > 0 && clip / tot < 0.15 ? HZ_YELLOW : HZ_GREEN));
         this.hzRefreshVisibility();
      }

      // Purpose: short label for an effect icon id.
      // Inputs: a frame name such as PersonalEffect_CardioRespiratoryCirculatory_Negative.
      // Outputs: "Cardio Respiratory Circulatory" for that name. Thermal, Radiation, Airborne, and Corrosive stay one word.
      // The game's own bio alert shows sAlertText only (vanilla BottomLeftGroup, BIO_ALERT). This label is used when sAlertSubText is empty.
      // Dependencies: hzSplitCamel. Scaleform String.replace does not expand $1, so the camel split is not a replace.
      private function hzPretty(id:String) : String
      {
         if(!id) { return ""; }
         var s:String = id;
         var lo:String = s.toLowerCase();
         if(lo.indexOf("thermal") >= 0) { return "Thermal"; }
         if(lo.indexOf("radiation") >= 0) { return "Radiation"; }
         if(lo.indexOf("airborne") >= 0) { return "Airborne"; }
         if(lo.indexOf("corros") >= 0) { return "Corrosive"; }
         s = s.replace(/^(PersonalEffect_|Personal_|HazardEffect_|Hazard_)/,"");
         s = s.replace(/_(Negative|Positive)$/,"");
         s = s.replace(/_/g," ");
         s = this.hzSplitCamel(s);
         return s;
      }
      // A lowercase letter followed by a capital gets a space. "CardioRespiratoryCirculatory" becomes "Cardio Respiratory Circulatory".
      private function hzSplitCamel(s:String) : String
      {
         if(s == null || s.length < 2) { return s == null ? "" : s; }
         var o:String = s.charAt(0);
         var i:int = 1;
         while(i < s.length)
         {
            var p:int = s.charCodeAt(i - 1);
            var c:int = s.charCodeAt(i);
            if(p >= 97 && p <= 122 && c >= 65 && c <= 90) { o += " "; }
            o += s.charAt(i);
            i++;
         }
         return o;
      }

      private function hzJoinEffects(a:Array) : String
      {
         var out:Array = [];
         if(a)
         {
            for each(var o:Object in a)
            {
               var p:String = this.hzPretty(o.sEffectIcon);
               if(p && out.indexOf(p) < 0) { out.push(p); }
            }
         }
         return out.length ? out.join(", ") : "None";
      }

      // Purpose: format the planet temperature with a unit. The game value is Celsius.
      // Inputs: Celsius number from LocalEnvironmentData.fTemperature.
      // Outputs: rounded text such as "11 °C" or "52 °F". Dependencies: hzTempUnit (0 C, 1 F).
      // Last modified: 2026-10-24.
      private function hzTempText(c:Number) : String
      {
         if(c == null || isNaN(c)) { return "--"; }
         var v:Number = int(this.hzTempUnit) == 1 ? Math.round(c * 9 / 5 + 32) : Math.round(c);
         return String(v) + (int(this.hzTempUnit) == 1 ? " °F" : " °C");
      }

      private function hzOnLocalEnv(e:FromClientDataEvent) : *
      {
         var d:Object = e.data;
         this.hzFixFonts();
         var body:String = d.sBodyName ? String(d.sBodyName) : (d.sLocationName ? String(d.sLocationName) : "--");
         var sys:String = this.hzPick(d,["sSystemName","sStarSystemName","sSystem","sStarName"]);
         this.hzSetHdr(this.hzPlanTitle,(sys != null && sys != body) ? body + " / " + sys : body);
         this.hzPpBodyName = body;
         var inShip:Boolean = Boolean(d.bInSpaceship) && !d.bIsLanded;
         if(this.hzInShip != Boolean(d.bInSpaceship)) { this.hzInShip = Boolean(d.bInSpaceship); this.hzRefreshVisibility(); }
         if(inShip)
         {
            this.hzEnvTempC = NaN;
            this.hzEnvTemp.text = "--"; this.hzEnvGrav.text = "--"; this.hzEnvAir.text = "--";
         }
         else
         {
            if(d.fTemperature == null || isNaN(Number(d.fTemperature)))
            {
               this.hzEnvTempC = NaN;
               this.hzEnvTemp.text = "--";
            }
            else
            {
               this.hzEnvTempC = Number(d.fTemperature);
               this.hzEnvTemp.text = this.hzTempText(this.hzEnvTempC);
            }
            this.hzEnvGrav.text = GlobalFunc.FormatNumberToString(d.fGravity,2,true) + "g";
            this.hzEnvAir.text = d.fOxygenPercent + "%";
         }
         this.hzPpSys = sys != null ? sys : "";
         // LocalEnvironmentData.uBodyType (BSGalaxyTypes): 0 undefined, 1 star, 2 planet, 3 moon, 4 satellite, 5 asteroid belt, 6 station
         var bt:int = (d.uBodyType != undefined && d.uBodyType !== null) ? int(d.uBodyType) : -1;
         var pk:String = inShip ? "ship" : (bt == 6 ? "station" : (d.bIsInSpace === true ? "space" : "planet"));
         if(!this.hzV19()) { pk = Boolean(d.bInSpaceship) ? "ship" : (d.bIsInSpace === true ? "space" : "planet"); }
         if(bt != this.hzPpBodyType) { this.hzPpBodyType = bt; this.hzPpDrawIcon(); }
         if(this.hzDebug) { this.hzDbgEnv = "LocalEnvironmentData: " + this.hzKeys(d) + "\n" + this.hzDbgEnv.split("\n").slice(1).join("\n"); }
         if(pk != this.hzPpKind) { this.hzPpKind = pk; this.hzPpDrawIcon(); }
         this.hzPpSync();
      }

      private function hzOnEnvEffects(e:FromClientDataEvent) : *
      {
         this.hzFixFonts();
         var a:Array = e.data.aEnvironmentEffects as Array;
         var txt:String = this.hzJoinEffects(a);
         this.hzEnvHaz.text = txt == "None" ? "No hazards" : txt;
         var soak:Number = Number(e.data.fSoakDamagePct);
         if(isNaN(soak)) { soak = 0; }
         this.hzMeter(this.hzEnvSoak,HZ_W - 32,soak,soak > 0.66 ? HZ_RED : HZ_YELLOW);
         this.hzEnvSoak.visible = txt != "None";
         this.hzPlanAlertOn = this.hzHazardAlert && txt != "None" && soak > 0.01;
         if(!this.hzPlanAlertOn) { this.hzPlanAlert.graphics.clear(); }
         this.hzDot(this.hzDotPlan,txt == "None" ? HZ_GREEN : (soak > 0.66 ? HZ_RED : HZ_YELLOW));
         var n:int = 0;
         var word:String = "HAZARD";
         for each(var ef:Object in a)
         {
            var ic:String = ef && ef.sEffectIcon != null ? String(ef.sEffectIcon) : "";
            if(ic == "HazardEffect_RestoreSoak") { continue; }
            n++;
            var li:String = ic.toLowerCase();
            if(n == 1)
            {
               if(li.indexOf("thermal") >= 0 || li.indexOf("heat") >= 0 || li.indexOf("cold") >= 0) { word = "THERMAL"; }
               else if(li.indexOf("radiation") >= 0) { word = "RADIATION"; }
               else if(li.indexOf("corrosive") >= 0) { word = "CORROSIVE"; }
               else if(li.indexOf("airborne") >= 0 || li.indexOf("toxic") >= 0) { word = "AIRBORNE"; }
            }
         }
         if(n == 0) { this.hzPpStatus = "SAFE"; this.hzPpStatusCol = 0; }
         else if(soak >= 1) { this.hzPpStatus = "DANGER"; this.hzPpStatusCol = 2; }
         else { this.hzPpStatus = word; this.hzPpStatusCol = 1; }
         this.hzPpSync();
         this.hzAfSetEnv(a,soak);
      }

      private function hzOnPersonalEffects(e:FromClientDataEvent) : *
      {
         this.hzFixFonts();
         try { this.hz26Log("PersonalEffectsData",e.data); } catch(errL:Error) { }
         var t:String = this.hzJoinEffects(e.data.aPersonalEffects as Array);
         this.hzEnvAff.text = t;
         this.hzAfSetPers(e.data.aPersonalEffects as Array);
      }

      private function hzOnCrosshair(e:FromClientDataEvent) : *
      {
         this.hzCrossOn = e.data.bEnabled !== false;
         try { this.hzCrossIron = Boolean(e.data.bIronSights); this.hzCross3rd = Boolean(e.data.bIn3rdPerson); this.hzCrossTool = Boolean(e.data.bIsToolGrip); } catch(errX:Error) { }
         var ct:Number = Number(e.data.uType);
         if(ct != this.hzCrossType) { this.hzT19Ver++; }
         this.hzCrossType = ct;
         this.hzDbgCross = this.hzDump(e.data);
         this.hzDbgShow();
         this.hzRefreshVisibility();
      }

      private function hzOnPlayerData(e:FromClientDataEvent) : *
      {
         if(this.hz36SetCombat(e.data.bIsInCombat === true)) { this.hzRefreshVisibility(); }
      }

      // Compact mode: one slim line per reading (icon, value, bar).
      private function hzStrip(p:Sprite, y:Number, icon:String, col:uint) : Array
      {
         this.hzTile(p,0,y,210,24);
         this.hzIcon(p,icon,8,y + 6,col);
         var t:TextField = this.hzText(p,"--",110,y + 3,92,12,HZ_VALUE,true,"valS");
         var bar:Sprite = new Sprite(); bar.x = 26; bar.y = y + 11;
         p.addChild(bar);
         this.hzMeter(bar,80,1,col);
         return [t,bar];
      }

      private function hzBuildCompact() : void
      {
         var a:Array = null;
         this.HorizonCompact_mc = new Sprite();
         var n0:int = this.HorizonCompact_mc.numChildren;
         a = this.hzStrip(this.HorizonCompact_mc,0,"ammo",HZ_ACCENT); this.hzCAmmo = a[0]; Sprite(a[1]).visible = false;
         this.hzCAmmoRow = [];
         while(n0 < this.HorizonCompact_mc.numChildren) { if(this.HorizonCompact_mc.getChildAt(n0) != a[1]) { this.hzCAmmoRow.push(this.HorizonCompact_mc.getChildAt(n0)); } n0++; }
         this.hzEqApplyStyle();
         a = this.hzStrip(this.HorizonCompact_mc,30,"o2",HZ_ACCENT); this.hzCO2 = a[0]; this.hzCO2Bar = a[1];
         a = this.hzStrip(this.HorizonCompact_mc,60,"heart",HZ_GREEN); this.hzCHp = a[0]; this.hzCHpBar = a[1];
         a = this.hzStrip(this.HorizonCompact_mc,90,"vitals",HZ_ACCENT); this.hzCJet = a[0]; this.hzCJetBar = a[1];
         this.HorizonCompact_mc.scaleX = this.HorizonCompact_mc.scaleY = HZ_SCALE;
         this.HorizonCompact_mc.x = 80;
         this.HorizonCompact_mc.y = 746 - 114 * HZ_SCALE;
         addChild(this.HorizonCompact_mc);
         this.HorizonCompact_mc.visible = false;
         // Compact quest strip: one line, objective + distance
         this.HorizonCompactQuest_mc = new Sprite();
         this.hzTile(this.HorizonCompactQuest_mc,0,0,HZ_W,24);
         this.hzIcon(this.HorizonCompactQuest_mc,"flag",8,6,HZ_ACCENT);
         this.hzCQText = this.hzText(this.HorizonCompactQuest_mc,this.hzQActive ? this.hzQActive.text : "No active objective",26,4,HZ_W - 112,11,HZ_VALUE,false,"sec");
         this.hzCQDist = this.hzText(this.HorizonCompactQuest_mc,this.hzQActiveSub ? this.hzQActiveSub.text : "",HZ_W - 90,4,82,11,HZ_ACCENT,true,"lbl",true);
         this.hzBuildCQuest19();
         this.HorizonCompactQuest_mc.scaleX = this.HorizonCompactQuest_mc.scaleY = HZ_SCALE * this.hzHudScale;
         this.HorizonCompactQuest_mc.x = 1920 - 80 - HZ_W * HZ_SCALE;
         this.HorizonCompactQuest_mc.y = 300;
         addChild(this.HorizonCompactQuest_mc);
         this.HorizonCompactQuest_mc.visible = false;
         this.hzFixFonts();
      }

      // Anchor cards to the real visible screen edges (fixes cards floating mid-screen).
      private function hzLayout() : Boolean
      {
         var vr:Rectangle = Extensions.visibleRect;
         if(vr == null || vr.width < 100 || stage == null) { return false; }
         var tl:Point = globalToLocal(new Point(vr.left,vr.top));
         var br:Point = globalToLocal(new Point(vr.right,vr.bottom));
         if(isNaN(tl.x) || br.x - tl.x < 100) { return false; }
         var m:Number = this.hzMargin;
         var s:Number = HZ_SCALE * this.hzHudScale;   // fallback size of unknown clips
         // v0.34: per-card factors (the default spots use each card's own size)
         var sJ:Number = this.hz34S("Jetpack");
         var sV:Number = this.hz34S("Vitals");
         var sP:Number = this.hz34S("Planet");
         var sA:Number = this.hz34S("Afflictions");
         var sE:Number = this.hz34S("Equipment");
         var sQ:Number = this.hz34S("Quests");
         var sCm:Number = this.hz34S("Compass");
         var sC:Number = this.hz34S("Compact");
         var left:Number = tl.x + m;
         var right:Number = br.x - m;
         var bottom:Number = br.y - m;
         var cx:Number = (tl.x + br.x) / 2;
         var eh:Number = this.hzPillOn() ? this.hzPpH : 128;
         var vh:Number = this.hzVitNew ? 98 : 128;
         this.hzPlace(this.HorizonEnv_mc,left,bottom - eh * sP);
         this.hzPlace(this.HorizonCard_mc,left,bottom - eh * sP - (10 + 56) * sJ);
         this.hzPlace(this.HorizonAffl_mc,left,bottom - eh * sP - (10 + 56) * sJ - (10 + 68) * sA);
         this.hzPlace(this.HorizonCompact_mc,left,bottom - 114 * sC);
         this.hzPlace(this.HorizonVitals_mc,cx - HZ_W * sV / 2 + this.hzVitOff,bottom - vh * sV);
         this.hzVitCX = cx;
         this.hzPlace(this.HorizonAmmo_mc,right - HZ_EQ_W * sE,bottom - 84 * sE);
         this.hzPlace(this.HorizonQuest_mc,right - HZ_W * sQ,tl.y + (br.y - tl.y) * 0.3);
         this.hzPlace(this.HorizonCompactQuest_mc,right - HZ_W * sQ,tl.y + (br.y - tl.y) * 0.3);
         this.hzPlace(this.HorizonCompass_mc,cx - HZ_CMP_W * sCm / 2,tl.y + this.hz27CmpTop());
         if(this.hzV19())
         {
            // v0.19 default spots (hud_layout_v1, 1920x1080, M = Margin): planet top-left, compass top-center,
            // quests top-right, jetpack / health / oxygen bottom-left, afflictions right of vitals, equipment bottom-right
            var top:Number = tl.y + m;
            try { this.hz31PpFit(left,cx,sP,sCm); } catch(err31:Error) { }
            this.hzPlace(this.HorizonEnv_mc,left,top);
            this.hzPlace(this.HorizonCompass_mc,cx - this.hzCmpW19 * sCm / 2,tl.y + this.hz27CmpTop());
            this.hzPlace(this.HorizonQuest_mc,right - HZ_Q19_W * sQ,top);
            this.hzPlace(this.HorizonCompactQuest_mc,right - HZ_CQ19_W * sQ,top);
            try { this.hz42VitApply(); } catch(err42:Error) { }   // v0.42.0: VitalsLayout (card size 330 x 124 or 668 x 58)
            var vy:Number = bottom - this.hz42VH() * sV;
            this.hzPlace(this.HorizonVitals_mc,left,vy);
            this.hzVitCX = NaN;
            this.hzVitOff = 0;
            this.hzPlace(this.HorizonCard_mc,left,vy - 8 * sV - this.hzJ19H * sJ);
            this.hzPlace(this.HorizonAffl_mc,left + (this.hz42VW() + 16) * sV,bottom - this.hzAfH * sA);
            this.hzPlace(this.HorizonCompact_mc,left,bottom - 114 * sC);
            var eqw:Number = this.hzE19Wd;
            var eqh:Number = this.hzE19H;
            this.hzPlace(this.HorizonAmmo_mc,right - eqw * sE,bottom - eqh * sE);
            try { this.hz26LayoutDefaults(left,top,cx,tl.y + this.hz27CmpTop(),sP); } catch(err26:Error) { }
         }
         try { this.hz31PxDefaults(tl,br); } catch(err31x:Error) { }
         // user layout (ARRANGE CARDS): normalized top-left in the visible rect, clamped on screen
         var vw:Number = br.x - tl.x;
         var vh:Number = br.y - tl.y;
         var li:int = 0;
         while(li < HZ_LAY_KEYS.length)
         {
            var lk:String = HZ_LAY_KEYS[li];
            var lo:Object = this.hzLay[lk];
            if(lo)
            {
               for each(var lc:Sprite in this.hzLayClips(lk))
               {
                  var cw:Number = this.hzCW(lc) > 1 ? this.hzCW(lc) : HZ_W * s;
                  var ch:Number = this.hzCH(lc) > 1 ? this.hzCH(lc) : 60 * s;
                  // v0.30: edge-anchored (offset from the margin line of the nearest edge, or from the center): every
                  // placed card moves with Screen Margin. Old 0-1 fractions are converted here once (same spot as v0.29).
                  var lpp:Point = this.hz30Resolve(lk,lo,cw,ch,tl,br);
                  this.hzPlace(lc,lpp.x,lpp.y);
               }
            }
            li++;
         }
         try { this.hz26LayoutAfter(this.hz34S("Character")); } catch(err26b:Error) { }
         return true;
      }

      private function hzPlace(c:Sprite, x:Number, y:Number) : void
      {
         if(!c) { return; }
         // v0.26: card origins on the device-pixel grid (ScreenHeight), whole units otherwise
         var pu:Number = this.hzScrH >= 360 ? 1080 / this.hzScrH : 1;
         x = Math.round(x / pu) * pu;
         y = Math.round(y / pu) * pu;
         c.x = x;
         c.y = y;
         for each(var e:Object in this.hzFades) { if(e.c == c) { e.base = y; } }
      }

      // HorizonUI.ini (Data/Interface/HorizonUI/HorizonUI.ini): key=value lines, ; comments.
      private function hzLoadIni() : void
      {
         // v0.37: HorizonUI.default.ini + HorizonUI.user.ini (legacy HorizonUI.ini as fallback), merged by the shared reader
         try { this.hz37Load(1); } catch(err:Error) { }
         try { this.hz30ModProbeAll(); } catch(errMod:Error) { }
      }

      private function hzOnIni(e:Event) : void
      {
         var src37:String = this.hz37Txt;   // v0.37: the merged text from the shared reader
         if(src37 == null) { return; }
         this.hz30IniRaw = src37;
         var lines:Array = src37.split("\r").join("").split("\n");
         try { lines = this.hz31OldFirst(lines); } catch(err31o:Error) { }
         try { this.hz31ParseIni(lines); } catch(err31p:Error) { }
         try { this.hz40ParseIni(lines); } catch(err40p:Error) { }
         for each(var ln:String in lines)
         {
            var sc:int = ln.indexOf(";");
            if(sc >= 0) { ln = ln.substr(0,sc); }
            var eq:int = ln.indexOf("=");
            if(eq <= 0) { continue; }
            var k:String = ln.substr(0,eq).replace(/\s/g,"").toLowerCase();
            var v:String = ln.substr(eq + 1).replace(/^\s+|\s+$/g,"");
            var bv:Boolean = v == "1" || v.toLowerCase() == "true";
            var nv:Number = Number(v);
            if(isNaN(nv) && this.hz30IniPos(k,v)) { continue; }
            switch(k)
            {
               case "showjetpack": this.hzShowJetpack = bv; break;
               case "jetpackautohide": this.hzJetpackAutoHide = bv; break;
               case "showvitals": this.hzShowVitals = bv; break;
               case "showplanet": this.hzShowPlanet = bv; break;
               case "showafflictions": this.hzShowAfflictions = bv; break;
               case "afflictionsautohide": this.hzAfflAutoHide = bv; break;
               case "showammo": this.hzShowAmmo = bv; break;
               case "ammoonlywhendrawn": this.hzAmmoOnlyWhenDrawn = bv; break;
               case "showquests": this.hzShowQuests = bv; break;
               case "showcompass": this.hzShowCompass = bv; break;
               case "vehicleexitpill": this.hzVehOn = bv; break;   // 0.42.0.7: [Cards], part of the HUD
               case "compassmarkers": this.hzShowCompassMarkers = bv; break;
               case "smoothbars": this.hzSmoothBars = bv; break;
               case "fadecards": this.hzFadeCards = bv; break;
               case "combatdim": this.hzCombatDim = bv; break;
               case "dimopacity": if(!isNaN(nv)) { this.hzDimAlpha = Math.max(0.1,Math.min(1,nv)); } break;
               case "cardopacity": if(!isNaN(nv)) { this.hzCardOpacity = Math.max(0.2,Math.min(1.6,nv)); } break;
               case "containeropacity": if(!isNaN(nv)) { this.hzContOpacity = Math.max(0.2,Math.min(1.6,nv)); this.hzT19Sig = ""; } break;
               case "texttone": if(!isNaN(nv)) { this.hzTextTone = Math.max(0,Math.min(2,int(nv))); } break;
               case "fontface": if(!isNaN(nv)) { this.hzFontFace = Math.max(0,Math.min(3,int(nv))); } break;
               case "timedisplay": if(!isNaN(nv)) { this.hzTimeDisplay = Math.max(0,Math.min(3,int(nv))); } break;
               case "clockformat": if(!isNaN(nv)) { this.hzClockFmt = Math.max(0,Math.min(1,int(nv))); } break;
               case "tempunit": if(!isNaN(nv)) { this.hzTempUnit = Math.max(0,Math.min(1,int(nv))); } break;
               case "afflictionlayout": if(!isNaN(nv)) { this.hzAfLayout = Math.max(0,Math.min(2,int(nv))); } break;
               case "planetdetails": this.hzPlanDetails = bv; break;
               case "showtarget": this.hzShowTarget = bv; break;
               case "targetanchor": if(!isNaN(nv)) { this.hzTgAnchor = Math.max(0,Math.min(1,int(nv))); } break;
               case "targetshowvalue": this.hzTgShowValue = bv; break;
               case "compact": this.hzCompact = bv; break;
               case "debug": this.hzDebug = bv; this.hzDbgShow(); this.hzDbgEnvSub(); break;
               case "hazardalert": this.hzHazardAlert = bv; break;
               case "accentcolor": if(!isNaN(nv)) { this.hzAccentChoice = Math.max(0,Math.min(HZ_ACCENTS.length,int(nv))); } break;
               case "magazinebar": this.hzMagBar = bv; this.hzDrawMag(); break;
               case "autocentervitals": this.hzAutoCenterVitals = bv; break;
               case "jetpackrule": this.hzRuleJetpack = this.hzRuleFix("JetpackRule",int(nv)); break;
               case "vitalsrule": this.hzRuleVitals = this.hzRuleFix("VitalsRule",int(nv)); break;
               case "planetrule": this.hzRulePlanet = this.hzRuleFix("PlanetRule",int(nv)); break;
               case "afflictionsrule": this.hzRuleAffl = this.hzRuleFix("AfflictionsRule",int(nv)); break;
               case "ammorule": this.hzRuleAmmo = this.hzRuleFix("AmmoRule",int(nv)); break;
               case "questsrule": this.hzRuleQuests = this.hzRuleFix("QuestsRule",int(nv)); break;
               case "compassrule": this.hzRuleCompass = this.hzRuleFix("CompassRule",int(nv)); break;
               case "rulesversion": this.hzRulesV2 = nv >= 2; break;
               case "accenthex": this.hzAccentHex = this.hzParseHex(v); break;
               case "cardhex": this.hzCardHex = this.hzParseHex(v); break;
               case "showfollowers": this.hzCmpFollowers = bv; break;
               case "showlocations": this.hzCmpLocations = bv; break;
               case "showship": this.hzCmpShip = bv; break;
               case "showenemies": this.hzCmpEnemies = bv; break;
               case "showplayermarker": this.hzCmpPlayerMark = bv; break;
               case "settingskey": if(v.length > 0) { this.hzSettingsKeyName = v; } break;
               case "cardcolor": if(!isNaN(nv)) { this.hzCardColor = Math.max(0,Math.min(HZ_CARDCOLS.length,int(nv))); } break;
               case "hudscale": if(!isNaN(nv)) { this.hzHudScale = Math.max(0.7,Math.min(1.4,nv)); this.hzApplyScale(); } break;
               case "textscale": if(!isNaN(nv)) { this.hzTextScale = Math.max(0.8,Math.min(1.3,nv)); this.hzApplyTypo(); } break;
               case "targetscale": if(!isNaN(nv)) { this.hzTgScaleLeg = nv; } break;   // pre-v0.26 key, migrated below
               case "containerscale": if(!isNaN(nv)) { this.hzTgScale = this.hz34ScClamp(nv); this.hzTgScaleSet = true; this.hzT19Sig = ""; } break;
               case "crosshairstyle": if(!isNaN(nv)) { this.hzXhStyle = Math.max(0,Math.min(3,int(nv))); this.hzXhSig = ""; } break;
               case "objectring": if(!isNaN(nv)) { this.hzObjRing = Math.max(0,Math.min(2,int(nv))); } break;
               case "screenheight": if(!isNaN(nv)) { this.hzScrH = nv >= 360 && nv <= 4320 ? int(nv) : 0; this.hzT19Sig = ""; } break;
               case "headerstyle": if(!isNaN(nv)) { this.hzHeaderStyle = Math.max(0,Math.min(1,int(nv))); this.hzApplyTypo(); } break;
               case "textshadow": this.hzTextShadow = bv; this.hzApplyTypo(); break;
               case "margin": if(!isNaN(nv)) { this.hzMargin = nv; this.hzLaidOut = false; } break;
               case "scopeholdbreathchip": case "scopechipx": case "scopechipy": case "scopechipscale": this.hz42ScIni(k,v,nv); break;   // v0.42.0 r2: [Scope]
               case "arrangebarx": if(!isNaN(nv) && !this.hzArrTbDrag) { this.hzArrTbDX = nv; } break;
               case "arrangebary": if(!isNaN(nv) && !this.hzArrTbDrag) { this.hzArrTbDY = nv; } break;
               default: if(!this.hz34Ini(k,nv) && !this.hz26Ini(k,bv,nv)) { this.hzIniLayoutKey(k,nv); } break;
            }
         }
         // v0.26 migration: TargetScale multiplied HudScale; ContainerScale is absolute -> keep the on-screen size
         if(!this.hzTgScaleSet && !isNaN(this.hzTgScaleLeg)) { this.hzTgScale = this.hz26SnapTgs(this.hzTgScaleLeg * this.hzHudScale); this.hzT19Sig = ""; }
         // v0.15 migration: old auto-hide toggles become the card's visibility rule (only for pre-v0.15 ini files)
         if(!this.hzRulesV2)
         {
            if(this.hzJetpackAutoHide && this.hzRuleJetpack == 0) { this.hzRuleJetpack = 4; }
            if(this.hzAfflAutoHide && this.hzRuleAffl == 0) { this.hzRuleAffl = 6; }
            if(this.hzAmmoOnlyWhenDrawn && this.hzRuleAmmo == 0) { this.hzRuleAmmo = 3; }
            if(!this.hzJetpackAutoHide && this.hzRuleJetpack == 4) { this.hzRuleJetpack = 0; }
            if(!this.hzAfflAutoHide && this.hzRuleAffl == 6) { this.hzRuleAffl = 0; }
            if(!this.hzAmmoOnlyWhenDrawn && this.hzRuleAmmo == 3) { this.hzRuleAmmo = 0; }
            this.hzRulesV2 = true;
         }
         this.hzApplyAccentLive();
         this.hzRedrawBodies();
         this.hzApplyTypo();
         if(this.hzEqKind.length > 0) { this.hzEqDrawWeapIcon(this.hzEqKind); }
         this.hzEqDrawAmmoIcon();
         this.hz26ChSig = "";
         this.hzApplyScale();   // v0.34: per-card sizes
         this.hzLaidOut = false;
         this.hzRefreshVisibility();
      }

      // Accent change after build: recolor the accent-colored header texts/bars on next updates.
      private function hzApplyAccentLive() : void
      {
         var old:uint = HZ_ACCENT;
         this.HZ_ACCENT = this.hzAccentOf(this.hzAccentChoice);
         for each(var o:Object in this.hzTexts) { if(o.col == old) { o.col = HZ_ACCENT; } }
         this.hzApplyTypo();
         for each(var e:Object in this.hzBars) { if(e.col == old) { e.col = HZ_ACCENT; } }
         for each(var ic35:Object in this.hzIcons) { if(ic35.acc) { ic35.c = HZ_ACCENT; try { this.hzIconDraw(Sprite(ic35.s),String(ic35.k),HZ_ACCENT); } catch(eIc:Error) { } } }   // v0.35 vitals icons
         var tint:ColorTransform = new ColorTransform();
         for each(var c:Sprite in [this.HorizonCard_mc,this.HorizonVitals_mc,this.HorizonEnv_mc,this.HorizonAffl_mc,this.HorizonAmmo_mc,this.HorizonQuest_mc,this.HorizonCompass_mc])
         {
            if(c) { c.transform.colorTransform = tint; }
         }
         if(this.hzEqKind.length > 0) { this.hzEqDrawWeapIcon(this.hzEqKind); }
         this.hzEqDrawAmmoIcon();
         this.hzRedrawDividers();
         this.hzV19Redraw();
      }

      private function hzBuild() : void
      {
         this.HZ_ACCENT = this.hzAccentOf(this.hzAccentChoice);
         var bw:Number = HZ_W - 32;
         // Jetpack card: header [art] JETPACK (BOOST) ... 100% (dot), slim bar tile
         this.HorizonCard_mc = new Sprite();
         this.hzDotJet = this.hzCard(this.HorizonCard_mc,HZ_W,56,null,null);
         this.hzJetIcon(this.HorizonCard_mc,10,7);
         try
         {
            var art:Sprite = this.hzBoostVector(24);
            art.x = 6; art.y = 2;
            this.HorizonCard_mc.addChild(art);
            this.hzJetIconVec.visible = false;
         }
         catch(err:Error)
         {
         }
         this.hzText(this.HorizonCard_mc,"JETPACK (BOOST)",34,7,150,12,HZ_LABEL,false,"hdr");
         this.hzJetPct = this.hzText(this.HorizonCard_mc,"100%",HZ_W - 98,4,72,15,HZ_VALUE,true,"val");
         this.hzTile(this.HorizonCard_mc,8,HZ_HDR + 6,HZ_W - 16,16);
         this.hzJetBar = new Sprite(); this.hzJetBar.x = 16; this.hzJetBar.y = HZ_HDR + 12;
         this.HorizonCard_mc.addChild(this.hzJetBar);
         this.hzMeter(this.hzJetBar,bw,1,HZ_ACCENT);
         this.hzBuildJet19();
         // Vitals card: header + two tiles
         this.HorizonVitals_mc = new Sprite();
         this.hzVitOld = new Sprite();
         this.HorizonVitals_mc.addChild(this.hzVitOld);
         this.hzDotVit = this.hzCard(this.hzVitOld,HZ_W,128,"vitals","VITALS");
         this.hzTile(this.hzVitOld,8,HZ_HDR + 6,HZ_W - 16,42);
         this.hzIcon(this.hzVitOld,"heart",16,HZ_HDR + 12,HZ_ACCENT); this.hzIcons[this.hzIcons.length - 1].acc = true;
         this.hzVitHpLbl = this.hzText(this.hzVitOld,"HEALTH",33,HZ_HDR + 10,100,10,HZ_ACCENT,false,"lbl",true);
         this.hzVitHp = this.hzText(this.hzVitOld,"--",HZ_W - 128,HZ_HDR + 7,112,15,HZ_VALUE,true,"val");
         this.hzVitHpBar = new Sprite(); this.hzVitHpBar.x = 16; this.hzVitHpBar.y = HZ_HDR + 34;
         this.hzVitOld.addChild(this.hzVitHpBar);
         this.hzTile(this.hzVitOld,8,HZ_HDR + 52,HZ_W - 16,42);
         this.hzIcon(this.hzVitOld,"o2",16,HZ_HDR + 58,HZ_ACCENT); this.hzIcons[this.hzIcons.length - 1].acc = true;
         this.hzVitO2Lbl = this.hzText(this.hzVitOld,"OXYGEN",33,HZ_HDR + 56,100,10,HZ_ACCENT,false,"lbl",true);
         this.hzVitO2 = this.hzText(this.hzVitOld,"--",HZ_W - 128,HZ_HDR + 53,112,15,HZ_VALUE,true,"val");
         this.hzVitO2Bar = new Sprite(); this.hzVitO2Bar.x = 16; this.hzVitO2Bar.y = HZ_HDR + 80;
         this.hzVitOld.addChild(this.hzVitO2Bar);
         this.hzVitBg = new Sprite();
         this.hzVitOld.addChild(this.hzVitBg);
         bw = HZ_W - 32;
         this.hzMeter(this.hzVitHpBar,bw,1,HZ_GREEN);
         this.hzMeter(this.hzVitO2Bar,bw,1,HZ_ACCENT);
         this.hzBuildVitNew();
         this.HorizonVitals_mc.scaleX = this.HorizonVitals_mc.scaleY = HZ_SCALE;
         this.HorizonCard_mc.scaleX = this.HorizonCard_mc.scaleY = HZ_SCALE;
         this.HorizonVitals_mc.x = 960 - HZ_W * HZ_SCALE / 2;
         this.HorizonVitals_mc.y = 746 - 128 * HZ_SCALE;
         this.HorizonCard_mc.x = 80;
         this.HorizonCard_mc.y = 746 - (128 + 10 + 56) * HZ_SCALE;
         addChild(this.HorizonVitals_mc);
         addChild(this.HorizonCard_mc);
         this.hzBuildCompass();
         this.hzBuildEnv();
         this.hzBuildQuest();
         this.hzBuildTarget();
         this.hzFixFonts();
         BSUIDataManager.Subscribe("HudJetpackData",this.hzOnJetpack);
         BSUIDataManager.Subscribe("PlayerFrequentData",this.hzOnPlayerFrequent);
         BSUIDataManager.Subscribe("PlayerData",this.hzOnPlayerData);
         BSUIDataManager.Subscribe("HudCrosshairData",this.hzOnCrosshair);
         try { BSUIDataManager.Subscribe("HUDVehicleData",this.hz42VehOnData); } catch(e42vs:Error) { }
         try { BSUIDataManager.Subscribe("ControlMapData",this.hz42VehOnMap); } catch(e42vm:Error) { }
         try { this.hz26Build(); } catch(err26:Error) { }
         try { this.hz40Init(); } catch(err40:Error) { }
         this.hzLoadIni();
         this.hzBuildCompact();
         addEventListener(Event.ENTER_FRAME,this.hzOnFrame);
         this.hzRefreshVisibility();
      }

      private function hzOnJetpack(e:FromClientDataEvent) : *
      {
         var c:Number = Number(e.data.fJetpackCharge);
         if(isNaN(c)) { return; }
         this.hzFixFonts();
         this.hzJetCharge = c;
         var f:Number = c < 0 ? 1 : Math.max(0,Math.min(1,c));
         this.hzJetPct.text = Math.round(f * 100) + "%";
         if(this.hzCJet) { this.hzCJet.text = Math.round(f * 100) + "%"; this.hzMeter(this.hzCJetBar,80,f,f < 0.25 ? HZ_RED : HZ_ACCENT); }
         this.hzMeter(this.hzJetBar,HZ_W - 32,f,f < 0.25 ? HZ_RED : HZ_ACCENT);
         this.hzDot(this.hzDotJet,f < 0.25 ? HZ_RED : (f < 0.5 ? HZ_YELLOW : HZ_GREEN));
         this.hzJetTrack(c);
         this.hzRefreshVisibility();
      }

      private function hzOnPlayerFrequent(e:FromClientDataEvent) : *
      {
         try { this.hz36HideTick(); } catch(e36q:Error) { }   // v0.36: the game re-shows HealthBarGhost_mc on these updates (heal)
         var d:Object = e.data;
         this.hzFixFonts();
         var hp:Number = Number(d.fHealth);
         var mhp:Number = Number(d.fMaxHealth);
         if(!isNaN(hp) && mhp > 0)
         {
            this.hzVitHp.text = Math.round(hp) + " / " + Math.round(mhp);
            var hf:Number = hp / mhp;
            this.hzVitHpF = hf;
            var hc:uint = hf <= 0.3 ? HZ_RED : (hf <= 0.6 ? HZ_YELLOW : HZ_GREEN);
            this.hzMeter(this.hzVitHpBar,HZ_W - 32,hf,hc);
            if(this.hzVnHp) { this.hzVnHp.text = Math.round(hp) + " / " + Math.round(mhp); this.hzMeter(this.hzVnHpBar,HZ_VN_W - 28,hf,this.hz26WarnCol(hf,HZ_GREEN)); this.hzTxtTint(this.hzVnHp,hf < 0.35 ? this.hz26WarnCol(hf,HZ_GREEN) : null); this.hz26VnWarn(0,hf); }
            if(this.hzCHp) { this.hzCHp.text = Math.round(hp) + " / " + Math.round(mhp); this.hzMeter(this.hzCHpBar,80,hf,hc); }
            this.hzDot(this.hzDotVit,hc);
            this.hzLowHealth = hf <= 0.3 && hp > 0;
            if(!this.hzLowHealth) { this.hzDrawVitBg(0); }
         }
         var o2:Number = Number(d.fOxygen);
         var mo2:Number = Number(d.fMaxO2CO2);
         if(!isNaN(o2) && mo2 > 0)
         {
            this.hzVitO2.text = Math.round(o2 / mo2 * 100) + "%";
            if(this.hzVnO2) { this.hzVnO2.text = Math.round(o2 / mo2 * 100) + "%"; this.hzMeter(this.hzVnO2Bar,HZ_VN_W - 28,o2 / mo2,this.hz26WarnCol(o2 / mo2,HZ_O2_BLUE)); this.hzTxtTint(this.hzVnO2,o2 / mo2 < 0.35 ? this.hz26WarnCol(o2 / mo2,HZ_O2_BLUE) : null); this.hz26VnWarn(1,o2 / mo2); }
            this.hzMeter(this.hzVitO2Bar,HZ_W - 32,o2 / mo2,o2 / mo2 < 0.25 ? 0xF2735F : HZ_ACCENT);
            if(this.hzCO2) { this.hzCO2.text = Math.round(o2 / mo2 * 100) + "%"; this.hzMeter(this.hzCO2Bar,80,o2 / mo2,o2 / mo2 < 0.25 ? HZ_RED : HZ_ACCENT); }
         }
         if(!isNaN(o2) && mo2 > 0) { this.hzVitO2F = o2 / mo2; }
         if(this.hzRuleVitals == 5) { this.hzRefreshVisibility(); }
         this.hzVitHp.visible = this.hzVitHpLbl.visible = this.hzVitHpBar.visible = this.hzShowHealth;
         this.hzVitO2.visible = this.hzVitO2Lbl.visible = this.hzVitO2Bar.visible = this.hzShowOxygen;
      }

      private var hzPlugActive:Boolean = false;
      private var hzPlugDrawn:Boolean = false;
      public function hzSetWeaponDrawn(drawn:Boolean) : void
      {
         var changed:Boolean = !this.hzPlugActive || this.hzPlugDrawn != drawn;
         this.hzPlugActive = true;
         this.hzPlugDrawn = drawn;
         if(changed)
         {
            this.hzRefreshVisibility();
         }
      }
      public function hzSetAmmoType(name:String) : void
      {
         if(this.hzAmmoType)
         {
            this.hzAmmoType.text = name && name.length > 0 ? name.toUpperCase() : "--";
         }
         this.hzEqSync();
      }
      private var hzCrossType:Number = -1;
      public var hzDebug:Boolean = false;
      private var hzDbgCross:String = "";
      private var hzDbgWeap:String = "";
      private var hzDbgText:TextField = null;
      private function hzDump(o:Object) : String
      {
         var out:String = "";
         for(var k:String in o)
         {
            var v:* = o[k];
            if(v is Array) { out += k + "=[" + (v as Array).length + "] "; }
            else if(v is Object && !(v is String) && !(v is Number) && !(v is Boolean)) { out += k + "={} "; }
            else { out += k + "=" + v + " "; }
         }
         return out;
      }
      private function hzDbgShow() : void
      {
         if(!this.hzDebug)
         {
            if(this.hzDbgText) { this.hzDbgText.visible = false; }
            return;
         }
         if(!this.hzDbgText)
         {
            this.hzDbgText = new TextField();
            this.hzDbgText.multiline = true;
            this.hzDbgText.wordWrap = true;
            this.hzDbgText.width = 900;
            this.hzDbgText.height = 760;
            this.hzDbgText.x = 40;
            this.hzDbgText.y = 120;
            this.hzDbgText.selectable = false;
            this.hzDbgText.mouseEnabled = false;
            this.hzDbgText.embedFonts = true;
            addChild(this.hzDbgText);
         }
         var vr:Rectangle = Extensions.visibleRect;
         if(vr != null && vr.width >= 100 && stage != null)
         {
            var tl:Point = globalToLocal(new Point(vr.left,vr.top));
            if(!isNaN(tl.x)) { this.hzDbgText.x = tl.x + 40; this.hzDbgText.y = tl.y + 120; }
         }
         var df:TextFormat = new TextFormat(this.hzFont ? this.hzFont : "$MAIN_Font",14,0xFFFF66);
         this.hzDbgText.defaultTextFormat = df;
         this.hzDbgText.visible = true;
         this.hzDbgText.text = "CROSSHAIR: " + this.hzDbgCross + "\n\nWEAPON: " + this.hzDbgWeap + "\n\nCOMPASS (array:type x count): " + this.hzDbgCmp + "\n\nENV KEYS:\n" + this.hzDbgEnv + "\n\nV0.26 PROVIDERS:\n" + this.hz26DbgText();
         this.hzDbgText.setTextFormat(df);
         this.hzDbgText.textColor = 0xFFFF66;
      }
      private var hzQTitle:TextField = null;
      public function hzSetQuestTitle(name:String) : void
      {
         if(String(name != null ? name : "").toLowerCase() != String(this.hzQName != null ? this.hzQName : "").toLowerCase()) { this.hz27QMain = ""; this.hz27QObjs = []; this.hz27QSubs = []; }
         if(this.hzQTitle)
         {
            this.hzQTitle.text = name && name.length > 0 ? name.toUpperCase() : "ACTIVE OBJECTIVE";
         }
         this.hzQName = name != null ? name : "";
         this.hzQSync();
      }
      private function hzOnQuestData(e:FromClientDataEvent) : *
      {
         var qs:Array = e.data ? e.data.aQuests as Array : null;
         var name:String = "";
         if(qs)
         {
            for(var i:int = 0; i < qs.length; i++)
            {
               if(qs[i] && qs[i].bActive === true && qs[i].sName)
               {
                  name = String(qs[i].sName);
                  break;
               }
            }
         }
         if(name.length > 0) { this.hzSetQuestTitle(name); }
      }
      private var hzWeapName:String = "";
      private var hzInvItems:Array = null;
      private function hzOnQuestUpdate(e:FromClientDataEvent) : *
      {
         var a:Array = e.data ? e.data.QuestUpdatesA as Array : null;
         if(!a) { return; }
         for(var i:int = a.length - 1; i >= 0; i--)
         {
            var q:Object = a[i];
            if(q && q.bActiveQuest === true && q.strQuestName && q.bCompleted !== true && q.bFailed !== true)
            {
               this.hzSetQuestTitle(String(q.strQuestName));
               try { this.hz27QSetObjs(q); } catch(errO:Error) { }
               return;
            }
         }
      }
      private function hzOnInventory(e:FromClientDataEvent) : *
      {
         this.hzInvItems = e.data ? e.data.aItems as Array : null;
         this.hzResolveAmmoType();
         this.hzDrawMag();
      }
      private function hzFindAmmo(o:Object, depth:int) : String
      {
         if(o == null || depth > 2) { return null; }
         if(o.sAmmoType != null && String(o.sAmmoType).length > 0) { return String(o.sAmmoType); }
         for(var k:String in o)
         {
            var v:* = o[k];
            if(v != null && typeof v == "object")
            {
               var r:String = this.hzFindAmmo(v,depth + 1);
               if(r != null) { return r; }
            }
         }
         return null;
      }
      private function hzFindNum(o:Object, key:String, depth:int) : Number
      {
         if(o == null || depth > 2) { return NaN; }
         if(o[key] != undefined && !isNaN(Number(o[key]))) { return Number(o[key]); }
         for(var k:String in o)
         {
            var v:* = o[k];
            if(v != null && typeof v == "object")
            {
               var r:Number = this.hzFindNum(v,key,depth + 1);
               if(!isNaN(r)) { return r; }
            }
         }
         return NaN;
      }

      // Magazine fullness bar under the ammo count (accent, amber < 30%, red < 10%).
      private function hzDrawMag() : void
      {
         this.hzEqDrawTicks();
         if(!this.hzMagSp) { return; }
         var g:* = this.hzMagSp.graphics;
         g.clear();
         var cap:Number = this.hzMagCap > 0 ? this.hzMagCap : this.hzMagMax;
         this.hzMagSp.visible = this.hzMagBar && cap > 0 && this.hzMagClip >= 0;
         if(!this.hzMagSp.visible) { return; }
         var f:Number = Math.max(0,Math.min(1,this.hzMagClip / cap));
         var col:uint = f < 0.1 ? HZ_RED : (f < 0.3 ? 0xF2B45F : HZ_ACCENT);
         var w:Number = 68;
         g.beginFill(0x050C12,0.7);
         g.drawRoundRect(0,0,w,3,3,3);
         g.endFill();
         if(f > 0)
         {
            g.beginFill(col,0.95);
            g.drawRoundRect(0,0,Math.max(2,w * f),3,3,3);
            g.endFill();
         }
      }

      private function hzWeaponOut() : Boolean
      {
         return this.hzPlugActive ? this.hzPlugDrawn : (this.hzAmmoDrawn && this.hzCrossOn && this.hzCrossType != 2);
      }

      private function hzRuleFix(key:String, v:int) : int
      {
         var allowed:Object = {"JetpackRule":[0,4,1,2],"VitalsRule":[0,5,1,2],"PlanetRule":[0,1,2],"AfflictionsRule":[0,6,1,2],"AmmoRule":[0,3,1,2],"QuestsRule":[0,1,2],"CompassRule":[0,1,2],"CharacterRule":[0,7,8,9,1,2]};
         var a:Array = allowed[key] as Array;
         return (a && a.indexOf(v) >= 0) ? v : 0;
      }

      // One visibility rule per card (see HZ_RULE_NAMES).
      private function hzRuleOk(rule:int) : Boolean
      {
         switch(rule)
         {
            case 1: return this.hzInCombat;
            case 2: return !this.hzInShip;
            case 3: return this.hzWeaponOut();
            case 4: return this.hzJetCharge >= 0 && this.hzJetCharge < 0.999;
            case 5: return this.hzVitHpF < 0.995 || this.hzVitO2F < 0.995;
            case 6: return this.hzAfflCount > 0;
         }
         return true;
      }

      // Vitals: exact center when the Equipment card is hidden, slightly left of center while it is shown (smooth slide).
      private function hzTickVitals() : void
      {
         if(!this.HorizonVitals_mc || isNaN(this.hzVitCX) || this.hzV19()) { return; }
         if(this.hzLayHas("Vitals")) { return; } // user placed the vitals card: no auto-center
         var s:Number = this.hz34S("Vitals");
         var ammoOn:Boolean = false;
         for each(var e:Object in this.hzFades) { if(e.c == this.HorizonAmmo_mc) { ammoOn = e.t > 0.5; } }
         var t:Number = (this.hzAutoCenterVitals && ammoOn) ? -110 * s : 0;
         var d:Number = t - this.hzVitOff;
         this.hzVitOff = Math.abs(d) < 0.5 ? t : this.hzVitOff + d * 0.15;
         this.HorizonVitals_mc.x = this.hzVitCX - HZ_W * s / 2 + this.hzVitOff;
      }

      private function hzResolveAmmoType() : void
      {
         if(!this.hzInvItems) { return; }
         var fallback:String = null;
         for(var i:int = 0; i < this.hzInvItems.length; i++)
         {
            var it:Object = this.hzInvItems[i];
            if(!it || it.bIsEquipped !== true) { continue; }
            var t:String = this.hzFindAmmo(it,0);
            if(t == null) { continue; }
            var nm:String = it.sName != null ? String(it.sName) : "";
            if(this.hzWeapName.length == 0 && nm.length > 0) { this.hzInvWeapName = nm; }
            if(this.hzWeapName.length > 0 && nm.indexOf(this.hzWeapName) == 0)
            {
               var cap:Number = this.hzFindNum(it,"uAmmoCapacity",0);
               if(cap > 0) { this.hzMagCap = cap; }
               this.hzSetAmmoType(t);
               return;
            }
            if(fallback == null) { fallback = t; }
         }
         this.hzSetAmmoType(fallback != null ? fallback : "");
      }
      public var hzUserHidden:Boolean = false;
      public function hzToggleAll() : void
      {
         this.hzUserHidden = !this.hzUserHidden;
         if(this.HorizonCompass_mc)
         {
            this.HorizonCompass_mc.visible = !this.hzUserHidden && this.hzShowCompass;
         }
         this.hzRefreshVisibility();
      }
      public function hzRefreshVisibility() : void
      {
         try { this.hzCmpApplyCompact(); } catch(errCc:Error) { }
         try { if(this.hzPlanPill && this.hzPpC != (this.hz34C("Planet") ? 1 : 0)) { this.hzPpLayout(); } } catch(errPc:Error) { }
         try { if(this.hzEq19 && this.hz34C("Equipment") != this.hzE19Cm) { this.hzE19Sync(); } } catch(errEc:Error) { }
         var base:Boolean = this.hzGroupVisible && !this.hzUserHidden;
         var cardBase:Boolean = base && !this.hz40Hide;   // v0.40: the cards only; combat feedback keeps base
         var full:Boolean = !this.hzCompact && cardBase;
         var vitBase:Boolean = base && !this.hz40Hide;   // v0.41.0: the HUD vitals cards hide too; hz41V draws the kept vitals
         var vitFull:Boolean = !this.hzCompact && vitBase;
         if(this.hzArrange) { this.hzArrShowAll(); return; }
         if(this.HorizonCard_mc) { this.hzShow(this.HorizonCard_mc,vitFull && this.hzShowJetpack && this.hzRuleOk(this.hzRuleJetpack)); }
         if(this.HorizonVitals_mc) { this.hzShow(this.HorizonVitals_mc,vitFull && this.hzShowVitals && this.hzRuleOk(this.hzRuleVitals)); }
         // planet pill is compact-friendly: also shown in compact mode
         if(this.HorizonEnv_mc) { this.hzShow(this.HorizonEnv_mc,(this.hzPillOn() ? cardBase : full) && this.hzShowPlanet && this.hzRuleOk(this.hzRulePlanet)); }
         if(this.HorizonAffl_mc) { this.hzShow(this.HorizonAffl_mc,full && this.hzShowAfflictions && this.hzRuleOk(this.hzRuleAffl)); }
         if(this.HorizonQuest_mc) { this.hzShow(this.HorizonQuest_mc,!this.hz34C("Quests") && cardBase && this.hzShowQuests && this.hzRuleOk(this.hzRuleQuests)); }
         if(this.HorizonCompactQuest_mc) { this.hzShow(this.HorizonCompactQuest_mc,this.hz34C("Quests") && cardBase && this.hzShowQuests && this.hzRuleOk(this.hzRuleQuests)); }
         // the Equipment card also shows in compact mode (layout C); the old compact ammo strip stays hidden
         if(this.HorizonAmmo_mc) { this.hzShow(this.HorizonAmmo_mc,cardBase && this.hzShowAmmo && this.hzRuleOk(this.hzRuleAmmo)); }
         for each(var cr:DisplayObject in this.hzCAmmoRow) { cr.visible = false; }
         if(this.HorizonCompact_mc) { this.hzShow(this.HorizonCompact_mc,this.hzCompact && vitBase); }
         if(this.HorizonCompass_mc) { this.hzShow(this.HorizonCompass_mc,cardBase && this.hzShowCompass && this.hzRuleOk(this.hzRuleCompass)); }
         try { this.hz26Vis(base); } catch(err26:Error) { }
      }

      // Fade + slide cards in/out; dim to hzDimAlpha out of combat.
      private function hzShow(c:Sprite, on:Boolean) : void
      {
         var e:Object = null;
         for each(var o:Object in this.hzFades) { if(o.c == c) { e = o; break; } }
         if(e == null)
         {
            e = {"c":c,"base":c.y,"s":(on ? 1 : 0),"t":(on ? 1 : 0)};
            this.hzFades.push(e);
         }
         e.t = on ? 1 : 0;
         if(!this.hzFadeCards) { e.s = e.t; }
      }

      private function hzTickFades() : void
      {
         var mul:Number = (this.hzCombatDim && !this.hzInCombat && !this.hzLowHealth) ? this.hzDimAlpha : 1;
         if(this.hzV19() && mul < 1) { mul = 1 - (1 - mul) * 0.4; } // v0.19: DimOpacity 0.6 -> 0.84, cards stay solid like the mockup
         for each(var e:Object in this.hzFades)
         {
            var d:Number = e.t - e.s;
            if(Math.abs(d) > 0.01) { e.s += d * 0.2; } else { e.s = e.t; }
            if(e.m == undefined) { e.m = mul; }
            e.m += (mul - e.m) * 0.08;
            var c:Sprite = e.c;
            c.visible = (this.hzLaidOut || this.hzLayEver) && e.s > 0.02; // v0.26: cards stay up while a relayout is pending
            c.alpha = e.s * e.m; // CardOpacity is applied to panel fills only (hzPanelA), text stays solid
            c.y = e.base + (1 - e.s) * 10;
         }
      }

      private function hzFindByName(c:DisplayObjectContainer, n:String, depth:int) : DisplayObject
      {
         var i:int = 0;
         var ch:DisplayObject = null;
         var r:DisplayObject = null;
         if(depth > 8) { return null; }
         while(i < c.numChildren)
         {
            ch = c.getChildAt(i);
            if(ch && ch.name == n) { return ch; }
            if(ch is DisplayObjectContainer && ch != this.HorizonCard_mc && ch != this.HorizonVitals_mc && ch != this.HorizonEnv_mc && ch != this.HorizonCompass_mc && ch != this.HorizonAffl_mc && ch != this.HorizonAmmo_mc && ch != this.HorizonQuest_mc && ch != this.HorizonCompact_mc && ch != this.HorizonCompactQuest_mc && ch != this.HorizonSettings_mc)
            {
               r = this.hzFindByName(DisplayObjectContainer(ch),n,depth + 1);
               if(r) { return r; }
            }
            i++;
         }
         return null;
      }

      // Screen-only hide of vanilla clips Horizon replaces. Never removeChild; files untouched.
      private function hzOnFrame(e:Event) : void
      {
         var names:Array = [];
         var o:Object = null;
         this.hzFrameN++;
         try { this.hz42VehTick(); } catch(e42v:Error) { }   // 0.42.0.7: own try, first, so a throw later in this frame cannot skip the exit pill
         try { this.hz40Frame(); } catch(e40f:Error) { }
         try { this.hz42QmFont(); } catch(e42q:Error) { }   // v0.40.2: in-world quest-marker labels in the Horizon face
         try { this.hz35CmpTick(); } catch(e35c:Error) { }   // v0.35: global Compact follow
         if(this.hzHideCache == null || this.hzFrameN % 90 == 1 || this.hz36HideStale)
         {
            this.hzHideTries++;
            this.hzHideCache = [];
            this.hz36HideStale = false;
            if(this.hzHideVanillaBoost) { names.push("JetpackMeterWrapper_mc","JetpackMeterAnim_mc"); }
            if(this.hzHideVanillaCompass) { names.push("WatchOutline_mc","WatchPointerOutline_mc","WatchIconsWidget_mc","MissionIconsWidget_mc","EnemyIconsWidget_mc","DayCycleBase_mc","locationNameBase_mc","Temperature_mc","Oxygen_mc","Grav_mc","OffPlanet_mc"); }
            if(this.hzHideVanillaWatch) { names.push("O2CO2_mc","O2CO2thin_mc","WatchOutline_mc","WatchPointerOutline_mc","BioCondition_mc","BioConditionBase_mc","EnvCondition_mc","EnvConditionBase_mc","BioAlertBG_mc"); }
            if(this.hzHideVanillaAmmo) { names.push("EquippedWeaponAmmo_mc","EquippedWeaponAmmoTotal_mc","VerticalDivider_mc","EquippedWeaponIconHolder_mc"); }
            if(this.hzHideVanillaHealth) { names.push("HealthBar_mc","HealthBarEmpty_mc","HealthBarGhost_mc","HealthBarDamage_mc","HealthBarIncrease_mc","Health_mc"); }
            for each(var n:String in names)
            {
               try { this.hz36HideFind(this,n,this.hzHideCache); } catch(e36f:Error) { }   // v0.36: parent + name kept
            }
         }
         try { this.hz36HideTick(); } catch(e36a:Error) { }   // v0.36: hide first, so a throw below can't skip it
         if(this.hz40Hide) { try { this.hz40ForceHide(); } catch(e40a:Error) { } }
         if(this.hzHideVanillaWatch)
         {
            if(this.hzBlg == null && this.hzFrameN % 30 == 1)
            {
               this.hzBlg = this.hzFindByName(this,"BottomLeftGroup_mc",0) as DisplayObjectContainer;
            }
            if(this.hzBlg)
            {
               var bi:int = 0;
               while(bi < this.hzBlg.numChildren)
               {
                  var bc:DisplayObject = this.hzBlg.getChildAt(bi);
                  if(bc && bc.visible && bc.name != "EnemyDetectionAnim_mc" && bc.name != "Autopilot_mc" && bc.name != "EnvAlertText" && bc.name != "BioAlertText" && bc.name != "LocationAlertText")
                  {
                     bc.visible = false;
                  }
                  bi++;
               }
            }
         }
         // v0.26: after the first good layout a pending relayout runs on the very next frame (was: every 15th frame, cards hidden meanwhile)
         if(!this.hzLaidOut && (this.hzLayEver || this.hzFrameN % 15 == 2)) { this.hzLaidOut = this.hzLayout(); if(this.hzLaidOut) { this.hzLayEver = true; } }
         if(this.hzFrameN % 15 == 7) { try { this.hzTypoGuard(); } catch(e36g:Error) { } }
         try { this.hzEqTick(); } catch(e36e:Error) { }
         if(this.hz30ModT0 > 0) { try { this.hz30ModTick(); } catch(errMt:Error) { this.hz30ModT0 = 0; } }
         if(this.hzFrameN % 30 == 11) { try { this.hzPpClock(); } catch(errClk:Error) { } }
         if(this.hzFontFace >= 1 && this.hzFontFace <= 3 && this.hzFontRetry < 6 && this.hzFrameN % 300 == 150 && (this.hzFontFace == 3 || this.hz30Mod["font"] === 1))
         {
            // fontlibs can register late: re-probe faces that failed (a few times in the first ~60 s)
            var fbefore:String = this.hzFontName() + this.hzFontName("rg") + this.hzFontName("bd");
            var fbad:Boolean = false;
            for(var fk:String in this.hzFontOkMap) { if(this.hzFontOkMap[fk] != 1) { delete this.hzFontOkMap[fk]; fbad = true; } }
            if(fbad) { this.hzFontRetry++; if(this.hzFontName() + this.hzFontName("rg") + this.hzFontName("bd") != fbefore) { this.hzApplyTypo(); } else { try { this.hzAfRetryLayout(); } catch(errAf:Error) { } } }
            else { this.hzFontRetry = 6; }
         }
         try { this.hzTgTick(); } catch(errTg:Error) { try { this.hzTgRestore(); this.HorizonTarget_mc.visible = false; } catch(errTg2:Error) { } }
         try { this.hzXhTick(); } catch(errXh:Error) { try { this.hzXhRestore(); if(this.hzXh) { this.hzXh.visible = false; } } catch(errXh2:Error) { } }
         try { this.hzTickBars(); } catch(e36b:Error) { }
         try { this.hzTickFades(); } catch(e36d:Error) { }
         try { this.hzTickVitals(); } catch(e36v:Error) { }
         try { this.hz26Tick(); } catch(err26:Error) { }
         try { this.hzAfLoadWatch(); } catch(errAfW:Error) { }
         if(this.hzPlanAlertOn)
         {
            this.hzPlanPulse += 0.07;
            var pa:Number = 0.5 + 0.5 * Math.sin(this.hzPlanPulse);
            this.hzPlanAlert.graphics.clear();
            this.hzPlanAlert.graphics.lineStyle(1.5 + pa,0xF2A03F,0.35 + 0.6 * pa);
            this.hzPlanAlert.graphics.beginFill(0xF2A03F,0.004); this.hzPlanAlert.graphics.drawRoundRect(0,0,HZ_W,128,18,18); this.hzPlanAlert.graphics.endFill();   // v0.40.3: closes the path
         }
         if(this.hzLowHealth)
         {
            this.hzPulseT += 0.08;
            this.hzDrawVitBg(0.5 + 0.5 * Math.sin(this.hzPulseT));
         }
         try { this.hz36HideTick(); } catch(e36z:Error) { }   // v0.36: and again after everything else this frame
         if(this.hz40Hide) { try { this.hz40ForceHide(); } catch(e40z:Error) { } }
      }

      // 0.42.0.7: vehicle exit pill, part of the main HUD (not its own movie). Same keycap and pill language as the
      // scope hold-breath chip: the key the game is showing, then EXIT. The sweep is HoldAnim_mc from StartHold to
      // buttonHoldComplete. The pill turns green with a check when that hold completes. The game's button stays in the movie.
      private var hzVehOn:Boolean = true;
      private var hzVehPx:Sprite = null;
      private var hzVehSig:String = "";
      private var hzVehIn:int = -1;       // HUDVehicleData.bInVehicle: -1 unknown, 0 out, 1 in
      private var hzVehPad:int = -1;      // ControlMapData.uiController: -1 unknown, 0 keyboard, 1 controller
      private var hzVehHid:Boolean = false;
      private var hzVehAlpha:Number = 1;
      private var hzVehW:Number = 0;
      private var hzVehH:Number = 42;
      private var hzVehFail:int = 0;
      private function hz42VehOnData(e:FromClientDataEvent) : void
      {
         try
         {
            if(e == null || e.data == null || e.data.bInVehicle == undefined) { return; }
            this.hzVehIn = Boolean(e.data.bInVehicle) ? 1 : 0;
         }
         catch(err:Error) { }
      }
      private function hz42VehOnMap(e:FromClientDataEvent) : void
      {
         try
         {
            if(e == null || e.data == null || e.data.uiController == undefined) { return; }
            this.hzVehPad = uint(e.data.uiController) > 0 ? 1 : 0;
         }
         catch(err:Error) { }
      }
      private function hz42VehBtn() : *
      {
         try
         {
            var rm:* = this["RightMeters_mc"];
            if(rm == null) { return null; }
            var hv:* = rm.HUDVehicle_mc;
            if(hv == null) { return null; }
            return hv.GetUpButton_mc;
         }
         catch(err:Error) { }
         return null;
      }
      // alpha only: visible stays the game's, so the hold timeline keeps running and the exit still fires.
      // Name, x, and y stay the game's too. Exit input depends on GetUpButton_mc remaining that button.
      private function hz42VehHideVan(b:*, hide:Boolean) : void
      {
         if(b == null) { return; }
         try
         {
            if(hide)
            {
               if(!this.hzVehHid)
               {
                  var a:Number = Number(b.alpha);
                  this.hzVehAlpha = (!isNaN(a) && a > 0.05) ? a : 1;
                  this.hzVehHid = true;
               }
               b.alpha = 0;
            }
            else if(this.hzVehHid)
            {
               b.alpha = this.hzVehAlpha > 0 ? this.hzVehAlpha : 1;
               this.hzVehHid = false;
            }
         }
         catch(err:Error) { }
      }
      private function hz42VehLabel(mc:*, name:String) : int
      {
         var f:int = 0;
         try
         {
            var labs:Array = mc.currentLabels;
            var i:int = 0;
            var n:int = labs != null ? int(labs.length) : 0;
            while(i < n)
            {
               var lb:* = labs[i];
               if(lb != null && String(lb.name) == name) { f = int(lb.frame); break; }
               i++;
            }
         }
         catch(err:Error) { f = 0; }
         return f;
      }
      // 0 at or before StartHold, 1 at or after buttonHoldComplete. The frames after that label are the end flash.
      private function hz42VehSpan(cur:int, a:int, z:int) : Number
      {
         if(a < 1 || z <= a) { return 0; }
         if(cur >= z) { return 1; }
         if(cur <= a) { return 0; }
         return (cur - a) / (z - a);
      }
      private function hz42VehHold(b:*) : *
      {
         var pc:* = this.hz42VehAt(b,["PCButton_mc","ButtonInstance_mc","HoldAnim_mc"]);
         var con:* = this.hz42VehAt(b,["ConsoleButton_mc","ButtonInstance_mc","HoldAnim_mc"]);
         var pad:int = this.hzVehPad;
         if(pad < 0)
         {
            var pcOn:Boolean = this.hz42VehShown(this.hz42VehAt(b,["PCButton_mc"]),b);
            var conOn:Boolean = this.hz42VehShown(this.hz42VehAt(b,["ConsoleButton_mc"]),b);
            if(conOn && !pcOn) { pad = 1; }
            else { pad = 0; }
         }
         var hold:* = pad == 1 ? con : pc;
         if(hold == null) { hold = pad == 1 ? pc : con; }
         return hold;
      }
      private function hz42VehProg(b:*) : Number
      {
         var p:Number = 0;
         var hold:* = this.hz42VehHold(b);
         if(hold != null)
         {
            var cur:int = 0;
            try { cur = int(hold.currentFrame); } catch(eH:Error) { cur = 0; }
            var a:int = this.hz42VehLabel(hold,"StartHold");
            var z:int = this.hz42VehLabel(hold,"buttonHoldComplete");
            p = this.hz42VehSpan(cur,a,z);
         }
         // The button's own frames, including 41 and later, are not the sweep.
         if(p < 0) { return 0; }
         return p > 1 ? 1 : p;
      }
      private function hz42VehAt(o:*, path:Array) : *
      {
         try
         {
            var c:* = o;
            for each(var n:String in path) { if(c == null) { return null; } c = c[n]; }
            return c;
         }
         catch(err:Error) { }
         return null;
      }
      private function hz42VehShown(d:*, top:*) : Boolean
      {
         try
         {
            var c:* = d;
            var n:int = 0;
            while(c != null && c != top && n < 8)
            {
               if(c.visible == false) { return false; }
               c = c.parent;
               n++;
            }
            return c != null;
         }
         catch(err:Error) { }
         return false;
      }
      private function hz42VehTx(t:*) : String
      {
         try
         {
            if(t == null || t.visible == false || t.text == null) { return null; }
            var s:String = String(t.text).replace(/^\s+|\s+$/g,"").replace(/\s+/g," ");
            if(s.length == 0 || s == "?" || s == "null" || s == "undefined" || s.charAt(0) == "$") { return null; }
            return s.length > 12 ? s.substr(0,12) : s;
         }
         catch(err:Error) { }
         return null;
      }
      // live key only: keyboard text or the controller glyph. No stand-in key when the game has not drawn one.
      private function hz42VehKey(b:*) : Array
      {
         var pc:* = this.hz42VehAt(b,["PCButton_mc","ButtonInstance_mc","PCButton_tf"]);
         if(pc == null) { pc = this.hz42VehAt(b,["PCButton_mc","PCButton_tf"]); }
         var con:* = this.hz42VehAt(b,["ConsoleButton_mc","ButtonInstance_mc","ConsoleButton_tf"]);
         if(con == null) { con = this.hz42VehAt(b,["ConsoleButton_mc","ConsoleButton_tf"]); }
         var pcOn:Boolean = pc != null && this.hz42VehShown(pc,b);
         var conOn:Boolean = con != null && this.hz42VehShown(con,b);
         var usePad:int = this.hzVehPad;
         if(usePad < 0)
         {
            if(conOn && !pcOn) { usePad = 1; }
            else if(pcOn && !conOn) { usePad = 0; }
            else { return ["",""]; }
         }
         if(usePad == 1)
         {
            if(!conOn) { return ["",""]; }
            var ct:String = this.hz42VehTx(con);
            if(ct == null) { return ["",""]; }
            var font:String = "";
            try { var f:* = con.getTextFormat().font; if(f) { font = String(f); } } catch(err:Error) { font = ""; }
            return [ct,font];
         }
         if(!pcOn) { return ["",""]; }
         var pt:String = this.hz42VehTx(pc);
         if(pt == null) { return ["",""]; }
         return [pt.toUpperCase(),""];
      }
      private function hz42VehFs(size:Number) : Number
      {
         var ts:Number = this.hzTextScale;
         if(isNaN(ts) || ts <= 0) { ts = 1; }
         ts = Math.max(0.8,Math.min(1.3,ts));
         var sz:Number = Math.round(size * ts * 2) / 2;
         if(sz < 13) { sz = 13; }
         return sz;
      }
      private function hz42VehTf(p:Sprite, s:String, size:Number, col:uint, font:String, ls:Number, align:String = "left") : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = flash.text.TextFieldAutoSize.LEFT;
         var f:TextFormat = new TextFormat(font,size,col);
         f.letterSpacing = ls;
         f.align = align;
         t.defaultTextFormat = f;
         t.text = s;
         t.setTextFormat(f);
         t.textColor = col;
         t.filters = this.hz35Shadow(false);
         try { t.antiAliasType = "advanced"; t.gridFitType = "pixel"; } catch(err:Error) { }
         p.addChild(t);
         return t;
      }
      // Stage sizes for the 1440p measurement (pill was 48 px from a 39-unit box, about 1.23 screen px per stage unit).
      // 42 -> about 52 px tall, key 24 -> about 30 px, inset 8 -> about 10 px, gap 11 -> about 14 px.
      // Key 17 -> about 21 px bold. EXIT 19.5 -> about 24 px semibold. The repo's 1080/ScreenHeight rule (0.75) is noted in the findings.
      // Outline, glow, sweep, and the key follow HZ_ACCENT. Only the finished hold is HZ_GREEN.
      private function hz42VehDraw(key:String, face:String, prog:Number, done:Boolean) : void
      {
         var p:Sprite = this.hzVehPx;
         while(p.numChildren > 0) { p.removeChildAt(0); }
         var g:* = p.graphics;
         g.clear();
         var keyFs:Number = this.hz42VehFs(17);
         var labFs:Number = this.hz42VehFs(19.5);
         var edge:uint = done ? HZ_GREEN : HZ_ACCENT;
         var h:Number = 42;
         var keyBox:Number = 24;
         var x0:Number = 8;
         var gap:Number = 11;
         var kt:TextField = null;
         var kw:Number = 0;
         var kh:Number = keyBox;
         if(key != null && key.length > 0)
         {
            var kface:String = face != null && face.length > 0 ? face : this.hzFontName("bd");
            kt = this.hz42VehTf(p,key,keyFs,edge,kface,0,"center");
            var kMeas:Number = Number(kt.textWidth);
            if(isNaN(kMeas) || kMeas < 0) { kMeas = 0; }
            kw = Math.ceil(kMeas + 8);
            if(kw < keyBox) { kw = keyBox; }
            var kth:Number = kt.height;
            kt.autoSize = flash.text.TextFieldAutoSize.NONE;
            kt.width = kw;
            if(kt.height < kth) { kt.height = kth; }
            // Height stays keyBox (24). A taller text field used to stretch the cap to about 28.
         }
         var lab:String = this.hzHdrCase("EXIT");
         var lls:Number = Math.round(labFs * 0.1 * 10) / 10;
         var lt:TextField = this.hz42VehTf(p,lab,labFs,0xF2F7F9,this.hzFontName(),lls);
         var tw:Number = Number(lt.textWidth);
         if(isNaN(tw) || tw < 8) { tw = 36; }
         var labLen:int = lab != null ? int(lab.length) : 0;
         var tracked:Number = Math.ceil(tw + lls * (labLen > 0 ? labLen - 1 : 0));
         var lth:Number = lt.height;
         lt.autoSize = flash.text.TextFieldAutoSize.NONE;
         lt.width = tracked + 4;
         if(lt.height < lth) { lt.height = lth; }
         if(lt.height + 12 > h) { h = Math.round(lt.height + 12); }
         if(kh + 10 > h) { h = kh + 10; }
         var lx:Number = x0 + (kw > 0 ? kw + gap : 0);
         var checkW:Number = done ? 18 : 0;
         var w:Number = Math.round(lx + tracked + 16 + checkW);
         if(w < 96) { w = 96; }
         var i:int = 0;
         while(i < 3)
         {
            var sx:Number = 2 + i;
            var sy:Number = 3;
            var sw:Number = w - 8 - i * 2;
            var shd:Number = h - 8;
            if(sw > 4 && shd > 4) { g.beginFill(0x000000,0.07); g.drawRoundRect(sx,sy,sw,shd,h,h); g.endFill(); }
            i++;
         }
         var opa:Number = Number(this.hzCardOpacity);
         if(isNaN(opa)) { opa = 1; }
         g.lineStyle();
         g.beginFill(0x0B1218,Math.min(1,0.88 * opa));
         g.drawRoundRect(0.5,0.5,w - 1,h - 1,h - 1,h - 1);
         g.endFill();
         var sweep:Sprite = new Sprite();
         sweep.mouseEnabled = false;
         sweep.mouseChildren = false;
         var fw:Number = Math.round(w * (done ? 1 : prog));
         var sweepA:Number = 0.30;
         if(fw > 0)
         {
            var sg:* = sweep.graphics;
            var sweepCol:uint = done ? HZ_GREEN : edge;
            if(!done && fw < w - 1)
            {
               var feather:Number = 6;
               if(feather > fw) { feather = fw; }
               var mtx:* = new flash.geom.Matrix();
               mtx.createGradientBox(w,h,0,0,0);
               var fade0:int = int(Math.round(255 * Math.max(0,fw - feather) / w));
               var fade1:int = int(Math.round(255 * fw / w));
               if(fade1 <= fade0) { fade1 = fade0 + 1; }
               if(fade1 > 255) { fade1 = 255; }
               if(fade0 >= fade1) { fade0 = fade1 - 1; }
               if(fade0 < 0) { fade0 = 0; }
               sg.beginGradientFill("linear",[sweepCol,sweepCol,sweepCol],[sweepA,sweepA,0],[0,fade0,fade1],mtx);
            }
            else { sg.beginFill(sweepCol,sweepA); }
            sg.drawRoundRect(0.5,0.5,w - 1,h - 1,h - 1,h - 1);
            sg.endFill();
            p.addChild(sweep);
         }
         var idleRim:Boolean = !done && prog <= 0.02;
         var rimCol:uint = done ? HZ_GREEN : (idleRim ? 0xFFFFFF : edge);
         var rimA:Number = idleRim ? 0.18 : (done ? 1 : 0.95);
         var rimW:Number = idleRim ? 1.5 : 2;
         var rim:Sprite = new Sprite();
         rim.mouseEnabled = false;
         rim.mouseChildren = false;
         var rg:* = rim.graphics;
         rg.lineStyle(rimW,rimCol,rimA,true,"none");
         rg.beginFill(rimCol,0.004);
         rg.drawRoundRect(rimW * 0.5,rimW * 0.5,w - rimW,h - rimW,Math.max(0,h - rimW),Math.max(0,h - rimW));
         rg.endFill();
         // Blur 6 stays under Scaleform's 15.9 px text-and-shape glow cap. Idle has no glow.
         if(!idleRim) { try { rim.filters = [new GlowFilter(rimCol,0.30,6,6,1,1)]; } catch(eGlow:Error) { } }
         p.addChild(rim);
         if(kw > 0)
         {
            var cap:Sprite = new Sprite();
            cap.mouseEnabled = false;
            cap.mouseChildren = false;
            var ky:Number = Math.round((h - kh) / 2);
            var cg:* = cap.graphics;
            cg.lineStyle(1.5,edge,0.9,true,"none");
            var capA:Number = done ? 0.18 : (idleRim ? 0.10 : 0.22);
            cg.beginFill(edge,capA);
            cg.drawRoundRect(x0 + 0.75,ky + 0.75,kw - 1.5,kh - 1.5,8,8);
            cg.endFill();
            p.addChild(cap);
            kt.x = x0;
            kt.y = Math.round(ky + (kh - kt.height) / 2);
            p.addChild(kt);
         }
         lt.x = Math.round(lx);
         lt.y = Math.round(h / 2 - lt.height / 2);
         p.addChild(lt);
         if(done)
         {
            var ck:Sprite = new Sprite();
            ck.mouseEnabled = false;
            var kg:* = ck.graphics;
            var cx0:Number = Math.round(lx + tracked + 8);
            var cy0:Number = Math.round(h / 2);
            kg.lineStyle(2,HZ_GREEN,1,true,"none");
            kg.moveTo(cx0,cy0);
            kg.lineTo(cx0 + 4,cy0 + 4);
            kg.lineTo(cx0 + 11,cy0 - 5);
            p.addChild(ck);
         }
         this.hzVehW = w;
         this.hzVehH = h;
      }
      private function hz42VehFront() : void
      {
         var p:Sprite = this.hzVehPx;
         if(p == null) { return; }
         if(p.parent != this) { this.addChild(p); }
         try { this.setChildIndex(p,this.numChildren - 1); } catch(err:Error) { }
         var tops:Array = [this.hzArr_mc,this.HorizonSettings_mc];
         var i:int = 0;
         while(i < tops.length)
         {
            var c:Sprite = tops[i] as Sprite;
            if(c != null && c.parent == this && c.visible) { try { this.setChildIndex(c,this.numChildren - 1); } catch(err2:Error) { } }
            i++;
         }
      }
      private function hz42VehPlace(b:*) : Boolean
      {
         var r:Rectangle = null;
         try { r = b.getBounds(this); } catch(err:Error) { r = null; }
         var bad:Boolean = r == null || isNaN(r.x) || isNaN(r.y) || isNaN(r.width) || isNaN(r.height) || r.width < 1 || r.height < 1 || r.width > 800 || r.height > 400;
         if(bad)
         {
            r = null;
            try
            {
               var lp:Point = this.globalToLocal(b.localToGlobal(new Point(b.width > 1 ? b.width / 2 : 0,b.height > 1 ? b.height / 2 : 0)));
               if(lp != null && !isNaN(lp.x) && !isNaN(lp.y)) { r = new Rectangle(lp.x,lp.y,2,2); }
            }
            catch(err2:Error) { r = null; }
         }
         if(r == null || isNaN(r.x) || isNaN(r.y)) { return false; }
         this.hzVehPx.x = Math.round(r.x + r.width / 2 - this.hzVehW / 2);
         this.hzVehPx.y = Math.round(r.y + r.height / 2 - this.hzVehH / 2);
         return true;
      }
      private function hz42VehTick() : void
      {
         var b:* = this.hz42VehBtn();
         if(!this.hzVehOn || b == null)
         {
            this.hzVehFail = 0;
            this.hz42VehHideVan(b,false);
            if(this.hzVehPx != null) { this.hzVehPx.visible = false; }
            return;
         }
         var shown:Boolean = false;
         var haveVis:Boolean = false;
         try
         {
            var vv:* = b.Visible;
            if(vv !== undefined) { haveVis = true; shown = Boolean(vv); }
         }
         catch(eV:Error) { haveVis = false; }
         if(!haveVis) { shown = this.hzVehIn == 1; }
         if(this.hzVehIn == 0) { shown = false; }
         try { if(b.stage == null) { shown = false; } } catch(eS:Error) { }
         if(shown && !this.hz42VehShown(b,this)) { shown = false; }
         if(!shown)
         {
            this.hzVehFail = 0;
            this.hz42VehHideVan(b,false);
            if(this.hzVehPx != null) { this.hzVehPx.visible = false; }
            return;
         }
         var prog:Number = this.hz42VehProg(b);
         if(isNaN(prog) || prog < 0) { prog = 0; }
         if(prog > 1) { prog = 1; }
         var done:Boolean = prog >= 1;
         var key:Array = this.hz42VehKey(b);
         var ks:String = key != null && key[0] != null ? String(key[0]) : "";
         var kf:String = key != null && key[1] != null ? String(key[1]) : "";
         var sig:String = (done ? "1" : "0") + "|" + String(int(Math.round(prog * 100))) + "|" + ks + "|" + kf + "|" + String(int(HZ_ACCENT)) + "|" + String(this.hzTextScale) + "|" + String(this.hzFontFace) + "|" + String(this.hzHeaderStyle) + "|" + String(this.hzCardOpacity);
         if(this.hzVehPx == null)
         {
            this.hzVehPx = new Sprite();
            this.hzVehPx.mouseEnabled = false;
            this.hzVehPx.mouseChildren = false;
            this.hzVehPx.name = "hzVehExit";
            this.hzVehSig = "";
         }
         if(sig != this.hzVehSig)
         {
            try
            {
               this.hz42VehDraw(ks,kf,prog,done);
               this.hzVehSig = sig;
               this.hzVehFail = 0;
            }
            catch(eD:Error)
            {
               this.hzVehFail++;
               if(this.hzVehFail >= 3)
               {
                  this.hzVehSig = sig;
                  this.hzVehPx.visible = false;
                  this.hz42VehHideVan(b,false);
               }
               return;
            }
         }
         if(this.hzVehW < 1 || !this.hz42VehPlace(b))
         {
            this.hzVehPx.visible = false;
            this.hz42VehHideVan(b,false);
            return;
         }
         this.hzVehPx.visible = true;
         this.hz42VehFront();
         this.hz42VehHideVan(b,true);
      }
      // =================== Horizon settings window (keyboard + mouse) ===================
      public var HorizonSettings_mc:Sprite = null;
      public var hzSettingsKeyName:String = "F11";
      private var hzSetBody:Sprite = null;
      private var hzSetCursor:Sprite = null;
      private var hzSetIsOpen:Boolean = false;
      private var hzDllFileVer:String = "";   // v0.42.0.4: DLL file version, from hzSetDllFileVersion
      private var hzSetPend:Object = null;
      private var hzSetOrig:Object = null;
      private var hzSetTab:int = 0;
      private var hzSetRow:int = 0;
      private var hzSetHover:String = "";
      private var hzSetHits:Array = [];
      private var hzSetDrag:int = -1;
      private var hzSetPrevDown:Boolean = false;
      private var hzSetSaveText:String = "";
      private static const HZ_SET_W:Number = 1000;
      private static const HZ_SET_H:Number = 660;
      private static const HZ_SET_TABS:Array = ["CARDS","STYLE","TEXT","EFFECTS","RULES","COMPASS","CONTROLS","SCANNER","COMMS"];   // v0.30: 7 SCANNER, 8 COMMS (optional modules)
      private static const HZ_SET_KEYS:Array = ["F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","Insert","Home","End","PageUp","PageDown"];
      private static const HZ_SET_ACCNAMES:Array = ["CYAN","TEAL","AMBER","VIOLET","LIME","WHITE","ROSE","ORANGE","SKY","GOLD","MINT","STEEL","DEEP BLUE"];

      // Row definitions: k = INI key, t = b(ool) / n(umber slider) / a(ccent swatches) / r(choice) / q(rule) / l(value list) / c(key) / x(action)
      // h = section heading drawn above the row; pill = drawn as the highlighted toggle in the tab header (CARDS: COMPACT MODE)
      private function hzSetRows(tab:int) : Array
      {
         if(tab == 0)
         {
            return this.hz34CardRows();   // v0.34: per-card SIZE / COMPACT FORM sub-rows
         }
         if(tab == 1)
         {
            return [{"k":"CardOpacity","l":"CARD OPACITY (HUD CARDS)","t":"n","mn":0.2,"mx":1.6,"st":0.05,"h":"PANEL"},{"k":"ContainerOpacity","l":"CONTAINER / CROSSHAIR CARD OPACITY","t":"n","mn":0.2,"mx":1.6,"st":0.05},{"k":"AccentColor","l":"ACCENT COLOR","t":"a","pal":this.hzAccPal(),"names":this.hzAccNames(),"note":"Also tints this window. Custom: AccentHex=#RRGGBB in the ini","h":"COLOR"},{"k":"CardColor","l":"CARD COLOR","t":"a","pal":this.hzCardPal(),"names":this.hzCardNames(),"note":"Light colors switch the text (and this window) to dark"},{"k":"HudScale","l":"HUD SCALE","t":"n","mn":0.7,"mx":1.4,"st":0.05,"h":"SIZE & PLACEMENT","note":"Every card on GLOBAL size. Per-card sizes are in CARDS"},{"k":"Margin","l":"SCREEN MARGIN","t":"n","mn":20,"mx":200,"st":10,"note":"Moves every card, ARRANGE-placed ones too (they keep their distance from it)"},{"k":"AfflictionLayout","l":"AFFLICTIONS LAYOUT","t":"r","opts":HZ_AFLAY_NAMES},{"k":"CrosshairStyle","l":"CROSSHAIR STYLE (INTERACT)","t":"r","opts":HZ_XH_NAMES,"h":"CROSSHAIR"},{"k":"ObjectRing","l":"OBJECT RING","t":"r","opts":HZ_RING_NAMES,"note":"The ring + line the game draws around the object you look at"},{"k":"ScreenHeight","l":"SCREEN HEIGHT (PIXEL SNAP)","t":"l","vals":HZ_SET_SCRH,"names":HZ_SET_SCRH_N,"note":"Your vertical resolution: crosshair cards snap to whole pixels"}];
         }
         if(tab == 2)
         {
            return this.hz30FontRows([{"k":"TextTone","l":"TEXT TONE","t":"r","opts":HZ_TONE_NAMES,"note":"AUTO = dark text on light card colors","h":"TYPE"},{"k":"FontFace","l":"FONT","t":"r","opts":HZ_FONT_NAMES,"ids":HZ_FONT_IDS,"note":"EXO 2 (default) / ROBOTO need fonts_horizon.swf + fontconfig; game font is used if missing."},{"k":"TextScale","l":"TEXT SIZE","t":"n","mn":0.8,"mx":1.3,"st":0.05},{"k":"HeaderStyle","l":"CARD HEADER STYLE","t":"r","opts":HZ_HDRSTYLE_NAMES},{"k":"TextShadow","l":"TEXT SHADOW","t":"b"},{"k":"TimeDisplay","l":"PLANET TIME","t":"r","opts":HZ_TIME_NAMES,"h":"CLOCK"},{"k":"ClockFormat","l":"CLOCK FORMAT","t":"r","opts":HZ_CLOCK_NAMES},{"k":"TempUnit","l":"TEMPERATURE UNITS","t":"r","opts":HZ_TEMP_NAMES}]);
         }
         if(tab == 3)
         {
            return [{"k":"SmoothBars","l":"SMOOTH BARS","t":"b","h":"CARDS"},{"k":"FadeCards","l":"FADE CARDS","t":"b"},{"k":"CombatDim","l":"DIM OUT OF COMBAT","t":"b"},{"k":"DimOpacity","l":"DIM OPACITY","t":"n","mn":0.2,"mx":1,"st":0.05},{"k":"HazardAlert","l":"HAZARD ALERT","t":"b"},{"k":"AutoCenterVitals","l":"CENTER VITALS WHEN EQUIPMENT HIDDEN","t":"b","note":"Ignored once the vitals card is moved in ARRANGE CARDS"},{"k":"TargetAnchor","l":"TARGET: ANCHOR","t":"r","opts":HZ_TGANCHOR_NAMES,"h":"TARGET"},{"k":"TargetShowValue","l":"TARGET: ITEM VALUE / WEIGHT","t":"b"},{"k":"EdgePulse","l":"LOW HEALTH / O2 SCREEN-EDGE PULSE","t":"b","h":"WARNINGS"},{"k":"XpToast","l":"XP GAIN TOAST","t":"b","note":"With the Comms module the game's own +XP popup is hidden while this is on"},{"k":"RegenSliver","l":"HEALING REGEN SLIVER","t":"b"},{"k":"HitMarkers","l":"HIT MARKER + KILL X","t":"b","h":"COMBAT FEEDBACK"},{"k":"DamageNumbers","l":"FLOATING DAMAGE NUMBERS","t":"b"},{"k":"DirectionRing","l":"DAMAGE DIRECTION RING","t":"b"}];
         }
         if(tab == 4)
         {
            return [{"k":"JetpackRule","l":"JETPACK","t":"q","ids":[0,4,1,2],"h":"WHEN EACH CARD SHOWS"},{"k":"VitalsRule","l":"VITALS","t":"q","ids":[0,5,1,2]},{"k":"PlanetRule","l":"PLANET","t":"q","ids":[0,1,2]},{"k":"AfflictionsRule","l":"AFFLICTIONS","t":"q","ids":[0,6,1,2]},{"k":"AmmoRule","l":"EQUIPMENT","t":"q","ids":[0,3,1,2]},{"k":"QuestsRule","l":"QUEST TRACKER","t":"q","ids":[0,1,2]},{"k":"CompassRule","l":"COMPASS","t":"q","ids":[0,1,2]},{"k":"CharacterRule","l":"CHARACTER CARD","t":"q","ids":[0,7,8,9,1,2],"note":"XP / level / credits / skill point: shows for 8 s, then fades (CharacterShowSeconds in the ini)"}];
         }
         if(tab == 5)
         {
            return [{"k":"CompassMarkers","l":"COMPASS MARKERS (ALL)","t":"b","h":"COMPASS MARKERS"},{"k":"ShowFollowers","l":"FOLLOWERS / COMPANIONS","t":"b"},{"k":"FollowerColor","l":"FOLLOWER MARKER COLOR","t":"a","pal":HZ_FOL_PAL,"names":HZ_FOL_NAMES},{"k":"ShowLocations","l":"LOCATIONS / POIS / OUTPOSTS","t":"b"},{"k":"ShowShip","l":"SHIP / VEHICLE","t":"b"},{"k":"ShowEnemies","l":"ENEMIES","t":"b"},{"k":"ShowPlayerMarker","l":"CUSTOM MAP MARKER","t":"b","note":"Quest objectives always show while markers are on"}];
         }
         if(tab == 7) { return this.hz37WithWarn(this.hz40ScanRows()); }
         if(tab == 8) { return this.hz37WithWarn(this.hz30Mod["comms"] === 1 ? this.hz31CommsRows() : this.hz30ModRows("comms")); }
         var ml:Object = {"k":"_msglog","l":"MESSAGE LOG","t":"x","btn":"OPEN","n13":true};
         if(this.hzMsglogModule() == 0) { ml.dis = true; ml.note = "needs Notifications"; }
         return this.hz37WithWarn([{"k":"SettingsKey","l":"SETTINGS MENU KEY","t":"c","note":"takes effect after restart","h":"CONTROLS"},{"k":"_arrange","l":"ARRANGE CARDS  (drag cards on screen)","t":"x"},ml]).concat(this.hz37Rows());
      }

      private function hzSetCurrent() : Object
      {
         var cur:Object = {"ShowJetpack":this.hzShowJetpack,"JetpackAutoHide":this.hzJetpackAutoHide,"ShowVitals":this.hzShowVitals,"ShowPlanet":this.hzShowPlanet,"ShowAfflictions":this.hzShowAfflictions,"AfflictionsAutoHide":this.hzAfflAutoHide,"ShowAmmo":this.hzShowAmmo,"AmmoOnlyWhenDrawn":this.hzAmmoOnlyWhenDrawn,"ShowQuests":this.hzShowQuests,"ShowCompass":this.hzShowCompass,"VehicleExitPill":this.hzVehOn,"CompassMarkers":this.hzShowCompassMarkers,"CardOpacity":this.hzCardOpacity,"ContainerOpacity":this.hzContOpacity,"AccentColor":Math.max(0,Math.min(this.hzAccPal().length - 1,this.hzAccentChoice)),"Margin":this.hzMargin,"Compact":this.hzCompact,"SmoothBars":this.hzSmoothBars,"FadeCards":this.hzFadeCards,"CombatDim":this.hzCombatDim,"DimOpacity":this.hzDimAlpha,"HazardAlert":this.hzHazardAlert,"CardColor":Math.max(0,Math.min(this.hzCardPal().length - 1,this.hzCardColor)),"HudScale":this.hzHudScale,"AutoCenterVitals":this.hzAutoCenterVitals,"JetpackRule":this.hzRuleJetpack,"VitalsRule":this.hzRuleVitals,"PlanetRule":this.hzRulePlanet,"AfflictionsRule":this.hzRuleAffl,"AmmoRule":this.hzRuleAmmo,"QuestsRule":this.hzRuleQuests,"CompassRule":this.hzRuleCompass,"SettingsKey":this.hzSettingsKeyName,"ShowFollowers":this.hzCmpFollowers,"TextTone":this.hzTextTone,"FontFace":this.hzFontFace,"PlanetDetails":this.hzPlanDetails,"ShowTarget":this.hzShowTarget,"TargetAnchor":this.hzTgAnchor,"TargetShowValue":this.hzTgShowValue,"ShowLocations":this.hzCmpLocations,"ShowShip":this.hzCmpShip,"ShowEnemies":this.hzCmpEnemies,"ShowPlayerMarker":this.hzCmpPlayerMark,"TextScale":this.hzTextScale,"ContainerScale":this.hzTgScale,"ScreenHeight":this.hzScrH,"CrosshairStyle":this.hzXhStyle,"ObjectRing":this.hzObjRing,"HeaderStyle":this.hzHeaderStyle,"TextShadow":this.hzTextShadow,"TimeDisplay":this.hzTimeDisplay,"ClockFormat":this.hzClockFmt,"TempUnit":this.hzTempUnit,"AfflictionLayout":this.hzAfLayout};
         try { this.hz26SetCur(cur); } catch(err26:Error) { }
         try { this.hz31SetCur(cur); } catch(err31:Error) { }
         try { this.hz34SetCur(cur); } catch(err34:Error) { }
         try { this.hz40SetCur(cur); } catch(err40:Error) { }
         try { this.hz42ScSetCur(cur); } catch(err42c:Error) { }   // v0.42.0 r2: [Scope]
         return cur;
      }

      private var hzPopLayers:Array = [];   // 0.43.0.1: extra F11 layers (log / settings / confirm). P1 is plumbing only.

      public function hzSettingsOpen() : Boolean
      {
         return this.hzSetIsOpen || this.hzArrange || (this.hzPopLayers != null && this.hzPopLayers.length > 0);
      }

      // Purpose: forced close when a full-screen menu opens. Every layer goes.
      // The older path toggled at most twice and could leave a layer stuck (freeze risk).
      // Inputs: none. Outputs: none. Dependencies: hzArrExit, hzSetCancel, hz37Reset.
      public function hzSettingsCloseAll() : void
      {
         this.hzMsglogForceClose();
         this.hzPopLayers = [];
         try { if(this.hz41SA) { this.hz41SAEnd(false); } } catch(eSa:Error) { }
         if(this.hzArrange) { this.hzArrExit(false); }
         if(this.hzSetIsOpen) { this.hzSetCancel(); }
         try { this.hz37Reset(); } catch(e37:Error) { }
      }

      public function hzPopPush(id:String) : void
      {
         if(id == null || id.length == 0) { return; }
         if(this.hzPopLayers == null) { this.hzPopLayers = []; }
         if(this.hzPopLayers.length >= 8) { return; }
         this.hzPopLayers.push(id);
      }

      public function hzPopPop() : String
      {
         if(this.hzPopLayers == null || this.hzPopLayers.length == 0) { return ""; }
         return String(this.hzPopLayers.pop());
      }

      public function hzPopTop() : String
      {
         if(this.hzPopLayers == null || this.hzPopLayers.length == 0) { return ""; }
         return String(this.hzPopLayers[this.hzPopLayers.length - 1]);
      }

      private function hzPopKey(code:String) : void
      {
         var top:String = this.hzPopTop();
         if(top == "log" || top == "mlconfirm" || top == "logset" || top == "mlhist" || top == "mlchars") { this.hzMsglogKey(code); return; }
         if(code == "cancel") { this.hzPopPop(); }
      }

      // F11 and the Message Log open from the keyboard only. Never a pad button.
      public function hzMsglogOpenHint() : String
      {
         return "F11";
      }

      public function hzMsglogModule() : Number
      {
         return this.hz30Mod["notifications"] === 1 ? 1 : 0;
      }

      // ut|lt|body for the log detail strip. lt is -1 when vanilla blanks local time.
      public function hzMsglogClock() : String
      {
         var ut:String = this.hzPpUT >= 0 ? String(this.hzPpUT) : "-1";
         var lt:String = this.hzPpDay >= 0 ? String(this.hzPpDay) : "-1";
         var body:String = this.hzPpBodyName != null && this.hzPpBodyName != "--" ? this.hzPpBodyName : "";
         return ut + "|" + lt + "|" + body;
      }

      // ---------- Message Log popup (0.43.0.6). Inside the 1000x660 F11 window. ----------
      // v6 layout: 976x620, 10 visible rows at 28 px, time column 168 px, text at least 13 px. No new F keys.
      // Decision A (2026-10-27): every later-point row is dimmed, not just pins.
      private static const HZ_ML_W:Number = 976;
      private static const HZ_ML_H:Number = 620;
      private static const HZ_ML_ROW:Number = 28;
      private static const HZ_ML_VIS:int = 10;
      private static const HZ_ML_CLOCK:Number = 168;
      private static const HZ_MLS_W:Number = 620;
      private static const HZ_MLS_H:Number = 620;
      private static const HZ_ML_CHIPS:Array = ["ALL","MEDICAL","CREW","REACTIONS","BUSY","CRIME","CREDITS","QUEST","LOCATION","GAME","XP"];
      private static const HZ_ML_KIND:Array = ["","medical","crew","reaction","busy","crime","credits","quest","location","game","xp"];
      private var hzMlLayer:Sprite = null;
      private var hzMlHits:Array = [];
      private var hzMlRows:Array = [];
      private var hzMlSelId:Number = 0;
      private var hzMlScroll:int = 0;
      private var hzMlChip:int = 0;
      private var hzMlChipX:Number = 0;
      private var hzMlFind:String = "";
      private var hzMlFindOn:Boolean = false;
      private var hzMlAllTime:Boolean = true;
      private var hzMlStatus:String = "ok";
      private var hzMlSess:int = 0;
      private var hzMlPinN:int = 0;
      private var hzMlPinCap:int = 50;
      private var hzMlAct:String = "";
      private var hzMlPacked:String = "";
      private var hzMlNotice:String = "";
      private var hzMlPad:Boolean = false;
      private var hzMlHover:String = "";
      private var hzMlRecord:Boolean = true;
      private var hzMlPersist:Boolean = true;
      private var hzMlHistory:int = 500;
      private var hzMlTypes:String = "medical,crew,reaction,busy,crime,credits,quest,location,xp,game";
      private var hzMlMissed:Boolean = true;
      private var hzMlFolder:String = "";
      private var hzMlOtherN:int = 0;
      private var hzMlOthers:Array = [];
      private var hzMlSetRow:int = 0;
      private var hzMlSetScroll:int = 0;

      public function hzMsglogNeed() : String
      {
         var top:String = this.hzPopTop();
         return (top == "log" || top == "mlconfirm" || top == "logset" || top == "mlhist" || top == "mlchars") ? "1" : "0";
      }

      public function hzTakeMsglogAct() : String
      {
         var s:String = this.hzMlAct != null ? this.hzMlAct : "";
         this.hzMlAct = "";
         return s;
      }

      public function hzSetMsglogView(s:String) : void
      {
         if(s == null) { s = ""; }
         if(s == this.hzMlPacked) { return; }
         this.hzMlPacked = s;
         this.hzMsglogParse(s);
         if(this.hzPopTop() == "log" || this.hzPopTop() == "mlconfirm" || this.hzPopTop() == "logset" || this.hzPopTop() == "mlhist" || this.hzPopTop() == "mlchars") { this.hzMsglogDraw(); }
      }

      private function hzMsglogOpen() : void
      {
         if(this.hzMsglogModule() == 0) { return; }
         if(this.hzPopTop() == "log" || this.hzPopTop() == "mlconfirm") { return; }
         this.hzPopPush("log");
         this.hzMlFindOn = false;
         this.hzMlFind = "";
         this.hzMlNotice = "";
         this.hzMlPacked = "";
         this.hzMsglogEnsure();
         this.hzMsglogDraw();
      }

      private function hzMsglogForceClose() : void
      {
         this.hzMlAct = "";
         this.hzMlFindOn = false;
         this.hzMlNotice = "";
         this.hzMlPacked = "";
         if(this.hzMlLayer != null) { this.hzMlLayer.visible = false; }
         while(this.hzPopTop() == "log" || this.hzPopTop() == "mlconfirm" || this.hzPopTop() == "logset" || this.hzPopTop() == "mlhist" || this.hzPopTop() == "mlchars") { this.hzPopPop(); }
      }

      private function hzMsglogEnsure() : void
      {
         if(this.hzMlLayer != null) { return; }
         this.hzMlLayer = new Sprite();
         this.hzMlLayer.mouseEnabled = false;
         this.hzMlLayer.mouseChildren = false;
      }

      private function hzMsglogParse(s:String) : void
      {
         this.hzMlRows = [];
         this.hzMlOthers = [];
         if(s == null || s.length < 3) { return; }
         var lines:Array = s.split("\n");
         var head:Array = String(lines[0]).split("|");
         if(head.length >= 7)
         {
            this.hzMlStatus = String(head[1]);
            this.hzMlSess = int(head[2]);
            this.hzMlPinN = int(head[3]);
            this.hzMlPinCap = int(head[4]);
         }
         if(head.length >= 14)
         {
            this.hzMlRecord = String(head[7]) != "0";
            this.hzMlPersist = String(head[8]) != "0";
            this.hzMlHistory = int(head[9]);
            this.hzMlTypes = String(head[10]);
            this.hzMlMissed = String(head[11]) != "0";
            this.hzMlOtherN = int(head[12]);
            this.hzMlFolder = String(head[13]);
         }
         var i:int = 1;
         while(i < lines.length)
         {
            var p:Array = String(lines[i]).split("|");
            if(p.length >= 4 && String(p[0]) == "o")
            {
               this.hzMlOthers.push({"name":String(p[1]),"n":int(p[2]),"ts":Number(p[3])});
               i++;
               continue;
            }
            if(p.length >= 15)
            {
               this.hzMlRows.push({
                  "id":Number(p[0]),"k":String(p[1]),"title":String(p[2]),"text":String(p[3]),
                  "tag":String(p[4]),"loc":String(p[5]),"n":int(p[6]),"pin":int(p[7]),
                  "missed":int(p[8]),"sess":int(p[9]),"ts":Number(p[10]),"gt":Number(p[11]),
                  "ut":Number(p[12]),"lt":Number(p[13]),"later":int(p[14]) == 1
               });
            }
            i++;
         }
         if(this.hzMlOthers.length > 0) { this.hzMlOtherN = this.hzMlOthers.length; }
      }

      private function hzMsglogShown() : Array
      {
         var out:Array = [];
         var q:String = this.hzMlFind != null ? this.hzMlFind.toLowerCase() : "";
         var want:String = this.hzMlChip > 0 && this.hzMlChip < HZ_ML_KIND.length ? String(HZ_ML_KIND[this.hzMlChip]) : "";
         var i:int = 0;
         while(i < this.hzMlRows.length)
         {
            var r:Object = this.hzMlRows[i];
            if(!this.hzMlAllTime && int(r.sess) != this.hzMlSess) { i++; continue; }
            if(want.length > 0 && String(r.k) != want) { i++; continue; }
            if(q.length > 0)
            {
               var hay:String = (String(r.title) + " " + String(r.text) + " " + String(r.tag) + " " + String(r.loc)).toLowerCase();
               if(hay.indexOf(q) < 0) { i++; continue; }
            }
            out.push(r);
            i++;
         }
         return out;
      }

      private function hzMsglogChipCount(kind:String) : int
      {
         var n:int = 0;
         var q:String = this.hzMlFind != null ? this.hzMlFind.toLowerCase() : "";
         var i:int = 0;
         while(i < this.hzMlRows.length)
         {
            var r:Object = this.hzMlRows[i];
            if(!this.hzMlAllTime && int(r.sess) != this.hzMlSess) { i++; continue; }
            if(kind.length > 0 && String(r.k) != kind) { i++; continue; }
            if(q.length > 0)
            {
               var hay:String = (String(r.title) + " " + String(r.text) + " " + String(r.tag) + " " + String(r.loc)).toLowerCase();
               if(hay.indexOf(q) < 0) { i++; continue; }
            }
            n++;
            i++;
         }
         return n;
      }

      private function hzMsglogList() : Array
      {
         var rows:Array = this.hzMsglogShown();
         var list:Array = [];
         var pins:Array = [];
         var rest:Array = [];
         var i:int = 0;
         while(i < rows.length)
         {
            if(int(rows[i].pin) != 0) { pins.push(rows[i]); }
            else { rest.push(rows[i]); }
            i++;
         }
         if(pins.length > 0)
         {
            list.push({"g":1,"lab":"PINNED " + String(this.hzMlPinN) + " / " + String(this.hzMlPinCap)});
            i = 0;
            while(i < pins.length) { list.push(pins[i]); i++; }
         }
         var lastKey:String = "";
         i = rest.length - 1;
         var grouped:Array = [];
         while(i >= 0)
         {
            var e:Object = rest[i];
            var gk:String = this.hzMsglogGroup(e);
            grouped.push({"e":e,"gk":gk});
            i--;
         }
         i = 0;
         while(i < grouped.length)
         {
            var item:Object = grouped[i];
            if(String(item.gk) != lastKey)
            {
               list.push({"g":1,"lab":String(item.gk)});
               lastKey = String(item.gk);
            }
            list.push(item.e);
            i++;
         }
         return list;
      }

      private function hzMsglogGroup(e:Object) : String
      {
         var today:Boolean = this.hzMsglogIsToday(Number(e.ts));
         if(int(e.sess) == this.hzMlSess) { return today ? "Today · this session" : "This session"; }
         return today ? "Today · earlier" : "Earlier";
      }

      private function hzMsglogIsToday(ts:Number) : Boolean
      {
         if(ts <= 0) { return false; }
         var now:Date = new Date();
         var d:Date = new Date(ts * 1000);
         return now.fullYear == d.fullYear && now.month == d.month && now.date == d.date;
      }

      private function hzMsglogAgo(ts:Number) : String
      {
         if(ts <= 0) { return ""; }
         var sec:Number = Math.max(0, Math.floor(new Date().getTime() / 1000 - ts));
         if(sec < 60) { return "just now"; }
         if(sec < 3600) { return String(Math.floor(sec / 60)) + " min ago"; }
         if(sec < 86400) { return String(Math.floor(sec / 3600)) + " h ago"; }
         return String(Math.floor(sec / 86400)) + " d ago";
      }

      private function hzMsglogClockTxt(v:Number) : String
      {
         if(v < 0) { return ""; }
         var h:int = int(v) % 24;
         var m:int = int((v - int(v)) * 60);
         if(m < 0) { m = 0; }
         var hs:String = h < 10 ? "0" + String(h) : String(h);
         var ms:String = m < 10 ? "0" + String(m) : String(m);
         return hs + ":" + ms;
      }

      private function hzMsglogKindLab(k:String) : String
      {
         var i:int = 0;
         while(i < HZ_ML_KIND.length)
         {
            if(String(HZ_ML_KIND[i]) == k) { return String(HZ_ML_CHIPS[i]); }
            i++;
         }
         return "GAME";
      }

      private function hzMsglogStatusLab() : String
      {
         if(this.hzMlStatus == "memory" || this.hzMlStatus == "paused") { return "History not saved"; }
         if(this.hzMlStatus == "saving") { return "Saving"; }
         if(this.hzMlStatus == "fallback") { return "Character key fallback"; }
         return "";
      }

      private function hzMsglogChipKeepVisible(chipW:Number, chipInner:Number, activeLeft:Number, activeW:Number) : void
      {
         var maxX:Number = Math.max(0, chipW - chipInner);
         if(activeLeft < this.hzMlChipX) { this.hzMlChipX = activeLeft; }
         if(activeLeft + activeW > this.hzMlChipX + chipInner) { this.hzMlChipX = activeLeft + activeW - chipInner; }
         if(this.hzMlChipX > maxX) { this.hzMlChipX = maxX; }
         if(this.hzMlChipX < 0) { this.hzMlChipX = 0; }
      }

      private function hzMsglogKindIcon(g:*, x:Number, y:Number, k:String, col:uint, a:Number) : void
      {
         g.beginFill(col, a);
         if(k == "medical")
         {
            g.drawRect(x + 6, y + 1, 4, 14);
            g.drawRect(x + 1, y + 6, 14, 4);
         }
         else if(k == "location")
         {
            g.drawCircle(x + 8, y + 6, 5);
            g.moveTo(x + 3, y + 8);
            g.lineTo(x + 8, y + 15);
            g.lineTo(x + 13, y + 8);
            g.lineTo(x + 3, y + 8);
         }
         else if(k == "quest")
         {
            g.drawRect(x + 3, y + 2, 10, 12);
            g.drawRect(x + 6, y + 5, 4, 6);
         }
         else if(k == "xp")
         {
            g.moveTo(x + 8, y + 1);
            g.lineTo(x + 15, y + 15);
            g.lineTo(x + 1, y + 15);
            g.lineTo(x + 8, y + 1);
         }
         else if(k == "credits")
         {
            g.drawCircle(x + 8, y + 8, 7);
         }
         else if(k == "reaction")
         {
            g.drawCircle(x + 5, y + 7, 4);
            g.drawCircle(x + 11, y + 7, 4);
         }
         else if(k == "crew")
         {
            g.drawCircle(x + 8, y + 5, 4);
            g.drawRect(x + 3, y + 10, 10, 5);
         }
         else if(k == "crime")
         {
            g.moveTo(x + 8, y + 1);
            g.lineTo(x + 15, y + 8);
            g.lineTo(x + 8, y + 15);
            g.lineTo(x + 1, y + 8);
            g.lineTo(x + 8, y + 1);
         }
         else if(k == "busy")
         {
            g.drawCircle(x + 8, y + 8, 7);
            g.drawRect(x + 7, y + 4, 2, 5);
            g.drawRect(x + 7, y + 8, 5, 2);
         }
         else
         {
            g.drawRoundRect(x + 2, y + 2, 12, 12, 4, 4);
         }
         g.endFill();
      }

      private function hzMsglogEllip(t:TextField, maxW:Number) : void
      {
         if(t == null) { return; }
         var s:String = t.text;
         if(s == null) { return; }
         t.width = 2000;
         if(this.hzTW(t) <= maxW) { t.width = Math.round(maxW); return; }
         while(s.length > 1 && this.hzTW(t) > maxW)
         {
            s = s.substr(0,s.length - 1);
            t.text = s + "...";
            t.width = 2000;
         }
         t.width = Math.round(maxW);
      }

      private function hzMsglogDraw() : void
      {
         this.hzMsglogEnsure();
         if(this.HorizonSettings_mc == null) { return; }
         if(this.hzMlLayer.parent != this.HorizonSettings_mc) { this.HorizonSettings_mc.addChild(this.hzMlLayer); }
         this.hzMlLayer.visible = true;
         while(this.hzMlLayer.numChildren > 0) { this.hzMlLayer.removeChildAt(0); }
         this.hzMlLayer.graphics.clear();
         this.hzMlHits = [];
         var T:Object = this.hzSetTheme();
         var acc:uint = uint(T.acc);
         var b:Sprite = this.hzMlLayer;
         var g:* = b.graphics;
         var ox:Number = Math.round((HZ_SET_W - HZ_ML_W) / 2);
         var oy:Number = Math.round((HZ_SET_H - HZ_ML_H) / 2);
         b.x = 0; b.y = 0;
         g.beginFill(0x000000,0.35);
         g.drawRoundRect(0,0,HZ_SET_W,HZ_SET_H,36,36);
         g.endFill();
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(ox,oy,HZ_ML_W,HZ_ML_H,36,36);
         g.endFill();
         this.hz33Edge(b,ox,oy,HZ_ML_W,HZ_ML_H,36,uint(T.edge),Number(T.ea),1);
         this.hzWT(b,"HORIZON UI · MESSAGE LOG",ox + 22,oy + 14,520,15,"bd",uint(T.txt),2, "left", 13);
         var st:String = this.hzMsglogStatusLab();
         if(st.length > 0) { this.hzWT(b,st,ox + HZ_ML_W - 22,oy + 16,240,13,"sb",uint(T.mut),0.4,"right",13); }

         var cx:Number = ox + 22;
         var cy:Number = oy + 44;
         var i:int = 0;
         var chipW:Number = 0;
         var chipWs:Array = [];
         var chipLefts:Array = [];
         while(i < HZ_ML_CHIPS.length)
         {
            var cn:int = this.hzMsglogChipCount(String(HZ_ML_KIND[i]));
            var clab:String = String(HZ_ML_CHIPS[i]) + " " + String(cn);
            var on:Boolean = i == this.hzMlChip;
            var dim:Boolean = cn == 0 && i != 0;
            var tw:TextField = this.hzWT(b,clab,0,0,180,13,"sb",on ? uint(T.ontxt) : (dim ? uint(T.off) : uint(T.txt)),1.2,"left",13);
            var cw:Number = Math.round(this.hzTW(tw) + 18);
            b.removeChild(tw);
            chipLefts.push(chipW);
            chipWs.push(cw);
            chipW += cw + 8;
            i++;
         }
         var chipInner:Number = HZ_ML_W - 44;
         var actL:Number = this.hzMlChip >= 0 && this.hzMlChip < chipLefts.length ? Number(chipLefts[this.hzMlChip]) : 0;
         var actW:Number = this.hzMlChip >= 0 && this.hzMlChip < chipWs.length ? Number(chipWs[this.hzMlChip]) : 0;
         this.hzMsglogChipKeepVisible(chipW, chipInner, actL, actW);
         var strip:Sprite = new Sprite();
         strip.x = cx;
         strip.y = cy;
         strip.mouseEnabled = false;
         strip.mouseChildren = false;
         b.addChild(strip);
         var clip:Sprite = new Sprite();
         clip.graphics.beginFill(0xFFFFFF, 1);
         clip.graphics.drawRect(cx, cy, chipInner, 36);
         clip.graphics.endFill();
         clip.mouseEnabled = false;
         b.addChild(clip);
         strip.mask = clip;
         var sg:* = strip.graphics;
         i = 0;
         var at:Number = -this.hzMlChipX;
         while(i < HZ_ML_CHIPS.length)
         {
            cn = this.hzMsglogChipCount(String(HZ_ML_KIND[i]));
            clab = String(HZ_ML_CHIPS[i]) + " " + String(cn);
            on = i == this.hzMlChip;
            dim = cn == 0 && i != 0;
            tw = this.hzWT(strip,clab,at + 8,8,180,13,"sb",on ? uint(T.ontxt) : (dim ? uint(T.off) : uint(T.txt)),1.2,"left",13);
            cw = Math.round(this.hzTW(tw) + 18);
            sg.beginFill(on ? acc : uint(T.mut), on ? 0.9 : (dim ? 0.12 : 0.2));
            sg.drawRoundRect(at,4,cw,28,28,28);
            sg.endFill();
            tw.x = at + 8;
            var visX:Number = cx + at;
            var visR:Number = Math.min(visX + cw, cx + chipInner);
            var visL:Number = Math.max(visX, cx);
            if(visR > visL)
            {
               this.hzMlHits.push({"id":"chip" + i,"x":visL,"y":cy + 4,"w":visR - visL,"h":28});
            }
            at += cw + 8;
            i++;
         }

         var fy:Number = oy + 80;
         this.hzSetKey(b,g,ox + 22,fy + 4,"/",uint(T.mut),24,13,13);
         var boxX:Number = ox + 56;
         var boxW:Number = 320;
         g.lineStyle(1, uint(T.edge), this.hzMlFindOn ? Number(T.ea) : 0.55);
         g.beginFill(uint(T.fill), this.hzMlFindOn ? 0.55 : 0.28);
         g.drawRoundRect(boxX, fy, boxW, 28, 8, 8);
         g.endFill();
         g.lineStyle();
         var findLab:String = this.hzMlFind.length > 0 ? this.hzMlFind : "Find…";
         if(this.hzMlPad && !this.hzMlFindOn && this.hzMlFind.length == 0) { findLab = "Find (keyboard only)"; }
         var findCol:uint = (this.hzMlFindOn || this.hzMlFind.length > 0) ? uint(T.txt) : uint(T.mut);
         var ftf:TextField = this.hzWT(b,findLab,boxX + 10,fy + 6,boxW - 28,13,"rg",findCol,0.3,"left",13);
         if(this.hzMlFindOn)
         {
            var caretX:Number = boxX + 10 + (this.hzMlFind.length > 0 ? Math.min(boxW - 36, Math.round(this.hzTW(ftf))) : 0);
            g.beginFill(uint(T.txt), (int(getTimer() / 400) % 2 == 0) ? 0.9 : 0.15);
            g.drawRect(caretX + 1, fy + 6, 1, 16);
            g.endFill();
         }
         this.hzMlHits.push({"id":"find","x":ox + 22,"y":fy,"w":boxX + boxW - (ox + 22),"h":28});
         var allOn:Boolean = this.hzMlAllTime;
         this.hzSetSwitch(b,g,ox + HZ_ML_W - 22,fy + 18,allOn,T,false);
         this.hzWT(b,"ALL TIME",ox + HZ_ML_W - 70,fy + 8,80,13,"sb",uint(T.lab),1.2,"right",13);
         this.hzMlHits.push({"id":"alltime","x":ox + HZ_ML_W - 120,"y":fy,"w":98,"h":28});

         var list:Array = this.hzMsglogList();
         var rowTop:Number = oy + 116;
         var rowH:Number = 320;
         if(this.hzMlScroll < 0) { this.hzMlScroll = 0; }
         var maxSc:int = Math.max(0,list.length - HZ_ML_VIS);
         if(this.hzMlScroll > maxSc) { this.hzMlScroll = maxSc; }
         if(list.length == 0)
         {
            this.hzWT(b,"Starts empty. Messages from before this log was on cannot be recovered.",ox + 28,rowTop + 40,HZ_ML_W - 56,13,"rg",uint(T.mut),0.3,"left",13);
         }
         var vis:int = 0;
         var li:int = this.hzMlScroll;
         var ry:Number = rowTop;
         var sel:Object = null;
         while(li < list.length && vis < HZ_ML_VIS)
         {
            var it:Object = list[li];
            if(it.g)
            {
               this.hzWT(b,String(it.lab),ox + 28,ry + 6,400,13,"sb",acc,1.6,"left",13);
            }
            else
            {
               var isSel:Boolean = Number(it.id) == this.hzMlSelId;
               if(this.hzMlSelId == 0 && sel == null) { isSel = true; this.hzMlSelId = Number(it.id); }
               if(isSel) { sel = it; }
               var later:Boolean = it.later == true;
               var aMul:Number = later ? 0.45 : 1;
               if(isSel)
               {
                  g.beginFill(acc,0.13);
                  g.drawRoundRect(ox + 18,ry,HZ_ML_W - 48,HZ_ML_ROW,14,14);
                  g.endFill();
                  g.beginFill(acc,1);
                  g.drawRoundRect(ox + 18,ry + 6,3,16,3,3);
                  g.endFill();
               }
               var tcol:uint = later ? uint(T.mut) : uint(T.txt);
               var clock:String = this.hzMsglogClockTxt(Number(it.ut));
               if(clock.length == 0) { clock = this.hzMsglogAgo(Number(it.ts)); }
               else { clock = clock + "  " + this.hzMsglogAgo(Number(it.ts)); }
               var line:String = String(it.title);
               if(String(it.text).length > 0 && String(it.text) != String(it.title)) { line += "  " + String(it.text); }
               if(int(it.n) > 1) { line += "  x " + String(it.n); }
               var locX:Number = ox + HZ_ML_W - 196;
               var chipX:Number = locX - 118;
               var iconX:Number = ox + 28 + HZ_ML_CLOCK + 8;
               var textX:Number = iconX + 22;
               var textW:Number = chipX - textX - 8;
               if(textW < 80) { textW = 80; }
               var rt:TextField = this.hzWT(b,clock,ox + 28,ry + 6,HZ_ML_CLOCK,13,"sb",tcol,0.4,"left",13);
               rt.alpha = aMul;
               this.hzMsglogKindIcon(g, iconX, ry + 6, String(it.k), later ? uint(T.mut) : acc, later ? 0.45 : 0.9);
               var tt:TextField = this.hzWT(b,line,textX,ry + 6,textW,13,"rg",tcol,0.3,"left",13);
               tt.alpha = aMul;
               this.hzMsglogEllip(tt,textW);
               var chipLab:String = later ? "from a later point" : (String(it.tag).length > 0 ? String(it.tag) : this.hzMsglogKindLab(String(it.k)));
               var chp:TextField = this.hzWT(b,chipLab,0,0,140,13,"sb",later ? uint(T.mut) : uint(T.lab),1.2,"left",13);
               var chw:Number = Math.min(108, Math.round(this.hzTW(chp) + 14));
               g.beginFill(later ? uint(T.mut) : acc, later ? 0.12 : 0.18);
               g.drawRoundRect(chipX, ry + 4, chw, 20, 20, 20);
               g.endFill();
               chp.x = chipX + 7;
               chp.y = ry + 4;
               chp.alpha = aMul;
               this.hzMsglogEllip(chp, chw - 10);
               var where:String = String(it.loc);
               if(where.length > 0)
               {
                  var lt:TextField = this.hzWT(b,where,locX,ry + 6,132,13,"rg",tcol,0.3,"left",13);
                  lt.alpha = aMul;
                  this.hzMsglogEllip(lt, 132);
               }
               if(int(it.pin) != 0)
               {
                  g.beginFill(acc,0.85);
                  g.moveTo(ox + HZ_ML_W - 40, ry + 8);
                  g.lineTo(ox + HZ_ML_W - 32, ry + 8);
                  g.lineTo(ox + HZ_ML_W - 36, ry + 20);
                  g.lineTo(ox + HZ_ML_W - 40, ry + 8);
                  g.endFill();
               }
               this.hzMlHits.push({"id":"row" + String(it.id),"x":ox + 18,"y":ry,"w":HZ_ML_W - 48,"h":HZ_ML_ROW,"rid":Number(it.id)});
            }
            ry += HZ_ML_ROW;
            vis++;
            li++;
         }
         if(maxSc > 0)
         {
            var trX:Number = ox + HZ_ML_W - 16;
            var thH:Number = Math.max(24, Math.round(rowH * HZ_ML_VIS / Math.max(1,list.length)));
            var thY:Number = rowTop + (rowH - thH) * this.hzMlScroll / Math.max(1,maxSc);
            g.beginFill(uint(T.track),Number(T.ta));
            g.drawRoundRect(trX,rowTop,3,rowH,3,3);
            g.endFill();
            g.beginFill(acc,0.9);
            g.drawRoundRect(trX,thY,3,thH,3,3);
            g.endFill();
         }

         var dy:Number = oy + HZ_ML_H - 92 - 64;
         g.beginFill(uint(T.line),Number(T.la));
         g.drawRect(ox + 22,dy,HZ_ML_W - 44,1);
         g.endFill();
         if(sel != null)
         {
            this.hzMsglogKindIcon(g, ox + 28, dy + 10, String(sel.k), acc, 0.9);
            var d1:String = this.hzMsglogKindLab(String(sel.k)) + "  ·  " + String(sel.title);
            if(String(sel.text).length > 0) { d1 += "  " + String(sel.text); }
            var dtf:TextField = this.hzWT(b,d1,ox + 50,dy + 8,HZ_ML_W - 78,13,"sb",uint(T.txt),0.4,"left",13);
            this.hzMsglogEllip(dtf,HZ_ML_W - 78);
            var uts:String = this.hzMsglogClockTxt(Number(sel.ut));
            var lts:String = Number(sel.lt) >= 0 ? this.hzMsglogClockTxt(Number(sel.lt)) : "";
            var when:String = uts.length > 0 ? "IN-GAME " + uts : "";
            if(lts.length > 0) { when += (when.length > 0 ? " + " : "") + "local " + lts; }
            var where:String = String(sel.loc).length > 0 ? String(sel.loc) : "";
            var real:String = "";
            if(Number(sel.ts) > 0)
            {
               var rd:Date = new Date(Number(sel.ts) * 1000);
               real = String(rd.getFullYear()) + "-" + (rd.getMonth() + 1 < 10 ? "0" : "") + String(rd.getMonth() + 1) + "-" + (rd.date < 10 ? "0" : "") + String(rd.date) + "  " + (rd.hours < 10 ? "0" : "") + String(rd.hours) + ":" + (rd.minutes < 10 ? "0" : "") + String(rd.minutes);
            }
            var d2:String = when;
            if(where.length > 0) { d2 += (d2.length > 0 ? "  ·  " : "") + where; }
            if(real.length > 0) { d2 += (d2.length > 0 ? "  ·  " : "") + real; }
            if(sel.later == true) { d2 += (d2.length > 0 ? "  ·  " : "") + "from a later point"; }
            var dtf2:TextField = this.hzWT(b,d2.length > 0 ? d2 : " ",ox + 28,dy + 32,HZ_ML_W - 56,13,"rg",uint(T.mut),0.3,"left",13);
            this.hzMsglogEllip(dtf2,HZ_ML_W - 56);
         }

         var foot:Number = oy + HZ_ML_H - 92;
         g.beginFill(uint(T.line),Number(T.la));
         g.drawRect(ox + 22,foot,HZ_ML_W - 44,1);
         g.endFill();
         var hx:Number = ox + 28;
         var hy:Number = foot + 10;
         var pinLab:String = (sel != null && int(sel.pin) != 0) ? "UNPIN" : "PIN";
         var hints:Array = this.hzMlPad
            ? [["LB/RB","CHIPS"],["A",pinLab],["X","SETTINGS"],["Y","CLEAR"],["B","BACK"]]
            : [["UP/DN","SELECT"],["ENTER",pinLab],["ESC","BACK"],["/","FIND"]];
         var hi:int = 0;
         while(hi < hints.length)
         {
            var hk:Number = this.hzSetKey(b,g,hx,hy,String(hints[hi][0]),uint(T.mut),22,13,13);
            this.hzWT(b,String(hints[hi][1]),hx + hk + 6,hy + 4,70,13,"sb",uint(T.mut),1.2,"left",13);
            hx += hk + 78;
            hi++;
         }
         var by:Number = foot + 48;
         var bxr:Number = ox + HZ_ML_W - 22;
         var hit0:int = this.hzSetHits.length;
         bxr -= this.hzSetBtn(b,g,bxr,by,"BACK",false,false,this.hzMlHover == "back",T,"mlback",13,13) + 10;
         bxr -= this.hzSetBtn(b,g,bxr,by,"CLEAR SESSION",false,true,this.hzMlHover == "clear",T,"mlclear",13,13) + 10;
         bxr -= this.hzSetBtn(b,g,bxr,by,pinLab,true,false,this.hzMlHover == "pin",T,"mlpin",13,13) + 10;
         this.hzSetBtn(b,g,bxr,by,"SETTINGS",false,true,this.hzMlHover == "set",T,"mlset",13,13);
         while(this.hzSetHits.length > hit0)
         {
            this.hzMlHits.push(this.hzSetHits.pop());
         }
         if(this.hzMlNotice.length > 0)
         {
            this.hzWT(b,this.hzMlNotice,ox + 28,foot + 36,400,13,"sb",uint(T.note),0.4,"left",13);
         }
         if(this.hzPopTop() == "logset" || this.hzPopTop() == "mlhist") { this.hzMsglogDrawSettings(b,g,T,acc,ox,oy); }
         if(this.hzPopTop() == "mlchars") { this.hzMsglogDrawChars(b,g,T,acc,ox,oy); }
         if(this.hzPopTop() == "mlconfirm") { this.hzMsglogDrawConfirm(b,g,T,acc,ox,oy); }
      }

      private function hzMsglogDrawConfirm(b:Sprite, g:*, T:Object, acc:uint, ox:Number, oy:Number) : void
      {
         var n:int = 0;
         var i:int = 0;
         while(i < this.hzMlRows.length)
         {
            var r:Object = this.hzMlRows[i];
            if(int(r.sess) == this.hzMlSess && int(r.pin) == 0) { n++; }
            i++;
         }
         var cw:Number = 420;
         var ch:Number = 168;
         var cx:Number = ox + Math.round((HZ_ML_W - cw) / 2);
         var cy:Number = oy + Math.round((HZ_ML_H - ch) / 2);
         g.beginFill(0x000000,0.45);
         g.drawRoundRect(ox,oy,HZ_ML_W,HZ_ML_H,36,36);
         g.endFill();
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(cx,cy,cw,ch,28,28);
         g.endFill();
         this.hz33Edge(b,cx,cy,cw,ch,28,uint(T.edge),Number(T.ea),1);
         this.hzWT(b,"Clear this session?",cx + 22,cy + 18,cw - 44,15,"bd",uint(T.txt),2,"left",13);
         this.hzWT(b,"Removes " + String(n) + " unpinned messages from this launch. Can't be undone.",cx + 22,cy + 48,cw - 44,13,"rg",uint(T.lab),0.3,"left",13);
         var br:Number = cx + cw - 22;
         var hit0:int = this.hzSetHits.length;
         br -= this.hzSetBtn(b,g,br,cy + 120,"CANCEL",false,false,this.hzMlHover == "cfcancel",T,"cfcancel",13,13) + 10;
         this.hzSetBtn(b,g,br,cy + 120,"CLEAR",true,false,this.hzMlHover == "cfok",T,"cfok",13,13);
         while(this.hzSetHits.length > hit0)
         {
            this.hzMlHits.push(this.hzSetHits.pop());
         }
      }

      private function hzMsglogTypeOn(k:String) : Boolean
      {
         if(k == null || k.length == 0) { return true; }
         var t:String = "," + this.hzMlTypes + ",";
         return t.indexOf("," + k + ",") >= 0;
      }

      private function hzMsglogTypeToggle(k:String) : void
      {
         var on:Boolean = this.hzMsglogTypeOn(k);
         var parts:Array = this.hzMlTypes.split(",");
         var out:Array = [];
         var i:int = 0;
         while(i < parts.length)
         {
            var p:String = String(parts[i]);
            if(p.length > 0 && p != k) { out.push(p); }
            i++;
         }
         if(!on) { out.push(k); }
         this.hzMlTypes = out.join(",");
         this.hzMlAct = "set|types|" + this.hzMlTypes;
         this.hzMsglogSaveIni();
      }

      private function hzMsglogSaveIni() : void
      {
         var p:Object = this.hzSetPend != null ? this.hzSetPend : this.hzSetCurrent();
         this.hzSetSaveText = this.hzBuildIniText(p);
      }

      private function hzMsglogOpenSettings() : void
      {
         if(this.hzPopTop() != "log") { return; }
         this.hzPopPush("logset");
         this.hzMlSetRow = 0;
         this.hzMlSetScroll = 0;
         this.hzMlAct = "list";
         this.hzMsglogDraw();
      }

      private function hzMsglogSetRows() : Array
      {
         var rows:Array = [
            {"id":"record","k":"record","l":"RECORD MESSAGES"},
            {"id":"persist","k":"persist","l":"SAVE TO DISK"}
         ];
         if(!this.hzMlPersist) { rows.push({"id":"folder","k":"folder","l":"FOLDER"}); }
         rows.push({"id":"history","k":"history","l":"HISTORY"});
         var i:int = 1;
         while(i < HZ_ML_KIND.length)
         {
            rows.push({"id":"type" + String(i),"k":String(HZ_ML_KIND[i]),"l":String(HZ_ML_CHIPS[i]),"type":1});
            i++;
         }
         rows.push({"id":"missed","k":"missed","l":"MISSED BADGE"});
         rows.push({"id":"old","k":"old","l":"OLD CHARACTERS"});
         return rows;
      }

      private function hzMsglogDrawSettings(b:Sprite, g:*, T:Object, acc:uint, ox:Number, oy:Number) : void
      {
         var cw:Number = HZ_MLS_W;
         var ch:Number = HZ_MLS_H;
         var cx:Number = ox + Math.round((HZ_ML_W - cw) / 2);
         var cy:Number = oy + Math.round((HZ_ML_H - ch) / 2);
         g.beginFill(0x000000,0.45);
         g.drawRoundRect(ox,oy,HZ_ML_W,HZ_ML_H,36,36);
         g.endFill();
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(cx,cy,cw,ch,28,28);
         g.endFill();
         this.hz33Edge(b,cx,cy,cw,ch,28,uint(T.edge),Number(T.ea),1);
         this.hzWT(b,"MESSAGE LOG SETTINGS",cx + 22,cy + 16,cw - 44,15,"bd",uint(T.txt),2,"left",13);
         var rows:Array = this.hzMsglogSetRows();
         var bodyY:Number = cy + 44;
         var bodyH:Number = ch - 44 - 56;
         var rowH:Number = 36;
         var vis:int = int(Math.floor(bodyH / rowH));
         if(this.hzMlSetRow < 0) { this.hzMlSetRow = 0; }
         if(this.hzMlSetRow >= rows.length) { this.hzMlSetRow = rows.length - 1; }
         if(this.hzMlSetScroll > this.hzMlSetRow) { this.hzMlSetScroll = this.hzMlSetRow; }
         if(this.hzMlSetScroll < this.hzMlSetRow - vis + 1) { this.hzMlSetScroll = this.hzMlSetRow - vis + 1; }
         if(this.hzMlSetScroll < 0) { this.hzMlSetScroll = 0; }
         var i:int = this.hzMlSetScroll;
         var n:int = 0;
         var ry:Number = bodyY;
         while(i < rows.length && n < vis)
         {
            var r:Object = rows[i];
            var sel:Boolean = i == this.hzMlSetRow;
            if(sel)
            {
               g.beginFill(acc,0.13);
               g.drawRoundRect(cx + 14,ry,cw - 28,rowH - 4,10,10);
               g.endFill();
            }
            if(r.id == "folder")
            {
               var path:String = this.hzMlFolder.length > 0 ? this.hzMlFolder : "MessageLog";
               this.hzWT(b,"Memory only. Existing files stay on disk.",cx + 22,ry + 2,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);
               var ptf:TextField = this.hzWT(b,path,cx + 22,ry + 16,cw - 44,13,"rg",uint(T.lab),0.3,"left",13);
               this.hzMsglogEllip(ptf,cw - 44);
            }
            else if(r.id == "history")
            {
               this.hzWT(b,String(r.l),cx + 22,ry + 8,200,13,"sb",uint(T.txt),1.2,"left",13);
               this.hzSetTri(g,cx + cw - 86,ry + 16,-1,acc,0.9);
               this.hzWT(b,String(this.hzMlHistory),cx + cw - 78,ry + 8,40,13,"sb",acc,0.5,"center",13);
               this.hzSetTri(g,cx + cw - 30,ry + 16,1,acc,0.9);
               this.hzMlHits.push({"id":"mlshistl","x":cx + cw - 100,"y":ry,"w":28,"h":32});
               this.hzMlHits.push({"id":"mlshistr","x":cx + cw - 44,"y":ry,"w":28,"h":32});
            }
            else if(r.id == "old")
            {
               this.hzWT(b,"OLD CHARACTERS (" + String(this.hzMlOtherN) + " FILES)",cx + 22,ry + 8,320,13,"sb",uint(T.txt),1.2,"left",13);
               var hit0:int = this.hzSetHits.length;
               this.hzSetBtn(b,g,cx + cw - 18,ry + 4,"VIEW LIST",false,true,this.hzMlHover == "mlslist",T,"mlslist",13,13);
               while(this.hzSetHits.length > hit0) { this.hzMlHits.push(this.hzSetHits.pop()); }
            }
            else if(r.type)
            {
               var mid:Number = cx + Math.round(cw / 2);
               this.hzWT(b,String(r.l),cx + 22,ry + 8,200,13,"sb",uint(T.txt),1.2,"left",13);
               this.hzSetSwitch(b,g,mid - 16,ry + 16,this.hzMsglogTypeOn(String(r.k)),T,false);
               this.hzMlHits.push({"id":"mlstype" + String(r.k),"x":cx + 14,"y":ry,"w":mid - cx - 20,"h":32});
               if(i + 1 < rows.length && rows[i + 1].type)
               {
                  var r2:Object = rows[i + 1];
                  this.hzWT(b,String(r2.l),mid + 8,ry + 8,200,13,"sb",uint(T.txt),1.2,"left",13);
                  this.hzSetSwitch(b,g,cx + cw - 22,ry + 16,this.hzMsglogTypeOn(String(r2.k)),T,false);
                  this.hzMlHits.push({"id":"mlstype" + String(r2.k),"x":mid,"y":ry,"w":cx + cw - 14 - mid,"h":32});
                  i++;
               }
            }
            else
            {
               this.hzWT(b,String(r.l),cx + 22,ry + 8,280,13,"sb",uint(T.txt),1.2,"left",13);
               var on:Boolean = r.id == "record" ? this.hzMlRecord : (r.id == "persist" ? this.hzMlPersist : this.hzMlMissed);
               this.hzSetSwitch(b,g,cx + cw - 22,ry + 16,on,T,false);
               this.hzMlHits.push({"id":"mls" + String(r.id),"x":cx + 14,"y":ry,"w":cw - 28,"h":32});
            }
            ry += rowH;
            n++;
            i++;
         }
         var foot:Number = cy + ch - 56;
         g.beginFill(uint(T.line),Number(T.la));
         g.drawRect(cx + 18,foot,cw - 36,1);
         g.endFill();
         var hx:Number = cx + 22;
         var hy:Number = foot + 8;
         if(this.hzMlPad)
         {
            this.hzSetKey(b,g,hx,hy,"A",uint(T.mut),22,13,13);
            this.hzWT(b,"TOGGLE",hx + 30,hy + 4,70,13,"sb",uint(T.mut),1.2,"left",13);
         }
         var br:Number = cx + cw - 22;
         var hit1:int = this.hzSetHits.length;
         br -= this.hzSetBtn(b,g,br,foot + 20,"BACK",false,false,this.hzMlHover == "mlsback",T,"mlsback",13,13) + 10;
         this.hzSetBtn(b,g,br,foot + 20,"CLEAR HISTORY",false,true,this.hzMlHover == "mlsclear",T,"mlsclear",13,13);
         while(this.hzSetHits.length > hit1) { this.hzMlHits.push(this.hzSetHits.pop()); }
         if(this.hzPopTop() == "mlhist") { this.hzMsglogDrawHist(b,g,T,acc,ox,oy); }
      }

      private function hzMsglogDrawHist(b:Sprite, g:*, T:Object, acc:uint, ox:Number, oy:Number) : void
      {
         var cw:Number = 420;
         var ch:Number = 168;
         var cx:Number = ox + Math.round((HZ_ML_W - cw) / 2);
         var cy:Number = oy + Math.round((HZ_ML_H - ch) / 2);
         g.beginFill(0x000000,0.45);
         g.drawRoundRect(ox,oy,HZ_ML_W,HZ_ML_H,36,36);
         g.endFill();
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(cx,cy,cw,ch,28,28);
         g.endFill();
         this.hz33Edge(b,cx,cy,cw,ch,28,uint(T.edge),Number(T.ea),1);
         this.hzWT(b,"Clear all history?",cx + 22,cy + 18,cw - 44,15,"bd",uint(T.txt),2,"left",13);
         this.hzWT(b,"Removes every unpinned message for this character. Pins stay. Can't be undone.",cx + 22,cy + 48,cw - 44,13,"rg",uint(T.lab),0.3,"left",13);
         var br:Number = cx + cw - 22;
         var hit0:int = this.hzSetHits.length;
         br -= this.hzSetBtn(b,g,br,cy + 120,"CANCEL",false,false,this.hzMlHover == "mhcancel",T,"mhcancel",13,13) + 10;
         this.hzSetBtn(b,g,br,cy + 120,"CLEAR",true,false,this.hzMlHover == "mhok",T,"mhok",13,13);
         while(this.hzSetHits.length > hit0) { this.hzMlHits.push(this.hzSetHits.pop()); }
      }

      private function hzMsglogDrawChars(b:Sprite, g:*, T:Object, acc:uint, ox:Number, oy:Number) : void
      {
         var cw:Number = 620;
         var ch:Number = 414;
         var cx:Number = ox + Math.round((HZ_ML_W - cw) / 2);
         var cy:Number = oy + Math.round((HZ_ML_H - ch) / 2);
         g.beginFill(0x000000,0.45);
         g.drawRoundRect(ox,oy,HZ_ML_W,HZ_ML_H,36,36);
         g.endFill();
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(cx,cy,cw,ch,28,28);
         g.endFill();
         this.hz33Edge(b,cx,cy,cw,ch,28,uint(T.edge),Number(T.ea),1);
         this.hzWT(b,"OLD CHARACTERS",cx + 22,cy + 16,cw - 44,15,"bd",uint(T.txt),2,"left",13);
         this.hzWT(b,"Read-only. The current character is not listed.",cx + 22,cy + 40,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);
         var i:int = 0;
         var ry:Number = cy + 68;
         if(this.hzMlOthers.length == 0)
         {
            this.hzWT(b,"No other character files.",cx + 22,ry,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);
         }
         while(i < this.hzMlOthers.length && ry < cy + ch - 64)
         {
            var oc:Object = this.hzMlOthers[i];
            this.hzWT(b,String(oc.name),cx + 22,ry,300,13,"sb",uint(T.txt),1.2,"left",13);
            this.hzWT(b,String(oc.n) + " messages",cx + cw - 22,ry,160,13,"rg",uint(T.mut),0.3,"right",13);
            ry += 28;
            i++;
         }
         var hit0:int = this.hzSetHits.length;
         this.hzSetBtn(b,g,cx + cw - 22,cy + ch - 44,"BACK",false,false,this.hzMlHover == "mlcback",T,"mlcback",13,13);
         while(this.hzSetHits.length > hit0) { this.hzMlHits.push(this.hzSetHits.pop()); }
      }

      private function hzMsglogSetToggle() : void
      {
         var rows:Array = this.hzMsglogSetRows();
         if(this.hzMlSetRow < 0 || this.hzMlSetRow >= rows.length) { return; }
         var r:Object = rows[this.hzMlSetRow];
         this.hzMsglogSetAct(String(r.id), 0);
      }

      private function hzMsglogSetAct(id:String, dir:int) : void
      {
         if(id == "record")
         {
            this.hzMlRecord = !this.hzMlRecord;
            this.hzMlAct = "set|record|" + (this.hzMlRecord ? "1" : "0");
         }
         else if(id == "persist")
         {
            this.hzMlPersist = !this.hzMlPersist;
            this.hzMlAct = "set|persist|" + (this.hzMlPersist ? "1" : "0");
         }
         else if(id == "missed")
         {
            this.hzMlMissed = !this.hzMlMissed;
            this.hzMlAct = "set|missed|" + (this.hzMlMissed ? "1" : "0");
         }
         else if(id == "history" || id == "mlshistl" || id == "mlshistr")
         {
            var step:int = (id == "mlshistl" || dir < 0) ? -100 : 100;
            if(id == "history" && dir == 0) { step = 100; }
            this.hzMlHistory = this.hzMlHistory + step;
            if(this.hzMlHistory < 100) { this.hzMlHistory = 100; }
            if(this.hzMlHistory > 1000) { this.hzMlHistory = 1000; }
            this.hzMlAct = "set|history|" + String(this.hzMlHistory);
         }
         else if(id.indexOf("type") == 0 || id.indexOf("mlstype") == 0)
         {
            var k:String = id.indexOf("mlstype") == 0 ? id.substr(7) : "";
            if(k.length == 0)
            {
               var rows:Array = this.hzMsglogSetRows();
               if(this.hzMlSetRow >= 0 && this.hzMlSetRow < rows.length && rows[this.hzMlSetRow].type)
               {
                  k = String(rows[this.hzMlSetRow].k);
               }
            }
            if(k.length > 0) { this.hzMsglogTypeToggle(k); this.hzMsglogDraw(); return; }
         }
         else if(id == "old" || id == "mlslist")
         {
            if(this.hzPopTop() == "logset") { this.hzPopPush("mlchars"); this.hzMlAct = "list"; this.hzMsglogDraw(); }
            return;
         }
         else { return; }
         this.hzMsglogSaveIni();
         this.hzMsglogDraw();
      }

      private function hzMsglogKey(code:String) : void
      {
         if(code == "up" || code == "down" || code == "left" || code == "right" || code == "ok" || code == "cancel" || code == "padx" || code == "pady" || code == "tabprev" || code == "tabnext") { this.hzMlPad = (code == "padx" || code == "pady" || code.indexOf("tab") == 0); }
         if(this.hzPopTop() == "mlhist")
         {
            if(code == "cancel") { this.hzPopPop(); this.hzMsglogDraw(); return; }
            if(code == "ok" || code == "pady") { this.hzPopPop(); this.hzMlAct = "clearhist"; this.hzMsglogDraw(); return; }
            return;
         }
         if(this.hzPopTop() == "mlchars")
         {
            if(code == "cancel" || code == "ok") { this.hzPopPop(); this.hzMsglogDraw(); return; }
            if(code == "wheelup" || code == "up") { this.hzMlSetScroll--; this.hzMsglogDraw(); return; }
            if(code == "wheeldown" || code == "down") { this.hzMlSetScroll++; this.hzMsglogDraw(); return; }
            return;
         }
         if(this.hzPopTop() == "logset")
         {
            var setN:int = this.hzMsglogSetRows().length;
            if(code == "cancel") { this.hzPopPop(); this.hzMsglogDraw(); return; }
            if(code == "up") { this.hzMlSetRow--; if(this.hzMlSetRow < 0) { this.hzMlSetRow = 0; } this.hzMsglogDraw(); return; }
            if(code == "down") { this.hzMlSetRow++; if(this.hzMlSetRow >= setN) { this.hzMlSetRow = setN - 1; } this.hzMsglogDraw(); return; }
            if(code == "left") { this.hzMsglogSetAct(String(this.hzMsglogSetRows()[this.hzMlSetRow].id), -1); return; }
            if(code == "right" || code == "ok") { this.hzMsglogSetToggle(); return; }
            if(code == "pady") { this.hzPopPush("mlhist"); this.hzMsglogDraw(); return; }
            if(code == "wheelup") { this.hzMlSetRow--; if(this.hzMlSetRow < 0) { this.hzMlSetRow = 0; } this.hzMsglogDraw(); return; }
            if(code == "wheeldown") { this.hzMlSetRow++; if(this.hzMlSetRow >= setN) { this.hzMlSetRow = setN - 1; } this.hzMsglogDraw(); return; }
            return;
         }
         if(this.hzPopTop() == "mlconfirm")
         {
            if(code == "cancel") { this.hzPopPop(); this.hzMsglogDraw(); return; }
            if(code == "ok" || code == "pady") { this.hzMsglogDoClear(); return; }
            return;
         }
         if(this.hzMlFindOn)
         {
            if(code == "cancel") { this.hzMlFindOn = false; this.hzMlFind = ""; this.hzMsglogDraw(); return; }
            if(code == "bksp")
            {
               if(this.hzMlFind.length > 0) { this.hzMlFind = this.hzMlFind.substr(0,this.hzMlFind.length - 1); this.hzMsglogDraw(); }
               return;
            }
            if(code.indexOf("ch:") == 0)
            {
               var ch:String = code.substr(3);
               if(ch.length > 0) { this.hzMlFind += ch; this.hzMsglogDraw(); }
               return;
            }
            if(code == "ok") { this.hzMlFindOn = false; this.hzMsglogDraw(); return; }
         }
         if(code == "cancel") { this.hzMsglogForceClose(); return; }
         if(code == "wheelup") { this.hzMlScroll--; this.hzMsglogDraw(); return; }
         if(code == "wheeldown") { this.hzMlScroll++; this.hzMsglogDraw(); return; }
         if(code == "tabprev") { this.hzMsglogChipStep(-1); return; }
         if(code == "tabnext") { this.hzMsglogChipStep(1); return; }
         if(code == "up") { this.hzMsglogSelStep(-1); return; }
         if(code == "down") { this.hzMsglogSelStep(1); return; }
         if(code == "ok") { this.hzMsglogDoPin(); return; }
         if(code == "padx") { this.hzMsglogOpenSettings(); return; }
         if(code == "pady") { this.hzMsglogAskClear(); return; }
         if(code.indexOf("ch:") == 0 && code.substr(3) == "/") { this.hzMlFindOn = true; this.hzMsglogDraw(); return; }
         if(code == "bksp" && this.hzMlFind.length > 0) { this.hzMlFindOn = true; this.hzMsglogDraw(); }
      }

      private function hzMsglogChipStep(dir:int) : void
      {
         this.hzMlChip = (this.hzMlChip + dir + HZ_ML_CHIPS.length) % HZ_ML_CHIPS.length;
         this.hzMlScroll = 0;
         this.hzMsglogDraw();
      }

      private function hzMsglogSelStep(dir:int) : void
      {
         var list:Array = this.hzMsglogList();
         var ids:Array = [];
         var i:int = 0;
         while(i < list.length)
         {
            if(!list[i].g) { ids.push(Number(list[i].id)); }
            i++;
         }
         if(ids.length == 0) { return; }
         var at:int = 0;
         i = 0;
         while(i < ids.length)
         {
            if(Number(ids[i]) == this.hzMlSelId) { at = i; break; }
            i++;
         }
         at += dir;
         if(at < 0) { at = 0; }
         if(at >= ids.length) { at = ids.length - 1; }
         this.hzMlSelId = Number(ids[at]);
         var visAt:int = 0;
         i = 0;
         while(i < list.length)
         {
            if(!list[i].g && Number(list[i].id) == this.hzMlSelId) { visAt = i; break; }
            i++;
         }
         if(visAt < this.hzMlScroll) { this.hzMlScroll = visAt; }
         if(visAt >= this.hzMlScroll + HZ_ML_VIS) { this.hzMlScroll = visAt - HZ_ML_VIS + 1; }
         this.hzMsglogDraw();
      }

      private function hzMsglogDoPin() : void
      {
         if(this.hzMlSelId == 0) { return; }
         var pinned:Boolean = false;
         var i:int = 0;
         while(i < this.hzMlRows.length)
         {
            if(Number(this.hzMlRows[i].id) == this.hzMlSelId) { pinned = int(this.hzMlRows[i].pin) != 0; break; }
            i++;
         }
         if(!pinned && this.hzMlPinN >= this.hzMlPinCap)
         {
            this.hzMlNotice = "Pin limit reached (50)";
            this.hzMsglogDraw();
            return;
         }
         this.hzMlNotice = "";
         this.hzMlAct = (pinned ? "unpin|" : "pin|") + String(this.hzMlSelId);
      }

      private function hzMsglogAskClear() : void
      {
         if(this.hzPopTop() != "log") { return; }
         this.hzPopPush("mlconfirm");
         this.hzMsglogDraw();
      }

      private function hzMsglogDoClear() : void
      {
         if(this.hzPopTop() == "mlconfirm") { this.hzPopPop(); }
         this.hzMlAct = "clearsess";
         this.hzMsglogDraw();
      }

      private function hzMsglogHit(mx:Number, my:Number) : Object
      {
         var i:int = this.hzMlHits.length - 1;
         while(i >= 0)
         {
            var h:Object = this.hzMlHits[i];
            if(mx >= h.x && mx <= h.x + h.w && my >= h.y && my <= h.y + h.h) { return h; }
            i--;
         }
         return null;
      }

      private function hzMsglogMouse(nx:Number, ny:Number, down:Boolean) : void
      {
         if(!this.HorizonSettings_mc || isNaN(nx) || isNaN(ny)) { return; }
         var vr:Rectangle = Extensions.visibleRect;
         var gp:Point = (vr != null && vr.width >= 1) ? new Point(vr.x + nx * vr.width,vr.y + ny * vr.height) : new Point(nx * 1920,ny * 1080);
         var lp:Point = globalToLocal(gp);
         var mx:Number = lp.x - this.HorizonSettings_mc.x;
         var my:Number = lp.y - this.HorizonSettings_mc.y;
         this.hzMlPad = false;
         this.hzSetDrawCursor();
         this.hzSetCursor.x = mx;
         this.hzSetCursor.y = my;
         this.hzSetCursor.visible = true;
         var hit:Object = this.hzMsglogHit(mx,my);
         this.hzMlHover = hit != null ? String(hit.id) : "";
         var pressed:Boolean = down && !this.hzSetPrevDown;
         this.hzSetPrevDown = down;
         if(!pressed) { this.hzMsglogDraw(); return; }
         if(this.hzPopTop() == "mlconfirm")
         {
            if(this.hzMlHover == "cfok") { this.hzMsglogDoClear(); return; }
            if(this.hzMlHover == "cfcancel" || this.hzMlHover == "") { this.hzPopPop(); this.hzMsglogDraw(); }
            return;
         }
         if(this.hzPopTop() == "mlhist")
         {
            if(this.hzMlHover == "mhok") { this.hzPopPop(); this.hzMlAct = "clearhist"; this.hzMsglogDraw(); return; }
            if(this.hzMlHover == "mhcancel" || this.hzMlHover == "") { this.hzPopPop(); this.hzMsglogDraw(); }
            return;
         }
         if(this.hzPopTop() == "mlchars")
         {
            if(this.hzMlHover == "mlcback" || this.hzMlHover == "") { this.hzPopPop(); this.hzMsglogDraw(); }
            return;
         }
         if(this.hzPopTop() == "logset")
         {
            if(this.hzMlHover == "mlsback") { this.hzPopPop(); this.hzMsglogDraw(); return; }
            if(this.hzMlHover == "mlsclear") { this.hzPopPush("mlhist"); this.hzMsglogDraw(); return; }
            if(this.hzMlHover == "mlslist") { this.hzMsglogSetAct("old", 0); return; }
            if(this.hzMlHover == "mlshistl") { this.hzMsglogSetAct("mlshistl", -1); return; }
            if(this.hzMlHover == "mlshistr") { this.hzMsglogSetAct("mlshistr", 1); return; }
            if(this.hzMlHover.indexOf("mlstype") == 0) { this.hzMsglogSetAct(this.hzMlHover, 0); return; }
            if(this.hzMlHover.indexOf("mls") == 0) { this.hzMsglogSetAct(this.hzMlHover.substr(3), 0); return; }
            return;
         }
         if(hit == null) { return; }
         var id:String = String(hit.id);
         if(id.indexOf("chip") == 0) { this.hzMlChip = int(id.substr(4)); this.hzMlScroll = 0; this.hzMsglogDraw(); return; }
         if(id.indexOf("row") == 0) { this.hzMlSelId = Number(hit.rid); this.hzMsglogDraw(); return; }
         if(id == "find") { this.hzMlFindOn = true; this.hzMsglogDraw(); return; }
         if(id == "alltime") { this.hzMlAllTime = !this.hzMlAllTime; this.hzMlScroll = 0; this.hzMsglogDraw(); return; }
         if(id == "mlpin") { this.hzMsglogDoPin(); return; }
         if(id == "mlclear") { this.hzMsglogAskClear(); return; }
         if(id == "mlset") { this.hzMsglogOpenSettings(); return; }
         if(id == "mlback") { this.hzMsglogForceClose(); return; }
      }

      public function hzToggleSettings() : void
      {
         if(!this.hzSetIsOpen && !this.hzArrange && this.hz40F11Block()) { return; }   // v0.42.0: F11 opens from the main HUD only (never while scanning)
         if(this.hzPopLayers != null && this.hzPopLayers.length > 0) { this.hzPopLayers = []; }
         if(this.hzArrange) { this.hzArrExit(false); return; }
         if(this.hzSetIsOpen) { this.hzSetCancel(); return; }
         try { this.hz30ModProbeAll(); } catch(errMod:Error) { }
         this.hzSetOrig = this.hzSetCurrent();
         this.hzSetPend = this.hzSetCurrent();
         this.hzSetTab = 0;
         this.hzSetRow = 0;
         this.hzSetScroll = 0;
         this.hzSetDrag = -1;
         this.hzSetHover = "";
         if(this.HorizonSettings_mc == null)
         {
            this.HorizonSettings_mc = new Sprite();
            this.hzSetBody = new Sprite();
            this.HorizonSettings_mc.addChild(this.hzSetBody);
            this.hzSetCursor = new Sprite();
            this.HorizonSettings_mc.addChild(this.hzSetCursor);
            this.HorizonSettings_mc.mouseEnabled = false;
            this.HorizonSettings_mc.mouseChildren = false;
         }
         this.hzSetIsOpen = true;
         addChild(this.HorizonSettings_mc); // re-add = topmost, above every Horizon card
         this.HorizonSettings_mc.visible = true;
         this.hzSetCursor.visible = false;
         this.hzSetPlace();
         this.hzSetDraw();
      }

      // CANCEL: revert the live preview to the values captured at open.
      private function hzSetCancel() : void
      {
         if(this.hzSetOrig) { this.hzSetLive(this.hzSetOrig); }
         this.hzSetClose();
      }

      private function hzSetClose() : void
      {
         this.hzSetIsOpen = false;
         try { this.hz37Reset(); } catch(e37r:Error) { }
         this.hzSetPend = null;
         this.hzSetOrig = null;
         this.hzSetDrag = -1;
         if(this.HorizonSettings_mc) { this.HorizonSettings_mc.visible = false; }
         if(this.hzSetCursor) { this.hzSetCursor.visible = false; }
      }

      public function hzTakeSaveIni() : String
      {
         // v0.30: re-read the file, then hand over the generated text merged into it: only the HUD's own sections /
         // keys are replaced, every other section ([Scanner], [Comms], ...), key and comment stays as it is
         if(!this.hzSetSaveText) { return ""; }
         var now:Number = new Date().getTime();
         if(this.hz30Wait == 0) { this.hz30WaitT = now; this.hz30Fetch(); return ""; }
         if(this.hz30Wait == 1 && now - this.hz30WaitT < 900) { return ""; }
         var base:String = this.hz30Wait == 2 ? this.hz30Fresh : this.hz30IniRaw;
         var gen:String = this.hzSetSaveText;
         this.hzSetSaveText = "";
         this.hz30Wait = 0;
         this.hz30Fresh = null;
         var r:String = null;
         try { r = this.hz30Merge(base,gen); } catch(errM:Error) { r = null; }
         if(r == null || r.length == 0) { return ""; }   // never fall back to a full rewrite (it would drop other modules' sections)
         this.hz30IniRaw = r;
         return r;
      }

      private function hzSetPlace() : void
      {
         var cx:Number = 960;
         var cy:Number = 540;
         var vr:Rectangle = Extensions.visibleRect;
         if(vr != null && vr.width >= 100 && stage != null)
         {
            var tl:Point = globalToLocal(new Point(vr.left,vr.top));
            var br:Point = globalToLocal(new Point(vr.right,vr.bottom));
            if(!isNaN(tl.x) && br.x - tl.x >= 100) { cx = (tl.x + br.x) / 2; cy = (tl.y + br.y) / 2; }
         }
         this.HorizonSettings_mc.x = Math.round(cx - HZ_SET_W / 2);
         this.HorizonSettings_mc.y = Math.round(cy - HZ_SET_H / 2);
      }

      public function hzSettingsKey(code:String) : void
      {
         this.hz35Kb = true;   // v0.35: keys / controller -> the selected row shows its info
         if(this.hzPopLayers != null && this.hzPopLayers.length > 0) { this.hzPopKey(code); return; }   // 0.43.0.1: only the top layer
         if(this.hzArrange) { this.hzArrKey(code); return; }
         if(!this.hzSetIsOpen) { return; }
         if(this.hz37Key(code)) { this.hzSetDraw(); return; }   // v0.37: preset name entry / pending confirm
         if(code.indexOf("ch:") == 0 || code == "bksp") { return; }
         var rows:Array = this.hzSetRows(this.hzSetTab);
         switch(code)
         {
            case "up": this.hz30RowStep(rows,-1); break;
            case "down": this.hz30RowStep(rows,1); break;
            case "left": this.hzSetChange(rows[this.hzSetRow],-1); break;
            case "right": this.hzSetChange(rows[this.hzSetRow],1); break;
            case "tabprev": this.hzSetTab = (this.hzSetTab + HZ_SET_TABS.length - 1) % HZ_SET_TABS.length; this.hzSetRow = 0; this.hzSetScroll = 0; break;
            case "tabnext": this.hzSetTab = (this.hzSetTab + 1) % HZ_SET_TABS.length; this.hzSetRow = 0; this.hzSetScroll = 0; break;
            // optional codes (a plugin build that forwards the mouse wheel); the selection follows the view
            case "wheelup": this.hzSetScrollBy(-1); break;
            case "wheeldown": this.hzSetScrollBy(1); break;
            case "ok": this.hzSetApply(); return;
            case "cancel": this.hzSetCancel(); return;
            default: return;
         }
         this.hzSetDraw();
      }

      private function hzSetChange(r:Object, dir:int) : void
      {
         if(r == null || this.hzSetPend == null) { return; }
         if(r.dis) { return; }   // v0.30: locked (module not installed / font missing) rows never change
         if(String(r.k).indexOf("_hz37") == 0) { this.hz37Act(r,dir); return; }   // v0.37 presets / backup
         if(r.t == "m") { this.hz34NoteCmp = !this.hz34NoteCmp; this.hzSetPend.ModuleNoteCompact = this.hz34NoteCmp ? 1 : 0; return; }   // v0.34 fold
         if(r.t == "z") { this.hz34ZStep(String(r.k),dir); return; }
         var k:String = r.k;
         if(k == "_hz31page") { this.hz31Page = 1 - this.hz31Page; this.hzSetPend[k] = this.hz31Page; this.hzSetScroll = 0; return; }
         if(r.t == "b") { this.hzSetPend[k] = !this.hzSetPend[k]; }
         else if(r.t == "n")
         {
            var v:Number = Number(this.hzSetPend[k]) + dir * r.st;
            this.hzSetPend[k] = this.hzSetSnap(v,r);
         }
         else if(r.t == "a") { var pn:int = (r.pal as Array).length; this.hzSetPend[k] = (int(this.hzSetPend[k]) + dir + pn) % pn; }
         else if(r.t == "r" && r.ids != undefined && r.ids != null)
         {
            var rids:Array = r.ids as Array;
            var ri:int = rids.indexOf(int(this.hzSetPend[k]));
            if(ri < 0) { ri = 0; }
            this.hzSetPend[k] = int(rids[(ri + dir + rids.length) % rids.length]);
         }
         else if(r.t == "r") { var rn:int = (r.opts as Array).length; this.hzSetPend[k] = (int(this.hzSetPend[k]) + dir + rn) % rn; }
         else if(r.t == "l")
         {
            var lv:Array = r.vals as Array;
            var lx:int = this.hzSetListIdx(r,this.hzSetPend[k]);
            this.hzSetPend[k] = lv[(lx + dir + lv.length) % lv.length];
         }
         else if(r.t == "q")
         {
            var ids:Array = r.ids as Array;
            var qi:int = ids.indexOf(int(this.hzSetPend[k]));
            if(qi < 0) { qi = 0; }
            this.hzSetPend[k] = int(ids[(qi + dir + ids.length) % ids.length]);
         }
         else if(r.t == "x")
         {
            if(r.k == "_arrange") { this.hzArrEnter(); return; }
            if(r.k == "_msglog") { this.hzMsglogOpen(); return; }
            if(r.k == "_hz41arrscan") { this.hz41SAEnter(); return; }   // v0.41.0: ARRANGE SCANNER
            if(r.k == "_hz31usesub") { this.hzSetPend.SubAutoPause = false; }
            else if(r.k == "_hz31usedlg") { this.hzSetPend.DlgAutoPause = false; }
            else if(r.k == "_hz31gocomms") { this.hzSetTab = 8; this.hzSetRow = 0; this.hzSetScroll = 0; return; }
            else if(r.k == "_hz40goscan") { this.hzSetTab = 7; this.hzSetRow = 0; this.hzSetScroll = 0; return; }
            else if(r.k == "_hz42scrst") { this.hzSetPend.ScopeChipX = 0; this.hzSetPend.ScopeChipY = 0; this.hzSetPend.ScopeChipScale = 1; }   // v0.42.0 r2
            else if(r.k == "_hz40rstlay") { this.hz40Reset(true); }
            else if(r.k == "_hz40rstall") { this.hz40Reset(false); }
            else { return; }
         }
         else if(r.t == "c")
         {
            var i:int = HZ_SET_KEYS.indexOf(String(this.hzSetPend[k]));
            if(i < 0) { i = 10; }
            this.hzSetPend[k] = HZ_SET_KEYS[(i + dir + HZ_SET_KEYS.length) % HZ_SET_KEYS.length];
         }
         this.hzSetLive(this.hzSetPend);
      }

      private function hzSetSnap(v:Number, r:Object) : Number
      {
         v = Math.round((v - r.mn) / r.st) * r.st + r.mn;
         v = Math.max(r.mn,Math.min(r.mx,v));
         return Math.round(v * 1000) / 1000;
      }

      private function hzSetNum(v:Number) : String
      {
         var s:String = String(Math.round(v * 1000) / 1000);
         if(s.indexOf(".") < 0) { s += ".0"; }
         return s;
      }

      private function hzB(o:Object) : String
      {
         return o ? "1" : "0";
      }

      // OK: values are already live (preview); save INI text and close.
      private function hzSetApply() : void
      {
         var p:Object = this.hzSetPend;
         if(p == null) { this.hzSetClose(); return; }
         this.hzSetLive(p);
         this.hzSetSaveText = this.hzBuildIniText(p);
         this.hzSetClose();
      }

      // Push a settings object into the live vars and run every apply path (live preview / revert).
      private function hzSetLive(p:Object) : void
      {
         if(p == null) { return; }
         this.hzShowJetpack = p.ShowJetpack;
         this.hzJetpackAutoHide = p.JetpackAutoHide;
         this.hzShowVitals = p.ShowVitals;
         this.hzShowPlanet = p.ShowPlanet;
         this.hzShowAfflictions = p.ShowAfflictions;
         this.hzAfflAutoHide = p.AfflictionsAutoHide;
         this.hzShowAmmo = p.ShowAmmo;
         this.hzAmmoOnlyWhenDrawn = p.AmmoOnlyWhenDrawn;
         this.hzShowQuests = p.ShowQuests;
         this.hzShowCompass = p.ShowCompass;
         if(p.VehicleExitPill !== undefined) { this.hzVehOn = p.VehicleExitPill === true || Number(p.VehicleExitPill) >= 0.5; }
         this.hzShowCompassMarkers = p.CompassMarkers;
         this.hzCmpFollowers = p.ShowFollowers;
         var rd:Boolean = false;
         if(p.TextTone != undefined && this.hzTextTone != int(p.TextTone)) { this.hzTextTone = int(p.TextTone); rd = true; }
         if(p.FontFace != undefined && this.hzFontFace != Math.max(0,Math.min(3,int(p.FontFace)))) { this.hzFontFace = Math.max(0,Math.min(3,int(p.FontFace))); rd = true; }
         if(Math.abs(this.hzCardOpacity - Number(p.CardOpacity)) > 0.001) { this.hzCardOpacity = Number(p.CardOpacity); rd = true; }
         if(p.ContainerOpacity != undefined && !isNaN(Number(p.ContainerOpacity)) && Math.abs(this.hzContOpacity - Number(p.ContainerOpacity)) > 0.001) { this.hzContOpacity = Math.max(0.2,Math.min(1.6,Number(p.ContainerOpacity))); this.hzT19Sig = ""; }
         if(p.ShowTarget != undefined) { this.hzShowTarget = Boolean(p.ShowTarget); }
         if(p.TargetAnchor != undefined) { this.hzTgAnchor = int(p.TargetAnchor); }
         if(p.TargetShowValue != undefined) { this.hzTgShowValue = Boolean(p.TargetShowValue); }
         this.hzTgDirty = true;
         if(!this.hzShowTarget) { this.hzTgRestore(); }
         if(p.TimeDisplay != undefined && this.hzTimeDisplay != int(p.TimeDisplay)) { this.hzTimeDisplay = Math.max(0,Math.min(3,int(p.TimeDisplay))); this.hzPpLayout(); }
         if(p.ClockFormat != undefined && this.hzClockFmt != int(p.ClockFormat)) { this.hzClockFmt = Math.max(0,Math.min(1,int(p.ClockFormat))); this.hzPpLayout(); }
         if(p.TempUnit != undefined && this.hzTempUnit != int(p.TempUnit))
         {
            this.hzTempUnit = Math.max(0,Math.min(1,int(p.TempUnit)));
            if(this.hzEnvTemp != null && !isNaN(this.hzEnvTempC)) { this.hzEnvTemp.text = this.hzTempText(this.hzEnvTempC); }
            this.hzPpLayout();
         }
         if(p.AfflictionLayout != undefined && this.hzAfLayout != int(p.AfflictionLayout)) { this.hzAfLayout = Math.max(0,Math.min(2,int(p.AfflictionLayout))); this.hzAfSync(); this.hzLaidOut = false; }
         if(p.PlanetDetails != undefined && this.hzPlanDetails != Boolean(p.PlanetDetails)) { this.hzPlanDetails = Boolean(p.PlanetDetails); this.hzPpLayout(); }
         if(rd) { this.hzRedrawBodies(); if(this.hzEqKind.length > 0) { this.hzEqDrawWeapIcon(this.hzEqKind); } this.hzEqDrawAmmoIcon(); }
         this.hzCmpLocations = p.ShowLocations;
         this.hzCmpShip = p.ShowShip;
         this.hzCmpEnemies = p.ShowEnemies;
         this.hzCmpPlayerMark = p.ShowPlayerMarker;
         this.hzMargin = Number(p.Margin);
         this.hzCompact = p.Compact;
         this.hzSmoothBars = p.SmoothBars;
         this.hzFadeCards = p.FadeCards;
         this.hzCombatDim = p.CombatDim;
         this.hzDimAlpha = Number(p.DimOpacity);
         this.hzHazardAlert = p.HazardAlert;
         this.hzSettingsKeyName = String(p.SettingsKey);
         this.hzAutoCenterVitals = p.AutoCenterVitals;
         this.hzRuleJetpack = int(p.JetpackRule);
         this.hzRuleVitals = int(p.VitalsRule);
         this.hzRulePlanet = int(p.PlanetRule);
         this.hzRuleAffl = int(p.AfflictionsRule);
         this.hzRuleAmmo = int(p.AmmoRule);
         this.hzRuleQuests = int(p.QuestsRule);
         this.hzRuleCompass = int(p.CompassRule);
         this.hzDrawMag();
         if(p.CrosshairStyle != undefined && !isNaN(Number(p.CrosshairStyle))) { this.hzXhStyle = Math.max(0,Math.min(3,int(p.CrosshairStyle))); this.hzXhSig = ""; }
         if(p.ObjectRing != undefined && !isNaN(Number(p.ObjectRing))) { this.hzObjRing = Math.max(0,Math.min(2,int(p.ObjectRing))); }
         if(p.ContainerScale != undefined && !isNaN(Number(p.ContainerScale))) { this.hzTgScale = this.hz34ScClamp(p.ContainerScale); this.hzT19Sig = ""; }
         if(p.ScreenHeight != undefined && !isNaN(Number(p.ScreenHeight))) { var nsh0:Number = Number(p.ScreenHeight); this.hzScrH = nsh0 >= 360 && nsh0 <= 4320 ? int(nsh0) : 0; }
         var nts:Number = Math.max(0.8,Math.min(1.3,Number(p.TextScale)));
         var nhs:int = Math.max(0,Math.min(1,int(p.HeaderStyle)));
         var nsh:Boolean = Boolean(p.TextShadow);
         if(isNaN(nts)) { nts = 1; }
         if(nts != this.hzTextScale || nhs != this.hzHeaderStyle || nsh != this.hzTextShadow)
         {
            this.hzTextScale = nts;
            this.hzHeaderStyle = nhs;
            this.hzTextShadow = nsh;
            this.hzApplyTypo();
         }
         if(this.hzAccentChoice != int(p.AccentColor) || HZ_ACCENT != this.hzAccentOf(int(p.AccentColor)))
         {
            this.hzAccentChoice = int(p.AccentColor);
            this.hzApplyAccentLive();
         }
         if(!this.hzHazardAlert && this.hzPlanAlertOn)
         {
            this.hzPlanAlertOn = false;
            if(this.hzPlanAlert) { this.hzPlanAlert.graphics.clear(); }
         }
         if(this.hzCardColor != int(p.CardColor))
         {
            this.hzCardColor = int(p.CardColor);
            this.hzRedrawBodies();
            this.hzApplyTypo();
         }
         try { this.hzDrawCompassMarkers(); } catch(err:Error) { }
         if(this.hzHudScale != Number(p.HudScale))
         {
            this.hzHudScale = Number(p.HudScale);
            this.hzApplyScale();
         }
         else
         {
            this.hzLaidOut = this.hzLayout();
         }
         try { this.hz26SetLive(p); } catch(err26:Error) { }
         try { this.hz31SetLive(p); } catch(err31:Error) { }
         try { this.hz34SetLive(p); } catch(err34:Error) { }
         try { this.hz40SetLive(p); } catch(err40:Error) { }
         try { this.hz42ScSetLive(p); } catch(err42l:Error) { }   // v0.42.0 r2: [Scope] (live preview / cancel)
         this.hzRefreshVisibility();
      }

      private function hzBuildIniText(p:Object) : String
      {
         var a:Array = [];
         a.push("; Horizon UI - HUD module settings");
         a.push("; 1 = on, 0 = off. Change in-game with F11 (settings window).");
         a.push("");
         a.push("[Hotkeys]");
         a.push("; Settings menu key (needs the Horizon SFSE helper). Default F11. Takes effect after restart. F11 opens from the main HUD only (not while the scanner or a full-screen menu is open).");
         a.push("SettingsKey=" + p.SettingsKey);
         a.push("");
         a.push("[Cards]");
         a.push("; Card on/off. When each card shows is set in [Rules].");
         for each(var k:String in ["ShowJetpack","ShowVitals","ShowPlanet","ShowAfflictions","ShowAmmo","ShowQuests","ShowCompass"])
         {
            a.push(k + "=" + this.hzB(p[k]));
         }
         a.push("; Vehicle exit prompt: 1 = Horizon pill (the key the game shows, EXIT, a hold sweep). 0 = the game's prompt.");
         a.push("VehicleExitPill=" + this.hzB(p.VehicleExitPill !== undefined ? p.VehicleExitPill : this.hzVehOn));
         a.push("; Planet pill: extra GRAV / AIR line");
         a.push("PlanetDetails=" + this.hzB(p.PlanetDetails));
         a.push("; Target card (restyled activate prompt). 0 = vanilla prompt untouched. Scanner / inventory prompts always stay vanilla");
         a.push("ShowTarget=" + this.hzB(p.ShowTarget));
         a.push("; Target anchor: 0 crosshair (frames the game's button bar), 1 follow the target on screen");
         a.push("TargetAnchor=" + int(p.TargetAnchor));
         a.push("TargetShowValue=" + this.hzB(p.TargetShowValue));
         a.push("; ShowAmmo = the EQUIPMENT card (always the v0.26 layout: A normally, C in compact mode)");
         this.hz34IniLines(a,p);
         a.push("");
         a.push("[Compass]");
         a.push("; Master switch for markers on the Horizon compass (quest objectives always show when on)");
         a.push("CompassMarkers=" + this.hzB(p.CompassMarkers));
         for each(var ck:String in ["ShowFollowers","ShowLocations","ShowShip","ShowEnemies","ShowPlayerMarker"])
         {
            a.push(ck + "=" + this.hzB(p[ck]));
         }
         a.push("; Follower / companion marker color: 0 bright green (#5CFF7A), 1 lime, 2 gold, 3 pink, 4 white, 5 mint (pre-v0.27)");
         a.push("FollowerColor=" + int(p.FollowerColor));
         a.push("");
         a.push("[Style]");
         a.push("; Card opacity 0.2 - 1.6 (above 1.0: fully opaque, then darker on dark cards / brighter on light cards)");
         a.push("CardOpacity=" + this.hzSetNum(Number(p.CardOpacity)));
         a.push("; Container / crosshair card opacity 0.2 - 1.6 (target tag, container list, item card); CardOpacity is for the HUD cards");
         a.push("ContainerOpacity=" + this.hzSetNum(Number(p.ContainerOpacity != undefined ? p.ContainerOpacity : 1)));
         a.push("; Text tone: 0 auto (dark text on light cards), 1 always light text, 2 always dark text");
         a.push("TextTone=" + int(p.TextTone));
         a.push("; Font: 1 Exo 2 (default), 2 Roboto, 0 game font, 3 game font semibold (built into the game, nothing to install). Exo 2 / Roboto need Interface/fonts_horizon.swf + fontconfig; the game font is used if missing");
         a.push("FontFace=" + int(p.FontFace));
         a.push("; Planet card time: 0 off, 1 LOCAL planet time (GAME hh:mm UT where there is no local day), 2 PC/REAL clock, 3 both");
         a.push("TimeDisplay=" + int(p.TimeDisplay));
         a.push("; Clock format for LOCAL and PC: 0 12-hour (AM/PM), 1 24-hour (GAME UT is always 24-hour, like the game)");
         a.push("ClockFormat=" + int(p.ClockFormat));
         a.push("; Temperature units on the planet card and scanner: 0 Celsius, 1 Fahrenheit (default Celsius)");
         a.push("TempUnit=" + int(p.TempUnit != undefined ? p.TempUnit : this.hzTempUnit));
         a.push("; Afflictions: 0 column of chips, 1 row, 2 icons only");
         a.push("AfflictionLayout=" + int(p.AfflictionLayout));
         a.push("; 0 cyan, 1 teal, 2 amber, 3 violet, 4 lime, 5 white, 6 rose, 7 orange, 8 sky, 9 gold, 10 mint, 11 steel, 12 deep blue, 13 custom (AccentHex)");
         a.push("AccentColor=" + int(p.AccentColor));
         a.push("; Optional custom accent, e.g. AccentHex=#FF8800 (leave empty for none)");
         a.push("AccentHex=" + (this.hzAccentHex >= 0 ? this.hzHex(this.hzAccentHex) : ""));
         a.push("; Card background: 0 slate, 1 graphite, 2 navy, 3 deep teal, 4 plum, 5 crimson, 6 storm gray,");
         a.push(";   7 light gray, 8 white, 9 pale blue, 10 pale amber, 11 pale mint, 12 custom (CardHex). Light cards use dark text.");
         a.push("CardColor=" + int(p.CardColor));
         a.push("; Optional custom card color, e.g. CardHex=#E8ECEF (leave empty for none)");
         a.push("CardHex=" + (this.hzCardHex >= 0 ? this.hzHex(this.hzCardHex) : ""));
         a.push("; Size of all Horizon cards 0.7 - 1.4");
         a.push("HudScale=" + this.hzSetNum(Number(p.HudScale)));
         a.push("SmoothBars=" + this.hzB(p.SmoothBars));
         a.push("FadeCards=" + this.hzB(p.FadeCards));
         a.push("CombatDim=" + this.hzB(p.CombatDim));
         a.push("; Opacity of cards out of combat when CombatDim=1");
         a.push("DimOpacity=" + this.hzSetNum(Number(p.DimOpacity)));
         a.push("HazardAlert=" + this.hzB(p.HazardAlert));
         a.push("Compact=" + this.hzB(p.Compact));
         a.push("; Distance of cards from the screen edges (20 - 200). Every card follows it: default spots sit this far in, cards moved");
         a.push(";   in ARRANGE CARDS keep their distance from this line at their nearest edge. The compass top follows it too.");
         a.push("Margin=" + int(Math.round(Number(p.Margin))));
         a.push("; Size of all Horizon text 0.8 - 1.3 (on top of HudScale)");
         a.push("TextScale=" + this.hzSetNum(Number(p.TextScale)));
         a.push("; Size of the container window (full item list): -1 = GLOBAL (HudScale), 0.60 - 1.60 = its own size (v0.34; set in F11 > CARDS)");
         a.push("ContainerScale=" + this.hz34ScStr(p.ContainerScale));
         a.push("; Size of the hover cards (activate prompt, loose item / take card, compare, enemy tag): -1 = GLOBAL, 0.60 - 1.60");
         a.push("HoverScale=" + this.hz34ScStr(p.HoverScale != undefined ? p.HoverScale : this.hz30Hover));
         a.push("; Your vertical screen resolution (e.g. 1440) so crosshair cards snap to whole pixels; 0 = off");
         a.push("ScreenHeight=" + int(p.ScreenHeight));
         a.push("; Crosshair while aiming at something you can use: 0 vanilla ring, 1 Horizon dot, 2 Horizon cross, 3 none");
         a.push("CrosshairStyle=" + int(p.CrosshairStyle));
         a.push("; Ring + leader line around the object you look at: 0 off, 1 container lists only, 2 vanilla");
         a.push("ObjectRing=" + int(p.ObjectRing));
         a.push("; Card titles: 0 CAPS + letter-spaced, 1 Title Case with tight spacing");
         a.push("HeaderStyle=" + int(p.HeaderStyle));
         a.push("; Hard 1px text shadow (no blur). 0 = off (sharpest, default), 1 = on (helps over bright scenery)");
         a.push("TextShadow=" + this.hzB(p.TextShadow));
         a.push("");
         this.hz26IniLines(a,p);
         a.push("[Rules]");
         a.push("; One rule per card - when it shows:");
         a.push(";   0 always, 1 combat only, 2 hide in ship, 3 weapon drawn only (Equipment),");
         a.push(";   4 in use / not full (Jetpack), 5 HP or O2 below 100% (Vitals), 6 only when afflicted (Afflictions)");
         a.push(";   Character card: 0 always, 7 on XP / level up / credits / skill point (then fades), 8 when overweight, 9 7 or 8, 1, 2");
         a.push("; Replaces the old JetpackAutoHide / AfflictionsAutoHide / AmmoOnlyWhenDrawn keys (AmmoRule = Equipment card).");
         a.push("RulesVersion=2");
         for each(var rk:String in ["JetpackRule","VitalsRule","PlanetRule","AfflictionsRule","AmmoRule","QuestsRule","CompassRule","CharacterRule"])
         {
            a.push(rk + "=" + int(p[rk]));
         }
         a.push("; Seconds the character card stays after an XP / level / credits event (rules 7 and 9), 2 - 60");
         a.push("CharacterShowSeconds=" + String(Math.round(this.hz27CharSecs * 10) / 10));
         a.push("; Vitals slide to the exact center when the Equipment card is hidden (ignored if the vitals card was moved)");
         a.push("AutoCenterVitals=" + this.hzB(p.AutoCenterVitals));
         a.push("");
         a.push("[Layout]");
         a.push("; Card positions from ARRANGE CARDS, anchored to the nearest edge (v0.30): X = L / R / C + offset, Y = T / B / C + offset,");
         a.push(";   offset in 1080p units from the Screen Margin line (C = from the screen center). -1 = default spot.");
         a.push(";   Old 0-1 fractions are still read and converted on the next save.");
         for each(var lk:String in HZ_LAY_KEYS)
         {
            var lp:Object = this.hzLay[lk];
            a.push(lk + "X=" + (lp ? this.hz30PosStr(lp,"x") : "-1"));
            a.push(lk + "Y=" + (lp ? this.hz30PosStr(lp,"y") : "-1"));
         }
         a.push("; ARRANGE CARDS toolbar: offset from its default spot (1080p units), set by dragging it");
         a.push("ArrangeBarX=" + String(Math.round(this.hzArrTbDX)));
         a.push("ArrangeBarY=" + String(Math.round(this.hzArrTbDY)));
         a.push("");
         a.push("[UI]");
         a.push("; v0.34: 1 = the module status card on the SCANNER / COMMS tabs is folded to one line (click it in F11)");
         a.push("ModuleNoteCompact=" + (Number(p.ModuleNoteCompact) >= 0.5 || p.ModuleNoteCompact === true ? "1" : "0"));
         a.push("");
         try { this.hz31IniLines(a,p); } catch(err31w:Error) { }
         try { this.hz40ScanIniLines(a,p); } catch(err40w:Error) { }
         try { this.hz42ScIniLines(a,p); } catch(err42w:Error) { }   // v0.42.0 r2: [Scope]
         a.push("[MessageLog]");
         a.push("Record=" + (this.hzMlRecord ? "1" : "0"));
         a.push("LogTypes=" + this.hzMlTypes);
         a.push("HistorySize=" + String(this.hzMlHistory));
         a.push("MissedBadge=" + (this.hzMlMissed ? "1" : "0"));
         a.push("Persist=" + (this.hzMlPersist ? "1" : "0"));
         a.push("");
         a.push("[Debug]");
         a.push("; 1 shows a live data readout (for troubleshooting)");
         a.push("Debug=" + this.hzB(this.hzDebug));
         return a.join("\r\n") + "\r\n";
      }

      // Accent divider overlay on each card so a live accent change is visible immediately.
      private function hzRedrawDividers() : void
      {
         this.hzRedrawBodies();
         if(this.hzSetIsOpen) { this.hzSetDraw(); }
      }

      // Own text helper (not registered in hzTexts so window redraws do not leak).
      private function hzSText(p:Sprite, txt:String, x:Number, y:Number, w:Number, size:int, col:uint, align:String, role:String = null) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         // settings window follows TextScale but clamped so rows never overflow the fixed layout
         var ts:Number = Math.max(0.9,Math.min(1.15,this.hzTextScale));
         var sz:int = int(Math.round(size * ts));
         var al:Number = 1;
         if(role == "hdr") { col = HZ_ACCENT; al = Number(HZ_TY_ALPHA.hdr); txt = this.hzHdrCase(txt); }
         else if(role == "lbl") { al = Number(HZ_TY_ALPHA.lbl); }
         else if(role == "sec") { al = Number(HZ_TY_ALPHA.sec); }
         t.width = w; t.height = sz + 10; t.x = x; t.y = y - (sz - size) / 2;
         var f:TextFormat = new TextFormat(this.hzFontName(),sz,col);
         f.align = align;
         f.letterSpacing = (role == "hdr" && this.hzHeaderStyle == 0) ? 1.6 : (role == "lbl" ? 0.4 : 0);
         t.defaultTextFormat = f;
         t.text = txt;
         t.setTextFormat(f);
         t.textColor = col;
         t.alpha = al;
         t.filters = this.hz35Shadow(false);
         p.addChild(t);
         return t;
      }

      // v0.33: 1 px (or t px) rounded edge as a stroke on a fresh Sprite in b. Replaces the old "two drawRoundRect in one
      // fill" ring, which Scaleform could join to a stale path point and draw as a pale wedge / shadow (F11 module banner,
      // live preview frames, buttons, pills, window edge). ew = the drawRoundRect ellipse size of the shape it outlines.
      private function hz33Edge(b:Sprite, x:Number, y:Number, w:Number, h:Number, ew:Number, col:uint, a:Number, t:Number) : void
      {
         if(b == null || a <= 0) { return; }
         var s:Sprite = new Sprite();
         s.mouseEnabled = false;
         s.mouseChildren = false;
         b.addChild(s);
         var g:* = s.graphics;
         g.lineStyle(t,col,Math.min(1,a),true);
         g.beginFill(col,0.004);
         g.drawRoundRect(x + t / 2,y + t / 2,w - t,h - t,Math.max(0,ew - t),Math.max(0,ew - t));
         g.endFill();
         g.lineStyle();
      }
      private function hzSetBox(g:*, x:Number, y:Number, w:Number, h:Number, line:uint, la:Number, fill:uint, fa:Number, r:Number) : void
      {
         g.lineStyle(1,line,la);
         g.beginFill(fill,fa);
         g.drawRoundRect(x,y,w,h,r,r);
         g.endFill();
         g.lineStyle();
      }

      // ---- v0.23 settings window (settings_mockup.py): Exo 2 faces, theme follows CardColor / TextTone ----
      private static const HZ_VERSION:String = "0.42.0";
      // v0.42.0.4: movie build id (hzBuildId, and the F11 header until the DLL sends its file version). One constant.
      private static const HZ_BUILD:String = "0.43.0.6";
      private static const HZ_SET_TOP:Number = 112;      // list viewport top
      private static const HZ_SET_TGS:Array = [0.8,0.9,1,1.067,1.1,1.125,1.2,1.25,1.333,1.4,1.5,1.6];
      private static const HZ_SET_TGS_N:Array = ["0.80","0.90","1.00","1.07","1.10","1.125","1.20","1.25","1.33","1.40","1.50","1.60"];
      private static const HZ_SET_SCRH:Array = [0,720,900,1080,1200,1440,1600,2160];
      private static const HZ_SET_SCRH_N:Array = ["OFF","720","900","1080","1200","1440","1600","2160"];
      // shipped HorizonUI.ini defaults: a value shown in the accent color = differs from the default
      private static const HZ_SET_DEF:Object = {"SettingsKey":"F11","ShowJetpack":1,"ShowVitals":1,"ShowPlanet":1,"ShowAfflictions":1,"ShowAmmo":1,"ShowQuests":1,"ShowCompass":1,"VehicleExitPill":1,"PlanetDetails":0,"ShowTarget":1,"TargetAnchor":0,"TargetShowValue":1,"CompassMarkers":1,"ShowFollowers":1,"ShowLocations":1,"ShowShip":1,"ShowEnemies":1,"ShowPlayerMarker":1,"CardOpacity":1,"ContainerOpacity":1,"AccentColor":0,"CardColor":0,"HudScale":1,"SmoothBars":1,"FadeCards":1,"CombatDim":1,"DimOpacity":0.6,"HazardAlert":1,"Compact":0,"Margin":40,"TextTone":0,"FontFace":1,"TimeDisplay":3,"ClockFormat":0,"TempUnit":0,"AfflictionLayout":0,"TextScale":1,"ContainerScale":1.125,"HoverScale":1,"ScreenHeight":1440,"CrosshairStyle":1,"ObjectRing":0,"HeaderStyle":0,"TextShadow":0,"JetpackRule":4,"VitalsRule":0,"PlanetRule":0,"AfflictionsRule":6,"AmmoRule":3,"QuestsRule":0,"CompassRule":0,"CharacterRule":0,"FollowerColor":0,"AutoCenterVitals":1,"ShowCharacter":1,"EnemyBar":1,"StealthMeter":1,"EquipmentExtras":1,"EdgePulse":1,"XpToast":1,"HitMarkers":1,"DamageNumbers":1,"DirectionRing":1,"RegenSliver":1,"ModuleNoteCompact":0,"JetpackScale":-1,"VitalsScale":-1,"VitalsLayout":0,"ScopeHoldBreathChip":1,"ScopeChipX":0,"ScopeChipY":0,"ScopeChipScale":1,"CharacterScale":-1,"CharacterCompact":-1,"XpToastScale":-1,"PlanetScale":-1,"PlanetCompact":-1,"AfflictionsScale":-1,"EquipmentScale":-1,"EquipmentCompact":-1,"QuestsScale":-1,"QuestsCompact":-1,"CompassScale":-1,"CompassCompact":-1,"EnemyScale":-1,"StealthScale":-1,"CompactScale":-1};
      private var hzSetScroll:int = 0;
      private var hzSetMaxScroll:int = 0;
      private var hzSetPv:Sprite = null;
      private var hzSetKeyOv:Sprite = new Sprite();   // keycap outlines, re-added above all window text each draw
      private var hzSetPvBody:Sprite = null;
      private var hzSetPvDisc:Sprite = null;
      private var hzSetPvG:Sprite = null;
      private var hzSetPvTf:Array = [];
      private var hzSetPvTg:Sprite = null;     // v0.24 preview: crosshair + sample crosshair card (TargetScale / CrosshairStyle / ObjectRing / ScreenHeight)
      private var hzSetPvTgCard:Sprite = null;
      private var hzSetPvTgTf:Object = null;
      private var hzSetPvAf:Sprite = null;     // v0.24 preview: sample affliction chips in the pending AfflictionLayout
      private var hzSetPvAfCh:Array = [];
      private var hzSetPvOp:Sprite = null;     // v0.25 preview: HUD card (CardOpacity) vs container card (ContainerOpacity)

      private function hzSetIsDef(k:String, v:*) : Boolean
      {
         var d:* = HZ_SET_DEF[k] != undefined ? HZ_SET_DEF[k] : HZ31_DEF[k];
         if(d == undefined) { return true; }
         if(d is String) { return String(v) == String(d); }
         if(v is Boolean) { return Boolean(v) == (Number(d) != 0); }
         return Math.abs(Number(v) - Number(d)) < 0.0005;
      }

      private function hzSetTheme() : Object
      {
         var lt:Boolean = this.hzDarkText();
         var acc:uint = HZ_ACCENT;
         if(lt && this.hzLum(acc) > 0.4) { acc = this.hzMix(acc,0x000000,0.35); }
         var fill:uint = this.hzCardFill();   // color only (CardColor); never the opacity-adjusted panel fill
         if(lt)
         {
            return {"lt":true,"fill":fill,"fa":0.95,"edge":0x000000,"ea":0.12,"txt":0x0E1A22,"lab":0x33454F,"mut":0x5F717B,"line":0x000000,"la":0.1,"acc":acc,"track":0x000000,"ta":0.12,"tile":0x000000,"tia":0.055,"off":0xAAB6BE,"note":0x8A6A00,"kon":0xFFFFFF,"koff":0xFFFFFF,"ontxt":0xFFFFFF};
         }
         return {"lt":false,"fill":fill,"fa":0.93,"edge":0xFFFFFF,"ea":0.1,"txt":0xF2F7F9,"lab":0xC4D2D9,"mut":0x96A6AE,"line":0xFFFFFF,"la":0.086,"acc":acc,"track":0xFFFFFF,"ta":0.12,"tile":0x060A0E,"tia":0.47,"off":0x46545E,"note":HZ_YELLOW,"kon":0x0B1218,"koff":0xE6ECF0,"ontxt":0x0B1218};
      }

      // window text: own faces ("rg" / "sb" / "bd" via hzFontName per-face fallback), whole pixels, no filters.
      // (x, y) is the mockup's text origin (left or right edge per align), compensating the 2 px TextField gutter.
      private function hzWT(p:Sprite, txt:String, x:Number, y:Number, w:Number, fs:Number, face:String, col:uint, ls:Number = 0, align:String = "left", minPx:int = 0) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         var ts:Number = Math.max(0.9,Math.min(1.15,this.hzTextScale));
         var sz:int = Math.max(9,int(Math.round(fs * ts)));
         if(minPx > sz) { sz = minPx; }   // v0.42.0.4: the version label passes 13 so TextScale 0.9 cannot round it to 12
         if(face == "rg" && sz <= 12) { face = "sb"; }
         var f:TextFormat = new TextFormat(this.hzFontName(face),sz,col);
         f.align = align;
         f.letterSpacing = ls;
         t.defaultTextFormat = f;
         t.width = Math.round(w);
         t.height = sz + 10;
         t.text = txt;
         t.setTextFormat(f);
         t.textColor = col;
         if(align == "right") { t.x = Math.round(x - w + 2); }
         else if(align == "center") { t.x = Math.round(x - w / 2); }
         else { t.x = Math.round(x - 2); }
         t.y = Math.round(y - 3 - (sz - fs) / 2);
         try { t.antiAliasType = "advanced"; t.gridFitType = "pixel"; } catch(errAA:Error) { }
         p.addChild(t);
         return t;
      }

      // keycap: 1 px ring drawn inside the box (never clipped), tinted fill; returns its width
      // minPx is forwarded to hzWT so the log can keep a 13 px floor at TextScale 0.90-0.96.
      private function hzSetKey(b:Sprite, g:*, x:Number, y:Number, k:String, col:uint, h:Number, fs:Number, minPx:int = 0) : Number
      {
         var t:TextField = this.hzWT(b,k,x,y,120,fs,"bd",col,0.4,"left",minPx);
         var tw:Number = Math.round(this.hzTW(t));
         var kw:Number = Math.max(h + 4,tw + 16);
         x = Math.round(x); y = Math.round(y);
         t.width = tw + 5;                                   // field inside the cap
         t.filters = [];
         t.x = Math.round(x + (kw - tw) / 2 - 2);
         t.y = Math.round(this.hzCapTop(t,y + h / 2));       // v0.26: centered on the cap by the real ascent
         this.hzKeycap(g,x,y,kw,h,col,1,this.hzSetKeyOv.graphics);
         return kw;
      }

      // ON / OFF switch, 38 x 18, right edge R, center cy
      private function hzSetSwitch(b:Sprite, g:*, R:Number, cy:Number, on:Boolean, T:Object, label:Boolean = true) : void
      {
         var acc:uint = uint(T.acc);
         g.beginFill(on ? acc : uint(T.off),on ? 0.86 : 1);
         g.drawRoundRect(R - 38,cy - 9,38,18,18,18);
         g.endFill();
         var kx:Number = on ? R - 9 : R - 29;
         g.beginFill(on ? uint(T.kon) : uint(T.koff),1);
         g.drawCircle(kx,cy,6.5);
         g.endFill();
         if(label) { this.hzWT(b,on ? "ON" : "OFF",R - 48,cy - 8,40,11,"sb",on ? acc : uint(T.mut),1.5,"right"); }
      }

      // cycler arrow: solid triangle, tip at (x, cy); dir -1 = points left, +1 = points right
      private function hzSetTri(g:*, x:Number, cy:Number, dir:int, col:uint, a:Number) : void
      {
         g.beginFill(col,a);
         g.moveTo(x,cy); g.lineTo(x - dir * 5,cy - 5); g.lineTo(x - dir * 5,cy + 5); g.lineTo(x,cy);
         g.endFill();
      }

      // pill button (OK / CANCEL / ARRANGE / OPEN); returns its width; right edge R
      // minPx is forwarded to hzWT so the log can keep a 13 px floor at TextScale 0.90-0.96.
      private function hzSetBtn(b:Sprite, g:*, R:Number, y:Number, lab:String, prim:Boolean, outline:Boolean, hov:Boolean, T:Object, id:String, fs:Number = 12, minPx:int = 0) : Number
      {
         var acc:uint = uint(T.acc);
         var t:TextField = this.hzWT(b,lab,0,y + (fs > 12 ? 5 : 6),220,fs,"sb",prim ? uint(T.ontxt) : uint(T.txt),1.8,"left",minPx);
         var w:Number = Math.round(this.hzTW(t) + 28);
         var x:Number = Math.round(R - w);
         g.beginFill(prim ? acc : uint(T.mut),prim ? (hov ? 1 : 0.8) : (hov ? 0.3 : 0.16));
         g.drawRoundRect(x,y,w,28,28,28);
         g.endFill();
         if(prim || outline)
         {
            this.hz33Edge(b,x,y,w,28,28,acc,hov ? 1 : 0.85,1);
         }
         t.x = x + 12;
         this.hzSetHits.push({"id":id,"x":x,"y":y,"w":w,"h":28});
         return w;
      }

      // list geometry: heights per scrolling row (pill rows excluded)
      private function hzSetRowH(r:Object) : Number
      {
         if(r.t == "m") { return (r.h ? 24 : 0) + this.hz34BanH(); }
         if(r.t == "w") { return (r.h ? 24 : 0) + 44; }
         return (r.h ? 24 : 0) + 32 + (r.note ? (r.n13 ? 20 : 18) : 0) + 4;
      }

      // scroll so the selected row is fully visible ("selection follows"); also computes the max scroll
      private function hzSetFollow(rows:Array) : void
      {
         var list:Array = [];
         for each(var r:Object in rows) { if(!r.pill) { list.push(r); } }
         var avail:Number = HZ_SET_H - 64 - HZ_SET_TOP;
         var ms:int = 0;
         var tot:Number = 0;
         var i:int = list.length - 1;
         while(i >= 0) { tot += this.hzSetRowH(list[i]); if(tot > avail) { ms = i + 1; break; } i--; }
         this.hzSetMaxScroll = ms;
         var cur:Object = rows[this.hzSetRow];
         var li:int = cur ? list.indexOf(cur) : -1;
         if(li >= 0)
         {
            if(li < this.hzSetScroll) { this.hzSetScroll = li; }
            var guard:int = 0;
            while(guard < 64)
            {
               var y:Number = 0;
               var j:int = this.hzSetScroll;
               while(j <= li) { y += this.hzSetRowH(list[j]); j++; }
               if(y <= avail || this.hzSetScroll >= li) { break; }
               this.hzSetScroll++;
               guard++;
            }
         }
         this.hzSetScroll = Math.max(0,Math.min(ms,this.hzSetScroll));
      }

      // mouse wheel / scrollbar: move the view, then pull the selection into it
      private function hzSetScrollBy(d:int) : void
      {
         var rows:Array = this.hzSetRows(this.hzSetTab);
         this.hzSetFollow(rows);
         this.hzSetScroll = Math.max(0,Math.min(this.hzSetMaxScroll,this.hzSetScroll + d));
         var list:Array = [];
         for each(var r:Object in rows) { if(!r.pill) { list.push(r); } }
         var avail:Number = HZ_SET_H - 64 - HZ_SET_TOP;
         var first:int = this.hzSetScroll;
         var last:int = first;
         var y:Number = 0;
         var j:int = first;
         while(j < list.length) { y += this.hzSetRowH(list[j]); if(y > avail) { break; } last = j; j++; }
         var cur:Object = rows[this.hzSetRow];
         var li:int = cur ? list.indexOf(cur) : -1;
         if(li >= 0 && li < first) { this.hzSetRow = rows.indexOf(list[first]); }
         else if(li > last) { this.hzSetRow = rows.indexOf(list[last]); }
      }

      private function hzSetDraw() : void
      {
         if(!this.HorizonSettings_mc || !this.hzSetPend) { return; }
         var b:Sprite = this.hzSetBody;
         while(b.numChildren > 0) { b.removeChildAt(0); }
         b.graphics.clear();
         this.hzSetKeyOv.graphics.clear();
         this.hzSetHits = [];
         var T:Object = this.hzSetTheme();
         var acc:uint = uint(T.acc);
         var W:Number = HZ_SET_W;
         var H:Number = HZ_SET_H;
         var g:* = b.graphics;
         var i:int = 0;
         // soft shadow (stacked, no filter) + body + 1 px edge
         i = 0;
         while(i < 5) { g.beginFill(0x000000,0.07); g.drawRoundRect(-2 - i * 2,4 - i,W + 4 + i * 4,H + 4 + i * 3,(18 + i * 2) * 2,(18 + i * 2) * 2); g.endFill(); i++; }
         g.beginFill(uint(T.fill),Number(T.fa));   // v0.25: fixed fill, ignores CardOpacity / ContainerOpacity / dimming
         g.drawRoundRect(0,0,W,H,36,36);
         g.endFill();
         this.hz33Edge(b,0,0,W,H,36,uint(T.edge),Number(T.ea),1);   // v0.33: stroked edge on its own Sprite (no even-odd ring)
         // title
         var tt:TextField = this.hzWT(b,"HORIZON UI",28,20,260,18,"bd",uint(T.txt),3);
         this.hzWT(b,"SETTINGS",28 + this.hzTW(tt) + 12,25,200,12,"sb",uint(T.mut),2.4);
         // v0.42.0.4: exact DLL file version. HZ_BUILD until hzSetDllFileVersion arrives.
         // The last argument is a 13 px floor. hzWT multiplies by TextScale (clamped to 0.9) and rounds,
         // so a bare 13 would draw at 12 px when TextScale is 0.9.
         var hv:String = HZ_BUILD;
         if(this.hz42FileVerOk(this.hzDllFileVer)) { hv = this.hzDllFileVer; }
         var vt:TextField = this.hzWT(b,"v" + hv,W - 28,24,170,13,"sb",uint(T.mut),0.4,"right",13);
         g.beginFill(acc,1); g.drawCircle(Math.round(W - 28 - this.hzTW(vt) - 14),32,4); g.endFill();
         // tabs
         var tx:Number = 28;
         var ty:Number = 62;
         // v0.30: 9 tabs; the gap shrinks (26 -> 12) so the tab row keeps room for the COMPACT pill / PGUP hint
         var tabTf:Array = [];
         var tabSum:Number = 0;
         i = 0;
         while(i < HZ_SET_TABS.length)
         {
            var sel:Boolean = i == this.hzSetTab;
            var hov:Boolean = this.hzSetHover == "tab" + i;
            var tb:TextField = this.hzWT(b,String(HZ_SET_TABS[i]),0,ty,160,11,"sb",sel || hov ? uint(T.txt) : uint(T.mut),2);
            tabTf.push(tb);
            tabSum += Math.round(this.hzTW(tb));
            i++;
         }
         var tgap:Number = Math.max(12,Math.min(26,Math.floor((W - 56 - 150 - tabSum) / Math.max(1,HZ_SET_TABS.length - 1))));
         i = 0;
         while(i < tabTf.length)
         {
            var tbx:TextField = tabTf[i] as TextField;
            var tw:Number = Math.round(this.hzTW(tbx));
            tbx.x = Math.round(tx - 2);
            if(i == this.hzSetTab) { g.beginFill(acc,1); g.drawRoundRect(tx,ty + 20,tw,2.5,2,2); g.endFill(); }
            if(i >= 7 && this.hz30Mod[i == 7 ? "scanner" : "comms"] !== 1) { this.hz30Lock(g,tx + tw + 7,ty + 5,9,uint(T.mut),0.9,uint(T.fill)); tw += 12; }
            this.hzSetHits.push({"id":"tab" + i,"x":tx - 6,"y":ty - 8,"w":tw + 12,"h":34});
            tx += tw + tgap;
            i++;
         }
         var tabEnd:Number = tx - tgap;
         var rows:Array = this.hzSetRows(this.hzSetTab);
         if(this.hzSetRow >= rows.length) { this.hzSetRow = 0; }
         // CARDS tab: COMPACT MODE as a highlighted pill toggle at the top right of the tab header
         var pillRow:int = -1;
         i = 0;
         while(i < rows.length) { if(rows[i].pill) { pillRow = i; } i++; }
         if(pillRow >= 0)
         {
            var pr:Object = rows[pillRow];
            var pon:Boolean = Boolean(this.hzSetPend[pr.k]);
            var psel:Boolean = this.hzSetRow == pillRow;
            var phov:Boolean = this.hzSetHover == "row" + pillRow;
            var plab:String = String(pr.l);
            var pt:TextField = this.hzWT(b,plab,0,ty,260,11,"sb",uint(T.txt),1.6);
            var pw:Number = Math.round(this.hzTW(pt) + 14 + 10 + 38 + 12);
            if(W - 28 - pw < tabEnd + 16) { pt.text = "COMPACT"; pw = Math.round(this.hzTW(pt) + 14 + 10 + 38 + 12); }
            if(W - 28 - pw < tabEnd + 16) { pt.text = ""; pw = 14 + 38 + 12; }   // v0.30: very large text scale: switch only
            var px0:Number = W - 28 - pw;
            var py0:Number = 55;
            g.beginFill(acc,psel ? 0.3 : (phov ? 0.24 : (pon ? 0.2 : 0.12)));
            g.drawRoundRect(px0,py0,pw,26,26,26);
            g.endFill();
            var pb:Number = psel ? 2 : 1;
            this.hz33Edge(b,px0,py0,pw,26,26,acc,psel || pon ? 1 : 0.7,pb);
            pt.x = px0 + 12;
            this.hzSetSwitch(b,g,px0 + pw - 6,py0 + 13,pon,T,false);
            this.hzSetHits.push({"id":"row" + pillRow,"x":px0,"y":py0,"w":pw,"h":26});
         }
         else { this.hzWT(b,"PGUP / PGDN",W - 28,ty + 1,160,10,"rg",uint(T.mut),1,"right"); }
         g.beginFill(uint(T.line),Number(T.la)); g.drawRect(28,ty + 28,W - 56,1); g.endFill();
         // rows (scroll in whole rows; only rows that fit are drawn)
         var prev:Boolean = this.hzSetTab == 1 || this.hzSetTab == 2;   // STYLE + TEXT: live preview column
         var right:Number = W - 28 - (prev ? 250 : 0);
         var R:Number = right - 6;
         this.hzSetFollow(rows);
         var list:Array = [];
         for each(var lr:Object in rows) { if(!lr.pill) { list.push(lr); } }
         var bottom:Number = H - 64;
         var y:Number = HZ_SET_TOP;
         var li:int = this.hzSetScroll;
         var lastShown:int = li - 1;
         this.hz35Tip = null;
         var bMain:Sprite = b;
         var gMain:* = g;
         var dimS:Sprite = new Sprite();
         dimS.mouseEnabled = false; dimS.mouseChildren = false;
         dimS.alpha = 0.4;   // v0.30: locked rows: grayed, no hit areas
         b.addChild(dimS);
         while(li < list.length)
         {
            var r:Object = list[li];
            if(y + this.hzSetRowH(r) - 4 > bottom) { break; }
            i = rows.indexOf(r);
            if(r.h)
            {
               this.hzWT(b,String(r.h),32,y + 6,300,9,"sb",r.dis && r.k != "FontFace" ? uint(T.mut) : acc,2.2);
               y += 24;
            }
            if(r.t == "w")
            {
               this.hz37DrawWarn(b,g,y,right,T,String(r.l));   // v0.37: amber install warning (another HUD mod)
               y += 44;
               lastShown = li;
               li++;
               continue;
            }
            if(r.t == "m")
            {
               try { this.hz30ModBanner(b,g,y,right,T,String(r.mod),i == this.hzSetRow,i); } catch(errMb:Error) { }
               y += this.hz34BanH();
               lastShown = li;
               li++;
               continue;
            }
            var hit0:int = this.hzSetHits.length;
            var lb35:TextField = null;
            if(r.dis)
            {
               this.hz30Lock(g,40,y + 15,11,uint(T.mut),0.95,uint(T.fill));
               b = dimS; g = dimS.graphics;
            }
            var rs:Boolean = i == this.hzSetRow && !r.dis;
            var rh:Boolean = this.hzSetHover == "row" + i;
            if(rs || rh)
            {
               g.beginFill(acc,rs ? 0.13 : 0.07); g.drawRoundRect(22,y,right + 6 - 22,32,18,18); g.endFill();
               if(rs) { g.beginFill(acc,1); g.drawRoundRect(22,y + 8,3,16,3,3); g.endFill(); }
            }
            if(r.sub)
            {
               // v0.34 sub-row of the card above: indented, smaller label, short accent tick
               g.beginFill(uint(T.line),0.9); g.drawRect(r.dis ? 60 : 40,y + 16,10,1); g.endFill();
               lb35 = this.hzWT(b,String(r.l),r.dis ? 76 : 56,y + 9,right - 340,11,"sb",rs ? uint(T.txt) : uint(T.lab),1.2);
            }
            else { lb35 = this.hzWT(b,String(r.l),r.dis ? 56 : 34,y + 8,right - 300,13,"rg",rs ? uint(T.txt) : uint(T.lab),0.3); }
            this.hzSetHits.push({"id":"row" + i,"x":22,"y":y,"w":right + 6 - 22,"h":32});
            // v0.35: "i" after the label; hover it, or select the row with keys / controller, for the explanation
            var inf35:String = r.dis ? null : this.hz35InfoOf(r);
            if(inf35 != null && lb35 != null && String(r.l).length > 0)
            {
               var ix35:Number = Math.round(lb35.x + 2 + Math.min(lb35.width,this.hzTW(lb35)) + 14);
               var ion35:Boolean = this.hzSetHover == "inf" + i || (rs && this.hz35Kb);
               this.hz35InfoIcon(b,g,ix35,y + 16,acc,T,ion35,i);
               if(ion35) { this.hz35Tip = {"t":inf35,"x":ix35,"y":y,"h":32}; }
            }
            var v:* = r.dis ? r.dv : this.hzSetPend[r.k];
            var cy:Number = y + 16;
            var isDef:Boolean = this.hzSetIsDef(String(r.k),v);
            var vcol:uint = isDef ? uint(T.txt) : acc;
            if(r.t == "b") { this.hzSetSwitch(b,g,R,cy,Boolean(v),T); }
            else if(r.t == "n")
            {
               var bw:Number = prev ? 150 : 200;
               var bx:Number = R - 56 - bw;
               var fr:Number = Math.max(0,Math.min(1,(Number(v) - r.mn) / (r.mx - r.mn)));
               this.hzWT(b,r.st < 1 ? this.hzSetNum(Number(v)) : String(int(Math.round(Number(v)))),R,cy - 9,56,13,"sb",vcol,0.5,"right");
               g.beginFill(uint(T.track),Number(T.ta)); g.drawRoundRect(bx,cy - 2,bw,4,4,4); g.endFill();
               if(fr > 0) { g.beginFill(acc,1); g.drawRoundRect(bx,cy - 2,Math.max(4,Math.round(bw * fr)),4,4,4); g.endFill(); }
               var kx:Number = Math.round(bx + bw * fr);
               g.beginFill(acc,1); g.drawCircle(kx,cy,7); g.endFill();
               g.beginFill(uint(T.txt),1); g.drawCircle(kx,cy,5); g.endFill();
               this.hzSetHits.push({"id":"bar" + i,"x":bx - 10,"y":y,"w":bw + 20,"h":32,"bx":bx,"bw":bw});
            }
            else if(r.t == "z") { this.hz34ZDraw(b,g,i,y,R,v,T,acc,prev); }
            else if(r.t == "a")
            {
               var ai:int = int(v);
               var pal:Array = r.pal as Array;
               var nm:String = String((r.names as Array)[Math.max(0,Math.min(pal.length - 1,ai))]);
               var nt:TextField = this.hzWT(b,nm,R,cy - 9,140,13,"sb",r.k == "AccentColor" ? this.hzIconCol(uint(pal[ai])) : vcol,1.2,"right");
               var st:Number = 17;
               var sx:Number = Math.round(R - this.hzTW(nt) - 18 - st * pal.length);
               var j:int = 0;
               while(j < pal.length)
               {
                  var xx:Number = sx + j * st;
                  var cs:Boolean = j == ai;
                  if(cs) { g.beginFill(uint(T.txt),1); g.drawRoundRect(xx - 2,cy - 9,16,18,9,9); g.endFill(); }
                  else { g.beginFill(uint(T.line),0.35); g.drawRoundRect(xx - 1,cy - 8,14,16,8,8); g.endFill(); }
                  g.beginFill(uint(pal[j]),1); g.drawRoundRect(xx,cy - 7,12,14,7,7); g.endFill();
                  this.hzSetHits.push({"id":"sw" + i + "_" + j,"x":xx - 2,"y":y,"w":st,"h":32});
                  j++;
               }
            }
            else if(r.t == "r" || r.t == "q" || r.t == "l" || r.t == "c")
            {
               var txt:String = "";
               if(r.t == "r") { txt = String((r.opts as Array)[Math.max(0,Math.min((r.opts as Array).length - 1,this.hz29OptIdx(r,v)))]); }
               else if(r.t == "q") { txt = String(HZ_RULE_NAMES[Math.max(0,Math.min(HZ_RULE_NAMES.length - 1,int(v)))]); }
               else if(r.t == "l")
               {
                  var vi:int = this.hzSetListIdx(r,v);
                  txt = String((r.names as Array)[vi]);
               }
               var x0:Number = 0;
               if(r.t == "c")
               {
                  var kt:TextField = this.hzWT(b,String(v),0,0,120,11,"bd",acc,0.4);
                  var kw:Number = Math.max(28,Math.round(this.hzTW(kt) + 16));
                  b.removeChild(kt);
                  x0 = Math.round(R - 14 - kw);
                  this.hzSetKey(b,g,x0,cy - 12,String(v),isDef ? uint(T.txt) : acc,24,11);
               }
               else
               {
                  var ct:TextField = this.hzWT(b,txt,R - 14,cy - 9,260,13,"sb",vcol,1.2,"right");
                  x0 = Math.round(R - 14 - this.hzTW(ct));
               }
               var lh:Boolean = this.hzSetHover == "lt" + i;
               var rhv:Boolean = this.hzSetHover == "rt" + i;
               this.hzSetTri(g,x0 - 14,cy,-1,acc,lh ? 1 : 0.78);
               this.hzSetTri(g,R,cy,1,acc,rhv ? 1 : 0.78);
               this.hzSetHits.push({"id":"lt" + i,"x":x0 - 24,"y":y,"w":22,"h":32});
               this.hzSetHits.push({"id":"rt" + i,"x":R - 10,"y":y,"w":22,"h":32});
            }
            else if(r.t == "p") { this.hz37DrawPick(b,g,r,i,cy,R,T); }
            else if(r.t == "x" && String(r.k).indexOf("_hz37") == 0) { this.hz37DrawBtn(b,g,r,i,R,cy,rh,T); }
            else if(r.t == "x")
            {
               this.hzSetBtn(b,g,R,cy - 14,r.btn != undefined ? String(r.btn) : "OPEN",false,true,rh,T,"row" + i);
            }
            if(r.dis)
            {
               this.hzSetHits.splice(hit0,this.hzSetHits.length - hit0);
               b = bMain; g = gMain;
            }
            y += 32;
            if(r.note)
            {
               this.hzWT(b,String(r.note),(r.dis ? 56 : 34) + (r.sub ? 22 : 0),y - 2,right - 40,r.n13 ? 13 : 11,"rg",uint(T.note),0.2);
               y += r.n13 ? 20 : 18;
            }
            y += 4;
            lastShown = li;
            li++;
         }
         // scroll track (only when the tab does not fit)
         if(this.hzSetMaxScroll > 0)
         {
            var trX:Number = right + 12;
            var trT:Number = HZ_SET_TOP + 4;
            var trH:Number = bottom - trT - 4;
            var shown:int = Math.max(1,lastShown - this.hzSetScroll + 1);
            var tot:int = list.length;
            var thH:Number = Math.max(24,Math.round(trH * shown / tot));
            var thY:Number = Math.round(trT + (trH - thH) * this.hzSetScroll / Math.max(1,this.hzSetMaxScroll));
            g.beginFill(uint(T.track),Number(T.ta)); g.drawRoundRect(trX,trT,3,trH,3,3); g.endFill();
            g.beginFill(acc,0.9); g.drawRoundRect(trX,thY,3,thH,3,3); g.endFill();
            this.hzSetHits.push({"id":"strk","x":trX - 8,"y":trT,"w":19,"h":trH,"ty":trT,"th":trH});
         }
         // STYLE tab: live preview column
         if(this.hzSetPv) { this.hzSetPv.visible = false; }
         if(this.hzSetPvTg) { this.hzSetPvTg.visible = false; }
         if(this.hzSetPvAf) { this.hzSetPvAf.visible = false; }
         if(this.hzSetPvOp) { this.hzSetPvOp.visible = false; }
         if(prev)
         {
            var pvk:String = this.hzSetRow >= 0 && this.hzSetRow < rows.length ? String(rows[this.hzSetRow].k) : "";
            if(pvk == "ContainerScale" || pvk == "HoverScale" || pvk == "CrosshairStyle" || pvk == "ObjectRing" || pvk == "ScreenHeight") { this.hz30PvKey = pvk; this.hzSetPvTgDraw(b,g,W - 28 - 226,HZ_SET_TOP,T); }
            else if(pvk == "AfflictionLayout") { this.hzSetPvAfDraw(b,g,W - 28 - 226,HZ_SET_TOP,T); }
            else if(pvk == "CardOpacity" || pvk == "ContainerOpacity") { this.hzSetPvOpDraw(b,g,W - 28 - 226,HZ_SET_TOP,T); }
            else { this.hzSetPvDraw(b,g,W - 28 - 226,HZ_SET_TOP,T); }
         }
         // footer: keycap hints + buttons
         var fy:Number = H - 56;
         g.beginFill(uint(T.line),Number(T.la)); g.drawRect(22,fy,W - 44,1); g.endFill();
         var by:Number = fy + 18;
         var hx:Number = 28;
         for each(var hk:Array in [["UP/DN","SELECT"],["L/R","CHANGE"],["PGUP","TAB"],["ENTER","OK"],["ESC","CANCEL"]])
         {
            var hkw:Number = this.hzSetKey(b,g,hx,by - 2,String(hk[0]),uint(T.mut),22,10);
            var hl:TextField = this.hzWT(b,String(hk[1]),hx + hkw + 6,by + 3,120,10,"sb",uint(T.mut),1.2);
            hl.y = Math.round(this.hzCapTop(hl,by + 9));
            hx = Math.round(hx + hkw + 5 + this.hzTW(hl) + 12);
         }
         var bxr:Number = W - 28;
         bxr -= this.hzSetBtn(b,g,bxr,by - 5,"CANCEL",false,false,this.hzSetHover == "cancel",T,"cancel") + 10;
         bxr -= this.hzSetBtn(b,g,bxr,by - 5,"OK",true,false,this.hzSetHover == "ok",T,"ok") + 10;
         this.hzSetBtn(b,g,bxr,by - 5,"ARRANGE CARDS",false,true,this.hzSetHover == "arrange",T,"arrange");
         b.addChild(this.hzSetKeyOv);   // keycap outlines above every text field of the window
         try { this.hz35TipDraw(b,W,H,T,acc); } catch(e35p:Error) { }   // v0.35 info tooltip, above everything
         // keep cursor on top and the window above the cards
         this.HorizonSettings_mc.setChildIndex(this.hzSetCursor,this.HorizonSettings_mc.numChildren - 1);
         if(this.HorizonSettings_mc.parent == this && getChildIndex(this.HorizonSettings_mc) != numChildren - 1)
         {
            setChildIndex(this.HorizonSettings_mc,numChildren - 1);
         }
      }

      private function hzSetListIdx(r:Object, v:*) : int
      {
         var vals:Array = r.vals as Array;
         var best:int = 0;
         var bd:Number = 1e9;
         var i:int = 0;
         while(i < vals.length) { var d:Number = Math.abs(Number(vals[i]) - Number(v)); if(d < bd) { bd = d; best = i; } i++; }
         return best;
      }

      // STYLE tab live preview: the real planet card's panel + disc drawing code and its current texts, scaled into the column
      private function hzSetPvDraw(b:Sprite, g:*, px:Number, py:Number, T:Object) : void
      {
         var acc:uint = uint(T.acc);
         g.beginFill(uint(T.tile),Number(T.tia)); g.drawRoundRect(px,py,226,300,28,28); g.endFill();
         this.hz33Edge(b,px,py,226,300,28,uint(T.line),Number(T.la),1);
         this.hzWT(b,"LIVE PREVIEW",px + 14,py + 12,200,9,"sb",acc,2.2);
         var k:int = 0;
         for each(var ln:String in ["Updates while you change values.","CANCEL reverts to the values","captured when the window opened."])
         {
            this.hzWT(b,ln,px + 14,py + 232 + k * 16,210,11,"rg",uint(T.mut),0);
            k++;
         }
         if(!this.hzPpName || !this.hzPlanPill) { return; }
         if(!this.hzSetPv)
         {
            var p:Sprite = new Sprite();
            this.hzSetPv = p;
            this.hzSetPvBody = new Sprite(); p.addChild(this.hzSetPvBody);
            this.hzSetPvDisc = new Sprite(); this.hzSetPvDisc.x = 42; this.hzSetPvDisc.y = 42; p.addChild(this.hzSetPvDisc);
            this.hzSetPvG = new Sprite(); p.addChild(this.hzSetPvG);
            var src:Array = [this.hzPpName,this.hzPpLine,this.hzPpDet,this.hzPpLocT,this.hzPpLocL,this.hzPpRealT,this.hzPpRealL];
            for each(var s0:TextField in src)
            {
               var so:Object = this.hzTxtObj(s0);
               var c0:TextField = this.hzT(p,s0.text,s0.x,s0.y,s0.width,so ? Number(so.fs) : 12,so ? String(so.face) : "sb",so ? String(so.tone) : "main",so ? Number(so.ls) : 0,so && so.right ? "right" : "left");
               if(so && so.hdr19) { this.hzHdr19(c0); }
               this.hzSetPvTf.push([s0,c0]);
            }
         }
         var pv:Sprite = this.hzSetPv;
         if(pv.parent != this.HorizonSettings_mc) { this.HorizonSettings_mc.addChild(pv); }
         this.HorizonSettings_mc.setChildIndex(pv,this.HorizonSettings_mc.numChildren - 1);
         for each(var pair:Array in this.hzSetPvTf)
         {
            var a0:TextField = TextField(pair[0]);
            var c1:TextField = TextField(pair[1]);
            var ao:Object = this.hzTxtObj(a0);
            this.hzTxtTint(c1,ao ? ao.tint : null);
            c1.text = a0.text;
            c1.visible = a0.visible;
            c1.x = a0.x; c1.y = a0.y; c1.width = a0.width;
         }
         var pg:* = this.hzSetPvBody.graphics;
         pg.clear();
         this.hzPanel(pg,this.hzPpW,this.hzPpH > 0 ? this.hzPpH : 84,this.hzPpC == 1 ? 14 : 18);
         this.hzSetPvDisc.x = this.hzPpDisc.x; this.hzSetPvDisc.y = this.hzPpDisc.y;
         this.hzSetPvDisc.scaleX = this.hzSetPvDisc.scaleY = this.hzPpDisc.scaleX;
         this.hzPpDrawIcon(this.hzSetPvDisc);
         // clock glyphs, same rule and positions as hzPpLayout
         var gg:* = this.hzSetPvG.graphics;
         gg.clear();
         var bgc:uint = this.hzPanelFill();
         var rws:Array = [];
         if(this.hzPpLocT.visible) { rws.push("loc"); }
         if(this.hzPpRealT.visible) { rws.push("real"); }
         var ys:Array = rws.length == 2 ? [17,42] : [29];
         var ri:int = 0;
         while(ri < rws.length)
         {
            var isLoc:Boolean = rws[ri] == "loc";
            var gtf:TextField = isLoc ? this.hzPpLocT : this.hzPpRealT;
            var gx:Number = isLoc ? this.hzPpGlx : this.hzPpGrx;
            var gy:Number = isLoc ? this.hzPpGly : this.hzPpGry;
            if(isLoc && this.hzPpShowUT) { this.hzGlyph(gg,"clock",gx,gy,this.hzIconCol(HZ_ACCENT),bgc); }
            else if(isLoc) { this.hzGlyph(gg,this.hzPpDay >= 0.25 && this.hzPpDay <= 0.75 ? "sun" : "moon",gx,gy,this.hzIconCol(0xFFD678),bgc); }
            else { this.hzGlyph(gg,"clock",gx,gy,this.hzIconCol(0x96A6AE),bgc); }
            ri++;
         }
         var sc:Number = 206 / this.hzPpW;
         pv.scaleX = pv.scaleY = sc;
         pv.x = Math.round(px + (226 - this.hzPpW * sc) / 2);
         pv.y = Math.round(py + 44);
         pv.visible = true;
      }

      // preview column frame shared by the three previews
      private function hzSetPvFrame(b:Sprite, g:*, px:Number, py:Number, T:Object, title:String, lines:Array) : void
      {
         g.beginFill(uint(T.tile),Number(T.tia)); g.drawRoundRect(px,py,226,300,28,28); g.endFill();
         this.hz33Edge(b,px,py,226,300,28,uint(T.line),Number(T.la),1);
         this.hzWT(b,"LIVE PREVIEW",px + 14,py + 12,200,9,"sb",uint(T.acc),2.2);
         if(title.length > 0) { this.hzWT(b,title,px + 212,py + 12,180,9,"sb",uint(T.mut),1.2,"right"); }
         var k:int = 0;
         for each(var ln:String in lines)
         {
            this.hzWT(b,ln,px + 14,py + 232 + k * 16,210,11,"rg",uint(T.mut),0);
            k++;
         }
      }

      // Crosshair card preview: crosshair glyph (pending CrosshairStyle) + a sample item tag at the real +26,+26 offset,
      // drawn with the tag's own panel / keycap code at 0.5 x the pending TargetScale (so sizes compare 1:1 between values)
      private function hzSetPvTgDraw(b:Sprite, g:*, px:Number, py:Number, T:Object) : void
      {
         var P:Object = this.hzSetPend ? this.hzSetPend : {};
         var tsC:Number = this.hz34Eff(P.ContainerScale != undefined && !isNaN(Number(P.ContainerScale)) ? this.hz34ScClamp(P.ContainerScale) : this.hzTgScale);
         var tsH:Number = this.hz34Eff(P.HoverScale != undefined && !isNaN(Number(P.HoverScale)) ? this.hz34ScClamp(P.HoverScale) : this.hz30Hover);
         // v0.30: the sample follows the slider in focus (container window or hover cards); others show the hover size
         var pvC:Boolean = this.hz30PvKey == "ContainerScale";
         var ts:Number = pvC ? tsC : tsH;
         var tsDef:Number = pvC ? 1.125 : 1;
         var xs:int = P.CrosshairStyle != undefined ? int(P.CrosshairStyle) : this.hzXhStyle;
         var orng:int = P.ObjectRing != undefined ? int(P.ObjectRing) : this.hzObjRing;
         var sh:int = P.ScreenHeight != undefined ? int(P.ScreenHeight) : this.hzScrH;
         var ppu:Number = 1080 > 0 && sh >= 360 ? sh / 1080 * HZ_SCALE * ts : 0;
         var l1:String = (pvC ? "Container window x" : "Hover cards x") + this.hzSetNum(ts) + " (not HUD SCALE)" + (ppu > 0 ? "  =  " + this.hzSetNum(Math.round(ppu * 100) / 100) + " px per unit" : "");
         var l2:String = "Ring: " + String(HZ_RING_NAMES[Math.max(0,Math.min(2,orng))]).toLowerCase() + "   Crosshair: " + String(HZ_XH_NAMES[Math.max(0,Math.min(3,xs))]).toLowerCase();
         this.hzSetPvFrame(b,g,px,py,T,"CROSSHAIR",[l1,l2,"Dashed outline = default size (" + this.hzSetNum(tsDef) + ")."]);
         if(!this.hzSetPvTg)
         {
            var p:Sprite = new Sprite();
            p.mouseEnabled = false; p.mouseChildren = false;
            this.hzSetPvTg = p;
            var c:Sprite = new Sprite(); p.addChild(c);
            this.hzSetPvTgCard = c;
            var cg:Sprite = new Sprite(); c.addChild(cg);
            var o:Object = {"g":cg};
            o.n = this.hzT(c,"MED PACK",18,11,200,16,"sb","main",2); this.hzHdr19(o.n);
            o.m = this.hzT(c,"x3  ·  0.1",100,14,96,12,"rg","mut",0.5,"right");
            o.k = this.hzT(c,"E",0,0,60,12,"bd","col",0,"left");
            o.l = this.hzT(c,"TAKE",0,0,120,13,"sb","main",1.6);
            this.hzChip13(o.l,"Hover");
            o.ov = new Sprite(); c.addChild(o.ov);
            this.hzSetPvTgTf = o;
            p.addChild(new Sprite());   // scene layer (crosshair, ring, ghost) above the card
         }
         var pv:Sprite = this.hzSetPvTg;
         if(pv.parent != this.HorizonSettings_mc) { this.HorizonSettings_mc.addChild(pv); }
         this.HorizonSettings_mc.setChildIndex(pv,this.HorizonSettings_mc.numChildren - 1);
         var tf:Object = this.hzSetPvTgTf;
         TextField(tf.n).text = this.hzUC("Med Pack");
         // sample tag, same metrics as the item tag (stripe, title, meta, divider, keycap row)
         var CW:Number = 200;
         var CH:Number = 86;
         var kt:TextField = TextField(tf.k);
         this.hzTxtTint(kt,this.hzIconCol(HZ_ACCENT));
         var kw:Number = Math.max(26,Math.round(this.hzTW(kt) + 16));
         var lt:TextField = TextField(tf.l);
         var loTk:Object = this.hzTxtObj(lt); if(loTk) { this.hzApplyFmt(loTk); }
         CW = Math.max(200,18 + kw + 7 + this.hzTW(lt) + 14);
         var cgg:* = Sprite(tf.g).graphics;
         cgg.clear();
         var opS:Number = this.hzCardOpacity;
         this.hzCardOpacity = P.ContainerOpacity != undefined ? Number(P.ContainerOpacity) : this.hzContOpacity;
         this.hzPanel(cgg,CW,CH,18,-1,-1);
         this.hzCardOpacity = opS;
         cgg.beginFill(this.hzIconCol(HZ_ACCENT),1); cgg.drawRoundRect(5,8,3,CH - 16,3,3); cgg.endFill();
         this.hzT19Line(cgg,40,CW,false);
         Sprite(tf.ov).graphics.clear();
         this.hzKeycap(cgg,18,48,kw,24,this.hzIconCol(HZ_ACCENT),1,Sprite(tf.ov).graphics);
         kt.width = Math.round(this.hzTW(kt) + 5);
         kt.x = Math.round(18 + (kw - this.hzTW(kt)) / 2 - 2); this.hzTxtTop(kt,this.hzCapTop(kt,60));
         lt.x = 18 + kw + 7; this.hzTxtTop(lt,this.hzCapTop(lt,60));
         TextField(tf.m).x = CW - 14 - 96; this.hzTxtTop(TextField(tf.m),14);
         // v0.31: CONTAINER WINDOW SCALE previews a stand-in container window (header, item rows, selected row,
         // divider, take / transfer bar); HOVER CARD SCALE and the crosshair rows keep the item hover card
         var card:Sprite = this.hzSetPvTgCard;
         var cont:Sprite = null;
         try { cont = this.hz31PvCont(pv,P); } catch(errPc:Error) { cont = null; }
         if(pvC && cont != null)
         {
            card.visible = false;
            cont.visible = true;
            card = cont;
            CW = HZ31_PC_W;
            CH = HZ31_PC_H;
         }
         else
         {
            card.visible = true;
            if(cont != null) { cont.visible = false; }
         }
         // scene
         var sc:Number = pvC ? 0.5 * 226 / 270 * ts : 0.5 * ts;   // the container stand-in is wider: fit the 226 px column at 1.6
         var cx:Number = px + (pvC ? 14 : 34);
         var cy:Number = py + 58;
         card.scaleX = card.scaleY = sc;
         card.x = Math.round(cx + 26 * sc); card.y = Math.round(cy + 26 * sc);
         var scene:Sprite = Sprite(pv.getChildAt(pv.numChildren - 1));
         var sg:* = scene.graphics;
         sg.clear();
         // default-size ghost when the pending size differs
         if(Math.abs(ts - tsDef) > 0.001)
         {
            var gs:Number = sc / ts * tsDef;
            var gx0:Number = Math.round(cx + 26 * gs);
            var gy0:Number = Math.round(cy + 26 * gs);
            var gw:Number = CW * gs;
            var gh:Number = CH * gs;
            var d:Number = 0;
            sg.beginFill(uint(T.mut),0.55);
            while(d < gw) { sg.drawRect(gx0 + d,gy0,Math.min(4,gw - d),1); sg.drawRect(gx0 + d,gy0 + gh,Math.min(4,gw - d),1); d += 8; }
            d = 0;
            while(d < gh) { sg.drawRect(gx0,gy0 + d,1,Math.min(4,gh - d)); sg.drawRect(gx0 + gw,gy0 + d,1,Math.min(4,gh - d)); d += 8; }
            sg.endFill();
         }
         // object ring (vanilla-like stand-in drawn by us) when the pending ObjectRing would show it for an item
         if(orng == 2)
         {
            sg.lineStyle(1,uint(T.mut),0.8); sg.drawCircle(cx + 2,cy - 30,9); sg.moveTo(cx + 2,cy - 21); sg.lineTo(cx,cy - 6); sg.lineStyle();
         }
         // crosshair glyph
         if(xs == 0)
         {
            sg.lineStyle(2,0xF2F7F9,0.9); sg.drawCircle(cx,cy,11); sg.lineStyle();
         }
         else if(xs == 1)
         {
            sg.beginFill(0x000000,0.45); sg.drawCircle(cx,cy,4.6); sg.endFill();
            sg.beginFill(0xF2F7F9,0.95); sg.drawCircle(cx,cy,3.6); sg.endFill();
         }
         else if(xs == 2)
         {
            var arms:Array = [[5,-1,6,2],[-11,-1,6,2],[-1,5,2,6],[-1,-11,2,6]];
            for each(var a1:Array in arms) { sg.beginFill(0x000000,0.4); sg.drawRect(cx + a1[0] - 1,cy + a1[1] - 1,a1[2] + 2,a1[3] + 2); sg.endFill(); }
            for each(var a2:Array in arms) { sg.beginFill(0xF2F7F9,0.95); sg.drawRect(cx + a2[0],cy + a2[1],a2[2],a2[3]); sg.endFill(); }
            sg.beginFill(this.hzIconCol(HZ_ACCENT),1); sg.drawRect(cx - 1,cy - 1,2,2); sg.endFill();
         }
         pv.visible = true;
      }

      // Opacity preview: an original striped "scene" with a HUD card sample (CardOpacity) and a container card
      // sample (ContainerOpacity) on top, both drawn with the real panel code
      private function hzSetPvOpDraw(b:Sprite, g:*, px:Number, py:Number, T:Object) : void
      {
         var P:Object = this.hzSetPend ? this.hzSetPend : {};
         var co:Number = P.CardOpacity != undefined ? Number(P.CardOpacity) : this.hzCardOpacity;
         var ko:Number = P.ContainerOpacity != undefined ? Number(P.ContainerOpacity) : this.hzContOpacity;
         this.hzSetPvFrame(b,g,px,py,T,"OPACITY",["HUD cards: x" + this.hzSetNum(co) + "   Container: x" + this.hzSetNum(ko),"The settings window itself always","uses a fixed fill."]);
         this.hzWT(b,"HUD CARD",px + 22,py + 44,180,9,"sb",uint(T.mut),1.6);
         this.hzWT(b,"CONTAINER / CROSSHAIR CARD",px + 22,py + 128,200,9,"sb",uint(T.mut),1.6);
         if(!this.hzSetPvOp) { this.hzSetPvOp = new Sprite(); this.hzSetPvOp.mouseEnabled = false; }
         var pv:Sprite = this.hzSetPvOp;
         if(pv.parent != this.HorizonSettings_mc) { this.HorizonSettings_mc.addChild(pv); }
         this.HorizonSettings_mc.setChildIndex(pv,this.HorizonSettings_mc.numChildren - 1);
         var pg:* = pv.graphics;
         pg.clear();
         var X:Number = px + 14;
         var cols:Array = [0xD8B070,0x6E94B8,0xE8E2D0,0x8A6A48,0x5C7A5A];
         var k:int = 0;
         // scenery behind both samples: diagonal-free vertical bands so the translucency is obvious
         while(k < 10)
         {
            pg.beginFill(uint(cols[k % cols.length]),1);
            pg.drawRect(X + k * 20,py + 60,20,58);
            pg.drawRect(X + k * 20,py + 144,20,70);
            pg.endFill();
            k++;
         }
         var save:Number = this.hzCardOpacity;
         this.hzCardOpacity = co;
         this.hzSetPvPanel(pg,X + 10,py + 68,180,42);
         this.hzCardOpacity = ko;
         this.hzSetPvPanel(pg,X + 10,py + 152,180,54);
         this.hzCardOpacity = save;
         pv.visible = true;
      }

      private function hzSetPvPanel(g:*, x:Number, y:Number, w:Number, h:Number) : void
      {
         var lt:Boolean = this.hzLight();
         g.beginFill(this.hzPanelFill(),this.hzPanelA(lt ? 0.96 : 0.92));
         g.drawRoundRect(x,y,w,h,24,24);
         g.endFill();
         g.beginFill(this.hzIconCol(HZ_ACCENT),1);
         g.drawRoundRect(x,y + 10,4,h - 20,4,4);
         g.endFill();
         var tc:uint = this.hzTxtMain();
         g.beginFill(tc,0.85); g.drawRoundRect(x + 16,y + 12,80,6,6,6); g.endFill();
         g.beginFill(tc,0.45); g.drawRoundRect(x + 16,y + 24,120,4,4,4); g.endFill();
      }

      // Afflictions preview: two sample chips (an injury + an environmental hazard with exposure) in the pending layout,
      // drawn with the afflictions card's own panel / disc / glyph code
      private function hzSetPvAfDraw(b:Sprite, g:*, px:Number, py:Number, T:Object) : void
      {
         var P:Object = this.hzSetPend ? this.hzSetPend : {};
         var mode:int = P.AfflictionLayout != undefined ? Math.max(0,Math.min(2,int(P.AfflictionLayout))) : this.hzAfLayout;
         this.hzSetPvFrame(b,g,px,py,T,"AFFLICTIONS",["Sample: one affliction and one","environmental hazard (exposure bar).","Layout: " + String(HZ_AFLAY_NAMES[mode]).toLowerCase() + "."]);
         if(!this.hzSetPvAf)
         {
            var p:Sprite = new Sprite();
            p.mouseEnabled = false; p.mouseChildren = false;
            this.hzSetPvAf = p;
            var i:int = 0;
            while(i < 2)
            {
               var c:Sprite = new Sprite(); p.addChild(c);
               var body:Sprite = new Sprite(); c.addChild(body);
               var lb:TextField = this.hzT(c,"",48,8,240,13,"sb","acc",2);
               this.hzHdr19(lb);
               this.hzVit13(lb);
               var sb:TextField = this.hzT(c,"",48,24,200,13,"sb","col",0.6);
               this.hzVit13(sb);
               this.hzSetPvAfCh.push({"c":c,"b":body,"l":lb,"s":sb});
               i++;
            }
         }
         var pv:Sprite = this.hzSetPvAf;
         if(pv.parent != this.HorizonSettings_mc) { this.HorizonSettings_mc.addChild(pv); }
         this.HorizonSettings_mc.setChildIndex(pv,this.HorizonSettings_mc.numChildren - 1);
         var samples:Array = [{"name":"Affliction","kind":"injury","env":false},{"name":"Radiation","kind":"radiation","env":true}];
         var soak:Number = 0.45;
         var icons:Boolean = mode == 2;
         var bg:uint = this.hzDarkText() ? this.hzMix(this.hzPanelFill(),0x000000,0.14) : 0x060A0E;
         var x:Number = 0;
         var y:Number = 0;
         var maxW:Number = 0;
         var rowH:Number = 48;
         var sz13:int = this.hzAf13Sz();
         var grow:int = Math.max(0,sz13 - 13);
         var barY:int = 23 + grow + sz13 + 3;
         var j:int = 0;
         this.hzAfFmt13();
         while(j < this.hzSetPvAfCh.length)
         {
            var ch:Object = this.hzSetPvAfCh[j];
            var a:Object = samples[j];
            var cg:* = Sprite(ch.b).graphics;
            cg.clear();
            var lt:TextField = TextField(ch.l);
            var st:TextField = TextField(ch.s);
            var col:uint = a.env ? HZ_AMB : HZ_RED;
            var ic:uint = this.hzIconCol(col);
            var two:Boolean = a.env;
            var h:Number = (!icons && two) ? Math.max(48, barY + 9) : 48;
            lt.visible = !icons;
            st.visible = !icons && a.env;
            if(!icons)
            {
               lt.text = this.hzUC(String(a.name));
               this.hzTxtTint(lt,a.env ? null : HZ_RED);
               if(a.env) { st.text = "Exposure " + Math.round(soak * 100) + "%"; this.hzTxtTop(lt,7); this.hzTxtTop(st,23 + grow); }
               else { this.hzTxtTop(lt,15); }
            }
            var w:Number = icons ? 48 : Math.max(190,Math.max(this.hzTW(lt),a.env ? this.hzTW(st) : 0) + 48 + 18);
            this.hzPanel(cg,w,h,16);
            this.hzTileDisc(cg,24,24,16,-1);
            cg.lineStyle(1.2,ic,0.55,true); cg.drawCircle(24,24,16); cg.lineStyle();
            this.hzGlyph(cg,String(a.kind),24,24,ic,bg);
            if(a.env && !icons)
            {
               var bw:Number = w - 48 - 14;
               var tr:uint = this.hzDarkText() ? 0x000000 : 0xFFFFFF;
               cg.beginFill(tr,0.14); cg.drawRoundRect(48,barY,bw,4,4,4); cg.endFill();
               cg.beginFill(ic,1); cg.drawRoundRect(48,barY,Math.max(4,bw * soak),4,4,4); cg.endFill();
            }
            var cs:Sprite = Sprite(ch.c);
            cs.x = x; cs.y = y;
            if(mode == 1) { x += w + 8; maxW = x - 8; if(h > rowH) { rowH = h; } }
            else { y += h + 8; maxW = Math.max(maxW,w); }
            j++;
         }
         var th:Number = mode == 1 ? rowH : y - 8;
         var sc:Number = Math.min(0.9,206 / Math.max(1,maxW),170 / Math.max(1,th));
         pv.scaleX = pv.scaleY = sc;
         pv.x = Math.round(px + (226 - maxW * sc) / 2);
         pv.y = Math.round(py + 40 + (180 - th * sc) / 2);
         pv.visible = true;
      }

      private function hzSetDrawCursor() : void
      {
         var g:* = this.hzSetCursor.graphics;
         g.clear();
         g.beginFill(0x000000,0.35);
         g.moveTo(2,3); g.lineTo(2,21); g.lineTo(7,16); g.lineTo(11,24); g.lineTo(14,22); g.lineTo(10,15); g.lineTo(17,15); g.lineTo(2,3);
         g.endFill();
         g.lineStyle(1,0x050C12,0.9);
         g.beginFill(HZ_ACCENT,1);
         g.moveTo(0,0); g.lineTo(0,18); g.lineTo(5,13); g.lineTo(9,21); g.lineTo(12,19); g.lineTo(8,12); g.lineTo(15,12); g.lineTo(0,0);
         g.endFill();
         g.lineStyle();
      }

      // Mouse from the SFSE plugin: nx, ny = 0..1 of the game client area.
      public function hzSettingsMouse(nx:Number, ny:Number, down:Boolean) : void
      {
         if(this.hzPopLayers != null && this.hzPopLayers.length > 0)
         {
            var topM:String = this.hzPopTop();
            if(topM == "log" || topM == "mlconfirm") { this.hzMsglogMouse(nx,ny,down); return; }
            return;
         }
         if(this.hzArrange) { this.hzArrMouse(nx,ny,down); return; }
         if(!this.hzSetIsOpen || !this.HorizonSettings_mc || isNaN(nx) || isNaN(ny)) { this.hzSetPrevDown = down; return; }
         var vr:Rectangle = Extensions.visibleRect;
         var gp:Point = null;
         if(vr != null && vr.width >= 1) { gp = new Point(vr.x + nx * vr.width,vr.y + ny * vr.height); }
         else { gp = new Point(nx * 1920,ny * 1080); }
         var lp:Point = globalToLocal(gp);
         var mx:Number = lp.x - this.HorizonSettings_mc.x;
         var my:Number = lp.y - this.HorizonSettings_mc.y;
         var kb35:Boolean = false;
         if(isNaN(this.hz35Mx) || Math.abs(mx - this.hz35Mx) > 2 || Math.abs(my - this.hz35My) > 2) { kb35 = this.hz35Kb; this.hz35Kb = false; this.hz35Mx = mx; this.hz35My = my; }
         this.hzSetDrawCursor();
         this.hzSetCursor.x = mx;
         this.hzSetCursor.y = my;
         this.hzSetCursor.visible = true;
         var pressed:Boolean = down && !this.hzSetPrevDown;
         this.hzSetPrevDown = down;
         var hit:Object = null;
         var hid:String = "";
         for each(var h:Object in this.hzSetHits)
         {
            if(mx >= h.x && mx <= h.x + h.w && my >= h.y && my <= h.y + h.h)
            {
               hit = h; hid = h.id;
               if(String(h.id).indexOf("bar") == 0) { break; } // slider wins over its row
            }
         }
         var dirty:Boolean = false;
         var rows:Array = this.hzSetRows(this.hzSetTab);
         if(!down) { this.hzSetDrag = -1; }
         if(this.hzSetDrag >= 0 && this.hzSetDrag < rows.length)
         {
            this.hzSetBarAt(rows[this.hzSetDrag],this.hzSetDrag,mx);
            dirty = true;
         }
         else if(pressed && hit != null)
         {
            var id:String = String(hit.id);
            this.hz37Press(id,rows);   // v0.37: a click elsewhere drops a pending confirm / the name entry
            if(id == "ok") { this.hzSetApply(); return; }
            if(id == "cancel") { this.hzSetCancel(); return; }
            if(id == "arrange") { this.hzArrEnter(); return; }
            if(id.indexOf("tab") == 0) { this.hzSetTab = int(id.substr(3)); this.hzSetRow = 0; this.hzSetScroll = 0; dirty = true; }
            else if(id.indexOf("lt") == 0 || id.indexOf("rt") == 0)
            {
               // cycler arrows: left = previous, right = next
               var ci:int = int(id.substr(2));
               this.hzSetRow = ci;
               this.hzSetChange(rows[ci],id.indexOf("lt") == 0 ? -1 : 1);
               dirty = true;
            }
            else if(id.indexOf("sw") == 0)
            {
               // palette swatch: pick it directly
               var sp:Array = id.substr(2).split("_");
               var swr:int = int(sp[0]);
               this.hzSetRow = swr;
               var swRow:Object = rows[swr];
               if(swRow && this.hzSetPend) { this.hzSetPend[swRow.k] = int(sp[1]); this.hzSetLive(this.hzSetPend); }
               dirty = true;
            }
            else if(id == "strk")
            {
               var sf:Number = Math.max(0,Math.min(1,(my - Number(hit.ty)) / Math.max(1,Number(hit.th))));
               this.hzSetScrollBy(int(Math.round(sf * this.hzSetMaxScroll)) - this.hzSetScroll);
               dirty = true;
            }
            else if(id.indexOf("zg") == 0)
            {
               var zi:int = int(id.substr(2));
               this.hzSetRow = zi;
               if(rows[zi] && !rows[zi].dis) { this.hz34ZToggle(String(rows[zi].k)); }
               dirty = true;
            }
            else if(id.indexOf("bar") == 0)
            {
               var bi:int = int(id.substr(3));
               this.hzSetRow = bi;
               this.hzSetDrag = bi;
               this.hzSetBarAt(rows[bi],bi,mx);
               dirty = true;
            }
            else if(id.indexOf("inf") == 0) { this.hzSetRow = int(id.substr(3)); dirty = true; }   // v0.35: the "i" selects, never toggles
            else if(id.indexOf("row") == 0)
            {
               var ri:int = int(id.substr(3));
               this.hzSetRow = ri;
               var rr:Object = rows[ri];
               if(rr.t == "b" || rr.t == "a" || rr.t == "c" || rr.t == "r" || rr.t == "q" || rr.t == "x" || rr.t == "m" || rr.t == "p") { this.hzSetChange(rr,1); if(this.hzArrange) { return; } }
               else if(rr.t == "z" && !rr.dis) { this.hz34ZToggle(String(rr.k)); }
               dirty = true;
            }
         }
         if(hid.indexOf("bar") == 0) { hid = "row" + hid.substr(3); }
         else if(hid.indexOf("zg") == 0) { hid = "row" + hid.substr(2); }
         else if(hid.indexOf("sw") == 0) { hid = "row" + hid.substr(2).split("_")[0]; }
         if(hid != this.hzSetHover) { this.hzSetHover = hid; dirty = true; }
         if(kb35) { dirty = true; }   // v0.35: mouse moved after key input -> hide the keyboard tooltip
         if(dirty) { this.hzSetDraw(); }
      }

      private function hzSetBarAt(r:Object, idx:int, mx:Number) : void
      {
         if(r == null || (r.t != "n" && r.t != "z") || r.dis) { return; }
         var bx:Number = HZ_SET_W - 400;
         var bw:Number = 260;
         for each(var h:Object in this.hzSetHits) { if(h.id == "bar" + idx) { bx = h.bx; bw = h.bw; } }
         var f:Number = Math.max(0,Math.min(1,(mx - bx) / bw));
         if(r.t == "z") { this.hz34ZAt(r,f); return; }   // v0.34: dragging a GLOBAL size makes it CUSTOM
         this.hzSetPend[r.k] = this.hzSetSnap(r.mn + f * (r.mx - r.mn),r);
         this.hzSetLive(this.hzSetPend);
      }
      // ===== ARRANGE CARDS (layout edit mode, driven by the same virtual mouse/keys as the settings window) =====
      private function hzLayClips(k:String) : Array
      {
         switch(k)
         {
            case "Jetpack": return [this.HorizonCard_mc];
            case "Vitals": return [this.HorizonVitals_mc];
            case "Planet": return [this.HorizonEnv_mc];
            case "Afflictions": return [this.HorizonAffl_mc];
            case "Ammo": return [this.HorizonAmmo_mc];
            case "Quests": return [this.HorizonQuest_mc,this.HorizonCompactQuest_mc].filter(this.hzNotNull);
            case "Compass": return [this.HorizonCompass_mc];
            case "Compact": return [this.HorizonCompact_mc];
            case "Character": return [this.HorizonChar_mc].filter(this.hzNotNull);
            case "Enemy": return [this.HorizonEnemy_mc].filter(this.hzNotNull);
            case "Stealth": return [this.HorizonStealth_mc].filter(this.hzNotNull);
            case "XpToast": return [this.HorizonXp_mc].filter(this.hzNotNull);
            case "Subtitle": case "Speaker": case "Dialogue": case "MissionToast": case "HudMessages": return this.hz31PxOn(k) ? [this.hz31Px(k)] : [];
         }
         return [];
      }

      private function hzNotNull(o:*, i:int, a:Array) : Boolean
      {
         return o != null;
      }

      private function hzLayHas(k:String) : Boolean
      {
         return this.hzLay[k] != null && this.hzLay[k] != undefined;
      }

      private function hzIniLayoutKey(k:String, nv:Number) : void
      {
         if(isNaN(nv) || k.length < 2) { return; }
         var axis:String = k.charAt(k.length - 1);
         if(axis != "x" && axis != "y") { return; }
         var pre:String = k.substr(0,k.length - 1);
         for each(var lk:String in HZ_LAY_KEYS)
         {
            if(lk.toLowerCase() == pre)
            {
               if(nv < 0 || nv > 1) { delete this.hzLay[lk]; return; }
               var o:Object = this.hzLay[lk];
               if(!o) { o = {"x":0,"y":0,"hx":false,"hy":false}; this.hzLay[lk] = o; }
               o[axis] = nv;
               o["h" + axis] = true;
               o["n" + axis] = false;   // v0.30: legacy fraction, converted to an edge anchor on layout
               this.hzLaidOut = false;
               return;
            }
         }
      }

      // the cards that can be arranged in the current mode
      private function hzArrList() : Array
      {
         if(this.hz41SA) { return this.hz41SAList(); }   // v0.41.0: ARRANGE SCANNER: the mock scanner panels
         var r:Array = [];
         var i:int = 0;
         while(i < HZ_LAY_KEYS.length)
         {
            var k:String = HZ_LAY_KEYS[i];
            var ok:Boolean = true;
            switch(k)
            {
               case "Jetpack": ok = !this.hzCompact && this.hzShowJetpack; break;
               case "Vitals": ok = !this.hzCompact && this.hzShowVitals; break;
               case "Planet": ok = (!this.hzCompact || this.hzPillOn()) && this.hzShowPlanet; break;
               case "Afflictions": ok = !this.hzCompact && this.hzShowAfflictions; break;
               case "Ammo": ok = this.hzShowAmmo; break;
               case "Quests": ok = this.hzShowQuests; break;
               case "Compass": ok = this.hzShowCompass; break;
               case "Compact": ok = this.hzCompact; break;
               case "Character": ok = this.hzShowChar; break;
               case "Enemy": ok = this.hzEnemyBarOn; break;
               case "Stealth": ok = this.hzStealthOn; break;
               case "XpToast": ok = this.hzXpToastOn; break;
               case "Subtitle": case "Speaker": case "Dialogue": case "MissionToast": case "HudMessages": ok = this.hz31PxOn(k); break;   // v0.31 / v0.32: Comms proxies
            }
            if(ok)
            {
               var lcs:Array = this.hzLayClips(k);
               var c:Sprite = this.hz34C("Quests") && k == "Quests" ? this.HorizonCompactQuest_mc : (lcs.length > 0 ? Sprite(lcs[0]) : null);
               if(c) { r.push({"k":k,"n":HZ_LAY_NAMES[i],"c":c}); }
            }
            i++;
         }
         try { if(this.hz42ScAvail() && this.hz42ScPx != null) { r.push({"k":HZ42_SC_KEY,"n":"SCOPE: HOLD BREATH","c":this.hz42ScPx}); } } catch(err42a:Error) { }   // v0.42.0 r2
         return r;
      }

      private function hzArrShowAll() : void
      {
         var on:Array = [];
         if(!this.hz41SA) { for each(var e:Object in this.hzArrList()) { on.push(e.c); } }   // v0.41.0: ARRANGE SCANNER hides the HUD cards
         for each(var c:Sprite in [this.HorizonCard_mc,this.HorizonVitals_mc,this.HorizonEnv_mc,this.HorizonAffl_mc,this.HorizonAmmo_mc,this.HorizonQuest_mc,this.HorizonCompactQuest_mc,this.HorizonCompass_mc,this.HorizonCompact_mc,this.HorizonChar_mc,this.HorizonEnemy_mc,this.HorizonStealth_mc,this.HorizonXp_mc])
         {
            if(c) { this.hzShow(c,on.indexOf(c) >= 0); }
         }
         try { this.hz26CharSync(); this.hz26XpSync(); this.hzE19Sync(); } catch(err26:Error) { }
      }

      private function hzLayCopy(src:Object) : Object
      {
         var r:Object = {};
         for(var k:String in src)
         {
            var o:Object = src[k];
            if(!o) { continue; }
            var c:Object = {};
            for(var f:String in o) { c[f] = o[f]; }
            c.hx = true; c.hy = true;
            r[k] = c;
         }
         return r;
      }

      private function hzVis() : Rectangle
      {
         var vr:Rectangle = Extensions.visibleRect;
         if(vr != null && vr.width >= 100 && stage != null)
         {
            var tl:Point = globalToLocal(new Point(vr.left,vr.top));
            var br:Point = globalToLocal(new Point(vr.right,vr.bottom));
            if(!isNaN(tl.x) && br.x - tl.x >= 100) { return new Rectangle(tl.x,tl.y,br.x - tl.x,br.y - tl.y); }
         }
         return new Rectangle(0,0,1920,1080);
      }

      private function hzArrEnter() : void
      {
         if(this.hzArrange) { return; }
         this.hzLayOrig = this.hzLayCopy(this.hzLay);
         this.hz42VLOrig = this.hz42VL;   // v0.42.0: CANCEL restores the vitals layout
         this.hz42ScOrig = {"x":this.hz42ScX,"y":this.hz42ScY,"s":this.hz42ScS};   // v0.42.0 r2: CANCEL restores the scope chip
         this.hzArrange = true;
         this.hzArrDrag = null;
         this.hzArrTbDrag = false;
         this.hzArrSel = null;
         this.hzArrPrev = true; // ignore the click that opened the editor
         if(this.HorizonSettings_mc) { this.HorizonSettings_mc.visible = false; }
         if(this.hzArr_mc == null)
         {
            this.hzArr_mc = new Sprite();
            this.hzArr_mc.mouseEnabled = false;
            this.hzArr_mc.mouseChildren = false;
            this.hzArrCursor = new Sprite();
            var g:* = this.hzArrCursor.graphics;
            g.beginFill(0x000000,0.35);
            g.moveTo(2,3); g.lineTo(2,21); g.lineTo(7,16); g.lineTo(11,24); g.lineTo(14,22); g.lineTo(10,15); g.lineTo(17,15); g.lineTo(2,3);
            g.endFill();
            g.lineStyle(1,0x050C12,0.9);
            g.beginFill(0xFFFFFF,1);
            g.moveTo(0,0); g.lineTo(0,18); g.lineTo(5,13); g.lineTo(9,21); g.lineTo(12,19); g.lineTo(8,12); g.lineTo(15,12); g.lineTo(0,0);
            g.endFill();
         }
         try { this.hz42ScSync(); } catch(err42e:Error) { }   // v0.42.0 r2: the scope proxy (under the ARRANGE layer)
         addChild(this.hzArr_mc); // topmost
         this.hzEqLayout();
         this.hzArr_mc.visible = true;
         this.hzRefreshVisibility();
         this.hzArrDraw();
      }

      // save=true: keep positions and write the INI (with the pending settings) then close everything.
      // save=false: revert positions and return to the settings window.
      private function hzArrExit(save:Boolean) : void
      {
         if(!this.hzArrange) { return; }
         this.hzArrange = false;
         if(this.hz41SA) { this.hz41SAEnd(save); }   // v0.41.0: keep or restore the pending [Scanner] positions
         this.hzArrDrag = null;
         this.hzArrTbDrag = false;
         if(this.hzArr_mc) { this.hzArr_mc.visible = false; while(this.hzArr_mc.numChildren > 0) { this.hzArr_mc.removeChildAt(0); } this.hzArr_mc.graphics.clear(); }
         if(save)
         {
            this.hzLayOrig = null;
            this.hz42ScOrig = null;
            this.hzLaidOut = this.hzLayout();
            try { this.hz31PxSync(); } catch(err31f:Error) { }
            if(this.hzSetIsOpen) { this.hzSetApply(); }
            else { this.hzSetSaveText = this.hzBuildIniText(this.hzSetCurrent()); }
         }
         else
         {
            if(this.hzLayOrig) { this.hzLay = this.hzLayOrig; }
            this.hzLayOrig = null;
            if(this.hz42ScOrig != null) { this.hz42ScPut(this.hz42ScOrig.x,this.hz42ScOrig.y,this.hz42ScOrig.s); }   // v0.42.0 r2: CANCEL
            this.hz42ScOrig = null;
            if(this.hz42VLOrig >= 0 && this.hz42VLOrig != this.hz42VL) { this.hz42VL = this.hz42VLOrig; if(this.hzSetPend != null) { this.hzSetPend.VitalsLayout = this.hz42VL; } try { this.hz42VitApply(); } catch(err42x:Error) { } }   // v0.42.0
            this.hzLaidOut = this.hzLayout();
            try { this.hz31PxSync(); } catch(err31e:Error) { }
            if(this.hzSetIsOpen && this.HorizonSettings_mc)
            {
               addChild(this.HorizonSettings_mc);
               this.HorizonSettings_mc.visible = true;
               this.hzSetDraw();
            }
         }
         this.hzRefreshVisibility();
         try { this.hz42ScSync(); } catch(err42p:Error) { }   // v0.42.0 r2: the scope proxy only shows in ARRANGE
         try { this.hz40Apply(); } catch(err42h:Error) { }   // v0.42.0 r2: re-apply the scan hide (ARRANGE closed while the scanner opened)
      }

      private function hzArrReset() : void
      {
         if(this.hz41SA) { this.hz41SAReset(); return; }
         this.hzLay = {};
         this.hzVitOff = 0;
         if(this.hz30Mod["scope"] === 1) { try { this.hz42ScPut(0,0,1); } catch(err42z:Error) { } }   // v0.42.0 r2: the scope chip back to the game's spot and size (r3: only with the Scope module)
         this.hzLaidOut = this.hzLayout();
         this.hzArrDraw();
      }

      private function hzArrStore(k:String, c:Sprite) : void
      {
         if(this.hz41SA) { this.hz41SAStore(k,c); return; }
         if(k == "ScopeChip") { try { this.hz42ScFromPx(c); } catch(err42f:Error) { } return; }   // v0.42.0 r2: offsets, not a card anchor
         var vr:Rectangle = this.hzVis();
         var o:Object = {"x":Math.max(0,Math.min(1,(c.x - vr.x) / vr.width)),"y":Math.max(0,Math.min(1,(this.hzFadeBase(c) - vr.y) / vr.height)),"hx":true,"hy":true};
         // v0.30: store edge-anchored offsets (the 0-1 fractions stay only as a fallback)
         try
         {
            var cw0:Number = this.hzCW(c) > 1 ? this.hzCW(c) : HZ_W * HZ_SCALE * this.hzHudScale;
            var ch0:Number = this.hzCH(c) > 1 ? this.hzCH(c) : 60 * HZ_SCALE * this.hzHudScale;
            var sx0:Number = c.x;
            var sy0:Number = this.hzFadeBase(c);
            if(this.hz31PxKey(c) != null) { var po:Point = this.hz33PxOff(k); sx0 -= po.x; sy0 -= po.y; }   // v0.33: store without the F11 offset
            this.hz30Anchor(k,o,sx0,sy0,cw0,ch0,new Point(vr.x,vr.y),new Point(vr.right,vr.bottom),true,true);
         }
         catch(errA:Error) { }
         this.hzLay[k] = o;
      }

      private function hzFadeBase(c:Sprite) : Number
      {
         for each(var e:Object in this.hzFades) { if(e.c == c) { return Number(e.base); } }
         return c.y;
      }

      private function hzArrMove(k:String, c:Sprite, x:Number, y:Number) : void
      {
         var vr:Rectangle = this.hzVis();
         var gx:Number = 10;
         x = vr.x + Math.round((x - vr.x) / gx) * gx;
         y = vr.y + Math.round((y - vr.y) / gx) * gx;
         x = Math.max(vr.x,Math.min(vr.right - this.hzCW(c),x));
         y = Math.max(vr.y,Math.min(vr.bottom - this.hzCH(c),y));
         this.hzPlace(c,x,y);
         if(k == "Quests") { for each(var q:Sprite in this.hzLayClips("Quests")) { this.hzPlace(q,x,y); } }
         this.hzArrStore(k,c);
      }

      private function hzArrDraw() : void
      {
         if(!this.hzArr_mc) { return; }
         while(this.hzArr_mc.numChildren > 0) { this.hzArr_mc.removeChildAt(0); }
         var g:* = this.hzArr_mc.graphics;
         g.clear();
         var vr:Rectangle = this.hzVis();
         // dim + light grid (40 px, snapping is 10 px)
         g.beginFill(0x000000,0.25);
         g.drawRect(vr.x,vr.y,vr.width,vr.height);
         g.endFill();
         g.lineStyle(1,0xFFFFFF,0.06);
         var gx:Number = vr.x;
         while(gx <= vr.right) { g.moveTo(gx,vr.y); g.lineTo(gx,vr.bottom); gx += 40; }
         var gy:Number = vr.y;
         while(gy <= vr.bottom) { g.moveTo(vr.x,gy); g.lineTo(vr.right,gy); gy += 40; }
         g.lineStyle(1,HZ_ACCENT,0.18);
         g.moveTo(vr.x + vr.width / 2,vr.y); g.lineTo(vr.x + vr.width / 2,vr.bottom);
         g.lineStyle();
         this.hzArrHits = [];
         try { this.hz31PxSync(); } catch(err31s:Error) { }
         try { this.hz42ScSync(); } catch(err42s:Error) { }   // v0.42.0 r2: the scope proxy at its stored spot / size
         for each(var e:Object in this.hzArrList())
         {
            var c:Sprite = e.c;
            var bx:Number = c.x;
            var by:Number = this.hzFadeBase(c);
            var bw:Number = Math.max(40,this.hzCW(c));
            var bh:Number = Math.max(24,this.hzCH(c));
            var sel:Boolean = e.k == this.hzArrSel || e.k == this.hzArrDrag;
            var hov:Boolean = this.hzArrHover == e.k;
            g.lineStyle(sel ? 2 : 1.5,sel ? HZ_ACCENT : 0xFFFFFF,sel ? 1 : (hov ? 0.85 : 0.5));
            g.beginFill(HZ_ACCENT,sel ? 0.12 : (hov ? 0.08 : 0.03));
            g.drawRoundRect(bx - 4,by - 4,bw + 8,bh + 8,16,16);
            g.endFill();
            g.lineStyle();
            var lbl:TextField = this.hzSText(this.hzArr_mc,String(e.n) + (!this.hz41SA && e.k == "Vitals" ? "  ·  " + this.hz42VLName() : ""),bx,by - 24,Math.max(140,bw),13,sel ? HZ_ACCENT : HZ_VALUE,"left","hdr");
            this.hzArrHits.push({"id":e.k,"x":bx - 4,"y":by - 4,"w":bw + 8,"h":bh + 8,"c":c});
         }
         // toolbar
         var tw:Number = this.hz41SA ? 720 : 580;   // r2: ARRANGE SCANNER has the longer hint
         var tb:Point = this.hz33TbPos(vr,tw,74);
         var tx:Number = tb.x;
         var ty:Number = tb.y;
         this.hzSetBox(g,tx,ty,tw,74,HZ_ACCENT,this.hzArrTbDrag ? 1 : 0.8,0x0B1620,0.92,16);
         this.hzArrHits.push({"id":"tbar","x":tx,"y":ty,"w":tw,"h":74,"c":null});   // before the buttons: they win
         // grip: 2 x 3 dots at the left edge
         var gi:int = 0;
         while(gi < 6)
         {
            g.beginFill(0xFFFFFF,this.hzArrHover == "tbar" || this.hzArrTbDrag ? 0.75 : 0.4);
            g.drawCircle(tx + 9 + (gi % 2) * 5,ty + 29 + int(gi / 2) * 6,1.4);
            g.endFill();
            gi++;
         }
         this.hzSText(this.hzArr_mc,this.hz41SA ? "ARRANGE SCANNER" : "ARRANGE CARDS",tx + 24,ty + 8,300,14,HZ_VALUE,"left","hdr");
         if(this.hz41SA) { this.hzSText(this.hzArr_mc,"Drag a panel  ·  arrows nudge  ·  C compact  ·  L layout  ·  R reset  ·  ENTER save  ·  ESC cancel",tx + 24,ty + 27,tw - 42,13,HZ_LABEL,"left","lbl"); }
         else { this.hzSText(this.hzArr_mc,this.hzArrSel == "ScopeChip" ? "Drag the chip  ·  arrows nudge  ·  - / + size  ·  ENTER save  ·  ESC cancel" : "Drag a card  ·  arrows nudge  ·  L vitals layout  ·  ENTER save  ·  ESC cancel",tx + 24,ty + 27,tw - 42,13,HZ_LABEL,"left","lbl"); }   // v0.42.0: 13 px
         var btn:Array = this.hz41SA ? [["reset","RESET"],["ok","SAVE"],["cancel","CANCEL"]] : [["reset","RESET"],["ok","OK"],["cancel","CANCEL"]];
         var bi:int = 0;
         while(bi < btn.length)
         {
            var bxx:Number = tx + tw - 18 - (3 - bi) * 96 + 6;
            var h:Boolean = this.hzArrHover == btn[bi][0];
            this.hzSetBox(g,bxx,ty + 46,88,22,btn[bi][0] == "ok" ? HZ_ACCENT : 0x5A6A76,h ? 1 : 0.75,btn[bi][0] == "ok" ? HZ_ACCENT : 0x26343F,h ? 0.6 : 0.3,12);
            this.hzSText(this.hzArr_mc,String(btn[bi][1]),bxx,ty + 47,88,13,HZ_VALUE,"center");   // v0.42.0: 13 px in ARRANGE CARDS too
            this.hzArrHits.push({"id":"btn_" + btn[bi][0],"x":bxx,"y":ty + 46,"w":88,"h":22,"c":null});
            bi++;
         }
         if(this.hz41SA) { try { this.hz41SAChips(g); } catch(e41c:Error) { } }   // v0.41.0: COMPACT / LAYOUT chips on the selected panel
         else { try { this.hz42ArrChip(g); } catch(e42c:Error) { } }   // v0.42.0: L LAYOUT chip on the selected vitals card
         if(!this.hz41SA) { try { this.hz42ScChip(g); } catch(e42sc:Error) { } }   // v0.42.0 r2: - SIZE + chip on the selected scope proxy
         if(this.hzArrCursor) { this.hzArr_mc.addChild(this.hzArrCursor); }
      }

      // toolbar spot: default (centered, 42 % down) + the dragged offset, always fully on screen
      private function hz33TbPos(vr:Rectangle, tw:Number, th:Number) : Point
      {
         var x:Number = vr.x + (vr.width - tw) / 2 + this.hzArrTbDX;
         var y:Number = vr.y + vr.height * 0.42 + this.hzArrTbDY;
         x = Math.max(vr.x,Math.min(vr.right - tw,x));
         y = Math.max(vr.y,Math.min(vr.bottom - th,y));
         return new Point(Math.round(x),Math.round(y));
      }
      private function hzArrMouse(nx:Number, ny:Number, down:Boolean) : void
      {
         if(isNaN(nx) || isNaN(ny)) { this.hzArrPrev = down; return; }
         var vr0:Rectangle = Extensions.visibleRect;
         var gp:Point = (vr0 != null && vr0.width >= 1) ? new Point(vr0.x + nx * vr0.width,vr0.y + ny * vr0.height) : new Point(nx * 1920,ny * 1080);
         var lp:Point = globalToLocal(gp);
         var pressed:Boolean = down && !this.hzArrPrev;
         this.hzArrPrev = down;
         if(this.hzArrCursor) { this.hzArrCursor.x = lp.x; this.hzArrCursor.y = lp.y; this.hzArrCursor.visible = true; }
         var dirty:Boolean = false;
         if(this.hzArrTbDrag)
         {
            if(!down) { this.hzArrTbDrag = false; }
            else
            {
               var tvr:Rectangle = this.hzVis();
               this.hzArrTbDX = lp.x - this.hzArrTbGX - (tvr.x + (tvr.width - 580) / 2);
               this.hzArrTbDY = lp.y - this.hzArrTbGY - (tvr.y + tvr.height * 0.42);
               var tcl:Point = this.hz33TbPos(tvr,580,74);   // store the clamped spot
               this.hzArrTbDX = tcl.x - (tvr.x + (tvr.width - 580) / 2);
               this.hzArrTbDY = tcl.y - (tvr.y + tvr.height * 0.42);
            }
            this.hzArrDraw();
            return;
         }
         if(this.hzArrDrag != null)
         {
            if(!down) { this.hzArrDrag = null; dirty = true; }
            else
            {
               for each(var e:Object in this.hzArrList())
               {
                  if(e.k == this.hzArrDrag) { this.hzArrMove(e.k,e.c,lp.x - this.hzArrDX,lp.y - this.hzArrDY); }
               }
               dirty = true;
            }
         }
         var hit:Object = null;
         for each(var h:Object in this.hzArrHits)
         {
            if(lp.x >= h.x && lp.x <= h.x + h.w && lp.y >= h.y && lp.y <= h.y + h.h)
            {
               hit = h;
               if(String(h.id).indexOf("btn_") == 0) { break; } // toolbar wins over cards
            }
         }
         var hid:String = hit ? String(hit.id) : "";
         if(pressed && hit)
         {
            if(hid == "btn_ok") { this.hzArrExit(true); return; }
            if(hid == "btn_cancel") { this.hzArrExit(false); return; }
            if(hid == "btn_reset") { this.hzArrReset(); return; }
            if(hid == "btn_hz41cmp") { this.hz41SAKey("ch:c"); return; }   // v0.41.0: ARRANGE SCANNER chips
            if(hid == "btn_hz41lay") { this.hz41SAKey("ch:l"); return; }
            if(hid == "btn_hz42lay") { this.hz42ArrLay(); return; }   // v0.42.0
            if(hid == "btn_hz42scm") { this.hz42ScStep(-1); return; }   // v0.42.0 r2: scope chip size
            if(hid == "btn_hz42scp") { this.hz42ScStep(1); return; }
            if(hid == "tbar")
            {
               this.hzArrTbDrag = true;
               this.hzArrTbGX = lp.x - Number(hit.x);
               this.hzArrTbGY = lp.y - Number(hit.y);
               this.hzArrDraw();
               return;
            }
            if(hit.c)
            {
               this.hzArrDrag = hid;
               this.hzArrSel = hid;
               this.hzArrDX = lp.x - Sprite(hit.c).x;
               this.hzArrDY = lp.y - this.hzFadeBase(Sprite(hit.c));
               dirty = true;
            }
         }
         if(hid != this.hzArrHover) { this.hzArrHover = hid; dirty = true; }
         if(dirty) { this.hzArrDraw(); }
      }

      private function hzArrKey(code:String) : void
      {
         if(this.hz41SA && this.hz41SAKey(code)) { return; }   // v0.41.0: C compact, L layout, R reset
         if(!this.hz41SA && code != null && code.toLowerCase() == "ch:l") { this.hz42ArrLay(); return; }   // v0.42.0: L = vitals layout
         if(!this.hz41SA && this.hzArrSel == "ScopeChip" && code != null)   // v0.42.0 r2: - / + = scope chip size
         {
            if(code == "ch:-" || code == "ch:_") { this.hz42ScStep(-1); return; }
            if(code == "ch:+" || code == "ch:=") { this.hz42ScStep(1); return; }
         }
         var dx:Number = 0;
         var dy:Number = 0;
         switch(code)
         {
            case "ok": this.hzArrExit(true); return;
            case "cancel": this.hzArrExit(false); return;
            case "left": dx = -10; break;
            case "right": dx = 10; break;
            case "up": dy = -10; break;
            case "down": dy = 10; break;
            case "tabprev":
            case "tabnext":
               var l:Array = this.hzArrList();
               if(l.length == 0) { return; }
               var ci:int = -1;
               var i:int = 0;
               while(i < l.length) { if(l[i].k == this.hzArrSel) { ci = i; } i++; }
               ci = (ci + (code == "tabnext" ? 1 : l.length - 1) + (ci < 0 ? 1 : 0)) % l.length;
               this.hzArrSel = l[ci].k;
               this.hzArrDraw();
               return;
            default: return;
         }
         for each(var e:Object in this.hzArrList())
         {
            if(e.k == this.hzArrSel) { this.hzArrMove(e.k,e.c,e.c.x + dx,this.hzFadeBase(e.c) + dy); }
         }
         this.hzArrDraw();
      }

      // ---- EQUIPMENT card, style 1: two floating tiles (weapon, ammo) + segmented tick meter, no outer card ----
      // ---- EQUIPMENT card, style 1 (v0.17): one panel ----
      //   [icon] Weapon name            (ellipsis at max width; full name for ~3 s after a swap and in ARRANGE)
      //   7  / 654                      (clip large; reserve smaller + dimmer; or "85%" for percent weapons)
      //   3KV LZR                       (ammo type, hidden when unknown)
      // ---- EQUIPMENT card, style 1 (v0.18): one panel, two rows ----
      //   [weapon line-art]  WEAPON NAME...                     (ellipsis; full name ~3 s after swap / in ARRANGE)
      //   [3 cartridges] AMMO TYPE ..................  7  / 654   (clip large+bright, reserve smaller+dimmer)
      private function hzBuildEqNew() : void
      {
         this.hzEqNew = new Sprite();
         this.HorizonAmmo_mc.addChild(this.hzEqNew);
         var p:Sprite = this.hzEqNew;
         this.hzEqBody = new Sprite();
         this.hzEqBody.name = "hzEqBody";
         p.addChild(this.hzEqBody);
         this.hzEqBodyRec = {"h":60};
         this.hzEqWIcon = new Sprite(); this.hzEqWIcon.x = HZ_EQ_P; this.hzEqWIcon.y = HZ_EQ_P;
         p.addChild(this.hzEqWIcon);
         this.hzEqWeap = this.hzText(p,"",HZ_EQ_P + 58,HZ_EQ_P + 4,HZ_EQ_W - HZ_EQ_P * 2 - 58,13,HZ_VALUE,false,"valS");
         this.hzTxtObj(this.hzEqWeap).ls = 1.4;
         this.hzEqAmmoIcon = new Sprite(); this.hzEqAmmoIcon.x = HZ_EQ_P + 2;
         p.addChild(this.hzEqAmmoIcon);
         this.hzEqType = this.hzText(p,"",HZ_EQ_P + 30,0,150,10,HZ_LABEL,false,"sec");
         this.hzTxtObj(this.hzEqType).ls = 1.2;
         this.hzEqCount = this.hzText(p,"--",0,0,110,24,HZ_VALUE,true,"big");
         this.hzEqReserve = this.hzText(p,"",0,0,100,13,HZ_VALUE,false,"sec");
         this.hzBuildEq19();
         this.hzEqDrawWeapIcon("rifle");
         this.hzEqDrawAmmoIcon();
         this.hzEqApplyStyle();
         this.hzEqLayout();
      }

      private function hzEqDrawAmmoIcon() : void
      {
         if(!this.hzEqAmmoIcon) { return; }
         var g:* = this.hzEqAmmoIcon.graphics;
         var c:uint = this.hzIconCol(HZ_ACCENT);
         g.clear();
         var i:int = 0;
         while(i < 3)
         {
            var bx:Number = i * 7;
            g.beginFill(c,0.95);
            g.moveTo(bx,21); g.lineTo(bx,8); g.curveTo(bx,0,bx + 2.5,0); g.curveTo(bx + 5,0,bx + 5,8); g.lineTo(bx + 5,21); g.lineTo(bx,21);
            g.endFill();
            g.beginFill(c,0.55);
            g.drawRect(bx,22,5,2);
            g.endFill();
            i++;
         }
      }

      private function hzTxtObj(tf:TextField) : Object
      {
         for each(var o:Object in this.hzTexts) { if(o.tf == tf) { return o; } }
         return null;
      }

      // set the logical top of a registered text (survives TextScale / guard re-formatting)
      // Unflagged texts use the 4e0c1ef size (round(base*ts), no 9 px floor) so
      // legacy cards keep their y after a reformat. Vitals / affliction (hzVit13)
      // and chip-family lines use hzTextSz19.
      private function hzTxtTop(tf:TextField, top:Number) : void
      {
         var o:Object = this.hzTxtObj(tf);
         top = Math.round(top);
         if(!o) { tf.y = top; return; }
         o.su = undefined;   // v0.26: plain whole-unit top (device-grid snap only via hzTxtTopU)
         var base:Number = (o.role != null && HZ_TY_SIZE[o.role] != undefined) ? Number(HZ_TY_SIZE[o.role]) : Number(o.size);
         var sz:Number = Math.round(base * Math.max(0.8,Math.min(1.3,this.hzTextScale)));
         var card:String = o.chipCard != null && String(o.chipCard).length > 0 ? String(o.chipCard) : "";
         if(o.vit13 || o.af13 || card.length > 0) { sz = this.hzTextSz19(o,base); }
         o.y0 = top + (sz - base) / 2;
         tf.y = top;
      }

      private function hzTxtTint(tf:TextField, col:*) : void
      {
         var o:Object = this.hzTxtObj(tf);
         if(!o) { return; }
         if(o.tint === col) { return; }
         o.tint = col;
         this.hzApplyFmt(o);
      }

      private function hzEqDrawBody() : void
      {
         if(!this.hzEqBody) { return; }
         var h:Number = Number(this.hzEqBodyRec.h);
         var g:* = this.hzEqBody.graphics;
         var lt:Boolean = this.hzLight();
         g.clear();
         g.beginFill(0x000000,0.12 + 0.2 * this.hzOpExtra());
         g.drawRoundRect(-1,1,HZ_EQ_W + 2,h + 2,18,18);
         g.endFill();
         // +0.1 opacity vs the other cards: readable over bright scenery, still translucent
         g.beginFill(this.hzPanelFill(),this.hzPanelA(lt ? 0.95 : 0.88));
         g.drawRoundRect(0,0,HZ_EQ_W,h,16,16);
         g.endFill();
         g.lineStyle();
      }

      // ellipsis-fit by measuring textWidth (never wider than the field)
      private function hzFitText(tf:TextField, full:String, maxW:Number) : void
      {
         tf.text = full;
         if(this.hzTW(tf) <= maxW - 4 || full.length < 2) { return; }
         var lo:int = 1;
         var hi:int = full.length;
         while(lo < hi)
         {
            var mid:int = (lo + hi + 1) >> 1;
            tf.text = full.substr(0,mid) + "...";
            if(this.hzTW(tf) <= maxW - 4) { lo = mid; } else { hi = mid - 1; }
         }
         tf.text = full.substr(0,lo).replace(/\s+$/,"") + "...";
      }


      // Vertical layout: rows collapse when hidden, so there is never an empty gap. Top-left stays fixed.
      // Two-row layout; rows collapse when irrelevant (no gaps). Top-left stays fixed.
      private function hzEqLayout() : void
      {
         if(!this.hzEqNew || !this.hzEqWeap) { return; }
         var ts:Number = Math.max(0.8,Math.min(1.3,this.hzTextScale));
         var W:Number = HZ_EQ_W;
         var P:Number = HZ_EQ_P;
         var nameX:Number = P + 58;
         var nameW:Number = W - P - nameX;
         var expand:Boolean = this.hzArrange || this.hzFrameN < this.hzEqExpandUntil;
         var no:Object = this.hzTxtObj(this.hzEqWeap);
         var full:String = this.hzEqFullName.length > 0 ? this.hzUC(this.hzEqFullName) : "--";
         var lines:int = 1;
         this.hzEqWeap.wordWrap = expand;
         this.hzEqWeap.multiline = expand;
         if(expand) { this.hzEqWeap.text = full; lines = this.hzEqWeap.numLines > 1 ? 2 : 1; }
         if(no && int(no.lines) != lines) { no.lines = lines; this.hzApplyFmt(no); }
         if(!expand) { this.hzFitText(this.hzEqWeap,full,nameW); }
         this.hzEqExpanded = expand;
         var lineH:Number = Math.round(13 * ts) + 4;
         var row1H:Number = Math.max(24,lineH * lines);
         this.hzTxtTop(this.hzEqWeap,P + Math.max(0,(24 - lineH) / 2));
         var y:Number = P + row1H + 12; // extra spacing between name row and ammo row
         var showAmmo:Boolean = this.hzEqHasAmmo;
         this.hzEqCount.visible = showAmmo;
         this.hzEqReserve.visible = showAmmo && !this.hzEqPct;
         this.hzEqAmmoIcon.visible = showAmmo;
         var typeTxt:String = this.hzAmmoType ? this.hzAmmoType.text : "";
         var showType:Boolean = showAmmo && typeTxt.length > 0 && typeTxt != "--";
         this.hzEqType.visible = showType;
         if(showAmmo)
         {
            var bigH:Number = Math.round(24 * ts);
            var rowH:Number = Math.max(26,bigH + 2);
            var rw:Number = this.hzEqReserve.visible ? this.hzEqReserve.textWidth + 6 : 0;
            this.hzEqReserve.x = W - P - rw;
            this.hzEqCount.x = this.hzEqReserve.x - (rw > 0 ? 6 : 0) - 110;
            this.hzTxtTop(this.hzEqCount,y + (rowH - bigH) / 2 - 2);
            this.hzTxtTop(this.hzEqReserve,y + (rowH - bigH) / 2 + bigH - Math.round(13 * ts) - 6);
            this.hzEqAmmoIcon.y = y + (rowH - 24) / 2;
            if(showType)
            {
               var countLeft:Number = this.hzEqCount.x + 110 - this.hzEqCount.textWidth - 4;
               this.hzEqType.x = P + 30;
               this.hzFitText(this.hzEqType,typeTxt.toUpperCase(),Math.max(30,countLeft - 10 - this.hzEqType.x));
               this.hzTxtTop(this.hzEqType,y + (rowH - Math.round(10 * ts)) / 2 - 3);
            }
            y += rowH;
         }
         else
         {
            y = P + row1H;
         }
         this.hzEqBodyRec.h = Math.round(y + P);
         this.hzEqDrawBody();
      }


      private function hzEqApplyStyle() : void
      {
         // v0.27: only the new card is shown; the old sprites stay detached / hidden as data holders
         if(this.hzEqOld) { this.hzEqOld.visible = false; }
         if(this.hzEqNew) { this.hzEqNew.visible = false; }
         if(this.hzEq19) { this.hzEq19.visible = true; this.hzSetSz(this.HorizonAmmo_mc,this.hzE19Wd,this.hzE19H); }
         for each(var d:DisplayObject in this.hzCAmmoRow) { d.visible = false; }
         this.hzLaidOut = false;
      }

      private function hzEqIconBullet(p:Sprite, x:Number, y:Number) : void
      {
         var s2:Sprite = new Sprite();
         var g:* = s2.graphics;
         var i:int = 0;
         while(i < 3)
         {
            var bx:Number = i * 7;
            g.lineStyle(1.2,HZ_ACCENT,0.95);
            g.beginFill(HZ_ACCENT,0.25 + i * 0.25);
            g.moveTo(bx,24); g.lineTo(bx,9); g.curveTo(bx + 2.5,0,bx + 5,9); g.lineTo(bx + 5,24); g.lineTo(bx,24);
            g.endFill();
            g.moveTo(bx,20); g.lineTo(bx + 5,20);
            i++;
         }
         g.lineStyle();
         s2.x = x; s2.y = y;
         p.addChild(s2);
         this.hzEqBulletSp = s2;
      }
      private var hzEqBulletSp:Sprite = null;

      // keyword-based weapon class (original glyphs)
      // keyword-based weapon class (original glyphs)
      private function hzEqKindOf(n:String) : String
      {
         var l:String = n == null ? "" : n.toLowerCase();
         if(l.length == 0 || l.indexOf("unarmed") >= 0 || l.indexOf("fist") >= 0) { return "unarmed"; }
         var groups:Array = [
            ["melee",["knife","blade","axe","sword","katana","baton","hammer","rapier","tanto","wakizashi","machete","pick","bayonet","cutlass","mace","club"]],
            ["heavy",["launcher","minigun","shatter","magstorm","magshear","big bang","heavy","cannon","lawgiver","flamer"]],
            ["laser",["laser","lzr","equinox","orion","solstice","novalight","photon","particle","arc ","em-","pulse"]],
            ["shotgun",["shotgun","coachman","breach","pacifier","scatter","boom"]],
            ["sniper",["sniper","marksman","hard target","longfang","bridger"]],
            ["pistol",["pistol","revolver","eon","magshot","sidearm","razorback","rattler","cutter","welder","peacemaker","m1919"]]];
         for each(var gr:Array in groups)
         {
            for each(var k:String in gr[1]) { if(l.indexOf(k) >= 0) { return String(gr[0]); } }
         }
         return "rifle";
      }

      // ~48x24 original line-art silhouettes, drawn in the text color with a soft glow
      private function hzEqDrawWeapIcon(kind:String) : void
      {
         if(!this.hzEqWIcon) { return; }
         this.hzEqKind = kind;
         var g:* = this.hzEqWIcon.graphics;
         var c:uint = this.hzTxtMain();
         g.clear();
         g.lineStyle(1.5,c,1,true);
         this.hzWeapPath(g,kind);
         g.lineStyle();
         this.hzEqWIcon.filters = [new GlowFilter(this.hzDarkText() ? 0xFFFFFF : c,this.hzDarkText() ? 0.35 : 0.3,5,5,1.2,1)];
         this.hzE19DrawIcon();
      }

      // shared ~48x24 weapon line-art paths (stroke style set by the caller)
      private function hzWeapPath(g:*, kind:String) : void
      {
         if(kind == "pistol")
         {
            g.moveTo(10,6); g.lineTo(38,6); g.lineTo(38,12); g.lineTo(22,12); g.lineTo(18,22); g.lineTo(11,22); g.lineTo(14,12); g.lineTo(10,12); g.lineTo(10,6);
            g.moveTo(20,12); g.curveTo(20,17,25,15);
            g.moveTo(34,6); g.lineTo(34,4); g.moveTo(12,8); g.lineTo(30,8);
         }
         else if(kind == "shotgun")
         {
            g.moveTo(0,10); g.lineTo(10,8); g.lineTo(47,8); g.lineTo(47,11); g.lineTo(20,11); g.lineTo(17,18); g.lineTo(13,18); g.lineTo(14,12); g.lineTo(6,15); g.lineTo(0,15); g.lineTo(0,10);
            g.drawRoundRect(26,11,12,4,2,2);
            g.moveTo(30,13); g.lineTo(34,13);
         }
         else if(kind == "sniper")
         {
            g.moveTo(0,11); g.lineTo(10,10); g.lineTo(14,8); g.lineTo(48,8); g.lineTo(48,10); g.lineTo(26,10); g.lineTo(24,13); g.lineTo(20,13); g.lineTo(18,19); g.lineTo(14,19); g.lineTo(15,13); g.lineTo(9,16); g.lineTo(0,16); g.lineTo(0,11);
            g.drawRoundRect(14,2,16,4,3,3); g.moveTo(18,6); g.lineTo(18,8); g.moveTo(26,6); g.lineTo(26,8);
            g.moveTo(36,10); g.lineTo(33,20); g.moveTo(36,10); g.lineTo(39,20);
         }
         else if(kind == "heavy")
         {
            g.drawRoundRect(4,6,32,12,6,6);
            g.drawRect(36,9,11,5);
            g.drawRoundRect(14,2,12,4,2,2);
            g.moveTo(16,18); g.lineTo(15,23); g.lineTo(21,23); g.lineTo(22,18);
            g.drawCircle(30,12,3);
            g.moveTo(8,10); g.lineTo(24,10);
         }
         else if(kind == "laser")
         {
            g.moveTo(4,8); g.lineTo(38,8); g.curveTo(47,9,44,13); g.lineTo(24,13); g.lineTo(20,21); g.lineTo(14,21); g.lineTo(17,13); g.lineTo(4,13); g.lineTo(4,8);
            g.moveTo(33,8); g.lineTo(33,13); g.moveTo(37,8); g.lineTo(37,13);
            g.drawRoundRect(8,10,10,1.5,1,1);
         }
         else if(kind == "melee")
         {
            g.moveTo(10,19); g.lineTo(38,4); g.lineTo(45,3); g.lineTo(42,9); g.lineTo(14,22); g.lineTo(10,19);
            g.moveTo(8,13); g.lineTo(16,24);
            g.moveTo(10,19); g.lineTo(4,22);
         }
         else if(kind == "unarmed")
         {
            g.drawRoundRect(14,6,20,14,7,7);
            g.moveTo(19,6); g.lineTo(19,11); g.moveTo(24,6); g.lineTo(24,11); g.moveTo(29,6); g.lineTo(29,11);
            g.moveTo(14,14); g.lineTo(9,11);
         }
         else
         {
            // rifle: stock, receiver, magazine, grip, optic, barrel
            g.moveTo(0,10); g.lineTo(9,9); g.lineTo(12,7); g.lineTo(40,7); g.lineTo(40,9); g.lineTo(47,9); g.lineTo(47,11); g.lineTo(31,11); g.lineTo(29,13); g.lineTo(23,13);
            g.lineTo(20,20); g.lineTo(16,20); g.lineTo(18,13); g.lineTo(13,13); g.lineTo(9,17); g.lineTo(1,17); g.lineTo(0,10);
            g.moveTo(25,13); g.lineTo(26,21); g.lineTo(30,21); g.lineTo(29,13);
            g.drawRoundRect(16,2,12,4,2,2); g.moveTo(19,6); g.lineTo(19,7); g.moveTo(25,6); g.lineTo(25,7);
         }
      }

      // mirror the classic card data into the new card (called from the weapon / ammo writers)
      // mirror WeaponData / inventory into the style-1 card (called from the weapon / ammo writers)
      private function hzEqSync() : void
      {
         if(!this.hzEqNew) { return; }
         var name:String = this.hzWeapName.length > 0 ? this.hzWeapName : this.hzInvWeapName;
         if(name != this.hzEqFullName)
         {
            if(this.hzEqFullName.length > 0 || name.length > 0) { this.hzEqExpandUntil = this.hzFrameN + 90; } // ~3 s full name after a swap
            this.hzEqFullName = name;
         }
         var k:String = this.hzEqKindOf(name);
         if(!this.hzEqHasAmmo && k == "rifle") { k = name.length > 0 ? "melee" : "unarmed"; } // no conventional ammo
         if(k != this.hzEqKind) { this.hzEqDrawWeapIcon(k); }
         if(this.hzEqHasAmmo)
         {
            var clip:Number = this.hzEqClip;
            var tot:Number = this.hzEqTot;
            if(this.hzEqPct)
            {
               var pc:int = tot > 0 ? int(Math.floor(clip / tot * 100)) : 0;
               this.hzEqCount.text = pc + "%";
               this.hzEqLow = false;
               this.hzTxtTint(this.hzEqCount,pc <= 0 ? HZ_RED : (pc < 25 ? 0xF2B45F : null));
            }
            else
            {
               // same reserve maths as the game's own ammo readout (BottomRightGroup.OnWeaponDataUpdate)
               var rest:Number = tot <= clip ? 0 : tot - clip;
               this.hzEqCount.text = String(clip);
               var cap:Number = this.hzMagCap > 0 ? this.hzMagCap : this.hzMagMax; // uAmmoCapacity, else max clip seen
               var low:Boolean = cap > 0 && clip > 0 && clip < cap * 0.25;
               this.hzEqLow = low;
               this.hzTxtTint(this.hzEqCount,clip <= 0 ? HZ_RED : (low ? (clip < cap * 0.1 ? HZ_RED : 0xF2B45F) : null));
               this.hzEqReserve.text = "/ " + (rest > 9999 ? "9999+" : String(rest));
               this.hzTxtTint(this.hzEqReserve,rest <= 0 ? this.hzMix(HZ_RED,this.hzLight() ? 0x000000 : 0xFFFFFF,0.25) : null);
            }
         }
         if(!this.hzEqHasAmmo) { this.hzEqLow = false; }
         if(!this.hzEqLow && this.hzEqCount) { this.hzEqCount.alpha = 1; }
         this.hzEqLastClip = this.hzEqClip;
         this.hzEqLayout();
         this.hzE19Sync();
      }

      private function hzEqTick() : void
      {
         if(!this.hzEqNew) { return; }
         var want:Boolean = this.hzArrange || this.hzFrameN < this.hzEqExpandUntil;
         if(want != this.hzEqExpanded) { this.hzEqLayout(); }
         if(this.hzEqLow && this.hzEqCount)
         {
            this.hzEqPulse += 0.25;
            this.hzEqCount.alpha = 0.5 + 0.5 * (0.5 + 0.5 * Math.sin(this.hzEqPulse));
         }
         this.hzE19Tick();
      }

      private function hzEqDrawTicks() : void
      {
         if(!this.hzEqTicks) { return; }
         var g:* = this.hzEqTicks.graphics;
         g.clear();
         var cap:Number = this.hzMagCap > 0 ? this.hzMagCap : this.hzMagMax;
         this.hzEqTicks.visible = this.hzMagBar && cap > 0 && this.hzMagClip >= 0;
         if(!this.hzEqTicks.visible) { return; }
         var n:int = cap <= 40 ? int(cap) : 30;
         var shown:Number = this.hzEqShown < 0 ? this.hzMagClip : this.hzEqShown;
         var f:Number = Math.max(0,Math.min(1,shown / cap));
         var filled:int = int(Math.round(f * n));
         var flashTo:int = int(Math.round(Math.max(0,Math.min(1,this.hzEqFlashFrom / cap)) * n));
         var col:uint = f < 0.1 ? HZ_RED : (f < 0.3 ? 0xF2B45F : HZ_ACCENT);
         var lt:Boolean = this.hzLight();
         var W:Number = HZ_W - 8;
         var step:Number = W / n;
         var bw:Number = Math.max(1.5,Math.min(6,step * 0.55));
         var i:int = 0;
         while(i < n)
         {
            // staircase: short to tall in 4 steps
            var hh:Number = 6 + Math.floor(i / Math.max(1,n / 4)) * 3;
            var x:Number = i * step + (step - bw) / 2;
            if(i < filled)
            {
               g.beginFill(col,0.95);
            }
            else if(this.hzEqFlash > 0 && i < flashTo)
            {
               g.beginFill(0xFFFFFF,0.8 * this.hzEqFlash);
            }
            else
            {
               g.beginFill(lt ? 0x000000 : 0xFFFFFF,lt ? 0.16 : 0.13);
            }
            g.drawRoundRect(x,15 - hh,bw,hh,2,2);
            g.endFill();
            i++;
         }
      }

      // ===== v0.18 frame-dependent card forms =====
      // v0.24: the borderless pill forms are the only frame (CardFrame removed); classic children stay hidden.
      private function hzFrameApply() : void
      {
         var nf:Boolean = true;
         if(this.hzPlanOld) { this.hzPlanOld.visible = !nf; }
         if(this.hzPlanPill) { this.hzPlanPill.visible = nf; this.hzPpLayout(); }
         if(this.hzVitOld) { this.hzVitOld.visible = !nf; }
         if(this.hzVitNew) { this.hzVitNew.visible = nf; this.hzVnDraw(); }
         if(this.hzJetOld) { this.hzJetOld.visible = !nf; }
         if(this.hzJetNew) { this.hzJetNew.visible = nf; }
         if(this.hzCmpOld) { this.hzCmpOld.visible = !nf; }
         if(this.hzCmpNew) { this.hzCmpNew.visible = nf; }
         if(this.hzQOld) { this.hzQOld.visible = !nf; }
         if(this.hzQNew) { this.hzQNew.visible = nf; }
         if(this.hzCQOld) { this.hzCQOld.visible = !nf; }
         if(this.hzCQNew) { this.hzCQNew.visible = nf; }
         if(this.hzAfOld) { this.hzAfOld.visible = !nf; }
         if(this.hzAfNew) { this.hzAfNew.visible = nf; }
         this.hzEqApplyStyle();
         this.hzV19Redraw();
         this.hzLaidOut = false;
      }

      private function hzV19Redraw() : void
      {
         if(!this.hzV19()) { return; }
         try { this.hzCmpDraw19(); } catch(e1:Error) { }
         try { this.hzQDraw19(); } catch(e2:Error) { }
         try { this.hzJ19Draw(); } catch(e3:Error) { }
         try { if(this.hzAfNew) { this.hzAfSync(); } } catch(e4:Error) { }
         try { this.hzE19Sync(); } catch(e5:Error) { }
         try { this.hzDrawCompassMarkers(); } catch(e6:Error) { }
         try { this.hz26Redraw(); } catch(e7:Error) { }
         this.hzT19Sig = "";
      }

      private function hzSzDel(c:Sprite) : void
      {
         var i:int = 0;
         while(i < this.hzSz.length) { if(this.hzSz[i].c == c) { this.hzSz.splice(i,1); } else { i++; } }
      }

      private function hzPillOn() : Boolean
      {
         return this.hzPlanPill != null;
      }

      // ---- Target card: restyled activate prompt (HUDRolloverActivationData). Vanilla button bar stays live. ----
      private function hzBuildTarget() : void
      {
         this.HorizonTarget_mc = new Sprite();
         this.HorizonTarget_mc.mouseEnabled = false;
         this.HorizonTarget_mc.mouseChildren = false;
         var p:Sprite = this.HorizonTarget_mc;
         this.hzTgBody = new Sprite(); p.addChild(this.hzTgBody);
         this.hzTgChipBg = new Sprite(); p.addChild(this.hzTgChipBg);
         this.hzTgName = this.hzText(p,"",16,8,HZ_TG_W - 32,15,HZ_VALUE,false,"val");
         this.hzTxtObj(this.hzTgName).ls = 1.2;
         this.hzTgChip = this.hzText(p,"",0,10,110,9,0x0E151B,false,null,true);
         this.hzTxtObj(this.hzTgChip).ls = 1.2;
         this.hzTgInfo = this.hzText(p,"",16,30,HZ_TG_W - 32,11,HZ_LABEL,false,"valS");
         this.hzTxtObj(this.hzTgInfo).ls = 1;
         this.hzBuildTg19();
         p.visible = false;
         try
         {
            var ri:int = this.getChildIndex(this.RolloverWidget_mc);
            this.addChildAt(p,Math.max(0,ri)); // below the vanilla rollover: its button bar draws on top of our panel
         }
         catch(err:Error)
         {
            addChild(p);
         }
         try { BSUIDataManager.Subscribe("HUDRolloverActivationData",this.hzOnTgAct); } catch(e1:Error) { }
         try { BSUIDataManager.Subscribe("HUDRolloverData",this.hzOnTgRoll); } catch(e2:Error) { }
         try { BSUIDataManager.Subscribe("HudEnemyData",this.hzOnTgEnemy); } catch(e3:Error) { }
         try { BSUIDataManager.Subscribe("HUDRolloverItemData",this.hzOnTgItems); } catch(e4:Error) { }
      }

      private function hzOnTgAct(e:FromClientDataEvent) : *
      {
         try { this.hzTgAct = e.data; } catch(err:Error) { this.hzTgAct = null; }
         this.hzTgDirty = true;
         this.hzT19Ver++;
      }

      // HUDRolloverItemData.aItems (the container list the game feeds ContainerList_mc.InitializeEntries)
      private function hzOnTgItems(e:FromClientDataEvent) : *
      {
         try { this.hzTgItems = (e.data && e.data.aItems is Array) ? e.data.aItems as Array : null; } catch(err:Error) { this.hzTgItems = null; }
         this.hzT19Ver++;
      }

      private function hzOnTgRoll(e:FromClientDataEvent) : *
      {
         try
         {
            if(e.data && e.data.fScreenX != undefined) { this.hzTgSX = Number(e.data.fScreenX); this.hzTgSY = Number(e.data.fScreenY); }
         }
         catch(err:Error) { }
      }

      private function hzOnTgEnemy(e:FromClientDataEvent) : *
      {
         var found:Object = null;
         try
         {
            var d:Object = e.data;
            if(d && d.EnemiesA)
            {
               for each(var en:Object in d.EnemiesA)
               {
                  if(en && en.uID == d.uTargetUnderCrosshairID) { found = en; break; }
               }
            }
         }
         catch(err:Error) { found = null; }
         var hp:Number = found && found.fHealth != undefined ? Number(found.fHealth) : -1;
         var leg:Boolean = found != null && (Boolean(found.bIsLegendary) || Number(found.uLegendaryRank) > 0);
         var enm:String = found && found.sName != null ? String(found.sName) : "";
         var rk:int = found && found.uLegendaryRank != undefined ? int(found.uLegendaryRank) : 0;
         var ons:Boolean = found != null && found.bOnScreen !== false;
         if(enm != this.hzTgEnName || rk != this.hzTgRank || ons != this.hzTgOnScr) { this.hzTgEnName = enm; this.hzTgRank = rk; this.hzTgOnScr = ons; this.hzT19Ver++; }
         if(hp != this.hzTgHpV || leg != this.hzTgLeg) { this.hzTgHpV = hp; this.hzTgLeg = leg; this.hzTgDirty = true; this.hzT19Ver++; }
      }

      // vanilla modes: 0 BASIC, 1 SINGLE_ITEM, 2 SINGLE_ITEM_WITH_CARD (styled); 3-5 scanner / inventory stay vanilla
      private function hzTgMode() : int
      {
         var a:Object = this.hzTgAct;
         if(!a || !a.bShowRolloverActivation) { return -1; }
         var m:int = int(a.uMode);
         return m >= 0 && m <= 2 ? m : -1;
      }

      private function hzTgRestore() : void
      {
         for each(var o:Object in this.hzTgHidden)
         {
            try
            {
               if(o.a != undefined) { DisplayObject(o.d).alpha = Number(o.a); }
               else { DisplayObject(o.d).visible = Boolean(o.v); }
            }
            catch(err:Error) { }
         }
         this.hzTgHidden = [];
      }

      private function hzTgHide(d:DisplayObject) : void
      {
         if(!d) { return; }
         for each(var o:Object in this.hzTgHidden) { if(o.d == d) { if(d.visible) { d.visible = false; } return; } }
         this.hzTgHidden.push({"d":d,"v":d.visible});
         d.visible = false;
      }

      private function hzTgTick() : void
      {
         if(!this.HorizonTarget_mc) { return; }
         if(this.hzV19() && this.hzTg19) { this.hzT19Tick(); return; }
         if(this.hzTg19 && this.hzTg19.visible) { this.hzTg19.visible = false; this.hzTgRestore(); this.hzTgDirty = true; }
         if(this.hzTgOld) { this.hzTgOld.visible = true; }
         var aw:Object = null;
         var rw:Object = null;
         try { rw = this.RolloverWidget_mc; aw = rw ? rw.RolloverActivation_mc : null; } catch(err:Error) { aw = null; }
         var m:int = this.hzTgMode();
         var on:Boolean = this.hzShowTarget && aw != null && m >= 0 && rw.visible && this.hzGroupVisible && !this.hzUserHidden && !this.hzArrange;
         if(!on)
         {
            if(this.hzTgHidden.length > 0) { this.hzTgRestore(); }
            this.HorizonTarget_mc.visible = false;
            return;
         }
         var hdr:DisplayObject = null;
         var ivw:DisplayObject = null;
         var bars:DisplayObject = null;
         var card:DisplayObject = null;
         try { hdr = aw.Header_mc as DisplayObject; } catch(e1:Error) { }
         try { ivw = aw.ItemValueWeight_mc as DisplayObject; } catch(e2:Error) { }
         try { bars = aw.ButtonBars_mc as DisplayObject; } catch(e3:Error) { }
         try { card = aw.RolloverItemCard_mc as DisplayObject; } catch(e4:Error) { }
         if(!hdr) { this.HorizonTarget_mc.visible = false; return; } // unknown layout: leave vanilla alone
         this.hzTgHide(hdr);
         if(ivw) { this.hzTgHide(ivw); }
         var s:Number = HZ_SCALE * this.hzHudScale;
         this.HorizonTarget_mc.scaleX = this.HorizonTarget_mc.scaleY = s;
         if(this.hzTgDirty || this.hzTgLastMode != m) { this.hzTgDirty = false; this.hzTgLastMode = m; this.hzTgContent(m); }
         // geometry (HUDMenu space)
         var bb:Rectangle = null;
         var cb:Rectangle = null;
         try { if(bars && bars.visible) { bb = bars.getBounds(this); } } catch(e5:Error) { bb = null; }
         try { if(card && m == 2 && card.visible) { cb = card.getBounds(this); } } catch(e6:Error) { cb = null; }
         if(bb && (bb.width < 4 || bb.height < 4)) { bb = null; }
         var w:Number = HZ_TG_W;
         var th:Number = this.hzTgTextH;
         var h:Number = th;
         var x:Number = 0;
         var y:Number = 0;
         var frame:Boolean = false;
         if(m == 2 && cb)
         {
            // item card mode: compact title card sitting on top of the vanilla item card
            x = cb.x; y = cb.y - (th + 6) * s;
            w = Math.max(HZ_TG_W,cb.width / s);
         }
         else if(this.hzTgAnchor == 0 && bb)
         {
            // frame the vanilla button bar: our text above, its live buttons inside the lower part of our panel
            frame = true;
            x = bb.x - 14 * s; y = bb.y - th * s;
            w = Math.max(HZ_TG_W,bb.width / s + 28);
            h = th + bb.height / s + 10;
         }
         else
         {
            var sx:Number = isNaN(this.hzTgSX) ? 960 : this.hzTgSX;
            var sy:Number = isNaN(this.hzTgSY) ? 540 : this.hzTgSY;
            if(this.hzTgAnchor == 0) { sx = Number(rw.x); sy = Number(rw.y); } // rollover is locked to safe-rect center
            x = sx + 40; y = sy + 22;
         }
         var vr:Rectangle = this.hzVis();
         if(vr)
         {
            x = Math.max(vr.x + 8,Math.min(vr.x + vr.width - w * s - 8,x));
            y = Math.max(vr.y + 8,Math.min(vr.y + vr.height - h * s - 8,y));
         }
         this.HorizonTarget_mc.x = Math.round(x);
         this.HorizonTarget_mc.y = Math.round(y);
         if(w != this.hzTgW || h != this.hzTgH || frame != this.hzTgFramed) { this.hzTgW = w; this.hzTgH = h; this.hzTgFramed = frame; this.hzTgContent(m); }
         this.HorizonTarget_mc.alpha = 1; // prompt is always full strength (no combat dim)
         this.HorizonTarget_mc.visible = true;
      }

      private function hzTgRarityCol(r:int) : int
      {
         switch(r)
         {
            case 1: return 0x5FA8F2; // rare
            case 2: return 0xB98BF2; // epic
            case 3: return 0xF2C45F; // legendary
            case 4: return 0xF28C5F; // exotic
         }
         return -1;
      }

      // 0.42.0.9: the name on the crosshair target card. The DLL reads it on the task thread for the busy card.
      public function hzCrossName() : String
      {
         var s:String = "";
         try
         {
            if(this.hzTgAct != null && this.hzTgAct.sHeaderText != null) { s = String(this.hzTgAct.sHeaderText); }
         }
         catch(e:Error) { return ""; }
         var o:String = "";
         var i:int = 0;
         while(i < s.length && o.length < 80)
         {
            var c:int = s.charCodeAt(i);
            if(c >= 32 && c != 127) { o += s.charAt(i); }
            i++;
         }
         while(o.length > 0 && o.charAt(0) == " ") { o = o.substr(1); }
         while(o.length > 0 && o.charAt(o.length - 1) == " ") { o = o.substr(0,o.length - 1); }
         return o;
      }

      private function hzTgContent(m:int) : void
      {
         var a:Object = this.hzTgAct;
         if(!a || !this.hzTgName) { return; }
         var w:Number = Math.max(HZ_TG_W,this.hzTgW);
         var ts:Number = Math.max(0.8,Math.min(1.3,this.hzTextScale));
         var steal:Boolean = Boolean(a.bStealing);
         var contra:Boolean = Boolean(a.bContraband);
         var chip:String = steal ? "STEAL" : (contra ? "CONTRABAND" : "");
         var chipCol:uint = steal ? HZ_RED : 0xF2B45F;
         var cw:Number = 0;
         var cg:* = this.hzTgChipBg.graphics;
         cg.clear();
         this.hzTgChip.visible = chip.length > 0;
         if(chip.length > 0)
         {
            this.hzTgChip.text = chip;
            cw = this.hzTgChip.textWidth + 14;
            this.hzTgChip.x = w - 14 - cw + 7;
            this.hzTxtTop(this.hzTgChip,11);
            cg.beginFill(chipCol,1);
            cg.drawRoundRect(w - 14 - cw,10,cw,Math.round(9 * ts) + 8,8,8);
            cg.endFill();
         }
         var nm:String = a.sHeaderText != null ? String(a.sHeaderText) : "";
         this.hzFitText(this.hzTgName,nm.toUpperCase(),w - 32 - (cw > 0 ? cw + 8 : 0));
         this.hzTxtTop(this.hzTgName,8);
         var y:Number = 8 + Math.round(15 * ts) + 8;
         // value / weight for items
         var info:String = "";
         if(this.hzTgShowValue && m != 0)
         {
            var parts:Array = [];
            var val:Number = Number(a.iSingleItemValue);
            var wt:Number = Number(a.fSingleItemWeight);
            var pr:int = a.uWeightPrecision != undefined ? Math.max(0,Math.min(3,int(a.uWeightPrecision))) : 1;
            if(!isNaN(val) && val > 0) { parts.push(String(int(val)) + " CR"); }
            if(!isNaN(wt) && wt > 0) { parts.push(wt.toFixed(pr) + " KG"); }
            info = parts.join("  ·  ");
         }
         this.hzTgInfo.visible = info.length > 0;
         if(info.length > 0)
         {
            this.hzFitText(this.hzTgInfo,info,w - 32);
            this.hzTxtTop(this.hzTgInfo,y - 2);
            y += Math.round(11 * ts) + 8;
         }
         this.hzTgTextH = y + 2;
         var h:Number = this.hzTgFramed ? Math.max(this.hzTgH,this.hzTgTextH) : this.hzTgTextH;
         // body
         var g:* = this.hzTgBody.graphics;
         var lt:Boolean = this.hzLight();
         var fill:uint = steal ? this.hzMix(this.hzPanelFill(),HZ_RED,lt ? 0.18 : 0.22) : this.hzPanelFill();
         g.clear();
         g.beginFill(0x000000,0.12 + 0.2 * this.hzOpExtra());
         g.drawRoundRect(-1,1,w + 2,h + 2,18,18);
         g.endFill();
         g.beginFill(fill,this.hzPanelA(lt ? 0.92 : 0.86));
         g.drawRoundRect(0,0,w,h,16,16);
         g.endFill();
         g.lineStyle();
         var rc:int = steal ? int(HZ_RED) : this.hzTgRarityCol(a.uRarity != undefined ? int(a.uRarity) : 0);
         if(rc >= 0)
         {
            g.beginFill(this.hzIconCol(uint(rc)),1);
            g.drawRoundRect(5,8,3,h - 16,3,3);
            g.endFill();
         }
         if(this.hzTgFramed)
         {
            g.lineStyle(1,lt ? 0x000000 : 0xFFFFFF,lt ? 0.12 : 0.08);
            g.moveTo(16,this.hzTgTextH - 2); g.lineTo(w - 16,this.hzTgTextH - 2);
            g.lineStyle();
         }
      }

      // ---- PLANET pill v3 (336x84): body disc + day rim | name / temp · status | local + real time ----
      private var hzPpDisc:Sprite;
      private var hzPpLocT:TextField;
      private var hzPpLocL:TextField;
      private var hzPpRealT:TextField;
      private var hzPpRealL:TextField;
      private var hzPpLocG:Sprite;
      private var hzPpRealG:Sprite;
      private var hzPpDay:Number = -1;
      private var hzPpUT:Number = -1;   // LocalEnvData_Frequent.fGalacticStandardTime, hours (DataMenu ClockWidget prints it as "HH:MM UT")
      private var hzPpShowUT:Boolean = false;   // true when the local row is showing GAME time; do not read the label text
      private var hzPpBodyType:int = -1;
      private var hzPpRealMin:int = -1;
      private var hzPpDrawnDay:Number = -2;
      private var hzPpLine:TextField;

      private function hzBuildPlanPill() : void
      {
         this.hzPlanPill = new Sprite();
         this.HorizonEnv_mc.addChild(this.hzPlanPill);
         var p:Sprite = this.hzPlanPill;
         this.hzPpBody = new Sprite(); this.hzPpBody.name = "hzPpBody";
         p.addChild(this.hzPpBody);
         this.hzPpDisc = new Sprite(); this.hzPpDisc.x = 42; this.hzPpDisc.y = 42;
         p.addChild(this.hzPpDisc);
         this.hzPpIcon = this.hzPpDisc;
         this.hzPpName = this.hzT(p,"--",86,13,140,19,"sb","main",2.2);
         this.hzHdr19(this.hzPpName);
         this.hzPpLine = this.hzT(p,"",86,40,140,17,"sb","acc",1);
         this.hzPpTemp = this.hzPpLine;
         this.hzPpHaz = this.hzPpLine;
         this.hzPpDet = this.hzT(p,"",86,60,180,10,"rg","dim",1);
         var r:Number = HZ_PP_W - 16;
         this.hzPpLocT = this.hzT(p,"",r - 34 - 90,17,90,13,"sb","mut",0.6,"right");
         this.hzPpLocL = this.hzT(p,"LOCAL/GAME",r - 80,21,80,8,"sb","dim",0.8,"right");
         this.hzPpRealT = this.hzT(p,"",r - 34 - 90,42,90,12,"rg","dim",0.4,"right");
         this.hzPpRealL = this.hzT(p,"PC/REAL",r - 62,45,64,8,"sb","dim",0.8,"right");
         this.hzPpLocG = new Sprite(); p.addChild(this.hzPpLocG);
         this.hzPpRealG = new Sprite(); p.addChild(this.hzPpRealG);
         this.hzSetSz(this.HorizonEnv_mc,HZ_PP_W,84);
         try
         {
            BSUIDataManager.Subscribe("LocalEnvData_Frequent",this.hzOnEnvFreq);
         }
         catch(err:Error) { }
         this.hzFrameApply();
      }

      // LocalEnvData_Frequent.fLocalPlanetTime: 0-1 fraction of the local day (verified: BottomLeftGroup.as)
      // LocalEnvData_Frequent (verified: DataMenu/ClockWidget.as, SleepWaitMenu.as, BottomLeftGroup.as):
      //   fLocalPlanetTime 0-1 of the local day, fLocalPlanetHoursPerDay, fGalacticStandardTime (hours, shown as "UT").
      // Vanilla blanks the local clock when fLocalPlanetHoursPerDay <= 0 (or in a flying ship); an exact 0 is treated as
      // "no data" too (stations sent 0 -> 12:00 AM). Then the UT clock takes the LOCAL row.
      private function hzOnEnvFreq(e:FromClientDataEvent) : *
      {
         var d:Object = e.data;
         var t:Number = d ? Number(d.fLocalPlanetTime) : NaN;
         var hpd:Number = (d && d.fLocalPlanetHoursPerDay != undefined) ? Number(d.fLocalPlanetHoursPerDay) : NaN;
         var nd:Number = (isNaN(t) || t <= 0 || t > 1.0001 || (!isNaN(hpd) && hpd <= 0)) ? -1 : Math.min(1,t);
         var ut:Number = (d && d.fGalacticStandardTime != undefined) ? Number(d.fGalacticStandardTime) : NaN;
         var nu:Number = (isNaN(ut) || ut < 0) ? -1 : ut % 24;
         var utMin:int = nu < 0 ? -1 : int(Math.floor(nu)) * 60 + int(Math.floor((nu - Math.floor(nu)) * 60));
         var oldMin:int = this.hzPpUT < 0 ? -1 : int(Math.floor(this.hzPpUT)) * 60 + int(Math.floor((this.hzPpUT - Math.floor(this.hzPpUT)) * 60));
         var utChg:Boolean = utMin != oldMin;
         this.hzPpUT = nu;
         if(nd < 0 && this.hzPpDay < 0 && !utChg) { return; }
         if(utChg || nd < 0 || this.hzPpDay < 0 || Math.abs(nd - this.hzPpDay) > 0.0004 || this.hzPpMinOf(nd) != this.hzPpMinOf(this.hzPpDay))
         {
            this.hzPpDay = nd;
            this.hzPpLayout();
         }
      }

      private function hzPpMinOf(day:Number) : int
      {
         if(day < 0) { return -1; }
         var hh:Number = (day * 24) % 24;
         return int(Math.floor(hh)) * 60 + int(Math.floor((hh - Math.floor(hh)) * 60));
      }

      // real-world clock refresh, ~1 s (called from the frame loop)
      private function hzPpClock() : void
      {
         if(!this.hzPlanPill || !this.hzPlanPill.visible || this.hzTimeDisplay < 2) { return; }
         var m:int = -2;
         try { var dt:Date = new Date(); m = dt.getHours() * 60 + dt.getMinutes(); } catch(err:Error) { m = -2; }
         if(m != this.hzPpRealMin) { this.hzPpLayout(); }
      }

      private function hzPpDraw() : void
      {
         if(!this.hzPpBody) { return; }
         var g:* = this.hzPpBody.graphics;
         g.clear();
         this.hzPanel(g,this.hzPpW,this.hzPpH,this.hzPpC == 1 ? 14 : 18);
         this.hzPpDrawIcon();
      }

      private function hzPpSurf() : Boolean
      {
         return this.hzPpKind != "ship" && this.hzPpKind != "station" && this.hzPpKind != "space";
      }

      private function hzPpStCol() : uint
      {
         if(!this.hzPpSurf()) { return HZ_ACCENT; }
         return this.hzPpStatusCol == 2 ? HZ_RED : (this.hzPpStatusCol == 1 ? HZ_AMB : HZ_ACCENT);
      }

      // the disc: tile, day rim (track + arc + sun / moon dot) and an original body glyph per LocalEnvironmentData.uBodyType
      private function hzPpDrawIcon(tgt:Sprite = null) : void
      {
         var dsc:Sprite = tgt != null ? tgt : this.hzPpDisc;
         if(!dsc) { return; }
         var g:* = dsc.graphics;
         g.clear();
         var dk:Boolean = this.hzDarkText();
         var ac:uint = this.hzIconCol(this.hzPpStCol());
         var tile:uint = dk ? this.hzMix(this.hzPanelFill(),0x000000,0.14) : 0x080D12;
         g.beginFill(tile,0.92); g.drawCircle(0,0,30); g.endFill();
         var day:Number = this.hzPpDay;
         var showDay:Boolean = day >= 0 && this.hzPpKind != "ship" && (this.hzTimeDisplay == 1 || this.hzTimeDisplay == 3);
         if(showDay)
         {
            g.lineStyle(1.6,ac,0.24); g.drawCircle(0,0,26);
            var a0:Number = -Math.PI / 2;
            var a1:Number = a0 + Math.PI * 2 * day;
            g.lineStyle(2.2,ac,1);
            g.moveTo(Math.cos(a0) * 26,Math.sin(a0) * 26);
            var n:int = Math.max(2,int(Math.ceil(day * 48)));
            var i:int = 1;
            while(i <= n) { var a:Number = a0 + (a1 - a0) * i / n; g.lineTo(Math.cos(a) * 26,Math.sin(a) * 26); i++; }
            g.lineStyle();
            var dx:Number = Math.cos(a1) * 26;
            var dy:Number = Math.sin(a1) * 26;
            var sun:Boolean = day >= 0.25 && day <= 0.75;
            g.beginFill(tile,1); g.drawCircle(dx,dy,4.6); g.endFill();
            g.beginFill(sun ? 0xFFD678 : 0xC8D7EB,1); g.drawCircle(dx,dy,3.4); g.endFill();
         }
         else
         {
            g.lineStyle(1.6,ac,0.43); g.drawCircle(0,0,26); g.lineStyle();
         }
         if(tgt == null) { this.hzPpDrawnDay = day; }
         var k:String = this.hzPpKind;
         var bt:int = this.hzPpBodyType;
         var j:int = 0;
         if(k == "ship")
         {
            var sc:uint = dk ? 0x18242C : 0xF2F7F9;
            g.beginFill(sc,1);
            g.moveTo(0,-15); g.lineTo(5,-4); g.lineTo(14,3); g.lineTo(14,7); g.lineTo(4,5); g.lineTo(3,12); g.lineTo(-3,12); g.lineTo(-4,5); g.lineTo(-14,7); g.lineTo(-14,3); g.lineTo(-5,-4); g.lineTo(0,-15);
            g.endFill();
            g.beginFill(ac,1); g.moveTo(0,-11); g.lineTo(2.6,-5); g.lineTo(-2.6,-5); g.lineTo(0,-11); g.endFill();
            g.beginFill(HZ_AMB,0.85); g.drawRect(-2,12,4,3); g.endFill();
         }
         else if(k == "station")
         {
            g.lineStyle(2.2,ac,1,true); g.drawEllipse(-17,-7,34,14);
            g.lineStyle(1.8,ac,0.85); g.moveTo(0,-14); g.lineTo(0,14); g.moveTo(-20,0); g.lineTo(-17,0); g.moveTo(17,0); g.lineTo(20,0);
            g.lineStyle();
            g.beginFill(ac,1); g.drawCircle(0,0,4); g.drawRect(-22,-3,3,6); g.drawRect(19,-3,3,6); g.endFill();
         }
         else if(k == "space")
         {
            g.lineStyle(1.6,ac,1,true); g.drawCircle(0,0,4); g.drawEllipse(-15,-7,30,14); g.lineStyle();
            g.beginFill(ac,1); g.drawCircle(12,-4,2.2); g.endFill();
         }
         else if(bt == 5)
         {
            // asteroid belt: three irregular rocks
            for each(var rk:Array in [[-8,-4,7],[6,-7,5],[4,7,6]])
            {
               g.beginFill(dk ? 0x6A7076 : 0x8A9096,1);
               var rr:Number = Number(rk[2]);
               g.moveTo(rk[0] + rr,rk[1]);
               j = 1;
               while(j < 7) { var ra:Number = j * Math.PI * 2 / 7; var rm:Number = rr * (j % 2 == 0 ? 0.78 : 1); g.lineTo(rk[0] + Math.cos(ra) * rm,rk[1] + Math.sin(ra) * rm); j++; }
               g.lineTo(rk[0] + rr,rk[1]);
               g.endFill();
            }
         }
         else
         {
            // shaded sphere (highlight upper-left) without gradients: offset concentric discs
            var R:Number = bt == 4 ? 12 : 17;
            var c0:uint = 0x1E465A; var c1:uint = 0x8CDCE6;
            if(bt == 1) { c0 = 0xB8641E; c1 = 0xFFE29A; }
            else if(bt == 3 || bt == 4) { c0 = 0x3C4046; c1 = 0xD2D6DC; }
            if(bt == 1)
            {
               g.beginFill(0xFFC864,0.12); g.drawCircle(0,0,R + 5); g.endFill();
               g.beginFill(0xFFC864,0.12); g.drawCircle(0,0,R + 2.5); g.endFill();
            }
            j = 0;
            while(j < 6)
            {
               g.beginFill(this.hzMix(c0,c1,j / 5),1);
               g.drawCircle(-j * R * 0.09,-j * R * 0.09,R - j * R * 0.14);
               g.endFill();
               j++;
            }
            if(bt == 3 || bt == 4)
            {
               g.beginFill(0x000000,0.2); g.drawCircle(-R * 0.3,-R * 0.2,R * 0.2); g.drawCircle(R * 0.35,R * 0.25,R * 0.24); g.drawCircle(R * 0.1,-R * 0.55,R * 0.13); g.endFill();
            }
            else if(bt != 1)
            {
               g.lineStyle(1.6,0xFFFFFF,0.12);
               g.moveTo(-R * 0.85,-R * 0.25); g.curveTo(0,-R * 0.05,R * 0.85,-R * 0.4);
               g.moveTo(-R * 0.8,R * 0.4); g.curveTo(0,R * 0.6,R * 0.75,R * 0.3);
               g.lineStyle();
            }
            g.lineStyle(1,ac,0.67,true); g.drawCircle(0,0,R + 2); g.lineStyle();
         }
      }

      private function hzPpSync() : void
      {
         if(!this.hzPlanPill) { return; }
         this.hzPpLayout();
      }

      private var hzPpGlx:Number = 0;   // glyph centers of the two time rows (shared with the settings preview)
      private var hzPpGrx:Number = 0;
      private var hzPpGly:Number = 26;
      private var hzPpGry:Number = 51;

      private var hzPpC:int = -1;          // compact (strip) form applied: 1 strip, 0 full card
      private var hzPpW:Number = 392;      // current card width (HZ_PP_W, or HZ_PP_CW as a strip)
      private static const HZ_PP_CW:Number = 490;   // v0.31: was 420 (+16.7 %, same ratio as the card)

      // v0.25 compact strip (Compact=1): 420 x 36, small disc | NAME · status ........ [glyph] LABEL time  [glyph] LABEL time
      private function hzPpForm(cm:Boolean) : void
      {
         var c:int = cm ? 1 : 0;
         if(c == this.hzPpC) { return; }
         this.hzPpC = c;
         this.hzPpW = this.hz31PpWidth(cm);
         this.hzPpDisc.scaleX = this.hzPpDisc.scaleY = cm ? 0.4 : 1;
         this.hzPpDisc.x = cm ? 20 : 42; this.hzPpDisc.y = cm ? 18 : 42;
         var no:Object = this.hzTxtObj(this.hzPpName);
         if(no) { no.fs = cm ? 13 : 19; no.size = no.fs; no.ls = cm ? 1.6 : 2.2; this.hzApplyFmt(no); }
         var lo:Object = this.hzTxtObj(this.hzPpLine);
         if(lo) { lo.fs = cm ? 11 : 17; lo.size = lo.fs; lo.ls = cm ? 0.8 : 1; this.hzApplyFmt(lo); }
         this.hzPpName.x = cm ? 40 : 86;
         this.hzPpLine.x = 86;
         this.hzLaidOut = false;
      }

      private function hzPpLayout() : void
      {
         if(!this.hzPlanPill || !this.hzPpName) { return; }
         var cm:Boolean = this.hz34C("Planet");
         this.hzPpForm(cm);
         this.hzPpW = this.hz31PpWidth(cm);
         var W:Number = this.hzPpW;
         var surf:Boolean = this.hzPpSurf();
         var td:int = this.hzTimeDisplay;
         // time block (right edge W-16)
         // local clock when valid (planet / landed ship / station with real data); vanilla hides it in a flying ship
         var locOk:Boolean = this.hzPpDay >= 0 && this.hzPpKind != "ship";
         var showUT:Boolean = !locOk && this.hzPpUT >= 0 && (td == 1 || td == 3);
         var showLoc:Boolean = (locOk && (td == 1 || td == 3)) || showUT;
         this.hzPpShowUT = showUT;
         this.hzPpLocL.text = "LOCAL/GAME";
         var realStr:String = null;
         if(td >= 2)
         {
            try { var dt:Date = new Date(); realStr = this.hzFmtClock(dt.getHours(),dt.getMinutes()); this.hzPpRealMin = dt.getHours() * 60 + dt.getMinutes(); }
            catch(err:Error) { realStr = null; this.hzPpRealMin = -2; }
         }
         var showReal:Boolean = realStr != null;
         var r:Number = W - 16;
         var gl:* = this.hzPpLocG.graphics; gl.clear();
         var gr:* = this.hzPpRealG.graphics; gr.clear();
         var bg:uint = this.hzPanelFill();
         var blockW:Number = 0;
         var rows:Array = [];
         if(showLoc) { rows.push("loc"); }
         if(showReal) { rows.push("real"); }
         var ys:Array = cm ? [9,9] : (rows.length == 2 ? [17,42] : [29]);
         if(cm) { rows.reverse(); }   // strip: PC/REAL rightmost, LOCAL / GAME to its left
         this.hzPpLocT.visible = this.hzPpLocL.visible = showLoc;
         this.hzPpRealT.visible = this.hzPpRealL.visible = showReal;
         var ri:int = 0;
         while(ri < rows.length)
         {
            var loc:Boolean = rows[ri] == "loc";
            var tf:TextField = loc ? this.hzPpLocT : this.hzPpRealT;
            var lb:TextField = loc ? this.hzPpLocL : this.hzPpRealL;
            var y:Number = Number(ys[ri]);
            if(loc && showUT)
            {
               // game time as the game shows it: always 24-hour "HH:MM UT" (ClockFormat does not apply)
               var uh:int = int(Math.floor(this.hzPpUT)) % 24;
               var um:int = int(Math.floor((this.hzPpUT - Math.floor(this.hzPpUT)) * 60));
               tf.text = this.hzPad2(uh) + ":" + this.hzPad2(um) + " UT";
            }
            else if(loc)
            {
               var hh:Number = (this.hzPpDay * 24) % 24;
               var H:int = int(Math.floor(hh));
               var M:int = int(Math.floor((hh - H) * 60));
               tf.text = this.hzFmtClock(H,M);
            }
            else { tf.text = realStr; }
            this.hzTxtTop(tf,loc ? y : y + 1);
            this.hzTxtTop(lb,y + 4);
            // v0.24 row = [glyph] LABEL value, e.g. "GAME 18:29 UT" / "LOCAL 6:42 PM" / "PC 8:28 PM", value flush right
            var tw:Number = this.hzTW(tf);
            tf.x = Math.round(r - tf.width + 2);
            var lw:Number = this.hzTW(lb);
            lb.x = Math.round(r - tw - 6 - lb.width + 2);
            var gx:Number = Math.round(r - tw - 6 - lw - 10);
            if(loc) { this.hzPpGlx = gx; } else { this.hzPpGrx = gx; }
            if(loc) { this.hzPpGly = y + 9; } else { this.hzPpGry = y + 9; }
            var gy:Number = y + 9;
            var gc:uint = this.hzIconCol(loc ? HZ_ACCENT : 0x96A6AE);
            if(loc && showUT) { this.hzGlyph(gl,"clock",gx,gy,this.hzIconCol(HZ_ACCENT),bg); }
            else if(loc) { this.hzGlyph(gl,this.hzPpDay >= 0.25 && this.hzPpDay <= 0.75 ? "sun" : "moon",gx,gy,this.hzIconCol(0xFFD678),bg); }
            else { this.hzGlyph(gr,"clock",gx,gy,gc,bg); }
            if(cm)
            {
               // next item goes left of this one; the strip block is everything right of the cursor
               blockW = W - 16 - (gx - 9) + 2;
               r = gx - 9 - 14;
            }
            else { blockW = Math.max(blockW,tw + 6 + lw + 10 + 9); }
            ri++;
         }
         var nameX:Number = cm ? 40 : 86;
         var nameW:Number = W - nameX - (blockW > 0 ? blockW + 8 : 16);
         this.hzPpName.width = Math.max(40,Math.round(nameW + 4));   // v0.31: field as wide as the room (was a fixed 140 px)
         this.hzPpLine.width = Math.max(40,Math.round(nameW + 4));
         this.hzPpDet.width = Math.max(40,Math.round(nameW + 4));
         this.hzFitText(this.hzPpName,this.hzUC(this.hzPpBodyName ? this.hzPpBodyName : "--"),nameW);
         // line 2: temp · status ; STATION / IN SHIP / IN SPACE
         var l2:String;
         if(this.hzPpKind == "ship") { l2 = "IN SHIP"; }
         else if(this.hzPpKind == "station") { l2 = "STATION"; }
         else if(this.hzPpKind == "space") { l2 = "IN SPACE"; }
         else
         {
            var temp:String = this.hzEnvTemp ? this.hzEnvTemp.text : "--";
            l2 = (temp.length > 0 && temp != "--") ? temp + "  ·  " + this.hzPpStatus : this.hzPpStatus;
         }
         if(cm)
         {
            // strip: status follows the name on the same line when there is room
            var nx2:Number = Math.round(nameX + this.hzTW(this.hzPpName) + 10);
            var room2:Number = nameX + nameW - nx2;
            this.hzPpLine.visible = room2 > 40;
            this.hzPpLine.x = nx2;
            this.hzPpLine.width = Math.max(40,Math.round(room2 + 4));
            if(this.hzPpLine.visible) { this.hzFitText(this.hzPpLine,"·  " + l2,room2); }
         }
         else
         {
            this.hzPpLine.visible = true;
            this.hzFitText(this.hzPpLine,l2,nameW);
         }
         this.hzTxtTint(this.hzPpLine,surf ? (this.hzPpStatusCol == 2 ? HZ_RED : (this.hzPpStatusCol == 1 ? HZ_AMB : null)) : null);
         var parts:Array = [];
         if(this.hzPpSys.length > 0) { parts.push(this.hzPpSys.toUpperCase()); }
         if(surf && this.hzEnvGrav && this.hzEnvGrav.text != "--") { parts.push(this.hzEnvGrav.text); }
         if(surf && this.hzEnvAir && this.hzEnvAir.text != "--") { parts.push("AIR " + this.hzEnvAir.text); }
         var det:Boolean = this.hzPlanDetails && parts.length > 0 && !cm;
         this.hzPpDet.visible = det;
         if(cm)
         {
            this.hzTxtTop(this.hzPpName,10);
            this.hzTxtTop(this.hzPpLine,12);
         }
         else if(det)
         {
            this.hzFitText(this.hzPpDet,parts.join("  ·  "),nameW);
            this.hzTxtTop(this.hzPpName,9);
            this.hzTxtTop(this.hzPpLine,33);
            this.hzTxtTop(this.hzPpDet,57);
         }
         else
         {
            this.hzTxtTop(this.hzPpName,13);
            this.hzTxtTop(this.hzPpLine,40);
         }
         var ph:Number = cm ? 36 : 84;
         if(this.hzPpH != ph) { this.hzPpH = ph; this.hzLaidOut = false; }
         this.hzSetSz(this.HorizonEnv_mc,W,ph);
         this.hzPpDraw();
      }

      // ---- VITALS (330x58 each, gap 8): bare icon | LABEL ...... value  + 8px bar with recent-damage ghost ----
      private static const HZ_VN_W:Number = 330;

      private function hzBuildVitNew() : void
      {
         this.hzVitNew = new Sprite();
         this.HorizonVitals_mc.addChild(this.hzVitNew);
         var p:Sprite = this.hzVitNew;
         var i:int = 0;
         while(i < 2)
         {
            var y:Number = i * 66;
            var b:Sprite = new Sprite(); b.y = y; b.name = "hzVnBody";
            p.addChild(b);
            this.hzVnBodies.push(b);
            var ic:Sprite = new Sprite(); ic.x = 13; ic.y = y + 12;
            p.addChild(ic);
            this.hzIcons.push({"s":ic,"k":(i == 0 ? "vnheart" : "vno2"),"c":HZ_ACCENT,"acc":true});   // v0.35: icon + label follow the accent
            this.hzHdr19(this.hzT(p,i == 0 ? "HEALTH" : "OXYGEN",50,y + 9,150,13,"sb","acc",2));
            var v:TextField = this.hzT(p,"--",HZ_VN_W - 14 - 160,y + 4,160,20,"sb","main",1,"right");
            var bar:Sprite = new Sprite(); bar.name = "hzThick8"; bar.x = 14; bar.y = y + 40;
            p.addChild(bar);
            if(i == 0) { this.hzVnHp = v; this.hzVnHpBar = bar; } else { this.hzVnO2 = v; this.hzVnO2Bar = bar; }
            this.hzMeter(bar,HZ_VN_W - 28,1,i == 0 ? HZ_GREEN : HZ_O2_BLUE);
            i++;
         }
         this.hzSetSz(this.HorizonVitals_mc,HZ_VN_W,124);
         this.hzVnDraw();
      }

      private function hzVnDraw() : void
      {
         var vi:int = 0;
         for each(var b:Sprite in this.hzVnBodies)
         {
            var g:* = b.graphics;
            g.clear();
            this.hzPanel(g,HZ_VN_W,58,16);
            // v0.26: warning stripe while the reading is amber / red
            var wf:Number = vi == 0 ? this.hz26VnF0 : this.hz26VnF1;
            if(wf < 0.35) { this.hzAccStripe(g,58,this.hz26WarnCol(wf,HZ_GREEN)); }
            vi++;
         }
         for each(var bar:Sprite in [this.hzVnHpBar,this.hzVnO2Bar])
         {
            for each(var e:Object in this.hzBars) { if(e.b == bar) { this.hzMeterDraw(e.b,e.w,e.cur,e.col,e.ghost); } }
         }
      }

      // =================== v0.19 card skin (approved mockups hud_cards_v1 / planet v3 / crosshair tags v1) ===================
      // Shared tokens: radius 18 (16 small, 14 strips), padding 14, panel #0B1218 ~80% + 1px white 10% edge + soft shadow.
      private static const HZ_AMB:uint = 0xF2A93B;
      private static const HZ_BLUE:uint = 0x4DB6FF;
      // Item rarity colors read from the vanilla QuickContainerListEntry rarity frames (HUDRolloverActivationWidget.fla, Symbol 23):
      // Rare #73CCDF, Epic #9A7BFF, Legendary #EEC162. Exotic has no vanilla frame here -> legendary gold.
      private static const HZ_RAR:Array = [0xF2F7F9,0x73CCDF,0x9A7BFF,0xEEC162,0xEEC162];
      private static const HZ_RARN:Array = ["","RARE","EPIC","LEGENDARY","EXOTIC"];
      private static const HZ_TIME_NAMES:Array = ["OFF","LOCAL / GAME","PC/REAL","LOCAL / GAME + PC/REAL"];
      private static const HZ_CLOCK_NAMES:Array = ["12 H","24 H"];
      private static const HZ_TEMP_NAMES:Array = ["°C","°F"];
      private static const HZ_AFLAY_NAMES:Array = ["COLUMN","ROW","ICONS ONLY"];
      public var hzTimeDisplay:int = 3;
      public var hzClockFmt:int = 0;
      public var hzTempUnit:int = 0;
      public var hzAfLayout:int = 0;
      private var hzSz:Array = [];
      private var hzFontOkMap:Object = {};
      private var hzFontRetry:int = 0;

      private function hzV19() : Boolean
      {
         return true;
      }

      private function hzSetSz(c:Sprite, w:Number, h:Number) : void
      {
         if(!c) { return; }
         for each(var o:Object in this.hzSz) { if(o.c == c) { o.w = w; o.h = h; return; } }
         this.hzSz.push({"c":c,"w":w,"h":h});
      }

      // on-screen size of a card (known v0.19 sizes; hidden classic children are not counted)
      private function hzCW(c:Sprite) : Number
      {
         var pk:String = this.hz31PxKey(c);
         if(pk != null) { return this.hz31PxSize(pk).x; }   // v0.32: Comms proxies use their logical card size
         if(this.hzV19()) { for each(var o:Object in this.hzSz) { if(o.c == c) { return Number(o.w) * c.scaleX; } } }
         return c.width;
      }

      private function hzCH(c:Sprite) : Number
      {
         var pk:String = this.hz31PxKey(c);
         if(pk != null) { return this.hz31PxSize(pk).y; }
         if(this.hzV19()) { for each(var o:Object in this.hzSz) { if(o.c == c) { return Number(o.h) * c.scaleY; } } }
         return c.height;
      }

      // move every existing child of a card into one wrapper (classic look), so the v0.19 form can sit beside it
      private function hzWrap(c:Sprite) : Sprite
      {
         var w:Sprite = new Sprite();
         while(c.numChildren > 0) { w.addChild(c.getChildAt(0)); }
         c.addChild(w);
         return w;
      }

      // Panel: soft drop shadow, translucent fill (CardOpacity / CardColor), 1px edge. r = corner radius in px.
      private function hzPanel(g:*, w:Number, h:Number, r:Number, tint:int = -1, edge:int = -1) : void
      {
         var lt:Boolean = this.hzLight();
         var x:Number = this.hzOpExtra();
         var rr:Number = Math.min(r,h / 2);
         var i:int = 0;
         while(i < 4)
         {
            g.beginFill(0x000000,(0.055 + 0.035 * x) * (lt ? 0.55 : 1));
            g.drawRoundRect(-1 - i,2 - i * 0.5,w + 2 + i * 2,h + 1 + i * 2,(rr + i) * 2,(rr + i) * 2);
            g.endFill();
            i++;
         }
         var f:uint = tint >= 0 ? uint(tint) : this.hzPanelFill();
         // "none" scale mode: the edge stays one device pixel whatever the HUD / stage scale
         if(edge >= 0) { g.lineStyle(1,uint(edge),0.5,true,"none"); }
         else { g.lineStyle(1,lt ? 0x0E1E1C : 0xFFFFFF,lt ? 0.24 : 0.18,true,"none"); }
         g.beginFill(f,this.hzPanelA(lt ? 0.96 : 0.92));
         g.drawRoundRect(0.5,0.5,w - 1,h - 1,rr * 2,rr * 2);
         g.endFill();
         g.lineStyle();
      }

      // round icon tile (darker disc) with optional ring
      private function hzTileDisc(g:*, cx:Number, cy:Number, r:Number, ring:int = -1, ringA:Number = 0.35) : void
      {
         var dk:Boolean = this.hzDarkText();
         g.beginFill(dk ? this.hzMix(this.hzPanelFill(),0x000000,0.14) : 0x060A0E,dk ? 0.9 : 0.92);
         g.drawCircle(cx,cy,r);
         g.endFill();
         if(ring >= 0)
         {
            g.lineStyle(1.4,this.hzIconCol(uint(ring)),ringA,true);
            g.drawCircle(cx,cy,r - 4);
            g.lineStyle();
         }
      }

      private function hzMainCol() : uint
      {
         return this.hzDarkText() ? 0x0E151B : 0xF2F7F9;
      }

      // v0.19 text: explicit size / face ("sb" SemiBold, "rg" Regular, "bd" Bold) / tone ("main","mut","dim","acc","col")
      private function hzT(p:Sprite, txt:String, x:Number, y:Number, w:Number, fs:Number, face:String, tone:String, ls:Number = 0, align:String = "left", col:uint = 0xFFFFFF) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         t.width = w; t.height = fs + 10; t.x = x; t.y = y;
         p.addChild(t);
         var o:Object = {"tf":t,"size":fs,"fs":fs,"face":face,"tone":tone,"col":col,"ls":ls,"right":align == "right","center":align == "center","y0":y,"raw":null,"role":null,"keep":true};
         this.hzTexts.push(o);
         t.text = txt;
         this.hzApplyFmt(o);
         return t;
      }

      private function hzApplyFmt19(o:Object) : void
      {
         var fs:Number = Number(o.fs);
         var sz:int = this.hzTextSz19(o,fs);
         var dk:Boolean = this.hzDarkText();
         var col:uint = 0;
         switch(String(o.tone))
         {
            case "main": col = dk ? 0x0E151B : 0xF2F7F9; break;
            case "mut": col = dk ? 0x2E3E46 : 0xB2C0C7; break;
            case "dim": col = dk ? 0x4A5A64 : 0x8E9CA4; break;
            case "acc": col = this.hzTextAccent(); break;
            default: col = this.hzIconCol(uint(o.col));
         }
         if(o.tint != undefined && o.tint !== null) { col = o.abs ? uint(o.tint) : this.hzIconCol(uint(o.tint)); }
         var face:String = String(o.face);
         if(face == "rg" && sz <= 12) { face = "sb"; } // small labels never thinner than SemiBold
         var f:TextFormat = new TextFormat(this.hzFontName(face),sz,col);
         if(o.right) { f.align = "right"; }
         if(o.center) { f.align = "center"; }
         // HeaderStyle 0: CAPS + letter-spaced titles; 1: Title Case, tight tracking
         f.letterSpacing = (o.hdr19 && this.hzHeaderStyle == 1) ? Math.min(Number(o.ls),0.2) : Number(o.ls);
         var tf:TextField = TextField(o.tf);
         var keepTxt:String = o.hdr19 ? this.hzUC(tf.text) : tf.text;
         tf.filters = [];
         tf.text = "";
         tf.defaultTextFormat = f;
         tf.text = keepTxt;
         tf.setTextFormat(f);
         tf.textColor = col;
         o.cc = col;
         var nl:int = (o.lines != undefined && int(o.lines) > 1) ? int(o.lines) : 1;
         tf.height = (sz + 5) * nl + 6;
         var su:Number = o.su != undefined && Number(o.su) > 0 ? Number(o.su) : 1;
         if(o.y0 != undefined && o.y0 != null) { tf.y = Math.round((Number(o.y0) - (sz - fs) / 2) / su) * su; }
         tf.x = Math.round(tf.x / su) * su;
         tf.width = Math.round(tf.width);
         // crisp glyphs: advanced AA, pixel grid fit, a touch of extra weight on small sizes (ignored where unsupported)
         try
         {
            tf.antiAliasType = "advanced";
            tf.gridFitType = sz >= 14 ? "subpixel" : "pixel";
            tf.sharpness = 60;
            tf.thickness = sz <= 12 ? 60 : (sz <= 15 ? 35 : 15);
         }
         catch(errAA:Error) { }
         tf.filters = this.hzTy19Filters();
         o.sh = this.hzTextShadow;   // v0.36: applied shadow state (hzTypoGuard)
      }

      // TextShadow (v0.24): off by default (sharpest). On = a hard 1px drop, no blur, on every card and opacity.
      // Dark text (light cards) gets a 1px white lift instead, so the toggle is visible there too.
      private function hzTy19Filters() : Array
      {
         return this.hz35Shadow(this.hzDarkText());   // v0.35: was a 1 px blur-0 drop (invisible in Scaleform)
      }

      // mark a v0.19 title field: follows HeaderStyle (case + tracking)
      private function hzHdr19(tf:TextField) : void
      {
         var o:Object = this.hzTxtObj(tf);
         if(o) { o.hdr19 = true; this.hzApplyFmt(o); }
      }

      // title text for v0.19 cards: HeaderStyle 0 CAPS, 1 Title Case (numerals / roman numerals / codes stay upper)
      private function hzUC(s:String) : String
      {
         if(s == null) { return ""; }
         if(this.hzHeaderStyle == 0) { return s.toUpperCase(); }
         var w:Array = s.split(" ");
         var i:int = 0;
         while(i < w.length)
         {
            var ws:String = String(w[i]);
            var up:String = ws.toUpperCase();
            if(ws.length > 0 && !/[0-9]/.test(ws) && !/^(I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII)[,.:]?$/.test(up) && ws != "...")
            {
               var c0:int = (ws.charAt(0) == "(" || ws.charAt(0) == "'") && ws.length > 1 ? 1 : 0;
               w[i] = ws.substr(0,c0) + ws.charAt(c0).toUpperCase() + ws.substr(c0 + 1).toLowerCase();
            }
            else { w[i] = up; }
            i++;
         }
         return w.join(" ");
      }

      // one font face probe (cached); "$Horizon_Font*" only counts when it really renders glyphs
      private function hzFontProbe(n:String) : Boolean
      {
         if(this.hzFontOkMap[n] != undefined) { return this.hzFontOkMap[n] == 1; }
         var ok:Boolean = false;
         try
         {
            var t:TextField = new TextField();
            t.embedFonts = true;
            var tf:TextFormat = new TextFormat(n,20,0xFFFFFF);
            t.defaultTextFormat = tf;
            t.text = "WMW";
            t.setTextFormat(tf);
            ok = t.textWidth > 8 && t.textHeight > 4;
            if(ok)
            {
               // a font the player does not have may silently fall back to a default face: compare with a name that never exists
               var b:TextField = new TextField();
               b.embedFonts = true;
               var bf:TextFormat = new TextFormat("$Horizon_NoSuchFace_x",20,0xFFFFFF);
               b.defaultTextFormat = bf;
               b.text = "WMW";
               b.setTextFormat(bf);
               if(b.textWidth > 0 && Math.abs(b.textWidth - t.textWidth) < 0.01) { ok = false; }
            }
         }
         catch(err:Error) { ok = false; }
         this.hzFontOkMap[n] = ok ? 1 : 0;
         if(ok)
         {
            this.hzAfRemeasure = true;
            if(this.hzAfRemeasureAt == 0) { this.hzAfRemeasureAt = Math.max(1,this.hzFrameN); }
         }
         return ok;
      }

      private var hzLsMode:int = -1; // 1 = textWidth already includes letterSpacing, 0 = it does not

      // rendered text width: textWidth plus letterSpacing when the player's textWidth omits it (probed once)
      private function hzTW(tf:TextField) : Number
      {
         if(!tf) { return 0; }
         var w:Number = tf.textWidth;
         if(this.hzLsMode < 0)
         {
            this.hzLsMode = 0;
            try
            {
               var a:TextField = new TextField();
               var f:TextFormat = new TextFormat(this.hzFontName(),20,0xFFFFFF);
               a.embedFonts = true; a.defaultTextFormat = f; a.text = "MMMMMMMMMM"; a.setTextFormat(f);
               var w0:Number = a.textWidth;
               f.letterSpacing = 10;
               a.setTextFormat(f);
               if(w0 > 0 && a.textWidth - w0 > 60) { this.hzLsMode = 1; }
            }
            catch(err:Error) { this.hzLsMode = 0; }
         }
         if(this.hzLsMode == 0)
         {
            var ls:Number = 0;
            try { ls = Number(tf.getTextFormat().letterSpacing); } catch(err2:Error) { ls = 0; }
            if(!isNaN(ls) && ls > 0 && tf.text.length > 1) { w += ls * (tf.text.length - 1); }
         }
         return w;
      }

      private function hzPad2(n:int) : String
      {
         return n < 10 ? "0" + n : String(n);
      }

      private function hzFmtClock(h:int, m:int) : String
      {
         if(this.hzClockFmt == 1) { return this.hzPad2(h) + ":" + this.hzPad2(m); }
         var h12:int = h % 12;
         if(h12 == 0) { h12 = 12; }
         return h12 + ":" + this.hzPad2(m) + " " + (h < 12 ? "AM" : "PM");
      }

      private function hzFmtInt(v:Number) : String
      {
         var neg:Boolean = v < 0;
         var s:String = String(Math.round(Math.abs(v)));
         var out:String = "";
         while(s.length > 3) { out = "," + s.substr(s.length - 3) + out; s = s.substr(0,s.length - 3); }
         return (neg ? "-" : "") + s + out;
      }

      private function hzRarCol(r:int) : uint
      {
         if(r <= 0 || r >= HZ_RAR.length) { return this.hzMainCol(); }
         return this.hzIconCol(uint(HZ_RAR[r]));
      }

      // small rounded chip (fill or outline) drawn into g; returns its width
      private function hzChip(g:*, tf:TextField, x:Number, y:Number, txt:String, col:uint, solid:Boolean, outline:Boolean = false) : Number
      {
         var o:Object = this.hzTxtObj(tf);
         if(o) { o.tint = solid ? 0xFFFFFF : col; o.abs = solid; }
         tf.text = txt;
         if(o) { this.hzApplyFmt(o); }
         var w:Number = this.hzTW(tf) + 14;
         var h:Number = 15;
         var c:uint = this.hzIconCol(col);
         if(outline) { x = Math.round(x); y = Math.round(y); w = Math.round(w); }   // v0.36: outlined chips on whole pixels
         if(solid) { g.beginFill(c,0.85); }
         else { g.beginFill(c,0.2); }
         g.drawRoundRect(x,y,w,h,h,h);
         g.endFill();
         if(outline) { this.hz36RingG(g,x,y,w,h,8,c,0.65,1); }   // v0.36: bars + quarter rings, no stroke
         tf.x = x + 7 - 2;
         this.hzTxtTop(tf,y - 1);
         tf.visible = true;
         return w;
      }

      // ---- original vector glyphs (Graphics only) ----
      private function hzGlyph(g:*, kind:String, cx:Number, cy:Number, col:uint, bg:uint) : void
      {
         var k:int = 0;
         switch(kind)
         {
            case "thermal":
               g.lineStyle(1.5,col,1,true);
               g.beginFill(col,0.004);
               g.drawRoundRect(cx - 2.6,cy - 10,5.2,14,5.2,5.2);
               g.endFill();
               g.lineStyle();
               g.beginFill(col,1); g.drawCircle(cx,cy + 6,5); g.endFill();
               g.lineStyle(1.6,col,1); g.moveTo(cx,cy - 4); g.lineTo(cx,cy + 4); g.lineStyle();
               break;
            case "radiation":
               g.beginFill(col,1);
               while(k < 3)
               {
                  var a0:Number = (-90 + k * 120 - 30) * Math.PI / 180;
                  var a1:Number = (-90 + k * 120 + 30) * Math.PI / 180;
                  g.moveTo(cx,cy);
                  var st:int = 0;
                  while(st <= 6) { var aa:Number = a0 + (a1 - a0) * st / 6; g.lineTo(cx + Math.cos(aa) * 10,cy + Math.sin(aa) * 10); st++; }
                  g.lineTo(cx,cy);
                  k++;
               }
               g.endFill();
               g.beginFill(bg,1); g.drawCircle(cx,cy,4); g.endFill();
               g.beginFill(col,1); g.drawCircle(cx,cy,2.3); g.endFill();
               break;
            case "corrosive":
               g.beginFill(col,1);
               g.moveTo(cx,cy - 10); g.lineTo(cx + 5.6,cy + 2); g.curveTo(cx + 6,cy + 10,cx,cy + 10); g.curveTo(cx - 6,cy + 10,cx - 5.6,cy + 2); g.lineTo(cx,cy - 10);
               g.endFill();
               g.beginFill(bg,1); g.drawCircle(cx - 0.5,cy + 4.5,1.6); g.endFill();
               break;
            case "airborne":
               g.lineStyle(1.8,col,1);
               g.moveTo(cx - 9,cy - 6); g.lineTo(cx + 5,cy - 6);
               g.moveTo(cx - 9,cy); g.lineTo(cx + 9,cy);
               g.moveTo(cx - 9,cy + 6); g.lineTo(cx + 2,cy + 6);
               g.lineStyle();
               g.beginFill(col,1); g.drawCircle(cx + 7,cy - 8,1.6); g.drawCircle(cx + 10,cy + 4,1.6); g.drawCircle(cx + 4,cy + 9,1.6); g.endFill();
               break;
            case "injury":
               g.beginFill(col,1);
               g.drawRoundRect(cx - 2,cy - 10,4,20,4,4);
               g.drawRoundRect(cx - 10,cy - 2,20,4,4,4);
               g.endFill();
               g.lineStyle(2,bg,1); g.moveTo(cx - 9,cy + 9); g.lineTo(cx + 9,cy - 9); g.lineStyle();
               break;
            case "bolt":
               g.beginFill(col,1);
               g.moveTo(cx + 1,cy - 8); g.lineTo(cx - 5,cy + 1); g.lineTo(cx - 0.5,cy + 1); g.lineTo(cx - 2,cy + 8); g.lineTo(cx + 5,cy - 1.5); g.lineTo(cx + 0.5,cy - 1.5); g.lineTo(cx + 1,cy - 8);
               g.endFill();
               break;
            case "diamond":
               g.beginFill(col,1); g.moveTo(cx,cy - 9); g.lineTo(cx + 9,cy); g.lineTo(cx,cy + 9); g.lineTo(cx - 9,cy); g.lineTo(cx,cy - 9); g.endFill();
               break;
            case "sun":
               g.beginFill(col,1); g.drawCircle(cx,cy,2.5); g.endFill();
               g.lineStyle(1.1,col,1);
               while(k < 8) { var sa:Number = k * Math.PI / 4; g.moveTo(cx + Math.cos(sa) * 3.8,cy + Math.sin(sa) * 3.8); g.lineTo(cx + Math.cos(sa) * 5.4,cy + Math.sin(sa) * 5.4); k++; }
               g.lineStyle();
               break;
            case "moon":
               g.beginFill(col,1); g.drawCircle(cx,cy,4); g.endFill();
               g.beginFill(bg,1); g.drawCircle(cx + 2.6,cy - 1,4); g.endFill();
               break;
            case "clock":
               g.lineStyle(1.1,col,1,true); g.drawCircle(cx,cy,3.6);
               g.moveTo(cx,cy); g.lineTo(cx,cy - 2.2); g.moveTo(cx,cy); g.lineTo(cx + 1.8,cy);
               g.lineStyle();
               break;
            default:
               // generic hazard triangle
               g.lineStyle(1.6,col,1,true);
               g.moveTo(cx,cy - 9); g.lineTo(cx + 9,cy + 7); g.lineTo(cx - 9,cy + 7); g.lineTo(cx,cy - 9);
               g.moveTo(cx,cy - 3); g.lineTo(cx,cy + 2); g.moveTo(cx,cy + 4); g.lineTo(cx,cy + 5);
               g.lineStyle();
         }
      }

      // ---- COMPASS strip (640x58, r14) + heading pill (72x26) ----
      private static const HZ_CMP19_W:Number = 640;
      private var hzCmpOld:Sprite;
      private var hzCmpNew:Sprite;
      private var hzCmpBody19:Sprite;
      private var hzCmpTicks19:Sprite;
      private var hzCmpMarks19:Sprite;
      private var hzCmpLbl19:Array = [];
      private var hzCmpHead19:TextField;
      private var hzCmpPill19:Sprite;
      // v0.25 compact (strips) form: 420 x 40, cardinal labels only, short ticks, heading inside the strip
      private var hzCmpW19:Number = 640;
      private var hzCmpC:int = -1;          // compact form currently applied (-1 = not yet)
      private var hzCmpMY:Number = 47;      // marker row
      private var hzCmpHeadIn:TextField;

      private function hzCmpApplyCompact() : void
      {
         if(!this.hzCmpBody19) { return; }
         var c:int = this.hz34C("Compass") ? 1 : 0;
         if(c == this.hzCmpC) { return; }
         this.hzCmpC = c;
         this.hzCmpW19 = c == 1 ? 420 : 640;
         this.hzCmpMY = c == 1 ? 29 : 47;
         this.hzCmpPill19.visible = c == 0;
         this.hzCmpPill19.x = this.hzCmpW19 / 2 - 36;
         if(this.hzCmpHeadIn) { this.hzCmpHeadIn.visible = c == 1; this.hzCmpHeadIn.x = Math.round(this.hzCmpW19 - 12 - this.hzCmpHeadIn.width + 2); }
         var i:int = 0;
         while(i < this.hzCmpLbl19.length)
         {
            var card:Boolean = i % 2 == 0;
            this.hzTxtTop(TextField(this.hzCmpLbl19[i]),c == 1 ? 3 : (card ? 9 : 12));
            i++;
         }
         this.hzSetSz(this.HorizonCompass_mc,this.hzCmpW19,c == 1 ? 40 : 90);
         this.hzLaidOut = false;
         this.hzCmpDraw19();
         try { this.hzDrawCompassMarkers(); } catch(errC:Error) { }
      }

      private function hzBuildCmp19() : void
      {
         this.hzCmpOld = this.hzWrap(this.HorizonCompass_mc);
         var p:Sprite = new Sprite();
         this.hzCmpNew = p;
         this.HorizonCompass_mc.addChild(p);
         this.hzCmpBody19 = new Sprite(); p.addChild(this.hzCmpBody19);
         this.hzCmpTicks19 = new Sprite(); p.addChild(this.hzCmpTicks19);
         var i:int = 0;
         while(i < HZ_CARD.length)
         {
            var card:Boolean = i % 2 == 0;
            this.hzCmpLbl19.push(this.hzT(p,HZ_CARD[i],0,card ? 9 : 12,40,card ? 15 : 11,card ? "sb" : "rg",card ? "main" : "mut",0,"center"));
            i++;
         }
         this.hzCmpMarks19 = new Sprite(); p.addChild(this.hzCmpMarks19);
         this.hzCmpPill19 = new Sprite(); this.hzCmpPill19.x = HZ_CMP19_W / 2 - 36; this.hzCmpPill19.y = 64;
         p.addChild(this.hzCmpPill19);
         this.hzCmpHead19 = this.hzT(this.hzCmpPill19,"0°",0,4,72,14,"sb","acc",0.6,"center");
         this.hzCmpHeadIn = this.hzT(p,"0°",HZ_CMP19_W - 12 - 60,12,60,12,"sb","acc",0.6,"right");
         this.hzCmpHeadIn.visible = false;
         this.hzSetSz(this.HorizonCompass_mc,HZ_CMP19_W,90);
         this.hzCmpApplyCompact();
      }

      private function hzCmpDraw19() : void
      {
         if(!this.hzCmpBody19) { return; }
         var g:* = this.hzCmpBody19.graphics;
         g.clear();
         var CW:Number = this.hzCmpW19;
         this.hzPanel(g,CW,this.hzCmpC == 1 ? 40 : 58,14);
         var ac:uint = this.hzIconCol(HZ_ACCENT);
         g.beginFill(ac,1);
         g.moveTo(CW / 2 - 6,0); g.lineTo(CW / 2 + 6,0); g.lineTo(CW / 2,7); g.lineTo(CW / 2 - 6,0);
         g.endFill();
         var pg:* = this.hzCmpPill19.graphics;
         pg.clear();
         this.hzPanel(pg,72,26,13,-1,ac);
         this.hzCmpTick19();
      }

      private function hzCmpTick19() : void
      {
         if(!this.hzCmpTicks19) { return; }
         var deg:Number = this.hzCmpDeg;
         var g:* = this.hzCmpTicks19.graphics;
         g.clear();
         var W:Number = this.hzCmpW19;
         var cmp:Boolean = this.hzCmpC == 1;
         var tY:Number = cmp ? 21 : 32;
         var tS:Number = cmp ? 0.55 : 1;
         var cx:Number = W / 2;
         var ppd:Number = (W - 40) / 180;
         var col:uint = this.hzMainCol();
         var a:int = 0;
         while(a < 360)
         {
            var d:Number = a - deg;
            while(d > 180) { d -= 360; }
            while(d < -180) { d += 360; }
            if(Math.abs(d) <= 90)
            {
               var x:Number = cx + d * ppd;
               var fade:Number = Math.pow(Math.max(0,1 - Math.abs(x - cx) / (cx - 16)),0.6);
               var L:Number = a % 45 == 0 ? 10 : (a % 15 == 0 ? 7 : 4);
               var al:Number = a % 45 == 0 ? 0.86 : (a % 15 == 0 ? 0.47 : 0.27);
               if(fade > 0.02)
               {
                  g.lineStyle(a % 45 == 0 ? 1.6 : 1.1,col,al * fade);
                  g.moveTo(x,tY); g.lineTo(x,tY + Math.round(L * tS));
               }
            }
            a += 5;
         }
         g.lineStyle();
         var i:int = 0;
         while(i < this.hzCmpLbl19.length)
         {
            var t:TextField = this.hzCmpLbl19[i];
            var dd:Number = i * 45 - deg;
            while(dd > 180) { dd -= 360; }
            while(dd < -180) { dd += 360; }
            t.visible = Math.abs(dd) <= 88 && (!cmp || i % 2 == 0);   // compact: N / E / S / W only
            var lx:Number = cx + dd * ppd;
            t.x = lx - t.width / 2;
            t.alpha = Math.pow(Math.max(0,1 - Math.abs(lx - cx) / (cx - 16)),0.6);
            i++;
         }
         if(this.hzCmpHead19) { this.hzCmpHead19.text = String(int(Math.round(deg)) % 360) + "°"; }
         if(this.hzCmpHeadIn && cmp) { this.hzCmpHeadIn.text = String(int(Math.round(deg)) % 360) + "°"; }
      }

      // one marker on the v0.19 strip at y = 47 (original glyphs)
      private function hzCmpMark19(g:*, kind:String, mx:Number, fa:Number) : void
      {
         var y:Number = this.hzCmpMY;
         var ac:uint = this.hzIconCol(HZ_ACCENT);
         var dk:Boolean = this.hzDarkText();
         switch(kind)
         {
            case "quest":
               g.beginFill(ac,fa);
               g.moveTo(mx,y - 6); g.lineTo(mx + 6,y); g.lineTo(mx,y + 6); g.lineTo(mx - 6,y); g.lineTo(mx,y - 6);
               g.endFill();
               break;
            case "follower":
               // v0.27: own color (FollowerColor, default bright green #5CFF7A) + thin dark edge, a touch larger
               g.lineStyle(1,0x0B1620,0.75 * fa,true);
               g.beginFill(this.hz27FolCol(),fa);
               g.drawCircle(mx,y - 4.8,3);
               g.endFill();
               g.beginFill(this.hz27FolCol(),fa);
               g.moveTo(mx - 6,y + 5.5); g.curveTo(mx - 6,y - 1,mx,y - 1); g.curveTo(mx + 6,y - 1,mx + 6,y + 5.5); g.lineTo(mx - 6,y + 5.5);
               g.endFill();
               g.lineStyle();
               break;
            case "ship":
               g.beginFill(this.hzIconCol(HZ_BLUE),fa);
               g.moveTo(mx,y - 6); g.lineTo(mx + 2,y - 1.6); g.lineTo(mx + 6,y + 1.4); g.lineTo(mx + 6,y + 3); g.lineTo(mx + 1.6,y + 2.2); g.lineTo(mx + 1.2,y + 5);
               g.lineTo(mx - 1.2,y + 5); g.lineTo(mx - 1.6,y + 2.2); g.lineTo(mx - 6,y + 3); g.lineTo(mx - 6,y + 1.4); g.lineTo(mx - 2,y - 1.6); g.lineTo(mx,y - 6);
               g.endFill();
               break;
            case "enemyT":
            case "enemy":
               g.beginFill(this.hzIconCol(HZ_RED),0.95 * fa);
               g.drawCircle(mx,y,kind == "enemyT" ? 4.2 : 3.5);
               g.endFill();
               break;
            case "player":
               g.beginFill(this.hzMainCol(),fa);
               g.drawRect(mx - 1,y - 6,2,12);
               g.moveTo(mx + 1,y - 6); g.lineTo(mx + 7,y - 3); g.lineTo(mx + 1,y); g.lineTo(mx + 1,y - 6);
               g.endFill();
               break;
            case "outpost":
               g.lineStyle(1.3,this.hzMainCol(),0.85 * fa,true);
               g.drawRect(mx - 4,y - 4,8,8);
               g.lineStyle();
               break;
            default:
               g.lineStyle(1.3,this.hzMainCol(),0.85 * fa,true);
               var k:int = 0;
               while(k <= 6)
               {
                  var ha:Number = (k * 60 - 90) * Math.PI / 180;
                  if(k == 0) { g.moveTo(mx + Math.cos(ha) * 6,y + Math.sin(ha) * 6); }
                  else { g.lineTo(mx + Math.cos(ha) * 6,y + Math.sin(ha) * 6); }
                  k++;
               }
               g.lineStyle();
         }
      }

      // ---- QUESTS card (380x78) + compact strip (420x36) ----
      private static const HZ_Q19_W:Number = 380;
      private static const HZ_CQ19_W:Number = 420;
      private var hzQOld:Sprite;
      private var hzQNew:Sprite;
      private var hzQ19Body:Sprite;
      private var hzQ19T:TextField;
      private var hzQ19O:TextField;
      private var hzQ19D:TextField;
      private var hzCQOld:Sprite;
      private var hzCQNew:Sprite;
      private var hzCQ19Body:Sprite;
      private var hzCQ19T:TextField;
      private var hzCQ19O:TextField;
      private var hzCQ19D:TextField;
      private var hzQName:String = "";
      private var hzQObjStr:String = "";
      private var hzQDistStr:String = "";

      private function hzBuildQuest19() : void
      {
         this.hzQOld = this.hzWrap(this.HorizonQuest_mc);
         var p:Sprite = new Sprite();
         this.hzQNew = p;
         this.HorizonQuest_mc.addChild(p);
         this.hzQ19Body = new Sprite(); p.addChild(this.hzQ19Body);
         this.hzQ19T = this.hzT(p,"",74,10,HZ_Q19_W - 74 - 14 - 84,15,"sb","main",2);
         this.hzHdr19(this.hzQ19T);
         this.hzQ19D = this.hzT(p,"",HZ_Q19_W - 14 - 84,11,84,14,"sb","acc",1,"right");
         this.hzQ19O = this.hzT(p,"",74,37,HZ_Q19_W - 74 - 14,13,"rg","mut");
         try { this.hz27QBuild(p); } catch(errQB:Error) { }
         this.hzSetSz(this.HorizonQuest_mc,HZ_Q19_W,78);
         this.hzQDraw19();
      }

      private function hzBuildCQuest19() : void
      {
         this.hzCQOld = this.hzWrap(this.HorizonCompactQuest_mc);
         var p:Sprite = new Sprite();
         this.hzCQNew = p;
         this.HorizonCompactQuest_mc.addChild(p);
         this.hzCQ19Body = new Sprite(); p.addChild(this.hzCQ19Body);
         this.hzCQ19T = this.hzT(p,"",32,9,200,12,"sb","main",1.6);
         this.hzHdr19(this.hzCQ19T);
         this.hzCQ19O = this.hzT(p,"",120,9,200,12,"rg","mut");
         this.hzCQ19D = this.hzT(p,"",HZ_CQ19_W - 14 - 80,9,80,12,"sb","acc",0.8,"right");
         this.hzSetSz(this.HorizonCompactQuest_mc,HZ_CQ19_W,36);
         this.hzQDraw19();
      }

      private function hzQDraw19() : void
      {
         if(this.hzQ19Body)
         {
            var g:* = this.hzQ19Body.graphics;
            g.clear();
            this.hzPanel(g,HZ_Q19_W,this.hz27QH,18);
            this.hzTileDisc(g,38,39,24,HZ_ACCENT,0.35);
            this.hzGlyph(g,"diamond",38,39,this.hzIconCol(HZ_ACCENT),0);
         }
         if(this.hzCQ19Body)
         {
            var c:* = this.hzCQ19Body.graphics;
            c.clear();
            this.hzPanel(c,HZ_CQ19_W,36,14);
            var ac:uint = this.hzIconCol(HZ_ACCENT);
            c.beginFill(ac,1); c.moveTo(20,12); c.lineTo(26,18); c.lineTo(20,24); c.lineTo(14,18); c.lineTo(20,12); c.endFill();
         }
         this.hzQSync();
      }

      // title = quest name (hzSetQuestTitle), objective = active marker strText, distance = fDistanceToPlayer (HudCompassData)
      private function hzQSync() : void
      {
         var name:String = this.hzQName != null ? this.hzQName : "";
         var obj:String = this.hzQObjStr != null ? this.hzQObjStr : "";
         var title:String = name.length > 0 ? name : (obj.length > 0 ? obj : "No active objective");
         var sub:String = name.length > 0 ? obj : "";
         var dist:String = this.hzQDistStr != null ? this.hzQDistStr : "";
         if(this.hzQ19T)
         {
            this.hzQ19D.text = dist;
            this.hzQ19D.visible = dist.length > 0;
            var tw:Number = HZ_Q19_W - 74 - 14 - (dist.length > 0 ? this.hzTW(this.hzQ19D) + 12 : 0);
            this.hzFitText(this.hzQ19T,this.hzUC(title),tw);
            this.hzQ19O.visible = sub.length > 0;
            if(sub.length > 0 || this.hz27QSubs.length > 0)
            {
               this.hzFitText(this.hzQ19O,sub,HZ_Q19_W - 74 - 14);
               this.hzTxtTop(this.hzQ19T,10);
               this.hzTxtTop(this.hzQ19D,11);
            }
            else
            {
               this.hzTxtTop(this.hzQ19T,28);
               this.hzTxtTop(this.hzQ19D,29);
            }
            try { this.hz27QLayout(sub.length > 0); } catch(errQL:Error) { }
         }
         if(this.hzCQ19T)
         {
            this.hzCQ19D.text = dist;
            this.hzCQ19D.visible = dist.length > 0;
            var right:Number = HZ_CQ19_W - 14 - (dist.length > 0 ? this.hzTW(this.hzCQ19D) + 12 : 0);
            this.hzFitText(this.hzCQ19T,this.hzUC(title),Math.min(200,right - 32));
            var ox:Number = 32 + this.hzTW(this.hzCQ19T) + 6;
            this.hzCQ19O.visible = sub.length > 0 && right - ox > 40;
            if(this.hzCQ19O.visible)
            {
               this.hzCQ19O.x = ox;
               this.hzFitText(this.hzCQ19O,"·  " + sub,right - ox);
            }
         }
      }

      // ---- JETPACK (330x72): round tile + glyph | JETPACK / BOOST nn% | 10-segment bar ----
      private static const HZ_J19_W:Number = 330;
      private var hzJetOld:Sprite;
      private var hzJetNew:Sprite;
      private var hzJ19Body:Sprite;
      private var hzJ19Glyph:Sprite;
      private var hzJ19Seg:Sprite;
      private var hzJ19Bolt:Sprite;
      private var hzJ19Title:TextField;
      private var hzJ19Sub:TextField;
      private var hzJ19W:Number = 330;
      private var hzJ19H:Number = 72;
      private var hzJ19BarY:Number = 54;
      private var hzJetRech:Boolean = false;
      private var hzJetLastC:Number = -2;

      private function hzBuildJet19() : void
      {
         this.hzJetOld = this.hzWrap(this.HorizonCard_mc);
         var p:Sprite = new Sprite();
         this.hzJetNew = p;
         this.HorizonCard_mc.addChild(p);
         this.hzJ19Body = new Sprite(); p.addChild(this.hzJ19Body);
         this.hzJ19Glyph = new Sprite(); this.hzJ19Glyph.x = 40; this.hzJ19Glyph.y = 34; p.addChild(this.hzJ19Glyph);
         this.hzJ19Title = this.hzT(p,"JETPACK",78,9,170,14,"sb","main",2);
         this.hzHdr19(this.hzJ19Title);
         this.hzChip13(this.hzJ19Title,"Jetpack");
         this.hzJ19Bolt = new Sprite(); this.hzJ19Bolt.x = 83; this.hzJ19Bolt.y = 39; p.addChild(this.hzJ19Bolt);
         this.hzJ19Sub = this.hzT(p,"BOOST 100%",78,29,230,12,"sb","acc",1.2);
         this.hzChip13(this.hzJ19Sub,"Jetpack");
         this.hzJ19Seg = new Sprite(); this.hzJ19Seg.x = 78; this.hzJ19Seg.y = 54; p.addChild(this.hzJ19Seg);
         this.hzSetSz(this.HorizonCard_mc,HZ_J19_W,72);
         this.hzJ19Draw();
      }

      private function hzJ19Draw() : void
      {
         if(!this.hzJ19Body) { return; }
         var szT:int = this.hzChipSzOn(14,"Jetpack",13);
         var szS:int = this.hzChipSzOn(12,"Jetpack",13);
         var subTop:int = 9 + szT + 6;
         var barY:int = subTop + szS + 13;
         var h:Number = Math.max(72,barY + 18);
         if(this.hzJ19Title) { this.hzTxtTop(this.hzJ19Title,9); }
         if(this.hzJ19Sub) { this.hzTxtTop(this.hzJ19Sub,subTop); }
         var tw:Number = 0;
         if(this.hzJ19Title) { tw = Math.max(tw,this.hzTW(this.hzJ19Title)); }
         if(this.hzJ19Sub) { tw = Math.max(tw,this.hzTW(this.hzJ19Sub)); }
         var w:Number = Math.max(HZ_J19_W,78 + tw + 18);
         if(w != this.hzJ19W || h != this.hzJ19H) { this.hzLaidOut = false; }
         this.hzJ19W = w;
         this.hzJ19H = h;
         this.hzJ19BarY = barY;
         this.hzSetSz(this.HorizonCard_mc,w,h);
         var cy:Number = Math.round(h / 2);
         if(this.hzJ19Glyph) { this.hzJ19Glyph.y = cy - 2; }
         if(this.hzJ19Bolt) { this.hzJ19Bolt.y = subTop + Math.round(szS / 2) + 4; }
         if(this.hzJ19Seg) { this.hzJ19Seg.y = barY; }
         var g:* = this.hzJ19Body.graphics;
         g.clear();
         this.hzPanel(g,w,h,18);
         var col:uint = this.hzJetRech ? HZ_AMB : HZ_ACCENT;
         this.hzTileDisc(g,40,cy,26,-1);
         g.lineStyle(1.4,this.hzIconCol(col),0.35,true); g.drawCircle(40,cy,22); g.lineStyle();
         // original jetpack glyph: twin-tank pack, center spine, two nozzles, optional flames
         var j:* = this.hzJ19Glyph.graphics;
         j.clear();
         var mc:uint = this.hzDarkText() ? 0x18242C : 0xF2F7F9;
         j.lineStyle(1.8,mc,1,true);
         j.beginFill(mc,0.004);
         j.drawRoundRect(-9,-12,18,18,8,8);
         j.endFill();
         j.lineStyle(1.2,mc,0.63);
         j.moveTo(0,-9); j.lineTo(0,3);
         j.lineStyle();
         j.beginFill(mc,1);
         j.moveTo(-8,6); j.lineTo(-3,6); j.lineTo(-4,10); j.lineTo(-7,10); j.lineTo(-8,6);
         j.moveTo(3,6); j.lineTo(8,6); j.lineTo(7,10); j.lineTo(4,10); j.lineTo(3,6);
         j.endFill();
         if(!this.hzJetRech)
         {
            j.beginFill(0xFFB45A,0.9);
            j.moveTo(-7,11); j.lineTo(-4,11); j.lineTo(-5.5,17); j.lineTo(-7,11);
            j.moveTo(4,11); j.lineTo(7,11); j.lineTo(5.5,17); j.lineTo(4,11);
            j.endFill();
         }
         this.hzJ19Sync();
      }

      private function hzJ19Sync() : void
      {
         if(!this.hzJ19Seg) { return; }
         var c:Number = this.hzJetCharge;
         var f:Number = c < 0 ? 1 : Math.max(0,Math.min(1,c));
         var rech:Boolean = this.hzJetRech;
         var col:uint = this.hzIconCol(rech ? HZ_AMB : (f < 0.15 ? HZ_RED : HZ_ACCENT));
         this.hzJ19Bolt.visible = rech;
         var bg:* = this.hzJ19Bolt.graphics; bg.clear();
         if(rech) { this.hzGlyph(bg,"bolt",0,0,this.hzIconCol(HZ_AMB),0); }
         this.hzJ19Sub.x = rech ? 92 : 78;
         this.hzJ19Sub.text = (rech ? "RECHARGING " : "BOOST ") + Math.round(f * 100) + "%";
         this.hzTxtTint(this.hzJ19Sub,rech ? HZ_AMB : (f < 0.15 ? HZ_RED : null));
         var g:* = this.hzJ19Seg.graphics;
         g.clear();
         var n:int = 10;
         var gap:Number = 3;
         var bw:Number = Math.max(238,this.hzJ19W - 78 - 14);
         var sw:Number = (bw - gap * (n - 1)) / n;
         var lit:Number = f * n;
         var tr:uint = this.hzDarkText() ? 0x000000 : 0xFFFFFF;
         var i:int = 0;
         while(i < n)
         {
            var x:Number = i * (sw + gap);
            g.beginFill(tr,0.12); g.drawRoundRect(x,0,sw,6,3,3); g.endFill();
            var fp:Number = Math.max(0,Math.min(1,lit - i));
            if(fp > 0)
            {
               g.beginFill(col,fp >= 1 ? 1 : (rech ? 0.35 : Math.max(0.25,fp)));
               g.drawRoundRect(x,0,sw,6,3,3);
               g.endFill();
            }
            i++;
         }
      }

      // charge rising below full = recharging; falling = boosting (held until the next rise)
      private function hzJetTrack(c:Number) : void
      {
         var was:Boolean = this.hzJetRech;
         if(c < 0 || c >= 0.999) { this.hzJetRech = false; }
         else if(this.hzJetLastC > -1 && c > this.hzJetLastC + 0.0005) { this.hzJetRech = true; }
         else if(this.hzJetLastC > -1 && c < this.hzJetLastC - 0.0005) { this.hzJetRech = false; }
         this.hzJetLastC = c;
         if(was != this.hzJetRech) { this.hzJ19Draw(); } else { this.hzJ19Sync(); }
      }

      // ---- AFFLICTIONS chips (>=190x48, r16): env hazards (global exposure bar) + personal effects (red name) ----
      private var hzAfOld:Sprite;
      private var hzAfNew:Sprite;
      private var hzAfChips:Array = [];
      private var hzAfEnv:Array = [];
      private var hzAfPers:Array = [];
      private var hzAfSoak:Number = 0;
      private var hzAfSeen:Object = {};
      private var hzAfRemeasure:Boolean = false;
      private var hzAfRemeasureAt:int = 0;
      private var hzAfLoadAt:int = 0;
      private var hzAfTitleW:Number = 0;
      private var hzAfLastWall:Number = 0;
      private var hzAfH:Number = 48;
      private var hzAfW:Number = 190;

      private function hzBuildAffl19() : void
      {
         this.hzAfOld = this.hzWrap(this.HorizonAffl_mc);
         this.hzAfNew = new Sprite();
         this.HorizonAffl_mc.addChild(this.hzAfNew);
         var i:int = 0;
         while(i < 5)
         {
            var c:Sprite = new Sprite();
            this.hzAfNew.addChild(c);
            var body:Sprite = new Sprite(); c.addChild(body);
            var lb:TextField = this.hzT(c,"",48,8,240,13,"sb","acc",2);
            this.hzHdr19(lb);
            this.hzVit13(lb);
            var sb:TextField = this.hzT(c,"",48,24,200,13,"sb","col",0.6);
            this.hzVit13(sb);
            c.visible = false;
            this.hzAfChips.push({"c":c,"b":body,"l":lb,"s":sb});
            i++;
         }
         this.hzSetSz(this.HorizonAffl_mc,190,48);
         this.hzAfLayoutChips([]);
      }

      private function hzAfKind(ic:String) : String
      {
         var li:String = ic.toLowerCase();
         if(li.indexOf("thermal") >= 0 || li.indexOf("heat") >= 0 || li.indexOf("cold") >= 0) { return "thermal"; }
         if(li.indexOf("radiation") >= 0) { return "radiation"; }
         if(li.indexOf("corros") >= 0) { return "corrosive"; }
         if(li.indexOf("airborne") >= 0 || li.indexOf("toxic") >= 0) { return "airborne"; }
         return "hazard";
      }

      private function hzAfSetEnv(a:Array, soak:Number) : void
      {
         var out:Array = [];
         var keys:Array = [];
         if(a)
         {
            for each(var ef:Object in a)
            {
               var ic:String = ef && ef.sEffectIcon != null ? String(ef.sEffectIcon) : "";
               if(ic == "" || ic == "HazardEffect_RestoreSoak") { continue; }
               var nm:String = this.hzPretty(ic);
               if(keys.indexOf(nm) >= 0) { continue; }
               keys.push(nm);
               out.push({"key":"e:" + nm,"name":nm,"kind":this.hzAfKind(ic),"env":true});
            }
         }
         this.hzAfEnv = out;
         this.hzAfSoak = isNaN(soak) ? 0 : Math.max(0,Math.min(1,soak));
         this.hzAfSync();
      }

      private function hzAfSetPers(a:Array) : void
      {
         var out:Array = [];
         var keys:Array = [];
         if(a)
         {
            for each(var o:Object in a)
            {
               if(!o || o.sEffectIcon == null) { continue; }
               var sys:String = this.hzPretty(String(o.sEffectIcon));
               if(sys.length == 0 || keys.indexOf(sys) >= 0) { continue; }
               keys.push(sys);
               out.push({"key":"p:" + sys,"name":"Affliction","sub":sys,"kind":"injury","env":false,"cat":String(o.sEffectIcon).replace(new RegExp("_(Negative|Positive)$"),"")});
            }
         }
         this.hzAfPers = out;
         this.hzAfSync();
      }

      private function hzAfSortFn(a:Object, b:Object) : int
      {
         if(a.sev != b.sev) { return a.sev > b.sev ? -1 : 1; }
         if(a.seen != b.seen) { return a.seen > b.seen ? -1 : 1; }
         return 0;
      }

      private function hzAfSync() : void
      {
         var all:Array = [];
         var live:Object = {};
         var crit:Boolean = this.hzAfSoak >= 0.66;
         var hz27src:Array = this.hzAfEnv.concat(this.hz27PersSafe());
         for each(var o:Object in hz27src)
         {
            live[o.key] = true;
            if(this.hzAfSeen[o.key] == undefined) { this.hzAfSeen[o.key] = this.hzFrameN; }
            o.seen = int(this.hzAfSeen[o.key]);
            o.sev = o.env ? (crit ? 2 : 1) : 3;
            all.push(o);
         }
         try { if(this.hz26OwInAffl()) { live["w:ow"] = true; all.push({"key":"w:ow","name":"Overweight","kind":"weight","env":false,"ow":true,"sev":2,"seen":0}); } } catch(errOw:Error) { }
         for(var k:String in this.hzAfSeen) { if(!live[k]) { delete this.hzAfSeen[k]; } }
         all.sort(this.hzAfSortFn);
         this.hzAfflCount = this.hzV19() ? all.length : (this.hzAfPers.length > 0 ? 1 : 0);
         this.hzAfLayoutChips(all);
         this.hzRefreshVisibility();
      }

      private function hzAfRetryLayout() : void
      {
         try { if(this.hzAfNew && this.hz31AfLast != null) { this.hzAfLayoutChips(this.hz31AfLast); } } catch(err:Error) { }
      }

      private function hzAfArmRelayout() : void
      {
         this.hzAfRemeasure = true;
         if(this.hzAfRemeasureAt == 0) { this.hzAfRemeasureAt = Math.max(1,this.hzFrameN); }
      }

      private function hzAfOnLoad() : void
      {
         try
         {
            this.hz27Alerts = [];
            this.hzAfSeen = {};
            this.hzAfRemeasure = true;
            this.hzAfRemeasureAt = Math.max(1,this.hzFrameN);
            this.hzAfLoadAt = Math.max(1,this.hzFrameN);
            if(this.hzAfNew) { this.hzAfSync(); }
         }
         catch(err:Error) { }
      }

      private function hzAfLoadWatch() : void
      {
         var now:Number = this.hz26Now();
         if(this.hzAfLastWall > 0 && now - this.hzAfLastWall > 4000) { this.hzAfArmRelayout(); }
         if(now > 0) { this.hzAfLastWall = now; }
         if(this.hzAfLoadAt > 0)
         {
            var age:int = this.hzFrameN - this.hzAfLoadAt;
            if(age == 30 || age == 120) { this.hzAfRetryLayout(); }
            if(age >= 120) { this.hzAfLoadAt = 0; }
         }
         if(this.hzAfRemeasure)
         {
            this.hzAfRetryLayout();
            if(this.hzAfRemeasureAt > 0 && this.hzFrameN - this.hzAfRemeasureAt >= 120)
            {
               this.hzAfRemeasure = false;
               this.hzAfRemeasureAt = 0;
            }
         }
      }

      private function hzAfLayoutChips(all:Array) : void
      {
         if(!this.hzAfNew) { return; }
         this.hz31AfLast = all;
         this.hzAfRemeasure = false;
         var mode:int = this.hzAfLayout;
         var shown:int = Math.min(4,all.length);
         var more:int = all.length - shown;
         var none:Boolean = all.length == 0;
         var icons:Boolean = mode == 2;
         var x:Number = 0;
         var y:Number = 0;
         var maxW:Number = 0;
         var rowH:Number = 48;
         var sz13:int = this.hzAf13Sz();
         var grow:int = Math.max(0,sz13 - 13);
         var barY:int = 23 + grow + sz13 + 3;
         var bg:uint = this.hzDarkText() ? this.hzMix(this.hzPanelFill(),0x000000,0.14) : 0x060A0E;
         var i:int = 0;
         while(i < this.hzAfChips.length)
         {
            var ch:Object = this.hzAfChips[i];
            var c:Sprite = Sprite(ch.c);
            var isMore:Boolean = (i == shown && more > 0) || (none && i == 0);
            if(i >= shown && !isMore) { c.visible = false; i++; continue; }
            c.visible = true;
            var g:* = Sprite(ch.b).graphics;
            g.clear();
            var lb:TextField = TextField(ch.l);
            var sb:TextField = TextField(ch.s);
            var w:Number;
            var h:Number = 48;
            if(isMore)
            {
               h = icons ? 48 : 30;
               lb.visible = true; sb.visible = false;
               lb.text = none ? "NO AFFLICTIONS" : (icons ? "+" + more : "+" + more + " MORE");
               if(none) { icons = false; }
               this.hzTxtTint(lb,none ? 0x96A6AE : null);
               var mo31:Object = this.hzTxtObj(lb);
               if(mo31) { this.hzApplyFmt(mo31); }
               lb.width = Math.round(this.hzTW(lb) + 8);
               w = icons ? Math.max(48,Math.ceil(this.hzTW(lb)) + 16) : Math.max(96,Math.ceil(this.hzTW(lb)) + 32);
               lb.x = icons ? (48 - this.hzTW(lb)) / 2 - 2 : 16;
               this.hzTxtTop(lb,h / 2 - 9);
               this.hzPanel(g,w,h,16);
            }
            else
            {
               var a:Object = all[i];
               var col:uint = a.ow ? HZ_AMB : (a.env ? (this.hzAfSoak >= 0.66 ? HZ_RED : HZ_AMB) : HZ_RED);
               var ic:uint = this.hzIconCol(col);
               var hasSub:Boolean = a.sub != undefined && a.sub != null && String(a.sub).length > 0;
               var two:Boolean = a.env || a.ow || hasSub;
               lb.visible = !icons;
               sb.visible = !icons && two;
               var tw31:Number = 0;
               // v0.31 FIX: the chip sprites are reused; the "NO AFFLICTIONS" / "+N MORE" state moves the title to x 16
               // (or centers it in icons mode) and nothing moved it back, so a hazard arriving after "NO AFFLICTIONS"
               // drew its title over the icon. Title and sub-line now always share the inset past the icon.
               lb.x = HZ31_AF_TX;
               sb.x = HZ31_AF_TX;
               if(!icons)
               {
                  // v0.31: final format first (font, TextScale, tint, header case), then measure, cap + ellipsis, and size
                  // the field and the chip from that measurement in this same call (no one-frame overflow)
                  lb.text = this.hzUC(String(a.name));
                  this.hzTxtTint(lb,(two && !hasSub) ? null : HZ_RED);
                  this.hzTxtTint(sb,a.ow ? HZ_AMB : null);
                  sb.text = two ? (a.ow ? this.hz26OwText() : (a.env ? "Exposure " + Math.round(this.hzAfSoak * 100) + "%" : String(a.sub))) : "";
                  tw31 = this.hz31AfFit(lb,sb,two);
                  if(two)
                  {
                     h = a.env ? Math.max(48, barY + 9) : Math.max(48,23 + grow + sz13 + 6);
                     this.hzTxtTop(lb,7);
                     this.hzTxtTop(sb,23 + grow);
                  }
                  else { this.hzTxtTop(lb,15); }
               }
               w = icons ? 48 : Math.max(HZ31_AF_MINW,Math.ceil(tw31) + 48 + 22);
               this.hzPanel(g,w,h,16);
               this.hzTileDisc(g,24,24,16,-1);
               g.lineStyle(1.2,ic,0.55,true); g.drawCircle(24,24,16); g.lineStyle();
               if(a.ow) { this.hz26Weight(g,24,25,ic,0.85); } else { this.hzGlyph(g,String(a.kind),24,24,ic,bg); }
               if(a.env && !icons)
               {
                  var bw:Number = w - 48 - 14;
                  var tr:uint = this.hzDarkText() ? 0x000000 : 0xFFFFFF;
                  g.beginFill(tr,0.14); g.drawRoundRect(48,barY,bw,4,4,4); g.endFill();
                  if(this.hzAfSoak > 0.005)
                  {
                     g.beginFill(ic,1); g.drawRoundRect(48,barY,Math.max(4,bw * this.hzAfSoak),4,4,4); g.endFill();
                  }
               }
            }
            c.x = x; c.y = y;
            if(mode == 1) { x += w + 8; maxW = x - 8; if(h > rowH) { rowH = h; } }
            else { y += h + 8; maxW = Math.max(maxW,w); }
            i++;
         }
         var tw:Number = Math.max(48,maxW);
         var th:Number = mode == 1 ? rowH : Math.max(48,y - 8);
         if(th != this.hzAfH || tw != this.hzAfW) { this.hzAfH = th; this.hzAfW = tw; this.hzLaidOut = false; }
         this.hzSetSz(this.HorizonAffl_mc,tw,th);
      }

      // ---- EQUIPMENT v0.19 (420x92): weapon line-art | NAME / cartridges · ammo type ..... COUNT / reserve + RELOAD chip ----
      // v0.25 (equipment_weapon_v1): A = 470 wide, 3:1 icon tile 128 wide on the left, text from x 156;
      // compact (strips) = C: 300 x 56, outline + clip / reserve. Both carry the left accent stripe.
      // v0.26 (equipment_power_v1): A = 400 wide, tile 108 x 68, text from x 134, a touch smaller type; optional
      // grenade / Starborn power row under a divider (+34). C = 300 (+ grenades / power arc on the right).
      private static const HZ_E19_W:Number = 400;
      private static const HZ_E19_TX:Number = 134;
      private var hzE19T:Number = 92;
      private var hzE19Wd:Number = 400;
      private var hzE19Cm:Boolean = false;
      private var hzE19Sym:Sprite;               // holder for the game's own per-weapon symbol (never bundled)
      private var hzE19SymObj:DisplayObject = null;
      private var hzE19SymName:String = "";
      private var hzE19LoadN:int = 0;            // load counter: stale completions are dropped
      private var hzE19SwfSt:int = 0;            // WeaponIcons.swf: 0 not requested, 1 loading, 2 loaded, -1 failed
      private var hzE19Ldr:Loader = null;
      private var hzEq19:Sprite;
      private var hzE19Body:Sprite;
      private var hzE19Icon:Sprite;
      private var hzE19Cart:Sprite;
      private var hzE19Chip:Sprite;
      private var hzE19Name:TextField;
      private var hzE19Type:TextField;
      private var hzE19Cnt:TextField;
      private var hzE19Res:TextField;
      private var hzE19RelT:TextField;
      private var hzE19H:Number = 92;
      private var hzE19Exp:Boolean = false;

      private function hzBuildEq19() : void
      {
         this.hzEq19 = new Sprite();
         this.HorizonAmmo_mc.addChild(this.hzEq19);
         var p:Sprite = this.hzEq19;
         this.hzE19Body = new Sprite(); p.addChild(this.hzE19Body);
         this.hzE19Icon = new Sprite(); this.hzE19Icon.x = 26; this.hzE19Icon.y = 24; this.hzE19Icon.scaleX = this.hzE19Icon.scaleY = 2.1;
         p.addChild(this.hzE19Icon);
         this.hzE19Sym = new Sprite(); this.hzE19Sym.mouseEnabled = false; this.hzE19Sym.mouseChildren = false;
         p.addChild(this.hzE19Sym);
         this.hzE19Name = this.hzT(p,"--",HZ_E19_TX,14,HZ_E19_W - HZ_E19_TX - 14,14,"sb","main",1.6);
         this.hzHdr19(this.hzE19Name);
         this.hzE19Cart = new Sprite(); this.hzE19Cart.x = HZ_E19_TX; p.addChild(this.hzE19Cart);
         this.hzE19Type = this.hzT(p,"",HZ_E19_TX + 24,51,160,12,"sb","mut",1.2);
         this.hzE19Cnt = this.hzT(p,"--",0,36,140,28,"bd","main",0.5,"right");
         this.hzE19Res = this.hzT(p,"",0,54,120,14,"rg","dim",0.4);
         this.hzE19Chip = new Sprite(); p.addChild(this.hzE19Chip);
         this.hzE19RelT = this.hzT(this.hzE19Chip,"RELOAD",0,0,80,10,"sb","col",1.2,"left",HZ_AMB);
         this.hzE19Chip.visible = false;
         this.hzE19Draw();
      }

      private function hzE19Draw() : void
      {
         if(!this.hzEq19) { return; }
         var g:* = this.hzE19Body.graphics;
         g.clear();
         var W:Number = this.hzE19Wd;
         var H:Number = this.hzE19H;
         this.hzPanel(g,W,H,this.hzE19Cm ? 14 : 18);
         this.hzAccStripe(g,H,this.hzEqLow ? HZ_AMB : HZ_ACCENT);
         if(!this.hzE19Cm)
         {
            // wide 3:1 icon tile
            var dk:Boolean = this.hzDarkText();
            g.lineStyle(1,this.hzIconCol(HZ_ACCENT),0.28,true,"none");
            g.beginFill(dk ? this.hzMix(this.hzPanelFill(),0x000000,0.14) : 0x080D12,0.92);
            g.drawRoundRect(12.5,12.5,107,this.hzE19T - 25,22,22);
            g.endFill();
            g.lineStyle();
         }
         this.hzE19DrawIcon();
         var c:* = this.hzE19Cart.graphics;
         c.clear();
         var col:uint = this.hzIconCol(this.hzEqLow ? HZ_AMB : HZ_ACCENT);
         var i:int = 0;
         while(i < 3)
         {
            var bx:Number = i * 6;
            c.beginFill(col,0.95);
            c.moveTo(bx,14); c.lineTo(bx,5); c.curveTo(bx,0,bx + 2,0); c.curveTo(bx + 4,0,bx + 4,5); c.lineTo(bx + 4,14); c.lineTo(bx,14);
            c.endFill();
            c.beginFill(col,0.5); c.drawRect(bx,15,4,1.6); c.endFill();
            i++;
         }
      }

      private function hzE19DrawIcon() : void
      {
         if(!this.hzE19Icon) { return; }
         var g:* = this.hzE19Icon.graphics;
         g.clear();
         var c:uint = this.hzTxtMain();
         var k:String = this.hzEqKind.length > 0 ? this.hzEqKind : "rifle";
         g.lineStyle(1.5 / 2.1,c,1,true);
         this.hzWeapPath(g,k);
         g.lineStyle();
         if(k == "rifle" || k == "sniper" || k == "shotgun" || k == "laser")
         {
            g.lineStyle(1.2 / 2.1,this.hzIconCol(HZ_ACCENT),0.9);
            g.moveTo(14,9.6); g.lineTo(36,9.6);
            g.lineStyle();
         }
         this.hzE19Icon.filters = [new GlowFilter(this.hzIconCol(HZ_ACCENT),this.hzDarkText() ? 0.25 : 0.4,6,6,1.2,1)];
         this.hzE19PlaceIcons();
      }

      // icon box: inside the tile (A) or the left of the strip (C)
      private function hzE19Box() : Rectangle
      {
         if(this.hzE19Cm) { return new Rectangle(16,10,96,this.hzE19T - 20); }
         return new Rectangle(22,20,86,this.hzE19T - 40);
      }

      // fit a display object into r by its own bounds (uniform scale <= mx), whole-unit position
      private function hzE19Fit(o:DisplayObject, r:Rectangle, mx:Number) : void
      {
         o.scaleX = o.scaleY = 1;
         var b:Rectangle = o.getBounds(o);
         if(b.width < 1 || b.height < 1) { return; }
         var sc:Number = Math.min(mx,Math.min(r.width / b.width,r.height / b.height));
         o.scaleX = o.scaleY = sc;
         o.x = Math.round(r.x + (r.width - b.width * sc) / 2 - b.x * sc);
         o.y = Math.round(r.y + (r.height - b.height * sc) / 2 - b.y * sc);
      }

      private function hzE19PlaceIcons() : void
      {
         if(!this.hzE19Icon || !this.hzE19Sym) { return; }
         var has:Boolean = this.hzE19SymObj != null && this.hzE19SymObj.parent == this.hzE19Sym;
         this.hzE19Icon.visible = !has;
         this.hzE19Sym.visible = has;
         var r:Rectangle = this.hzE19Box();
         if(has)
         {
            try
            {
               var col:uint = this.hzIconCol(this.hzEqLow ? HZ_AMB : HZ_ACCENT);
               this.hzE19SymObj.transform.colorTransform = new ColorTransform(0,0,0,1,(col >> 16) & 0xFF,(col >> 8) & 0xFF,col & 0xFF,0);
               this.hzE19Fit(this.hzE19SymObj,r,4);
               this.hzE19Sym.filters = [new GlowFilter(col,this.hzDarkText() ? 0.2 : 0.35,5,5,1.1,1)];
            }
            catch(errF:Error) { this.hzE19Icon.visible = true; this.hzE19Sym.visible = false; }
         }
         if(this.hzE19Icon.visible) { this.hzE19Fit(this.hzE19Icon,r,2.1); }
      }

      // WeaponData.sIconLinkageName -> the game's per-model symbol. Same order as vanilla SymbolLoaderClip:
      // use the definition if the game already has it, else load WeaponIcons.swf into the current domain once.
      // Failure of any kind = the generic Horizon outline.
      // WeaponData.sIconLinkageName -> the game's per-model symbol. Same order as vanilla SymbolLoaderClip:
      // use the definition if the game already has it, else load WeaponIcons.swf into the current domain once.
      // v0.26: the previous symbol stays on screen until the new one exists (no generic-outline flash on a swap),
      // and every instance is cached per linkage name (a swap back is instant, nothing is re-created).
      // Failure of any kind = the generic Horizon outline.
      private var hzE19SymCache:Object = {};
      private function hzE19SetSym(name:String) : void
      {
         if(name == this.hzE19SymName) { return; }
         this.hzE19SymName = name;
         this.hzE19LoadN++;
         if(name.length == 0) { this.hzE19DropSym(); this.hzE19PlaceIcons(); return; }
         if(this.hzE19MakeSym()) { this.hzE19PlaceIcons(); return; }
         if(this.hzE19SwfSt == 0)
         {
            this.hzE19SwfSt = 1;
            try
            {
               this.hzE19Ldr = new Loader();
               this.hzE19Ldr.contentLoaderInfo.addEventListener(Event.COMPLETE,this.hzE19OnSwf);
               this.hzE19Ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,this.hzE19OnSwfErr);
               this.hzE19Ldr.load(new URLRequest("WeaponIcons.swf"),new LoaderContext(false,ApplicationDomain.currentDomain));
            }
            catch(errL:Error) { this.hzE19SwfSt = -1; }
         }
         // still loading: keep whatever is shown; loaded / failed and no definition: generic outline
         if(this.hzE19SwfSt != 1) { this.hzE19DropSym(); }
         this.hzE19PlaceIcons();
      }

      private function hzE19DropSym() : void
      {
         try { if(this.hzE19SymObj && this.hzE19SymObj.parent) { this.hzE19SymObj.parent.removeChild(this.hzE19SymObj); } } catch(errD:Error) { }
         this.hzE19SymObj = null;
      }

      private function hzE19OnSwf(e:Event) : void
      {
         this.hzE19SwfSt = 2;
         try { if(!this.hzE19MakeSym()) { this.hzE19DropSym(); } } catch(err:Error) { this.hzE19DropSym(); }
         this.hzE19PlaceIcons();
      }

      private function hzE19OnSwfErr(e:Event) : void
      {
         this.hzE19SwfSt = -1;
         this.hzE19DropSym();
         this.hzE19PlaceIcons();
      }

      private function hzE19MakeSym() : Boolean
      {
         var name:String = this.hzE19SymName;
         if(name.length == 0) { return false; }
         try
         {
            var inst:DisplayObject = this.hzE19SymCache[name] as DisplayObject;
            if(inst == null)
            {
               if(!ApplicationDomain.currentDomain.hasDefinition(name)) { return false; }
               var C:Class = ApplicationDomain.currentDomain.getDefinition(name) as Class;
               if(C == null) { return false; }
               inst = new C() as DisplayObject;
               if(inst == null) { return false; }
               if(inst is MovieClip) { MovieClip(inst).stop(); }
               // our own instance: drop the sizing box / ammo parts so only the weapon outline is measured and shown
               if(inst is DisplayObjectContainer)
               {
                  var dc:DisplayObjectContainer = DisplayObjectContainer(inst);
                  var i:int = dc.numChildren - 1;
                  while(i >= 0)
                  {
                     var ch:DisplayObject = dc.getChildAt(i);
                     var cn:String = ch && ch.name ? ch.name : "";
                     if(cn.indexOf("Sizer") >= 0 || cn.indexOf("AmmoIcon") >= 0 || cn.indexOf("AmmoLabel") >= 0) { dc.removeChild(ch); }
                     i--;
                  }
               }
               this.hzE19SymCache[name] = inst;
            }
            if(this.hzE19SymObj != inst) { this.hzE19DropSym(); }
            this.hzE19SymObj = inst;
            if(inst.parent != this.hzE19Sym) { this.hzE19Sym.addChild(inst); }
            return true;
         }
         catch(err:Error) { }
         return false;
      }

      private function hzE19Sync() : void
      {
         if(!this.hzEq19 || !this.hzEqCount) { return; }
         var cm:Boolean = this.hz34C("Equipment");
         this.hzE19Cm = cm;
         var W:Number = cm ? 300 : HZ_E19_W;
         var full:String = this.hzEqFullName.length > 0 ? this.hzUC(this.hzEqFullName) : "--";
         var expand:Boolean = (this.hzArrange || this.hzFrameN < this.hzEqExpandUntil) && !cm;
         var no:Object = this.hzTxtObj(this.hzE19Name);
         var lines:int = 1;
         this.hzE19Name.wordWrap = expand;
         this.hzE19Name.multiline = expand;
         if(expand) { this.hzE19Name.text = full; lines = this.hzE19Name.numLines > 1 ? 2 : 1; }
         if(no && int(no.lines) != lines) { no.lines = lines; this.hzApplyFmt(no); }
         if(!expand) { this.hzFitText(this.hzE19Name,full,cm ? W - 126 - 14 : W - HZ_E19_TX - 14); }
         this.hzE19Exp = expand;
         var ts:Number = Math.max(0.8,Math.min(1.3,this.hzTextScale));
         var dy:Number = lines > 1 ? Math.round(15 * ts) + 5 : 0;
         var am:Boolean = this.hzEqHasAmmo;
         // compact (C): outline + clip / reserve only; the name shows only when there is no ammo (melee)
         this.hzE19Name.visible = !cm || !am;
         this.hzE19Name.x = cm ? 126 : HZ_E19_TX;
         if(cm) { this.hzTxtTop(this.hzE19Name,19); } else { this.hzTxtTop(this.hzE19Name,14); }
         this.hzE19Cnt.visible = am;
         this.hzE19Res.visible = am && !this.hzEqPct;
         this.hzE19Cart.visible = am && !cm;
         var typeTxt:String = this.hzAmmoType ? this.hzAmmoType.text : "";
         var showType:Boolean = am && !cm && typeTxt.length > 0 && typeTxt != "--";
         this.hzE19Type.visible = showType;
         var low:Boolean = am && this.hzEqLow;
         var empty:Boolean = am && !this.hzEqPct && this.hzEqClip <= 0;
         this.hz28GX = NaN;   // v0.30: no ammo-line chip any more (grenade badge on the weapon icon)
         this.hz30CntL = NaN;
         this.hzE19Chip.visible = (low || empty) && !cm;
         if(am)
         {
            this.hzE19Cnt.text = this.hzEqCount.text;
            this.hzTxtTint(this.hzE19Cnt,empty ? HZ_RED : (low ? HZ_AMB : (this.hzTxtObj(this.hzEqCount) ? this.hzTxtObj(this.hzEqCount).tint : null)));
            this.hzE19Res.text = this.hzEqReserve.text;
            var rw:Number = this.hzE19Res.visible ? this.hzTW(this.hzE19Res) + 4 : 0;
            this.hzE19Res.x = W - 14 - rw - 2;
            this.hzTxtTop(this.hzE19Res,cm ? 26 : 54 + dy);
            this.hzE19Cnt.x = W - 14 - rw - (rw > 0 ? 6 : 0) - 140;
            this.hzTxtTop(this.hzE19Cnt,cm ? 9 : 35 + dy);
            var countLeft:Number = this.hzE19Cnt.x + 140 - this.hzTW(this.hzE19Cnt) - 4;
            this.hz30CntL = countLeft;
            this.hzE19Cart.y = 53 + dy;
            var lim:Number = countLeft - 10;
            if(this.hzE19Chip.visible)
            {
               var cg:* = this.hzE19Chip.graphics;
               cg.clear();
               var ccol:uint = empty ? HZ_RED : HZ_AMB;
               this.hzE19RelT.text = "RELOAD";
               this.hzTxtTint(this.hzE19RelT,ccol);
               var cw:Number = this.hzTW(this.hzE19RelT) + 16;
               cg.lineStyle(1,this.hzIconCol(ccol),0.9,true);
               cg.beginFill(this.hzIconCol(ccol),0.14);
               cg.drawRoundRect(0,0,cw,16,16,16);
               cg.endFill();
               cg.lineStyle();
               this.hzE19RelT.x = 6;
               this.hzTxtTop(this.hzE19RelT,0);
               this.hzE19Chip.x = countLeft - cw - 10;
               this.hzE19Chip.y = 53 + dy;
               lim = this.hzE19Chip.x - 8;
            }
            if(showType)
            {
               this.hzFitText(this.hzE19Type,typeTxt.toUpperCase(),Math.max(30,lim - HZ_E19_TX - 24));
               this.hzTxtTop(this.hzE19Type,52 + dy);
            }
         }
         var T:Number = cm ? 56 : (am ? 92 + dy : Math.max(72,40 + dy));
         this.hzE19T = T;
         var h:Number = T;
         var xr:Object = null;
         try { xr = this.hz26EqRow(cm,W,T); } catch(errX:Error) { xr = null; if(this.hz26EqRowS) { this.hz26EqRowS.visible = false; } }
         if(xr != null) { h = Number(xr.h); W = Number(xr.w); }
         if(W != this.hzE19Wd) { this.hzE19Wd = W; this.hzLaidOut = false; }
         if(h != this.hzE19H) { this.hzE19H = h; this.hzLaidOut = false; }
         this.hzSetSz(this.HorizonAmmo_mc,W,h);
         this.hzE19Draw();
      }

      private function hzE19Tick() : void
      {
         if(!this.hzEq19 || !this.hzEq19.visible) { return; }
         var want:Boolean = (this.hzArrange || this.hzFrameN < this.hzEqExpandUntil) && !this.hz34C("Equipment");
         if(want != this.hzE19Exp || this.hz34C("Equipment") != this.hzE19Cm) { this.hzE19Sync(); }
         if(this.hzEqLow && this.hzE19Cnt)
         {
            var a:Number = 0.35 + 0.45 * (0.5 + 0.5 * Math.sin(this.hzEqPulse));
            this.hzE19Cnt.filters = [new GlowFilter(this.hzIconCol(HZ_AMB),a,10,10,1.6,1)].concat(this.hzTyFilters());
         }
         else if(this.hzE19Cnt && this.hzE19Cnt.filters.length > this.hzTyFilters().length)
         {
            this.hzE19Cnt.filters = this.hzTyFilters();
         }
      }

      // ---- TARGET / crosshair tags v0.20 (target_container_v1): A item, B container list, C owned container,
      //      D compare card, E prompt card (people and objects), E2 hostile. Anchored to the crosshair (+26,+26 like the mockup).
      //      While our tag shows, the whole vanilla activation widget (RolloverActivation_mc: header, list, item card,
      //      button bars) and the targeting ring (Reticle_mc + the RolloverReticle leader-line shapes) are hidden via
      //      alpha only; input stays with the game (ProcessUserEvent / list focus). Everything is restored on step-back. ----
      private var hzTgOld:Sprite;
      private var hzTg19:Sprite;
      private var hzT19G:Sprite;
      private var hzT19Name:TextField;
      private var hzT19Meta:TextField;
      private var hzT19Ch1:TextField;
      private var hzT19Ch2:TextField;
      private var hzT19Ch3:TextField;
      private var hzT19HdrR:TextField;
      private var hzT19Foot:TextField;
      private var hzT19FootR:TextField;
      private var hzT19Rows:Array = [];
      private var hzT19Cmp:Array = [];
      private var hzT19Btn:Array = [];
      private var hzT19Sig:String = "";
      private var hzT19Ver:int = 0;
      private var hzTgItems:Array = null;
      private var hzTgEnName:String = "";
      private var hzTgRank:int = 0;
      private var hzTgOnScr:Boolean = false;
      private var hzTgScale:Number = 1.125;    // TargetScale: extra size for the crosshair cards only (1.333 x 1.125 = 1.5 px per unit at 1440p)
      private var hzScrH:int = 0;              // ScreenHeight: your vertical resolution for device-pixel snapping (0 = off)
      private var hzT19A:Number = 0;           // our tag's fade (quick fade-out, never the vanilla roll-off)
      private var hzXlTf:TextField;            // probe field for $-key translation
      private var hzTgGhost:Number = -1;
      private var hzTgGhostHold:int = 0;
      private var hzT19LastHp:Number = -1;
      private var hzT19W:Number = 300;
      private var hzT19H:Number = 60;
      private var hzT19Keys:String = "";

      private function hzBuildTg19() : void
      {
         this.hzTgOld = this.hzWrap(this.HorizonTarget_mc);
         var p:Sprite = new Sprite();
         this.hzTg19 = p;
         this.HorizonTarget_mc.addChild(p);
         this.hzT19G = new Sprite(); p.addChild(this.hzT19G);
         this.hzT19Name = this.hzT(p,"",18,11,260,16,"sb","main",2);
         this.hzHdr19(this.hzT19Name);
         this.hzT19Meta = this.hzT(p,"",100,34,180,13,"rg","mut",0.5,"right");
         this.hzT19Ch1 = this.hzT(p,"",0,0,140,10,"sb","col",1.5);
         this.hzT19Ch2 = this.hzT(p,"",0,0,140,10,"sb","col",1.4);
         this.hzT19Ch3 = this.hzT(p,"",0,0,140,10,"sb","col",1.4);
         this.hzT19HdrR = this.hzT(p,"",100,15,140,12,"sb","mut",1.4,"right");
         this.hzT19Foot = this.hzT(p,"",14,0,200,12,"rg","mut",0.3);
         this.hzT19FootR = this.hzT(p,"",100,0,180,12,"rg","mut",0.5,"right");
         var i:int = 0;
         while(i < 5)
         {
            this.hzT19Rows.push({"n":this.hzT(p,"",30,0,220,14,"rg","col",0.3,"left",0xD7E0E6),"c":this.hzT(p,"",200,0,60,13,"sb","mut",0.5,"right"),"t":this.hzT(p,"",0,0,100,10,"sb","col",1.4)});
            i++;
         }
         i = 0;
         while(i < 6)
         {
            this.hzT19Cmp.push({"l":this.hzT(p,"",18,0,140,12,"sb","mut",1.4),"v":this.hzT(p,"",100,0,120,15,"sb","main",0.3,"right"),"d":this.hzT(p,"",200,0,80,13,"sb","col",0.3,"right")});
            i++;
         }
         i = 0;
         while(i < 4)
         {
            var lp:TextField = this.hzT(p,"",0,0,160,13,"sb","main",1.6);
            var lh:TextField = this.hzT(p,"",0,0,160,13,"sb","mut",1.6);
            var kp:TextField = this.hzT(p,"",0,0,60,12,"bd","col",0,"left");
            var kh:TextField = this.hzT(p,"",0,0,60,12,"bd","col",0,"left");
            var hh:TextField = this.hzT(p,"HOLD",0,0,60,11,"rg","mut",1.2);
            this.hzChip13(lp,"Hover");
            this.hzChip13(lh,"Hover");
            this.hzChip13(kp,"Hover");
            this.hzChip13(kh,"Hover");
            this.hzChip13(hh,"Hover");
            this.hzT19Btn.push({"kp":kp,"lp":lp,"hh":hh,"kh":kh,"lh":lh});
            i++;
         }
         p.visible = false;
      }

      private function hzT19Hide(d:DisplayObject) : void
      {
         this.hzTgHide(d);
      }

      // alpha-only hide (visible / input untouched); re-applied every frame because vanilla timelines reset clips
      private function hzT19HideA(d:DisplayObject) : void
      {
         if(!d) { return; }
         for each(var o:Object in this.hzTgHidden) { if(o.d == d && o.a != undefined) { if(d.alpha != 0) { d.alpha = 0; } return; } }
         this.hzTgHidden.push({"d":d,"v":d.visible,"a":d.alpha});
         d.alpha = 0;
      }

      // vanilla targeting ring: HUDRolloverWidget.Reticle_mc + the two leader-line Shapes RolloverReticle adds at index 0
      private function hzT19HideReticle(rw:Object) : void
      {
         try { this.hzT19HideA(rw.Reticle_mc as DisplayObject); } catch(e1:Error) { }
         try
         {
            var c:DisplayObjectContainer = rw as DisplayObjectContainer;
            var i:int = 0;
            while(c && i < c.numChildren)
            {
               var ch:DisplayObject = c.getChildAt(i);
               if(ch && !(ch is DisplayObjectContainer) && !(ch is TextField)) { this.hzT19HideA(ch); }
               i++;
            }
         }
         catch(e2:Error) { }
      }

      // undo hzT19HideReticle only (the activation widget stays hidden)
      private function hzT19ShowReticle(rw:Object) : void
      {
         var ds:Array = [];
         try { if(rw.Reticle_mc) { ds.push(rw.Reticle_mc); } } catch(e1:Error) { }
         try
         {
            var c:DisplayObjectContainer = rw as DisplayObjectContainer;
            var i:int = 0;
            while(c && i < c.numChildren)
            {
               var ch:DisplayObject = c.getChildAt(i);
               if(ch && !(ch is DisplayObjectContainer) && !(ch is TextField)) { ds.push(ch); }
               i++;
            }
         }
         catch(e2:Error) { }
         var k:int = this.hzTgHidden.length - 1;
         while(k >= 0)
         {
            var o:Object = this.hzTgHidden[k];
            if(o.a != undefined && ds.indexOf(o.d) >= 0)
            {
               try { DisplayObject(o.d).alpha = Number(o.a); } catch(e3:Error) { }
               this.hzTgHidden.splice(k,1);
            }
            k--;
         }
      }

      // ---- CROSSHAIR STYLE (interact reticle only) ----
      // CenterGroup_mc.ReticleBase_mc is the vanilla Crosshair (gotoAndStop(uType + 1)); on uType HCT_INTERACT (7) it shows
      // Player_Interaction_ReticleAnim_mc (~22 px ring). We alpha-hide that clip (re-applied every frame) and draw our own
      // glyph at the reticle's center in whole device pixels. Every other uType (weapons, command 8, none) is untouched.
      private static const HZ_HCT_INTERACT:int = 7;
      private static const HZ_XH_NAMES:Array = ["VANILLA","HORIZON DOT","HORIZON CROSS","NONE"];
      private static const HZ_RING_NAMES:Array = ["OFF","CONTAINERS ONLY","VANILLA"];

      private function hzXhRestore() : void
      {
         for each(var o:Object in this.hzXhHid)
         {
            try { DisplayObject(o.d).alpha = Number(o.a); } catch(err:Error) { }
         }
         this.hzXhHid = [];
      }

      private function hzXhTick() : void
      {
         var rb:Object = null;
         try { rb = this.CenterGroup_mc ? this.CenterGroup_mc.ReticleBase_mc : null; } catch(e1:Error) { rb = null; }
         var ia:DisplayObject = null;
         try { ia = rb ? rb.Player_Interaction_ReticleAnim_mc as DisplayObject : null; } catch(e2:Error) { ia = null; }
         // vanilla rule (Crosshair.onCrosshairDataChange): bEnabled && (!bIronSights || bIn3rdPerson || bIsToolGrip)
         var vrule:Boolean = this.hzCrossOn && (!this.hzCrossIron || this.hzCross3rd || this.hzCrossTool);
         var active:Boolean = this.hzXhStyle != 0 && !this.hzUserHidden && rb != null && ia != null && this.hzCrossType == HZ_HCT_INTERACT && vrule;
         var vis:Boolean = false;
         if(active)
         {
            try
            {
               var d:DisplayObject = rb as DisplayObject;
               vis = true;
               while(d != null && d != this) { if(!d.visible) { vis = false; break; } d = d.parent; }
            }
            catch(e3:Error) { vis = false; }
         }
         if(!active)
         {
            if(this.hzXhHid.length > 0) { this.hzXhRestore(); }
            if(this.hzXh) { this.hzXh.visible = false; }
            return;
         }
         // hide the vanilla interact ring (the timeline may hand us a fresh instance: track by object)
         var known:Boolean = false;
         for each(var o:Object in this.hzXhHid) { if(o.d == ia) { known = true; } }
         if(!known) { this.hzXhRestore(); this.hzXhHid.push({"d":ia,"a":ia.alpha}); }
         if(ia.alpha != 0) { ia.alpha = 0; }
         if(this.hzXhStyle == 3 || !vis) { if(this.hzXh) { this.hzXh.visible = false; } return; }
         if(!this.hzXh)
         {
            this.hzXh = new Sprite();
            this.hzXh.mouseEnabled = false;
            this.hzXh.mouseChildren = false;
            var at:int = -1;
            try { at = getChildIndex(this.CenterGroup_mc as DisplayObject) + 1; } catch(e4:Error) { at = -1; }
            if(at > 0 && at <= numChildren) { addChildAt(this.hzXh,at); } else { addChild(this.hzXh); }
         }
         // device pixel in stage units (ScreenHeight; 1080 assumed when 0) -> the glyph is drawn in device pixels
         var pu:Number = this.hzScrH >= 360 ? 1080 / this.hzScrH : 1;
         var gp:Point = (rb as DisplayObject).localToGlobal(new Point(0,0));
         var lp:Point = globalToLocal(gp);
         this.hzXh.scaleX = this.hzXh.scaleY = pu;
         this.hzXh.x = Math.round(lp.x / pu) * pu;
         this.hzXh.y = Math.round(lp.y / pu) * pu;
         var sig:String = this.hzXhStyle + "|" + pu + "|" + HZ_ACCENT;
         if(sig != this.hzXhSig) { this.hzXhSig = sig; this.hzXhDraw(pu); }
         this.hzXh.visible = true;
      }

      // original glyphs, whole device pixels around (0,0); dark 1 px halo for contrast on bright scenes
      private function hzXhDraw(pu:Number) : void
      {
         var g:* = this.hzXh.graphics;
         g.clear();
         var k:Number = 1 / pu;                       // device pixels per stage unit
         if(this.hzXhStyle == 1)
         {
            var r:Number = Math.max(2,Math.round(2.4 * k));
            g.beginFill(0x000000,0.45); g.drawCircle(0,0,r + 1); g.endFill();
            g.beginFill(0xF2F7F9,0.95); g.drawCircle(0,0,r); g.endFill();
            return;
         }
         // HORIZON CROSS: four ticks (gap, length, 2 px thick) + accent center dot
         var th:int = 2;
         var gap:int = Math.max(3,int(Math.round(4 * k)));
         var len:int = Math.max(4,int(Math.round(5 * k)));
         var arms:Array = [[gap,-1,len,th],[-gap - len,-1,len,th],[-1,gap,th,len],[-1,-gap - len,th,len]];
         for each(var a:Array in arms)
         {
            g.beginFill(0x000000,0.4); g.drawRect(a[0] - 1,a[1] - 1,a[2] + 2,a[3] + 2); g.endFill();
         }
         for each(var b:Array in arms)
         {
            g.beginFill(0xF2F7F9,0.95); g.drawRect(b[0],b[1],b[2],b[3]); g.endFill();
         }
         g.beginFill(0x000000,0.45); g.drawRect(-2,-2,4,4); g.endFill();
         g.beginFill(HZ_ACCENT,1); g.drawRect(-1,-1,2,2); g.endFill();
      }

      private function hzT19Off() : void
      {
         if(this.hzTgHidden.length > 0) { this.hzTgRestore(); }
         if(this.hzTg19) { this.hzTg19.visible = false; }
         this.HorizonTarget_mc.visible = false;
      }

      // quick fade of OUR tag when the crosshair leaves (vanilla stays hidden, so its roll-off never shows)
      private function hzT19FadeOut() : void
      {
         if(!this.HorizonTarget_mc.visible || !this.hzTg19 || !this.hzTg19.visible) { this.HorizonTarget_mc.visible = false; this.hzT19A = 0; return; }
         this.hzT19A -= 0.25;
         if(this.hzT19A <= 0)
         {
            this.hzT19A = 0;
            this.hzTg19.visible = false;
            this.HorizonTarget_mc.visible = false;
            this.hzT19Sig = "";
         }
         else { this.HorizonTarget_mc.alpha = this.hzT19A; }
      }

      // local units per device pixel inside the crosshair card (needs ScreenHeight; 0 = unknown)
      // device pixel in card units, or 1 unit when ScreenHeight snapping is off
      private function hzT19U() : Number
      {
         var dp:Number = this.hzT19Dp();
         return dp > 0.2 && dp < 4 ? dp : 1;
      }

      private function hzSnapU(v:Number, u:Number) : Number
      {
         return Math.round(v / u) * u;
      }

      // Keycap (v0.26). v0.25 drew the outline as ONE compound even-odd fill (outer round rect minus inner round rect).
      // Scaleform joins the two sub-paths where drawRoundRect starts them (the right edge, bottom corner), which left a
      // thin wedge / spur just after the cap. The ring is now 8 separate simple shapes (4 straight bars + 4 quarter
      // rings), each its own closed fill, opaque so the slight overlaps are invisible; every edge on the device grid u.
      //   g  = faint fill of the full box (behind the text)
      //   og = the outline, a layer ABOVE every text field of the window / tag
      private function hzKeycap(g:*, x:Number, y:Number, w:Number, h:Number, col:uint, u:Number, og:* = null) : void
      {
         var bt:Number = u < 1 ? 2 * u : u;
         var r:Number = Math.min(h,12) / 2;
         if(og == null) { og = g; }
         g.lineStyle();
         g.beginFill(col,0.12);
         g.drawRoundRect(x,y,w,h,r * 2,r * 2);
         g.endFill();
         og.lineStyle();
         var ri:Number = Math.max(0,r - bt);
         var ov:Number = Math.min(0.5,bt / 2);
         // straight bars, a touch into the corners
         og.beginFill(col,1); og.drawRect(x + r - ov,y,w - 2 * r + 2 * ov,bt); og.endFill();
         og.beginFill(col,1); og.drawRect(x + r - ov,y + h - bt,w - 2 * r + 2 * ov,bt); og.endFill();
         og.beginFill(col,1); og.drawRect(x,y + r - ov,bt,h - 2 * r + 2 * ov); og.endFill();
         og.beginFill(col,1); og.drawRect(x + w - bt,y + r - ov,bt,h - 2 * r + 2 * ov); og.endFill();
         // quarter rings (outer arc out, inner arc back), one closed contour each
         this.hzKeyCorner(og,x + r,y + r,r,ri,-1,-1,col);
         this.hzKeyCorner(og,x + w - r,y + r,r,ri,1,-1,col);
         this.hzKeyCorner(og,x + w - r,y + h - r,r,ri,1,1,col);
         this.hzKeyCorner(og,x + r,y + h - r,r,ri,-1,1,col);
      }

      private function hzKeyCorner(g:*, cx:Number, cy:Number, r:Number, ri:Number, sx:int, sy:int, col:uint) : void
      {
         var n:int = 6;
         var i:int = 0;
         g.beginFill(col,1);
         while(i <= n)
         {
            var an:Number = Math.PI / 2 * i / n;
            var px:Number = cx + sx * Math.cos(an) * r;
            var py:Number = cy + sy * Math.sin(an) * r;
            if(i == 0) { g.moveTo(px,py); } else { g.lineTo(px,py); }
            i++;
         }
         i = n;
         while(i >= 0)
         {
            var bn:Number = Math.PI / 2 * i / n;
            g.lineTo(cx + sx * Math.cos(bn) * ri,cy + sy * Math.sin(bn) * ri);
            i--;
         }
         g.lineTo(cx + sx * r,cy);
         g.endFill();
      }

      // v0.26: field top that puts the CAP-height center of a text on cy (real ascent from the line metrics;
      // fallback 0.8 x textHeight). TextField gutter = 2. Caps are ~0.72 em tall.
      private function hzCapTop(tf:TextField, cy:Number) : Number
      {
         var sz:Number = 12;
         try { sz = Number(tf.getTextFormat().size); } catch(errS:Error) { sz = 12; }
         if(isNaN(sz) || sz <= 0) { sz = 12; }
         var asc:Number = NaN;
         try { asc = tf.getLineMetrics(0).ascent; } catch(errM:Error) { asc = NaN; }
         if(isNaN(asc) || asc <= 0 || asc > sz * 2) { asc = tf.textHeight > 0 ? tf.textHeight * 0.8 : sz * 0.95; }
         return cy - 2 - asc + 0.36 * sz;
      }

      // registered text: logical top on the device grid su, kept through TextScale / typo-guard re-formatting
      private function hzTxtTopU(tf:TextField, top:Number, su:Number) : void
      {
         var o:Object = this.hzTxtObj(tf);
         if(su <= 0) { su = 1; }
         var t:Number = this.hzSnapU(top,su);
         if(!o) { tf.y = t; tf.x = this.hzSnapU(tf.x,su); return; }
         var fs:Number = Number(o.fs != undefined ? o.fs : o.size);
         var sz:Number = this.hzTextSz19(o,fs);
         o.su = su;
         o.y0 = t + (sz - fs) / 2;
         tf.y = t;
         tf.x = this.hzSnapU(tf.x,su);
      }

      // vertical accent stripe on the left edge (equipment card variant B geometry: x 0-4, 16 from top / bottom)
      private function hzAccStripe(g:*, H:Number, col:uint) : void
      {
         if(H < 40) { return; }
         g.beginFill(this.hzIconCol(col),1);
         g.drawRoundRect(0,16,4,H - 32,4,4);
         g.endFill();
      }

      // keycap outline layer of the crosshair tag: kept as the top child of the tag (above every text field)
      private var hzT19Kov:Sprite = null;
      private function hzT19KeyOv() : *
      {
         if(!this.hzTg19) { return null; }
         if(!this.hzT19Kov) { this.hzT19Kov = new Sprite(); this.hzT19Kov.mouseEnabled = false; }
         if(this.hzT19Kov.parent != this.hzTg19 || this.hzTg19.getChildIndex(this.hzT19Kov) != this.hzTg19.numChildren - 1) { this.hzTg19.addChild(this.hzT19Kov); }
         return this.hzT19Kov.graphics;
      }

      private function hzT19Dp() : Number
      {
         var sc:Number = HZ_SCALE * this.hz30TgSc;   // v0.30: the scale of the card kind on screen (ContainerScale / HoverScale)
         if(this.hzScrH < 360 || sc <= 0) { return 0; }
         return 1080 / this.hzScrH / sc;
      }

      // vanilla button clip for an aButtons iType (HUDRolloverActivationWidget: A/X top bar, Y/B bottom bar)
      private function hzT19BtnClip(aw:Object, t:int) : Object
      {
         try
         {
            var bars:Object = aw.ButtonBars_mc;
            if(t == 0) { return bars.TopButtonBar_mc.Button2_mc; }
            if(t == 1) { return bars.TopButtonBar_mc.Button1_mc; }
            if(t == 2) { return bars.BottomButtonBar_mc.Button2_mc; }
            if(t == 3) { return bars.BottomButtonBar_mc.Button1_mc; }
         }
         catch(err:Error) { }
         return null;
      }

      // the vanilla label text after the game translated it: MinimalButton.Label_mc.LabelInstance_mc.Label_tf (or Label_mc.Label_tf);
      // hold: ReleaseHoldComboButton.HoldLabel_mc.LabelInstance_mc.Label_tf
      private function hzT19VanLbl(aw:Object, t:int, hold:Boolean) : String
      {
         var btn:Object = this.hzT19BtnClip(aw,t);
         var r:String = "";
         if(!btn) { return r; }
         try
         {
            if(hold) { r = String(btn.HoldLabel_mc.LabelInstance_mc.Label_tf.text); }
            else
            {
               var lm:Object = btn.Label_mc;
               if(lm && lm.LabelInstance_mc && lm.LabelInstance_mc.Label_tf) { r = String(lm.LabelInstance_mc.Label_tf.text); }
               else if(lm && lm.Label_tf) { r = String(lm.Label_tf.text); }
            }
         }
         catch(err:Error) { r = ""; }
         return r == null || r == "null" ? "" : r;
      }

      // "$Key" strings: let a TextField translate them (as vanilla GlobalFunc.SetText does); anything still holding "$" is dropped
      private function hzT19Xl(raw:String) : String
      {
         if(raw == null) { return ""; }
         if(raw.indexOf("$") < 0) { return raw; }
         var r:String = "";
         try
         {
            if(!this.hzXlTf) { this.hzXlTf = new TextField(); }
            this.hzXlTf.text = raw;
            r = this.hzXlTf.text;
         }
         catch(err:Error) { r = ""; }
         if(r == null || r.indexOf("$") >= 0) { return ""; }
         return r;
      }

      // button label: aButtons text, or the translated vanilla label when the text is a $ key; never shows a "$" string
      private function hzT19Label(aw:Object, t:int, hold:Boolean, raw:*) : String
      {
         var s:String = this.hzT19Trim(raw);
         if(s.length == 0) { return ""; }
         if(s.indexOf("$") < 0) { return s; }
         var v:String = this.hzT19Trim(this.hzT19VanLbl(aw,t,hold));
         if(v.length > 0 && v.indexOf("$") < 0) { return v; }
         return this.hzT19Trim(this.hzT19Xl(s));
      }

      private function hzT19Trim(s:*) : String
      {
         if(s == undefined || s === null) { return ""; }
         var t:String = String(s);
         while(t.length > 0 && (t.charAt(0) == "\n" || t.charAt(0) == "\r" || t.charAt(0) == " ")) { t = t.substr(1); }
         while(t.length > 0 && (t.charAt(t.length - 1) == "\n" || t.charAt(t.length - 1) == " ")) { t = t.substr(0,t.length - 1); }
         return t;
      }

      // key label for aButtons[].iType (0 A, 1 X, 2 Y, 3 B): the game's own PC key text (PCButton_mc.ButtonInstance_mc.PCButton_tf)
      private function hzT19Key(aw:Object, t:int) : String
      {
         var btn:Object = this.hzT19BtnClip(aw,t);
         var k:String = "";
         var pad:Boolean = false;
         try { var pc:Object = btn.PCButton_mc.ButtonInstance_mc; if(pc && pc.visible) { k = this.hzT19Trim(pc.PCButton_tf.text); } } catch(e2:Error) { }
         try { var cb:Object = btn.ConsoleButton_mc.ButtonInstance_mc; if(cb && cb.visible) { pad = true; } } catch(e3:Error) { }
         if(k.length == 0 || pad) { k = t >= 0 && t < 4 ? ["A","X","Y","B"][t] : "?"; }
         if(k.length > 8) { k = k.substr(0,8); }
         return k.toUpperCase();
      }

      // Keycap box for the hover TAKE row: at least 24, and tall enough for the floored E / HOLD type.
      private function hzT19CapH() : Number
      {
         var u:Number = this.hzT19U();
         var keySz:int = this.hzChipSzOn(12,"Hover",13);
         var holdSz:int = this.hzChipSzOn(11,"Hover",13);
         return this.hzSnapU(Math.max(24,Math.max(keySz,holdSz) + 10),u);
      }

      // our keycap action row from aButtons (sTextPressAndRelease / sTextHold / bVisible / bEnabled / iType).
      // g == null only measures. Returns the row width.
      private function hzT19Buttons(g:*, a:Object, aw:Object, x0:Number, y:Number, col:uint) : Number
      {
         var x:Number = x0;
         var used:int = 0;
         var list:Array = (a && a.aButtons is Array) ? a.aButtons as Array : [];
         var dk:Boolean = this.hzDarkText();
         var c:uint = this.hzIconCol(col);
         for each(var b:Object in list)
         {
            if(used >= this.hzT19Btn.length) { break; }
            if(!b || b.bVisible === false) { continue; }
            var t:int = b.iType != undefined ? int(b.iType) : -1;
            if(t < 0) { continue; }
            var press:String = b.bPressAndRelease === false ? "" : this.hzT19Label(aw,t,false,b.sTextPressAndRelease);
            var hold:String = b.bPressAndHold === false ? "" : this.hzT19Label(aw,t,true,b.sTextHold);
            if(press.length == 0 && hold.length == 0) { continue; }
            var on:Boolean = b.bEnabled !== false;
            var key:String = this.hzT19Key(aw,t);
            var slot:Object = this.hzT19Btn[used];
            // v0.26: caps 24 units tall (was 20); key glyph + labels centered on the cap by their real ascent
            var u:Number = this.hzT19U();
            var ky:Number = this.hzSnapU(y,u);
            var kh:Number = this.hzT19CapH();
            var kcy:Number = ky + kh / 2;
            used++;
            if(x > x0) { x += 16; }
            var pairs:Array = [];
            if(press.length > 0) { pairs.push([false,press]); }
            if(hold.length > 0) { pairs.push([true,hold]); }
            for each(var pr:Array in pairs)
            {
               var isHold:Boolean = Boolean(pr[0]);
               var kt:TextField = TextField(isHold ? slot.kh : slot.kp);
               var lt:TextField = TextField(isHold ? slot.lh : slot.lp);
               var loTk:Object = this.hzTxtObj(lt); if(loTk && loTk.chipMin) { this.hzApplyFmt(loTk); }
               var koTk:Object = this.hzTxtObj(kt); if(koTk && koTk.chipMin) { this.hzApplyFmt(koTk); }
               if(isHold)
               {
                  if(pairs.length > 1) { x += 14; }
                  var ht:TextField = TextField(slot.hh);
                  var hoTk:Object = this.hzTxtObj(ht); if(hoTk && hoTk.chipMin) { this.hzApplyFmt(hoTk); }
                  ht.visible = g != null;
                  ht.x = this.hzSnapU(x,u); this.hzTxtTopU(ht,this.hzCapTop(ht,kcy),u);
                  x += this.hzTW(ht) + 6;
               }
               var kc:uint = isHold || !on ? this.hzMix(c,this.hzPanelFill(),0.45) : c;
               this.hzTxtTint(kt,kc);
               kt.text = key;
               // v0.24: keycap box lives on the DEVICE-pixel grid (1 unit = 1.5 px at 1440p x TargetScale 1.125),
               // so both edges of every keycap land on whole pixels; width padded so the glyph never nears the border
               var kw:Number = this.hzSnapU(Math.max(26,this.hzTW(kt) + 16),u);
               x = this.hzSnapU(x,u);
               if(g != null) { this.hzKeycap(g,x,ky,kw,kh,kc,u,this.hzT19KeyOv()); }
               kt.visible = g != null;
               kt.width = Math.round(this.hzTW(kt) + 5);   // key field inside the cap (never reaches past its right edge)
               kt.x = this.hzSnapU(x + (kw - this.hzTW(kt)) / 2 - 2,u);
               this.hzTxtTopU(kt,this.hzCapTop(kt,kcy),u);
               x += kw + 7;
               this.hzTxtTint(lt,isHold || !on ? 0xA8B6BE : (col == HZ_ACCENT ? null : col));
               lt.text = isHold ? hold.toUpperCase() : press.toUpperCase();
               lt.visible = g != null;
               lt.x = this.hzSnapU(x,u); this.hzTxtTopU(lt,this.hzCapTop(lt,kcy),u);
               x += this.hzTW(lt);
            }
         }
         return x - x0;
      }

      private function hzT19Tick() : void
      {
         if(this.hzTgOld) { this.hzTgOld.visible = false; }
         if(!this.hzTg19) { this.hzT19Off(); return; }
         var aw:Object = null;
         var rw:Object = null;
         try { rw = this.RolloverWidget_mc; aw = rw ? rw.RolloverActivation_mc : null; } catch(err:Error) { aw = null; }
         var a:Object = this.hzTgAct;
         var show:Boolean = a != null && Boolean(a.bShowRolloverActivation) && aw != null && rw != null && Boolean(rw.visible);
         var m:int = show ? int(a.uMode) : -1;
         var base:Boolean = this.hzShowTarget && this.hzGroupVisible && !this.hzUserHidden && !this.hzArrange;
         // hostile = the crosshair target is in HudEnemyData.EnemiesA with fHealth and bOnScreen (same rule as v0.20),
         // except while the crosshair is HCT_COMMAND (giving an order is never a hostile tag)
         var foe:Boolean = this.hzTgHpV >= 0 && this.hzTgOnScr && this.hzCrossType != HZ_HCT_COMMAND;
         var hdr:DisplayObject = null;
         var cl:Object = null;
         if(show)
         {
            try { hdr = aw.Header_mc as DisplayObject; } catch(e1:Error) { }
            try { cl = aw.ContainerList_mc; } catch(e5:Error) { cl = null; }
         }
         var kind:String = "";
         if(base && show && hdr != null && aw is DisplayObject)
         {
            if(m == 4) { kind = (cl != null && this.hzTgItems != null && this.hzTgItems.length > 0) ? "list" : "prompt"; }
            else if(m == 2) { kind = a.ItemData != null ? "cmp" : "item"; }
            else if(m == 1) { kind = "item"; }
            else if(m == 0) { kind = foe ? "foe" : "prompt"; }   // v0.39: a person gets the plain prompt card like any object
         }
         else if(base && !show && foe && !this.hz26EnemyTakes()) { kind = "foe"; }   // v0.26: the top enemy bar replaces the plain foe tag
         // v0.38: the vanilla rollover (holder + activation widget + ring + leader line) is hidden ONLY while Horizon's
         // card is on screen (drawn this frame without an error, or still fading out). v0.37 hid it whenever ShowTarget
         // was on, so any prompt Horizon did not draw (kind "", a draw error, an unexpected uMode) left the player with
         // no prompt at all - the "could not select anyone for a minute" report. Scanner modes (3, 5) and the user
         // toggle hand it back to vanilla as before.
         var lastMode:int = a != null && a.uMode != undefined ? int(a.uMode) : -1;
         var scan:Boolean = lastMode == 3 || lastMode == 5;
         var mine:Boolean = this.hzShowTarget && !this.hzUserHidden && !scan && rw != null && aw != null;
         var prompt:Boolean = show && m != 3 && m != 5;
         if(!mine && this.hzTgHidden.length > 0) { this.hzTgRestore(); }
         if(kind == "")
         {
            this.hzT19FadeOut();
            if(mine) { this.hz38Vanilla(rw,aw,kind,prompt,Boolean(this.HorizonTarget_mc.visible)); }
            return;
         }
         this.hzT19A = 1;
         // v0.30: ContainerScale = the full container list; HoverScale = prompt / item / compare / foe hover cards
         this.hz30TgSc = kind == "list" ? this.hz34Eff(this.hzTgScale) : this.hz34Eff(this.hz30Hover);   // v0.34: -1 = HudScale
         var s:Number = HZ_SCALE * this.hz30TgSc;   // independent of HudScale
         this.HorizonTarget_mc.scaleX = this.HorizonTarget_mc.scaleY = s;
         var sel:int = -1;
         var start:int = 0;
         var items:Array = this.hzTgItems;
         if(kind == "list")
         {
            var se:Object = null;
            try { se = cl.selectedEntry; } catch(e7:Error) { se = null; }
            if(se != null)
            {
               sel = items.indexOf(se);
               if(sel < 0)
               {
                  var ii:int = 0;
                  while(ii < items.length) { var it:Object = items[ii]; if(it && it.sName == se.sName && it.uCount == se.uCount && it.uRarity == se.uRarity) { sel = ii; break; } ii++; }
               }
            }
            if(sel < 0) { try { sel = int(cl.selectedIndex); } catch(e8:Error) { sel = -1; } }
            if(sel >= items.length) { sel = -1; }
            start = Math.max(0,Math.min(items.length - 5,(sel < 0 ? 0 : sel) - 2));
         }
         if(kind == "foe")
         {
            var hp:Number = Math.max(0,Math.min(1,this.hzTgHpV));
            if(this.hzTgGhost < hp || this.hzT19LastHp < 0) { this.hzTgGhost = hp; }
            if(hp < this.hzT19LastHp - 0.0005) { this.hzTgGhostHold = 24; }
            this.hzT19LastHp = hp;
            if(this.hzTgGhostHold > 0) { this.hzTgGhostHold--; }
            else if(this.hzTgGhost > hp) { this.hzTgGhost = Math.max(hp,this.hzTgGhost - 0.012); }
         }
         else { this.hzT19LastHp = -1; this.hzTgGhost = -1; }
         // the key text can change (rebinding / controller): include it in the signature
         var keys:String = "";
         if(show) { var kk:int = 0; while(kk < 4) { keys += this.hzT19Key(aw,kk) + ":" + this.hzT19VanLbl(aw,kk,false) + ":" + this.hzT19VanLbl(aw,kk,true) + ","; kk++; } }
         var sig:String = kind + "|" + m + "|" + sel + "|" + start + "|" + this.hzT19Ver + "|" + Math.round(this.hzTgGhost * 200) + "|" + this.hzTextScale + "|" + this.hzCardColor + "|" + this.hzContOpacity + "|" + HZ_ACCENT + "|" + this.hzTextTone + "|" + this.hzTgShowValue + "|" + this.hzFontFace + "|" + keys + "|" + show + "|" + this.hzTgScale + "|" + this.hz30Hover + "|" + this.hzScrH;
         if(sig != this.hzT19Sig)
         {
            this.hzT19Sig = sig;
            // ContainerOpacity drives the panel alpha of the crosshair cards only (HUD cards keep CardOpacity)
            var opSave:Number = this.hzCardOpacity;
            this.hzCardOpacity = this.hzContOpacity;
            this.hz38DrawOk = false;
            try { this.hzT19Content(kind,show ? a : null,aw,sel,start); this.hz38DrawOk = true; }
            catch(eOp:Error)
            {
               // v0.38: v0.37 swallowed this with the signature already stored, so the card never redrew and the prompt
               // stayed hidden. Now the vanilla prompt shows and the draw is retried.
               this.hz38DrawErr++;
               if(this.hz38DrawErr <= 30) { this.hzT19Sig = ""; }
            }
            this.hzCardOpacity = opSave;
         }
         var W:Number = this.hzT19W;
         var H:Number = this.hzT19H;
         // anchor: the crosshair (RolloverWidget_mc is locked to the safe-rect center); TargetAnchor=1 follows the object
         var sx:Number = rw ? Number(rw.x) : 960;
         var sy:Number = rw ? Number(rw.y) : 540;
         if(this.hzTgAnchor == 1 && !isNaN(this.hzTgSX)) { sx = this.hzTgSX; sy = this.hzTgSY; }
         if(isNaN(sx) || isNaN(sy)) { sx = 960; sy = 540; }
         var x:Number = sx + 26 * s;
         var y:Number = sy + 26 * s;
         var vr:Rectangle = this.hzVis();
         if(vr)
         {
            x = Math.max(vr.x + 8,Math.min(vr.x + vr.width - W * s - 8,x));
            y = Math.max(vr.y + 8,Math.min(vr.y + vr.height - H * s - 8,y));
         }
         // v0.38: keep the card clear of the game's object ring (ObjectRing CONTAINERS ONLY / VANILLA)
         var ry:Number = NaN;
         try { ry = this.hz38RingClear(rw,kind,x,y,W * s,H * s,vr); } catch(eRc:Error) { ry = NaN; }
         if(!isNaN(ry)) { y = ry; }
         // whole device pixels: stage units per pixel = 1080 / ScreenHeight (0.75 at 1440p)
         var pu:Number = this.hzScrH >= 360 ? 1080 / this.hzScrH : 1;
         this.HorizonTarget_mc.x = Math.round(x / pu) * pu;
         this.HorizonTarget_mc.y = Math.round(y / pu) * pu;
         var okCard:Boolean = this.hz38DrawOk && W > 20 && H > 20;
         this.HorizonTarget_mc.alpha = 1;
         this.hzTg19.visible = okCard;
         this.HorizonTarget_mc.visible = okCard;
         if(mine) { this.hz38Vanilla(rw,aw,kind,prompt,okCard); }
      }
      // v0.38: apply hz38VanillaRule; a prompt with no Horizon card gets the game's widget back the same frame
      private function hz38Vanilla(rw:Object, aw:Object, kind:String, prompt:Boolean, card:Boolean) : void
      {
         if(this.hz38VanillaRule(true,prompt,card) == "hide") { this.hz38HideVanilla(rw,aw,kind); this.hz38VanShown = false; return; }
         this.hz38VanShown = true;
         if(this.hzTgHidden.length > 0) { this.hzTgRestore(); }
         // an alpha captured mid roll-on can be 0: a live prompt must be visible
         try
         {
            var hd:DisplayObject = rw.RolloverActivationHolder_mc as DisplayObject;
            var ad:DisplayObject = aw as DisplayObject;
            if(hd && hd.alpha < 0.05) { hd.alpha = 1; }
            if(ad && ad.alpha < 0.05) { ad.alpha = 1; }
         }
         catch(eV:Error) { }
      }

      // round icon tile with a neutral activation glyph (the prompt card for people and objects)
      private function hzT19Tile(g:*, cx:Number, cy:Number, col:uint) : void
      {
         var c:uint = this.hzIconCol(col);
         this.hzTileDisc(g,cx,cy,23,col,0.67);
         g.lineStyle(1,c,0.35,true); g.drawCircle(cx,cy,23); g.lineStyle();
         g.lineStyle(1.6,c,0.9,true); g.drawCircle(cx,cy,7); g.lineStyle();
         g.beginFill(c,1); g.drawCircle(cx,cy,2.6); g.endFill();
      }

      // the player's CHARACTER card icon: round tile with an original vector bust
      private function hz26Bust(g:*, cx:Number, cy:Number, col:uint) : void
      {
         var c:uint = this.hzIconCol(col);
         var dk:Boolean = this.hzDarkText();
         var tile:uint = dk ? this.hzMix(this.hzPanelFill(),0x000000,0.14) : 0x060A0E;
         this.hzTileDisc(g,cx,cy,23,col,0.67);
         g.lineStyle(1,c,0.35,true); g.drawCircle(cx,cy,23); g.lineStyle();
         var k:Number = 0.95;
         var by:Number = cy + 1;
         g.beginFill(c,1); g.drawCircle(cx,by - 7 * k,6 * k); g.endFill();
         // shoulders: upper half of a 12-radius circle centered 13 below the neck
         var sy:Number = by + 13 * k;
         var r:Number = 12 * k;
         g.beginFill(c,1);
         g.moveTo(cx - r,sy);
         var i:int = 1;
         while(i <= 24) { var an:Number = Math.PI + Math.PI * i / 24; g.lineTo(cx + Math.cos(an) * r,sy + Math.sin(an) * r); i++; }
         g.lineTo(cx - r,sy);
         g.endFill();
         g.beginFill(tile,1);
         g.moveTo(cx - 3.2 * k,by + 1.6 * k); g.lineTo(cx + 3.2 * k,by + 1.6 * k); g.lineTo(cx,by + 6.5 * k); g.lineTo(cx - 3.2 * k,by + 1.6 * k);
         g.endFill();
      }

      private function hzT19Star(g:*, cx:Number, cy:Number, col:uint) : void
      {
         g.beginFill(col,1);
         var k:int = 0;
         while(k <= 10)
         {
            var rr:Number = k % 2 == 0 ? 5.5 : 2.5;
            var an:Number = -Math.PI / 2 + k * Math.PI / 5;
            if(k == 0) { g.moveTo(cx + Math.cos(an) * rr,cy + Math.sin(an) * rr); }
            else { g.lineTo(cx + Math.cos(an) * rr,cy + Math.sin(an) * rr); }
            k++;
         }
         g.endFill();
      }

      private function hzT19Num(v:*) : Number
      {
         if(v == undefined || v === null) { return NaN; }
         var n:Number = Number(v);
         return isNaN(n) ? NaN : n;
      }

      // v0.42.0 r3: item type bits of iFilterFlag (the game's InventoryItemUtils order: new 1, weapons 2, ammo 4, spacesuits 8,
      // backpacks 16, helmets 32, apparel 64)
      private static const HZ42_ICF_WEAPONS:int = 2;
      private static const HZ42_ICF_ARMOR:int = 8 | 16 | 32 | 64;
      // compare rows from ItemData / CompareItemData (InvItemCard fields)
      private function hzT19CmpRows(it:Object, cmp:Object) : Array
      {
         var r:Array = [];
         var wi:Object = it.WeaponInfo;
         var ai:Object = it.ArmorInfo;
         var cw:Object = cmp ? cmp.WeaponInfo : null;
         var ca:Object = cmp ? cmp.ArmorInfo : null;
         // v0.42.0 r3: the item type decides (iFilterFlag, as the game's item card), not the presence of WeaponInfo / ArmorInfo
         var ff:Number = it.iFilterFlag != undefined && it.iFilterFlag !== null ? Number(it.iFilterFlag) : NaN;
         var isW:Boolean = isNaN(ff) ? Boolean(wi) : (int(ff) & HZ42_ICF_WEAPONS) != 0;
         var isA:Boolean = isNaN(ff) ? Boolean(ai) : (int(ff) & HZ42_ICF_ARMOR) != 0;
         if(wi && isW)
         {
            var dmg:Number = NaN;
            var cd:Number = NaN;
            if(it.aElementalStats is Array) { dmg = 0; for each(var es:Object in it.aElementalStats) { if(es && !isNaN(Number(es.fValue))) { dmg += Number(es.fValue); } } }
            if(cmp && cmp.aElementalStats is Array) { cd = 0; for each(var cs:Object in cmp.aElementalStats) { if(cs && !isNaN(Number(cs.fValue))) { cd += Number(cs.fValue); } } }
            r.push({"l":"DAMAGE","v":dmg,"c":cw ? cd : NaN,"dec":0,"low":false});
            r.push({"l":"RATE OF FIRE","v":this.hzT19Num(wi.fRateOfFire),"c":cw ? this.hzT19Num(cw.fRateOfFire) : NaN,"dec":0,"low":false});
            r.push({"l":"RANGE","v":this.hzT19Num(wi.fRange),"c":cw ? this.hzT19Num(cw.fRange) : NaN,"dec":0,"low":false});
            r.push({"l":"ACCURACY","v":this.hzT19Num(wi.fAccuracy),"c":cw ? this.hzT19Num(cw.fAccuracy) : NaN,"dec":1,"low":false,"pct":true});
         }
         else if(ai && isA)
         {
            for each(var ak:Array in [["THERMAL","fThermalResist"],["AIRBORNE","fAirborneResist"],["CORROSIVE","fCorrosiveResist"],["RADIATION","fRadiationResist"]])
            {
               r.push({"l":String(ak[0]),"v":this.hzT19Num(ai[ak[1]]),"c":ca ? this.hzT19Num(ca[ak[1]]) : NaN,"dec":0,"low":false});
            }
         }
         var pr:int = it.uWeightPrecision != undefined ? Math.max(0,Math.min(3,int(it.uWeightPrecision))) : 1;
         r.push({"l":"MASS","v":this.hzT19Num(it.fWeight),"c":cmp ? this.hzT19Num(cmp.fWeight) : NaN,"dec":pr,"low":true});
         r.push({"l":"VALUE","v":this.hzT19Num(it.uValue),"c":cmp ? this.hzT19Num(cmp.uValue) : NaN,"dec":0,"low":false,"int":true});
         var out:Array = [];
         for each(var o:Object in r) { if(!isNaN(Number(o.v))) { out.push(o); } }
         return out.slice(0,6);
      }

      private function hzT19Fmt(v:Number, dec:int, isInt:Boolean) : String
      {
         if(isInt) { return this.hzFmtInt(v); }
         return dec > 0 ? v.toFixed(dec) : String(Math.round(v));
      }

      private function hzT19Face(tf:TextField, face:String) : void
      {
         var o:Object = this.hzTxtObj(tf);
         if(o && o.face != face) { o.face = face; this.hzApplyFmt(o); }
      }

      private function hzT19Line(g:*, y:Number, W:Number, red:Boolean) : void
      {
         var dk:Boolean = this.hzDarkText();
         if(red) { g.lineStyle(1,this.hzIconCol(HZ_RED),0.36,true,"none"); }
         else { g.lineStyle(1,dk ? 0x000000 : 0xFFFFFF,dk ? 0.18 : 0.13,true,"none"); }
         g.moveTo(14,Math.round(y) + 0.5); g.lineTo(W - 14,Math.round(y) + 0.5);
         g.lineStyle();
      }

      private function hzT19Content(kind:String, a:Object, aw:Object, sel:int, start:int) : void
      {
         if(this.hzT19Kov) { this.hzT19Kov.graphics.clear(); }
         var g:* = this.hzT19G.graphics;
         g.clear();
         var dk:Boolean = this.hzDarkText();
         var steal:Boolean = a != null && Boolean(a.bStealing);
         var red:Boolean = kind == "foe" || steal;
         var tint:int = red ? int(dk ? this.hzMix(this.hzPanelFill(),HZ_RED,0.14) : 0x1A0B0E) : -1;
         var edge:int = red ? int(this.hzIconCol(HZ_RED)) : -1;
         var acol:uint = steal ? HZ_RED : HZ_ACCENT;
         var W:Number = 300;
         var H:Number = 60;
         var i:int = 0;
         for each(var tf:TextField in [this.hzT19Name,this.hzT19Meta,this.hzT19Ch1,this.hzT19Ch2,this.hzT19Ch3,this.hzT19HdrR,this.hzT19Foot,this.hzT19FootR]) { tf.visible = false; }
         for each(var ro:Object in this.hzT19Rows) { ro.n.visible = false; ro.c.visible = false; ro.t.visible = false; }
         for each(var co:Object in this.hzT19Cmp) { co.l.visible = false; co.v.visible = false; co.d.visible = false; }
         for each(var bo:Object in this.hzT19Btn) { bo.kp.visible = false; bo.lp.visible = false; bo.hh.visible = false; bo.kh.visible = false; bo.lh.visible = false; }
         var nmTf:TextField = this.hzT19Name;
         var o:Object = this.hzTxtObj(nmTf);
         var hdrTxt:String = a && a.sHeaderText != null ? this.hzT19Xl(String(a.sHeaderText)) : "";
         var rar:int = a && a.uRarity != undefined ? int(a.uRarity) : 0;
         var bw:Number = a ? this.hzT19Buttons(null,a,aw,0,0,acol) : 0;
         var hasBtn:Boolean = bw > 0;
         if(kind == "prompt")
         {
            // v0.39 plain prompt card - people and objects alike: icon tile on top, the name (the game's header text)
            // centered below it, then the game's keycaps (TALK, OPEN, ...) centered. The v0.38 centered layout stays: the
            // title starts below the tile, so the two can never overlap.
            var PX:Number = HZ38_PR_PAD;
            var fbw:Number = bw;
            o.center = true; o.right = false; o.ls = 2; o.fs = 16;
            this.hzTxtTint(nmTf,null);
            this.hzApplyFmt(o);
            nmTf.text = this.hzUC(hdrTxt);
            var nmW:Number = hdrTxt.length > 0 ? this.hzTW(nmTf) : 0;
            W = this.hz38PromptW(fbw,nmW);
            var cw:Number = W - 2 * PX;
            var L38:Object = this.hz38PromptY();
            var dvY:Number = Number(L38.dv);
            H = hasBtn ? dvY + 8 + this.hzT19CapH() + 18 : dvY + 6;
            this.hzPanel(g,W,H,18,-1,-1);
            g.beginFill(this.hzIconCol(HZ_ACCENT),1); g.drawRoundRect(0,16,4,H - 32,4,4); g.endFill();
            this.hzT19Tile(g,Math.round(W / 2),Number(L38.icy),HZ_ACCENT);
            nmTf.visible = hdrTxt.length > 0;
            nmTf.x = PX; nmTf.width = cw;
            this.hzApplyFmt(o);
            this.hzFitText(nmTf,this.hzUC(hdrTxt),cw);
            this.hzTxtTop(nmTf,Number(L38.nt));
            if(hasBtn)
            {
               g.lineStyle(1,dk ? 0x000000 : 0xFFFFFF,dk ? 0.18 : 0.13,true,"none");
               g.moveTo(PX,dvY + 0.5); g.lineTo(W - PX,dvY + 0.5);
               g.lineStyle();
               this.hzT19Buttons(g,a,aw,Math.round((W - fbw) / 2),dvY + 8,HZ_ACCENT);
            }
         }
         else if(kind == "foe")
         {
            W = Math.max(300,Math.round(bw + 40));
            o.center = true; o.right = false; o.ls = 2.4; o.fs = 16;
            nmTf.visible = true;
            nmTf.x = 20; nmTf.width = W - 40;
            var en:String = this.hzTgEnName.length > 0 ? this.hzTgEnName : hdrTxt;
            var stars:int = this.hzTgRank > 0 ? Math.min(3,this.hzTgRank) : (this.hzTgLeg ? 1 : 0);
            this.hzTxtTint(nmTf,0xFF8A8A);
            this.hzApplyFmt(o);
            this.hzFitText(nmTf,this.hzUC(en),W - 40);
            this.hzTxtTop(nmTf,11);
            var by:Number = stars > 0 ? 48 : 40;
            H = by + 7 + 15 + (hasBtn ? this.hzT19CapH() + 10 : 0);
            this.hzPanel(g,W,H,18,tint,edge);
            i = 0;
            while(i < stars) { this.hzT19Star(g,W / 2 + (i - (stars - 1) / 2) * 15,36,this.hzIconCol(0xF2C14E)); i++; }
            var f:Number = Math.max(0,Math.min(1,this.hzTgHpV));
            var gh:Number = Math.max(f,this.hzTgGhost);
            var hw:Number = W - 40;
            var rc:uint = this.hzIconCol(HZ_RED);
            g.beginFill(dk ? 0x000000 : 0xFFFFFF,dk ? 0.14 : 0.12); g.drawRoundRect(20,by,hw,7,7,7); g.endFill();
            if(gh > f + 0.002) { g.beginFill(rc,0.37); g.drawRoundRect(20,by,Math.max(7,hw * gh),7,7,7); g.endFill(); }
            if(f > 0) { g.beginFill(rc,1); g.drawRoundRect(20,by,Math.max(7,hw * f),7,7,7); g.endFill(); }
            if(hasBtn)
            {
               this.hzT19Line(g,by + 16,W,true);
               this.hzT19Buttons(g,a,aw,Math.round((W - bw) / 2),by + 24,HZ_RED);
            }
         }
         else if(kind == "item" || kind == "cmp")
         {
            var it:Object = kind == "cmp" ? a.ItemData : null;
            var cmp:Object = (kind == "cmp" && a.bShouldCompareItems) ? a.CompareItemData : null;
            if(it && it.uRarity != undefined) { rar = int(it.uRarity); }
            var nm:String = it && it.sName != null ? this.hzT19Xl(String(it.sName)) : hdrTxt;
            W = Math.max(kind == "cmp" ? 330 : 300,Math.round(bw + 36));
            o.center = false; o.right = false; o.ls = 2; o.fs = 16;
            nmTf.visible = true;
            nmTf.x = 18; nmTf.width = W - 32;
            this.hzTxtTint(nmTf,rar > 0 ? uint(HZ_RAR[Math.min(4,rar)]) : null);
            this.hzApplyFmt(o);
            this.hzFitText(nmTf,this.hzUC(nm),W - 32);
            this.hzTxtTop(nmTf,11);
            var contra:Boolean = Boolean(a.bContraband);
            var meta:Array = [];
            if(this.hzTgShowValue && kind == "item")
            {
               var val:Number = Number(a.iSingleItemValue);
               var wt:Number = Number(a.fSingleItemWeight);
               var pr:int = a.uWeightPrecision != undefined ? Math.max(0,Math.min(3,int(a.uWeightPrecision))) : 1;
               if(!isNaN(val) && val > 0) { meta.push(this.hzFmtInt(val) + " CR"); }
               if(!isNaN(wt) && wt > 0) { meta.push(wt.toFixed(pr) + " KG"); }
            }
            var anyChip:Boolean = (rar > 0 && rar < HZ_RARN.length) || steal || contra;
            var vsEq:Boolean = kind == "cmp" && cmp != null;
            var head:Number = (anyChip || meta.length > 0 || vsEq) ? 58 : 40;
            var rows:Array = kind == "cmp" ? this.hzT19CmpRows(it,cmp) : [];
            var rowsY:Number = head + 9;
            var bodyEnd:Number = kind == "cmp" ? rowsY + rows.length * 24 : head;
            H = hasBtn ? bodyEnd + 12 + this.hzT19CapH() + 14 : bodyEnd + (kind == "cmp" ? 6 : 0);
            this.hzPanel(g,W,H,18,tint,edge);
            // v0.25: left accent stripe like the equipment card (red while stealing; rarity stays on its chip)
            this.hzAccStripe(g,H,steal ? HZ_RED : HZ_ACCENT);
            var cx:Number = 18;
            if(rar > 0 && rar < HZ_RARN.length) { cx += this.hzChip(g,this.hzT19Ch1,cx,36,String(HZ_RARN[rar]),uint(HZ_RAR[rar]),false) + 6; }
            if(steal) { cx += this.hzChip(g,this.hzT19Ch2,cx,36,"STEAL",HZ_RED,true) + 6; }
            if(contra) { cx += this.hzChip(g,this.hzT19Ch3,cx,36,"CONTRABAND",HZ_AMB,false,true) + 6; }
            // right label on the chip row; never overlaps the chips (measured), hidden if there is no room
            var rl:TextField = vsEq ? this.hzT19HdrR : (meta.length > 0 ? this.hzT19Meta : null);
            if(rl)
            {
               var room:Number = W - 14 - (cx + 8);
               rl.width = Math.max(20,Math.round(room));
               rl.x = Math.round(W - 14 - rl.width);
               if(vsEq) { this.hzT19Face(rl,"sb"); rl.text = "VS EQUIPPED"; this.hzTxtTop(rl,37); }
               else { this.hzFitText(rl,meta.join("  ·  "),room); this.hzTxtTop(rl,34); }
               rl.visible = this.hzTW(rl) <= room;
            }
            if(kind == "cmp")
            {
               this.hzT19Line(g,head,W,steal);
               i = 0;
               while(i < rows.length)
               {
                  var rw:Object = rows[i];
                  var ct:Object = this.hzT19Cmp[i];
                  var ry:Number = rowsY + i * 24;
                  var lt:TextField = TextField(ct.l);
                  lt.visible = true; lt.text = String(rw.l); lt.x = 18; this.hzTxtTop(lt,ry + 1);
                  var vt:TextField = TextField(ct.v);
                  vt.visible = true;
                  vt.text = this.hzT19Fmt(Number(rw.v),int(rw.dec),Boolean(rw["int"])) + (rw.pct ? "%" : "");
                  vt.x = Math.round(W - 92 - vt.width); this.hzTxtTop(vt,ry - 2);
                  var dt:TextField = TextField(ct.d);
                  var c:Number = Number(rw.c);
                  if(!isNaN(c))
                  {
                     var dv:Number = Number(rw.v) - c;
                     var eps:Number = Math.pow(10,-Math.max(0,int(rw.dec))) / 2;
                     dt.visible = true;
                     if(Math.abs(dv) < eps) { dt.text = "—"; this.hzTxtTint(dt,0x808E96); }
                     else
                     {
                        var better:Boolean = rw.low ? dv < 0 : dv > 0;
                        dt.text = (dv > 0 ? "+" : "−") + this.hzT19Fmt(Math.abs(dv),int(rw.dec),Boolean(rw["int"]));
                        this.hzTxtTint(dt,better ? HZ_GREEN : HZ_RED);
                        var tc:uint = this.hzIconCol(better ? HZ_GREEN : HZ_RED);
                        var tx:Number = W - 14 - this.hzTW(dt) - 9;
                        var tyc:Number = ry + 8;
                        g.beginFill(tc,1);
                        if(dv > 0) { g.moveTo(tx - 4,tyc + 3); g.lineTo(tx + 4,tyc + 3); g.lineTo(tx,tyc - 3.5); g.lineTo(tx - 4,tyc + 3); }
                        else { g.moveTo(tx - 4,tyc - 3); g.lineTo(tx + 4,tyc - 3); g.lineTo(tx,tyc + 3.5); g.lineTo(tx - 4,tyc - 3); }
                        g.endFill();
                     }
                     dt.x = Math.round(W - 14 - dt.width); this.hzTxtTop(dt,ry - 1);
                  }
                  i++;
               }
            }
            if(hasBtn)
            {
               this.hzT19Line(g,bodyEnd + 2,W,steal);
               this.hzT19Buttons(g,a,aw,18,bodyEnd + 12,acol);
            }
         }
         else if(kind == "list")
         {
            var items:Array = this.hzTgItems;
            var n:int = items.length;
            W = Math.max(340,Math.round(bw + 28));
            o.center = false; o.right = false; o.ls = 2; o.fs = 16;
            nmTf.visible = true;
            nmTf.x = 14; nmTf.width = W - 28;
            this.hzTxtTint(nmTf,steal ? HZ_RED : null);
            this.hzApplyFmt(o);
            this.hzT19HdrR.visible = true;
            this.hzT19Face(this.hzT19HdrR,"sb");
            this.hzT19HdrR.width = 140;
            this.hzT19HdrR.text = n + (n == 1 ? " ITEM" : " ITEMS");
            this.hzT19HdrR.x = W - 14 - 140;
            this.hzTxtTop(this.hzT19HdrR,15);
            var hroom:Number = W - 28 - this.hzTW(this.hzT19HdrR) - 14;
            var stw:Number = 0;
            if(steal) { stw = 60; hroom -= stw; }
            this.hzFitText(nmTf,this.hzUC(hdrTxt),hroom);
            this.hzTxtTop(nmTf,11);
            var vis:int = Math.min(5,n);
            var RH:Number = 28;
            var y0:Number = 48;
            var bot:Number = y0 + vis * RH;
            var fy:Number = bot + 10;
            var se:Object = sel >= 0 ? items[sel] : null;
            var fmeta:Array = [];
            if(se && this.hzTgShowValue)
            {
               var sv:Number = Number(se.uValue);
               var sw:Number = Number(se.fWeight);
               if(se.uValue != undefined && !isNaN(sv) && sv > 0) { fmeta.push(this.hzFmtInt(sv) + " CR"); }
               if(se.fWeight != undefined && !isNaN(sw) && sw > 0) { fmeta.push(sw.toFixed(1) + " KG"); }
            }
            // v0.25: value / weight line, then a thin divider, then the keycap row a little lower (whole units)
            H = hasBtn ? fy + 42 + this.hzT19CapH() + 14 : fy + 30;
            this.hzPanel(g,W,H,18,tint,edge);
            this.hzAccStripe(g,H,steal ? HZ_RED : HZ_ACCENT);
            if(steal)
            {
               var stx:Number = 14 + this.hzTW(nmTf) + 10;
               this.hzChip(g,this.hzT19Ch2,stx,15,"STEAL",HZ_RED,true);
            }
            var ac:uint = this.hzIconCol(acol);
            this.hzT19Line(g,42,W,steal);
            i = 0;
            while(i < vis)
            {
               var idx:int = start + i;
               var e:Object = items[idx];
               var r:Object = this.hzT19Rows[i];
               var y:Number = y0 + i * RH;
               if(!e) { i++; continue; }
               var er:int = e.uRarity != undefined ? int(e.uRarity) : 0;
               var isSel:Boolean = idx == sel;
               if(isSel)
               {
                  g.beginFill(ac,0.16); g.drawRoundRect(8,y,W - 30,RH - 3,14,14); g.endFill();
                  g.beginFill(ac,1); g.drawRoundRect(8,y + 5,3,RH - 13,3,3); g.endFill();
               }
               g.beginFill(er > 0 ? this.hzRarCol(er) : this.hzIconCol(0xD6DEE4),1);
               g.drawCircle(20.5,y + 12.5,3);
               g.endFill();
               var cnt:int = e.uCount != undefined ? int(e.uCount) : 1;
               var ctf:TextField = TextField(r.c);
               ctf.visible = cnt > 1;
               ctf.text = cnt > 1 ? "x" + cnt : "";
               ctf.x = Math.round(W - 30 - ctf.width);
               this.hzTxtTop(ctf,y + 4);
               var right:Number = W - 30 - (cnt > 1 ? this.hzTW(ctf) + 10 : 0);
               var tag:String = Boolean(e.bContraband) ? "CONTRABAND" : (Boolean(e.bStolen) ? "STOLEN" : "");
               var ttf:TextField = TextField(r.t);
               var tagW:Number = 0;
               if(tag.length > 0) { ttf.text = tag; tagW = this.hzTW(ttf) + 14; }
               var ntf:TextField = TextField(r.n);
               this.hzT19Face(ntf,isSel ? "sb" : "rg");
               ntf.visible = true;
               var nroom:Number = right - 30 - (tagW > 0 ? tagW + 8 : 0);
               ntf.width = Math.max(40,Math.round(nroom + 4));
               this.hzTxtTint(ntf,er > 0 ? uint(HZ_RAR[Math.min(4,er)]) : (isSel ? 0xF2F7F9 : 0xD7E0E6));
               this.hzFitText(ntf,e.sName != null ? this.hzT19Xl(String(e.sName)) : "",nroom);
               ntf.x = 30;
               this.hzTxtTop(ntf,y + 3);
               if(tagW > 0)
               {
                  var tcol:uint = tag == "STOLEN" ? HZ_RED : HZ_AMB;
                  var tgx:Number = Math.round(30 + this.hzTW(ntf) + 8);
                  var tcc:uint = this.hzIconCol(tcol);
                  this.hzTxtTint(ttf,tcol);
                  g.lineStyle(1,tcc,0.75,true,"none");
                  g.beginFill(tcc,0.16);
                  g.drawRoundRect(tgx + 0.5,y + 6.5,tagW,14,14,14);
                  g.endFill(); g.lineStyle();
                  ttf.x = tgx + 5; this.hzTxtTop(ttf,y + 6);
                  ttf.visible = true;
               }
               i++;
            }
            if(n > 5)
            {
               var sxx:Number = W - 13;
               var mc:uint = this.hzMainCol();
               g.beginFill(mc,start > 0 ? 0.7 : 0.2); g.moveTo(sxx - 4,y0 + 6); g.lineTo(sxx + 4,y0 + 6); g.lineTo(sxx,y0 + 1); g.lineTo(sxx - 4,y0 + 6); g.endFill();
               g.beginFill(mc,start + 5 < n ? 0.7 : 0.2); g.moveTo(sxx - 4,bot - 6); g.lineTo(sxx + 4,bot - 6); g.lineTo(sxx,bot - 1); g.lineTo(sxx - 4,bot - 6); g.endFill();
               var tl:Number = bot - y0 - 16;
               var th:Number = Math.max(10,tl * 5 / n);
               var tpos:Number = (tl - th) * start / Math.max(1,n - 5);
               g.beginFill(mc,0.12); g.drawRect(sxx - 1,y0 + 8,2,tl); g.endFill();
               g.beginFill(mc,0.7); g.drawRect(sxx - 1,y0 + 8 + tpos,2,th); g.endFill();
            }
            this.hzT19Line(g,fy,W,steal);
            var fr:TextField = this.hzT19FootR;
            fr.visible = fmeta.length > 0;
            var froom:Number = W - 28;
            if(fr.visible)
            {
               fr.width = 180; fr.text = fmeta.join("  ·  "); fr.x = W - 14 - 180; this.hzTxtTop(fr,fy + 7);
               froom -= this.hzTW(fr) + 14;
            }
            if(se && froom > 40)
            {
               this.hzT19Foot.visible = true;
               this.hzT19Foot.width = Math.round(froom + 4);
               this.hzFitText(this.hzT19Foot,se.sName != null ? this.hzT19Xl(String(se.sName)) : "",froom);
               this.hzTxtTop(this.hzT19Foot,fy + 7);
            }
            if(hasBtn)
            {
               this.hzT19Line(g,fy + 32,W,steal);
               this.hzT19Buttons(g,a,aw,14,fy + 42,acol);
            }
         }
         // every tag text field on the device-pixel grid too (no half-pixel glyph origins at 1.5x)
         var su:Number = this.hzT19U();
         if(su != 1)
         {
            var ci:int = 0;
            while(ci < this.hzTg19.numChildren)
            {
               var sco:DisplayObject = this.hzTg19.getChildAt(ci);
               if(sco is TextField && sco.visible) { this.hzTxtTopU(TextField(sco),sco.y,su); }
               ci++;
            }
         }
         this.hzT19W = W; this.hzT19H = H;
      }

      // ===================== v0.26 (hud_features_v1a / v1b, equipment_power_v1) =====================
      // Every element below is guarded: no provider / unknown field = that element simply stays hidden.
      public var hzShowChar:Boolean = true;      // ShowCharacter
      public var hzEdgePulse:Boolean = true;     // EdgePulse
      public var hzXpToastOn:Boolean = true;     // XpToast
      public var hzEnemyBarOn:Boolean = true;    // EnemyBar
      public var hzStealthOn:Boolean = true;     // StealthMeter
      public var hzHitMarkOn:Boolean = true;     // HitMarkers
      public var hzDmgNumOn:Boolean = true;      // DamageNumbers
      public var hzDirRingOn:Boolean = true;     // DirectionRing
      public var hzRegenOn:Boolean = true;       // RegenSliver
      public var hzEqExtrasOn:Boolean = true;    // EquipmentExtras (grenades + Starborn power)
      private var hzLayEver:Boolean = false;
      private var hzTgScaleLeg:Number = NaN;
      private var hzTgScaleSet:Boolean = false;
      public var HorizonChar_mc:Sprite = null;
      public var HorizonEnemy_mc:Sprite = null;
      public var HorizonStealth_mc:Sprite = null;
      public var HorizonXp_mc:Sprite = null;
      public var HorizonFx_mc:Sprite = null;
      public var HorizonEdge_mc:Sprite = null;
      private static const HZ_VIO:uint = 0xA274FF;
      private static const HZ_CH_W:Number = 360;
      private static const HZ_CH_H:Number = 150;
      private static const HZ_EN_W:Number = 480;
      private static const HZ_ST_W:Number = 220;
      private static const HZ_ST_H:Number = 48;
      private var hz26StW:Number = 220;
      private var hz26StH:Number = 48;
      private var hz26Dbg:Object = {};
      private var hz26Built:Boolean = false;
      // character data (PlayerData / PlayerInventoryData)
      private var hz26Name:String = "";
      private var hz26Lv:int = -1;
      private var hz26Xp:Number = NaN;
      private var hz26XpN:Number = NaN;
      private var hz26Sp:int = 0;
      private var hz26Enc:Number = NaN;
      private var hz26EncMax:Number = NaN;
      private var hz26Cr:Number = NaN;
      private var hz26CharOk:Boolean = false;
      private var hz26Over:Boolean = false;
      private var hz26OwKey:String = "";
      private var hz26ChF:Sprite;
      private var hz26ChS:Sprite;
      private var hz26ChG:Sprite;
      private var hz26ChSG:Sprite;
      private var hz26ChName:TextField;
      private var hz26ChSpT:TextField;
      private var hz26ChCr:TextField;
      private var hz26ChLv:TextField;
      private var hz26ChXpT:TextField;
      private var hz26ChNext:TextField;
      private var hz26ChML:TextField;
      private var hz26ChMV:TextField;
      private var hz26ChXpBar:Sprite;
      private var hz26ChsLv:TextField;
      private var hz26ChsPct:TextField;
      private var hz26ChsMass:TextField;
      private var hz26ChsCr:TextField;
      private var hz26ChsSp:TextField;
      private var hz26ChsXpBar:Sprite;
      private var hz26ChW:Number = 360;
      private var hz26ChH:Number = 150;
      private var hz26ChSig:String = "";
      // XP toast + bar ghost
      private var hz26XpAmt:Number = 0;
      private var hz26XpLastT:Number = 0;
      private var hz26XpUntil:Number = 0;
      private var hz26XpSeen:Boolean = false;
      private var hz26XpG:Number = -1;          // ghost start fraction on the XP bar
      private var hz26XpGA:Number = 0;
      private var hz26XpBody:Sprite;
      private var hz26XpT:TextField;
      private var hz26XpW:Number = 120;
      // vitals extras
      private var hz26HpF:Number = 1;
      private var hz26O2F:Number = 1;
      private var hz26Co2F:Number = 0;
      private var hz26Gain:Number = 0;
      private var hz26BoostT:Number = 0;
      private var hz26Regen:Sprite;
      private var hz26RegenT:TextField;
      private var hz26Co2Bar:Sprite;
      private var hz26Co2T:TextField;
      private var hz26RegenPh:Number = 0;
      private var hz26EdgeSig:String = "";
      private var hz26EdgeCol:int = -1;
      // equipment extras
      private var hz26Gren:int = -1;
      private var hz26SP:Number = NaN;
      private var hz26SPMax:Number = NaN;
      private var hz26PowSeen:Boolean = false;
      private var hz26PowHas:Boolean = false;
      private var hz26PowKey:String = "";
      private var hz26PowSrc:String = "none";
      private var hz26PowCache:Object = {};
      private var hz26PowObj:DisplayObject = null;
      private var hz26EqRowS:Sprite;
      private var hz26EqRowG:Sprite;
      private var hz26PowHold:Sprite;
      private var hz26PowGly:Sprite;
      private var hz26GrenT:TextField;
      private var hz26PowL:TextField;
      private var hz26PowP:TextField;
      private var hz26EqSig:String = "";
      // enemy bar
      private var hz26En:Object = null;
      private var hz26EnT:Number = 0;
      private var hz26EnOn:Boolean = false;
      private var hz26EnGhost:Number = -1;
      private var hz26EnLast:Number = -1;
      private var hz26EnHold:int = 0;
      private var hz26EnId:String = "";
      private var hz26EnG:Sprite;
      private var hz26EnLv:TextField;
      private var hz26EnName:TextField;
      private var hz26EnPct:TextField;
      private var hz26EnEmL:TextField;
      private var hz26EnEmR:TextField;
      private var hz26EnChips:Array = [];
      private var hz26EnH:Number = 62;
      // stealth
      private var hz26St:Object = null;
      private var hz26StOn:Boolean = false;
      private var hz26StG:Sprite;
      private var hz26StT:TextField;
      private var hz26StD:TextField;
      private var hz26StPh:Number = 0;
      // combat fx
      private var hz26Hit:Sprite;
      private var hz26Kill:Sprite;
      private var hz26HitT:Number = 0;
      private var hz26HitCrit:Boolean = false;
      private var hz26KillT:Number = 0;
      private var hz26Nums:Array = [];
      private var hz26Ring:Sprite;
      private var hz26Arcs:Array = [];
      private var hz26VCache:Object = {};
      private var hz26VHid:Object = {};

      private function hz26Now() : Number
      {
         return new Date().getTime();
      }

      private function hz26Build() : void
      {
         try { this.hz26BuildEdge(); } catch(e0:Error) { this.HorizonEdge_mc = null; }
         try { this.hz26BuildChar(); } catch(e1:Error) { this.HorizonChar_mc = null; }
         try { this.hz26BuildXp(); } catch(e2:Error) { this.HorizonXp_mc = null; }
         try { this.hz26BuildEnemy(); } catch(e3:Error) { this.HorizonEnemy_mc = null; }
         try { this.hz26BuildStealth(); } catch(e4:Error) { this.HorizonStealth_mc = null; }
         try { this.hz26BuildFx(); } catch(e5:Error) { this.HorizonFx_mc = null; }
         try { this.hz26BuildVit(); } catch(e6:Error) { }
         try { this.hz26BuildEq(); } catch(e7:Error) { }
         try { BSUIDataManager.Subscribe("PlayerData",this.hz26OnPlayer); } catch(s1:Error) { }
         try { BSUIDataManager.Subscribe("PlayerInventoryData",this.hz26OnInv); } catch(s2:Error) { }
         try { BSUIDataManager.Subscribe("PlayerFrequentData",this.hz26OnFreq); } catch(s3:Error) { }
         try { BSUIDataManager.Subscribe("WeaponData",this.hz26OnWeapon); } catch(s4:Error) { }
         try { BSUIDataManager.Subscribe("XPData",this.hz26OnXp); } catch(s5:Error) { }
         try { BSUIDataManager.Subscribe("HUDStealthData",this.hz26OnStealth); } catch(s6:Error) { }
         try { BSUIDataManager.Subscribe("HudHitKillIndicatorData",this.hz26OnHitKill); } catch(s7:Error) { }
         try { BSUIDataManager.Subscribe("HUDDirectionalHitData",this.hz26OnDirHit); } catch(s8:Error) { }
         try { BSUIDataManager.Subscribe("PlayerHealthBoostData",this.hz26OnBoost); } catch(s9:Error) { }
         try { BSUIDataManager.Subscribe("HUDStarbornPowersData",this.hz26OnPowers); } catch(s10:Error) { }
         try { BSUIDataManager.Subscribe("HudEnemyData",this.hz26OnEnemy); } catch(s11:Error) { }
         try { this.hz27Build(); } catch(s12:Error) { }
         this.hz26Built = true;
         this.hzApplyScale();
      }

      private function hz26Log(k:String, o:Object) : void
      {
         if(!this.hzDebug) { return; }
         try { this.hz26Dbg[k] = this.hzDump(o); } catch(err:Error) { }
      }

      private function hz26DbgText() : String
      {
         var out:String = "";
         for each(var k:String in ["PersonalEffectsData","PersonalAlertsData","aPersonalAlerts[0]","Afflictions","QuestObjectives","PlayerData","PlayerInventoryData","XPData","XPData[0]","HUDStealthData","HudHitKillIndicatorData","KillDataA[0]","HUDDirectionalHitData","aDirectionalHitIndicators[0]","PlayerHealthBoostData","HUDStarbornPowersData","PowerIcon","Enemy","EnemyModifiers"])
         {
            if(this.hz26Dbg[k] != undefined) { out += k + ": " + String(this.hz26Dbg[k]) + "\n"; }
         }
         return out;
      }

      // ---------- providers ----------
      private function hz26OnPlayer(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            this.hz26Log("PlayerData",d);
            if(d.sName != undefined && d.sName != null) { this.hz26Name = String(d.sName); }
            var lv:Number = Number(d.uLevel);
            var xp:Number = Number(d.fLevelXP);
            var nx:Number = Number(d.fNextLevelXP);
            // XP toast fallback: gains derived from fLevelXP when XPData does not reach the HUD
            if(!this.hz26XpSeen && this.hz26Lv >= 0 && !isNaN(xp) && !isNaN(this.hz26Xp))
            {
               var gain:Number = 0;
               if(!isNaN(lv) && int(lv) == this.hz26Lv && xp > this.hz26Xp) { gain = xp - this.hz26Xp; }
               else if(!isNaN(lv) && int(lv) == this.hz26Lv + 1 && this.hz26XpN > 0) { gain = Math.max(0,this.hz26XpN - this.hz26Xp) + xp; }
               if(gain >= 1) { this.hz26XpAdd(gain); }
            }
            if(!isNaN(lv)) { this.hz26Lv = int(lv); }
            if(!isNaN(xp)) { this.hz26Xp = xp; }
            if(!isNaN(nx)) { this.hz26XpN = nx; }
            if(d.uSkillPoints != undefined && !isNaN(Number(d.uSkillPoints))) { this.hz26Sp = int(d.uSkillPoints); }
            var en:Number = Number(d.fEncumbrance);
            var em:Number = Number(d.fMaxEncumbrance);
            if(!isNaN(en) && em > 0) { this.hz26Enc = en; this.hz26EncMax = em; }
            this.hz26CharOk = this.hz26Lv >= 0 || this.hz26Name.length > 0;
            try { this.hz27CharData(this.hz26Lv,this.hz26Sp,NaN); } catch(err27:Error) { }
            this.hz26CharChanged();
         }
         catch(err:Error) { }
      }

      private function hz26OnInv(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            if(this.hzDebug)
            {
               var lite:Object = {};
               for(var k:String in d) { if(k != "aItems") { lite[k] = d[k]; } }
               this.hz26Log("PlayerInventoryData",lite);
            }
            if(d.uCoin != undefined && !isNaN(Number(d.uCoin))) { this.hz26Cr = Number(d.uCoin); try { this.hz27CharData(-1,-1,this.hz26Cr); } catch(err27:Error) { } }
            var en:Number = Number(d.fEncumbrance);
            var em:Number = Number(d.fMaxEncumbrance);
            if(!isNaN(en) && em > 0) { this.hz26Enc = en; this.hz26EncMax = em; }
            this.hz26CharChanged();
         }
         catch(err:Error) { }
      }

      private function hz26CharChanged() : void
      {
         this.hz26Over = !isNaN(this.hz26Enc) && this.hz26EncMax > 0 && this.hz26Enc > this.hz26EncMax + 0.0001;
         try { this.hz26CharSync(); } catch(err:Error) { }
         this.hz26OwCheck();
      }

      // overweight chip lives on the character card; in Afflictions only when that card is off (never both)
      private function hz26OwInAffl() : Boolean
      {
         return this.hz26Over && this.hzShowAfflictions && !(this.hzShowChar && this.hz26CharOk && this.HorizonChar_mc != null && this.hz27CharCoversOw());
      }

      private function hz26OwText() : String
      {
         return Math.round(this.hz26Enc) + " / " + Math.round(this.hz26EncMax) + " KG";
      }

      private function hz26OwCheck() : void
      {
         var key:String = this.hz26OwInAffl() ? "1|" + this.hz26OwText() : "0";
         if(key != this.hz26OwKey)
         {
            this.hz26OwKey = key;
            try { if(this.hzAfNew) { this.hzAfSync(); } } catch(err:Error) { }
         }
      }

      private function hz26OnFreq(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            this.hz26Log("PlayerFrequentData",d);
            var hp:Number = Number(d.fHealth);
            var mhp:Number = Number(d.fMaxHealth);
            if(!isNaN(hp) && mhp > 0) { this.hz26HpF = Math.max(0,Math.min(1,hp / mhp)); }
            var gp:Number = Number(d.fHealthGainPct);
            this.hz26Gain = isNaN(gp) ? 0 : Math.max(0,Math.min(1,gp));
            var o2:Number = Number(d.fOxygen);
            var co2:Number = Number(d.fCarbonDioxide);
            var mo:Number = Number(d.fMaxO2CO2);
            if(!isNaN(o2) && mo > 0) { this.hz26O2F = Math.max(0,Math.min(1,o2 / mo)); }
            this.hz26Co2F = !isNaN(co2) && mo > 0 ? Math.max(0,Math.min(1,co2 / mo)) : 0;
            var sp:Number = Number(d.fStarPower);
            var spm:Number = Number(d.fMaxStarPower);
            var eqd:Boolean = false;
            if(!isNaN(sp) && sp != this.hz26SP) { this.hz26SP = sp; eqd = true; }
            if(!isNaN(spm) && spm != this.hz26SPMax) { this.hz26SPMax = spm; eqd = true; }
            if(eqd) { this.hz26EqChanged(); }
            this.hz26VitExtras();
         }
         catch(err:Error) { }
      }

      private function hz26OnWeapon(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            var n:Number = Number(d.uExplosiveCount);
            var g:int = isNaN(n) ? -1 : int(n);
            if(g != this.hz26Gren) { this.hz26Gren = g; this.hz26EqChanged(); }
         }
         catch(err:Error) { }
      }

      private function hz26OnPowers(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            this.hz26Log("HUDStarbornPowersData",d);
            this.hz26PowSeen = true;
            this.hz26PowHas = d.bHasSpell === true;
            var k:String = d.sKey != undefined && d.sKey != null ? String(d.sKey) : "";
            if(k != this.hz26PowKey) { this.hz26PowKey = k; this.hz26PowResolve(); }
            this.hz26EqChanged();
         }
         catch(err:Error) { }
      }

      private function hz26OnXp(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            this.hz26Log("XPData",d);
            var a:Array = d.XPUpdatesA as Array;
            if(!a || a.length == 0) { return; }
            this.hz26Log("XPData[0]",a[0]);
            var n:Number = 0;
            for each(var u:Object in a) { if(u && !isNaN(Number(u.uiXPAmount))) { n += Number(u.uiXPAmount); } }
            if(n > 0) { this.hz26XpSeen = true; this.hz26XpAdd(n); }
         }
         catch(err:Error) { }
      }

      private function hz26XpAdd(n:Number) : void
      {
         var now:Number = this.hz26Now();
         if(now < this.hz26XpUntil && now - this.hz26XpLastT < 1500) { this.hz26XpAmt += n; }
         else { this.hz26XpAmt = n; }
         this.hz26XpLastT = now;
         this.hz26XpUntil = now + 2000;
         this.hz27CharEvent();
         // white segment on the character XP bar for the new gain
         if(this.hz26XpN > 0 && !isNaN(this.hz26Xp))
         {
            var from:Number = Math.max(0,(this.hz26Xp - n) / this.hz26XpN);
            this.hz26XpG = this.hz26XpGA > 0.05 && this.hz26XpG >= 0 ? Math.min(this.hz26XpG,from) : from;
            this.hz26XpGA = 1;
         }
         try { this.hz26XpSync(); } catch(err:Error) { }
      }

      private function hz26OnStealth(e:FromClientDataEvent) : *
      {
         try { this.hz26St = e.data; this.hz26Log("HUDStealthData",e.data); } catch(err:Error) { this.hz26St = null; }
      }

      private function hz26OnBoost(e:FromClientDataEvent) : *
      {
         try { this.hz36HideTick(); } catch(e36q:Error) { }   // v0.36: the game re-shows HealthBarIncrease_mc on these updates
         try
         {
            this.hz26Log("PlayerHealthBoostData",e.data);
            if(e.data && Number(e.data.fHealthBoost) > 0) { this.hz26BoostT = this.hz26Now() + 700; }
         }
         catch(err:Error) { }
      }

      private function hz26OnEnemy(e:FromClientDataEvent) : *
      {
         var found:Object = null;
         try
         {
            var d:Object = e.data;
            if(d && d.EnemiesA)
            {
               for each(var en:Object in d.EnemiesA) { if(en && en.uID == d.uTargetUnderCrosshairID) { found = en; break; } }
            }
         }
         catch(err:Error) { found = null; }
         if(found != null && found.fHealth != undefined && !isNaN(Number(found.fHealth)) && found.bOnScreen !== false)
         {
            var id:String = String(found.uID);
            if(id != this.hz26EnId) { this.hz26EnId = id; this.hz26EnGhost = -1; this.hz26EnLast = -1; }
            this.hz26En = found;
            this.hz26EnT = this.hz26Now();
            if(this.hzDebug)
            {
               this.hz26Log("Enemy",found);
               var mk:String = "";
               for(var k:String in found) { if(/modif|perk|effect|legend/i.test(k)) { mk += k + "=" + this.hzDump({"v":found[k]}) + " "; } }
               this.hz26Dbg["EnemyModifiers"] = mk.length > 0 ? mk : "(no modifier fields)";
            }
         }
      }

      private function hz26OnHitKill(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            this.hz26Log("HudHitKillIndicatorData",d);
            var a:Array = d.KillDataA as Array;
            if(!a || a.length == 0) { return; }
            this.hz26Log("KillDataA[0]",a[0]);
            var now:Number = this.hz26Now();
            var kill:Boolean = false;
            var crit:Boolean = false;
            for each(var o:Object in a)
            {
               if(!o) { continue; }
               var t:int = int(o.uHitType);
               if(t == 3) { kill = true; }
               if(t == 2) { crit = true; }
               if(this.hzDmgNumOn && Number(o.fDamage) > 0 && Boolean(o.bShowDamageNumber)) { this.hz26Spawn(o,now); }
            }
            if(kill) { this.hz26KillT = now; }
            else { this.hz26HitT = now; this.hz26HitCrit = crit; }
         }
         catch(err:Error) { }
      }

      private function hz26OnDirHit(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            this.hz26Log("HUDDirectionalHitData",d);
            var a:Array = d.aDirectionalHitIndicators as Array;
            if(!a) { return; }
            if(a.length > 0) { this.hz26Log("aDirectionalHitIndicators[0]",a[0]); }
            var now:Number = this.hz26Now();
            for each(var o:Object in a)
            {
               if(!o || isNaN(Number(o.iRotation))) { continue; }
               if(this.hz26Arcs.length >= 6) { this.hz26Arcs.shift(); }
               this.hz26Arcs.push({"r":Number(o.iRotation),"t":now});
            }
         }
         catch(err:Error) { }
      }

      // ---------- character card (status card 360 x 150 / strip in compact mode) ----------
      private function hz26BuildChar() : void
      {
         var c:Sprite = new Sprite();
         c.mouseEnabled = false; c.mouseChildren = false;
         this.HorizonChar_mc = c;
         var f:Sprite = new Sprite(); c.addChild(f); this.hz26ChF = f;
         this.hz26ChG = new Sprite(); f.addChild(this.hz26ChG);
         var W:Number = HZ_CH_W;
         this.hz26ChName = this.hzT(f,"CHARACTER",76,14,W - 90,15,"sb","main",2); this.hzHdr19(this.hz26ChName);
         this.hz26ChSpT = this.hzT(f,"",0,0,100,10,"bd","col",0.8,"left",0xFFFFFF);
         this.hz26ChSpT.visible = false;
         this.hz26ChCr = this.hzT(f,"",W - 14 - 150,15,150,14,"sb","main",0.5,"right");
         this.hz26ChLv = this.hzT(f,"LV --",76,43,100,16,"bd","acc",1);
         this.hz26ChXpT = this.hzT(f,"",W - 14 - 200,46,200,12,"sb","mut",0.4,"right");
         this.hz26ChXpBar = new Sprite(); this.hz26ChXpBar.x = 76; this.hz26ChXpBar.y = 70; f.addChild(this.hz26ChXpBar);
         this.hz26ChNext = this.hzT(f,"",W - 14 - 200,80,200,11,"sb","dim",0.6,"right");
         this.hz26ChML = this.hzT(f,"MASS",44,114,160,11,"sb","mut",1.6);
         this.hz26ChMV = this.hzT(f,"",W - 14 - 200,110,200,14,"sb","main",0.5,"right");
         var s:Sprite = new Sprite(); c.addChild(s); this.hz26ChS = s;
         this.hz26ChSG = new Sprite(); s.addChild(this.hz26ChSG);
         this.hz26ChsLv = this.hzT(s,"LV --",16,10,70,14,"bd","acc",1);
         this.hz26ChsXpBar = new Sprite(); s.addChild(this.hz26ChsXpBar);
         this.hz26ChsPct = this.hzT(s,"",0,11,60,12,"sb","mut",0.4);
         this.hz26ChsMass = this.hzT(s,"",0,11,150,12,"sb","main",0.4);
         this.hz26ChsCr = this.hzT(s,"",0,11,150,12,"sb","main",0.4);
         this.hz26ChsSp = this.hzT(s,"",0,11,80,12,"bd","col",0.8,"left",HZ_AMB);
         s.visible = false;
         addChild(c);
         c.visible = false;
         this.hzSetSz(c,W,HZ_CH_H);
         this.hz26CharSync();
      }

      private function hz26Bar(sp:Sprite, w:Number, h:Number, f:Number, col:uint, gFrom:Number, gA:Number) : void
      {
         var g:* = sp.graphics;
         g.clear();
         var dk:Boolean = this.hzDarkText();
         g.beginFill(dk ? 0x000000 : 0xFFFFFF,dk ? 0.14 : 0.12); g.drawRoundRect(0,0,w,h,h,h); g.endFill();
         f = Math.max(0,Math.min(1,f));
         if(f > 0) { g.beginFill(this.hzIconCol(col),1); g.drawRoundRect(0,0,Math.max(h,Math.round(w * f)),h,h,h); g.endFill(); }
         if(gA > 0.01 && gFrom >= 0 && gFrom < f - 0.002)
         {
            var gx:Number = Math.round(w * gFrom);
            g.beginFill(dk ? 0x0E151B : 0xFFFFFF,0.85 * gA); g.drawRect(gx,0,Math.max(1,Math.round(w * f) - gx - h / 2),h); g.endFill();
         }
      }

      private function hz26Weight(g:*, cx:Number, cy:Number, col:uint, k:Number) : void
      {
         // original kettlebell-style mass glyph: handle loop + rounded body
         g.lineStyle(2 * k,col,1,true);
         g.beginFill(col,0.004);
         g.drawRoundRect(cx - 4.5 * k,cy - 9 * k,9 * k,8 * k,7 * k,7 * k);
         g.endFill();
         g.lineStyle();
         g.beginFill(col,1);
         g.drawRoundRect(cx - 8 * k,cy - 3 * k,16 * k,12 * k,7 * k,7 * k);
         g.endFill();
      }

      private function hz26CharSync() : void
      {
         if(!this.HorizonChar_mc || !this.hz26ChF) { return; }
         var smp:Boolean = this.hzArrange && !this.hz26CharOk;
         var cm:Boolean = this.hz34C("Character");
         var nm:String = smp ? "Character" : (this.hz26Name.length > 0 ? this.hz26Name : "Character");
         var lv:int = smp ? 34 : this.hz26Lv;
         var xp:Number = smp ? 12450 : this.hz26Xp;
         var nx:Number = smp ? 18200 : this.hz26XpN;
         var sp:int = smp ? 2 : this.hz26Sp;
         var cr:Number = smp ? 48320 : this.hz26Cr;
         var en:Number = smp ? 142 : this.hz26Enc;
         var em:Number = smp ? 175 : this.hz26EncMax;
         var xf:Number = nx > 0 && !isNaN(xp) ? Math.max(0,Math.min(1,xp / nx)) : 0;
         var hasM:Boolean = !isNaN(en) && em > 0;
         var over:Boolean = hasM && en > em + 0.0001;
         var lvS:String = lv >= 0 ? "LV " + lv : "LV --";
         var crS:String = isNaN(cr) ? "" : this.hzFmtInt(cr) + " CR";
         var mS:String = hasM ? this.hzFmtInt(en) + " / " + this.hzFmtInt(em) + " KG" : "-- KG";
         var dk:Boolean = this.hzDarkText();
         var bg:uint = dk ? this.hzMix(this.hzPanelFill(),0x000000,0.14) : 0x060A0E;
         var gF:Number = this.hz26XpGA > 0.01 ? this.hz26XpG : -1;
         this.hz26ChF.visible = !cm;
         this.hz26ChS.visible = cm;
         if(!cm)
         {
            var W:Number = HZ_CH_W;
            var H:Number = HZ_CH_H;
            var g:* = this.hz26ChG.graphics;
            g.clear();
            this.hzPanel(g,W,H,18);
            this.hzAccStripe(g,H,over ? HZ_RED : HZ_ACCENT);
            this.hz26Bust(g,40,40,HZ_ACCENT);
            this.hz26ChCr.text = crS;
            this.hzTxtTop(this.hz26ChCr,15);
            var crW:Number = crS.length > 0 ? this.hzTW(this.hz26ChCr) + 12 : 0;
            var spS:String = sp > 0 ? sp + (sp == 1 ? " SKILL PT" : " SKILL PTS") : "";
            var chipW:Number = 0;
            if(sp > 0) { this.hz26ChSpT.text = spS; chipW = this.hzTW(this.hz26ChSpT) + 14 + 8; }
            this.hzFitText(this.hz26ChName,this.hzUC(nm),Math.max(60,W - 14 - 76 - crW - chipW));
            this.hzTxtTop(this.hz26ChName,14);
            this.hz26ChSpT.visible = false;
            if(sp > 0) { this.hzChip(g,this.hz26ChSpT,Math.round(76 + this.hzTW(this.hz26ChName) + 8),17,spS,HZ_AMB,true); }
            this.hz26ChLv.text = lvS;
            this.hzTxtTop(this.hz26ChLv,43);
            this.hz26ChXpT.text = nx > 0 && !isNaN(xp) ? this.hzFmtInt(xp) + " / " + this.hzFmtInt(nx) + " XP" : "";
            this.hzTxtTop(this.hz26ChXpT,46);
            this.hz26ChNext.text = nx > 0 && !isNaN(xp) ? this.hzFmtInt(Math.max(0,nx - xp)) + " TO NEXT" : "";
            this.hzTxtTop(this.hz26ChNext,80);
            this.hz26Bar(this.hz26ChXpBar,W - 14 - 76,6,xf,HZ_ACCENT,gF,this.hz26XpGA);
            this.hzT19Line(g,104,W,false);
            var mc:uint = this.hzIconCol(over ? HZ_RED : HZ_ACCENT);
            this.hz26Weight(g,26,124,mc,0.9);
            this.hz26ChML.text = over ? "OVERWEIGHT" : "MASS";
            this.hzTxtTint(this.hz26ChML,over ? HZ_RED : null);
            this.hzTxtTop(this.hz26ChML,114);
            this.hz26ChMV.text = mS;
            this.hzTxtTint(this.hz26ChMV,over ? HZ_RED : null);
            this.hzTxtTop(this.hz26ChMV,110);
            var bx:Number = 44;
            var bw:Number = W - 14 - bx;
            g.beginFill(dk ? 0x000000 : 0xFFFFFF,dk ? 0.14 : 0.12); g.drawRoundRect(bx,134,bw,5,5,5); g.endFill();
            if(hasM)
            {
               var mf:Number = over ? 1 : Math.max(0,Math.min(1,en / em));
               var mcol:uint = over ? HZ_RED : (mf >= 0.9 ? HZ_AMB : HZ_ACCENT);
               if(mf > 0) { g.beginFill(this.hzIconCol(mcol),1); g.drawRoundRect(bx,134,Math.max(5,Math.round(bw * mf)),5,5,5); g.endFill(); }
               if(over)
               {
                  // where the limit sits on the overloaded bar
                  var tx:Number = Math.round(bx + bw * em / en);
                  g.beginFill(dk ? 0x0E151B : 0xFFFFFF,0.95); g.drawRect(tx - 1,130,2,13); g.endFill();
               }
            }
            this.hz26ChW = W; this.hz26ChH = H;
         }
         else
         {
            var sg:* = this.hz26ChSG.graphics;
            sg.clear();
            var x:Number = 16;
            this.hz26ChsLv.text = lvS; this.hz26ChsLv.x = x; this.hzTxtTop(this.hz26ChsLv,10);
            x += Math.round(this.hzTW(this.hz26ChsLv)) + 10;
            this.hz26ChsXpBar.x = x; this.hz26ChsXpBar.y = 17;
            this.hz26Bar(this.hz26ChsXpBar,80,5,xf,HZ_ACCENT,gF,this.hz26XpGA);
            x += 88;
            this.hz26ChsPct.text = nx > 0 ? Math.round(xf * 100) + "%" : "";
            this.hz26ChsPct.x = x; this.hzTxtTop(this.hz26ChsPct,11);
            x += Math.round(this.hzTW(this.hz26ChsPct)) + 12;
            var dc:uint = dk ? 0x4A5A64 : 0x8E9CA4;
            sg.beginFill(dc,1); sg.drawCircle(x,19,1.6); sg.endFill();
            x += 12;
            var mc2:uint = this.hzIconCol(over ? HZ_RED : HZ_ACCENT);
            this.hz26Weight(sg,x + 7,20,mc2,0.65);
            x += 18;
            this.hz26ChsMass.text = mS; this.hz26ChsMass.x = x; this.hzTxtTop(this.hz26ChsMass,11);
            this.hzTxtTint(this.hz26ChsMass,over ? HZ_RED : null);
            x += Math.round(this.hzTW(this.hz26ChsMass)) + 12;
            this.hz26ChsCr.visible = crS.length > 0;
            if(crS.length > 0)
            {
               sg.beginFill(dc,1); sg.drawCircle(x,19,1.6); sg.endFill();
               x += 12;
               this.hz26ChsCr.text = crS; this.hz26ChsCr.x = x; this.hzTxtTop(this.hz26ChsCr,11);
               x += Math.round(this.hzTW(this.hz26ChsCr));
            }
            this.hz26ChsSp.visible = sp > 0;
            if(sp > 0)
            {
               this.hz26ChsSp.text = sp + " SP";
               x += 16;
               this.hz26ChsSp.x = x; this.hzTxtTop(this.hz26ChsSp,11);
               x += Math.round(this.hzTW(this.hz26ChsSp));
            }
            var SW:Number = Math.max(300,x + 16);
            sg.lineStyle();
            var pg:* = this.hz26ChSG.graphics;
            pg.clear();
            this.hzPanel(pg,SW,38,14);
            // redraw the dots / glyph above the panel (panel first)
            var x2:Number = 16 + Math.round(this.hzTW(this.hz26ChsLv)) + 10 + 88 + Math.round(this.hzTW(this.hz26ChsPct)) + 12;
            pg.beginFill(dc,1); pg.drawCircle(x2,19,1.6); pg.endFill();
            this.hz26Weight(pg,x2 + 12 + 7,20,mc2,0.65);
            if(crS.length > 0)
            {
               var x3:Number = x2 + 12 + 18 + Math.round(this.hzTW(this.hz26ChsMass)) + 12;
               pg.beginFill(dc,1); pg.drawCircle(x3,19,1.6); pg.endFill();
            }
            this.hz26ChW = SW; this.hz26ChH = 38;
         }
         this.hzSetSz(this.HorizonChar_mc,this.hz26ChW,this.hz26ChH);
      }

      // ---------- XP toast ----------
      private function hz26BuildXp() : void
      {
         var c:Sprite = new Sprite();
         c.mouseEnabled = false; c.mouseChildren = false;
         this.HorizonXp_mc = c;
         this.hz26XpBody = new Sprite(); c.addChild(this.hz26XpBody);
         this.hz26XpT = this.hzT(c,"+0 XP",14,6,200,16,"bd","acc",1.2);
         addChild(c);
         c.visible = false;
         this.hz26XpSync();
      }

      private function hz26XpSync() : void
      {
         if(!this.HorizonXp_mc) { return; }
         var n:Number = this.hzArrange && this.hz26XpAmt <= 0 ? 120 : this.hz26XpAmt;
         this.hz26XpT.text = "+" + this.hzFmtInt(n) + " XP";
         this.hzTxtTop(this.hz26XpT,7);
         var w:Number = Math.round(this.hzTW(this.hz26XpT) + 30);
         var g:* = this.hz26XpBody.graphics;
         g.clear();
         this.hzPanel(g,w,32,16,-1,int(this.hzIconCol(HZ_ACCENT)));
         this.hz26XpW = w;
         this.hzSetSz(this.HorizonXp_mc,w,32);
      }

      // ---------- vitals: warning stripe, CO2 tail, regen sliver ----------
      private function hz26BuildVit() : void
      {
         if(!this.hzVitNew) { return; }
         var p:Sprite = this.hzVitNew;
         this.hz26Regen = new Sprite(); this.hz26Regen.x = 14; this.hz26Regen.y = 40; this.hz26Regen.mouseEnabled = false;
         p.addChild(this.hz26Regen);
         this.hz26RegenT = this.hzT(p,"",HZ_VN_W - 14 - 260,8,100,13,"sb","col",0.4,"right",HZ_GREEN);   // v0.42.0 r2: 13 px
         this.hz26RegenT.visible = false;
         this.hz26Co2Bar = new Sprite(); this.hz26Co2Bar.x = 14; this.hz26Co2Bar.y = 66 + 40; this.hz26Co2Bar.mouseEnabled = false;
         p.addChild(this.hz26Co2Bar);
         this.hz26Co2T = this.hzT(p,"",HZ_VN_W - 14 - 260,66 + 8,100,13,"sb","col",0.6,"right",HZ_RED);   // v0.42.0 r2: 13 px
         this.hz26Co2T.visible = false;
         try { this.hz42VitApply(); } catch(err42v:Error) { }   // v0.42.0: the CO2 tail / text join the O2 row
      }

      private function hz26WarnCol(f:Number, okCol:uint) : uint
      {
         return f < 0.15 ? HZ_RED : (f < 0.35 ? HZ_AMB : okCol);
      }

      private function hz26VitExtras() : void
      {
         if(!this.hzVitNew || !this.hz26Regen) { return; }
         var bw:Number = HZ_VN_W - 28;
         // CO2: red tail at the right end of the oxygen bar + "CO2 n%" next to the value
         var cg:* = this.hz26Co2Bar.graphics;
         cg.clear();
         var co:Number = this.hz26Co2F;
         var showCo:Boolean = co > 0.005;
         if(showCo)
         {
            var cw:Number = Math.max(4,Math.round(bw * co));
            cg.beginFill(this.hzIconCol(HZ_RED),0.9); cg.drawRoundRect(bw - cw,0,cw,8,8,8); cg.endFill();
            this.hz26Co2T.text = "CO2 " + Math.round(co * 100) + "%";
            var vw:Number = this.hzVnO2 ? this.hzTW(this.hzVnO2) : 40;
            this.hz26Co2T.x = Math.round(HZ_VN_W - 14 - vw - 10 - 100);
            this.hzTxtTop(this.hz26Co2T,66 + 12);
         }
         this.hz26Co2T.visible = showCo;
      }

      private function hz26TickRegen(now:Number) : void
      {
         if(!this.hz26Regen) { return; }
         var g:* = this.hz26Regen.graphics;
         g.clear();
         var gain:Number = this.hzRegenOn ? this.hz26Gain : 0;
         var boost:Boolean = this.hzRegenOn && now < this.hz26BoostT;
         var on:Boolean = (gain > 0.002 || boost) && this.hz26HpF < 0.999;
         this.hz26RegenT.visible = on && gain > 0.002;
         if(!on) { return; }
         var bw:Number = HZ_VN_W - 28;
         var f:Number = this.hz26HpF;
         var x0:Number = Math.round(bw * f);
         var x1:Number = Math.round(bw * Math.min(1,f + Math.max(gain,boost ? 0.04 : 0)));
         if(x1 - x0 < 3) { x1 = Math.min(bw,x0 + 3); }
         var gc:uint = this.hzIconCol(HZ_GREEN);
         g.beginFill(gc,0.38); g.drawRect(x0,0,x1 - x0,8); g.endFill();
         // chevrons drifting right inside the sliver
         this.hz26RegenPh = (this.hz26RegenPh + 0.6) % 10;
         var cx:Number = x0 + this.hz26RegenPh - 10;
         while(cx < x1)
         {
            if(cx >= x0 && cx + 4 <= x1)
            {
               g.lineStyle(1.2,gc,0.9,true);
               g.moveTo(cx,1.5); g.lineTo(cx + 3,4); g.lineTo(cx,6.5);
               g.lineStyle();
            }
            cx += 10;
         }
         if(gain > 0.002)
         {
            this.hz26RegenT.text = "+" + Math.max(1,Math.round(gain * 100)) + "%";
            var vw:Number = this.hzVnHp ? this.hzTW(this.hzVnHp) : 60;
            this.hz26RegenT.x = Math.round(HZ_VN_W - 14 - vw - 10 - 100);
            this.hzTxtTop(this.hz26RegenT,9);
         }
      }

      // ---------- screen-edge warning tint (stepped bands, center untouched) ----------
      private function hz26BuildEdge() : void
      {
         var c:Sprite = new Sprite();
         c.mouseEnabled = false; c.mouseChildren = false;
         this.HorizonEdge_mc = c;
         addChildAt(c,0);
         c.visible = false;
      }

      private function hz26DrawEdge(vr:Rectangle) : void
      {
         var sig:String = vr.x + "|" + vr.y + "|" + vr.width + "|" + vr.height;
         if(sig == this.hz26EdgeSig) { return; }
         this.hz26EdgeSig = sig;
         var g:* = this.HorizonEdge_mc.graphics;
         g.clear();
         var n:int = 16;
         var bt:Number = 7;
         var i:int = 0;
         while(i < n)
         {
            var a:Number = 0.3 * Math.pow(1 - i / n,1.6);
            var x:Number = vr.x + i * bt;
            var y:Number = vr.y + i * bt;
            var w:Number = vr.width - 2 * i * bt;
            var h:Number = vr.height - 2 * i * bt;
            if(w <= 2 * bt || h <= 2 * bt) { break; }
            g.beginFill(0xFFFFFF,a); g.drawRect(x,y,w,bt); g.endFill();
            g.beginFill(0xFFFFFF,a); g.drawRect(x,y + h - bt,w,bt); g.endFill();
            g.beginFill(0xFFFFFF,a); g.drawRect(x,y + bt,bt,h - 2 * bt); g.endFill();
            g.beginFill(0xFFFFFF,a); g.drawRect(x + w - bt,y + bt,bt,h - 2 * bt); g.endFill();
            i++;
         }
      }

      private function hz26TickEdge(now:Number, base:Boolean) : void
      {
         if(!this.HorizonEdge_mc) { return; }
         var col:int = -1;
         if(this.hzEdgePulse && base && !this.hzArrange && !this.hzSetIsOpen)
         {
            if(this.hz26HpF > 0 && this.hz26HpF < 0.15) { col = int(HZ_RED); }
            else if(this.hz26O2F < 0.15) { col = int(HZ_AMB); }
         }
         if(col < 0) { this.HorizonEdge_mc.visible = false; return; }
         this.hz26DrawEdge(this.hzVis());
         if(col != this.hz26EdgeCol)
         {
            this.hz26EdgeCol = col;
            var cu:uint = uint(col);
            this.HorizonEdge_mc.transform.colorTransform = new ColorTransform(0,0,0,1,(cu >> 16) & 0xFF,(cu >> 8) & 0xFF,cu & 0xFF,0);
         }
         // ~1 Hz
         this.HorizonEdge_mc.alpha = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(now / 1000 * Math.PI * 2));
         this.HorizonEdge_mc.visible = true;
         if(this.HorizonEdge_mc.parent == this && getChildIndex(this.HorizonEdge_mc) != 0) { setChildIndex(this.HorizonEdge_mc,0); }
      }

      // ---------- equipment extras: grenades + selected Starborn power (equipment_power_v1) ----------
      private function hz26BuildEq() : void
      {
         if(!this.hzEq19 || this.hz26EqRowS) { return; }
         var r:Sprite = new Sprite();
         r.mouseEnabled = false; r.mouseChildren = false;
         this.hzEq19.addChild(r);
         this.hz26EqRowS = r;
         this.hz26EqRowG = new Sprite(); r.addChild(this.hz26EqRowG);
         this.hz26PowGly = new Sprite(); r.addChild(this.hz26PowGly);
         this.hz26PowHold = new Sprite(); r.addChild(this.hz26PowHold);
         this.hz26GrenT = this.hzT(r,"",0,0,60,12,"bd","main",0.5);   // v0.28: grenade chip text
         this.hz26PowL = this.hzT(r,"POWER",0,0,80,12,"sb","mut",1.6);
         this.hz26PowP = this.hzT(r,"",0,0,60,14,"sb","main",0.5,"right");
         r.visible = false;
      }

      private function hz26EqChanged() : void
      {
         try { if(this.hzEq19) { this.hzE19Sync(); } } catch(err:Error) { }
      }

      private function hz26PowOn() : Boolean
      {
         if(!this.hzEqExtrasOn) { return false; }
         if(!(this.hz26SPMax > 0)) { return false; }
         return !this.hz26PowSeen || this.hz26PowHas;
      }

      private function hz26GrenOn() : Boolean
      {
         return this.hzEqExtrasOn && this.hz26Gren > 0;
      }

      // The selected power's own icon. Vanilla (PlayerHUDComponents ArtifactPowersIcon) shows it by
      // EquippedSpellIcon_mc.gotoAndStop(HUDStarbornPowersData.sKey); sKey is also the linkage class of each
      // per-power symbol (PowerTypes: "ArtifactPower_Supernova" ...). Runtime lookup only, never bundled; one
      // instance per key, cached. Not resolvable = the original Horizon glyph.
      private function hz26PowResolve() : void
      {
         var key:String = this.hz26PowKey;
         var inst:DisplayObject = null;
         var src:String = "glyph";
         try
         {
            if(this.hz26PowObj && this.hz26PowObj.parent) { this.hz26PowObj.parent.removeChild(this.hz26PowObj); }
            this.hz26PowObj = null;
            if(key.length > 0)
            {
               inst = this.hz26PowCache[key] as DisplayObject;
               if(inst != null) { src = String(this.hz26PowCache[key + "#src"]); }
               else if(ApplicationDomain.currentDomain.hasDefinition(key))
               {
                  var C:Class = ApplicationDomain.currentDomain.getDefinition(key) as Class;
                  inst = C != null ? new C() as DisplayObject : null;
                  if(inst is MovieClip) { MovieClip(inst).stop(); }
                  src = "class " + key;
               }
               else if(ApplicationDomain.currentDomain.hasDefinition("ArtifactPowersIcon"))
               {
                  var C2:Class = ApplicationDomain.currentDomain.getDefinition("ArtifactPowersIcon") as Class;
                  var host:Object = C2 != null ? new C2() : null;
                  var sic:MovieClip = host ? host.EquippedSpellIcon_mc as MovieClip : null;
                  if(sic != null)
                  {
                     sic.gotoAndStop(key);
                     if(sic.currentFrameLabel == key)
                     {
                        if(sic.parent) { sic.parent.removeChild(sic); }
                        sic.visible = true;
                        inst = sic;
                        src = "ArtifactPowersIcon.EquippedSpellIcon_mc @" + key;
                     }
                  }
               }
               if(inst != null) { this.hz26PowCache[key] = inst; this.hz26PowCache[key + "#src"] = src; }
            }
         }
         catch(err:Error) { inst = null; src = "glyph (error " + err.message + ")"; }
         this.hz26PowObj = inst;
         this.hz26PowSrc = inst != null ? src : (key.length > 0 && src.indexOf("error") < 0 ? "glyph (no definition for " + key + ")" : src);
         if(this.hzDebug) { this.hz26Dbg["PowerIcon"] = "sKey=" + key + " source=" + this.hz26PowSrc; }
         if(inst != null && this.hz26PowHold) { this.hz26PowHold.addChild(inst); }
      }

      // original power glyph: core, tilted orbit ring, four short rays
      private function hz26PowGlyph(g:*, cx:Number, cy:Number, r:Number, col:uint, a:Number) : void
      {
         g.beginFill(col,a); g.drawCircle(cx,cy,r * 0.28); g.endFill();
         g.lineStyle(Math.max(1,r * 0.13),col,a,true);
         var i:int = 0;
         var t:Number = -30 * Math.PI / 180;
         while(i <= 24)
         {
            var an:Number = Math.PI * 2 * i / 24;
            var ex:Number = Math.cos(an) * r * 0.85;
            var ey:Number = Math.sin(an) * r * 0.32;
            var px:Number = cx + ex * Math.cos(t) - ey * Math.sin(t);
            var py:Number = cy + ex * Math.sin(t) + ey * Math.cos(t);
            if(i == 0) { g.moveTo(px,py); } else { g.lineTo(px,py); }
            i++;
         }
         var k:int = 0;
         while(k < 4)
         {
            var ra:Number = k * Math.PI / 2;
            g.moveTo(cx + Math.cos(ra) * r * 0.62,cy + Math.sin(ra) * r * 0.62);
            g.lineTo(cx + Math.cos(ra) * r,cy + Math.sin(ra) * r);
            k++;
         }
         g.lineStyle();
      }

      private function hz26PowIcon(cx:Number, cy:Number, r:Number, ready:Boolean) : void
      {
         var col:uint = this.hzIconCol(HZ_VIO);
         var gg:* = this.hz26PowGly.graphics;
         gg.clear();
         var used:Boolean = false;
         if(this.hz26PowObj != null)
         {
            try
            {
               var o:DisplayObject = this.hz26PowObj;
               if(o.parent != this.hz26PowHold) { this.hz26PowHold.addChild(o); }
               o.transform.colorTransform = new ColorTransform(0,0,0,1,(col >> 16) & 0xFF,(col >> 8) & 0xFF,col & 0xFF,0);
               this.hzE19Fit(o,new Rectangle(cx - r,cy - r,r * 2,r * 2),8);
               used = o.width > 1;
            }
            catch(errP:Error) { used = false; }
         }
         this.hz26PowHold.visible = used;
         this.hz26PowGly.visible = !used;
         if(!used) { this.hz26PowGlyph(gg,cx,cy,r,col,1); }
         var tgt:Sprite = used ? this.hz26PowHold : this.hz26PowGly;
         tgt.alpha = ready ? 1 : 0.6;
         tgt.filters = ready ? [new GlowFilter(col,0.55,7,7,1.4,1)] : [];
      }

      private function hz26Grenade(g:*, cx:Number, cy:Number, col:uint, k:Number) : void
      {
         // original grenade glyph: body + lever + pin ring
         g.beginFill(col,1); g.drawEllipse(cx - 5.5 * k,cy - 4 * k,11 * k,13 * k); g.endFill();
         g.lineStyle(1.6 * k,col,1,true);
         g.moveTo(cx - 2 * k,cy - 4 * k); g.lineTo(cx - 2 * k,cy - 8 * k); g.lineTo(cx + 5 * k,cy - 6 * k);
         g.drawCircle(cx + 5.5 * k,cy - 9.5 * k,2 * k);
         g.lineStyle();
      }

      private function hz26Seg(g:*, x:Number, y:Number, w:Number, h:Number, n:int, f:Number, col:uint) : void
      {
         var dk:Boolean = this.hzDarkText();
         var gap:Number = 3;
         var sw:Number = (w - gap * (n - 1)) / n;
         var lit:Number = f * n;
         var i:int = 0;
         while(i < n)
         {
            var sx:Number = Math.round(x + i * (sw + gap));
            var ew:Number = Math.round(x + i * (sw + gap) + sw) - sx;
            g.beginFill(dk ? 0x000000 : 0xFFFFFF,dk ? 0.14 : 0.12); g.drawRect(sx,y,ew,h); g.endFill();
            var part:Number = Math.max(0,Math.min(1,lit - i));
            if(part > 0) { g.beginFill(col,1); g.drawRect(sx,y,Math.max(1,Math.round(ew * part)),h); g.endFill(); }
            i++;
         }
      }

      // lays out the extras for the current form; returns {w,h} of the whole card or null when nothing shows
      private function hz26EqRow(cm:Boolean, W:Number, T:Number) : Object
      {
         if(!this.hzEq19) { return null; }
         if(!this.hz26EqRowS) { this.hz26BuildEq(); }
         if(!this.hz26EqRowS) { return null; }
         var smp:Boolean = this.hzArrange && this.hz26Gren < 0 && !(this.hz26SPMax > 0) && this.hzEqExtrasOn;
         var gn:int = this.hz28GrenN();
         var gOn:Boolean = gn > 0;
         var pOn:Boolean = smp || this.hz26PowOn();
         var r:Sprite = this.hz26EqRowS;
         r.visible = gOn || pOn;
         if(!r.visible) { return null; }
         var g:* = this.hz26EqRowG.graphics;
         g.clear();
         var pf:Number = smp ? 1 : (this.hz26SPMax > 0 ? Math.max(0,Math.min(1,this.hz26SP / this.hz26SPMax)) : 0);
         var ready:Boolean = pf >= 0.999;
         var vio:uint = this.hzIconCol(HZ_VIO);
         var main:uint = this.hzIconCol(HZ_ACCENT);
         this.hz26GrenT.visible = gOn;
         this.hz26PowL.visible = pOn && !cm;
         this.hz26PowP.visible = pOn && !cm;
         this.hz26PowHold.visible = false;
         this.hz26PowGly.visible = false;
         if(!cm)
         {
            // layout A (v0.28): grenade chip sits in the ammo line (position from hzE19Sync); the row under the
            // divider is only the power meter: [power tile] READY / POWER [segmented bar] 100%
            // v0.30: grenade badge on the weapon tile's bottom-right corner (tile 12.5 - 119.5 x 12.5 - T-12.5; ammo text starts at 134)
            if(gOn) { this.hz30Badge(g,124,T - 7.5,gn,HZ_E19_TX - 6); }
            else { this.hz26GrenT.visible = false; }
            if(!pOn) { return {"w":W,"h":T}; }
            this.hzT19Line(g,T - 2,W,false);
            var cy:Number = T + 16;
            var lx:Number = 22;
            if(pOn)
            {
               var tcx:Number = lx + 14;
               var dk:Boolean = this.hzDarkText();
               g.lineStyle(1.4,vio,ready ? 0.9 : 0.47,true);
               g.beginFill(dk ? this.hzMix(this.hzPanelFill(),0x000000,0.14) : 0x060A0E,0.92);
               g.drawCircle(tcx,cy,14);
               g.endFill();
               g.lineStyle();
               this.hz26PowIcon(tcx,cy,9,ready);
               lx += 36;
               this.hz26PowL.text = ready ? "READY" : "POWER";
               this.hzTxtTint(this.hz26PowL,ready ? HZ_VIO : null);
               this.hz26PowL.x = lx; this.hzTxtTop(this.hz26PowL,cy - 8);
               this.hz26PowP.text = Math.round(pf * 100) + "%";
               this.hzTxtTint(this.hz26PowP,ready ? null : 0x96A6AE);
               this.hz26PowP.x = W - 14 - 60; this.hzTxtTop(this.hz26PowP,cy - 9);
               var bx:Number = lx + 62;
               var bw:Number = W - 14 - 48 - bx;
               if(bw > 24) { this.hz26Seg(g,bx,cy - 3,bw,6,8,pf,vio); }
            }
            return {"w":W,"h":T + 34};
         }
         // compact C: ... clip / reserve | grenade x3 | power icon in a mini arc meter
         var x:Number = W - 6;
         if(gOn)
         {
            // v0.30: the same badge on the bottom-right corner of the weapon outline (icon box 16 - 112 x 10 - T-10),
            // never reaching the clip numbers
            var lim30:Number = isNaN(this.hz30CntL) ? 120 : this.hz30CntL - 6;
            this.hz30Badge(g,114,T - 6,gn,lim30);
         }
         if(pOn)
         {
            var acx:Number = x + 18;
            var acy:Number = 28;
            g.lineStyle(3,this.hzDarkText() ? 0x000000 : 0xFFFFFF,0.16,true); g.drawCircle(acx,acy,15); g.lineStyle();
            if(pf > 0.001)
            {
               g.lineStyle(3,vio,1,true,"normal","none");
               var st:int = Math.max(2,int(Math.ceil(pf * 36)));
               var i:int = 0;
               while(i <= st)
               {
                  var aa:Number = -Math.PI / 2 + Math.PI * 2 * pf * i / st;
                  if(i == 0) { g.moveTo(acx + Math.cos(aa) * 15,acy + Math.sin(aa) * 15); }
                  else { g.lineTo(acx + Math.cos(aa) * 15,acy + Math.sin(aa) * 15); }
                  i++;
               }
               g.lineStyle();
            }
            this.hz26PowIcon(acx,acy,8,ready);
            x += 40;
         }
         return {"w":Math.max(W,x + 8),"h":T};
      }

      // ---------- enemy health (top center) ----------
      private function hz26BuildEnemy() : void
      {
         var c:Sprite = new Sprite();
         c.mouseEnabled = false; c.mouseChildren = false;
         this.HorizonEnemy_mc = c;
         this.hz26EnG = new Sprite(); c.addChild(this.hz26EnG);
         this.hz26EnLv = this.hzT(c,"",0,0,70,10,"bd","col",0.8,"left",HZ_RED);
         this.hz26EnName = this.hzT(c,"",110,12,HZ_EN_W - 220,15,"sb","col",2.2,"center",0xFF8A8A);
         this.hzHdr19(this.hz26EnName);
         this.hz26EnPct = this.hzT(c,"",HZ_EN_W - 14 - 80,13,80,13,"sb","main",0.4,"right");
         var i:int = 0;
         while(i < 4) { var ct:TextField = this.hzT(c,"",0,0,120,10,"bd","col",0.6,"left",0xF2C14E); ct.visible = false; this.hz26EnChips.push(ct); i++; }
         this.hz26EnEmL = this.hzT(c,"EM",14,0,40,10,"sb","col",1.2,"left",HZ_O2_BLUE);
         this.hz26EnEmR = this.hzT(c,"",HZ_EN_W - 14 - 160,0,160,11,"sb","col",0.8,"right",HZ_O2_BLUE);
         addChild(c);
         c.visible = false;
         this.hzSetSz(c,HZ_EN_W,62);
      }

      // legendary modifiers: not in the decompiled HUD data, so they are discovered at runtime (keys with "modif")
      private function hz26EnMods(e:Object) : Array
      {
         var out:Array = [];
         try
         {
            for(var k:String in e)
            {
               if(!/modif/i.test(k)) { continue; }
               var v:* = e[k];
               if(v is Array)
               {
                  for each(var it:* in v)
                  {
                     if(it is String && String(it).length > 0) { out.push(String(it)); }
                     else if(it != null && typeof it == "object" && it.sName != undefined) { out.push(String(it.sName)); }
                     else if(it != null) { out.push(String(out.length + 1)); }
                  }
               }
               else if(v is String && String(v).length > 0) { out.push(String(v)); }
               else if(typeof v == "number" && Number(v) > 0) { out.push(String(out.length + 1)); }
            }
         }
         catch(err:Error) { }
         return out.slice(0,4);
      }

      private function hz26EnDraw() : void
      {
         var e:Object = this.hz26En;
         if(e == null && this.hzArrange) { e = {"sName":"Ecliptic Captain","fHealth":0.62,"uEnemyDifficultyLevel":24,"uLegendaryRank":2,"bIsLegendary":true,"fElectromagneticHealth":0.7,"bIsStunned":false}; }
         if(e == null) { return; }
         var W:Number = HZ_EN_W;
         var dk:Boolean = this.hzDarkText();
         var hp:Number = Math.max(0,Math.min(1,Number(e.fHealth)));
         if(isNaN(hp)) { hp = 0; }
         if(this.hz26EnGhost < hp || this.hz26EnLast < 0) { this.hz26EnGhost = hp; }
         if(hp < this.hz26EnLast - 0.0005) { this.hz26EnHold = 24; }
         this.hz26EnLast = hp;
         if(this.hz26EnHold > 0) { this.hz26EnHold--; }
         else if(this.hz26EnGhost > hp) { this.hz26EnGhost = Math.max(hp,this.hz26EnGhost - 0.012); }
         var lvl:int = -1;
         if(e.uEnemyDifficultyLevel != undefined && e.uEnemyDifficultyLevel != null && !isNaN(Number(e.uEnemyDifficultyLevel))) { lvl = int(e.uEnemyDifficultyLevel); }
         var rk:int = int(Number(e.uLegendaryRank));
         if(isNaN(Number(e.uLegendaryRank))) { rk = 0; }
         var stars:int = rk > 0 ? Math.min(3,rk) : (Boolean(e.bIsLegendary) ? 1 : 0);
         var mods:Array = this.hz26EnMods(e);
         var emF:Number = Number(e.fElectromagneticHealth);
         var stun:Boolean = Boolean(e.bIsStunned);
         var emOn:Boolean = stun || (!isNaN(emF) && emF >= 0 && emF < 0.999);
         var legRow:Boolean = stars > 0 || mods.length > 0;
         var by:Number = legRow ? 62 : 40;
         var H:Number = by + 8 + 14;
         var emY:Number = by + 8 + 12;
         if(emOn) { H = emY + 5 + 14; }
         var g:* = this.hz26EnG.graphics;
         g.clear();
         var tint:int = int(dk ? this.hzMix(this.hzPanelFill(),HZ_RED,0.14) : 0x160B0D);
         this.hzPanel(g,W,H,18,tint,int(this.hzIconCol(HZ_RED)));
         this.hz26EnLv.visible = lvl >= 0;
         if(lvl >= 0) { this.hzChip(g,this.hz26EnLv,14,13,"LV " + lvl,HZ_RED,false,true); }
         this.hzFitText(this.hz26EnName,this.hzUC(e.sName != null ? String(e.sName) : ""),W - 220);
         this.hzTxtTop(this.hz26EnName,11);
         this.hz26EnPct.text = Math.round(hp * 100) + "%";
         this.hzTxtTop(this.hz26EnPct,12);
         var ci:int = 0;
         for each(var ctf:TextField in this.hz26EnChips) { ctf.visible = false; }
         if(legRow)
         {
            var gold:uint = this.hzIconCol(0xF2C14E);
            var widths:Array = [];
            var tot:Number = stars * 15;
            ci = 0;
            while(ci < mods.length)
            {
               var mt:TextField = TextField(this.hz26EnChips[ci]);
               mt.text = String(mods[ci]).toUpperCase();
               var mw:Number = this.hzTW(mt) + 14;
               widths.push(mw);
               tot += 8 + mw;
               ci++;
            }
            var rx:Number = Math.round(W / 2 - tot / 2);
            var si:int = 0;
            while(si < stars) { this.hzT19Star(g,rx + 7 + si * 15,47,gold); si++; }
            rx += stars * 15;
            ci = 0;
            while(ci < mods.length)
            {
               rx += 8;
               this.hzChip(g,TextField(this.hz26EnChips[ci]),rx,40,String(mods[ci]).toUpperCase(),0xF2C14E,false,true);
               rx += Number(widths[ci]);
               ci++;
            }
         }
         var hw:Number = W - 28;
         var rc:uint = this.hzIconCol(HZ_RED);
         g.beginFill(dk ? 0x000000 : 0xFFFFFF,dk ? 0.14 : 0.12); g.drawRoundRect(14,by,hw,8,8,8); g.endFill();
         if(this.hz26EnGhost > hp + 0.002) { g.beginFill(rc,0.37); g.drawRoundRect(14,by,Math.max(8,hw * this.hz26EnGhost),8,8,8); g.endFill(); }
         if(hp > 0) { g.beginFill(rc,1); g.drawRoundRect(14,by,Math.max(8,hw * hp),8,8,8); g.endFill(); }
         this.hz26EnEmL.visible = emOn;
         this.hz26EnEmR.visible = emOn;
         if(emOn)
         {
            var bc:uint = this.hzIconCol(HZ_O2_BLUE);
            this.hzTxtTop(this.hz26EnEmL,emY - 4);
            var tl:Number = Number(e.fElectromagneticShockTimeLeft);
            this.hz26EnEmR.text = stun ? (!isNaN(tl) && tl > 0 ? "STUNNED " + tl.toFixed(1) + "s" : "STUNNED") : Math.round(Math.max(0,emF) * 100) + "%";
            this.hzTxtTop(this.hz26EnEmR,emY - 5);
            var ex:Number = 44;
            var ew:Number = W - 14 - 120 - ex;
            var ef:Number = stun ? 0 : Math.max(0,Math.min(1,emF));
            if(stun && !isNaN(tl))
            {
               var tm:Number = Number(e.fElectromagneticShockTimeMax);
               ef = tm > 0 ? Math.max(0,Math.min(1,tl / tm)) : 0;
            }
            g.beginFill(dk ? 0x000000 : 0xFFFFFF,dk ? 0.14 : 0.12); g.drawRoundRect(ex,emY,ew,5,5,5); g.endFill();
            if(ef > 0) { g.beginFill(bc,1); g.drawRoundRect(ex,emY,Math.max(5,ew * ef),5,5,5); g.endFill(); }
         }
         if(H != this.hz26EnH) { this.hz26EnH = H; this.hzSetSz(this.HorizonEnemy_mc,W,H); }
      }

      private function hz26EnemyTakes() : Boolean
      {
         return this.hzEnemyBarOn && this.HorizonEnemy_mc != null && this.hz26EnOn;
      }

      // ---------- stealth pill (above the crosshair) ----------
      private function hz26BuildStealth() : void
      {
         var c:Sprite = new Sprite();
         c.mouseEnabled = false; c.mouseChildren = false;
         this.HorizonStealth_mc = c;
         this.hz26StG = new Sprite(); c.addChild(this.hz26StG);
         this.hz26StT = this.hzT(c,"HIDDEN",50,7,160,14,"bd","col",1.8,"left",0xB2C0C7);
         this.hzChip13(this.hz26StT,"Stealth");
         this.hz26StD = this.hzT(c,"",50,26,160,10,"sb","mut",1.2);
         this.hzChip13(this.hz26StD,"Stealth");
         addChild(c);
         c.visible = false;
         this.hz26StW = HZ_ST_W;
         this.hz26StH = HZ_ST_H;
         this.hzSetSz(c,HZ_ST_W,HZ_ST_H);
      }

      private function hz26StPct(d:Object) : Number
      {
         var p:Number = Number(d.fPercent);
         var low:Number = Number(d.fLowestDetectionLevel);
         if(isNaN(low) || low == 0) { low = -20; }
         var sec:Number = Number(d.fSecondaryPercent);
         var m:int = int(d.uSneakMode);
         var nx:int = int(d.uNextSneakMode);
         // same mapping as the game's own meter (StealthMeter.SetStealthMeter)
         if(m == 0 && !isNaN(sec)) { p = (sec - low) / (0 - low) * 100; }
         else if((m == 2 || m == 3) && (nx == 4 || nx == 1))
         {
            if(d.bIsInCombat === true && !isNaN(sec)) { p = 100 - sec / low * 100; }
            else { p = 100 - p; }
         }
         if(isNaN(p)) { p = 0; }
         return Math.max(0,Math.min(100,p));
      }

      private function hz26StDraw(now:Number) : void
      {
         if(!this.hz26StG || !this.hz26StT || !this.hz26StD) { return; }
         var d:Object = this.hz26St;
         if(d == null || !this.hz26StOn) { d = {"uSneakMode":2,"fPercent":45,"uNextSneakMode":2}; }
         var m:int = int(d.uSneakMode);
         var names:Array = ["HIDDEN","DETECTED","CAUTION","EVADING","DANGER"];
         var cols:Array = [0xB2C0C7,0xFF8A5B,HZ_AMB,HZ_AMB,HZ_RED];
         if(m < 0 || m > 4) { m = 0; }
         var col:uint = this.hzIconCol(uint(cols[m]));
         var pct:Number = this.hz26StPct(d);
         var szT:int = this.hzChipSzOn(14,"Stealth",13);
         var szS:int = this.hzChipSzOn(10,"Stealth",13);
         var subTop:int = 7 + szT + 5;
         var h:Number = Math.max(HZ_ST_H,subTop + szS + 12);
         this.hz26StT.text = String(names[m]);
         this.hzTxtTint(this.hz26StT,uint(cols[m]));
         this.hzTxtTop(this.hz26StT,7);
         this.hz26StD.text = "DETECTION " + Math.round(pct) + "%";
         this.hzTxtTop(this.hz26StD,subTop);
         this.hz26StT.width = Math.max(160,this.hzTW(this.hz26StT) + 8);
         this.hz26StD.width = Math.max(160,this.hzTW(this.hz26StD) + 8);
         var w:Number = Math.max(HZ_ST_W,50 + Math.max(this.hzTW(this.hz26StT),this.hzTW(this.hz26StD)) + 18);
         if(w != this.hz26StW || h != this.hz26StH) { this.hzLaidOut = false; }
         this.hz26StW = w;
         this.hz26StH = h;
         this.hzSetSz(this.HorizonStealth_mc,w,h);
         var g:* = this.hz26StG.graphics;
         g.clear();
         var edge:int = m == 4 ? int(this.hzIconCol(HZ_RED)) : -1;
         this.hzPanel(g,w,h,24,-1,edge);
         var cy:Number = Math.round(h / 2);
         if(m == 4)
         {
            this.hz26StPh = 0.5 + 0.5 * Math.sin(now / 1000 * Math.PI * 2);
            g.lineStyle(1.5,col,0.25 + 0.6 * this.hz26StPh,true); g.beginFill(col,0.004); g.drawRoundRect(0.5,0.5,w - 1,h - 1,48,48); g.endFill(); g.lineStyle();
         }
         var dk:Boolean = this.hzDarkText();
         this.hzTileDisc(g,24,cy,18,-1);
         g.lineStyle(2.5,dk ? 0x000000 : 0xFFFFFF,0.15,true); g.drawCircle(24,cy,14); g.lineStyle();
         if(pct > 0.5)
         {
            g.lineStyle(2.5,col,1,true,"normal","none");
            var st:int = Math.max(2,int(Math.ceil(pct / 100 * 36)));
            var i:int = 0;
            while(i <= st)
            {
               var a:Number = -Math.PI / 2 + Math.PI * 2 * (pct / 100) * i / st;
               if(i == 0) { g.moveTo(24 + Math.cos(a) * 14,cy + Math.sin(a) * 14); } else { g.lineTo(24 + Math.cos(a) * 14,cy + Math.sin(a) * 14); }
               i++;
            }
            g.lineStyle();
         }
         // original eye glyph
         g.lineStyle(1.5,col,1,true);
         g.moveTo(16.5,cy); g.curveTo(24,cy - 7,31.5,cy); g.curveTo(24,cy + 7,16.5,cy);
         g.lineStyle();
         g.beginFill(col,1); g.drawCircle(24,cy,2.8); g.endFill();
      }

      // ---------- combat feedback: hit marker, kill X, damage numbers, direction ring ----------
      private function hz26BuildFx() : void
      {
         var c:Sprite = new Sprite();
         c.mouseEnabled = false; c.mouseChildren = false;
         this.HorizonFx_mc = c;
         this.hz26Ring = new Sprite(); c.addChild(this.hz26Ring);
         this.hz26Hit = new Sprite(); c.addChild(this.hz26Hit);
         this.hz26Kill = new Sprite(); c.addChild(this.hz26Kill);
         var i:int = 0;
         while(i < 8)
         {
            var s:Sprite = new Sprite();
            var t:TextField = this.hzT(s,"",-100,0,200,18,"bd","main",0.5,"center");
            var tag:TextField = this.hzT(s,"",-100,-14,200,9,"sb","col",1.2,"center",HZ_AMB);
            s.visible = false;
            c.addChild(s);
            this.hz26Nums.push({"s":s,"t":t,"tag":tag,"on":false,"t0":0,"x":0,"y":0});
            i++;
         }
         addChild(c);
      }

      private function hz26Center() : Point
      {
         var p:Point = new Point(960,540);
         try { p = new Point(HUDMenu.CENTER_GROUP_POINT.x,HUDMenu.CENTER_GROUP_POINT.y); } catch(err:Error) { }
         if(isNaN(p.x) || isNaN(p.y) || (p.x == 0 && p.y == 0)) { var vr:Rectangle = this.hzVis(); p = new Point(vr.x + vr.width / 2,vr.y + vr.height / 2); }
         return p;
      }

      private function hz26Spawn(o:Object, now:Number) : void
      {
         var slot:Object = null;
         var oldest:Object = null;
         for each(var n:Object in this.hz26Nums)
         {
            if(!n.on) { slot = n; break; }
            if(oldest == null || Number(n.t0) < Number(oldest.t0)) { oldest = n; }
         }
         if(slot == null) { slot = oldest; }
         if(slot == null) { return; }
         var lw:Number = 1920;
         var lh:Number = 1080;
         try { if(loaderInfo && loaderInfo.width > 0) { lw = loaderInfo.width; lh = loaderInfo.height; } } catch(errL:Error) { }
         var x:Number;
         var y:Number;
         if(o.bOnScreen === true && !isNaN(Number(o.fScreenPositionX)))
         {
            x = lw * Number(o.fScreenPositionX);
            y = lh * (1 - Number(o.fScreenPositionY));
         }
         else
         {
            var c:Point = this.hz26Center();
            x = c.x; y = c.y;
         }
         var t:int = int(o.uHitType);
         var crit:Boolean = t == 2;
         var em:Boolean = Boolean(o.bIsEM);
         var mit:Boolean = Boolean(o.bIsMitigated);
         var tf:TextField = TextField(slot.t);
         var tg:TextField = TextField(slot.tag);
         tf.text = String(Math.max(1,Math.round(Number(o.fDamage))));
         var col:* = crit ? HZ_AMB : (em ? HZ_O2_BLUE : (mit ? 0x8E9CA4 : null));
         this.hzTxtTint(tf,col);
         var tagS:String = crit ? "CRIT" : (mit ? "RESIST" : (em ? "EM" : ""));
         tg.text = tagS;
         tg.visible = tagS.length > 0;
         if(tagS.length > 0) { this.hzTxtTint(tg,crit ? HZ_AMB : (em ? HZ_O2_BLUE : 0x8E9CA4)); }
         var sc:Number = HZ_SCALE * this.hzHudScale * (crit ? 1.25 : 1);
         var s:Sprite = Sprite(slot.s);
         s.scaleX = s.scaleY = sc;
         slot.x = x + (Math.random() * 16 - 8);
         slot.y = y - 18;
         slot.t0 = now;
         slot.on = true;
         s.x = slot.x; s.y = slot.y; s.alpha = 1;
         s.visible = true;
      }

      private function hz26TickFx(now:Number, base:Boolean) : void
      {
         if(!this.HorizonFx_mc) { return; }
         var on:Boolean = base && !this.hzArrange;
         this.HorizonFx_mc.visible = on;
         var c:Point = this.hz26Center();
         var s:Number = HZ_SCALE * this.hzHudScale;
         // hit marker: four diagonal ticks, ~0.25 s; crit amber
         var hg:* = this.hz26Hit.graphics;
         hg.clear();
         var ht:Number = (now - this.hz26HitT) / 250;
         if(this.hzHitMarkOn && ht >= 0 && ht < 1)
         {
            var hc:uint = this.hz26HitCrit ? HZ_AMB : 0xFFFFFF;
            var r0:Number = 7 + 3 * ht;
            hg.lineStyle(2,hc,1 - ht,true,"normal","none");
            var k:int = 0;
            while(k < 4)
            {
               var a:Number = Math.PI / 4 + k * Math.PI / 2;
               hg.moveTo(Math.cos(a) * r0,Math.sin(a) * r0); hg.lineTo(Math.cos(a) * (r0 + 7),Math.sin(a) * (r0 + 7));
               k++;
            }
            hg.lineStyle();
         }
         this.hz26Hit.x = c.x; this.hz26Hit.y = c.y; this.hz26Hit.scaleX = this.hz26Hit.scaleY = s;
         // kill: red X + dot, ~0.6 s
         var kg:* = this.hz26Kill.graphics;
         kg.clear();
         var kt:Number = (now - this.hz26KillT) / 600;
         if(this.hzHitMarkOn && kt >= 0 && kt < 1)
         {
            var ka:Number = kt < 0.7 ? 1 : (1 - kt) / 0.3;
            var kr:Number = 9 + 4 * Math.min(1,kt * 3);
            kg.lineStyle(2.6,HZ_RED,ka,true,"normal","none");
            kg.moveTo(-kr,-kr); kg.lineTo(-kr + 7,-kr + 7); kg.moveTo(kr,-kr); kg.lineTo(kr - 7,-kr + 7);
            kg.moveTo(-kr,kr); kg.lineTo(-kr + 7,kr - 7); kg.moveTo(kr,kr); kg.lineTo(kr - 7,kr - 7);
            kg.lineStyle();
            kg.beginFill(HZ_RED,ka); kg.drawCircle(0,0,2); kg.endFill();
         }
         this.hz26Kill.x = c.x; this.hz26Kill.y = c.y; this.hz26Kill.scaleX = this.hz26Kill.scaleY = s;
         // floating numbers: rise ~40 units over 0.9 s and fade
         for each(var n:Object in this.hz26Nums)
         {
            if(!n.on) { continue; }
            var nt:Number = (now - Number(n.t0)) / 900;
            var sp:Sprite = Sprite(n.s);
            if(nt >= 1 || !this.hzDmgNumOn) { n.on = false; sp.visible = false; continue; }
            sp.y = Number(n.y) - 40 * nt;
            sp.alpha = nt < 0.6 ? 1 : (1 - nt) / 0.4;
         }
         // direction ring: arcs at iRotation (0 = ahead / top), 1.2 s each
         var rg:* = this.hz26Ring.graphics;
         rg.clear();
         var R:Number = 90;
         var any:Boolean = false;
         if(this.hzDirRingOn)
         {
            var keep:Array = [];
            for each(var ar:Object in this.hz26Arcs)
            {
               var at:Number = (now - Number(ar.t)) / 1200;
               if(at >= 1) { continue; }
               keep.push(ar);
               any = true;
               var al:Number = at < 0.6 ? 1 : (1 - at) / 0.4;
               var mid:Number = (Number(ar.r) - 90) * Math.PI / 180;
               rg.lineStyle(5,HZ_RED,0.9 * al,true,"normal","none");
               var j:int = 0;
               while(j <= 12)
               {
                  var aa:Number = mid - 0.38 + 0.76 * j / 12;
                  if(j == 0) { rg.moveTo(Math.cos(aa) * R,Math.sin(aa) * R); } else { rg.lineTo(Math.cos(aa) * R,Math.sin(aa) * R); }
                  j++;
               }
               rg.lineStyle();
            }
            this.hz26Arcs = keep;
            if(any) { rg.lineStyle(1,0xFFFFFF,0.12,true); rg.drawCircle(0,0,R); rg.lineStyle(); }
         }
         else { this.hz26Arcs = []; }
         this.hz26Ring.x = c.x; this.hz26Ring.y = c.y; this.hz26Ring.scaleX = this.hz26Ring.scaleY = s;
      }

      // ---------- vanilla counterparts: alpha 0 while ours is on (never removed); restored when switched off ----------
      private function hz26V(name:String) : DisplayObject
      {
         var d:DisplayObject = this.hz26VCache[name] as DisplayObject;
         if(d != null) { return d; }
         try
         {
            switch(name)
            {
               case "EnemyHealthHolder_mc": d = this.EnemyHealthHolder_mc; break;
               case "HitDamageBase_mc": d = this.HitDamageBase_mc; break;
               case "HitAndKillIndicator_mc": d = this.HitAndKillIndicator_mc; break;
               case "StealthMeter_mc": d = this.TopCenterGroup_mc ? Object(this.TopCenterGroup_mc).StealthMeter_mc as DisplayObject : null; break;
               case "DirectionalHitIndicatorBase_mc": d = this.CenterGroup_mc ? Object(this.CenterGroup_mc).DirectionalHitIndicatorBase_mc as DisplayObject : null; break;
            }
            if(d == null && this.hzFrameN % 90 == 5) { d = this.hzFindByName(this,name,0); }
         }
         catch(err:Error) { d = null; }
         if(d != null) { this.hz26VCache[name] = d; }
         return d;
      }

      private function hz26HideV(name:String, on:Boolean) : void
      {
         var d:DisplayObject = this.hz26V(name);
         if(d == null) { return; }
         try
         {
            if(on)
            {
               if(this.hz26VHid[name] == undefined) { this.hz26VHid[name] = d.alpha > 0 ? d.alpha : 1; }
               if(d.alpha != 0) { d.alpha = 0; }
            }
            else if(this.hz26VHid[name] != undefined)
            {
               // top-level clips follow the HUD opacity like their sibling CenterGroup_mc
               var ra:Number = Number(this.hz26VHid[name]);
               if(d.parent == this && this.CenterGroup_mc) { ra = this.CenterGroup_mc.alpha; }
               d.alpha = ra;
               delete this.hz26VHid[name];
            }
         }
         catch(err:Error) { }
      }

      private function hz26Vanilla() : void
      {
         var live:Boolean = !this.hzUserHidden;
         this.hz26HideV("EnemyHealthHolder_mc",live && this.hzEnemyBarOn && this.HorizonEnemy_mc != null);
         this.hz26HideV("StealthMeter_mc",live && this.hzStealthOn && this.HorizonStealth_mc != null && this.hz26St != null && this.hz26StOn);
         this.hz26HideV("HitAndKillIndicator_mc",live && this.hzHitMarkOn && this.HorizonFx_mc != null);
         this.hz26HideV("HitDamageBase_mc",live && this.hzDmgNumOn && this.HorizonFx_mc != null);
         this.hz26HideV("DirectionalHitIndicatorBase_mc",live && this.hzDirRingOn && this.HorizonFx_mc != null);
         var eq:Boolean = live && this.hzEqExtrasOn && this.hzShowAmmo && this.hz26EqRowS != null;
         for each(var n:String in ["EquippedGrenadeIcon_mc","EquippedGrenadeCount_mc","PowerBar_mc","PowerBarEmpty_mc","PowerBarIncrease_mc","VerticalDivider2_mc"]) { this.hz26HideV(n,eq); }
      }

      // ---------- per frame ----------
      private function hz26Tick() : void
      {
         if(!this.hz26Built) { return; }
         var now:Number = this.hz26Now();
         var base:Boolean = this.hzGroupVisible && !this.hzUserHidden;
         // stealth: vanilla rule (sneaking and the meter is on)
         var sd:Object = this.hz26St;
         this.hz26StOn = sd != null && sd.bSneaking === true && sd.bShowMeter === true;
         try { this.hz26Vanilla(); } catch(e0:Error) { }
         // enemy: shown while targeted (+0.4 s hold)
         this.hz26EnOn = this.hz26En != null && now - this.hz26EnT < 400;
         if(!this.hz26EnOn && now - this.hz26EnT > 1500) { this.hz26En = null; }
         try { if(this.HorizonEnemy_mc && (this.hz26EnOn || this.hzArrange) && this.HorizonEnemy_mc.visible) { this.hz26EnDraw(); } } catch(e1:Error) { if(this.HorizonEnemy_mc) { this.HorizonEnemy_mc.visible = false; } }
         try { if(this.HorizonStealth_mc && (this.hz26StOn || this.hzArrange) && this.HorizonStealth_mc.visible) { this.hz26StDraw(now); } } catch(e2:Error) { }
         // first frame a card turns on: draw before it shows
         try { if(this.HorizonEnemy_mc && this.hz26EnOn && !this.HorizonEnemy_mc.visible) { this.hz26EnDraw(); } } catch(e3:Error) { }
         try { if(this.HorizonStealth_mc && this.hz26StOn && !this.HorizonStealth_mc.visible) { this.hz26StDraw(now); } } catch(e4:Error) { }
         try { this.hz26TickRegen(now); } catch(e5:Error) { }
         try { this.hz26TickEdge(now,base); } catch(e6:Error) { if(this.HorizonEdge_mc) { this.HorizonEdge_mc.visible = false; } }
         try { this.hz26TickFx(now,base); } catch(e7:Error) { if(this.HorizonFx_mc) { this.HorizonFx_mc.visible = false; } }
         // XP ghost on the character bar fades after the toast
         if(this.hz26XpGA > 0)
         {
            if(now > this.hz26XpUntil) { this.hz26XpGA = Math.max(0,this.hz26XpGA - 0.04); }
            try { this.hz26CharBarsOnly(); } catch(e8:Error) { }
         }
         var sig:String = this.hz34C("Character") + "|" + this.hzArrange + "|" + this.hzCardColor + "|" + HZ_ACCENT + "|" + this.hzTextScale;
         if(sig != this.hz26ChSig) { this.hz26ChSig = sig; try { this.hz26CharSync(); this.hz26XpSync(); } catch(e9:Error) { } }
         if(!this.hzArrange) { try { this.hz26Vis(base); } catch(e10:Error) { } }
         try { this.hz27Tick(now); } catch(e11:Error) { }
         if(this.hzDebug && this.hzFrameN % 30 == 17) { this.hzDbgShow(); }
      }

      private function hz26CharBarsOnly() : void
      {
         var xf:Number = this.hz26XpN > 0 && !isNaN(this.hz26Xp) ? Math.max(0,Math.min(1,this.hz26Xp / this.hz26XpN)) : 0;
         var gF:Number = this.hz26XpGA > 0.01 ? this.hz26XpG : -1;
         if(this.hz26ChXpBar && this.hz26ChF.visible) { this.hz26Bar(this.hz26ChXpBar,HZ_CH_W - 14 - 76,6,xf,HZ_ACCENT,gF,this.hz26XpGA); }
         if(this.hz26ChsXpBar && this.hz26ChS.visible) { this.hz26Bar(this.hz26ChsXpBar,80,5,xf,HZ_ACCENT,gF,this.hz26XpGA); }
      }

      private function hz26Vis(base:Boolean) : void
      {
         var now:Number = this.hz26Now();
         if(this.HorizonChar_mc) { this.hzShow(this.HorizonChar_mc,base && !this.hz40Hide && this.hzShowChar && this.hz26CharOk && this.hz27CharRuleOk()); }
         if(this.HorizonEnemy_mc) { this.hzShow(this.HorizonEnemy_mc,base && this.hzEnemyBarOn && this.hz26EnOn); }
         if(this.HorizonStealth_mc) { this.hzShow(this.HorizonStealth_mc,base && this.hzStealthOn && this.hz26StOn); }
         if(this.HorizonXp_mc) { this.hzShow(this.HorizonXp_mc,base && !this.hz40Hide && this.hzXpToastOn && now < this.hz26XpUntil); }
         this.hz26OwCheck();
      }

      private function hz26Clips() : Array
      {
         return [this.HorizonChar_mc,this.HorizonEnemy_mc,this.HorizonStealth_mc,this.HorizonXp_mc].filter(this.hzNotNull);
      }

      private function hz26Redraw() : void
      {
         try { this.hz26CharSync(); } catch(e1:Error) { }
         try { this.hz26XpSync(); } catch(e2:Error) { }
         try { this.hz26VitExtras(); } catch(e3:Error) { }
         this.hz26EdgeSig = "";
      }

      // default spots (hzLayout v0.19 branch): character under the planet card, enemy bar under the compass,
      // stealth pill above the crosshair
      private function hz26LayoutDefaults(left:Number, top:Number, cx:Number, cmpY:Number, s:Number) : void
      {
         // v0.34: s = the planet card's factor (the character card sits under it); each card uses its own size
         var eh:Number = this.hzPillOn() ? this.hzPpH : 128;
         var sEn:Number = this.hz34S("Enemy");
         var sCm:Number = this.hz34S("Compass");
         var sSt:Number = this.hz34S("Stealth");
         if(this.HorizonChar_mc) { this.hzPlace(this.HorizonChar_mc,left,top + (eh + 10) * s); }
         if(this.HorizonEnemy_mc) { this.hzPlace(this.HorizonEnemy_mc,cx - HZ_EN_W * sEn / 2,cmpY + (this.hz34C("Compass") ? 60 : 104) * sCm); }
         if(this.HorizonStealth_mc)
         {
            var c:Point = this.hz26Center();
            this.hzPlace(this.HorizonStealth_mc,c.x - this.hz26StW * sSt / 2,c.y - 150 * sSt - this.hz26StH * sSt);
         }
      }

      // after the user layout: the XP toast sits beside the character card's XP row unless it was placed itself
      private function hz26LayoutAfter(s:Number) : void
      {
         if(!this.HorizonXp_mc || !this.HorizonChar_mc || this.hzLayHas("XpToast")) { return; }
         var cy:Number = this.HorizonChar_mc.y;
         for each(var e:Object in this.hzFades) { if(e.c == this.HorizonChar_mc) { cy = Number(e.base); } }
         var cw:Number = this.hz26ChW * s;   // s = the character card's factor
         var row:Number = this.hz34C("Character") ? 3 : 34;
         this.hzPlace(this.HorizonXp_mc,this.HorizonChar_mc.x + cw + 8 * s,cy + row * s);
      }

      private function hz26SnapTgs(v:Number) : Number
      {
         // v0.27: slider grid 0.8 - 1.6 in 0.025 steps
         if(isNaN(v)) { return 1.125; }
         return Math.round(Math.max(0.8,Math.min(1.6,v)) * 40) / 40;
      }

      // ---------- ini / settings ----------
      private function hz26Ini(k:String, bv:Boolean, nv:Number) : Boolean
      {
         switch(k)
         {
            case "showcharacter": this.hzShowChar = bv; break;
            case "edgepulse": this.hzEdgePulse = bv; break;
            case "xptoast": this.hzXpToastOn = bv; break;
            case "enemybar": this.hzEnemyBarOn = bv; break;
            case "stealthmeter": this.hzStealthOn = bv; break;
            case "hitmarkers": this.hzHitMarkOn = bv; break;
            case "damagenumbers": this.hzDmgNumOn = bv; break;
            case "directionring": this.hzDirRingOn = bv; break;
            case "regensliver": this.hzRegenOn = bv; break;
            case "equipmentextras": this.hzEqExtrasOn = bv; this.hz26EqChanged(); break;
            default: return this.hz27Ini(k,bv,nv);
         }
         return true;
      }

      private function hz26SetCur(o:Object) : void
      {
         o.ShowCharacter = this.hzShowChar;
         o.EdgePulse = this.hzEdgePulse;
         o.XpToast = this.hzXpToastOn;
         o.EnemyBar = this.hzEnemyBarOn;
         o.StealthMeter = this.hzStealthOn;
         o.HitMarkers = this.hzHitMarkOn;
         o.DamageNumbers = this.hzDmgNumOn;
         o.DirectionRing = this.hzDirRingOn;
         o.RegenSliver = this.hzRegenOn;
         o.EquipmentExtras = this.hzEqExtrasOn;
         try { this.hz27SetCur(o); } catch(err27:Error) { }
      }

      private function hz26SetLive(p:Object) : void
      {
         if(p.ShowCharacter != undefined) { this.hzShowChar = Boolean(p.ShowCharacter); }
         if(p.EdgePulse != undefined) { this.hzEdgePulse = Boolean(p.EdgePulse); }
         if(p.XpToast != undefined) { this.hzXpToastOn = Boolean(p.XpToast); }
         if(p.EnemyBar != undefined) { this.hzEnemyBarOn = Boolean(p.EnemyBar); }
         if(p.StealthMeter != undefined) { this.hzStealthOn = Boolean(p.StealthMeter); }
         if(p.HitMarkers != undefined) { this.hzHitMarkOn = Boolean(p.HitMarkers); }
         if(p.DamageNumbers != undefined) { this.hzDmgNumOn = Boolean(p.DamageNumbers); }
         if(p.DirectionRing != undefined) { this.hzDirRingOn = Boolean(p.DirectionRing); }
         if(p.RegenSliver != undefined) { this.hzRegenOn = Boolean(p.RegenSliver); }
         if(p.EquipmentExtras != undefined && this.hzEqExtrasOn != Boolean(p.EquipmentExtras)) { this.hzEqExtrasOn = Boolean(p.EquipmentExtras); this.hz26EqChanged(); }
         try { this.hz27SetLive(p); } catch(err27:Error) { }
         this.hz26OwCheck();
         try { this.hz26Vanilla(); } catch(err:Error) { }
      }

      private function hz26IniLines(a:Array, p:Object) : void
      {
         a.push("[Cards Extra]");
         a.push("; Character card: name, LV + XP bar, skill points, credits, mass / overweight (strip in compact mode)");
         a.push("ShowCharacter=" + this.hzB(p.ShowCharacter));
         a.push("; Enemy health bar at the top center (LV, name, %, legendary stars / modifiers, EM / stunned). Hides the vanilla bar.");
         a.push("EnemyBar=" + this.hzB(p.EnemyBar));
         a.push("; Stealth pill above the crosshair while sneaking. Hides the vanilla stealth meter.");
         a.push("StealthMeter=" + this.hzB(p.StealthMeter));
         a.push("; Equipment card: grenade count + selected Starborn power (icon, meter). Hides the vanilla grenade / power readout.");
         a.push("EquipmentExtras=" + this.hzB(p.EquipmentExtras));
         a.push("");
         a.push("[Effects]");
         a.push("; Screen-edge tint pulsing ~1 Hz: red below 15% health, amber below 15% oxygen (center untouched)");
         a.push("EdgePulse=" + this.hzB(p.EdgePulse));
         a.push("; +N XP toast beside the character card for ~2 s (gains close together are summed)");
         a.push("XpToast=" + this.hzB(p.XpToast));
         a.push("; Hit marker + kill X at the crosshair (hides the vanilla markers)");
         a.push("HitMarkers=" + this.hzB(p.HitMarkers));
         a.push("; Floating damage numbers (white, CRIT amber, EM blue, RESIST gray; hides the vanilla numbers)");
         a.push("DamageNumbers=" + this.hzB(p.DamageNumbers));
         a.push("; Damage direction ring around the crosshair (hides the vanilla arcs)");
         a.push("DirectionRing=" + this.hzB(p.DirectionRing));
         a.push("; Green healing sliver ahead of the health bar while health regenerates");
         a.push("RegenSliver=" + this.hzB(p.RegenSliver));
         a.push("");
      }

      // vitals warning state per row (0 health, 1 oxygen) -> stripe redraw only when it changes band
      private var hz26VnF0:Number = 1;
      private var hz26VnF1:Number = 1;
      private function hz26VnWarn(i:int, f:Number) : void
      {
         var old:Number = i == 0 ? this.hz26VnF0 : this.hz26VnF1;
         if(i == 0) { this.hz26VnF0 = f; } else { this.hz26VnF1 = f; }
         if(this.hz26Band(old) != this.hz26Band(f)) { try { this.hzVnDraw(); } catch(err:Error) { } }
      }

      private function hz26Band(v:Number) : int
      {
         return v < 0.15 ? 2 : (v < 0.35 ? 1 : 0);
      }


      // ===================== v0.27 =====================
      // follower marker color (COMPASS tab), CHARACTER card rule (RULES tab), quest sub-lines, PersonalAlertsData
      private static const HZ_FOL_PAL:Array = [0x5CFF7A,0xC6FF4A,0xFFD24A,0xFF6BD6,0xF4F8FA,0x5EE3A1];
      private static const HZ_FOL_NAMES:Array = ["BRIGHT GREEN","LIME","GOLD","PINK","WHITE","MINT"];
      public var hzFolColor:int = 0;
      public var hzRuleChar:int = 0;
      private var hz27CharSecs:Number = 8;
      private var hz27CharEvUntil:Number = 0;
      private var hz27LastLv:int = -1;
      private var hz27LastSp:int = -1;
      private var hz27LastCr:Number = NaN;
      private var hz27BioHid:Boolean = false;
      private var hz27ExitOn:Boolean = false;
      private var hz27Alerts:Array = [];
      // quest tracker: sticky main objective + up to 3 sub-lines
      private var hz27QMain:String = "";
      private var hz27QMainT:Number = 0;
      private var hz27QMainDist:Number = NaN;
      private var hz27QMainOff:Boolean = false;
      private var hz27QObjs:Array = [];
      private var hz27QSubs:Array = [];
      private var hz27QL:Array = [];
      private var hz27QLD:Array = [];
      private var hz27QH:Number = 78;

      private function hz27FolCol() : uint
      {
         // v0.30: the exact FollowerColor (no dark-text darkening; the marker has its own dark edge), guarded
         try
         {
            if(HZ_FOL_PAL == null || HZ_FOL_PAL.length == 0) { return 0x5CFF7A; }
            var i:int = Math.max(0,Math.min(HZ_FOL_PAL.length - 1,this.hzFolColor));
            return uint(HZ_FOL_PAL[i]);
         }
         catch(err:Error) { }
         return 0x5CFF7A;
      }

      // ---------- CHARACTER rule ----------
      private function hz27CharEvent() : void
      {
         this.hz27CharEvUntil = this.hz26Now() + Math.max(2,Math.min(60,this.hz27CharSecs)) * 1000;
      }

      // 0 always, 7 XP / level / credits / skill point (N s, then fade), 8 overweight, 9 either, 1 combat only, 2 hide in ship
      private function hz27CharRuleOk() : Boolean
      {
         var ev:Boolean = this.hz26Now() < this.hz27CharEvUntil;
         switch(this.hzRuleChar)
         {
            case 7: return ev;
            case 8: return this.hz26Over;
            case 9: return ev || this.hz26Over;
         }
         return this.hzRuleOk(this.hzRuleChar);
      }

      // the overweight chip moves to Afflictions unless the character card shows while overweight
      private function hz27CharCoversOw() : Boolean
      {
         return this.hzRuleChar == 0 || this.hzRuleChar == 8 || this.hzRuleChar == 9;
      }

      // events fire on changes after the first reading only (no event on load)
      private function hz27CharData(lv:int, sp:int, cr:Number) : void
      {
         if(lv >= 0)
         {
            if(this.hz27LastLv >= 0 && lv > this.hz27LastLv) { this.hz27CharEvent(); }
            this.hz27LastLv = lv;
         }
         if(sp >= 0)
         {
            if(this.hz27LastSp >= 0 && sp > this.hz27LastSp) { this.hz27CharEvent(); }
            this.hz27LastSp = sp;
         }
         if(!isNaN(cr))
         {
            if(!isNaN(this.hz27LastCr) && Math.abs(cr - this.hz27LastCr) >= 1) { this.hz27CharEvent(); }
            this.hz27LastCr = cr;
         }
      }

      // ---------- Screen margin ----------
      // compass top follows the margin (28 at the default 40)
      private function hz27CmpTop() : Number
      {
         return Math.max(28,this.hzMargin - 12);
      }

      // margin used to clamp a card placed in ARRANGE CARDS (floating crosshair cards are exempt)
      private function hz27LayM(lk:String, vert:Boolean) : Number
      {
         if(lk == "Stealth" || lk == "XpToast") { return 0; }
         if(lk == "Compass" && vert) { return Math.min(this.hzMargin,28); }
         return this.hzMargin;
      }

      private function hz27Clamp(v:Number, lo:Number, hi:Number) : Number
      {
         if(hi < lo) { return lo; }
         return Math.max(lo,Math.min(hi,v));
      }

      // ---------- Quest tracker ----------
      private function hz27IsOpt(t:String) : Boolean
      {
         if(t == null) { return false; }
         var re:RegExp = new RegExp("\\(\\s*optional\\s*\\)|^\\s*optional\\b","i");
         return re.test(t);
      }

      private function hz27OptStrip(t:String) : String
      {
         var r1:RegExp = new RegExp("\\s*\\(\\s*optional\\s*\\)\\s*","ig");
         var r2:RegExp = new RegExp("^\\s*optional\\s*[:\\-]?\\s*","i");
         var r3:RegExp = new RegExp("^\\s+|\\s+$","g");
         var s:String = t.replace(r1," ");
         s = s.replace(r2,"");
         return s.replace(r3,"");
      }

      private function hz27QKeep(o:Object) : void
      {
         this.hz27QMain = String(o.strText);
         this.hz27QMainT = this.hz26Now();
         this.hz27QMainDist = Number(o.fDistanceToPlayer);
         this.hz27QMainOff = uint(o.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_QUEST_OFFPLANET;
      }

      // main objective: keep the current one while its marker is listed (and for 3 s gaps); otherwise the quest's
      // first open objective (QuestUpdateData order), then the first non-optional on-planet marker, then the first
      private function hz27PickMain(list:Array) : Object
      {
         var now:Number = this.hz26Now();
         var o:Object = null;
         if(this.hz27QMain.length > 0)
         {
            for each(o in list) { if(String(o.strText) == this.hz27QMain) { this.hz27QKeep(o); return o; } }
            if(now - this.hz27QMainT < 3000)
            {
               var held:Object = {"strText":this.hz27QMain,"fDistanceToPlayer":this.hz27QMainDist,"hzHeld":true};
               held.uiMarkerIconType = this.hz27QMainOff ? MapMarkerUtils.MIT_MARKER_QUEST_OFFPLANET : MapMarkerUtils.MIT_MARKER_QUEST;
               return held;
            }
         }
         var pick:Object = null;
         for each(var ob:String in this.hz27QObjs)
         {
            if(pick != null || this.hz27IsOpt(ob)) { continue; }
            for each(o in list) { if(pick == null && String(o.strText) == ob) { pick = o; } }
         }
         if(pick == null)
         {
            for each(o in list)
            {
               if(pick == null && !this.hz27IsOpt(String(o.strText)) && uint(o.uiMarkerIconType) != MapMarkerUtils.MIT_MARKER_QUEST_OFFPLANET) { pick = o; }
            }
         }
         if(pick == null && list.length > 0) { pick = list[0]; }
         if(pick != null) { this.hz27QKeep(pick); } else { this.hz27QMain = ""; }
         return pick;
      }

      private function hz27QSubSort(a:Object, b:Object) : int
      {
         if(Boolean(a.opt) != Boolean(b.opt)) { return a.opt ? 1 : -1; }
         var ta:String = String(a.t).toLowerCase();
         var tb:String = String(b.t).toLowerCase();
         return ta < tb ? -1 : (ta > tb ? 1 : 0);
      }

      // other objectives of the tracked quest as sub-lines (markers first, then open objectives without a marker)
      private function hz27QBuildSubs(list:Array, active:Object) : void
      {
         var subs:Array = [];
         var texts:Array = [];
         var mt:String = active ? String(active.strText) : "";
         for each(var o:Object in list)
         {
            var t:String = String(o.strText);
            texts.push(t);
            if(t == mt) { continue; }
            var off:Boolean = uint(o.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_QUEST_OFFPLANET;
            subs.push({"t":this.hz27OptStrip(t),"opt":this.hz27IsOpt(t),"d":off ? "OFF PLANET" : this.hzFmtDist(Number(o.fDistanceToPlayer))});
         }
         for each(var ob:String in this.hz27QObjs)
         {
            if(ob == mt || texts.indexOf(ob) >= 0) { continue; }
            subs.push({"t":this.hz27OptStrip(ob),"opt":this.hz27IsOpt(ob),"d":""});
         }
         subs.sort(this.hz27QSubSort);
         while(subs.length > 3) { subs.pop(); }
         this.hz27QSubs = subs;
      }

      // QuestUpdateData: open objectives of the active quest (ObjectiveDataA, same fields as the game's ObjectivesList)
      private function hz27QSetObjs(q:Object) : void
      {
         var a:Array = q.ObjectiveDataA as Array;
         if(!a) { return; }
         this.hz26Log("QuestObjectives",a);
         var out:Array = [];
         for each(var ob:Object in a)
         {
            if(!ob || ob.strObjectiveText == null) { continue; }
            if(ob.bCompleted === true || ob.bFailed === true || ob.bDormant === true) { continue; }
            var s:String = String(ob.strObjectiveText);
            if(s.length > 0 && out.indexOf(s) < 0) { out.push(s); }
         }
         this.hz27QObjs = out;
      }

      private function hz27QBuild(p:Sprite) : void
      {
         var i:int = 0;
         while(i < 3)
         {
            var tf:TextField = this.hzT(p,"",74,60 + i * 20,HZ_Q19_W - 74 - 14,11,"rg","mut",0.2);
            var td:TextField = this.hzT(p,"",HZ_Q19_W - 14 - 80,60 + i * 20,80,11,"sb","mut",0.5,"right");
            tf.visible = false;
            td.visible = false;
            this.hz27QL.push(tf);
            this.hz27QLD.push(td);
            i++;
         }
      }

      private function hz27QLayout(hasSub:Boolean) : void
      {
         if(!this.hzQ19T || this.hz27QL.length < 3) { return; }
         var n:int = Math.min(3,this.hz27QSubs.length);
         var y0:Number = hasSub ? 60 : 38;
         var i:int = 0;
         while(i < 3)
         {
            var tf:TextField = this.hz27QL[i];
            var td:TextField = this.hz27QLD[i];
            var on:Boolean = i < n;
            tf.visible = on;
            td.visible = false;
            if(on)
            {
               var s:Object = this.hz27QSubs[i];
               var d:String = String(s.d);
               td.text = d;
               td.visible = d.length > 0;
               this.hzTxtTop(td,y0 + i * 20);
               var lw:Number = HZ_Q19_W - 74 - 14 - (d.length > 0 ? this.hzTW(td) + 10 : 0);
               this.hzFitText(tf,(s.opt ? "+ OPTIONAL  " : "+  ") + String(s.t),lw);
               this.hzTxtTop(tf,y0 + i * 20);
            }
            i++;
         }
         var h:Number = n > 0 ? Math.max(78,y0 + n * 20 + 8) : 78;
         if(h != this.hz27QH)
         {
            this.hz27QH = h;
            this.hzSetSz(this.HorizonQuest_mc,HZ_Q19_W,h);
            this.hzLaidOut = false;
            this.hzQDraw19();
         }
      }

      // ---------- Afflictions: PersonalAlertsData (the vanilla red-ring popup on the left) ----------
      private function hz27OnPersAlerts(e:FromClientDataEvent) : *
      {
         try
         {
            var d:Object = e.data;
            if(!d) { return; }
            this.hz26Log("PersonalAlertsData",d);
            var a:Array = d.aPersonalAlerts as Array;
            if(!a || a.length == 0) { return; }
            this.hz26Log("aPersonalAlerts[0]",a[0]);
            var now:Number = this.hz26Now();
            var rs:RegExp = new RegExp("_(Negative|Positive)$");
            var rp:RegExp = new RegExp("_Positive$");
            for each(var o:Object in a)
            {
               if(!o) { continue; }
               var icon:String = o.sEffectIcon != null ? String(o.sEffectIcon) : "";
               var txt:String = o.sAlertText != null ? String(o.sAlertText) : "";
               var sub:String = o.sAlertSubText != null ? String(o.sAlertSubText) : "";
               var cat:String = icon.replace(rs,"");
               if(rp.test(icon))
               {
                  // a positive alert for a body system (treated / cured): drop that system's alerts
                  var kept:Array = [];
                  for each(var x1:Object in this.hz27Alerts) { if(String(x1.cat) != cat) { kept.push(x1); } }
                  this.hz27Alerts = kept;
                  continue;
               }
               if(icon.length == 0 && txt.length == 0) { continue; }
               var found:Boolean = false;
               for each(var x2:Object in this.hz27Alerts)
               {
                  if(String(x2.cat) == cat && String(x2.txt) == txt) { x2.t = now; x2.sub = sub; found = true; }
               }
               if(!found) { this.hz27Alerts.push({"cat":cat,"icon":icon,"txt":txt,"sub":sub,"t":now}); }
            }
            while(this.hz27Alerts.length > 6) { this.hz27Alerts.shift(); }
            if(this.hzAfNew) { this.hzAfSync(); }
         }
         catch(err:Error) { }
      }

      // alert entries replace the plain effect chip of the same body system; an alert stays while that system is
      // listed in PersonalEffectsData, otherwise 90 s
      private function hz27PersMerge(pers:Array) : Array
      {
         var now:Number = this.hz26Now();
         var cats:Array = [];
         for each(var p:Object in pers) { cats.push(String(p.cat)); }
         var keep:Array = [];
         for each(var a:Object in this.hz27Alerts)
         {
            if(cats.indexOf(String(a.cat)) < 0 && now - Number(a.t) > 90000) { continue; }
            keep.push(a);
         }
         this.hz27Alerts = keep;
         var out:Array = [];
         var used:Array = [];
         for each(var b:Object in keep)
         {
            var sys:String = this.hzPretty(String(b.icon));
            var nm:String = String(b.txt).length > 0 ? String(b.txt) : "Affliction";
            var sb:String = String(b.sub).length > 0 ? String(b.sub) : sys;
            if(sb.toLowerCase() == nm.toLowerCase()) { sb = (sys.length > 0 && sys.toLowerCase() != nm.toLowerCase()) ? sys : ""; }
            if(nm.length == 0) { continue; }
            out.push({"key":"a:" + String(b.cat) + ":" + nm,"name":nm,"sub":sb.length > 0 ? sb : null,"kind":"injury","env":false,"cat":String(b.cat)});
            used.push(String(b.cat));
         }
         for each(var q:Object in pers) { if(used.indexOf(String(q.cat)) < 0) { out.push(q); } }
         if(this.hzDebug)
         {
            var names:Array = [];
            for each(var r:Object in out) { names.push(String(r.name) + (r.sub ? " / " + String(r.sub) : "")); }
            this.hz26Dbg["Afflictions"] = "effects=" + pers.length + " alerts=" + keep.length + " -> " + names.join(", ");
         }
         return out;
      }

      private function hz27PersSafe() : Array
      {
         try { return this.hz27PersMerge(this.hzAfPers); } catch(err:Error) { }
         return this.hzAfPers;
      }

      // vanilla left-side affliction popup (BottomLeftGroup BioAlertText / BioCondition_mc / BioAlertBG_mc):
      // hidden while our Afflictions card is on, restored when it is off. Never removed.
      // r4: by visible, never alpha (the BottomLeftGroup timeline animates their alpha). The game never writes their visible, so
      // the restore is visible = true; BioCondition_mc / BioAlertBG_mc stay to the vanilla watch hide while that is on.
      private function hz27BioHide() : void
      {
         if(!this.hzBlg) { return; }
         var want:Boolean = this.hzShowAfflictions && this.hzHideVanillaWatch && !this.hzUserHidden;
         if(!want && !this.hz27BioHid) { return; }
         for each(var n:String in ["BioAlertText","BioCondition_mc","BioAlertBG_mc"])
         {
            var c:DisplayObject = this.hzBlg.getChildByName(n);
            if(!c) { continue; }
            if(want) { if(c.visible) { c.visible = false; } }
            else if(n == "BioAlertText" || !this.hzHideVanillaWatch) { c.visible = true; }
         }
         this.hz27BioHid = want;
      }

      // v0.31: the red ring on the left is BottomLeftGroup.EnemyDetectionAnim_mc (vanilla plays "Open" while in combat
      // and detected, so it shows up together with low health). It was left out of the watch hide on purpose before
      // Horizon had its own combat cues; the stealth pill, enemy bar and EdgePulse cover it now. Hidden by alpha
      // only (vanilla drives it with gotoAndPlay / gotoAndStop and never sets alpha), re-applied every frame and
      // after the timeline (exitFrame), never removed; restored when the vanilla watch is shown again.
      private var hz31DetHid:Boolean = false;

      private function hz31DetHide() : void
      {
         if(!this.hzBlg) { return; }
         var want:Boolean = this.hzHideVanillaWatch && !this.hzUserHidden;
         if(!want && !this.hz31DetHid) { return; }
         var c:DisplayObject = this.hzBlg.getChildByName("EnemyDetectionAnim_mc");
         if(c) { c.alpha = want ? 0 : 1; }
         this.hz31DetHid = want;
      }

      // after the timeline built this frame's children (alerts re-create instances on keyframes)
      private function hz27OnExit(e:Event) : void
      {
         try { this.hz27BioHide(); } catch(err:Error) { }
         try { this.hz31DetHide(); } catch(err31d:Error) { }
         try { this.hz41LocHide(); } catch(err41l:Error) { }   // r3
         try { this.hz41QmHide(); } catch(err41q:Error) { }    // r3
      }

      private function hz27Build() : void
      {
         try { BSUIDataManager.Subscribe("PersonalAlertsData",this.hz27OnPersAlerts); } catch(s1:Error) { }
         try { addEventListener("exitFrame",this.hz27OnExit); this.hz27ExitOn = true; } catch(s2:Error) { }
      }

      private function hz27Tick(now:Number) : void
      {
         try { this.hz27BioHide(); } catch(e1:Error) { }
         try { this.hz31DetHide(); } catch(err31d:Error) { }
         if(this.hz27Alerts.length > 0 && this.hzFrameN % 60 == 23) { try { if(this.hzAfNew) { this.hzAfSync(); } } catch(e2:Error) { } }
      }

      // ---------- ini / settings ----------
      private function hz27Ini(k:String, bv:Boolean, nv:Number) : Boolean
      {
         switch(k)
         {
            case "characterrule": if(!isNaN(nv)) { this.hzRuleChar = this.hzRuleFix("CharacterRule",int(nv)); } break;
            case "charactershowseconds": if(!isNaN(nv)) { this.hz27CharSecs = Math.max(2,Math.min(60,nv)); } break;
            case "followercolor":
            case "followercolour": if(!isNaN(nv)) { this.hzFolColor = Math.max(0,Math.min(HZ_FOL_PAL.length - 1,int(nv))); } break;
            case "equipmentstyle": break;   // v0.27: removed, the Equipment card is always the new layout
            default: return this.hz30Ini(k,bv,nv);
         }
         return true;
      }

      private function hz27SetCur(o:Object) : void
      {
         o.CharacterRule = this.hzRuleChar;
         o.FollowerColor = this.hzFolColor;
         o.HoverScale = this.hz30Hover;
      }

      private function hz27SetLive(p:Object) : void
      {
         if(p.CharacterRule != undefined && !isNaN(Number(p.CharacterRule))) { this.hzRuleChar = this.hzRuleFix("CharacterRule",int(p.CharacterRule)); }
         if(p.FollowerColor != undefined && !isNaN(Number(p.FollowerColor)) && this.hzFolColor != int(p.FollowerColor))
         {
            this.hzFolColor = Math.max(0,Math.min(HZ_FOL_PAL.length - 1,int(p.FollowerColor)));
            try { this.hzDrawCompassMarkers(); } catch(err:Error) { }
         }
         if(p.HoverScale != undefined && !isNaN(Number(p.HoverScale)))
         {
            var nhv:Number = this.hz34ScClamp(p.HoverScale);
            if(nhv != this.hz30Hover) { this.hz30Hover = nhv; this.hzT19Sig = ""; }
         }
         this.hz26OwCheck();
      }


      // ===================== v0.28 =====================
      // grenade chip (grenade_placement_v1 option A): glyph + "xN" pill, hidden at 0
      private var hz28GX:Number = NaN;
      private var hz28GY:Number = 0;

      // grenades to show: the count (0 = hidden); ARRANGE sample shows 3 while there is no data
      private function hz28GrenN() : int
      {
         if(!this.hzEqExtrasOn) { return 0; }
         if(this.hzArrange && this.hz26Gren < 0 && !(this.hz26SPMax > 0)) { return 3; }
         return this.hz26GrenOn() ? this.hz26Gren : 0;
      }

      // chip width for layout A (0 when hidden or in compact mode)
      private function hz28ChipW(cm:Boolean) : Number
      {
         if(cm) { return 0; }
         var n:int = this.hz28GrenN();
         if(n <= 0) { return 0; }
         if(!this.hz26EqRowS) { this.hz26BuildEq(); }
         if(!this.hz26GrenT) { return 0; }
         this.hz26GrenT.text = "x" + n;
         return Math.round(20 + this.hzTW(this.hz26GrenT) + 9);
      }

      private function hz28Chip(g:*, x:Number, y:Number, n:int) : Number
      {
         var h:Number = 18;
         var col:uint = this.hzIconCol(HZ_ACCENT);
         x = Math.round(x);
         y = Math.round(y);
         this.hz26GrenT.text = "x" + n;
         var cw:Number = Math.round(20 + this.hzTW(this.hz26GrenT) + 9);
         g.lineStyle(1,col,0.6,true);
         g.beginFill(col,0.13);
         g.drawRoundRect(x,y,cw,h,h,h);
         g.endFill();
         g.lineStyle();
         this.hz26Grenade(g,x + 11,y + h / 2 - 1.5,col,0.62);
         this.hz26GrenT.x = x + 19;
         this.hzTxtTop(this.hz26GrenT,this.hzCapTop(this.hz26GrenT,y + h / 2));
         this.hz26GrenT.visible = true;
         return cw;
      }


      // ===================== v0.29 =====================
      // settings "r" row: option index for a stored value (rows with "ids" list the values in display order)
      private function hz29OptIdx(r:Object, v:*) : int
      {
         if(r == null) { return 0; }
         if(r.ids != undefined && r.ids != null)
         {
            var i:int = (r.ids as Array).indexOf(int(v));
            return i < 0 ? 0 : i;
         }
         return int(v);
      }


      // ===================== v0.31 =====================
      // Planet card width: 392 (strip 490); at very large HudScale the default top-left spot is capped so the card
      // keeps 16 px (1080p) from the centered compass, never below the v0.30 widths (336 / 420).
      private var hz31PpMax:Number = 9999;

      private function hz31PpWidth(cm:Boolean) : Number
      {
         var w:Number = cm ? HZ_PP_CW : HZ_PP_W;
         var lo:Number = cm ? 420 : 336;
         var moved:Boolean = this.hzLay != null && this.hzLay["Planet"] != null;
         if(!moved && this.hz31PpMax < w) { w = Math.max(lo,Math.floor(this.hz31PpMax)); }
         return w;
      }

      private function hz31PpFit(left:Number, cx:Number, s:Number, sc:Number = -1) : void
      {
         if(sc <= 0) { sc = s; }   // v0.34: s = planet card factor, sc = compass factor
         if(s <= 0 || !this.hzShowCompass) { this.hz31PpSetMax(9999); return; }
         var cw:Number = this.hzCmpW19 > 0 ? this.hzCmpW19 : 640;
         var cmpL:Number = cx - cw * sc / 2;
         this.hz31PpSetMax((cmpL - 16 * s - left) / s);
      }

      private function hz31PpSetMax(v:Number) : void
      {
         if(isNaN(v)) { v = 9999; }
         if(Math.abs(v - this.hz31PpMax) < 1) { return; }
         var before:Number = this.hzPpW;
         this.hz31PpMax = v;
         if(this.hzPlanPill && this.hz31PpWidth(this.hz34C("Planet")) != before) { this.hzPpLayout(); }
      }

      // ---- v0.31 F11 preview: stand-in container window (original layout, sample text) ----
      private static const HZ31_PC_W:Number = 300;
      private static const HZ31_PC_H:Number = 236;
      private var hz31Pc:Sprite = null;
      private var hz31PcT:Object = null;

      private function hz31PvCont(pv:Sprite, P:Object) : Sprite
      {
         if(pv == null) { return null; }
         if(this.hz31Pc == null)
         {
            var c:Sprite = new Sprite();
            c.mouseEnabled = false; c.mouseChildren = false;
            var cg:Sprite = new Sprite(); c.addChild(cg);
            var o:Object = {"g":cg,"rows":[]};
            o.h = this.hz31PcTf(c,"STORAGE CRATE",18,12,190,16,"sb","main",2);
            this.hzHdr19(o.h);
            o.cnt = this.hz31PcTf(c,"6 ITEMS",HZ31_PC_W - 14 - 90,15,90,11,"sb","mut",1,"right");
            var names:Array = ["Med Pack","Ammo: 7.77mm","Aluminum","Frag Grenade","Data Slate"];
            var vals:Array = ["x3","x120","x14","x2","x1"];
            var i:int = 0;
            while(i < names.length)
            {
               var y:Number = 50 + i * 28;
               var n:TextField = this.hz31PcTf(c,String(names[i]),26,y + 6,180,13,"rg","main",0.3);
               var v:TextField = this.hz31PcTf(c,String(vals[i]),HZ31_PC_W - 16 - 70,y + 6,70,13,"sb","mut",0.4,"right");
               o.rows.push([n,v]);
               i++;
            }
            o.k1 = this.hz31PcTf(c,"E",0,0,40,12,"bd","col",0);
            o.l1 = this.hz31PcTf(c,"TAKE",0,0,80,12,"sb","main",1.6);
            o.k2 = this.hz31PcTf(c,"R",0,0,40,12,"bd","col",0);
            o.l2 = this.hz31PcTf(c,"TAKE ALL",0,0,90,12,"sb","main",1.6);
            o.k3 = this.hz31PcTf(c,"T",0,0,40,12,"bd","col",0);
            o.l3 = this.hz31PcTf(c,"TRANSFER",0,0,90,12,"sb","main",1.6);
            o.ov = new Sprite(); c.addChild(o.ov);
            this.hz31Pc = c;
            this.hz31PcT = o;
         }
         var pc:Sprite = this.hz31Pc;
         if(pc.parent != pv) { pv.addChildAt(pc,0); }
         var t:Object = this.hz31PcT;
         var g:* = Sprite(t.g).graphics;
         g.clear();
         var W:Number = HZ31_PC_W;
         var H:Number = HZ31_PC_H;
         var opS:Number = this.hzCardOpacity;
         this.hzCardOpacity = P.ContainerOpacity != undefined ? Number(P.ContainerOpacity) : this.hzContOpacity;
         this.hzPanel(g,W,H,18,-1,-1);
         this.hzCardOpacity = opS;
         var acc:uint = this.hzIconCol(HZ_ACCENT);
         g.beginFill(acc,1); g.drawRoundRect(5,8,3,H - 16,3,3); g.endFill();
         this.hzT19Line(g,40,W,false);
         // rows, the second one selected
         var i2:int = 0;
         while(i2 < t.rows.length)
         {
            var ry:Number = 50 + i2 * 28;
            var sel:Boolean = i2 == 1;
            if(sel)
            {
               g.beginFill(acc,0.16); g.drawRoundRect(12,ry,W - 24,26,10,10); g.endFill();
               g.beginFill(acc,1); g.drawRoundRect(14,ry + 6,3,14,3,3); g.endFill();
            }
            var rn:TextField = TextField(t.rows[i2][0]);
            var rv:TextField = TextField(t.rows[i2][1]);
            this.hzTxtTop(rn,this.hzCapTop(rn,ry + 13));
            this.hzTxtTop(rv,this.hzCapTop(rv,ry + 13));
            this.hzTxtTint(rn,sel ? null : 0xC4D2D9);
            i2++;
         }
         // divider + take / transfer bar
         var by:Number = 50 + t.rows.length * 28 + 6;
         this.hzT19Line(g,by,W,false);
         var ov:* = Sprite(t.ov).graphics;
         ov.clear();
         var x:Number = 18;
         var cy:Number = by + 22;
         for each(var pr:Array in [[t.k1,t.l1],[t.k2,t.l2],[t.k3,t.l3]])
         {
            var kt:TextField = TextField(pr[0]);
            var lt:TextField = TextField(pr[1]);
            this.hzTxtTint(kt,acc);
            var kw:Number = Math.max(24,Math.round(this.hzTW(kt) + 14));
            this.hzKeycap(g,x,cy - 11,kw,22,acc,1,ov);
            kt.width = Math.round(this.hzTW(kt) + 5);
            kt.x = Math.round(x + (kw - this.hzTW(kt)) / 2 - 2); this.hzTxtTop(kt,this.hzCapTop(kt,cy));
            lt.x = Math.round(x + kw + 6); this.hzTxtTop(lt,this.hzCapTop(lt,cy));
            lt.width = Math.round(this.hzTW(lt) + 6);
            x = Math.round(x + kw + 6 + this.hzTW(lt) + 14);
         }
         return pc;
      }

      private function hz31PcTf(p:Sprite, txt:String, x:Number, y:Number, w:Number, fs:Number, face:String, tone:String, ls:Number, align:String = "left") : TextField
      {
         var t:TextField = this.hzT(p,txt,x,y,w,fs,face,tone,ls,align);
         t.text = txt;
         return t;
      }

      // ---- v0.31 afflictions: chips sized from the measured text ----
      private static const HZ31_AF_MINW:Number = 210;   // was 190
      private static const HZ31_AF_TX:Number = 48;      // icon disc 8-40 + 8 px gap
      private static const HZ31_AF_MAXW:Number = 440;   // beyond this the text gets an ellipsis
      private var hz31AfLast:Array = null;

      // returns the text width the chip must hold (label / sub-line), after the final format and any ellipsis
      // ===================== v0.31: Comms (COMMS tab, [Comms] / [Scanner] keys, Arrange proxies) =====================
      // Defaults = COMMS_BUILD_SPEC_v031.md 6.1 / 6.2 and COMMS_DIALOGUE_ADDENDUM_v031.md 2. t: b 0/1, f float, i int, s string.
      // sec: the ini section the key is written to. These keys are read by the hudmessagesmenu / dialoguemenu patches.
      private static const HZ31_KEYS:Array = [
         ["Subtitles","b",1,0,1,"comms"],["SubAutoPause","b",1,0,1,"comms"],["SubSize","f",1,0.7,1.8,"comms"],["SubWidth","i",50,30,90,"comms"],
         ["SubBgOpacity","f",0.7,0,1,"comms"],["SubPosition","i",0,0,2,"comms"],["SubOffsetY","i",0,-300,300,"comms"],["SubAlign","i",0,0,1,"comms"],
         ["SubTextColor","i",-1,-1,13,"comms"],["SubTextHex","s","",0,0,"comms"],["SubCard","b",1,0,1,"comms"],["SubOffsetX","i",0,-600,600,"comms"],
         ["ShowSpeaker","b",1,0,1,"comms"],["SpeakerColor","i",-1,-1,13,"comms"],["SpeakerHex","s","",0,0,"comms"],["SpeakerCard","b",1,0,1,"comms"],
         ["KeepInDialogue","b",1,0,1,"comms"],["FixedInDialogue","b",1,0,1,"comms"],["SubMaxLines","i",3,2,5,"comms"],["SubFont","i",-1,-1,3,"comms"],
         ["MissionToast","b",1,0,1,"comms"],["MissionToastTime","i",5,2,15,"comms"],["MissionToastMax","i",3,1,5,"comms"],["MissionToastSound","b",1,0,1,"comms"],["MissionToastScale","z",-1,0.6,1.6,"comms"],["ReactionCard","b",1,0,1,"comms"],
         ["Dialogue","b",1,0,1,"comms"],["DlgAutoPause","b",1,0,1,"comms"],["DlgLayout","i",0,0,2,"comms"],["DlgVisible","i",0,0,12,"comms"],
         ["DlgMoreHint","b",1,0,1,"comms"],["DlgTextSize","f",1,0.8,1.6,"comms"],["DlgFont","i",-1,-1,3,"comms"],["DlgBgOpacity","f",0.85,0,1,"comms"],
         ["DlgCard","b",1,0,1,"comms"],["DlgOffsetX","i",0,-600,600,"comms"],
         ["DlgOffsetY","i",0,-400,400,"comms"],["DlgScale","f",1,0.7,1.5,"comms"],["DlgBgColor","i",0,0,12,"comms"],["DlgBgHex","s","",0,0,"comms"],
         ["DlgTextColor","i",-1,-1,13,"comms"],["DlgTextHex","s","",0,0,"comms"],
         ["DlgNumberKeys","b",1,0,1,"comms"],["DlgWheel","b",1,0,1,"comms"],["DlgHoverScroll","b",0,0,1,"comms"],["DlgSaidStyle","i",2,0,2,"comms"],
         ["DlgPersuadeStyle","i",0,0,2,"comms"],["DlgPersuadeColor","i",2,0,12,"comms"],["DlgPersuasionMeter","b",1,0,1,"comms"],["DlgMarkers","b",0,0,1,"comms"],["DlgInputDelay","i",150,0,1000,"comms"],
         ["DlgRolloverSound","i",0,0,1,"comms"],["DlgAnim","i",1,0,2,"comms"],
         ["DlgButtonBar","i",0,0,2,"comms"],["DlgQuickPickHint","b",1,0,1,"comms"],["DlgSelectHint","b",1,0,1,"comms"]];
      private static const HZ31_DEF:Object = {"Subtitles":1,"SubAutoPause":1,"SubSize":1,"SubWidth":50,"SubBgOpacity":0.7,"SubPosition":0,"SubOffsetY":0,"SubAlign":0,"TxtColIdx":0,"SubCard":1,"SubOffsetX":0,"MissionToast":1,"MissionToastTime":5,"MissionToastMax":3,"MissionToastSound":1,"MissionToastScale":-1,"ReactionCard":1,"DlgButtonBar":0,"DlgQuickPickHint":1,"DlgSelectHint":1,"ShowSpeaker":1,"SpkColIdx":0,"SpeakerCard":1,"KeepInDialogue":1,"FixedInDialogue":1,"SubMaxLines":3,"SubFont":-1,"Dialogue":1,"DlgAutoPause":1,"DlgLayout":0,"DlgVisible":0,"DlgCard":1,"DlgOffsetX":0,"DlgOffsetY":0,"DlgScale":1,"DlgBgColor":0,"DlgTxtIdx":0,"DlgMoreHint":1,"DlgTextSize":1,"DlgFont":-1,"DlgBgOpacity":0.85,"DlgNumberKeys":1,"DlgWheel":1,"DlgHoverScroll":0,"DlgSaidStyle":2,"DlgPersuadeStyle":0,"DlgPersuadeColor":2,"DlgPersuasionMeter":1,"DlgMarkers":0,"DlgInputDelay":150,"DlgRolloverSound":0,"DlgAnim":1,"HideQuestPopupsWhileScanning":1,"DimTraitPopupDuringBioscan":0,"TraitPopupDim":0.4};
      // URLLoader probes, relative to Data/Interface (same base as HorizonUI/HorizonUI.ini). Foreign mods are only reported.
      private static const HZ31_PROBE:Object = {"es":"Enhanced Subtitles - My Edits.ini","edi":"Enhanced Dialogue Interface - My Edits.ini","edi2":"Enhanced Dialogue Interface.ini"};   // v0.38: no file probes for other HUD mods (an ini left behind is not an active HUD)
      private static const HZ31_FONT_OPTS:Array = ["GLOBAL","EXO 2","ROBOTO","GAME FONT","GAME FONT (SEMIBOLD)"];
      private static const HZ31_FONT_IDS:Array = [-1,1,2,0,3];
      private var hz31C:Object = null;      // current [Comms] / [Scanner] values (numbers, SpeakerHex string)
      private var hz31Rev:int = 0;          // [Comms] HzRev from the file; every save writes +1
      private var hz31Page:int = 0;         // COMMS tab sub-page: 0 SUBTITLES, 1 DIALOGUE
      private var hz31PxS:Object = {};      // proxy ghosts by layout key (+ "SpeakerD": the card that follows the dialogue panel)

      private function hz31Cfg() : Object
      {
         if(this.hz31C == null)
         {
            this.hz31C = {};
            for each(var d:Array in HZ31_KEYS) { this.hz31C[d[0]] = d[2]; }
         }
         return this.hz31C;
      }
      private function hz31Def(k:String) : Array
      {
         for each(var d:Array in HZ31_KEYS) { if(d[0] == k) { return d; } }
         return null;
      }
      private function hz31Clamp(d:Array, v:*) : *
      {
         if(d[1] == "s") { return String(v); }
         var n:Number = Number(v);
         if(d[1] == "b") { return (v === true || n == 1 || String(v).toLowerCase() == "true") ? 1 : 0; }
         if(d[1] == "z") { return this.hz34ScClamp(v); }   // v0.34 size: -1 global, else 0.60 - 1.60
         if(isNaN(n)) { return d[2]; }
         n = Math.max(Number(d[3]),Math.min(Number(d[4]),n));
         return d[1] == "i" ? Math.round(n) : Math.round(n * 1000) / 1000;
      }
      private function hz31SecAlias(n:String) : String
      {
         // v0.31 rename (approved): the old names are read, and dropped on the next F11 save
         if(n == "cards v0.26") { return "cards extra"; }
         if(n == "effects v0.26") { return "effects"; }
         return n;
      }
      // old-name sections first, so that a key present under both names takes the new section's value
      private function hz31OldFirst(lines:Array) : Array
      {
         var oldL:Array = [];
         var rest:Array = [];
         var inOld:Boolean = false;
         for each(var ln:String in lines)
         {
            var h:String = this.hz30Hdr(ln);
            if(h != null) { inOld = h == "cards v0.26" || h == "effects v0.26"; }
            if(inOld) { oldL.push(ln); } else { rest.push(ln); }
         }
         return oldL.length == 0 ? lines : oldL.concat(rest);
      }
      // [Comms] / [Scanner] are section-aware (the rest of hzOnIni is not); unknown keys there are left alone
      private function hz31ParseIni(lines:Array) : void
      {
         var c:Object = this.hz31Cfg();
         var sec:String = "";
         for each(var ln:String in lines)
         {
            var h:String = this.hz30Hdr(ln);
            if(h != null) { sec = h; continue; }
            if(sec != "comms") { continue; }   // v0.40: [Scanner] is read by hz40ParseIni
            var t:String = ln;
            var sc:int = t.indexOf(";");
            if(sc >= 0) { t = t.substr(0,sc); }
            var eq:int = t.indexOf("=");
            if(eq <= 0) { continue; }
            var k:String = t.substr(0,eq).replace(/\s/g,"");
            var v:String = t.substr(eq + 1).replace(/^\s+|\s+$/g,"");
            if(sec == "comms" && k.toLowerCase() == "hzrev") { var rv:Number = Number(v); if(!isNaN(rv)) { this.hz31Rev = int(rv); } continue; }
            for each(var d:Array in HZ31_KEYS)
            {
               if(String(d[0]).toLowerCase() == k.toLowerCase() && d[5] == sec) { c[d[0]] = this.hz31Clamp(d,v); break; }
            }
         }
      }
      // settings window values: b keys as Boolean, SpeakerColor as a swatch index (0 = ACCENT, 1..13 palette, 14 custom)
      private function hz31SetCur(cur:Object) : void
      {
         var c:Object = this.hz31Cfg();
         for each(var d:Array in HZ31_KEYS)
         {
            if(d[0] == "SpeakerColor" || d[0] == "SpeakerHex" || d[0] == "SubTextColor" || d[0] == "SubTextHex" || d[0] == "DlgTextColor" || d[0] == "DlgTextHex" || d[0] == "DlgBgHex") { continue; }
            cur[d[0]] = d[1] == "b" ? int(c[d[0]]) != 0 : c[d[0]];
         }
         cur.SpkColIdx = Math.max(0,Math.min(this.hz31SpkPal().length - 1,int(c.SpeakerColor) + 1));
         cur.TxtColIdx = Math.max(0,Math.min(this.hz31TxtPal().length - 1,int(c.SubTextColor) + 1));
         cur.DlgTxtIdx = Math.max(0,Math.min(this.hz33TxtPal("DlgTextHex").length - 1,int(c.DlgTextColor) + 1));
         cur.DlgBgColor = Math.max(0,Math.min(this.hz33BgPal().length - 1,int(c.DlgBgColor)));
         cur._hz31page = this.hz31Page;
      }
      private function hz31SetLive(p:Object) : void
      {
         if(p == null) { return; }
         var c:Object = this.hz31Cfg();
         for each(var d:Array in HZ31_KEYS)
         {
            if(p[d[0]] == undefined || d[0] == "SpeakerColor" || d[0] == "SpeakerHex" || d[0] == "SubTextColor" || d[0] == "SubTextHex" || d[0] == "DlgTextColor" || d[0] == "DlgTextHex" || d[0] == "DlgBgHex") { continue; }
            c[d[0]] = this.hz31Clamp(d,p[d[0]]);
         }
         if(p.SpkColIdx != undefined) { c.SpeakerColor = Math.max(-1,Math.min(13,int(p.SpkColIdx) - 1)); }
         if(p.TxtColIdx != undefined) { c.SubTextColor = Math.max(-1,Math.min(13,int(p.TxtColIdx) - 1)); }
         if(p.DlgTxtIdx != undefined) { c.DlgTextColor = Math.max(-1,Math.min(13,int(p.DlgTxtIdx) - 1)); }
         if(this.hzArrange) { try { this.hz31PxSync(); } catch(err:Error) { } }
      }
      private function hz31SpkPal() : Array
      {
         var a:Array = [this.HZ_ACCENT].concat(HZ_ACCENTS);
         var hx:int = this.hzParseHex(String(this.hz31Cfg().SpeakerHex));
         if(hx >= 0) { a.push(uint(hx)); }
         return a;
      }
      private function hz31SpkNames() : Array
      {
         var a:Array = ["ACCENT"].concat(HZ_SET_ACCNAMES);
         if(this.hzParseHex(String(this.hz31Cfg().SpeakerHex)) >= 0) { a.push("CUSTOM"); }
         return a;
      }
      // v0.32 subtitle text color swatches: 0 OFF-WHITE (default), 1..13 the accent palette, 14 custom (SubTextHex)
      private function hz31TxtPal() : Array { return this.hz33TxtPal("SubTextHex"); }
      private function hz31TxtNames() : Array { return this.hz33TxtNames("SubTextHex"); }
      // text color swatches (subtitles / dialogue options): 0 OFF-WHITE, 1..13 accent palette, 14 custom (hex key)
      private function hz33TxtPal(hexKey:String) : Array
      {
         var a:Array = [0xE8F0F5].concat(HZ_ACCENTS);
         var hx:int = this.hzParseHex(String(this.hz31Cfg()[hexKey]));
         if(hx >= 0) { a.push(uint(hx)); }
         return a;
      }
      private function hz33TxtNames(hexKey:String) : Array
      {
         var a:Array = ["OFF-WHITE"].concat(HZ_SET_ACCNAMES);
         if(this.hzParseHex(String(this.hz31Cfg()[hexKey])) >= 0) { a.push("CUSTOM"); }
         return a;
      }
      // dialogue background swatches = the HUD card colors (0 SLATE default .. 11), 12 custom (DlgBgHex)
      private function hz33BgPal() : Array
      {
         var a:Array = HZ_CARDCOLS.concat();
         var hx:int = this.hzParseHex(String(this.hz31Cfg().DlgBgHex));
         if(hx >= 0) { a.push(uint(hx)); }
         return a;
      }
      private function hz33BgNames() : Array
      {
         var a:Array = HZ_CARDNAMES.concat();
         if(this.hzParseHex(String(this.hz31Cfg().DlgBgHex)) >= 0) { a.push("CUSTOM"); }
         return a;
      }
      private function hz31Num(d:Array, v:*) : String
      {
         var x:* = this.hz31Clamp(d,v);
         if(d[1] == "s") { return String(x); }
         if(d[1] == "f") { return Number(x).toFixed(2); }
         if(d[1] == "z") { return this.hz34ScStr(x); }
         return String(int(x));
      }
      // writer: only with the Comms module installed (otherwise a [Comms] block in the file stays byte-exact). v0.40: [Scanner] is hz40ScanIniLines
      private function hz31IniLines(a:Array, p:Object) : void
      {
         if(this.hz30Mod["comms"] !== 1) { return; }
         this.hz31SetLive(p);
         var c:Object = this.hz31Cfg();
         this.hz31Rev++;
         var cm:Object = {
            "Subtitles":"Horizon subtitle card (0 = the game's subtitles, or another mod's)",
            "SubAutoPause":"1 = pause Horizon subtitles while another mod that changes subtitles is installed",
            "SubSize":"0.70 - 1.80, times [Style] TextScale (v0.34: smaller base card; about 1.15 = the old default size)",
            "SubWidth":"card width, % of 1920 (30 - 90)",
            "SubPosition":"0 bottom center, 1 lower third, 2 top center (ignored once SubtitleX/Y in [Layout] are set)",
            "SubOffsetY":"-300 - 300, 1080p units, + moves the card up (added to the default spot or the ARRANGE position)",
            "SubAlign":"0 left, 1 center",
            "SubTextColor":"subtitle text: -1 off-white, 0 - 12 accent palette, 13 = SubTextHex (the speaker name keeps SpeakerColor)",
            "SubCard":"1 card behind the subtitles, 0 text only (soft dark outline)",
            "SubOffsetX":"-600 - 600, 1080p units, + moves the card right (added to the default spot or the ARRANGE position)",
            "SubMaxLines":"2 - 5: a longer line first widens the card (up to 90 %), then the card grows; the text size never changes",
            "MissionToast":"Horizon mission updated toast in place of the game's quest banner",
            "MissionToastTime":"seconds each toast stays (2 - 15)",
            "MissionToastMax":"toasts stacked at once (1 - 5), newest on top",
            "MissionToastSound":"1 = the game's quest sound plays (it is played by the game's banner; 0 is not supported yet)",
            "ReactionCard":"Horizon card for the companion reaction line (Name liked that.): 0 = the game's line. English game text only; any other line stays the game's",
            "DlgVisible":"options shown before scrolling: 0 = all (the card fits them), 1 - 12",
            "DlgCard":"1 panel behind the dialogue list, 0 text only",
            "DlgOffsetX":"-600 - 600, 1080p units, + moves the panel right (added to the default spot or the ARRANGE position)",
            "DlgOffsetY":"-400 - 400, 1080p units, + moves the panel up (added to the default spot or the ARRANGE position)",
            "DlgScale":"window size 0.70 - 1.50 (width, padding and text); DlgTextSize multiplies the option text on top. If all options do not fit the screen height the option text steps down (to 0.7 x)",
            "DlgBgColor":"panel color: 0 slate, 1 graphite, 2 navy, 3 deep teal, 4 plum, 5 crimson, 6 storm gray, 7 light gray, 8 white, 9 pale blue, 10 pale amber, 11 pale mint, 12 = DlgBgHex",
            "DlgTextColor":"option text: -1 off-white (dark text on light panels), 0 - 12 accent palette, 13 = DlgTextHex",
            "SpeakerColor":"-1 accent, 0 - 12 accent palette, 13 = SpeakerHex",
            "SubFont":"-1 global FontFace, 1 Exo 2, 2 Roboto, 0 game font, 3 game font (semibold)",
            "HzRev":"written by every F11 save; the Comms movies re-apply when it changes",
            "Dialogue":"Horizon dialogue list (needs the Horizon dialogue file; applies from the next conversation)",
            "DlgAutoPause":"1 = pause the Horizon dialogue list while another mod that changes the dialogue menu is installed",
            "DlgLayout":"0 card list, 1 compact, 2 classic centered",
            "DlgSaidStyle":"0 dimmed, 1 hidden, 2 tagged",
            "DlgPersuadeStyle":"0 chip, 1 colored text, 2 none; DlgPersuadeColor = accent palette index",
            "DlgPersuasionMeter":"1 = Horizon persuasion meter (score, the highlighted reply, turns). 0 = the game's meter",
            "DlgInputDelay":"ms before a list accepts input (game default 1000)",
            "DlgRolloverSound":"0 game default, 1 off",
            "DlgAnim":"0 off, 1 fast, 2 vanilla-like",
            "MissionToastScale":"toast size: -1 = [Style] HudScale (GLOBAL), 0.60 - 1.60 = its own size (TextScale applies on top)",
            "DlgButtonBar":"dialogue key bar: 0 Horizon (under the card), 1 the game's bar, 2 hidden (keys still work)",
            "DlgQuickPickHint":"1 = '1 - 9 QUICK PICK' hint on the Horizon bar (keyboard, with DlgNumberKeys=1)",
            "DlgSelectHint":"1 = SELECT key on the Horizon bar (keyboard)"};
         a.push("[Comms]");
         a.push("; Horizon Comms module (hudmessagesmenu + dialoguemenu patches). Set in F11 > COMMS.");
         for each(var d:Array in HZ31_KEYS)
         {
            if(d[5] != "comms") { continue; }
            if(d[0] == "Dialogue") { a.push("; ---- dialogue ----"); }
            if(d[0] == "MissionToast") { a.push("; ---- mission toast ----"); }
            if(d[0] == "ReactionCard") { a.push("; ---- companion reactions ----"); }   // v0.42.0 r2
            if(cm[d[0]] != undefined) { a.push("; " + cm[d[0]]); }
            a.push(d[0] + "=" + this.hz31Num(d,c[d[0]]));
            if(d[0] == "SubFont") { a.push("; " + cm.HzRev); a.push("HzRev=" + String(this.hz31Rev)); }
         }
         a.push("");
      }

      // ---------- F11 ----------
      private function hz31On(n:String) : Boolean { return this.hz30Mod[n] === 1; }
      private function hz31Val(k:String) : *
      {
         if(this.hzSetPend != null && this.hzSetPend[k] != undefined) { return this.hzSetPend[k]; }
         return this.hz31Cfg()[k];
      }
      private function hz31SubForeign() : String
      {
         if(this.hz31On("es")) { return "ANOTHER SUBTITLE MOD"; }
         return "";
      }
      private function hz31DlgForeign() : Boolean { return this.hz31On("edi") || this.hz31On("edi2"); }
      private function hz31BannerMsg(mod:String) : String
      {
         if(mod == "scanner") { return "Installed: Horizon hand scanner. Changes apply the next time you open the scanner."; }
         if(mod != "comms") { return "Module installed"; }
         var f:String = this.hz31SubForeign();
         if(f.length > 0) { return "Installed. Another subtitle mod is also installed: its HUD messages file may have replaced Horizon's."; }
         return this.hz31On("comms_dialogue") ? "Installed: subtitles, speaker card, scanner popups (set in SCANNER) and dialogue." : "Installed: subtitles, speaker card and scanner popups (set in SCANNER). Horizon dialogue not installed.";
      }
      private function hz31CommsRows() : Array
      {
         if(this.hzSetPend != null) { this.hzSetPend._hz31page = this.hz31Page; }
         var rows:Array = [{"k":"_hz30m_comms","l":"","t":"m","mod":"comms"},{"k":"_hz31page","l":"PAGE","t":"r","opts":["SUBTITLES","DIALOGUE"]}];
         var fontOk:Boolean = this.hz30FontAvail();
         var fnote:String = "Global font is in TEXT.";
         var r:Object;
         var body:Array;
         if(this.hz31Page == 0)
         {
            var f:String = this.hz31SubForeign();
            if(f.length > 0 && Boolean(this.hz31Val("SubAutoPause")))
            {
               rows.push({"k":"_hz31usesub","l":"ANOTHER SUBTITLE MOD DETECTED: HORIZON SUBTITLES PAUSED","t":"x","btn":"USE HORIZON","note":"Applies when another mod that changes subtitles is installed. USE HORIZON sets SubAutoPause=0 (works only if Horizon's HUD messages file is the one installed)."});
            }
            body = [{"k":"Subtitles","l":"HORIZON SUBTITLES","t":"b","h":"SUBTITLES","note":"Off = the game's subtitles (or another mod's) are used"},
               {"k":"SubSize","l":"SUBTITLE SIZE","t":"n","mn":0.7,"mx":1.8,"st":0.05,"note":"About 1.15 = the size before v0.34"},
               {"k":"SubWidth","l":"WIDTH (% OF SCREEN)","t":"n","mn":30,"mx":90,"st":2},
               {"k":"SubBgOpacity","l":"BACKGROUND OPACITY","t":"n","mn":0,"mx":1,"st":0.05},
               {"k":"SubPosition","l":"POSITION","t":"r","opts":["BOTTOM CENTER","LOWER THIRD","TOP CENTER"],"note":"Ignored once SUBTITLES is moved in ARRANGE CARDS"},
               {"k":"SubOffsetY","l":"VERTICAL OFFSET","t":"n","mn":-300,"mx":300,"st":10,"note":"+ moves the card up. Applies on top of the ARRANGE CARDS spot too"},
               {"k":"SubOffsetX","l":"HORIZONTAL OFFSET","t":"n","mn":-600,"mx":600,"st":10,"note":"+ moves the card right. Applies on top of the ARRANGE CARDS spot too"},
               {"k":"SubAlign","l":"TEXT ALIGN","t":"r","opts":["LEFT","CENTER"]},
               {"k":"SubCard","l":"CARD BACKGROUND","t":"b","note":"Off = text only, with a soft dark outline"},
               {"k":"TxtColIdx","l":"SUBTITLE TEXT COLOR","t":"a","pal":this.hz31TxtPal(),"names":this.hz31TxtNames(),"note":"Custom: SubTextColor=13 + SubTextHex=#RRGGBB in the ini"},
               {"k":"ShowSpeaker","l":"SPEAKER NAME","t":"b"},
               {"k":"SpkColIdx","l":"SPEAKER NAME COLOR","t":"a","pal":this.hz31SpkPal(),"names":this.hz31SpkNames(),"note":"Custom: SpeakerColor=13 + SpeakerHex=#RRGGBB in the ini"},
               {"k":"SpeakerCard","l":"SPEAKER CARD IN DIALOGUE","t":"b"},
               {"k":"KeepInDialogue","l":"KEEP ON SCREEN IN DIALOGUE","t":"b"},
               {"k":"FixedInDialogue","l":"FIXED POSITION IN DIALOGUE","t":"b"},
               {"k":"SubMaxLines","l":"MAX LINES BEFORE WIDENING","t":"n","mn":2,"mx":5,"st":1,"note":"Longer lines widen the card, then it grows. Text size never changes"},
               {"k":"SubFont","l":"FONT","t":"r","opts":HZ31_FONT_OPTS,"ids":HZ31_FONT_IDS,"note":int(this.hz31Val("SubFont")) == 3 ? this.hz34SemiNote() : fnote},
               {"k":"MissionToast","l":"MISSION UPDATED TOAST","t":"b","h":"MISSION TOAST","note":"Replaces the game's quest banner. Move it in ARRANGE CARDS"},
               {"k":"MissionToastTime","l":"SECONDS ON SCREEN","t":"n","mn":2,"mx":15,"st":1},
               {"k":"MissionToastMax","l":"MAX STACKED","t":"n","mn":1,"mx":5,"st":1},
               {"k":"MissionToastScale","l":"TOAST SIZE","t":"z","note":"GLOBAL = HUD SCALE (STYLE). Also in CARDS"},
               {"k":"MissionToastSound","l":"GAME QUEST SOUND","t":"b","dis":true,"dv":true,"note":"The sound comes from the game's banner and always plays for now"},
               {"k":"ReactionCard","l":"COMPANION REACTION CARD","t":"b","h":"COMPANION REACTIONS","note":"Restyles the 'liked that' line. English game text only for now; other lines stay the game's"},
               {"k":"_hz40goscan","l":"SCANNER POPUPS: NOW IN THE SCANNER TAB","t":"x","btn":"OPEN","h":"SCANNER POPUPS"}];
         }
         else
         {
            var dOk:Boolean = this.hz31On("comms_dialogue");
            if(dOk && this.hz31DlgForeign() && Boolean(this.hz31Val("DlgAutoPause")))
            {
               rows.push({"k":"_hz31usedlg","l":"ANOTHER DIALOGUE MOD DETECTED: HORIZON DIALOGUE PAUSED","t":"x","btn":"USE HORIZON","note":"Applies when another mod that changes the dialogue menu is installed. USE HORIZON sets DlgAutoPause=0 (from the next conversation)."});
            }
            body = [{"k":"Dialogue","l":"HORIZON DIALOGUE","t":"b","h":"DIALOGUE","note":"Off = the game's dialogue menu (or another mod's) is used. Applies from the next conversation."},
               {"k":"DlgLayout","l":"LAYOUT","t":"r","opts":["CARD LIST","COMPACT","CLASSIC CENTERED"]},
               {"k":"DlgVisible","l":"VISIBLE OPTIONS","t":"l","vals":[0,3,4,5,6,7,8,10,12],"names":["ALL","3","4","5","6","7","8","10","12"],"note":"ALL = the card fits every option. 'N MORE' shows only with a limit"},
               {"k":"DlgMoreHint","l":"'N MORE' HINT","t":"b"},
               {"k":"DlgTextSize","l":"OPTION TEXT SIZE","t":"n","mn":0.8,"mx":1.6,"st":0.05,"note":"Multiplies the option text on top of WINDOW SIZE"},
               {"k":"DlgFont","l":"FONT","t":"r","opts":HZ31_FONT_OPTS,"ids":HZ31_FONT_IDS,"note":int(this.hz31Val("DlgFont")) == 3 ? this.hz34SemiNote() : fnote},
               {"k":"DlgScale","l":"WINDOW SIZE","t":"n","mn":0.7,"mx":1.5,"st":0.05,"note":"Width + text together. If the options do not fit the screen height, their text steps down"},
               {"k":"DlgCard","l":"PANEL BACKGROUND","t":"b","note":"Off = text only (no panel, border or stripe)"},
               {"k":"DlgBgColor","l":"BACKGROUND COLOR","t":"a","pal":this.hz33BgPal(),"names":this.hz33BgNames(),"note":"Custom: DlgBgColor=12 + DlgBgHex=#RRGGBB in the ini"},
               {"k":"DlgBgOpacity","l":"BACKGROUND OPACITY","t":"n","mn":0,"mx":1,"st":0.05},
               {"k":"DlgTxtIdx","l":"OPTION TEXT COLOR","t":"a","pal":this.hz33TxtPal("DlgTextHex"),"names":this.hz33TxtNames("DlgTextHex"),"note":"Custom: DlgTextColor=13 + DlgTextHex=#RRGGBB in the ini"},
               {"k":"DlgOffsetX","l":"HORIZONTAL OFFSET","t":"n","mn":-600,"mx":600,"st":10,"note":"+ moves the panel right. Applies on top of the ARRANGE CARDS spot too"},
               {"k":"DlgOffsetY","l":"VERTICAL OFFSET","t":"n","mn":-400,"mx":400,"st":10,"note":"+ moves the panel up. Applies on top of the ARRANGE CARDS spot too"},
               {"k":"SpeakerCard","l":"SPEAKER CARD","t":"b"},
               {"k":"DlgSaidStyle","l":"ALREADY-SAID STYLE","t":"r","opts":["DIMMED","HIDDEN","TAGGED"],"h":"OPTION TAGS"},
               {"k":"DlgPersuadeStyle","l":"PERSUASION TAG","t":"r","opts":["CHIP","COLORED TEXT","NONE"]},
               {"k":"DlgPersuadeColor","l":"PERSUASION TAG COLOR","t":"a","pal":HZ_ACCENTS,"names":HZ_SET_ACCNAMES},
               {"k":"DlgPersuasionMeter","l":"PERSUASION METER","t":"b","note":"Score, the highlighted reply and turns, in place of the game's bars. Off = the game's meter."},
               {"k":"DlgMarkers","l":"QUESTION / ADVANCE MARKERS","t":"b","dis":true,"dv":false,"note":"Experimental: no marker data in this game version"},
               {"k":"DlgNumberKeys","l":"NUMBER KEYS 1 - 9","t":"b","h":"INPUT"},
               {"k":"DlgWheel","l":"MOUSE WHEEL SCROLL","t":"b"},
               {"k":"DlgHoverScroll","l":"HOVER AUTO-SCROLL","t":"b"},
               {"k":"DlgInputDelay","l":"INPUT DELAY (MS)","t":"n","mn":0,"mx":1000,"st":50,"note":"The game's own delay is 1000 ms"},
               {"k":"DlgRolloverSound","l":"ROLLOVER SOUND","t":"r","opts":["GAME DEFAULT","OFF"]},
               {"k":"DlgAnim","l":"OPEN / CLOSE ANIMATION","t":"r","opts":["OFF","FAST","VANILLA-LIKE"]},
               {"k":"DlgButtonBar","l":"KEY BAR","t":"r","opts":["HORIZON","GAME BAR","HIDDEN"],"ids":[0,1,2],"h":"BUTTON BAR","note":"HORIZON = restyled strip under the card. HIDDEN: the keys still work"},
               {"k":"DlgQuickPickHint","l":"1 - 9 QUICK PICK HINT","t":"b","note":"Keyboard, with NUMBER KEYS 1 - 9 on"},
               {"k":"DlgSelectHint","l":"SELECT KEY HINT","t":"b","note":"Keyboard only. Controller glyphs come from the game"}];
            if(!dOk)
            {
               for each(r in body)
               {
                  if(r.dis) { continue; }
                  r.dis = true;
                  r.dv = this.hz31Val(r.k);
               }
               body[0].note = "Horizon dialogue not installed (the game's dialogue menu, or another mod's, is used)";
            }
         }
         if(!fontOk)
         {
            for each(r in body)
            {
               if((r.k == "SubFont" || r.k == "DlgFont") && !r.dis) { r.opts = ["GLOBAL","GAME FONT","GAME FONT (SEMIBOLD)"]; r.ids = [-1,0,3]; r.note = "Horizon font not installed: EXO 2 / ROBOTO need it, the game font is used (your choice is kept)."; }
            }
         }
         return rows.concat(body);
      }

      // ---------- Arrange Cards proxies (the real cards live in hudmessagesmenu / dialoguemenu) ----------
      // Sizes and default spots are the same formulas as the movies' (hzc / hzd blocks), in 1080p units.
      private function hz31DlgOwnsSpk() : Boolean
      {
         var c:Object = this.hz31Cfg();
         return this.hz31On("comms_dialogue") && int(c.Dialogue) == 1 && !(int(c.DlgAutoPause) == 1 && this.hz31DlgForeign());
      }
      private function hz31PxOn(k:String) : Boolean
      {
         if(!this.hz31On("comms")) { return false; }
         var c:Object = this.hz31Cfg();
         if(k == "Subtitle") { return int(c.Subtitles) == 1; }
         if(k == "Speaker") { return int(c.SpeakerCard) == 1 && !this.hz31DlgOwnsSpk(); }
         if(k == "Dialogue") { return this.hz31DlgOwnsSpk() || (this.hz31On("comms_dialogue") && int(c.Dialogue) == 1); }
         if(k == "MissionToast") { return int(c.MissionToast) == 1; }
         if(k == "HudMessages") { return int(c.ReactionCard) == 1; }
         return false;
      }
      // layout key of a Comms proxy ghost, or null for any other card
      private function hz31PxKey(c:Sprite) : String
      {
         if(c == null) { return null; }
         for(var k:String in this.hz31PxS) { if(this.hz31PxS[k] == c && k != "SpeakerD") { return k; } }
         return null;
      }
      private function hz31Px(k:String) : Sprite
      {
         var p:Sprite = this.hz31PxS[k] as Sprite;
         if(p == null)
         {
            p = new Sprite();
            p.mouseEnabled = false;
            p.mouseChildren = false;
            p.visible = false;
            this.hz31PxS[k] = p;
         }
         return p;
      }
      // logical card sizes (1080p units). The subtitle ghost is compact (one line): the movie keeps the anchored edge, so
      // its real height does not matter for the saved spot. Dialogue with DlgVisible=0 (all) shows 4 sample rows.
      private function hz31PxSize(k:String) : Point
      {
         var c:Object = this.hz31Cfg();
         var ts:Number = this.hzTextScale;
         if(k == "Subtitle")
         {
            var sc:Number = Number(c.SubSize) * ts;
            var h:Number = 30 * sc + (int(c.ShowSpeaker) == 1 ? 24.6 * sc : 0) + 24 * 1.38 * sc;   // v0.34 card (hzc block)
            return new Point(Math.round(1920 * Number(c.SubWidth) / 100),Math.round(h));
         }
         if(k == "Speaker" || k == "SpeakerD") { return new Point(Math.round(400 * ts),Math.round(86 * ts)); }
         if(k == "MissionToast") { var mf:Number = ts * this.hz34ToastF(); return new Point(Math.round(460 * mf),Math.round(88 * mf)); }
         if(k == "HudMessages") { return new Point(Math.round(360 * ts),Math.round(80 * ts)); }
         var ds:Number = this.hz33DlgScale();
         var dz:Number = Number(c.DlgTextSize) * ts * ds;
         var cmp:Boolean = int(c.DlgLayout) == 1;
         var rowH:Number = cmp ? 12 * ds + 19 * 1.35 * dz : 22 * ds + 21 * 1.35 * dz;
         var hd:Number = ((cmp ? 12 : 16) + 21) * ds + 14 * ts * ds;
         var n:int = this.hz31PxRows();
         var dh:Number = hd + n * (rowH + 4 * ds) + 14 * ds + (int(c.DlgMoreHint) == 1 && int(c.DlgVisible) > 0 ? 24 * ds : 0) + (int(c.DlgNumberKeys) == 1 && int(c.DlgQuickPickHint) == 1 && int(c.DlgButtonBar) != 0 ? 40 * ds : 0);
         return new Point(Math.round(620 * ds),Math.round(dh));
      }
      // v0.34 mission toast size factor (MissionToastScale, -1 = HudScale); the toast multiplies TextScale on top
      private function hz34ToastF() : Number
      {
         var v:Number = this.hz34ScClamp(this.hz31Cfg().MissionToastScale);
         return v > 0 ? v : this.hzHudScale;
      }
      private function hz33DlgScale() : Number
      {
         var v:Number = Number(this.hz31Cfg().DlgScale);
         return isNaN(v) ? 1 : Math.max(0.7,Math.min(1.5,v));
      }
      // v0.33: the F11 offsets apply on top of the default spot AND the ARRANGE position (screen units; SubOffsetY /
      // DlgOffsetY + = up). Arrange shows and drags the final spot; the stored [Layout] value is the spot minus the offset.
      private function hz33PxOff(k:String) : Point
      {
         var c:Object = this.hz31Cfg();
         var ox:Number;
         var oy:Number;
         if(k == "Subtitle") { ox = Number(c.SubOffsetX); oy = -Number(c.SubOffsetY); }
         else if(k == "Dialogue") { ox = Number(c.DlgOffsetX); oy = -Number(c.DlgOffsetY); }
         else { return new Point(0,0); }
         return new Point(isNaN(ox) ? 0 : ox,isNaN(oy) ? 0 : oy);
      }
      private function hz31PxRows() : int
      {
         var n:int = int(this.hz31Cfg().DlgVisible);
         return n <= 0 ? 4 : Math.min(12,n);
      }
      // default top-left in the visible rect (tl / br), before any [Layout] position
      private function hz31PxHome(k:String, tl:Point, br:Point) : Point
      {
         var c:Object = this.hz31Cfg();
         var sz:Point = this.hz31PxSize(k);
         var mid:Number = (tl.x + br.x) / 2;
         if(k == "Subtitle")
         {
            var pos:int = int(c.SubPosition);
            var y:Number = pos == 2 ? tl.y + 120 : (pos == 1 ? tl.y + (br.y - tl.y) * 0.8 - sz.y : br.y - 80 - sz.y);
            return new Point(mid - sz.x / 2,y);
         }
         if(k == "Speaker") { return new Point(br.x - 710,tl.y + 300); }
         if(k == "MissionToast") { return new Point(mid - sz.x / 2,tl.y + Math.max(28,this.hzMargin - 12) + 90); }
         if(k == "HudMessages") { return new Point(br.x - 40 - sz.x,tl.y + 80); }
         if(int(c.DlgLayout) == 2) { return new Point(mid - sz.x / 2,br.y - 80 - sz.y); }
         return new Point(br.x - 90 - sz.x,tl.y + 404);
      }
      private function hz31PxDefaults(tl:Point, br:Point) : void
      {
         if(!this.hzArrange) { return; }   // the ghosts exist only in ARRANGE CARDS
         for each(var k:String in ["Subtitle","Speaker","Dialogue","MissionToast","HudMessages"])
         {
            if(!this.hz31PxOn(k)) { continue; }
            var p:Sprite = this.hz31Px(k);
            this.hz31PxDraw(k,p);
            var hp:Point = this.hz31PxHome(k,tl,br);
            var of0:Point = this.hz33PxOff(k);
            this.hzPlace(p,hp.x + of0.x,hp.y + of0.y);
         }
      }
      private function hz31PxSync() : void
      {
         var vr:Rectangle = this.hzVis();
         var tl:Point = new Point(vr.x,vr.y);
         var br:Point = new Point(vr.right,vr.bottom);
         for each(var k:String in ["Subtitle","Speaker","Dialogue","MissionToast","HudMessages","SpeakerD"])
         {
            var on:Boolean = this.hzArrange && !this.hz41SA && (k == "SpeakerD" ? this.hz31PxOn("Dialogue") && this.hz31DlgOwnsSpk() && int(this.hz31Cfg().SpeakerCard) == 1 : this.hz31PxOn(k));
            var p:Sprite = this.hz31PxS[k] as Sprite;
            if(!on) { if(p) { p.visible = false; } continue; }
            p = this.hz31Px(k);
            if(p.parent != this) { addChild(p); }
            this.hz31PxDraw(k,p);
            if(k != "SpeakerD")
            {
               var sz:Point = this.hz31PxSize(k);
               var lo:Object = this.hzLay[k];
               var at:Point = lo ? this.hz30Resolve(k,lo,sz.x,sz.y,tl,br) : this.hz31PxHome(k,tl,br);
               var of1:Point = this.hz33PxOff(k);
               at = new Point(at.x + of1.x,at.y + of1.y);
               // always fully on screen (the stand-in can be dragged by any point of its card)
               at.x = this.hz27Clamp(at.x,tl.x,br.x - sz.x);
               at.y = this.hz27Clamp(at.y,tl.y,br.y - sz.y);
               if(this.hzArrDrag != k) { this.hzPlace(p,at.x,at.y); }
            }
            p.visible = true;
            p.alpha = 1;
         }
         // the dialogue file's speaker card sits 104 px above the panel (addendum 3.4)
         var sd:Sprite = this.hz31PxS["SpeakerD"] as Sprite;
         var dp:Sprite = this.hz31PxS["Dialogue"] as Sprite;
         if(sd && sd.visible && dp) { sd.x = dp.x; sd.y = dp.y - 104 * this.hzTextScale; }
         if(this.hzArr_mc && this.hzArr_mc.parent == this) { addChild(this.hzArr_mc); }   // editor stays on top
      }
      // card art for a ghost: fill + 1 px stroked edge + stripe on a fresh Shape (no even-odd ring)
      private function hz31PxCard(p:Sprite, w:Number, h:Number, bg:Number, col:uint, bare:Boolean, fill:uint = 0x0B1218) : *
      {
         var s:Sprite = new Sprite();   // (HUDMenu imports no Shape)
         s.mouseEnabled = false;
         p.addChildAt(s,0);
         var g:* = s.graphics;
         if(bare)
         {
            g.lineStyle(1,0xFFFFFF,0.35,true); g.beginFill(0xFFFFFF,0.004); g.drawRoundRect(0.5,0.5,w - 1,h - 1,27,27); g.endFill(); g.lineStyle();   // outline only: card off
            return g;
         }
         g.beginFill(fill,Math.max(0.35,bg)); g.drawRoundRect(0,0,w,h,28,28); g.endFill();
         g.lineStyle(1,0xFFFFFF,0.10,true); g.beginFill(0xFFFFFF,0.004); g.drawRoundRect(0.5,0.5,w - 1,h - 1,27,27); g.endFill(); g.lineStyle();
         g.beginFill(col,1); g.drawRoundRect(0,14,4,Math.max(4,h - 28),4,4); g.endFill();
         return g;
      }
      // Arrange ghost font size. hzSText multiplies by clamped TextScale, so the
      // value passed in must not be pre-scaled. The result never drops under want px.
      private function hzArrFs(want:int) : int
      {
         var ts:Number = Math.max(0.9,Math.min(1.15,this.hzTextScale));
         if(!(ts > 0)) { ts = 1; }
         var n:int = int(Math.ceil(want / ts));
         if(n < want) { n = want; }
         return n;
      }
      private function hz31PxDraw(k:String, p:Sprite) : void
      {
         while(p.numChildren > 0) { p.removeChildAt(0); }
         var c:Object = this.hz31Cfg();
         var sz:Point = this.hz31PxSize(k);
         p.graphics.clear();
         var acc:uint = this.HZ_ACCENT;
         var bg:Number = k == "Subtitle" ? Number(c.SubBgOpacity) : (k == "Dialogue" ? Number(c.DlgBgOpacity) : 0.8);
         var bare:Boolean = (k == "Subtitle" && int(c.SubCard) == 0) || (k == "Dialogue" && int(c.DlgCard) == 0);
         var bgp:Array = this.hz33BgPal();
         var fillc:uint = k == "Dialogue" ? uint(bgp[Math.max(0,Math.min(bgp.length - 1,int(c.DlgBgColor)))]) : 0x0B1218;
         var g:* = this.hz31PxCard(p,sz.x,sz.y,bg,acc,bare,fillc);
         if(k == "Subtitle")
         {
            var sc:Number = Number(c.SubSize) * this.hzTextScale;
            var ty:Number = 14 * sc;
            var tcol:uint = uint(this.hz31TxtPal()[Math.max(0,Math.min(this.hz31TxtPal().length - 1,int(c.SubTextColor) + 1))]);
            if(int(c.ShowSpeaker) == 1) { this.hzSText(p,"SAM COE",28 * sc,ty,sz.x - 54 * sc,Math.round(15 * sc),acc,"left","hdr"); ty += 24.6 * sc; }
            this.hzSText(p,"Subtitles: drag from anywhere on the card",28 * sc,ty,sz.x - 54 * sc,Math.round(24 * sc * 0.8),tcol,int(c.SubAlign) == 1 ? "center" : "left");
         }
         else if(k == "Speaker" || k == "SpeakerD")
         {
            var ts:Number = this.hzTextScale;
            g.lineStyle(2,acc,0.7); g.beginFill(acc,0.08); g.drawCircle(46 * ts,43 * ts,26 * ts); g.endFill(); g.lineStyle();
            g.beginFill(acc,0.9); g.drawCircle(46 * ts,36 * ts,7 * ts); g.endFill();
            g.beginFill(acc,0.9); g.drawRoundRect(34 * ts,46 * ts,24 * ts,12 * ts,12 * ts,12 * ts); g.endFill();
            this.hzSText(p,"SAM COE",90 * ts,16 * ts,sz.x - 100 * ts,Math.round(20 * ts),0xE8F0F5,"left","hdr");
            this.hzSText(p,"SPEAKING",90 * ts,50 * ts,sz.x - 100 * ts,13,0x8FA3AE,"left","hdr");
         }
         else if(k == "HudMessages")
         {
            var hz:Number = this.hzTextScale;
            this.hzSText(p,"HUD MESSAGES",16 * hz,12 * hz,sz.x - 32 * hz,this.hzArrFs(15),acc,"left","hdr");
            this.hzSText(p,"Companion, crew, crime, credits, afflictions",16 * hz,34 * hz,sz.x - 32 * hz,this.hzArrFs(13),0xF2F7F9,"left");
            this.hzSText(p,"Default spot matches the current message column",16 * hz,52 * hz,sz.x - 32 * hz,this.hzArrFs(13),0x96A6AE,"left");
         }
         else if(k == "MissionToast")
         {
            var mz:Number = this.hzTextScale * this.hz34ToastF();
            g.beginFill(0x060A0E,0.92); g.drawCircle(44 * mz,44 * mz,24 * mz); g.endFill();
            g.lineStyle(1.4,acc,0.45,true); g.drawCircle(44 * mz,44 * mz,19 * mz); g.lineStyle();
            g.beginFill(acc,1); g.moveTo(44 * mz,36 * mz); g.lineTo(52 * mz,44 * mz); g.lineTo(44 * mz,52 * mz); g.lineTo(36 * mz,44 * mz); g.lineTo(44 * mz,36 * mz); g.endFill();
            this.hzSText(p,"MISSION UPDATED",80 * mz,10 * mz,sz.x - 98 * mz,Math.round(13 * mz),acc,"left","hdr");
            this.hzSText(p,"MISSION TOAST",80 * mz,27 * mz,sz.x - 98 * mz,Math.round(19 * mz),0xF2F7F9,"left","hdr");
            this.hzSText(p,"Newest on top: the stack grows away from the edge",80 * mz,53 * mz,sz.x - 98 * mz,Math.round(15 * mz),0x96A6AE,"left");
            g.beginFill(0xFFFFFF,0.07); g.drawRect(80 * mz,sz.y - 10 * mz,sz.x - 98 * mz,2); g.endFill();
            g.beginFill(acc,0.67); g.drawRect(80 * mz,sz.y - 10 * mz,(sz.x - 98 * mz) * 0.6,2); g.endFill();
         }
         else
         {
            var ds:Number = this.hz33DlgScale();
            var dz:Number = Number(c.DlgTextSize) * this.hzTextScale * ds;
            var cmp:Boolean = int(c.DlgLayout) == 1;
            var pad:Number = (cmp ? 12 : 16) * ds;
            var rowH:Number = cmp ? 12 * ds + 19 * 1.35 * dz : 22 * ds + 21 * 1.35 * dz;
            var tpal:Array = this.hz33TxtPal("DlgTextHex");
            var dtc:uint = uint(tpal[Math.max(0,Math.min(tpal.length - 1,int(c.DlgTextColor) + 1))]);
            if(int(c.DlgTextColor) < 0 && this.hzLum(fillc) > 0.5) { dtc = 0x0E151B; }
            var n:int = this.hz31PxRows();
            this.hzSText(p,"RESPOND",pad + 14,16 * ds,200,Math.round(14 * this.hzTextScale * ds),acc,"left","hdr");
            // counter inside the header: right edge = card width - padding - title inset (same as the dialogue file)
            this.hzSText(p,"1 OF " + (int(c.DlgVisible) <= 0 ? "ALL" : String(n)),sz.x - pad - 14 - 200,16 * ds,200,Math.round(14 * this.hzTextScale * ds),0x8FA3AE,"right","hdr");
            var y:Number = ((cmp ? 12 : 16) + 21) * ds + 14 * this.hzTextScale * ds;
            var i:int = 0;
            while(i < n)
            {
               if(i == 0 && int(c.DlgLayout) != 2) { g.beginFill(acc,0.14); g.drawRoundRect(pad,y,sz.x - 2 * pad,rowH,20,20); g.endFill(); }
               var lab:String = (int(c.DlgNumberKeys) == 1 ? String(i + 1) + "   " : "") + "Dialogue option " + String(i + 1);
               this.hzSText(p,lab,pad + 14,y + (rowH - 21 * dz * 1.2) / 2,sz.x - 2 * pad - 28,Math.round((cmp ? 19 : 21) * dz * 0.8),i == 0 ? dtc : this.hzMix(dtc,fillc,0.18),int(c.DlgLayout) == 2 ? "center" : "left");
               y += rowH + 4 * ds;
               i++;
            }
         }
      }
      private function hz31AfFit(lb:TextField, sb:TextField, two:Boolean) : Number
      {
         var maxT:Number = HZ31_AF_MAXW - 48 - 22;
         var lo:Object = this.hzTxtObj(lb);
         if(lo) { this.hzApplyFmt(lo); }
         if(two) { var so:Object = this.hzTxtObj(sb); if(so) { this.hzApplyFmt(so); } }
         lb.width = 2000;
         if(this.hzTW(lb) > maxT) { this.hzFitText(lb,lb.text,maxT); }
         var w:Number = this.hzTW(lb);
         if(lb.text.length > 0 && w < 4)
         {
            this.hzAfRemeasure = true;
            if(this.hzAfRemeasureAt == 0) { this.hzAfRemeasureAt = Math.max(1,this.hzFrameN); }
            if(this.hzAfTitleW > 4) { w = this.hzAfTitleW; lb.width = Math.round(w + 8); }
         }
         else
         {
            if(w >= 4) { this.hzAfTitleW = w; }
            lb.width = Math.round(w + 8);
         }
         if(two)
         {
            sb.width = 2000;
            if(this.hzTW(sb) > maxT) { this.hzFitText(sb,sb.text,maxT); }
            var w2:Number = this.hzTW(sb);
            if(sb.text.length > 0 && w2 < 4)
            {
               this.hzAfRemeasure = true;
               if(this.hzAfRemeasureAt == 0) { this.hzAfRemeasureAt = Math.max(1,this.hzFrameN); }
            }
            else { sb.width = Math.round(w2 + 8); }
            w = Math.max(w,w2);
         }
         return Math.min(maxT,w);
      }

      // ===================== v0.30 optional modules =====================
      // Marker files installed by the FOMOD options (Data/Interface/HorizonUI/modules/<name>.marker). Probed with
      // URLLoader on the same relative path base the HUD already reads HorizonUI.ini from; a missing file / folder
      // only raises IOErrorEvent (caught). State: undefined/-1 checking, 0 absent, 1 present. Re-probed on every F11
      // open so an install / uninstall shows without restarting.
      private static const HZ30_MODS:Array = ["scanner","comms","font","comms_dialogue","es","edi","edi2","scope","notifications"];   // 0.43.0.1: + notifications.marker
      private var hz30Mod:Object = {};
      private var hz30ModLdr:Object = {};
      private var hz30ModT0:Number = 0;
      private var hz30ModTk:int = 0;

      private function hz30ModProbeAll() : void
      {
         this.hz30ModT0 = new Date().getTime();
         this.hz30ModTk = 0;
         for each(var n:String in HZ30_MODS) { this.hz30ModProbe(n); }
      }

      private function hz30ModProbe(n:String) : void
      {
         if(this.hz30ModLdr[n] != null) { return; }   // a probe for this marker is still running
         if(this.hz30Mod[n] == undefined) { this.hz30Mod[n] = -1; }
         var l:URLLoader = null;
         try
         {
            l = new URLLoader();
            this.hz30ModLdr[n] = l;
            l.addEventListener(Event.COMPLETE,this.hz30ModOk);
            l.addEventListener(IOErrorEvent.IO_ERROR,this.hz30ModErr);
            l.addEventListener("securityError",this.hz30ModErr);
            l.load(new URLRequest(HZ31_PROBE[n] != undefined ? String(HZ31_PROBE[n]) : "HorizonUI/modules/" + n + ".marker"));
         }
         catch(err:Error) { this.hz30ModDone(n,0); }
      }

      private function hz30ModName(t:Object) : String
      {
         if(t == null) { return ""; }
         for(var k:String in this.hz30ModLdr) { if(this.hz30ModLdr[k] === t) { return k; } }
         return "";
      }

      private function hz30ModOk(e:Event) : void
      {
         try { this.hz30ModDone(this.hz30ModName(e ? e.target : null),1); } catch(err:Error) { }
      }

      private function hz30ModErr(e:Event) : void
      {
         try { this.hz30ModDone(this.hz30ModName(e ? e.target : null),0); } catch(err:Error) { }
      }

      private function hz30ModDone(n:String, v:int) : void
      {
         if(n == null || n.length == 0) { return; }
         var l:URLLoader = this.hz30ModLdr[n] as URLLoader;
         if(l != null)
         {
            try
            {
               l.removeEventListener(Event.COMPLETE,this.hz30ModOk);
               l.removeEventListener(IOErrorEvent.IO_ERROR,this.hz30ModErr);
               l.removeEventListener("securityError",this.hz30ModErr);
            }
            catch(err0:Error) { }
         }
         this.hz30ModLdr[n] = null;
         var was:* = this.hz30Mod[n];
         this.hz30Mod[n] = v;
         if(was !== v) { try { this.hz30ModChanged(n); } catch(err1:Error) { } }
      }

      // no answer within 4 s = no file (some loaders never fire for a missing folder)
      private function hz30ModTick() : void
      {
         // wall time AND processed frames, so a long loading screen (no frames) never times a slow answer out
         this.hz30ModTk++;
         if(this.hz30ModTk < 120 || new Date().getTime() - this.hz30ModT0 < 4000) { return; }
         this.hz30ModT0 = 0;
         for each(var n:String in HZ30_MODS)
         {
            var l:URLLoader = this.hz30ModLdr[n] as URLLoader;
            if(l == null) { continue; }
            try { l.close(); } catch(err:Error) { }
            this.hz30ModDone(n,this.hz30Mod[n] === 1 ? 1 : 0);
         }
      }

      private function hz30ModChanged(n:String) : void
      {
         if(n == "font" && (this.hzFontFace == 1 || this.hzFontFace == 2))
         {
            this.hzApplyTypo();
            this.hzRedrawBodies();
            if(this.hzEqKind.length > 0) { this.hzEqDrawWeapIcon(this.hzEqKind); }
            this.hzEqDrawAmmoIcon();
            this.hzT19Sig = "";
            this.hzLaidOut = false;
         }
         if(n == "scope" && this.hzArrange) { try { this.hzArrDraw(); } catch(err42m:Error) { } }   // v0.42.0 r2
         if(this.hzSetIsOpen) { this.hzSetDraw(); }
      }

      // Horizon fonts usable: font.marker not reported absent and at least one Horizon face renders
      private function hz30FontAvail() : Boolean
      {
         if(this.hz30Mod["font"] !== 1) { return false; }
         return this.hzFontProbe("$Horizon_Font") || this.hzFontProbe("$Horizon_Font_Alt");
      }

      // TEXT tab: FONT row locked to GAME FONT when the Horizon font is missing; the saved FontFace is untouched
      private function hz30FontRows(rows:Array) : Array
      {
         try
         {
            var fv:int = this.hzSetPend ? int(this.hzSetPend.FontFace) : this.hzFontFace;
            for each(var r0:Object in rows) { if(r0.k == "FontFace" && fv == 3) { r0.note = this.hz34SemiNote(); } }
            if(this.hz30FontAvail()) { return rows; }
            for each(var r:Object in rows)
            {
               if(r.k == "FontFace")
               {
                  // v0.34: the game's two faces stay selectable without the Horizon font
                  r.opts = ["GAME FONT","GAME FONT (SEMIBOLD)"];
                  r.ids = [0,3];
                  r.note = fv == 3 ? this.hz34SemiNote() : "Horizon font not installed: EXO 2 / ROBOTO need it, the game font is used (your choice is kept).";
               }
            }
         }
         catch(err:Error) { }
         return rows;
      }

      private function hz34SemiNote() : String
      {
         var d:String = " " + String.fromCharCode(0xB7) + " ";
         return "Starfield's built-in font" + d + "bold weight" + d + "not bundled";
      }

      private function hz30ModRows(mod:String) : Array
      {
         var rows:Array = [{"k":"_hz30m_" + mod,"l":"","t":"m","mod":mod}];
         if(this.hz30Mod[mod] === 1) { return rows; }
         // placeholders (never saved: "_" keys are not in the settings object); real controls come with the module
         if(mod == "scanner")
         {
            return rows.concat([{"k":"_hz30p_s1","l":"HIDE HORIZON HUD WHILE SCANNING","t":"b","dis":true,"dv":true,"h":"SCANNER"},{"k":"_hz30p_s2","l":"SCANNER SIZE","t":"z","dis":true,"dv":-1}]);
         }
         return rows.concat([{"k":"_hz30p_c1","l":"HORIZON SUBTITLES","t":"b","dis":true,"dv":true,"h":"SUBTITLES"},{"k":"_hz30p_c2","l":"SUBTITLE TEXT SIZE","t":"n","mn":0.8,"mx":1.6,"st":0.05,"dis":true,"dv":1},{"k":"_hz30p_c3","l":"HORIZON DIALOGUE WINDOW","t":"b","dis":true,"dv":true,"h":"DIALOGUE"},{"k":"_hz30p_c4","l":"SPEAKER NAME ABOVE THE LINE","t":"b","dis":true,"dv":true}]);
      }

      // up / down skip locked rows (a tab with nothing selectable keeps row 0)
      private function hz30RowStep(rows:Array, d:int) : void
      {
         var n:int = rows ? rows.length : 0;
         if(n <= 0) { this.hzSetRow = 0; return; }
         var i:int = this.hzSetRow;
         var k:int = 0;
         while(k < n)
         {
            i = (i + d + n) % n;
            var r:Object = rows[i];
            if(r != null && !r.dis) { this.hzSetRow = i; return; }   // v0.34: the module card is selectable (fold / unfold)
            k++;
         }
      }

      // module status banner (top of SCANNER / COMMS tabs). v0.34: the outline is a filled ring (the stroked right edge was
      // dropped), the card snaps to the device pixel grid, and a chevron folds it to one line ([UI] ModuleNoteCompact).
      private function hz30ModBanner(b:Sprite, g:*, y:Number, right:Number, T:Object, mod:String, sel:Boolean = false, idx:int = -1) : void
      {
         var st:* = this.hz30Mod[mod];
         var on:Boolean = st === 1;
         var chk:Boolean = st !== 0 && st !== 1;
         var acc:uint = uint(T.acc);
         var pu:Number = this.hzScrH >= 360 ? 1080 / this.hzScrH : 1;
         var cmp:Boolean = this.hz34NoteCmp;
         var x0:Number = 22;
         var w:Number = Math.floor((right + 6 - 22 - 2) / pu) * pu;   // whole device pixels, 2 units clear of the scroll track
         var h:Number = cmp ? 34 : 84;
         var y0:Number = Math.round((y + 4) / pu) * pu;
         g.beginFill(uint(T.tile),Number(T.tia)); g.drawRoundRect(x0,y0,w,h,18,18); g.endFill();
         if(sel || this.hzSetHover == "row" + idx) { g.beginFill(acc,sel ? 0.10 : 0.05); g.drawRoundRect(x0,y0,w,h,18,18); g.endFill(); }
         var nm:String = mod == "scanner" ? "Scanner" : "Comms";
         var title:String = mod == "scanner" ? "SCANNER MODULE" : "COMMS MODULE  (SUBTITLES + DIALOGUE)";
         var msg:String = on ? this.hz31BannerMsg(mod) : (chk ? "Checking for the " + nm + " module..." : "Requires the " + nm + " module. Install it from the Horizon UI installer.");
         var chx:Number = x0 + w - 24;
         if(cmp)
         {
            var ccx:Number = x0 + 22;
            var ccy:Number = y0 + h / 2;
            g.beginFill(on ? acc : uint(T.line),on ? 0.16 : 0.1); g.drawCircle(ccx,ccy,11); g.endFill();
            if(on) { this.hz30Check(g,ccx,ccy,10,acc); }
            else { this.hz30Lock(g,ccx,ccy + 1,11,uint(T.mut),1,uint(T.fill)); }
            var tt:TextField = this.hzWT(b,mod == "scanner" ? "SCANNER MODULE" : "COMMS MODULE",x0 + 44,y0 + 10,260,11,"bd",uint(T.txt),1.6);
            var sx:Number = Math.round(x0 + 44 + this.hzTW(tt) + 14);
            var stx:String = on ? "INSTALLED" : (chk ? "CHECKING..." : "NOT INSTALLED");
            this.hzWT(b,stx,sx,y0 + 10,Math.max(40,chx - 20 - sx),11,"sb",on ? acc : uint(T.lab),1.2);
         }
         else
         {
            var cx:Number = x0 + 40;
            var cy:Number = y0 + h / 2;
            g.beginFill(on ? acc : uint(T.line),on ? 0.16 : 0.1); g.drawCircle(cx,cy,22); g.endFill();
            g.lineStyle(1.4,on ? acc : uint(T.mut),0.7,true); g.drawCircle(cx,cy,22); g.lineStyle();
            if(on) { this.hz30Check(g,cx,cy,18,acc); }
            else { this.hz30Lock(g,cx,cy + 1,20,uint(T.mut),1,uint(T.fill)); }
            var tx:Number = x0 + 80;
            var tw:Number = chx - 18 - tx;
            this.hzWT(b,title,tx,y0 + 16,tw,13,"bd",uint(T.txt),1.6);
            this.hzWT(b,msg,tx,y0 + 40,tw,12,"rg",on ? acc : uint(T.lab),0.2);
            this.hzWT(b,"Data/Interface/HorizonUI/modules/" + mod + ".marker  " + (on ? "found" : (chk ? "..." : "not found")),tx,y0 + 60,tw,10,"rg",uint(T.mut),0.4);
         }
         this.hz34Chev(g,chx,y0 + (cmp ? h / 2 : 22),!cmp,sel ? acc : uint(T.lab),0.9);
         // the ring goes on top of the texts, on its own sprite, every piece at least one device pixel wide
         this.hz34Ring(b,x0,y0,w,h,9,on ? acc : uint(T.line),on ? 0.55 : Math.max(0.3,Number(T.la) * 2),Math.max(1,pu));
         if(idx >= 0) { this.hzSetHits.push({"id":"row" + idx,"x":x0,"y":y0,"w":w,"h":h}); }
      }

      // padlock (original art): shackle stroke + body with a keyhole; (cx, cy) = body center-ish, s = size
      private function hz30Lock(g:*, cx:Number, cy:Number, s:Number, col:uint, a:Number, hole:uint) : void
      {
         var bw:Number = s * 0.8;
         var bh:Number = s * 0.62;
         var top:Number = cy - bh * 0.28;
         var r:Number = s * 0.26;
         g.lineStyle(Math.max(1.4,s * 0.13),col,a,true,"normal","none");
         g.moveTo(cx - r,top);
         g.lineTo(cx - r,top - s * 0.12);
         g.curveTo(cx - r,top - s * 0.12 - r * 1.3,cx,top - s * 0.12 - r * 1.3);
         g.curveTo(cx + r,top - s * 0.12 - r * 1.3,cx + r,top - s * 0.12);
         g.lineTo(cx + r,top);
         g.lineStyle();
         g.beginFill(col,a); g.drawRoundRect(cx - bw / 2,top,bw,bh,s * 0.18,s * 0.18); g.endFill();
         if(s >= 10)
         {
            g.beginFill(hole,a);
            g.drawCircle(cx,top + bh * 0.4,s * 0.075);
            g.drawRect(cx - s * 0.03,top + bh * 0.4,s * 0.06,bh * 0.32);
            g.endFill();
         }
      }

      private function hz30Check(g:*, cx:Number, cy:Number, s:Number, col:uint) : void
      {
         g.lineStyle(Math.max(1.6,s * 0.14),col,1,true,"normal","round");
         g.moveTo(cx - s * 0.32,cy + s * 0.02);
         g.lineTo(cx - s * 0.08,cy + s * 0.26);
         g.lineTo(cx + s * 0.34,cy - s * 0.22);
         g.lineStyle();
      }


      // ===================== v0.36 combat flag, vanilla hide, outline rings =====================
      private var hz36HideStale:Boolean = false;
      private var hz36CmpTries:int = 0;
      private var hz36CmpLast:String = "";
      // PlayerData.bIsInCombat (the source the game's own detection meter uses); true when the state changed
      private function hz36SetCombat(v:Boolean) : Boolean
      {
         var was:Boolean = this.hzInCombat;
         this.hzInCombat = v;
         if(was != v) { this.hzT19Sig = ""; }
         return was != v;
      }

      // ---- vanilla hide (persistent) ----
      // v0.35 and earlier cached the clip objects for 90 frames and hid them at the very end of the frame tick. A timeline
      // jump in the game's health group (BottomRightGroup fades by jumping its timeline) can hand back a new clip under the
      // same name, any throw earlier in the tick skipped the hide for that frame, and on every heal update the game sets
      // HealthBarGhost_mc / HealthBarIncrease_mc visible = true again (it never touches their alpha). Also re-run inside
      // the PlayerFrequentData / PlayerHealthBoostData handlers. Now each entry keeps
      // its parent + name, is re-read with getChildByName every frame, set to alpha 0 + visible false at the start and at
      // the end of the tick, and a clip that left the stage rebuilds the list on the next frame.
      private function hz36HideFind(c:DisplayObjectContainer, n:String, out:Array) : void
      {
         var d:DisplayObject = this.hzFindByName(c,n,0);
         if(d == null) { return; }
         out.push({"p":d.parent,"n":n,"d":d});
      }
      private function hz36HideTick() : void
      {
         if(this.hzHideCache == null) { return; }
         for each(var e:Object in this.hzHideCache)
         {
            if(e == null) { continue; }
            var d:DisplayObject = e.d;
            try
            {
               var p:DisplayObjectContainer = e.p;
               if(p != null)
               {
                  var cur:DisplayObject = p.getChildByName(String(e.n));
                  if(cur != null && cur != d) { e.d = cur; d = cur; }
               }
            }
            catch(errP:Error) { }
            if(d == null) { continue; }
            if(d.stage == null) { this.hz36HideStale = true; }
            if(d.visible) { d.visible = false; }
            if(d.alpha != 0) { d.alpha = 0; }
         }
      }

      // ---- outline ring into an existing Graphics (cards redraw into one cleared Graphics) ----
      // Same pieces as hz34Ring (4 pixel-snapped bars + 4 quarter rings, fills only): a stroked drawRoundRect loses its
      // right edge in Scaleform (its path starts and ends there), an even-odd double round rect leaks a wedge.
      private function hz36RingG(g:*, x:Number, y:Number, w:Number, h:Number, r:Number, col:uint, a:Number, t:Number) : void
      {
         x = Math.round(x); y = Math.round(y); w = Math.round(w); h = Math.round(h);
         if(g == null || a <= 0 || t <= 0 || w <= 2 * t || h <= 2 * t) { return; }
         r = Math.max(t,Math.min(r,Math.min(w,h) / 2));
         a = Math.min(1,a);
         g.beginFill(col,a); g.drawRect(x + r,y,w - 2 * r,t); g.endFill();
         g.beginFill(col,a); g.drawRect(x + r,y + h - t,w - 2 * r,t); g.endFill();
         g.beginFill(col,a); g.drawRect(x,y + r,t,h - 2 * r); g.endFill();
         g.beginFill(col,a); g.drawRect(x + w - t,y + r,t,h - 2 * r); g.endFill();
         this.hz34Quarter(g,x + r,y + r,r,t,180,col,a);
         this.hz34Quarter(g,x + w - r,y + r,r,t,270,col,a);
         this.hz34Quarter(g,x + w - r,y + h - r,r,t,0,col,a);
         this.hz34Quarter(g,x + r,y + h - r,r,t,90,col,a);
      }
      // F11 info tooltip box: whole-pixel position / size, kept inside the window (the ring is drawn inside the box)
      private function hz36TipBox(W:Number, H:Number, tipX:Number, tipY:Number, tipH:Number, tw:Number, bh:Number) : Object
      {
         tw = Math.round(tw); bh = Math.round(bh);
         var bx:Number = Math.round(Math.max(28,Math.min(W - 28 - tw,tipX - 24)));
         var by:Number = Math.round(tipY + tipH + 2);
         if(by + bh > H - 64) { by = Math.round(tipY - bh - 2); }
         by = Math.round(Math.max(8,Math.min(H - 8 - bh,by)));
         return {"x":bx,"y":by,"w":tw,"h":bh};
      }
      // ===================== v0.35 info tooltips, compact follow, text shadow =====================
      // Shared design tokens (horizon-ui-starter/modules/core/design-tokens.json). Built-in defaults only: every ini / F11
      // setting overrides them. The accent / card color lists keep these as their first (default) entries.
      private static const HZ35_TOK:Object = {"accent":0x3FD0E0,"bg":0x0B1218,"text":0xF2F7F9,"value":0xFFFFFF,"label":0xC4D2D9,"muted":0x96A6AE,"amber":0xF2A93B,"follower":0x3FE0B0,"exotic":0xB48CFF,"minPx":13};
      private static const HZ35_AMBER:uint = 0xF2A93B;
      // ---- Global Compact follow (item 5) ----
      // The compass / planet / equipment / character forms are applied through guarded setters (hzCmpC, hzPpC, hzE19Cm,
      // hz26ChSig). v0.34 re-applied them only from hzRefreshVisibility, and each guard is committed before its work, so a
      // throw during an early apply (cards still building at ini load) left the guard saying "compact applied" while the
      // card kept its full form; every later global toggle then compared equal and was skipped. This signature check runs
      // every frame and force-applies every compact-capable card whenever the resolved form or a card's build state changes.
      private var hz35CmpSigS:String = "";
      private var hz35CmpWait:int = 0;
      private function hz35Form(card:String) : Boolean
      {
         for each(var c:Array in HZ34_CARDS) { if(c[0] == card) { return c[1] ? this.hz34C(card) : this.hzCompact; } }
         return this.hzCompact;
      }
      private function hz35CmpSig() : String
      {
         var s:String = this.hzCompact ? "G1" : "G0";
         for each(var c:Array in HZ34_CARDS) { if(c[1]) { s += this.hz34C(String(c[0])) ? "1" : "0"; } }
         s += "|" + (this.hzCmpBody19 ? "c" : "") + (this.hzPlanPill && this.hzPpName ? "p" : "") + (this.hzEq19 && this.hzEqCount ? "e" : "") + (this.HorizonCompactQuest_mc ? "q" : "");
         return s;
      }
      private function hz35CmpTick() : void
      {
         if(this.hz35CmpWait > 0) { this.hz35CmpWait--; return; }
         var sig:String = this.hz35CmpSig();
         if(sig == this.hz35CmpSigS) { return; }
         if(sig != this.hz36CmpLast) { this.hz36CmpLast = sig; this.hz36CmpTries = 0; }
         this.hz36CmpTries++;
         if(this.hz35CmpForce() || this.hz36CmpTries >= 4) { this.hz35CmpSigS = sig; this.hz36CmpTries = 0; }   // v0.36: bounded
         else { this.hz35CmpWait = 30; }   // retry in ~0.5 s, never every frame
      }
      private function hz35CmpForce() : Boolean
      {
         var ok:Boolean = true;
         try { if(this.hzCmpBody19) { this.hzCmpC = -1; this.hzCmpApplyCompact(); } } catch(e1:Error) { ok = false; this.hzCmpC = -1; }
         try { if(this.hzPlanPill && this.hzPpName) { this.hzPpC = -1; this.hzPpLayout(); } } catch(e2:Error) { ok = false; this.hzPpC = -1; }
         try { if(this.hzEq19 && this.hzEqCount) { this.hzE19Sync(); } } catch(e3:Error) { ok = false; }
         this.hz26ChSig = "";
         this.hzLaidOut = false;
         try { this.hzRefreshVisibility(); } catch(e4:Error) { ok = false; }
         return ok;
      }

      // ---- Text shadow (item 4) ----
      // v0.24-v0.34 used a hard 1 px drop (blur 0, alpha 0.8). Scaleform draws TextField filters through its glyph
      // shadow path: with blur 0 and 1 px the shadow sits under the glyph edge and is invisible on the dark panel; light
      // cards got no filter at all on the older card skin. v0.35: 1.5 px offset, 2 px blur, strength 2 - clearly visible,
      // still a drop shadow (not an outline). The typo guard re-applies it if a .text write drops the filter.
      private function hz35Shadow(dark:Boolean) : Array
      {
         if(!this.hzTextShadow) { return []; }
         if(dark) { return [new DropShadowFilter(1.5,90,0xFFFFFF,0.75,2,2,1.6,2)]; }
         return [new DropShadowFilter(1.5,60,0x000000,1,2.5,2.5,2,2)];
      }

      // ---- F11 info icons (item 6) ----
      private var hz35Kb:Boolean = false;     // last F11 input came from keys / controller: the selected row shows its info
      private var hz35Tip:Object = null;
      private var hz35Mx:Number = NaN;
      private var hz35My:Number = NaN;
      private static const HZ35_INFO:Object = {
         "KeepInDialogue":"During a conversation the game clears each subtitle when the line ends. On: the last line stays on screen until the next line starts. Off: it disappears like the game's.",
         "FixedInDialogue":"In dialogue the game moves its subtitles up (about 230 px, 290 on narrow screens). On: Horizon's card stays where it is. Off: it moves up the same way. Ignored once SUBTITLES is moved in ARRANGE CARDS.",
         "SubMaxLines":"How many lines a subtitle may use at its normal width. A longer line first widens the card in small steps (up to 90 % of the screen), then adds lines. The text size never changes.",
         "Subtitles":"On: Horizon draws the subtitles and hides the game's (alpha 0). If another subtitle mod is detected, Horizon pauses itself and shows a USE HORIZON row to switch back.",
         "Dialogue":"On: Horizon draws the dialogue options; the game's list stays underneath (hidden) and still handles keys, controller and choosing. If another dialogue mod is detected, Horizon pauses itself. Applies from the next conversation.",
         "_hz31usesub":"Horizon found another subtitle mod and paused its own subtitles so the two don't overlap (SubAutoPause=1). USE HORIZON sets SubAutoPause=0 so Horizon's subtitles show again.",
         "_hz31usedlg":"Horizon found another dialogue mod and paused its own dialogue menu (DlgAutoPause=1). USE HORIZON sets DlgAutoPause=0; it applies from the next conversation.",
         "DlgSaidStyle":"Options the game marks as already said. DIMMED: shown faded. HIDDEN: removed from the list; numbers 1 - 9 and the 1 OF N counter count only the shown options. If every option was said, all are shown. Persuasion lists never hide options. TAGGED: faded with a SAID chip.",
         "DlgInputDelay":"After the option list opens, input is ignored for this long so a held key doesn't pick an option by accident. The game's own delay is 1000 ms; lower is faster.",
         "DlgHoverScroll":"With the mouse resting on the top or bottom visible option for a quarter second, the list scrolls one option. Only matters when VISIBLE OPTIONS limits the list.",
         "DlgButtonBar":"HORIZON: a restyled key strip under the options card. GAME BAR: the game's own button bar. HIDDEN: no bar at all - the keys still work.",
         "DlgVisible":"How many options the card shows at once. ALL sizes the card to every option. A number limits it; the rest scroll with the selection, the wheel or hover.",
         "DlgMoreHint":"With VISIBLE OPTIONS limited, a small 'N MORE' line shows how many more options there are.",
         "DlgNumberKeys":"Keys 1 - 9 pick the option with that number. Numbers follow the shown options (HIDDEN already-said options are skipped).",
         "DlgWheel":"The mouse wheel moves the selection up / down the options.",
         "DlgRolloverSound":"GAME DEFAULT plays the game's rollover sound when the selection moves. OFF keeps it silent.",
         "DlgAnim":"How the options card appears and leaves: OFF (instant), FAST, or VANILLA-LIKE (the game's timing).",
         "DlgPersuadeStyle":"How persuasion options are marked: a CHIP, the option text in the tag color, or NONE.",
         "DlgPersuasionMeter":"On: a Horizon meter for the persuasion challenge (the score, a ghost of the highlighted reply's points, and turns left). The game's meter stays in the movie at alpha 0, so its result animations keep running. Off: the game's meter.",
         "DlgScale":"Width and text of the options card together. If the options don't fit the screen height, their text steps down to fit.",
         "DlgOffsetX":"Moves the options card sideways, in 1080p pixels (+ = right). Added on top of the ARRANGE CARDS spot.",
         "DlgOffsetY":"Moves the options card up or down, in 1080p pixels (+ = up). Added on top of the ARRANGE CARDS spot.",
         "SubOffsetX":"Moves the subtitle card sideways, in 1080p pixels (+ = right). Added on top of POSITION or the ARRANGE CARDS spot.",
         "SubOffsetY":"Moves the subtitle card up or down, in 1080p pixels (+ = up). Added on top of POSITION or the ARRANGE CARDS spot.",
         "SubWidth":"The normal width of the subtitle card as a share of the screen. MAX LINES BEFORE WIDENING can widen it further for long lines.",
         "SpeakerCard":"A small card with the speaker's name, shown for the whole conversation.",
         "Margin":"Gap between the screen edges and the cards, in 1080p pixels. Cards placed in ARRANGE CARDS keep their distance from this margin, so they move with it.",
         "ScreenHeight":"Set it to your vertical resolution (1080, 1440, 2160 ...) so the crosshair cards land on whole screen pixels and stay sharp. OFF = no snapping.",
         "ObjectRing":"The ring and line the game draws around the object you look at. OFF: never. CONTAINERS ONLY: only on a container that shows its item list. VANILLA: as the game draws it.",
         "CombatDim":"Out of combat (and not at low health) the HUD cards fade toward DIM OPACITY. On the current card style the fade is softened: 0.60 shows as about 0.84.",
         "DimOpacity":"How far the cards fade out of combat (see DIM OUT OF COMBAT). Lower = fainter.",
         "FadeCards":"Cards fade and slide in / out when they appear or hide, instead of popping.",
         "TargetAnchor":"Where the hover cards (prompt, item, container, enemy) sit. CROSSHAIR: just below and right of the crosshair. FOLLOW TARGET: next to the object on screen, using the position the game reports for it (falls back to the crosshair when there is none).",
         "SmoothBars":"On: Horizon's bars (health, O2, jetpack, hazard, ammo ...) glide to a new value over a few frames, and the health bars keep a short fading 'ghost' of what you just lost. Off: every bar jumps straight to the new value, no ghost.",
         "HazardAlert":"On: while your exposure to an environmental hazard builds up (heat, cold, radiation, airborne, corrosive ...), the planet card gets a pulsing amber outline. Off: no outline; the hazard line, its exposure bar and the colored dot on the card stay.",
         "TargetShowValue":"Value in credits and weight in kg on the item hover card and for the selected entry of a container list. Off: name, rarity and tags only.",
         "TextShadow":"A soft dark drop shadow under every HUD card text (a light one on light cards). Helps on bright backgrounds; off is sharpest.",
         "HeaderStyle":"Card titles in letter-spaced CAPS, or in Title Case with tight spacing.",
         "SettingsKey":"The key that opens this window (handled by HorizonUI.dll). A new key takes effect after restarting the game.",
         "ShowFollowers":"Markers for your follower and companions on the Horizon compass.",
         "CompassMarkers":"Master switch for every Horizon compass marker below. Quest objectives always show while it is on.",
         "ShowTarget":"Horizon's own card for the game's activate prompt (take, talk, open) and the item / container hover cards. Off = the game's prompt.",
         "VehicleExitPill":"While you are in a vehicle, the hold-to-exit prompt is a Horizon pill: the key the game shows, then EXIT. A fill sweeps across while you hold, and the pill turns green with a check when the hold completes. The game's button stays at alpha 0, so the hold still finishes. Off shows the game's prompt.",
         "PlanetDetails":"Adds a gravity / air line to the planet card.",
         "TempUnit":"Planet card and scanner temperature units. The game value is Celsius. Fahrenheit is C times 9/5 plus 32, rounded. Default Celsius.",
         "_size":"GLOBAL: this card uses HUD SCALE (STYLE tab). CUSTOM: it has its own size and HUD SCALE no longer changes it. Click the GLOBAL / CUSTOM chip or drag the slider to switch.",
         "_compact":"GLOBAL: this card takes its compact form whenever COMPACT MODE (top right) is on. ON / OFF: always compact / always full for this card only, whatever COMPACT MODE says.",
         "_rule":"When this card shows. ALWAYS, or only in the situation named (in combat, weapon drawn, not full ...). The card's own switch in CARDS still has to be on."};
      private function hz35InfoOf(r:Object) : String
      {
         if(r == null || r.pill) { return null; }
         if(r.info != undefined && r.info !== null) { return String(r.info); }
         var k:String = String(r.k);
         if(HZ35_INFO[k] != undefined) { return String(HZ35_INFO[k]); }
         if(r.t == "z") { return String(HZ35_INFO["_size"]); }
         if(r.t == "r" && k.length > 7 && k.substr(k.length - 7) == "Compact") { return String(HZ35_INFO["_compact"]); }
         if(r.t == "q" && k.length > 4 && k.substr(k.length - 4) == "Rule") { return String(HZ35_INFO["_rule"]); }
         return null;
      }
      // the "i" disc after a row label; returns its hit
      private function hz35InfoIcon(b:Sprite, g:*, cx:Number, cy:Number, acc:uint, T:Object, on:Boolean, i:int) : void
      {
         g.beginFill(acc,on ? 0.32 : 0.14);
         g.drawCircle(cx,cy,8);
         g.endFill();
         this.hz34Ring(b,Math.round(cx - 8),Math.round(cy - 8),16,16,8,acc,on ? 1 : 0.7,1);   // v0.36
         g.beginFill(on ? uint(T.txt) : acc,1);
         g.drawRect(cx - 1,cy - 2,2,6);
         g.drawCircle(cx,cy - 4.5,1.2);
         g.endFill();
         this.hzSetHits.push({"id":"inf" + i,"x":cx - 11,"y":cy - 12,"w":22,"h":24});
      }
      // tooltip above everything, inside the window (13 px minimum, wraps, flips above the row near the bottom)
      private function hz35TipDraw(b:Sprite, W:Number, H:Number, T:Object, acc:uint) : void
      {
         var tp:Object = this.hz35Tip;
         if(tp == null) { return; }
         var s:Sprite = new Sprite();
         s.mouseEnabled = false; s.mouseChildren = false;
         b.addChild(s);
         var tw:Number = Math.round(Math.min(440,W - 56));
         var tf:TextField = this.hzWT(s,String(tp.t),0,0,tw - 24,13,"rg",uint(T.txt),0.2);
         tf.wordWrap = true;
         tf.multiline = true;
         tf.width = tw - 24;
         tf.text = String(tp.t);
         tf.height = tf.textHeight + 8;
         var bb:Object = this.hz36TipBox(W,H,Number(tp.x),Number(tp.y),Number(tp.h),tw,tf.textHeight + 22);   // v0.36: whole pixels
         var bh:Number = Number(bb.h);
         var bx:Number = Number(bb.x);
         var by:Number = Number(bb.y);
         var g:* = s.graphics;
         g.beginFill(0x000000,0.25); g.drawRoundRect(bx + 2,by + 4,tw,bh,20,20); g.endFill();
         g.beginFill(uint(T.fill),1); g.drawRoundRect(bx,by,tw,bh,20,20); g.endFill();
         // pointer toward the icon
         var px:Number = Math.max(bx + 14,Math.min(bx + tw - 14,Number(tp.x)));
         g.beginFill(uint(T.fill),1);
         if(by > Number(tp.y)) { g.moveTo(px - 6,by + 1); g.lineTo(px,by - 6); g.lineTo(px + 6,by + 1); }
         else { g.moveTo(px - 6,by + bh - 1); g.lineTo(px,by + bh + 6); g.lineTo(px + 6,by + bh - 1); }
         g.endFill();
         tf.x = bx + 12 - 2;
         tf.y = by + 8;
         // v0.36: edge = 4 bars + 4 quarter rings on whole pixels, added last (above the pointer). v0.35 used a stroked
         // drawRoundRect (hz33Edge), whose right edge Scaleform drops - the cut-off right border
         this.hz34Ring(s,bx,by,tw,bh,10,acc,0.9,1);
      }
      // ===================== v0.34 per-card size + compact, banner ring / compact note =====================
      // [Cards] <Card>Scale = -1 (GLOBAL: [Style] HudScale) or 0.60 - 1.60 (CUSTOM: the card's own size; HudScale no
      // longer applies to that card). <Card>Compact = -1 (GLOBAL: [Style] Compact) / 0 off / 1 on, for the cards that
      // have a compact form. Jetpack, vitals and afflictions turn into the shared compact strips card, so they follow the
      // global Compact only. Hover / container cards keep [Style] HoverScale / ContainerScale (same meaning as before;
      // -1 now = GLOBAL). Edge-anchored ARRANGE positions use the real on-screen card size, so they stay put at any size.
      private static const HZ34_CARDS:Array = [["Jetpack",false],["Vitals",false],["Character",true],["XpToast",false],["Planet",true],["Afflictions",false],["Equipment",true],["Quests",true],["Compass",true],["Enemy",false],["Stealth",false],["Compact",false]];
      private static const HZ34_SEMI:String = "$NB_Grotesk_Semibold";   // the game's own semibold face: run-time name only, never shown
      private var hz34Sc:Object = {};
      private var hz34Cm:Object = {};
      private var hz34NoteCmp:Boolean = false;

      private function hz34ScClamp(v:*) : Number
      {
         var n:Number = Number(v);
         if(v === null || v === undefined || String(v) == "" || isNaN(n) || n < 0) { return -1; }
         return Math.round(Math.max(0.6,Math.min(1.6,n)) * 1000) / 1000;
      }
      private function hz34CmClamp(v:*) : int
      {
         var n:Number = Number(v);
         if(v === null || v === undefined || String(v) == "" || isNaN(n) || n < 0) { return -1; }
         return n >= 0.5 ? 1 : 0;
      }
      // the size factor of one card (multiplies HZ_SCALE)
      private function hz34F(card:String) : Number
      {
         var v:Number = this.hz34ScClamp(this.hz34Sc[card]);
         return v > 0 ? v : this.hzHudScale;
      }
      private function hz34S(card:String) : Number { return HZ_SCALE * this.hz34F(card); }
      // hover / container factor: -1 = global HudScale
      private function hz34Eff(v:Number) : Number { return !isNaN(v) && v > 0 ? v : this.hzHudScale; }
      private function hz34C(card:String) : Boolean
      {
         var n:int = this.hz34CmClamp(this.hz34Cm[card]);
         if(n == 1) { return true; }
         if(n == 0) { return false; }
         return this.hzCompact;
      }
      // ini keys (lower case, section-agnostic like the rest of the HUD parser)
      private function hz34Ini(k:String, nv:Number) : Boolean
      {
         if(k == "vitalslayout") { this.hz42VL = (!isNaN(nv) && nv >= 0.5) ? 1 : 0; this.hzLaidOut = false; return true; }   // v0.42.0
         if(k == "modulenotecompact") { this.hz34NoteCmp = !isNaN(nv) && nv >= 0.5; return true; }
         for each(var c:Array in HZ34_CARDS)
         {
            var n:String = String(c[0]).toLowerCase();
            if(k == n + "scale") { this.hz34Sc[c[0]] = this.hz34ScClamp(nv); return true; }
            if(c[1] && k == n + "compact") { this.hz34Cm[c[0]] = this.hz34CmClamp(nv); return true; }
         }
         return false;
      }
      private function hz34SetCur(o:Object) : void
      {
         for each(var c:Array in HZ34_CARDS)
         {
            o[c[0] + "Scale"] = this.hz34ScClamp(this.hz34Sc[c[0]]);
            if(c[1]) { o[c[0] + "Compact"] = this.hz34CmClamp(this.hz34Cm[c[0]]); }
         }
         o.ModuleNoteCompact = this.hz34NoteCmp ? 1 : 0;
         o.VitalsLayout = this.hz42VL;   // v0.42.0
      }
      private function hz34SetLive(p:Object) : void
      {
         if(p == null) { return; }
         var sd:Boolean = false;
         var cd:Boolean = false;
         for each(var c:Array in HZ34_CARDS)
         {
            var k:String = c[0];
            if(p[k + "Scale"] !== undefined)
            {
               var ns:Number = this.hz34ScClamp(p[k + "Scale"]);
               if(ns != this.hz34ScClamp(this.hz34Sc[k])) { this.hz34Sc[k] = ns; sd = true; }
            }
            if(c[1] && p[k + "Compact"] !== undefined)
            {
               var nc:int = this.hz34CmClamp(p[k + "Compact"]);
               if(nc != this.hz34CmClamp(this.hz34Cm[k])) { this.hz34Cm[k] = nc; cd = true; }
            }
         }
         if(p.ModuleNoteCompact !== undefined) { this.hz34NoteCmp = Number(p.ModuleNoteCompact) >= 0.5 || p.ModuleNoteCompact === true; }
         if(p.VitalsLayout !== undefined)   // v0.42.0: live preview / cancel
         {
            var vl:int = Number(p.VitalsLayout) >= 0.5 ? 1 : 0;
            if(vl != this.hz42VL) { this.hz42VL = vl; this.hz42VitApply(); this.hzLaidOut = false; }
         }
         if(cd) { this.hz26ChSig = ""; this.hzLaidOut = false; }
         if(sd) { this.hzApplyScale(); }
      }
      // [Cards] lines of the writer
      private function hz34IniLines(a:Array, p:Object) : void
      {
         a.push("; v0.34 card size: -1 = GLOBAL ([Style] HudScale), 0.60 - 1.60 = CUSTOM (this card's own size; HudScale no longer applies to it)");
         a.push("; CompactScale = the compact strips card. Hover / container sizes are [Style] HoverScale / ContainerScale");
         for each(var c:Array in HZ34_CARDS) { a.push(c[0] + "Scale=" + this.hz34ScStr(p[c[0] + "Scale"])); }
         a.push("; v0.42 vitals card layout: 0 = vertical (health above O2, default), 1 = horizontal (O2 beside health, one row); F11 > CARDS or ARRANGE CARDS (L)");
         a.push("VitalsLayout=" + (Number(p.VitalsLayout) >= 0.5 ? "1" : "0"));
         a.push("; v0.34 card compact form: -1 = GLOBAL ([Style] Compact), 0 off, 1 on. Jetpack / vitals / afflictions follow the global Compact");
         for each(var d:Array in HZ34_CARDS) { if(d[1]) { a.push(d[0] + "Compact=" + String(this.hz34CmClamp(p[d[0] + "Compact"]))); } }
      }
      private function hz34ScStr(v:*) : String
      {
         var n:Number = this.hz34ScClamp(v);
         return n < 0 ? "-1" : String(n);   // up to 3 decimals (ContainerScale 1.125 stays exact)
      }
      // F11 sub-rows of the CARDS tab
      private function hz34Sz(card:String, note:String = null) : Object
      {
         var r:Object = {"k":card + "Scale","l":"SIZE","t":"z","sub":true};
         if(note != null) { r.note = note; }
         return r;
      }
      private function hz34Cmp(card:String, note:String = null) : Object
      {
         var r:Object = {"k":card + "Compact","l":"COMPACT FORM","t":"r","opts":["GLOBAL","ON","OFF"],"ids":[-1,1,0],"sub":true};
         if(note != null) { r.note = note; }
         return r;
      }
      private function hz34CardRows() : Array
      {
         var szn:String = "GLOBAL = HUD SCALE (STYLE). CUSTOM = this card's own size: HUD SCALE no longer applies to it";
         var cmn:String = "GLOBAL = COMPACT MODE (top right). ON / OFF = this card only";
         var rows:Array = [{"k":"Compact","l":"COMPACT MODE (STRIPS)","t":"b","pill":true},
            {"k":"ShowJetpack","l":"JETPACK CARD","t":"b","h":"CARDS"},this.hz34Sz("Jetpack",szn),
            {"k":"ShowVitals","l":"VITALS CARD","t":"b"},this.hz34Sz("Vitals"),
            {"k":"VitalsLayout","l":"VITALS LAYOUT","t":"r","opts":["VERTICAL","HORIZONTAL"],"ids":[0,1],"sub":true,"note":"VERTICAL = health above O2.  HORIZONTAL = O2 beside health (one row).  ARRANGE CARDS: L"},
            {"k":"ShowCharacter","l":"CHARACTER CARD (LV / XP / CREDITS / MASS)","t":"b"},this.hz34Sz("Character"),this.hz34Cmp("Character",cmn),
            {"k":"XpToastScale","l":"XP TOAST: SIZE","t":"z","sub":true},
            {"k":"ShowPlanet","l":"PLANET CARD","t":"b"},this.hz34Sz("Planet"),this.hz34Cmp("Planet"),
            {"k":"PlanetDetails","l":"PLANET: GRAVITY / AIR LINE","t":"b"},
            {"k":"ShowAfflictions","l":"AFFLICTIONS CARD","t":"b"},this.hz34Sz("Afflictions"),
            {"k":"ShowAmmo","l":"EQUIPMENT CARD","t":"b"},this.hz34Sz("Equipment"),this.hz34Cmp("Equipment"),
            {"k":"EquipmentExtras","l":"EQUIPMENT: GRENADES + STARBORN POWER","t":"b"},
            {"k":"ShowQuests","l":"QUEST TRACKER","t":"b"},this.hz34Sz("Quests"),this.hz34Cmp("Quests"),
            {"k":"ShowCompass","l":"COMPASS","t":"b"},this.hz34Sz("Compass"),this.hz34Cmp("Compass","The enemy health bar follows the compass form"),
            {"k":"VehicleExitPill","l":"VEHICLE EXIT PILL","t":"b","note":"Hold-to-exit prompt while you are in a vehicle. Off = the game's prompt."},
            {"k":"EnemyBar","l":"ENEMY HEALTH BAR (TOP CENTER)","t":"b"},this.hz34Sz("Enemy"),
            {"k":"StealthMeter","l":"STEALTH METER (ABOVE CROSSHAIR)","t":"b"},this.hz34Sz("Stealth"),
            {"k":"CompactScale","l":"COMPACT STRIPS: SIZE","t":"z","note":"The jetpack / vitals / afflictions strips of COMPACT MODE"},
            {"k":"ShowTarget","l":"TARGET CARD (ACTIVATE PROMPT)","t":"b","h":"HOVER + CONTAINER"},
            {"k":"HoverScale","l":"HOVER CARDS: SIZE","t":"z","sub":true,"note":"Activate prompts, loose item / take card, compare and enemy tags"},
            {"k":"ContainerScale","l":"CONTAINER WINDOW: SIZE","t":"z","sub":true,"note":"The full container item list"}];
         var on:Boolean = this.hz30Mod["comms"] === 1;
         var mt:Object = {"k":"MissionToast","l":"MISSION TOAST","t":"b","h":"COMMS"};
         var ms:Object = {"k":"MissionToastScale","l":"SIZE","t":"z","sub":true};
         if(on) { ms.note = "Same switch as COMMS > MISSION TOAST. Move it in ARRANGE CARDS"; }
         else
         {
            mt.dis = true; mt.dv = false;
            ms.dis = true; ms.dv = -1;
            ms.note = "Comms module not installed. Install it from the Horizon UI installer.";
         }
         rows.push(mt); rows.push(ms);
         try { this.hz42ScRows(rows); } catch(err42r:Error) { }   // v0.42.0 r2: SCOPE rows (only with the Scope module)
         return rows;
      }
      // "z" row: GLOBAL -> CUSTOM toggle (row click / the chip)
      private function hz34ZToggle(k:String) : void
      {
         if(this.hzSetPend == null) { return; }
         var v:Number = Number(this.hzSetPend[k]);
         if(isNaN(v) || v <= 0)
         {
            var gv:Number = Number(this.hzSetPend.HudScale);
            if(isNaN(gv) || gv <= 0) { gv = 1; }
            this.hzSetPend[k] = Math.max(0.6,this.hz34ScClamp(Math.round(gv / 0.05) * 0.05));
         }
         else { this.hzSetPend[k] = -1; }
         this.hzSetLive(this.hzSetPend);
      }
      // left / right on a "z" row: GLOBAL <-> 0.60 ... 1.60 in 0.05 steps (left from the lowest size = back to GLOBAL).
      // v0.40.3: the scanner's sizes (Scan*Scale) start at 0.60 like every other card (v0.40.1 - 0.40.2: 1.00)
      private function hz34ZStep(k:String, dir:int) : void
      {
         var v:Number = Number(this.hzSetPend[k]);
         if(isNaN(v) || v <= 0)
         {
            if(dir > 0) { this.hz34ZToggle(k); }
            return;
         }
         var n:Number = Math.round((Math.round(v / 0.05) + dir) * 0.05 * 1000) / 1000;
         this.hzSetPend[k] = n < 0.6 - 0.0001 ? -1 : this.hz34ScClamp(n);
         this.hzSetLive(this.hzSetPend);
      }
      private function hz34ZAt(r:Object, f:Number) : void
      {
         var v:Number = 0.6 + Math.max(0,Math.min(1,f)) * 1;
         this.hzSetPend[r.k] = Math.max(0.6,this.hz34ScClamp(Math.round(v / 0.05) * 0.05));
         this.hzSetLive(this.hzSetPend);
      }
      // draws the value part of a "z" row (chip + slider + value); returns nothing, pushes the hit areas
      private function hz34ZDraw(b:Sprite, g:*, i:int, y:Number, R:Number, v:*, T:Object, acc:uint, prev:Boolean) : void
      {
         var cy:Number = y + 16;
         var glob:Boolean = isNaN(Number(v)) || Number(v) <= 0;
         var gv:Number = Number(this.hzSetPend ? this.hzSetPend.HudScale : this.hzHudScale);
         if(isNaN(gv) || gv <= 0) { gv = 1; }
         var zv:Number = glob ? gv : Number(v);
         var bw:Number = prev ? 120 : 160;
         var bx:Number = R - 56 - bw;
         var fr:Number = Math.max(0,Math.min(1,(zv - 0.6) / 1));
         this.hzWT(b,this.hzSetNum(Math.round(zv * 100) / 100),R,cy - 9,56,13,"sb",glob ? uint(T.mut) : acc,0.5,"right");
         g.beginFill(uint(T.track),Number(T.ta)); g.drawRoundRect(bx,cy - 2,bw,4,4,4); g.endFill();
         if(!glob && fr > 0) { g.beginFill(acc,1); g.drawRoundRect(bx,cy - 2,Math.max(4,Math.round(bw * fr)),4,4,4); g.endFill(); }
         var kx:Number = Math.round(bx + bw * fr);
         if(glob) { g.beginFill(uint(T.mut),0.8); g.drawCircle(kx,cy,5); g.endFill(); }
         else
         {
            g.beginFill(acc,1); g.drawCircle(kx,cy,7); g.endFill();
            g.beginFill(uint(T.txt),1); g.drawCircle(kx,cy,5); g.endFill();
         }
         this.hzSetHits.push({"id":"bar" + i,"x":bx - 10,"y":y,"w":bw + 20,"h":32,"bx":bx,"bw":bw});
         var ct:TextField = this.hzWT(b,glob ? "GLOBAL" : "CUSTOM",0,cy - 7,120,10,"sb",glob ? uint(T.txt) : acc,1.4);
         var cw:Number = Math.round(this.hzTW(ct) + 22);
         var cx:Number = Math.round(bx - 20 - cw);
         ct.x = cx + 11 - 2;
         g.beginFill(acc,glob ? 0.08 : 0.18); g.drawRoundRect(cx,cy - 11,cw,22,22,22); g.endFill();
         this.hz34Ring(b,cx,cy - 11,cw,22,11,glob ? uint(T.line) : acc,glob ? 0.8 : 0.9,1);
         this.hzSetHits.push({"id":"zg" + i,"x":cx - 2,"y":y,"w":cw + 4,"h":32});
      }

      // outline as a ring of separate filled pieces: 4 straight bars + 4 quarter rings, no strokes, no even-odd fill.
      // Scaleform drops / mis-hints the right edge of a stroked drawRoundRect (its path starts and ends there).
      private function hz34Ring(b:Sprite, x:Number, y:Number, w:Number, h:Number, r:Number, col:uint, a:Number, t:Number) : Sprite
      {
         var s:Sprite = new Sprite();
         s.mouseEnabled = false;
         s.mouseChildren = false;
         if(b != null) { b.addChild(s); }
         if(a <= 0 || t <= 0 || w <= 2 * t || h <= 2 * t) { return s; }
         var g:* = s.graphics;
         r = Math.max(t,Math.min(r,Math.min(w,h) / 2));
         a = Math.min(1,a);
         g.beginFill(col,a); g.drawRect(x + r,y,w - 2 * r,t); g.endFill();
         g.beginFill(col,a); g.drawRect(x + r,y + h - t,w - 2 * r,t); g.endFill();
         g.beginFill(col,a); g.drawRect(x,y + r,t,h - 2 * r); g.endFill();
         g.beginFill(col,a); g.drawRect(x + w - t,y + r,t,h - 2 * r); g.endFill();
         this.hz34Quarter(g,x + r,y + r,r,t,180,col,a);
         this.hz34Quarter(g,x + w - r,y + r,r,t,270,col,a);
         this.hz34Quarter(g,x + w - r,y + h - r,r,t,0,col,a);
         this.hz34Quarter(g,x + r,y + h - r,r,t,90,col,a);
         return s;
      }
      private function hz34Quarter(g:*, cx:Number, cy:Number, r:Number, t:Number, a0:Number, col:uint, a:Number) : void
      {
         var n:int = 8;
         var ri:Number = Math.max(0,r - t);
         var i:int = 0;
         var ang:Number = 0;
         g.beginFill(col,a);
         while(i <= n)
         {
            ang = (a0 + 90 * i / n) * Math.PI / 180;
            if(i == 0) { g.moveTo(cx + Math.cos(ang) * r,cy + Math.sin(ang) * r); }
            else { g.lineTo(cx + Math.cos(ang) * r,cy + Math.sin(ang) * r); }
            i++;
         }
         i = n;
         while(i >= 0)
         {
            ang = (a0 + 90 * i / n) * Math.PI / 180;
            g.lineTo(cx + Math.cos(ang) * ri,cy + Math.sin(ang) * ri);
            i--;
         }
         g.endFill();
      }
      // banner row height: full card or the one-line form
      private function hz34BanH() : Number { return this.hz34NoteCmp ? 44 : 96; }
      // chevron: down = expand (compact), up = collapse (full)
      private function hz34Chev(g:*, cx:Number, cy:Number, up:Boolean, col:uint, a:Number) : void
      {
         var d:Number = up ? -1 : 1;
         g.beginFill(col,a);
         g.moveTo(cx - 6,cy - 2 * d);
         g.lineTo(cx,cy + 3 * d);
         g.lineTo(cx + 6,cy - 2 * d);
         g.lineTo(cx + 6,cy - 2 * d - 2 * d);
         g.lineTo(cx,cy + d);
         g.lineTo(cx - 6,cy - 2 * d - 2 * d);
         g.lineTo(cx - 6,cy - 2 * d);
         g.endFill();
      }
      // ===================== end v0.34 =====================

      // ===================== v0.30 =====================
      // compass: follower pinned to the strip end; ARRANGE positions anchored to the margin line; grenade badge on the
      // weapon icon; HoverScale (hover cards) separate from ContainerScale (container window); merge-save of the ini

      private static const HZ30_BOM:String = String.fromCharCode(0xFEFF);
      private var hz30CntL:Number = NaN;
      private var hz30Hover:Number = 1;
      private var hz30TgSc:Number = 1.125;
      private var hz30PvKey:String = "";
      private var hz30IniRaw:String = null;
      private var hz30Fresh:String = null;
      private var hz30Wait:int = 0;        // 0 idle, 1 reading the file, 2 read, 3 read failed (cached text is used)
      private var hz30WaitT:Number = 0;
      private var hz30Ldr:URLLoader = null;

      // small outward chevron next to a follower pinned at the end of the compass strip
      private function hz30FolEdge(g:*, mx:Number, dir:int) : void
      {
         var y:Number = this.hzCmpMY;
         var col:uint = this.hz27FolCol();
         var x0:Number = mx + dir * 9;
         g.lineStyle(1.6,col,0.95,true);
         g.moveTo(x0 - dir * 2,y - 4); g.lineTo(x0 + dir * 2,y); g.lineTo(x0 - dir * 2,y + 4);
         g.lineStyle();
      }

      // ---------- ARRANGE positions ----------
      // inset of the margin line for a card / axis (the compass top uses its own line, like its default spot)
      private function hz30Inset(lk:String, top:Boolean) : Number
      {
         if(lk == "Compass" && top) { return this.hz27CmpTop(); }
         return this.hzMargin;
      }

      // anchor + offset from a top-left position (nearest edge; the middle third = center)
      private function hz30Anchor(lk:String, lo:Object, px:Number, py:Number, cw:Number, ch:Number, tl:Point, br:Point, doX:Boolean, doY:Boolean) : void
      {
         var vw:Number = br.x - tl.x;
         var vh:Number = br.y - tl.y;
         if(doX)
         {
            var scx:Number = (tl.x + br.x) / 2;
            var ccx:Number = px + cw / 2;
            var mx:Number = this.hz30Inset(lk,false);
            if(Math.abs(ccx - scx) < vw / 6) { lo.ax = "C"; lo.dx = Math.round(px - (scx - cw / 2)); }
            else if(ccx < scx) { lo.ax = "L"; lo.dx = Math.round(px - (tl.x + mx)); }
            else { lo.ax = "R"; lo.dx = Math.round(br.x - mx - cw - px); }
            lo.nx = true;
         }
         if(doY)
         {
            var scy:Number = (tl.y + br.y) / 2;
            var ccy:Number = py + ch / 2;
            if(Math.abs(ccy - scy) < vh / 6) { lo.ay = "C"; lo.dy = Math.round(py - (scy - ch / 2)); }
            else if(ccy < scy) { lo.ay = "T"; lo.dy = Math.round(py - (tl.y + this.hz30Inset(lk,true))); }
            else { lo.ay = "B"; lo.dy = Math.round(br.y - this.hzMargin - ch - py); }
            lo.ny = true;
         }
      }

      private function hz30Resolve(lk:String, lo:Object, cw:Number, ch:Number, tl:Point, br:Point) : Point
      {
         var vw:Number = br.x - tl.x;
         var vh:Number = br.y - tl.y;
         if(!lo.nx || !lo.ny)
         {
            // legacy 0-1 fraction: the spot v0.29 drew (clamped inside the margin), converted once
            var mgx:Number = this.hz27LayM(lk,false);
            var mgy:Number = this.hz27LayM(lk,true);
            var ox:Number = this.hz27Clamp(tl.x + Number(lo.x) * vw,tl.x + mgx,br.x - mgx - cw);
            var oy:Number = this.hz27Clamp(tl.y + Number(lo.y) * vh,tl.y + mgy,br.y - mgy - ch);
            if(isNaN(ox)) { ox = tl.x + this.hzMargin; }
            if(isNaN(oy)) { oy = tl.y + this.hzMargin; }
            this.hz30Anchor(lk,lo,ox,oy,cw,ch,tl,br,!lo.nx,!lo.ny);
         }
         var dx:Number = Number(lo.dx);
         var dy:Number = Number(lo.dy);
         if(isNaN(dx)) { dx = 0; }
         if(isNaN(dy)) { dy = 0; }
         var mx:Number = this.hz30Inset(lk,false);
         var x:Number;
         if(lo.ax == "R") { x = br.x - mx - cw - dx; }
         else if(lo.ax == "C") { x = (tl.x + br.x) / 2 - cw / 2 + dx; }
         else { x = tl.x + mx + dx; }
         var y:Number;
         if(lo.ay == "B") { y = br.y - this.hzMargin - ch - dy; }
         else if(lo.ay == "C") { y = (tl.y + br.y) / 2 - ch / 2 + dy; }
         else { y = tl.y + this.hz30Inset(lk,true) + dy; }
         // always fully on screen
         x = this.hz27Clamp(x,tl.x,br.x - cw);
         y = this.hz27Clamp(y,tl.y,br.y - ch);
         return new Point(x,y);
      }

      private function hz30PosStr(lp:Object, axis:String) : String
      {
         if(lp["n" + axis] && lp["a" + axis] != undefined)
         {
            var d:Number = Number(lp["d" + axis]);
            return String(lp["a" + axis]) + String(isNaN(d) ? 0 : int(Math.round(d)));
         }
         var f:Number = Number(lp[axis]);
         return String(Math.round((isNaN(f) ? 0 : f) * 10000) / 10000);
      }

      // JetpackX=L84 / AmmoY=B40 / CompassX=C0 ...
      private function hz30IniPos(k:String, v:String) : Boolean
      {
         if(k.length < 2 || v == null || v.length < 1) { return false; }
         var axis:String = k.charAt(k.length - 1);
         if(axis != "x" && axis != "y") { return false; }
         var pre:String = k.substr(0,k.length - 1);
         var a:String = v.charAt(0).toUpperCase();
         var okA:Boolean = axis == "x" ? (a == "L" || a == "R" || a == "C") : (a == "T" || a == "B" || a == "C");
         if(!okA) { return false; }
         var d:Number = Number(v.substr(1).replace(new RegExp("\\s","g"),""));
         if(isNaN(d)) { return false; }
         for each(var lk:String in HZ_LAY_KEYS)
         {
            if(lk.toLowerCase() != pre) { continue; }
            var o:Object = this.hzLay[lk];
            if(!o) { o = {"x":0,"y":0,"hx":false,"hy":false}; this.hzLay[lk] = o; }
            o["a" + axis] = a;
            o["d" + axis] = Math.max(-4000,Math.min(4000,d));
            o["n" + axis] = true;
            o["h" + axis] = true;
            this.hzLaidOut = false;
            return true;
         }
         return false;
      }

      // ---------- grenade badge ----------
      // round-ended badge (grenade glyph + count) whose right edge is rx (never past lim) and bottom is by
      private function hz30Badge(g:*, rx:Number, by:Number, n:int, lim:Number) : void
      {
         var t:TextField = this.hz26GrenT;
         if(!t) { return; }
         var h:Number = 20;
         var col:uint = this.hzIconCol(HZ_ACCENT);
         var dk:Boolean = this.hzDarkText();
         t.text = String(n);
         var bw:Number = Math.max(h + 10,Math.round(18 + this.hzTW(t) + 7));
         if(!isNaN(lim) && rx > lim) { rx = lim; }
         var x:Number = Math.round(Math.max(8,rx - bw));
         var y:Number = Math.round(by - h);
         g.lineStyle(1.4,col,0.85,true);
         g.beginFill(dk ? this.hzMix(this.hzPanelFill(),0x000000,0.1) : 0x080D12,0.96);
         g.drawRoundRect(x,y,bw,h,h,h);
         g.endFill();
         g.lineStyle();
         this.hz26Grenade(g,x + 10,y + h / 2 - 1.6,col,0.56);
         t.x = x + 17;
         this.hzTxtTop(t,this.hzCapTop(t,y + h / 2));
         t.visible = true;
      }

      // ---------- ini ----------
      private function hz30Ini(k:String, bv:Boolean, nv:Number) : Boolean
      {
         switch(k)
         {
            case "hoverscale": if(!isNaN(nv)) { this.hz30Hover = this.hz34ScClamp(nv); this.hzT19Sig = ""; } break;
            default: return false;
         }
         return true;
      }

      private function hz30Fetch() : void
      {
         this.hz30Wait = 1;
         this.hz30Fresh = null;
         try { this.hz37Load(2); }   // v0.37: merged default + user (shared reader)
         catch(err:Error) { this.hz30Wait = 3; }
      }

      private function hz30OnFetch(e:Event) : void
      {
         try { this.hz30Fresh = String(this.hz30Ldr.data); this.hz30Wait = 2; } catch(err:Error) { this.hz30Wait = 3; }
      }

      private function hz30OnFetchErr(e:Event) : void
      {
         this.hz30Wait = 3;
      }

      // section name of a header line ("[Name]" -> "name"), or null
      private function hz30Hdr(ln:String) : String
      {
         var t:String = ln.replace(new RegExp("^[\\s" + HZ30_BOM + "]+|\\s+$","g"),"");
         if(t.length < 3 || t.charAt(0) != "[") { return null; }
         var e:int = t.indexOf("]");
         if(e < 2) { return null; }
         return t.substring(1,e).replace(new RegExp("^\\s+|\\s+$","g"),"").toLowerCase();
      }

      // key of a key=value line (lower case, no blanks), or null for comments / blank / other lines
      private function hz30Key(ln:String) : String
      {
         var t:String = ln.replace(new RegExp("^[\\s" + HZ30_BOM + "]+","g"),"");
         if(t.length == 0) { return null; }
         var c:String = t.charAt(0);
         if(c == ";" || c == "#" || c == "[") { return null; }
         var eq:int = t.indexOf("=");
         if(eq <= 0) { return null; }
         return t.substr(0,eq).replace(new RegExp("\\s","g"),"").toLowerCase();
      }

      private function hz30IsBlank(ln:String) : Boolean
      {
         return ln.replace(new RegExp("[\\s" + HZ30_BOM + "]","g"),"").length == 0;
      }

      // raw = the file as it is now (null / "" = none); gen = the HUD's full text (CRLF lines)
      private function hz30Merge(raw:String, gen:String) : String
      {
         if(raw == null || raw.length == 0) { return gen; }
         var NL:String = "\r\n";
         var i:int = 0;
         // generated text: blocks of lines without line ends
         var gl:Array = gen.split("\r\n");
         if(gl.length > 0 && gl[gl.length - 1] == "") { gl.pop(); }
         var gb:Array = [{"n":null,"L":[]}];
         for each(var gln:String in gl)
         {
            var gh:String = this.hz30Hdr(gln);
            if(gh != null) { gb.push({"n":gh,"L":[gln]}); }
            else { gb[gb.length - 1].L.push(gln); }
         }
         var gIdx:Object = {};
         i = 0;
         while(i < gb.length) { if(gb[i].n != null) { gIdx[gb[i].n] = i; } i++; }
         // file: blocks of lines that keep their own line ends (byte-exact copy of unknown blocks)
         var rl:Array = [];
         var p:int = 0;
         while(p < raw.length)
         {
            var q:int = raw.indexOf("\n",p);
            if(q < 0) { rl.push(raw.substr(p)); break; }
            rl.push(raw.substring(p,q + 1));
            p = q + 1;
         }
         var rb:Array = [{"n":null,"L":[]}];
         for each(var rln:String in rl)
         {
            var rh:String = this.hz30Hdr(rln);
            if(rh != null) { rb.push({"n":rh,"L":[rln]}); }
            else { rb[rb.length - 1].L.push(rln); }
         }
         var inFile:Object = {};
         for each(var b0:Object in rb) { if(b0.n != null) { b0.n = this.hz31SecAlias(b0.n); inFile[b0.n] = true; } }
         var done:Array = [];
         i = 0;
         while(i < gb.length) { done.push(false); i++; }
         var out:Array = [];
         var bom:String = raw.charAt(0) == HZ30_BOM ? HZ30_BOM : "";
         var ri:int = 0;
         while(ri < rb.length)
         {
            var b:Object = rb[ri];
            var gi:int = b.n == null ? 0 : (gIdx[b.n] != undefined ? int(gIdx[b.n]) : -1);
            if(gi < 0)
            {
               // not ours: verbatim
               if(out.length > 0 && !this.hz30EndsNL(out)) { out.push(NL); }
               for each(var vl:String in b.L) { out.push(vl); }
            }
            else if(!done[gi])
            {
               this.hz30EmitGen(out,gb[gi],this.hz30Extras(b.L,gb[gi]),NL);
               done[gi] = true;
               // our sections that the file does not have yet go right after this one, in our order
               var nj:int = gi + 1;
               while(nj < gb.length && !inFile[gb[nj].n])
               {
                  if(!done[nj]) { this.hz30EmitGen(out,gb[nj],[],NL); done[nj] = true; }
                  nj++;
               }
            }
            else
            {
               // a second copy of one of our sections: keep only its unknown keys
               var ex2:Array = this.hz30Extras(b.L,gb[gi]);
               if(ex2.length > 0)
               {
                  if(out.length > 0 && !this.hz30EndsNL(out)) { out.push(NL); }
                  out.push(String(gb[gi].L[0]) + NL);   // v0.31: keep them under their own (new-name) header
                  for each(var xl:String in ex2) { out.push(xl); }
               }
            }
            ri++;
         }
         i = 0;
         while(i < gb.length)
         {
            if(!done[i]) { if(out.length > 0 && !this.hz30EndsNL(out)) { out.push(NL); } this.hz30EmitGen(out,gb[i],[],NL); done[i] = true; }
            i++;
         }
         var res:String = out.join("");
         if(bom.length > 0 && res.charAt(0) != HZ30_BOM) { res = bom + res; }
         return res;
      }

      private function hz30EndsNL(out:Array) : Boolean
      {
         var last:String = String(out[out.length - 1]);
         return last.length > 0 && last.charAt(last.length - 1) == "\n";
      }

      // unknown key lines of a file block (with the comment lines right above each), kept with their own line ends
      private function hz30Extras(L:Array, g:Object) : Array
      {
         var own:Object = {};
         for each(var gl:String in g.L) { var gk:String = this.hz30Key(gl); if(gk != null) { own[gk] = true; } }
         var res:Array = [];
         var pend:Array = [];
         var i:int = 0;
         while(i < L.length)
         {
            var ln:String = L[i];
            if(i == 0 && g.n != null && this.hz30Hdr(ln) != null) { i++; continue; }
            var k:String = this.hz30Key(ln);
            if(k == "scanshowvitals" && g.n == "scanner") { pend = []; i++; continue; }   // v0.41.0: retired (ScanShowVitalsHealth / O2 / Boost)
            if(k == null)
            {
               var t:String = ln.replace(new RegExp("^[\\s" + HZ30_BOM + "]+","g"),"");
               if(t.length > 0 && (t.charAt(0) == ";" || t.charAt(0) == "#")) { pend.push(ln); } else { pend = []; }
            }
            else
            {
               if(!own[k]) { for each(var pl:String in pend) { res.push(pl); } res.push(ln); }
               pend = [];
            }
            i++;
         }
         // the last kept line always ends with a line break
         if(res.length > 0)
         {
            var lst:String = String(res[res.length - 1]);
            if(lst.charAt(lst.length - 1) != "\n") { res[res.length - 1] = lst + "\r\n"; }
         }
         return res;
      }

      // one of our blocks (+ kept unknown lines before its trailing blank lines)
      private function hz30EmitGen(out:Array, g:Object, extras:Array, NL:String) : void
      {
         var L:Array = g.L as Array;
         var end:int = L.length;
         while(end > 0 && this.hz30IsBlank(String(L[end - 1]))) { end--; }
         var i:int = 0;
         while(i < end) { out.push(String(L[i]) + NL); i++; }
         for each(var x:String in extras) { out.push(x); }
         while(i < L.length) { out.push(String(L[i]) + NL); i++; }
      }

      // ===================== v0.37 settings files, presets, update backup =====================
      // ORIGINAL CODE (Horizon UI). Settings are read from two files: HorizonUI.default.ini (shipped, replaced by every
      // update) with HorizonUI.user.ini (the player's own values, never shipped) laid over it key by key. Without
      // HorizonUI.default.ini (old files installed by hand) the legacy HorizonUI.ini is the base. Without user.ini and
      // without HorizonUI.state.ini (no 0.37 DLL has run yet: an older DLL still saves HorizonUI.ini) the legacy file is
      // the overlay. Unknown keys are carried along and ignored as before; malformed lines are skipped. The reading and
      // merging is the shared helper (hzini_shared.as, prefix hz37), the same code the Comms movies use.
      // F11 SAVE still hands the full merged text to the DLL (hzTakeSaveIni, unchanged contract); HorizonUI.dll 0.37
      // keeps only what differs from the defaults in user.ini. Presets / backup: the DLL lists them (AS3 cannot list
      // files) with hzSetFileState, the HUD queues one action at a time (hzTakeFileAction), the DLL answers with
      // hzFileActionDone and the settings are re-read live. An older DLL never calls hzSetFileState, so these rows stay
      // hidden.
      private static const HZ37_CF_MS:Number = 8000;      // a confirm press must follow within 8 s
      private static const HZ37_BUSY_MS:Number = 6000;    // no answer from the DLL after 6 s = give up
      private static const HZ37_WARN_OTHERHUD:String = "Another HUD mod replaces the same HUD file as Horizon UI (hudmenu.gfx), so the two should not be installed together.";
      private var hz37Txt:String = null;     // merged text handed to hzOnIni
      private var hz37Refresh:Boolean = false;
      private var hz37Dll:Boolean = false;   // HorizonUI.dll 0.37+ answered
      private var hz37St:Object = {};
      private var hz37Ps:Array = [];
      private var hz37Sel:int = 0;
      private var hz37SelId:String = "";
      private var hz37Req:String = "";
      private var hz37Busy:String = "";
      private var hz37BusyT:Number = 0;
      private var hz37Cf:String = "";
      private var hz37CfT:Number = 0;
      private var hz37Edit:String = null;
      private var hz37Msg:String = "";
      private var hz37MsgK:String = "";

      // =================== v0.37 shared settings reader (hz37) ===================
      // ONE helper, spliced into every movie that reads the settings (hudmenu + hudmenu_lrg as hz37, hudmessagesmenu
      // x2 as hzc37, dialoguemenu x2 as hzd37; generated from /workspace/v037/work/hzini_shared.as, so the copies are
      // identical apart from the prefix). It reads HorizonUI.default.ini, HorizonUI.user.ini, HorizonUI.state.ini and the
      // legacy HorizonUI.ini (paths relative to Data/Interface) one after the other and hands every waiting callback the
      // merged text: the defaults with user.ini laid over (hz37Compose; mirrors HZF::Compose in HorizonUI.dll). A missing
      // file is normal: its IOErrorEvent is caught and counts as no file. The game logs every failed open, so
      // HorizonUI.ini is opened at most once, and only when Compose still needs that unshipped file.
      // No defaults file -> the legacy HorizonUI.ini is the base. Nothing at all -> null (callers keep built-in defaults).
      private static const hz37_FILES:Array = ["HorizonUI/HorizonUI.default.ini","HorizonUI/HorizonUI.user.ini","HorizonUI/HorizonUI.state.ini","HorizonUI/HorizonUI.ini"];
      private static const hz37_BOM:String = String.fromCharCode(0xFEFF);
      private var hz37Ldr:URLLoader = null;
      private var hz37Step:int = 0;          // 0 idle, n = reading hz37_FILES[n - 1]
      private var hz37T0:Number = 0;
      private var hz37Got:Array = null;
      private var hz37Q:Array = [];          // callbacks of the running read
      private var hz37N:Array = [];          // callbacks that arrived meanwhile (they get a fresh read)
      private var hz37Leg:String = null;     // last text of HorizonUI.ini, or null when that open missed
      private var hz37LegTry:int = 0;        // 0 = not opened yet, 1 = opened once
      private function hz37Ws(c:String) : Boolean { return c == " " || c == "\t" || c == "\r" || c == "\n"; }
      private function hz37Trim(s:String) : String
      {
         var b:int = 0;
         var e:int = s.length;
         while(b < e && (this.hz37Ws(s.charAt(b)) || s.charAt(b) == hz37_BOM)) { b++; }
         while(e > b && this.hz37Ws(s.charAt(e - 1))) { e--; }
         return s.substring(b,e);
      }
      private function hz37Blank(s:String) : Boolean { return this.hz37Trim(s).length == 0; }
      private function hz37Lines(t:String) : Array
      {
         var out:Array = [];
         if(t == null || t.length == 0) { return out; }
         if(t.charAt(0) == hz37_BOM) { t = t.substr(1); }
         var p:int = 0;
         while(p < t.length)
         {
            var q:int = t.indexOf("\n",p);
            var ln:String = q < 0 ? t.substr(p) : t.substring(p,q);
            if(ln.length > 0 && ln.charAt(ln.length - 1) == "\r") { ln = ln.substr(0,ln.length - 1); }
            out.push(ln);
            if(q < 0) { break; }
            p = q + 1;
         }
         return out;
      }
      // "[Name]" -> canonical section name (lower case; pre-v0.31 names aliased), or null
      private function hz37Hdr(ln:String) : String
      {
         var t:String = this.hz37Trim(ln);
         if(t.length < 3 || t.charAt(0) != "[") { return null; }
         var e:int = t.indexOf("]");
         if(e < 2) { return null; }
         return this.hz37Trim(t.substring(1,e)).toLowerCase();
      }
      private function hz37Alias(n:String) : String
      {
         if(n == "cards v0.26") { return "cards extra"; }
         if(n == "effects v0.26") { return "effects"; }
         return n;
      }
      // key=value line -> {k: key lower case without blanks, o: key as written, v: value up to ';'}; null otherwise
      private function hz37KV(ln:String) : Object
      {
         var t:String = this.hz37Trim(ln);
         if(t.length == 0) { return null; }
         var c:String = t.charAt(0);
         if(c == ";" || c == "#" || c == "[") { return null; }
         var eq:int = t.indexOf("=");
         if(eq <= 0) { return null; }
         var o:String = this.hz37Trim(t.substr(0,eq));
         var k:String = o.split(" ").join("").split("\t").join("").toLowerCase();
         if(k.length == 0) { return null; }
         var v:String = t.substr(eq + 1);
         var sc:int = v.indexOf(";");
         if(sc >= 0) { v = v.substr(0,sc); }
         return {"k":k,"o":o,"v":this.hz37Trim(v)};
      }
      // sections; a second copy / the pre-v0.31 name merges into the first, old names first so the new name wins
      private function hz37Parse(t:String) : Object
      {
         var d:Object = {"secs":[{"n":"","raw":[],"order":[],"kv":{}}],"idx":{"s_":0}};
         var lines:Array = this.hz37Lines(t);
         var pass:int = 0;
         while(pass < 2)
         {
            var cur:Object = d.secs[0];
            var old:Boolean = false;
            for each(var ln:String in lines)
            {
               var h:String = this.hz37Hdr(ln);
               if(h != null)
               {
                  old = h == "cards v0.26" || h == "effects v0.26";
                  var n:String = this.hz37Alias(h);
                  if((pass == 0) != old) { cur = null; continue; }
                  if(d.idx["s_" + n] == undefined) { d.idx["s_" + n] = d.secs.length; d.secs.push({"n":n,"raw":[],"order":[],"kv":{}}); }
                  cur = d.secs[int(d.idx["s_" + n])];
                  cur.raw.push(ln);
                  continue;
               }
               if(cur == null) { continue; }
               if(pass == 0 && cur.n == "") { continue; }
               cur.raw.push(ln);
               var kv:Object = this.hz37KV(ln);
               if(kv == null) { continue; }
               if(cur.kv["k_" + kv.k] == undefined) { cur.order.push(kv.k); }
               cur.kv["k_" + kv.k] = [kv.o,kv.v];
            }
            pass++;
         }
         return d;
      }
      private function hz37SecOf(d:Object, kl:String) : String
      {
         for each(var s:Object in d.secs) { if(s.n != "" && s.kv["k_" + kl] != undefined) { return String(s.n); } }
         return "";
      }
      private function hz37Flush(out:Array, sec:String, U:Object, ext:Object, flushed:Object) : void
      {
         if(sec == "" || flushed["s_" + sec] == true) { return; }
         flushed["s_" + sec] = true;
         var e:Array = ext["s_" + sec];
         if(e == null || e.length == 0) { return; }
         var blanks:int = 0;
         while(out.length > 0 && this.hz37Blank(String(out[out.length - 1]))) { out.pop(); blanks++; }
         for each(var k:String in e)
         {
            var p:Array = U["s_" + sec]["k_" + k];
            out.push(String(p[0]) + "=" + String(p[1]));
         }
         while(blanks > 0) { out.push(""); blanks--; }
      }
      // base with the player's values laid over it: known keys replace the base value in place, unknown keys of a known
      // section are appended to it, sections the base lacks are appended verbatim. CRLF out.
      private function hz37Overlay(base:String, over:String) : String
      {
         var B:Object = this.hz37Parse(base);
         var O:Object = this.hz37Parse(over);
         var U:Object = {};
         var ext:Object = {};
         var unk:Array = [];
         for each(var s:Object in O.secs)
         {
            if(s.n != "" && B.idx["s_" + s.n] == undefined) { unk.push(s); continue; }
            for each(var kl:String in s.order)
            {
               var sec:String = s.n == "" ? this.hz37SecOf(B,kl) : String(s.n);
               if(sec == "") { continue; }
               if(U["s_" + sec] == undefined) { U["s_" + sec] = {}; }
               var m:Object = U["s_" + sec];
               if(m["k_" + kl] == undefined && B.secs[int(B.idx["s_" + sec])].kv["k_" + kl] == undefined)
               {
                  if(ext["s_" + sec] == undefined) { ext["s_" + sec] = []; }
                  (ext["s_" + sec] as Array).push(kl);
               }
               m["k_" + kl] = s.kv["k_" + kl];
            }
         }
         var out:Array = [];
         var cur:String = "";
         var flushed:Object = {};
         for each(var ln:String in this.hz37Lines(base))
         {
            var h:String = this.hz37Hdr(ln);
            if(h != null) { this.hz37Flush(out,cur,U,ext,flushed); cur = this.hz37Alias(h); out.push(ln); continue; }
            if(cur != "")
            {
               var kv:Object = this.hz37KV(ln);
               if(kv != null && U["s_" + cur] != undefined && U["s_" + cur]["k_" + kv.k] != undefined)
               {
                  out.push(kv.o + "=" + String(U["s_" + cur]["k_" + kv.k][1]));
                  continue;
               }
            }
            out.push(ln);
         }
         this.hz37Flush(out,cur,U,ext,flushed);
         for each(var us:Object in unk)
         {
            if(out.length > 0 && !this.hz37Blank(String(out[out.length - 1]))) { out.push(""); }
            var r:Array = (us.raw as Array).concat();
            while(r.length > 0 && this.hz37Blank(String(r[r.length - 1]))) { r.pop(); }
            for each(var rl:String in r) { out.push(rl); }
         }
         return out.length == 0 ? "" : out.join("\r\n") + "\r\n";
      }
      // def / user / state / legacy texts (null = file missing) -> the effective settings text, or null
      private function hz37Compose(def:String, user:String, state:String, leg:String) : String
      {
         var hd:Boolean = def != null && def.length > 0;
         var hl:Boolean = leg != null && leg.length > 0;
         var base:String = hd ? def : (hl ? leg : null);
         var over:String = user != null ? user : (state == null && hd && hl ? leg : null);   // an old DLL still saves HorizonUI.ini
         if(base == null) { return over == null ? null : this.hz37Overlay(over,""); }
         return this.hz37Overlay(base,over != null ? over : "");
      }
      // read all four files, then cb(mergedText or null). Requests during a read get one fresh read afterwards.
      private function hz37IniRead(cb:Function) : void
      {
         var now:Number = new Date().getTime();
         if(this.hz37Step != 0 && now - this.hz37T0 < 3000)
         {
            if(this.hz37N.indexOf(cb) < 0) { this.hz37N.push(cb); }
            return;
         }
         if(this.hz37Step != 0 && this.hz37Ldr != null) { try { this.hz37Ldr.close(); } catch(e0:Error) { } }   // stuck: start over
         var q:Array = this.hz37Step != 0 ? this.hz37Q.concat(this.hz37N) : [];
         this.hz37N = [];
         if(q.indexOf(cb) < 0) { q.push(cb); }
         this.hz37Q = q;
         this.hz37Begin();
      }
      private function hz37Begin() : void
      {
         this.hz37Got = [null,null,null,null];
         this.hz37T0 = new Date().getTime();
         this.hz37Next(0);
      }
      private function hz37IsLeg(i:int) : Boolean
      {
         if(i < 0 || i >= hz37_FILES.length) { return false; }
         var pth:String = String(hz37_FILES[i]);
         return pth.length >= 13 && pth.substr(pth.length - 13) == "HorizonUI.ini";
      }
      // HorizonUI.ini is not shipped. Skip it when Compose would ignore it, and open it only once when it would not.
      private function hz37SkipLeg(i:int) : Boolean
      {
         if(!this.hz37IsLeg(i)) { return false; }
         if(this.hz37LegTry != 0) { return true; }
         var def:String = this.hz37Got[0] == null ? null : String(this.hz37Got[0]);
         var hd:Boolean = def != null && def.length > 0;
         if(hd && (this.hz37Got[1] != null || this.hz37Got[2] != null)) { return true; }
         return false;
      }
      private function hz37Next(i:int) : void
      {
         this.hz37Step = i + 1;
         if(i >= hz37_FILES.length) { this.hz37Ldr = null; this.hz37Done(); return; }
         if(this.hz37SkipLeg(i))
         {
            this.hz37Got[i] = this.hz37LegTry != 0 ? this.hz37Leg : null;
            this.hz37Next(i + 1);
            return;
         }
         try
         {
            this.hz37Ldr = new URLLoader();
            this.hz37Ldr.addEventListener(Event.COMPLETE,this.hz37OnOk);
            this.hz37Ldr.addEventListener(IOErrorEvent.IO_ERROR,this.hz37OnErr);
            this.hz37Ldr.addEventListener("securityError",this.hz37OnErr);
            this.hz37Ldr.load(new URLRequest(String(hz37_FILES[i])));
         }
         catch(err:Error) { this.hz37Next(i + 1); }
      }
      private function hz37OnOk(e:Event) : void
      {
         if(e == null || e.target != this.hz37Ldr) { return; }
         var i:int = this.hz37Step - 1;
         try { this.hz37Got[i] = String(this.hz37Ldr.data); } catch(err:Error) { }
         if(this.hz37IsLeg(i)) { this.hz37Leg = this.hz37Got[i] == null ? null : String(this.hz37Got[i]); this.hz37LegTry = 1; }
         this.hz37Next(i + 1);
      }
      private function hz37OnErr(e:Event) : void
      {
         if(e == null || e.target != this.hz37Ldr) { return; }
         if(this.hz37IsLeg(this.hz37Step - 1)) { this.hz37Leg = null; this.hz37LegTry = 1; }
         this.hz37Next(this.hz37Step);   // missing file: counted once, not opened again
      }
      private function hz37Done() : void
      {
         this.hz37Step = 0;
         var g:Array = this.hz37Got;
         var txt:String = null;
         try { txt = this.hz37Compose(g[0],g[1],g[2],g[3]); } catch(errC:Error) { txt = null; }
         var cbs:Array = this.hz37Q;
         this.hz37Q = [];
         for each(var cb:Function in cbs) { try { cb(txt); } catch(errCb:Error) { } }
         if(this.hz37N.length > 0 && this.hz37Step == 0) { this.hz37Q = this.hz37N; this.hz37N = []; this.hz37Begin(); }
      }
      // =================== end shared settings reader ===================

      // the HUD's two uses of the shared reader: 1 = apply the settings (start, reload after Apply / Restore / Undo),
      // 2 = fresh text for the F11 save merge (hz30Fetch)
      private function hz37Load(bit:int) : void
      {
         if((bit & 1) != 0) { this.hz37IniRead(this.hz37OnApplyTxt); }
         if((bit & 2) != 0) { this.hz37IniRead(this.hz37OnFreshTxt); }
      }
      private function hz37OnFreshTxt(txt:String) : void
      {
         if(txt != null) { this.hz30Fresh = txt; this.hz30Wait = 2; }
         else { this.hz30Wait = 3; }
      }
      private function hz37OnApplyTxt(txt:String) : void
      {
         if(txt != null) { this.hz37Txt = txt; try { this.hzOnIni(null); } catch(errA:Error) { } }
         if(this.hz37Refresh)
         {
            this.hz37Refresh = false;
            if(this.hzSetIsOpen)
            {
               this.hzSetOrig = this.hzSetCurrent();
               this.hzSetPend = this.hzSetCurrent();
               try { this.hzSetLive(this.hzSetPend); } catch(errL:Error) { }
               this.hzSetDraw();
            }
         }
      }

      // ---------- DLL contract ----------
      // "v=0.37.0|bak=1|undo=0|user=1|def=1|skip=N|last=<id of the last applied preset>" then "<id>|<1 user>|<name>|<author>|<version>|<description>" lines
      public function hzSetFileState(s:String) : void
      {
         try { this.hz37ParseState(s); } catch(err:Error) { }
         if(this.hzSetIsOpen) { this.hzSetDraw(); }
      }
      private function hz37ParseState(s:String) : void
      {
         var lines:Array = String(s).split("\r").join("").split("\n");
         var st:Object = {};
         for each(var f:String in String(lines[0]).split("|"))
         {
            var eq:int = f.indexOf("=");
            if(eq > 0) { st[f.substr(0,eq)] = f.substr(eq + 1); }
         }
         var ps:Array = [];
         var i:int = 1;
         while(i < lines.length)
         {
            var p:Array = String(lines[i]).split("|");
            if(p.length >= 6 && String(p[0]).length > 2 && String(p[2]).length > 0)
            {
               ps.push({"id":String(p[0]),"u":String(p[1]) == "1","n":String(p[2]),"a":String(p[3]),"v":String(p[4]),"d":p.slice(5).join("|")});
            }
            i++;
         }
         this.hz37St = st;
         this.hz37Ps = ps;
         this.hz37Dll = true;
         var keep:String = this.hz37SelId;
         this.hz37Sel = 0;
         i = 0;
         while(i < ps.length) { if(String(ps[i].id).toLowerCase() == keep.toLowerCase()) { this.hz37Sel = i; } i++; }
         this.hz37SelId = ps.length > 0 ? String(ps[this.hz37Sel].id) : "";
      }
      public function hzTakeFileAction() : String
      {
         var r:String = this.hz37Req;
         this.hz37Req = "";
         return r;
      }
      // "<kind>|<1 ok / 0 failed>|<message>"
      public function hzFileActionDone(s:String) : void
      {
         var p:Array = String(s).split("|");
         var kind:String = String(p[0]);
         var ok:Boolean = String(p[1]) == "1";
         this.hz37MsgK = this.hz37Busy.length > 0 ? this.hz37Busy : this.hz37KeyOf(kind);
         this.hz37Busy = "";
         this.hz37Msg = (ok ? "Done: " : "Failed: ") + (p.length > 2 ? p.slice(2).join("|") : "");
         if(ok && (kind == "apply" || kind == "restore" || kind == "undo")) { this.hz37Refresh = true; this.hz37Load(1); }
         if(this.hzSetIsOpen) { this.hzSetDraw(); }
      }
      private function hz37KeyOf(kind:String) : String
      {
         if(kind == "apply") { return "_hz37apply"; }
         if(kind == "save") { return "_hz37save"; }
         if(kind == "delete") { return "_hz37del"; }
         if(kind == "undo") { return "_hz37undo"; }
         return "_hz37bak";
      }

      // ---------- presets ----------
      private function hz37Cur() : Object
      {
         if(this.hz37Ps.length == 0) { return null; }
         return this.hz37Ps[Math.max(0,Math.min(this.hz37Ps.length - 1,this.hz37Sel))];
      }
      // file name for a saved preset (mirrors HZF::Slug): a-z 0-9, runs of anything else -> one '_', max 40
      private function hz37Slug(name:String) : String
      {
         var s:String = "";
         var us:Boolean = false;
         var i:int = 0;
         while(i < name.length)
         {
            var c:int = name.charCodeAt(i);
            if((c >= 97 && c <= 122) || (c >= 48 && c <= 57)) { s += name.charAt(i); us = false; }
            else if(c >= 65 && c <= 90) { s += String.fromCharCode(c + 32); us = false; }
            else if(s.length > 0 && !us) { s += "_"; us = true; }
            i++;
         }
         while(s.length > 0 && s.charAt(s.length - 1) == "_") { s = s.substr(0,s.length - 1); }
         if(s.length > 40) { s = s.substr(0,40); while(s.length > 0 && s.charAt(s.length - 1) == "_") { s = s.substr(0,s.length - 1); } }
         if(s.length == 0) { s = "preset"; }
         if(["con","prn","aux","nul","com1","com2","com3","com4","com5","com6","com7","com8","com9","lpt1","lpt2","lpt3","lpt4","lpt5","lpt6","lpt7","lpt8","lpt9"].indexOf(s) >= 0) { s += "_1"; }
         return s;
      }
      private function hz37NameTaken(name:String) : Boolean
      {
         var id:String = "u:" + this.hz37Slug(name) + ".ini";
         for each(var p:Object in this.hz37Ps)
         {
            if(p.u && String(p.id).toLowerCase() == id) { return true; }
         }
         return false;
      }
      // "0.36.2" older than "0.37.0" (numeric parts in order, missing = 0); false when either is not a version (mirrors HZF::VersionOlder)
      private function hz37Older(v:String, cur:String) : Boolean
      {
         var a:Array = this.hz37VerParts(v);
         var b:Array = this.hz37VerParts(cur);
         if(a == null || b == null) { return false; }
         var i:int = 0;
         while(i < Math.max(a.length,b.length))
         {
            var x:Number = i < a.length ? Number(a[i]) : 0;
            var y:Number = i < b.length ? Number(b[i]) : 0;
            if(x != y) { return x < y; }
            i++;
         }
         return false;
      }
      private function hz37VerParts(v:String) : Array
      {
         var t:String = this.hz37Trim(v == null ? "" : v);
         if(t.length > 0 && (t.charAt(0) == "v" || t.charAt(0) == "V")) { t = t.substr(1); }
         if(t.length == 0) { return null; }
         var out:Array = [];
         for each(var part:String in t.split("."))
         {
            if(part.length == 0 || part.length > 6) { return null; }
            var j:int = 0;
            while(j < part.length) { var c:int = part.charCodeAt(j); if(c < 48 || c > 57) { return null; } j++; }
            out.push(int(part));
         }
         return out;
      }
      // a shipped preset (came with the mod / installer) already has this name: never overwritten or shadowed
      private function hz37ShippedName(name:String) : Boolean
      {
         var sl:String = this.hz37Slug(name);
         for each(var p:Object in this.hz37Ps)
         {
            if(!p.u && this.hz37Slug(String(p.n)) == sl) { return true; }
         }
         return false;
      }
      // the SAVE name box starts with the last applied preset's name when that is one of yours, else "My preset N"
      private function hz37AutoName() : String
      {
         var last:String = this.hz37St.last != undefined ? String(this.hz37St.last).toLowerCase() : "";
         if(last.indexOf("u:") == 0)
         {
            for each(var lp:Object in this.hz37Ps)
            {
               if(lp.u && String(lp.id).toLowerCase() == last) { return String(lp.n); }
            }
         }
         var n:int = 1;
         while(n < 1000 && this.hz37NameTaken("My preset " + n)) { n++; }
         return "My preset " + n;
      }
      // the full current settings (what the window shows), as the save merge builds it
      private function hz37FullText() : String
      {
         var p:Object = this.hzSetPend != null ? this.hzSetPend : this.hzSetCurrent();
         return this.hz30Merge(this.hz30IniRaw,this.hzBuildIniText(p));
      }
      private function hz37Send(a:String, k:String) : void
      {
         this.hz37Req = a;
         this.hz37Busy = k;
         this.hz37BusyT = new Date().getTime();
         this.hz37Msg = "";
         this.hz37MsgK = "";
      }
      private function hz37SaveSubmit() : void
      {
         var nm:String = this.hz37Edit == null ? "" : this.hz37Trim(this.hz42NmSafe(this.hz37Edit));
         if(nm.length == 0) { this.hz37Msg = "Failed: type a name first"; this.hz37MsgK = "_hz37save"; return; }
         if(this.hz37ShippedName(nm)) { this.hz37Cf = ""; this.hz37Msg = "Failed: a preset that came with the mod has that name - pick another name"; this.hz37MsgK = "_hz37save"; return; }
         var now:Number = new Date().getTime();
         var taken:Boolean = this.hz37NameTaken(nm);
         if(taken && (this.hz37Cf != "_hz37save" || now - this.hz37CfT > HZ37_CF_MS)) { this.hz37Cf = "_hz37save"; this.hz37CfT = now; return; }
         this.hz37Cf = "";
         var full:String = null;
         try { full = this.hz37FullText(); } catch(err:Error) { full = null; }
         if(full == null || full.length == 0) { this.hz37Msg = "Failed: could not build the settings text"; this.hz37MsgK = "_hz37save"; return; }
         this.hz37Send("save|" + (taken ? "1" : "0") + "|" + nm + "\n" + full,"_hz37save");
         this.hz37SelId = "u:" + this.hz37Slug(nm) + ".ini";
         this.hz37Edit = null;
      }
      // a press on one of the rows (right / left / click); the picker cycles, the rest confirm first
      private function hz37Act(r:Object, dir:int) : void
      {
         var k:String = String(r.k);
         var n:int = this.hz37Ps.length;
         if(k == "_hz37pick")
         {
            if(n > 0) { this.hz37Sel = (this.hz37Sel + dir + n * 4) % n; this.hz37SelId = String(this.hz37Ps[this.hz37Sel].id); }
            this.hz37Cf = "";
            return;
         }
         if(r.off || this.hz37Busy.length > 0) { return; }
         if(k == "_hz37save")
         {
            if(this.hz37Edit == null) { this.hz37Edit = this.hz37AutoName(); this.hz37Cf = ""; this.hz37Msg = ""; return; }
            this.hz37SaveSubmit();
            return;
         }
         var now:Number = new Date().getTime();
         if(this.hz37Cf != k || now - this.hz37CfT > HZ37_CF_MS) { this.hz37Cf = k; this.hz37CfT = now; this.hz37Msg = ""; return; }
         this.hz37Cf = "";
         var p:Object = this.hz37Cur();
         if(k == "_hz37apply" && p != null) { this.hz37Send("apply|" + p.id,k); }
         else if(k == "_hz37del" && p != null && p.u) { this.hz37Send("delete|" + p.id,k); }
         else if(k == "_hz37undo") { this.hz37Send("undo",k); }
         else if(k == "_hz37bak") { this.hz37Send("restore",k); }
      }
      // keys first come here: name entry and pending confirms; true = used
      private function hz37Key(code:String) : Boolean
      {
         var rows:Array = this.hzSetRows(this.hzSetTab);
         var r:Object = this.hzSetRow >= 0 && this.hzSetRow < rows.length ? rows[this.hzSetRow] : null;
         var rk:String = r != null ? String(r.k) : "";
         if(this.hz37Edit != null)
         {
            if(code.indexOf("ch:") == 0) { if(this.hz37Edit.length < 32 && this.hz42NmOk(code.substr(3,1))) { this.hz37Edit += code.substr(3,1); } this.hz37Cf = ""; return true; }
            if(code == "padx" || code == "pady") { return true; }   // pad X/Y are actions, never typed characters
            if(code == "bksp") { if(this.hz37Edit.length > 0) { this.hz37Edit = this.hz37Edit.substr(0,this.hz37Edit.length - 1); } this.hz37Cf = ""; return true; }
            if(code == "ok" || (code == "right" && rk == "_hz37save")) { this.hz37SaveSubmit(); return true; }
            if(code == "cancel" || code == "left") { this.hz37Edit = null; this.hz37Cf = ""; return true; }
            this.hz37Edit = null;   // moving away ends the name entry
            this.hz37Cf = "";
            return false;
         }
         if(code.indexOf("ch:") == 0) { return true; }   // letters do nothing outside the name entry
         if(code == "padx" || code == "pady") { return false; }   // fall through as actions, never text
         if(this.hz37Cf.length > 0)
         {
            if(r != null && rk == this.hz37Cf && (code == "ok" || code == "right" || code == "left")) { this.hz37Act(r,1); return true; }
            this.hz37Cf = "";
            return code == "cancel" || code == "bksp";   // ESC drops only the confirm
         }
         return false;
      }
      // mouse press: a click anywhere else drops a pending confirm / the name entry
      private function hz37Press(id:String, rows:Array) : void
      {
         var ri:int = -1;
         if(id.indexOf("row") == 0 || id.indexOf("inf") == 0) { ri = int(id.substr(3)); }
         else if(id.indexOf("lt") == 0 || id.indexOf("rt") == 0) { ri = int(id.substr(2)); }
         var k:String = ri >= 0 && ri < rows.length ? String(rows[ri].k) : "";
         if(k != this.hz37Cf && id.indexOf("inf") != 0) { this.hz37Cf = ""; }
         if(this.hz37Edit != null && k != "_hz37save") { this.hz37Edit = null; }
      }
      private function hz37Reset() : void
      {
         this.hz37Edit = null;
         this.hz37Cf = "";
         this.hz37Msg = "";
         this.hz37MsgK = "";
      }
      private function hz37Note(k:String, base:String) : String
      {
         var p:Object = this.hz37Cur();
         var pn:String = p != null ? "'" + String(p.n) + "'" : "the preset";
         if(this.hz37Busy == k) { return "Working..."; }
         if(this.hz37Cf == k)
         {
            if(k == "_hz37apply") { return "Replaces your settings with " + pn + ". Press again (or ENTER) to apply - any other key cancels"; }
            if(k == "_hz37del") { return "Removes " + pn + " from this list. The file stays on disk. Press again (or ENTER) to confirm - any other key cancels"; }
            if(k == "_hz37undo") { return "Puts back your settings from before the last preset. Press again (or ENTER) to confirm"; }
            if(k == "_hz37bak") { return "Replaces your settings with the update backup. Press again (or ENTER) to confirm"; }
            if(k == "_hz37save") { return "'" + this.hz37Trim(String(this.hz37Edit)) + "' already exists. Press again (or ENTER) to overwrite - ESC cancels"; }
         }
         if(k == "_hz37save" && this.hz37Edit != null) { return "Type a name - ENTER saves - ESC cancels (with a controller: confirm the suggested name)"; }
         if(this.hz37MsgK == k && this.hz37Msg.length > 0) { return this.hz37Msg; }
         return base;
      }
      // rows appended to the CONTROLS tab (none without HorizonUI.dll 0.37+)
      private function hz37Rows() : Array
      {
         var rows:Array = [];
         if(!this.hz37Dll) { return rows; }
         if(this.hz37Busy.length > 0 && new Date().getTime() - this.hz37BusyT > HZ37_BUSY_MS)
         {
            this.hz37MsgK = this.hz37Busy;
            this.hz37Msg = "Failed: no answer from HorizonUI.dll";
            this.hz37Busy = "";
            this.hz37Req = "";
         }
         var n:int = this.hz37Ps.length;
         var p:Object = this.hz37Cur();
         var skip:int = int(this.hz37St.skip);
         var cnt:String = n + (n == 1 ? " preset" : " presets") + (skip > 0 ? " - " + skip + " skipped (see log)" : "");
         if(p != null)
         {
            var d:String = String(p.d).length > 0 ? String(p.d) : "No description.";
            var by:String = String(p.a).length > 0 ? " By " + String(p.a) : "";
            var ver:String = String(p.v).length > 0 ? (by.length > 0 ? ", version " : " Version ") + String(p.v) : "";
            var inf:String = d + by + ver + "." + (p.u ? " Saved by you (presets/user)." : " Came with the mod.");
            // layering rule 5: a preset made for an older version -> its missing (newer) settings use the defaults
            var older:Boolean = this.hz37Older(String(p.v),HZ_VERSION);
            rows.push({"k":"_hz37pick","l":"PRESET","t":"p","h":"PRESETS","note":this.hz37Note("_hz37pick",older ? "Made for " + String(p.v) + ": new settings use defaults." : cnt),"info":inf,"n13":true});
         }
         else
         {
            var emptyDir:String = this.hz37St.pdir != undefined && String(this.hz37St.pdir).length > 0 ? String(this.hz37St.pdir) : "Data/Interface/HorizonUI/presets/user";
            rows.push({"k":"_hz37pick","l":"PRESET","t":"p","h":"PRESETS","off":true,"n13":true,"note":"No presets yet: save your own below" + (skip > 0 ? " - " + skip + " skipped (see log)" : ""),"info":"Presets are complete looks for Horizon UI. Saved ones go to " + emptyDir + "; the installer can add Moragar's Choice. Removing a saved preset from this list leaves its file there so you can erase it yourself."});
         }
         rows.push({"k":"_hz37apply","l":"APPLY SELECTED PRESET","t":"x","btn":"APPLY","off":p == null,"n13":true,"note":this.hz37Note("_hz37apply",null),"info":"Your settings become exactly the defaults plus what the preset sets - anything it does not list goes back to its default. Your settings key, ScreenHeight and debug switches ([Debug]) stay as they are. Applies right away; UNDO LAST PRESET puts your old settings back."});
         rows.push({"k":"_hz37save","l":"SAVE CURRENT AS PRESET","t":"x","btn":"SAVE","n13":true,"note":this.hz37Note("_hz37save",null),"info":"Saves your current look as a preset in Data/Interface/HorizonUI/presets/user: every setting that differs from the defaults (card positions, sizes, colors, fonts, Comms and Scanner included; not your settings key or ScreenHeight). Type a name with the keyboard; with a controller, confirm the suggested name."});
         var delOff:Boolean = p == null || !p.u;
         var presetDir:String = this.hz37St.pdir != undefined && String(this.hz37St.pdir).length > 0 ? String(this.hz37St.pdir) : "Data/Interface/HorizonUI/presets/user";
         rows.push({"k":"_hz37del","l":"REMOVE FROM LIST","t":"x","btn":"REMOVE","off":delOff,"n13":true,"note":this.hz37Note("_hz37del",p != null && !p.u ? "Presets that came with the mod stay on this list" : null),"info":"Hides the selected preset you saved yourself. The file stays in " + presetDir + " so you can erase it yourself. Presets that came with the mod stay on this list."});
         var undo:Boolean = String(this.hz37St.undo) == "1";
         rows.push({"k":"_hz37undo","l":"UNDO LAST PRESET","t":"x","btn":"UNDO","off":!undo,"n13":true,"note":this.hz37Note("_hz37undo",undo ? null : "Nothing to undo"),"info":"Brings back your settings from just before the last preset was applied (one step)."});
         var bak:Boolean = String(this.hz37St.bak) == "1";
         rows.push({"k":"_hz37bak","l":"RESTORE UPDATE BACKUP","t":"x","btn":"RESTORE","h":"SETTINGS FILE","off":!bak,"n13":true,"note":this.hz37Note("_hz37bak",bak ? "Your settings as they were before the last Horizon UI update" : "No backup yet - one is made automatically at the next Horizon UI update"),"info":"Horizon UI copies your settings once each time the mod updates (HorizonUI.user.bak.ini). This puts that copy back and applies it right away."});
         for each(var r:Object in rows) { if(r.note == null) { delete r.note; } }
         return rows;
      }

      // ---------- other HUD mods (install status) ----------
      private function hz37OtherHud() : Boolean
      {
         // v0.38: v0.37 warned when another HUD mod's ini / translation files existed - they stay behind after that mod is
         // removed (and ship with other mods), hence the false warning. Such a mod replaces hudmenu.gfx: while this code
         // runs, Horizon's HUD movie is the one the game loaded, so the other HUD is not active and there is nothing
         // to warn about. The real check is in HorizonUI.dll: it logs a WARN when HUDMenu does not answer Horizon's calls.
         return false;
      }
      // amber warning row: first row, or right under a module status card
      private function hz37WithWarn(rows:Array) : Array
      {
         if(!this.hz37OtherHud()) { return rows; }
         var w:Object = {"k":"_hz37warn","l":HZ37_WARN_OTHERHUD,"t":"w","dis":true};
         var at:int = rows.length > 0 && rows[0].t == "m" ? 1 : 0;
         var out:Array = rows.slice(0,at);
         out.push(w);
         return out.concat(rows.slice(at));
      }

      // ---------- drawing ----------
      private function hz37Amber(T:Object) : uint
      {
         return T.lt ? this.hzMix(HZ35_AMBER,0x000000,0.4) : HZ35_AMBER;
      }
      private function hz37DrawWarn(b:Sprite, g:*, y:Number, right:Number, T:Object, txt:String) : void
      {
         var am:uint = this.hz37Amber(T);
         var x0:Number = 22;
         var w:Number = Math.round(right + 6 - 22 - 2);
         var h:Number = 40;
         var y0:Number = Math.round(y + 2);
         g.beginFill(am,0.12); g.drawRoundRect(x0,y0,w,h,20,20); g.endFill();
         this.hz34Ring(b,x0,y0,w,h,10,am,0.85,1);
         // warning triangle
         var cx:Number = x0 + 20;
         var cy:Number = y0 + h / 2;
         g.beginFill(am,1); g.moveTo(cx,cy - 8); g.lineTo(cx + 9,cy + 7); g.lineTo(cx - 9,cy + 7); g.lineTo(cx,cy - 8); g.endFill();
         g.beginFill(uint(T.fill),1); g.drawRect(cx - 1,cy - 3,2,6); g.drawRect(cx - 1,cy + 4,2,2); g.endFill();
         var t:TextField = this.hzWT(b,txt,x0 + 38,y0 + 4,w - 50,13,"sb",am,0.2);
         t.wordWrap = true;
         t.multiline = true;
         t.width = w - 50;
         t.text = txt;
         t.height = t.textHeight + 6;
         t.y = Math.round(y0 + (h - t.textHeight) / 2 - 3);
      }
      private function hz37DrawPick(b:Sprite, g:*, r:Object, i:int, cy:Number, R:Number, T:Object) : void
      {
         var acc:uint = uint(T.acc);
         var p:Object = this.hz37Cur();
         var x:Number = R - 14;
         if(p != null && String(p.a).length > 0)
         {
            var at:TextField = this.hzWT(b,String(p.a),x,cy - 8,200,13,"rg",uint(T.mut),0.2,"right");
            x = Math.round(x - this.hzTW(at) - 10);
         }
         var nt:TextField = this.hzWT(b,p != null ? String(p.n) : "NONE",x,cy - 9,320,13,"sb",p != null ? uint(T.txt) : uint(T.mut),0.6,"right");
         x = Math.round(x - this.hzTW(nt));
         if(p != null && p.u)
         {
            var ct:TextField = this.hzWT(b,"USER",0,cy - 8,80,13,"sb",acc,1.2);
            var cw:Number = Math.round(this.hzTW(ct) + 16);
            var cx0:Number = Math.round(x - 10 - cw);
            g.beginFill(acc,0.16); g.drawRoundRect(cx0,cy - 11,cw,22,22,22); g.endFill();
            this.hz34Ring(b,cx0,Math.round(cy - 11),cw,22,11,acc,0.9,1);
            ct.x = cx0 + 8 - 2;
            x = cx0;
         }
         if(!r.off && this.hz37Ps.length > 1)
         {
            this.hzSetTri(g,x - 14,cy,-1,acc,this.hzSetHover == "lt" + i ? 1 : 0.78);
            this.hzSetTri(g,R,cy,1,acc,this.hzSetHover == "rt" + i ? 1 : 0.78);
            this.hzSetHits.push({"id":"lt" + i,"x":x - 24,"y":cy - 16,"w":22,"h":32});
            this.hzSetHits.push({"id":"rt" + i,"x":R - 10,"y":cy - 16,"w":22,"h":32});
         }
      }
      private function hz37DrawBtn(b:Sprite, g:*, r:Object, i:int, R:Number, cy:Number, rh:Boolean, T:Object) : void
      {
         var k:String = String(r.k);
         var cf:Boolean = this.hz37Cf == k;
         var ed:Boolean = k == "_hz37save" && this.hz37Edit != null;
         var lab:String = cf ? (k == "_hz37save" ? "OVERWRITE" : "CONFIRM") : String(r.btn);
         var host:Sprite = b;
         var hg:* = g;
         var dim:Boolean = r.off || (this.hz37Busy.length > 0 && this.hz37Busy != k);
         if(dim)
         {
            host = new Sprite();
            host.alpha = 0.4;
            host.mouseEnabled = false;
            host.mouseChildren = false;
            b.addChild(host);
            hg = host.graphics;
         }
         var w:Number = this.hzSetBtn(host,hg,R,cy - 14,lab,cf || ed,true,rh && !dim,T,"row" + i,13);
         if(!ed) { return; }
         var acc:uint = uint(T.acc);
         var fw:Number = 280;
         var fx:Number = Math.round(R - w - 12 - fw);
         var fy:Number = Math.round(cy - 14);
         g.beginFill(uint(T.tile),Math.max(0.3,Number(T.tia))); g.drawRoundRect(fx,fy,fw,28,20,20); g.endFill();
         this.hz34Ring(b,fx,fy,fw,28,10,acc,1,1);
         var et:TextField = this.hzWT(b,this.hz37Edit,fx + 12,fy + 6,fw - 24,13,"sb",uint(T.txt),0.4);
         var cx:Number = Math.round(fx + 12 + Math.min(fw - 26,this.hzTW(et)) + 2);
         g.beginFill(acc,1); g.drawRect(cx,fy + 6,2,16); g.endFill();   // caret
      }
      // =================== end v0.37 settings files, presets, update backup ===================

      // ===================== v0.38 hover card reliability, centered prompt card, ring clearance =====================
      // In-game feedback on v0.37: (1) for about a minute after loading nothing could be highlighted; (2) the card's
      // text sat off the card's center and the game's object ring cut through the name. v0.38: the vanilla prompt is
      // hidden only while Horizon's own card is really on screen (hz38HideVanilla is called after a successful draw; any
      // prompt Horizon does not draw gets the vanilla widget back the same frame), the card is centered and moves clear
      // of the game's object ring. v0.39: people get the same plain prompt card as objects (name + keycaps).
      private static const HZ38_PR_PAD:Number = 20;      // prompt card side padding (content is centered between)
      private static const HZ38_PR_MINW:Number = 310;
      private static const HZ38_PR_MAXW:Number = 480;    // a long name grows the card up to this, then is cut with "..."
      private static const HZ38_RING_GAP:Number = 6;
      private var hz38DrawOk:Boolean = false;   // the last hzT19Content ran to the end (no throw)
      private var hz38DrawErr:int = 0;          // throws so far (redraw retried for the first 30)
      private var hz38VanShown:Boolean = false; // the vanilla widget is currently handed back

      // prompt card width: room for the keycaps and the name (up to HZ38_PR_MAXW)
      private function hz38PromptW(fbw:Number, nmW:Number) : Number
      {
         var p2:Number = 2 * HZ38_PR_PAD;
         return Math.round(Math.max(HZ38_PR_MINW,Math.max(fbw + p2,Math.min(HZ38_PR_MAXW,nmW + p2 + 8))));
      }
      // vertical layout (card units): icon tile center (radius 23), name top (8 units under the tile), divider
      private function hz38PromptY() : Object
      {
         return {"icy":31,"nt":60,"dv":86};
      }
      // ---- vanilla prompt: hidden only behind a drawn Horizon card ----
      private function hz38HideVanilla(rw:Object, aw:Object, kind:String) : void
      {
         try { this.hzT19HideA(rw.RolloverActivationHolder_mc as DisplayObject); } catch(eH:Error) { }
         try { this.hzT19HideA(aw as DisplayObject); } catch(eA:Error) { }
         // ObjectRing: 0 always hidden, 1 shown for container lists only, 2 as the game draws it
         if(this.hzObjRing == 0 || (this.hzObjRing == 1 && kind != "list")) { this.hzT19HideReticle(rw); }
         else { this.hzT19ShowReticle(rw); }
      }
      // what to do with the vanilla widget this frame (pure; tested): "hide" or "show"
      //   mine   = Horizon owns target prompts (ShowTarget on, not hidden by the user, not a scanner mode, widget found)
      //   prompt = the game shows an activate prompt right now
      //   card   = Horizon's card is on screen this frame (drawn and visible, or still fading out)
      private function hz38VanillaRule(mine:Boolean, prompt:Boolean, card:Boolean) : String
      {
         if(!mine) { return "show"; }
         if(card) { return "hide"; }
         return prompt ? "show" : "hide";   // a prompt with no Horizon card: the game's own prompt; idle: nothing to show
      }

      // ---- object ring clearance ----
      // ObjectRing VANILLA / CONTAINERS ONLY: the game draws its ring on the object's screen point, which can fall inside
      // the card (feedback screenshot: the ring sat on the name). The card moves below the ring, or above it when there
      // is no room below. Returns the new card top, or NaN to keep it.
      private function hz38RingClear(rw:Object, kind:String, x:Number, y:Number, w:Number, h:Number, vr:Rectangle) : Number
      {
         if(rw == null || this.hzObjRing == 0 || (this.hzObjRing == 1 && kind != "list")) { return NaN; }
         var rt:DisplayObject = null;
         try { rt = rw.Reticle_mc as DisplayObject; } catch(e0:Error) { rt = null; }
         if(rt == null || !rt.visible || rt.alpha <= 0) { return NaN; }
         var b:Rectangle = rt.getBounds(this);
         if(b == null || b.width <= 0 || b.height <= 0) { return NaN; }
         return this.hz38Clear(b.x,b.y,b.width,b.height,x,y,w,h,vr == null ? NaN : vr.y + 8,vr == null ? NaN : vr.y + vr.height - 8);
      }
      // pure (tested): card (x, y, w, h) against box (bx, by, bw, bh); top / bot = the usable screen band (NaN = none)
      private function hz38Clear(bx:Number, by:Number, bw:Number, bh:Number, x:Number, y:Number, w:Number, h:Number, top:Number, bot:Number) : Number
      {
         if(x + w <= bx || bx + bw <= x || y + h <= by || by + bh <= y) { return NaN; }
         var below:Number = by + bh + HZ38_RING_GAP;
         if(isNaN(bot) || below + h <= bot) { return below; }
         var above:Number = by - HZ38_RING_GAP - h;
         if(isNaN(top) || above >= top) { return above; }
         return NaN;
      }

      // =================== end v0.38 ===================

      // ===================== v0.40: Scanner module (SCANNER tab, [Scanner] keys, HideMainHudWhileScanning) =====================
      // The scanner movie (monoclemenu.swf / _lrg) reads the same [Scanner] keys itself; this movie writes them (F11) and
      // hides its own cards while the Horizon scanner is open. Types: b 0/1, i int, f float, z size, o -1 or a number,
      // p position (-1, L/R/C+n, T/B/C+n), s hex.
      private static const HZ40_SCAN_KEYS:Array = [["ScanLayoutVersion","i",1,1,99],["ScanShowPlanet","b",1,0,1],["ScanShowBioscan","b",1,0,1],["ScanShowSignals","b",1,0,1],["ScanShowTraits","b",1,0,1],["ScanShowCompass","b",1,0,1],["ScanShowMode","b",1,0,1],["ScanShowHints","b",1,0,1],["ScanShowWorldTags","b",1,0,1],["ScanWorldMarkers","b",1,0,1],["ScanShowBodyType","b",0,0,1],["ScanShowShip","b",1,0,1],["ScanPlanetX","p","-1",0,0],["ScanPlanetY","p","-1",0,0],["ScanBioscanX","p","-1",0,0],["ScanBioscanY","p","-1",0,0],["ScanSignalsX","p","-1",0,0],["ScanSignalsY","p","-1",0,0],["ScanTraitsX","p","-1",0,0],["ScanTraitsY","p","-1",0,0],["ScanSocialX","p","-1",0,0],["ScanSocialY","p","-1",0,0],["ScanCompassX","p","-1",0,0],["ScanCompassY","p","-1",0,0],["ScanModeX","p","-1",0,0],["ScanModeY","p","-1",0,0],["ScanHintsX","p","-1",0,0],["ScanHintsY","p","-1",0,0],["ScanVitalsX","p","-1",0,0],["ScanVitalsY","p","-1",0,0],["ScanPlanetScale","z",-1,0.6,1.6],["ScanBioscanScale","z",-1,0.6,1.6],["ScanSignalsScale","z",-1,0.6,1.6],["ScanTraitsScale","z",-1,0.6,1.6],["ScanSocialScale","z",-1,0.6,1.6],["ScanCompassScale","z",-1,0.6,1.6],["ScanModeScale","z",-1,0.6,1.6],["ScanHintsScale","z",-1,0.6,1.6],["ScanWorldTagScale","z",-1,0.6,1.6],["ScanPlanetCompact","i",-1,-1,1],["ScanBioscanCompact","i",-1,-1,1],["ScanSignalsCompact","i",-1,-1,1],["ScanTraitsCompact","i",-1,-1,1],["ScanCompassCompact","i",-1,-1,1],["ScanCompactAll","i",-1,-1,1],["ScanOpacity","o",-1,0.2,1.6],["ScanAccent","i",-1,-1,13],["ScanAccentHex","s","",0,0],["ScanTextCase","i",-1,-1,1],["ScanFont","i",-1,-1,3],["ScanMargin","o",-1,20,200],["ScanUnits","i",0,0,1],["ScanMaxSignals","i",5,1,8],["ScanHazardWarn","i",50,5,95],["ScanHazardCrit","i",85,10,100],["ScanCompleteFlash","b",1,0,1],["ScanLeftToFind","b",1,0,1],["ScanMinRarity","i",0,0,4],["ScanNearestUnscanned","b",1,0,1],["HideMainHudWhileScanning","b",1,0,1],["ScanShowVitalsHealth","b",1,0,1],["ScanShowVitalsO2","b",1,0,1],["ScanShowVitalsBoost","b",1,0,1],["ScanVitalsCompact","b",0,0,1],["ScanVitalsLayout","i",0,0,1],["HideQuestPopupsWhileScanning","b",1,0,1],["DimTraitPopupDuringBioscan","b",0,0,1],["TraitPopupDim","f",0.4,0.1,0.9]];
      private static const HZ40_SCAN_CM:Object = {"ScanLayoutVersion":["Layout version (written by the HUD; do not edit)"],"ScanShowPlanet":["---- panels: 1 = shown, 0 = hidden (the other panels of a stack close up) ----"],"ScanShowWorldTags":["1 = name tag next to the picked object; ScanWorldMarkers = markers on points of interest in the view (0 also hides the HUD's floating quest markers while scanning)"],"ScanShowBodyType":["1 = body type (planet, moon, ...) after the system name in the planet card"],"ScanShowShip":["1 = YOUR SHIP and YOUR VEHICLE rows in the signals list (only when the game gives the distance); 0 = your own ship and vehicle are left out of the signals list"],"ScanSocialX":["ScanSocialX / ScanSocialY / ScanSocialScale = the social strip (social skills, bounty) shown instead of the traits card while you scan someone (-1 = the traits card's spot / size)"],"ScanPlanetX":["---- positions: -1 = default spot, L/R/C+n (X) and T/B/C+n (Y) = 1080p units from that screen edge or the center, inside the edge distance ----","(set here, by a preset or with F11 > SCANNER > ARRANGE SCANNER)"],"ScanVitalsX":["ScanVitalsX / ScanVitalsY = the vitals the HUD keeps while scanning (-1 = bottom center)"],"ScanPlanetScale":["---- sizes: -1 = [Style] HudScale (GLOBAL), 0.60 - 1.60 = this panel's own size ----","(the text scales with the panel, as on the HUD cards: below 1.00 it draws under 13 px at 1080p, about 10.4 px at 0.80)"],"ScanWorldTagScale":["World tag size (-1 = GLOBAL); the tag follows the picked object, so it has no position keys"],"ScanPlanetCompact":["---- compact form: -1 = ScanCompactAll, 0 = full card, 1 = slim strip ----"],"ScanCompactAll":["Compact all panels: -1 = [Style] Compact (GLOBAL), 0 = off, 1 = on"],"ScanOpacity":["---- look ----","Panel opacity: -1 = [Style] CardOpacity, 0.20 - 1.60"],"ScanAccent":["Accent color: -1 = the HUD accent, 0 - 12 accent palette, 13 = ScanAccentHex (#RRGGBB)"],"ScanTextCase":["Text case of Horizon's own labels: -1 = [Style] HeaderStyle, 0 = CAPS, 1 = Title (game names are never re-cased to Title)"],"ScanFont":["Font: -1 = [Style] FontFace, 1 Exo 2, 2 Roboto, 0 game font, 3 game font (semibold)"],"ScanMargin":["Edge distance: -1 = [Style] Margin, 20 - 200 (1080p units)"],"ScanUnits":["Distances: 0 = auto (m / km), 1 = meters only"],"ScanMaxSignals":["---- lists and alerts ----","Signals listed (1 - 8); the quest objective row is always kept"],"ScanHazardWarn":["Hazard rows of the planet card: amber at this exposure % (5 - 95), red at ScanHazardCrit (10 - 100, at least amber + 5)"],"ScanCompleteFlash":["---- extras ----","1 = the bioscan card flashes green when a scan is complete"],"ScanLeftToFind":["1 = 'N FAUNA LEFT / N FLORA LEFT' (planet totals) under the bioscan rows"],"ScanMinRarity":["Resources listed: 0 all, 1 uncommon and up, 2 rare and up, 3 exotic and up, 4 unique only"],"ScanNearestUnscanned":["1 = highlight the nearest undiscovered signal in the signals list"],"HideMainHudWhileScanning":["---- main HUD ----","1 = hide the Horizon HUD cards while the Horizon scanner is open (needs the Scanner module). The item card, container list,","activate prompt and combat feedback always stay. Whatever this is set to, the vanilla bottom-left planet name / type always","hides while scanning, and the floating quest markers hide while scanning only when ScanWorldMarkers=0 (POI MARKERS off)."],"ScanShowVitalsHealth":["Vitals kept on screen while HideMainHudWhileScanning hides the HUD: 1 = shown, 0 = hidden","(health, O2, boost; these replace ScanShowVitals: an old ScanShowVitals=0 still turns all three off)"],"ScanVitalsCompact":["Kept vitals form: 0 = full card, 1 = slim strip"],"ScanVitalsLayout":["Kept vitals layout: 0 = vertical stack (one stat per row), 1 = horizontal row"],"HideQuestPopupsWhileScanning":["---- scanner popups (done by the Comms HUD Messages file) ----","1 = hide quest popups and the mission toast for the whole scan"],"DimTraitPopupDuringBioscan":["1 = dim the trait popup while scanning; TraitPopupDim = its opacity (0.10 - 0.90)"]};
      private static const HZ40_POPUP:Array = ["HideQuestPopupsWhileScanning","DimTraitPopupDuringBioscan","TraitPopupDim"];
      private static const HZ40_OPA_V:Array = [-1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.1,1.2,1.3,1.4,1.5,1.6];
      private static const HZ40_OPA_N:Array = ["FOLLOW HUD","0.20","0.30","0.40","0.50","0.60","0.70","0.80","0.90","1.00","1.10","1.20","1.30","1.40","1.50","1.60"];
      private static const HZ40_MAR_V:Array = [-1,20,30,40,50,60,70,80,90,100,110,120,130,140,150,160,170,180,190,200];
      private static const HZ40_MAR_N:Array = ["FOLLOW HUD","20","30","40","50","60","70","80","90","100","110","120","130","140","150","160","170","180","190","200"];
      private static const HZ40_CARDS:Array = ["HorizonCard_mc","HorizonVitals_mc","HorizonEnv_mc","HorizonAffl_mc","HorizonQuest_mc","HorizonCompactQuest_mc","HorizonAmmo_mc","HorizonCompact_mc","HorizonCompass_mc","HorizonChar_mc","HorizonXp_mc"];
      private var hz40C:Object = null;          // current [Scanner] values
      private var hz40Scan:Boolean = false;     // the hand scanner is open (HudCompassData.bIsHandscannerOpen / FireForget)
      private var hz40Hide:Boolean = false;     // the Horizon cards are hidden for the scanner right now
      private var hz40Latch:Boolean = false;    // a safety clear stays until the scanner closes
      private var hz40LastT:Number = 0;
      private var hz40LastGV:int = -1;

      private function hz40Cfg() : Object
      {
         if(this.hz40C == null) { this.hz40C = {}; for each(var d:Array in HZ40_SCAN_KEYS) { this.hz40C[d[0]] = d[2]; } }
         return this.hz40C;
      }
      private function hz40Def(k:String) : Array
      {
         var kl:String = k.toLowerCase();
         for each(var d:Array in HZ40_SCAN_KEYS) { if(String(d[0]).toLowerCase() == kl) { return d; } }
         return null;
      }
      // unknown values or NaN -> default; numbers clamped; a bad hex / position -> default (same rules as the scanner)
      private function hz40Clamp(d:Array, v:*) : *
      {
         var t:String = String(d[1]);
         if(t == "b") { if(v === true) { return 1; } if(v === false) { return 0; } }
         var sv:String = v == null ? "" : String(v).replace(/^\s+|\s+$/g,"");
         if(t == "s") { if(sv.length == 0) { return ""; } return this.hzParseHex(sv) >= 0 ? sv : String(d[2]); }
         if(t == "p")
         {
            if(sv.length < 2) { return "-1"; }
            var a:String = sv.charAt(0).toUpperCase();
            var isX:Boolean = String(d[0]).charAt(String(d[0]).length - 1) == "X";
            var okA:Boolean = isX ? (a == "L" || a == "R" || a == "C") : (a == "T" || a == "B" || a == "C");
            var dn:Number = Number(sv.substr(1).replace(/\s/g,""));
            if(!okA || isNaN(dn)) { return "-1"; }
            return a + String(int(Math.round(dn)));
         }
         var n:Number = Number(sv);
         if(sv.length == 0 || isNaN(n)) { return d[2]; }
         if(t == "b") { return n >= 0.5 ? 1 : 0; }
         if(t == "z") { return this.hz34ScClamp(n); }
         if(t == "o") { if(n < 0) { return -1; } n = Math.max(Number(d[3]),Math.min(Number(d[4]),n)); return Math.round(n * 1000) / 1000; }
         n = Math.max(Number(d[3]),Math.min(Number(d[4]),n));
         if(t == "i") { return int(Math.round(n)); }
         return Math.round(n * 1000) / 1000;
      }
      private function hz40Num(d:Array, v:*) : String
      {
         var x:* = this.hz40Clamp(d,v);
         var t:String = String(d[1]);
         if(t == "p" || t == "s") { return String(x); }
         if(t == "f") { return Number(x).toFixed(2); }
         if(t == "z") { return this.hz34ScStr(x); }
         if(t == "o") { if(Number(x) < 0) { return "-1"; } return d[0] == "ScanMargin" ? String(int(Math.round(Number(x)))) : String(Math.round(Number(x) * 1000) / 1000); }
         return String(int(x));
      }
      private function hz40Fix(c:Object) : void
      {
         if(int(c.ScanHazardCrit) < int(c.ScanHazardWarn) + 5) { c.ScanHazardCrit = Math.min(100,int(c.ScanHazardWarn) + 5); }
         c.ScanLayoutVersion = 1;
      }
      // section-aware: [Scanner] keys (the last duplicate wins). Every read starts from the defaults.
      private function hz40ParseIni(lines:Array) : void
      {
         this.hz40C = null;
         var c:Object = this.hz40Cfg();
         var sec:String = "";
         var li:int = -1;
         var oldI:int = -1;     // v0.41.0: the last ScanShowVitals line (retired key) and its value
         var oldV:int = 1;
         var lastI:Object = {};
         for each(var ln:String in lines)
         {
            li++;
            var h:String = this.hz30Hdr(ln);
            if(h != null) { sec = h; continue; }
            if(sec != "scanner") { continue; }
            var t:String = ln;
            var sc:int = t.indexOf(";");
            if(sc >= 0) { t = t.substr(0,sc); }
            var eq:int = t.indexOf("=");
            if(eq <= 0) { continue; }
            var k:String = t.substr(0,eq).replace(/\s/g,"");
            var v:String = t.substr(eq + 1).replace(/^\s+|\s+$/g,"");
            if(k.toLowerCase() == "scanshowvitals") { var ov:Number = Number(v); if(v.length > 0 && (ov == 0 || ov == 1)) { oldI = li; oldV = int(ov); } continue; }   // r2: 0 / 1 only (the DLL no longer writes it)
            var d:Array = this.hz40Def(k);
            if(d != null) { c[d[0]] = this.hz40Clamp(d,v); lastI[d[0]] = li; }
         }
         // v0.41.0: an old ScanShowVitals line (0.40.3) sets the three stats it covered, unless a stat has its own line after it
         // (the merged text is default.ini then user.ini, so a user.ini ScanShowVitals=0 beats the default.ini stat lines)
         if(oldI >= 0) { for each(var vk:String in HZ41_VIT_KEYS) { if(lastI[vk] == undefined || int(lastI[vk]) < oldI) { c[vk] = oldV; } } }
         this.hz40Fix(c);
         this.hz40Apply();
      }
      private function hz40SetCur(cur:Object) : void
      {
         var c:Object = this.hz40Cfg();
         for each(var d:Array in HZ40_SCAN_KEYS)
         {
            if(d[0] == "ScanAccent" || d[0] == "ScanAccentHex" || d[0] == "ScanLayoutVersion") { continue; }
            cur[d[0]] = d[1] == "b" ? int(c[d[0]]) != 0 : c[d[0]];
         }
         var n:int = 14 + (this.hzParseHex(String(c.ScanAccentHex)) >= 0 ? 1 : 0);
         cur.ScanAccIdx = Math.max(0,Math.min(n - 1,int(c.ScanAccent) + 1));
      }
      private function hz40SetLive(p:Object) : void
      {
         if(p == null) { return; }
         var c:Object = this.hz40Cfg();
         for each(var d:Array in HZ40_SCAN_KEYS)
         {
            if(p[d[0]] === undefined || d[0] == "ScanAccent" || d[0] == "ScanAccentHex" || d[0] == "ScanLayoutVersion") { continue; }
            c[d[0]] = this.hz40Clamp(d,p[d[0]]);
         }
         if(p.ScanAccIdx !== undefined) { c.ScanAccent = Math.max(-1,Math.min(13,int(p.ScanAccIdx) - 1)); }
         if(p.ScanAccentHex !== undefined) { c.ScanAccentHex = this.hzParseHex(String(p.ScanAccentHex)) >= 0 ? String(p.ScanAccentHex) : ""; }
         this.hz40Fix(c);
         this.hz40Apply();
      }
      // [Scanner] writer: with the Scanner module every key; with only Comms the three popup keys (other Scan* lines in the
      // file are kept verbatim by hz30Merge / hz30Extras); with neither module the block in the file stays byte-exact.
      private function hz40ScanIniLines(a:Array, p:Object) : void
      {
         var sc:Boolean = this.hz30Mod["scanner"] === 1;
         if(!sc && this.hz30Mod["comms"] !== 1) { return; }
         this.hz40SetLive(p);
         var c:Object = this.hz40Cfg();
         a.push("[Scanner]");
         a.push("; Horizon Scanner module. Read when the hand scanner opens; set in F11 > SCANNER from the main HUD (F11 does not open inside the scanner).");
         for each(var d:Array in HZ40_SCAN_KEYS)
         {
            if(!sc && HZ40_POPUP.indexOf(d[0]) < 0) { continue; }
            var cm:Array = HZ40_SCAN_CM[d[0]] as Array;
            if(cm != null) { for each(var ln:String in cm) { a.push("; " + ln); } }
            a.push(d[0] + "=" + this.hz40Num(d,c[d[0]]));
         }
         a.push("");
      }
      // RESET SCANNER LAYOUT (positions, sizes, compact forms) / RESET ALL SCANNER SETTINGS ([Scanner] only)
      private function hz40Reset(layoutOnly:Boolean) : void
      {
         if(this.hzSetPend == null) { return; }
         for each(var d:Array in HZ40_SCAN_KEYS)
         {
            var k:String = String(d[0]);
            var lay:Boolean = /^Scan\w+(X|Y|Scale|Compact)$/.test(k) || k == "ScanCompactAll" || k == "ScanVitalsLayout";   // v0.41.0: + the vitals layout
            if(layoutOnly && !lay) { continue; }
            if(k == "ScanAccent" || k == "ScanAccentHex" || k == "ScanLayoutVersion") { continue; }
            this.hzSetPend[k] = d[1] == "b" ? int(d[2]) != 0 : d[2];
         }
         if(!layoutOnly) { this.hzSetPend.ScanAccIdx = 0; this.hzSetPend.ScanAccentHex = ""; }
      }

      private function hz40Row(k:String, l:String, t:String, extra:Object = null) : Object
      {
         var r:Object = {"k":k,"l":l,"t":t};
         if(extra != null) { for(var x:String in extra) { r[x] = extra[x]; } }
         return r;
      }
      private function hz40AccPal() : Array
      {
         var a:Array = [this.HZ_ACCENT].concat(HZ_ACCENTS);
         var hx:int = this.hzParseHex(String(this.hz40Val("ScanAccentHex")));
         if(hx >= 0) { a.push(uint(hx)); }
         return a;
      }
      private function hz40AccNames() : Array
      {
         var a:Array = ["FOLLOW HUD"].concat(HZ_SET_ACCNAMES);
         if(this.hzParseHex(String(this.hz40Val("ScanAccentHex"))) >= 0) { a.push("CUSTOM"); }
         return a;
      }
      private function hz40Val(k:String) : *
      {
         if(this.hzSetPend != null && this.hzSetPend[k] != undefined) { return this.hzSetPend[k]; }
         return this.hz40Cfg()[k];
      }
      // the three scanner popup rows (Comms features: live whenever Comms is installed, even without the Scanner)
      private function hz40PopupRows() : Array
      {
         var on:Boolean = this.hz30Mod["comms"] === 1;
         var es:Boolean = this.hz30Mod["es"] === 1;
         var r1:Object = {"k":"HideQuestPopupsWhileScanning","l":"HIDE QUEST POPUPS WHILE SCANNING","t":"b","h":"SCANNER POPUPS","note":"Also hides the mission toast while scanning"};
         var r2:Object = {"k":"DimTraitPopupDuringBioscan","l":"DIM TRAIT POPUP WHILE SCANNING","t":"b"};
         var r3:Object = {"k":"TraitPopupDim","l":"TRAIT POPUP DIM","t":"n","mn":0.1,"mx":0.9,"st":0.05,"sub":true};
         if(!on || es)
         {
            for each(var r:Object in [r1,r2,r3]) { r.dis = true; r.dv = this.hz40Val(r.k); }
            r1.note = es ? "Another mod's HUD messages file is installed: scanner popup options unavailable" : "Needs the optional Horizon HUD Messages file (Comms FOMOD option)";
         }
         return [r1,r2,r3];
      }
      private function hz40ScanRows() : Array
      {
         if(this.hz30Mod["scanner"] !== 1)
         {
            var lock:Array = this.hz30ModRows("scanner");
            return this.hz30Mod["comms"] === 1 ? lock.concat(this.hz40PopupRows()) : lock;
         }
         var szn:String = "GLOBAL = HUD SCALE (STYLE). Below 1.00 the text is under 13 px at 1080p";
         var cmn:String = "GLOBAL = COMPACT ALL PANELS (below)";
         var rows:Array = [{"k":"_hz30m_scanner","l":"","t":"m","mod":"scanner"}].concat(this.hz41TopRows()).concat([
            {"k":"ScanShowPlanet","l":"PLANET CARD","t":"b","h":"PANELS","note":"Applies the next time you open the scanner"},this.hz34Sz("ScanPlanet",szn),this.hz34Cmp("ScanPlanet",cmn),
            {"k":"ScanShowBodyType","l":"BODY TYPE AFTER SYSTEM NAME","t":"b","sub":true},
            {"k":"ScanShowBioscan","l":"BIOSCAN","t":"b"},this.hz34Sz("ScanBioscan"),this.hz34Cmp("ScanBioscan"),
            {"k":"ScanShowSignals","l":"SIGNALS","t":"b"},this.hz34Sz("ScanSignals"),this.hz34Cmp("ScanSignals"),
            {"k":"ScanMaxSignals","l":"MAX SIGNALS LISTED","t":"n","mn":1,"mx":8,"st":1,"sub":true,"note":"The quest objective row is always kept"},
            {"k":"ScanShowShip","l":"YOUR SHIP ROW","t":"b","sub":true,"note":"Also the YOUR VEHICLE row. Off: your own ship and vehicle are left out of Signals"},
            {"k":"ScanShowTraits","l":"TRAITS + RESOURCES","t":"b","note":"A person scan shows the social skills and bounty here instead"},this.hz34Sz("ScanTraits"),this.hz34Cmp("ScanTraits"),
            {"k":"ScanShowCompass","l":"COMPASS","t":"b"},this.hz34Sz("ScanCompass"),this.hz34Cmp("ScanCompass"),
            {"k":"ScanShowMode","l":"MODE PILL","t":"b"},this.hz34Sz("ScanMode"),
            {"k":"ScanShowHints","l":"BUTTON HINTS","t":"b","note":"The keys still work with the hints off"},this.hz34Sz("ScanHints"),
            {"k":"ScanShowWorldTags","l":"WORLD TAGS","t":"b"},
            {"k":"ScanWorldMarkers","l":"POI MARKERS","t":"b","sub":true,"note":"Needs WORLD TAGS. Off also hides the HUD quest markers while scanning"},
            {"k":"ScanWorldTagScale","l":"WORLD TAG SIZE","t":"z","sub":true},
            {"k":"ScanCompactAll","l":"COMPACT ALL PANELS","t":"r","opts":["GLOBAL","ON","OFF"],"ids":[-1,1,0],"h":"COMPACT","note":"GLOBAL = COMPACT MODE (CARDS)"},
            {"k":"ScanCompleteFlash","l":"SCAN-COMPLETE FLASH","t":"b","h":"EXTRAS"},
            {"k":"ScanLeftToFind","l":"\"LEFT TO FIND\" COUNTS","t":"b","note":"Planet totals under the bioscan rows"},
            {"k":"ScanMinRarity","l":"RESOURCES SHOWN","t":"r","opts":["ALL","UNCOMMON+","RARE+","EXOTIC+","UNIQUE"],"ids":[0,1,2,3,4]},
            {"k":"ScanNearestUnscanned","l":"HIGHLIGHT NEAREST UNDISCOVERED","t":"b","note":"Signals list only"},
            {"k":"ScanOpacity","l":"OPACITY","t":"l","vals":HZ40_OPA_V,"names":HZ40_OPA_N,"h":"LOOK","note":"FOLLOW HUD = CARD OPACITY (STYLE)"},
            {"k":"ScanAccIdx","l":"ACCENT","t":"a","pal":this.hz40AccPal(),"names":this.hz40AccNames(),"note":"Custom: ScanAccent=13 + ScanAccentHex=#RRGGBB in the ini"},
            {"k":"ScanTextCase","l":"TEXT CASE","t":"r","opts":["FOLLOW HUD","CAPS","TITLE"],"ids":[-1,0,1],"note":"Game names are never re-cased to Title"},
            {"k":"ScanFont","l":"FONT","t":"r","opts":HZ31_FONT_OPTS,"ids":HZ31_FONT_IDS,"note":int(this.hz40Val("ScanFont")) == 3 ? this.hz34SemiNote() : "Global font is in TEXT."},
            {"k":"ScanMargin","l":"EDGE DISTANCE","t":"l","vals":HZ40_MAR_V,"names":HZ40_MAR_N,"note":"FOLLOW HUD = MARGIN (STYLE)"},
            {"k":"ScanUnits","l":"DISTANCE UNITS","t":"r","opts":["AUTO M / KM","METERS"],"ids":[0,1]},
            {"k":"ScanHazardWarn","l":"AMBER AT EXPOSURE %","t":"n","mn":5,"mx":95,"st":5,"h":"HAZARDS"},
            {"k":"ScanHazardCrit","l":"RED AT EXPOSURE %","t":"n","mn":10,"mx":100,"st":5,"note":"Always at least AMBER + 5. Exposure: one suit value shared by all active hazards; the color shows the severity"}]);
         rows = rows.concat(this.hz40PopupRows());
         rows.push({"k":"_hz40rstlay","l":"RESET SCANNER LAYOUT","t":"x","btn":"RESET","h":"RESET","note":"Positions: ARRANGE SCANNER, the [Scanner] keys (HorizonUI.user.ini) or a preset. Resets positions, sizes, compact forms and the vitals form / layout"});
         rows.push({"k":"_hz40rstall","l":"RESET ALL SCANNER SETTINGS","t":"x","btn":"RESET","note":"[Scanner] only: CARDS / STYLE / COMMS settings are kept"});
         return rows;
      }

      // ---------- hide the Horizon HUD while the Horizon scanner is open (D2, D5) ----------
      private function hz40Init() : void
      {
         BSUIDataManager.Subscribe("FireForgetEventData",this.hz40OnFF);
      }
      private function hz40HasFF(data:Object, n:String) : Boolean
      {
         try { for each(var o:Object in data.aEvents) { if(o != null && o.sEventName == n) { return true; } } } catch(e:Error) { }
         return false;
      }
      // backup signal (whether this movie receives FireForgetEventData is checked in game); the ship scanner never hides
      private function hz40OnFF(ev:FromClientDataEvent) : void
      {
         try
         {
            if(this.hz40HasFF(ev.data,"LoadingMenu_Opened") || this.hz40HasFF(ev.data,"LoadingMenu_Closed")) { this.hzAfOnLoad(); }
            if(this.hz41DllFresh()) { return; }   // v0.41.0: the DLL push is the scan state
            if(this.hz40HasFF(ev.data,"MonocleMenu_Opened")) { this.hz40SetScan(true); }
            else if(this.hz40HasFF(ev.data,"MonocleMenu_Closed")) { this.hz40SetScan(false); }
         }
         catch(e:Error) { }
      }
      private function hz40OnCmp(d:Object) : void
      {
         if(d == null || d.bIsHandscannerOpen === undefined) { return; }
         if(this.hz41DllFresh() && (d.bIsHandscannerOpen === true) != this.hz41DllOn) { return; }   // v0.41.0: a tool switch flicker; the DLL push wins
         this.hz40SetScan(d.bIsHandscannerOpen === true);
      }
      private function hz40SetScan(on:Boolean) : void
      {
         if(!on) { this.hz40Latch = false; }
         this.hz40Scan = on;
         this.hz40Apply();
         try { this.hz41LocHide(); } catch(e41e:Error) { }   // v0.42.0 r3: re-assert on every scan edge
      }
      private function hz40Want() : Boolean
      {
         // keep cards hidden while scanning (ARRANGE still shows them; v0.42.0: F11 cannot open while scanning)
         return this.hz40Scan && !this.hz40Latch && int(this.hz40Cfg().HideMainHudWhileScanning) == 1 && this.hz30Mod["scanner"] === 1 && !this.hzArrange;
      }
      private function hz40Apply() : void
      {
         var h:Boolean = this.hz40Want();
         if(h == this.hz40Hide) { return; }
         this.hz40Hide = h;
         if(h) { try { this.hz40ForceHide(); } catch(e:Error) { } }
         this.hzRefreshVisibility();   // restore: rules, fades and opacity are recomputed from scratch
      }
      // safety net: clear the hide (latch = keep it off until the scanner closes)
      private function hz40Clear(latch:Boolean) : void
      {
         if(latch) { this.hz40Latch = true; }
         if(!this.hz40Hide) { return; }
         this.hz40Hide = false;
         this.hzRefreshVisibility();
      }
      // v0.42.0: F11 opens from the main HUD only. While the hand scanner is open the key does nothing (the DLL ignores it
      // too while MonocleMenu is open, and closes a window left open when the scanner opens). Closing / ARRANGE exit still
      // work (hzToggleSettings asks this only before opening). ARRANGE SCANNER is started from F11 > SCANNER outside.
      private function hz40F11Block() : Boolean
      {
         return this.hz40Scan;
      }
      // v0.40.2: the game's floating quest markers (FloatingQuestMarkerBase > FloatingTarget > Text_mc.Text_tf: objective
      // name, or the distance) are drawn by the game in its own face. Horizon only swaps the font name (size, color,
      // alignment and text stay the game's; a size under 13 px is raised to 13), every 10 frames, on the field and its
      // default format, and only while the HUD uses a face other than the game font (FontFace / font module).
      // v0.40.3: a new marker is done at once (not after up to 10 frames); when the HUD goes back to the game font (FontFace,
      // or the font module is gone) the labels get the game's own face back ($MAIN_Font_Bold, the face of the game's field)
      private var hz42QmN:int = 0;
      private var hz42QmDone:int = 0;
      private var hz43QmKids:int = -1;
      private var hz43QmSwapped:Boolean = false;
      private static const HZ43_QM_GAME:String = "$MAIN_Font_Bold";
      private function hz42QmFont() : void
      {
         var base:DisplayObjectContainer = this.FloatingQuestMarkerBase as DisplayObjectContainer;
         if(base == null) { return; }
         var grew:Boolean = base.numChildren > this.hz43QmKids;
         this.hz43QmKids = base.numChildren;
         if(++this.hz42QmN % 10 != 0 && !grew) { return; }
         var game:String = this.hzFont ? this.hzFont : "$MAIN_Font";
         var fn:String = this.hzFontName("sb");
         if(fn == null || fn == game)
         {
            if(!this.hz43QmSwapped) { return; }
            fn = HZ43_QM_GAME;
            this.hz43QmSwapped = false;
         }
         else { this.hz43QmSwapped = true; }
         var i:int = 0;
         while(i < base.numChildren)
         {
            var tf:TextField = null;
            try { tf = Object(base.getChildAt(i)).Text_mc.Text_tf as TextField; } catch(e0:Error) { tf = null; }
            if(tf != null)
            {
               var f:TextFormat = tf.defaultTextFormat;
               if(f.font != fn)
               {
                  f.font = fn;
                  if(f.size != null && Number(f.size) < 13) { f.size = 13; }
                  tf.defaultTextFormat = f;
               }
               if(tf.length > 0)
               {
                  var c:TextFormat = tf.getTextFormat(0,1);
                  if(c.font != fn)
                  {
                     var nf:TextFormat = new TextFormat(fn);
                     if(c.size != null && Number(c.size) < 13) { nf.size = 13; }
                     tf.setTextFormat(nf);
                     this.hz42QmDone++;
                  }
               }
            }
            i++;
         }
      }
      // every frame: a frame gap over 1 s (a load) or a HUD group visibility change clears the hide; the next scanner
      // update sets it again while the scanner is really open
      private function hz40Frame() : void
      {
         var now:Number = new Date().getTime();
         if(this.hz40LastT > 0 && now - this.hz40LastT > 1000 && (this.hz40Hide || this.hz40Scan)) { this.hz40Scan = false; this.hz40Latch = false; this.hz40Clear(false); }   // v0.40.3: a latched scan / HideMainHudWhileScanning=0 too
         this.hz40LastT = now;
         var gv:int = this.hzGroupVisible ? 1 : 0;
         if(gv != this.hz40LastGV)
         {
            if(this.hz40LastGV >= 0 && (this.hz40Hide || this.hz40Scan) && !(this.hz41DllFresh() && this.hz41DllOn)) { this.hz40Scan = false; this.hz40Latch = false; this.hz40Clear(false); }   // v0.40.1: ends the scan state too (v0.40.3: also when nothing is hidden)
            this.hz40LastGV = gv;
         }
         try { this.hz41VitTick(); } catch(e41v:Error) { }
         try { this.hz41LocHide(); } catch(e41l:Error) { }   // r3
         try { this.hz41QmHide(); } catch(e41q:Error) { }    // r3
      }
      // v0.40.3: ScanShowVitals=1 (default) keeps the vitals cards on screen while the scanner hides the HUD: the jetpack / boost
      // card and the health / O2 card (in COMPACT MODE the compact strips), at their HUD place and size. Moving them and a
      // scanner-only form come with ARRANGE SCANNER.
      private static const HZ43_VIT_CARDS:Array = ["HorizonCard_mc","HorizonVitals_mc","HorizonCompact_mc"];
      private function hz43KeepVit() : Boolean
      {
         return false;   // v0.41.0: the vitals kept while scanning are the hz41V strip (ScanShowVitalsHealth / O2 / Boost)
      }
      private function hz40ForceHide() : void
      {
         var keep:Boolean = this.hz43KeepVit();
         for each(var n:String in HZ40_CARDS)
         {
            if(keep && HZ43_VIT_CARDS.indexOf(n) >= 0) { continue; }
            var c:Sprite = null;
            try { c = this[n] as Sprite; } catch(e:Error) { c = null; }
            if(c == null) { continue; }
            c.visible = false;
            c.alpha = 0;
            for each(var f:Object in this.hzFades) { if(f.c == c) { f.s = 0; f.t = 0; } }
         }
      }
      // ===================== v0.41.0: vitals while scanning, ARRANGE SCANNER, DLL scan state =====================
      // The vitals the HUD keeps while the scanner hides it (HideMainHudWhileScanning=1) are no longer the HUD cards: they are
      // one Horizon strip (hz41V) with the stats the player keeps (ScanShowVitalsHealth / O2 / Boost), full or compact
      // (ScanVitalsCompact), stacked or in a row (ScanVitalsLayout), at ScanVitalsX / ScanVitalsY (the scanner's position
      // format; -1 = bottom center). Text 13 px or larger at 1080p before HudScale.
      private static const HZ41_VIT_KEYS:Array = ["ScanShowVitalsHealth","ScanShowVitalsO2","ScanShowVitalsBoost"];
      private static const HZ41_VIT_IDS:Array = ["hp","o2","bo"];
      private static const HZ41_VIT_LBL:Array = ["HEALTH","O2","BOOST"];
      private static const HZ41_SA_PANELS:Array = ["Planet","Bioscan","Signals","Traits","Social","Compass","Mode","Hints","Vitals"];
      private static const HZ41_SA_NAMES:Array = ["PLANET","BIOSCAN","SIGNALS","TRAITS + RESOURCES","PERSON","COMPASS","MODE","BUTTON HINTS","VITALS"];
      private static const HZ41_SA_CMP:Array = ["Planet","Bioscan","Signals","Traits","Compass"];
      private var hz41V:Sprite = null;
      private var hz41VSig:String = "";
      private var hz41DllT:Number = 0;          // last DLL push (ms)
      private var hz41DllOn:Boolean = false;    // MonocleMenu open, as the DLL saw it
      private var hz41SA:Boolean = false;       // ARRANGE SCANNER is on (the ARRANGE CARDS engine runs on the mock panels)
      private var hz41SA_mc:Sprite = null;
      private var hz41SAP:Object = {};
      private var hz41SAOrig:Object = null;
      private var hz41VTx:Array = [];        // r2: the value text fields of the kept vitals strip (updated in place)
      private var hz41VLay:String = "";      // r2: layout signature of the strip (a change rebuilds it)
      private var hz41Op:Number = 1;         // r2: the game's HUD opacity (HUDOpacityData fHUDOpacity)
      private var hz41OpSub:Boolean = false;

      // ---- v0.41.0 test r3 / r4 / r6: while the hand scanner is open (and the Scanner module is installed), the game's planet
      // location alert (BottomLeftGroup_mc.LocationAlertText, filled by the game itself) is hidden. r6: always, whether or not
      // the PLANET CARD is on (ScanShowPlanet): with the card off the vanilla bottom-left planet name / type must still stay
      // gone. r4: hidden with visible = false, never by alpha (the BottomLeftGroup timeline fades its alpha in and out with the
      // scan; a script alpha write would fight it). Never removed; the visible value seen before goes back when the scan ends
      // (close, a load, F11 / the F11 latch, ARRANGE).
      // v0.42.0.4: FadeOutPlanetInfo stops on timeline frame 245 (0-based) and leaves that label current.
      // AS3 currentFrame is 1-based, so the playhead rests at 246. After the 1.5 s grace, the hide ends when the label
      // is not a planet-info label, currentFrame is 246, or the playhead has not moved since the previous frame tick.
      // A FadeInPlanetInfo that starts after the scan ended does not keep the hide going, and it does not start a new one.
      // v0.42.0.5: FadeInPlanetInfo holds on currentFrame 228. That stall is the landing alert still on screen, not the
      // end of the clip. If this scan saw that hold (already there, or the same FadeIn reached it before the grace ended),
      // the alert stays hidden after the grace until the game leaves the hold, or for 30 s, whichever comes first.
      // Leaving the hold is a new FadeIn, any other label, or currentFrame moving off 228 while the label is still FadeIn.
      // FadeOutPlanetInfo stays hidden until currentFrame 246, a stalled playhead, or a different label. The 30 s cap still ends it.
      // A landing alert with no scan is left alone. Visible only; nothing is removed. Both HUD sizes use this block.
      // With POI MARKERS off (ScanWorldMarkers=0) the game's floating quest markers (FloatingQuestMarkerBase) too, by alpha
      // (the game itself sets that alpha to the HUD opacity); r4: restored to the game's current HUD opacity (hz41Op).
      private var hz41LocBlg:Object = null;    // BottomLeftGroup_mc (own lookup: hzBlg exists only with the vanilla watch hide)
      private var hz41LocC:Object = null;      // the hidden LocationAlertText instance
      private var hz41LocV:Boolean = true;     // r4: its visible value before the hide
      private var hz41LocHid:Boolean = false;
      // v0.42.0 r3: hide session (scan + grace + planet-info leftovers), see hz41LocWant
      private static const HZ41_LOC_GRACE:Number = 1500;
      // currentFrame where FadeInPlanetInfo rests. hz41LocHoldAfterGrace reads currentFrame, and that stall is 228.
      private static const HZ41_LOC_HOLD:int = 228;
      // currentFrame where FadeOutPlanetInfo rests (timeline frame 245, 1-based).
      private static const HZ41_LOC_REST:int = 246;
      // After the scan ends, the 228 hold cannot keep the vanilla alert hidden longer than this.
      private static const HZ41_LOC_HOLD_MAX:Number = 30000;
      private var hz41LocArm:Boolean = false;   // a scan happened; its planet-info timeline leftovers stay hidden
      private var hz41LocEnd:Number = -1;       // when the scan ended (ms), -1 = scanning / none
      private var hz41LocAt:String = "";        // v0.42.0.4: label at the moment the scan ended
      private var hz41LocLeftIn:Boolean = false; // v0.42.0.4: saw a label other than FadeIn after the scan ended
      private var hz41LocPf:int = -1;           // v0.42.0.4: currentFrame on the previous frame tick
      private var hz41LocPfN:int = -1;          // v0.42.0.4: hzFrameN of that sample (enterFrame and exitFrame share a tick)
      private var hz41LocSawHold:Boolean = false; // v0.42.0.5: this scan saw FadeInPlanetInfo resting on 228
      public var hz41NowFn:Function = null;     // tests: mocked clock
      public var hz41LocLblFn:Function = null;  // tests: mocked timeline label
      public var hz41LocFrameFn:Function = null; // tests: mocked currentFrame
      private var hz41QmHid:Boolean = false;
      private function hz41ScanHideOn() : Boolean
      {
         // planet location / floating quest hides while scanning (v0.42.0: F11 cannot open while scanning)
         return this.hz40Scan && !this.hz40Latch && this.hz30Mod["scanner"] === 1 && !this.hzArrange;
      }
      // Grace and the 30 s cap.
      // Purpose: milliseconds for the 1.5 s grace and the 30 s cap.
      // new Date() is the wall clock. A step backwards (since < 0, or elapsed < 0) ends the hide instead of holding it open.
      // getTimer() is monotonic, but this block is injected as members of HUDMenu. That class does not
      // import getTimer, and an import is not legal inside the injected class body. A qualified flash.utils call
      // compiles in ffdec and then throws ReferenceError #1065 (it looks up a global named flash).
      // The exitFrame and scan-edge try/catch swallow that, so the landing alert would stay hidden for the session.
      // Inputs: hz41NowFn when a test supplies a clock, otherwise the wall clock. Output: milliseconds. No logging.
      private function hz41Now() : Number
      {
         if(this.hz41NowFn != null) { return Number(this.hz41NowFn()); }
         return new Date().getTime();
      }
      private function hz41LocLbl() : String
      {
         try
         {
            if(this.hz41LocLblFn != null) { var m:* = this.hz41LocLblFn(); return m == null ? "" : String(m); }
            var l:* = this.hz41LocBlg != null ? this.hz41LocBlg["currentLabel"] : null;
            return l == null ? "" : String(l);
         }
         catch(e:Error) { }
         return "";
      }
      private function hz41LocFrame() : int
      {
         try
         {
            var f:* = null;
            if(this.hz41LocFrameFn != null) { f = this.hz41LocFrameFn(); }
            else if(this.hz41LocBlg != null) { f = this.hz41LocBlg["currentFrame"]; }
            if(f == null || isNaN(Number(f))) { return -1; }
            return int(f);
         }
         catch(e:Error) { }
         return -1;
      }
      private function hz41LocClear() : void
      {
         this.hz41LocArm = false;
         this.hz41LocEnd = -1;
         this.hz41LocAt = "";
         this.hz41LocLeftIn = false;
         this.hz41LocPf = -1;
         this.hz41LocPfN = -1;
         this.hz41LocSawHold = false;
      }
      private function hz41LocAtHold(lb:String, fr:int) : Boolean
      {
         return lb == "FadeInPlanetInfo" && fr == HZ41_LOC_HOLD;
      }
      // Remember the playhead once per frame tick. enterFrame and exitFrame both call in, and they share hzFrameN.
      private function hz41LocNoteFrame() : void
      {
         var fr:int = this.hz41LocFrame();
         if(fr < 0 || this.hzFrameN == this.hz41LocPfN) { return; }
         this.hz41LocPf = fr;
         this.hz41LocPfN = this.hzFrameN;
      }
      // After the grace. A 228 hold this scan already saw stays hidden. Every other stall still ends the session.
      private function hz41LocHoldAfterGrace() : Boolean
      {
         var lb:String = this.hz41LocLbl();
         var fr:int = this.hz41LocFrame();
         var planet:Boolean = lb == "FadeInPlanetInfo" || lb == "FadeOutPlanetInfo";
         // A FadeIn that was not already playing when the scan ended, or that starts again later, is a new alert.
         var newIn:Boolean = lb == "FadeInPlanetInfo" && (this.hz41LocAt != "FadeInPlanetInfo" || this.hz41LocLeftIn);
         // An empty read is a failed lookup, not a different label. It must not turn the same FadeIn into a new one.
         if(lb != "" && lb != "FadeInPlanetInfo") { this.hz41LocLeftIn = true; }
         var stopped:Boolean = false;
         if(fr >= 0 && this.hzFrameN != this.hz41LocPfN)
         {
            if(this.hz41LocPf >= 0 && fr == this.hz41LocPf) { stopped = true; }
            this.hz41LocPf = fr;
            this.hz41LocPfN = this.hzFrameN;
         }
         var elapsed:Number = this.hz41Now() - this.hz41LocEnd;
         var expired:Boolean = this.hz41LocEnd >= 0 && (elapsed < 0 || elapsed >= HZ41_LOC_HOLD_MAX);
         if(expired) { return false; }
         if(this.hz41LocSawHold)
         {
            // Still the landing hold. The stopped playhead is the game keeping the alert up.
            if(!newIn && this.hz41LocAtHold(lb, fr)) { return true; }
            // A failed label read is not the game leaving the hold. The 30 s cap still ends it.
            if(lb == "") { return true; }
            // The fade-out's first frames are still the planet name (alpha falling for about 80 ms).
            // Keep it hidden until frame 246 or a stall, the same end as the branch below. A different label ends it.
            if(lb == "FadeOutPlanetInfo")
            {
               if(fr == HZ41_LOC_REST || stopped) { return false; }
               return true;
            }
            // Left that hold: a new fade-in, another label, or currentFrame moved off 228.
            if(newIn || !planet || (fr >= 0 && fr != HZ41_LOC_HOLD)) { return false; }
            return true;   // frame not readable yet; the 30 s cap still ends it
         }
         // v0.42.0.4: no 228 hold on this scan. Rest at 246, any stall, a new FadeIn, or another label ends it.
         if(!planet || newIn || fr == HZ41_LOC_REST || stopped) { return false; }
         return true;
      }
      // true while scanning (always, not gated on ScanShowPlanet), for 1.5 s after the scan ends, then while a
      // planet-info clip from that scan is still playing. A 228 hold seen during the scan stays hidden until the game
      // leaves it. FadeOutPlanetInfo stays hidden until currentFrame 246 or a stall. 30 s after the scan ends always ends it.
      // No scan: false, so a landing alert by itself stays vanilla.
      private function hz41LocWant() : Boolean
      {
         if(this.hz41ScanHideOn())
         {
            this.hz41LocArm = true;
            this.hz41LocEnd = -1;
            this.hz41LocAt = "";
            this.hz41LocLeftIn = false;
            this.hz41LocPf = -1;
            this.hz41LocPfN = -1;
            if(this.hz41LocAtHold(this.hz41LocLbl(), this.hz41LocFrame())) { this.hz41LocSawHold = true; }
            return true;
         }
         if(!this.hz41LocArm) { return false; }
         if(this.hz40Latch || this.hz30Mod["scanner"] !== 1 || this.hzArrange) { this.hz41LocClear(); return false; }
         var now:Number = this.hz41Now();
         if(this.hz41LocEnd < 0)
         {
            this.hz41LocEnd = now;
            this.hz41LocAt = this.hz41LocLbl();
            this.hz41LocLeftIn = false;
            this.hz41LocPf = -1;
            this.hz41LocPfN = -1;
         }
         var since:Number = now - this.hz41LocEnd;
         if(since < 0) { this.hz41LocClear(); return false; }
         if(since < HZ41_LOC_GRACE)
         {
            var gl:String = this.hz41LocLbl();
            if(gl != "" && gl != "FadeInPlanetInfo") { this.hz41LocLeftIn = true; }
            // The same FadeIn can reach the hold during the grace. A later FadeIn must not.
            if(!this.hz41LocSawHold && !this.hz41LocLeftIn && this.hz41LocAt == "FadeInPlanetInfo" && this.hz41LocAtHold(gl, this.hz41LocFrame()))
            {
               this.hz41LocSawHold = true;
            }
            this.hz41LocNoteFrame();
            return true;
         }
         if(!this.hz41LocHoldAfterGrace()) { this.hz41LocClear(); return false; }
         return true;
      }
      private function hz41LocHide() : void
      {
         var want:Boolean = this.hz41LocWant();   // r3: hide session (r6: always while scanning, not gated on ScanShowPlanet)
         if(!want && !this.hz41LocHid) { return; }
         if(this.hz41LocBlg == null && this.hzBlg != null) { this.hz41LocBlg = this.hzBlg; }
         if(this.hz41LocBlg == null && want && this.hzFrameN % 10 == 1) { this.hz41LocBlg = this.hzFindByName(this,"BottomLeftGroup_mc",0); }
         var c:Object = null;
         try { c = this.hz41LocBlg != null ? this.hz41LocBlg.getChildByName("LocationAlertText") : null; } catch(e0:Error) { c = null; }
         if(want)
         {
            if(c == null) { return; }
            if(!this.hz41LocHid) { this.hz41LocV = Boolean(c.visible); }   // r3: captured once per session (never the hidden state)
            if(this.hz41LocHid && this.hz41LocC != null && c != this.hz41LocC) { this.hz41LocC.visible = this.hz41LocV; }   // the timeline replaced it: the old one gets its visible value back
            this.hz41LocC = c;
            if(c.visible) { c.visible = false; }   // r3: re-hidden whenever the game shows it again
            this.hz41LocHid = true;
            return;
         }
         if(this.hz41LocC != null) { this.hz41LocC.visible = this.hz41LocV; }
         this.hz41LocC = null;
         this.hz41LocHid = false;
      }
      private function hz41QmHide() : void
      {
         var want:Boolean = this.hz41ScanHideOn() && !this.hz41B(this.hz40Cfg().ScanWorldMarkers);
         if(!want && !this.hz41QmHid) { return; }
         var b:Object = this.FloatingQuestMarkerBase;
         if(b == null) { return; }
         if(want)
         {
            b.alpha = 0;
            this.hz41QmHid = true;
            return;
         }
         b.alpha = this.hz41Op;   // r4: the game's current HUD opacity (what the game itself writes there)
         this.hz41QmHid = false;
      }
      private function hz41B(v:*) : Boolean
      {
         if(v === true) { return true; }
         if(v === false || v == null) { return false; }
         return Number(v) >= 0.5;
      }
      private function hz41Get(k:String, live:Boolean) : *
      {
         return live ? this.hz40Cfg()[k] : this.hz40Val(k);
      }
      // F11 SCANNER: LAYOUT and MAIN HUD come first (v0.41.0)
      private function hz41TopRows() : Array
      {
         var arr:Object = {"k":"_hz41arrscan","l":"ARRANGE SCANNER","t":"x","btn":"ARRANGE","h":"LAYOUT","note":"Mock scanner on the HUD: drag the panels and the kept vitals, then SAVE"};
         if(this.hz40Scan) { arr.dis = true; arr.dv = 0; arr.note = "Close the scanner first"; }
         var rows:Array = [arr,
            {"k":"HideMainHudWhileScanning","l":"HIDE HORIZON HUD WHILE SCANNING","t":"b","h":"MAIN HUD","note":"Item card, container list, activate prompt and combat feedback always stay"},
            {"k":"ScanShowVitalsHealth","l":"KEEP HEALTH","t":"b","sub":true,"note":"Kept on screen while the scanner hides the HUD (one vitals strip)"},
            {"k":"ScanShowVitalsO2","l":"KEEP O2","t":"b","sub":true},
            {"k":"ScanShowVitalsBoost","l":"KEEP BOOST","t":"b","sub":true},
            {"k":"ScanVitalsCompact","l":"COMPACT VITALS","t":"b","sub":true,"note":"Position: ARRANGE SCANNER (ScanVitalsX / ScanVitalsY)"},
            {"k":"ScanVitalsLayout","l":"VITALS LAYOUT","t":"r","opts":["VERTICAL","HORIZONTAL"],"ids":[0,1],"sub":true}];
         if(!this.hz41B(this.hz40Val("HideMainHudWhileScanning")))
         {
            var i:int = 2;
            while(i < rows.length) { rows[i].dis = true; rows[i].dv = this.hz40Val(String(rows[i].k)); i++; }
            rows[2].note = "Only used while HIDE HORIZON HUD WHILE SCANNING is on (the HUD stays whole otherwise)";
         }
         return rows;
      }

      // ---------- the kept vitals ----------
      private function hz41VitSt(live:Boolean) : Array
      {
         var a:Array = [];
         var i:int = 0;
         while(i < HZ41_VIT_KEYS.length)
         {
            if(this.hz41B(this.hz41Get(String(HZ41_VIT_KEYS[i]),live)) && (!live || HZ41_VIT_IDS[i] != "bo" || this.hzJetCharge >= 0)) { a.push(HZ41_VIT_IDS[i]); }
            i++;
         }
         return a;
      }
      private function hz41VitF(id:String) : Number
      {
         var f:Number = id == "hp" ? this.hzVitHpF : (id == "o2" ? this.hzVitO2F : this.hzJetCharge);
         return isNaN(f) ? 0 : Math.max(0,Math.min(1,f));
      }
      private function hz41VitCol(id:String, f:Number) : uint
      {
         if(id == "hp") { return f <= 0.3 ? HZ_RED : (f <= 0.6 ? HZ_YELLOW : HZ_GREEN); }
         if(id == "o2") { return f < 0.25 ? 0xF2735F : HZ_O2_BLUE; }
         return HZ_ACCENT;
      }
      private function hz41Bar(g:*, x:Number, y:Number, w:Number, h:Number, f:Number, col:uint) : void
      {
         g.beginFill(0xFFFFFF,0.12); g.drawRoundRect(x,y,w,h,h,h); g.endFill();
         g.beginFill(col,1); g.drawRoundRect(x,y,Math.max(h,w * f),h,h,h); g.endFill();
      }
      // st = stat ids, fr = id -> 0..1; returns [w, h] in 1080p units (the sprite is scaled by the caller)
      private function hz41VitDraw(p:Sprite, st:Array, fr:Object, cmp:Boolean, hor:Boolean, upd:Boolean = false) : Array
      {
         var mine:Boolean = p == this.hz41V;
         var keep:Boolean = upd && mine && this.hz41VTx.length == st.length;   // r2: values only: the text fields stay
         if(!keep) { while(p.numChildren > 0) { p.removeChildAt(0); } if(mine) { this.hz41VTx = []; } }
         var g:* = p.graphics;
         g.clear();
         var n:int = st.length;
         var cw:Number = cmp ? 100 : 150;
         var w:Number;
         var h:Number;
         if(cmp && hor) { w = 28 + n * cw + (n - 1) * 12; h = 40; }
         else if(cmp) { w = 220; h = 12 + n * 24; }
         else if(hor) { w = 32 + n * cw + (n - 1) * 16; h = 56; }
         else { w = 300; h = 18 + n * 36; }
         this.hzSetBox(g,0,0,w,h,0xFFFFFF,0.12,0x0B1620,0.82,cmp ? 24 : 32);
         var i:int = 0;
         while(i < n)
         {
            var id:String = String(st[i]);
            var f:Number = Number(fr[id]);
            var col:uint = this.hz41VitCol(id,f);
            var lab:String = String(HZ41_VIT_LBL[HZ41_VIT_IDS.indexOf(id)]);
            var val:String = Math.round(f * 100) + "%";
            var lx:Number; var ly:Number; var lw:Number; var vx:Number; var vy:Number; var vw:Number; var bx:Number; var by:Number; var bw:Number; var bh:Number;
            if(cmp && hor) { var x0:Number = 14 + i * (cw + 12); lx = x0; ly = 5; lw = cw; vx = x0; vy = 5; vw = cw; bx = x0; by = 27; bw = cw; bh = 4; }
            else if(cmp) { var y0:Number = 4 + i * 24; lx = 14; ly = y0; lw = 64; vx = w - 14 - 50; vy = y0; vw = 50; bx = 80; by = y0 + 9; bw = w - 80 - 64; bh = 4; }
            else if(hor) { var x1:Number = 16 + i * (cw + 16); lx = x1; ly = 10; lw = cw; vx = x1; vy = 10; vw = cw; bx = x1; by = 36; bw = cw; bh = 5; }
            else { var y1:Number = 10 + i * 36; lx = 16; ly = y1; lw = w - 32; vx = 16; vy = y1; vw = w - 32; bx = 16; by = y1 + 23; bw = w - 32; bh = 5; }
            if(keep) { TextField(this.hz41VTx[i]).text = val; }
            else
            {
               this.hzSText(p,lab,lx,ly,lw,13,HZ_LABEL,"left","lbl");
               var tv:TextField = this.hzSText(p,val,vx,vy,vw,13,HZ_VALUE,"right");
               if(mine) { this.hz41VTx.push(tv); }
            }
            this.hz41Bar(g,bx,by,bw,bh,f,col);
            i++;
         }
         return [w,h];
      }
      // the scanner's edge distance: ScanMargin, else [Style] Margin
      private function hz41Margin(live:Boolean) : Number
      {
         var m:Number = Number(this.hz41Get("ScanMargin",live));
         if(isNaN(m) || m < 0) { m = this.hzMargin; }
         return isNaN(m) ? 40 : m;
      }
      // the scanner's placement rule (hzsAt): a custom X / Y (L/R/C+n, T/B/C+n) replaces the default spot, kept inside the
      // edge distance; -1 keeps the default spot
      private function hz41Pos(pn:String, W:Number, H:Number, dx:Number, dy:Number, live:Boolean) : Point
      {
         var vr:Rectangle = this.hzVis();
         var M:Number = this.hz41Margin(live);
         var ccx:Number = vr.x + vr.width / 2;
         var ccy:Number = vr.y + vr.height / 2;
         var x:Number = dx;
         var y:Number = dy;
         var px:String = String(this.hz41Get("Scan" + pn + "X",live));
         var py:String = String(this.hz41Get("Scan" + pn + "Y",live));
         if(pn == "Social")   // r5: -1 = the traits card's spot (the strip is shown instead of it), axis by axis like the scanner
         {
            if(px == "-1") { px = String(this.hz41Get("ScanTraitsX",live)); }
            if(py == "-1") { py = String(this.hz41Get("ScanTraitsY",live)); }
         }
         var cust:Boolean = false;
         if(px != "-1" && px.length > 1)
         {
            var nx:Number = Number(px.substr(1));
            var ax:String = px.charAt(0);
            if(!isNaN(nx)) { x = ax == "L" ? vr.left + M + nx : (ax == "R" ? vr.right - M - nx - W : ccx - W / 2 + nx); cust = true; }
         }
         if(py != "-1" && py.length > 1)
         {
            var ny:Number = Number(py.substr(1));
            var ay:String = py.charAt(0);
            if(!isNaN(ny)) { y = ay == "T" ? vr.top + M + ny : (ay == "B" ? vr.bottom - M - ny - H : ccy - H / 2 + ny); cust = true; }
         }
         if(cust)
         {
            if(vr.right - M - W >= vr.left + M) { x = Math.max(vr.left + M,Math.min(vr.right - M - W,x)); }
            if(vr.bottom - M - H >= vr.top + M) { y = Math.max(vr.top + M,Math.min(vr.bottom - M - H,y)); }
         }
         return new Point(Math.round(x),Math.round(y));
      }
      // r2 (SF-4): the game's HUD opacity for the kept vitals (the strip is a Sprite: the game's own HUDOpacityData handler
      // only sets its MovieClips)
      private function hz41OnOp(e:FromClientDataEvent) : void
      {
         try { var o:Number = Number(e.data.fHUDOpacity); if(!isNaN(o)) { this.hz41Op = Math.max(0,Math.min(1,o)); } } catch(x:Error) { }
      }
      private function hz41VitTick() : void
      {
         if(!this.hz41OpSub) { this.hz41OpSub = true; try { BSUIDataManager.Subscribe("HUDOpacityData",this.hz41OnOp); } catch(e0:Error) { } }
         var on:Boolean = this.hz40Hide && this.hzGroupVisible && !this.hzUserHidden && !this.hzArrange && !this.hzSetIsOpen;   // r2: + the HUD's own visibility
         var st:Array = on ? this.hz41VitSt(true) : [];
         if(st.length == 0) { if(this.hz41V != null && this.hz41V.visible) { this.hz41V.visible = false; } return; }
         if(this.hz41V == null) { this.hz41V = new Sprite(); this.hz41V.name = "hz41Vitals"; this.hz41V.mouseEnabled = false; this.hz41V.mouseChildren = false; }
         if(this.hz41V.parent != this) { addChild(this.hz41V); }
         var c:Object = this.hz40Cfg();
         var fr:Object = {};
         var sv:Array = [];
         for each(var id:String in st) { fr[id] = Math.round(this.hz41VitF(id) * 100) / 100; sv.push(id + fr[id]); }
         var vr:Rectangle = this.hzVis();
         var lay:String = st.join(",") + "|" + int(c.ScanVitalsCompact) + int(c.ScanVitalsLayout) + "|" + c.ScanVitalsX + "," + c.ScanVitalsY + "|" + vr.toString() + "|" + this.HZ_ACCENT + "|" + this.hzHudScale + "|" + this.hz41Margin(true) + "|" + this.hzTextScale;
         var sig:String = lay + "|" + sv.join(",");
         if(sig != this.hz41VSig)
         {
            var full:Boolean = lay != this.hz41VLay;   // r2 (NIT-4): a value change only updates the texts and the bars
            this.hz41VSig = sig;
            this.hz41VLay = lay;
            var wh:Array = this.hz41VitDraw(this.hz41V,st,fr,int(c.ScanVitalsCompact) == 1,int(c.ScanVitalsLayout) == 1,!full);
            if(full)
            {
            var k:Number = HZ_SCALE * this.hzHudScale;
            this.hz41V.scaleX = this.hz41V.scaleY = k;
            var W:Number = Number(wh[0]) * k;
            var H:Number = Number(wh[1]) * k;
            var M:Number = this.hz41Margin(true);
            var pt:Point = this.hz41Pos("Vitals",W,H,vr.x + (vr.width - W) / 2,vr.bottom - M - H,true);
            this.hz41V.x = pt.x;
            this.hz41V.y = pt.y;
            }
         }
         this.hz41V.alpha = this.hz41Op;   // r2: the game's HUD opacity
         this.hz41V.visible = this.hz41Op > 0.01;
      }

      // ---------- the DLL's scan state (main_v0410r2.cpp BannerPoll: every 100 ms while the hand scanner is open + one closed push) ----------
      // While a push is younger than 500 ms it is the scan state: a HudCompassData / FireForget flicker during a tool
      // switch no longer ends the hide (the planet card ghost). Without a push (older DLL) nothing changes.
      public function hz41DllScan(on:Boolean) : void
      {
         try   // r2 (NIT-3): nothing may escape into the DLL's Invoke
         {
            this.hz41DllT = new Date().getTime();
            this.hz41DllOn = on === true;
            if(this.hz41DllOn != this.hz40Scan) { this.hz40SetScan(this.hz41DllOn); }
         }
         catch(e:Error) { }
      }
      private function hz41DllFresh() : Boolean
      {
         return this.hz41DllT > 0 && new Date().getTime() - this.hz41DllT < 500;
      }


      // ---------- ARRANGE SCANNER (F11 > SCANNER > LAYOUT) ----------
      // Mock scanner panels on the screen (the HUD cards are hidden meanwhile), moved with the ARRANGE CARDS engine (mouse
      // drag, arrows, TAB). A moved panel gets ScanPanelX / ScanPanelY in the scanner's format, anchored to the nearest edge
      // (thirds of the screen) inside the edge distance. C = compact form of the selected panel, L = vitals layout, R = reset
      // (RESET SCANNER LAYOUT). SAVE writes the pending settings like the F11 SAVE; CANCEL restores the keys and returns to F11.
      private function hz41SAKeys() : Array
      {
         var a:Array = [];
         for each(var d:Array in HZ40_SCAN_KEYS)
         {
            var k:String = String(d[0]);
            if(/^Scan\w+(X|Y|Compact|Scale)$/.test(k) || k == "ScanCompactAll" || k == "ScanVitalsLayout") { a.push(k); }   // r2: + Scale (R then CANCEL keeps the sizes)
         }
         return a;
      }
      private function hz41SAEnter() : void
      {
         if(this.hz30Mod["scanner"] !== 1 || this.hz40Scan || this.hzArrange || this.hzSetPend == null) { return; }
         this.hz41SAOrig = {};
         for each(var k:String in this.hz41SAKeys()) { this.hz41SAOrig[k] = this.hzSetPend[k]; }
         this.hz41SA = true;
         this.hz41SAP = {};
         if(this.hz41SA_mc == null) { this.hz41SA_mc = new Sprite(); this.hz41SA_mc.name = "hz41ArrangeScanner"; this.hz41SA_mc.mouseEnabled = false; this.hz41SA_mc.mouseChildren = false; }
         addChild(this.hz41SA_mc);
         this.hz41SA_mc.visible = true;
         for each(var pn:String in HZ41_SA_PANELS) { this.hz41SABuild(pn); }
         this.hz41SALayout();
         this.hzArrEnter();
         if(!this.hzArrange) { this.hz41SAEnd(false); }
      }
      private function hz41SAEnd(save:Boolean) : void
      {
         if(!save && this.hz41SAOrig != null) { for(var k:String in this.hz41SAOrig) { this.hzSetPend[k] = this.hz41SAOrig[k]; } }
         this.hz41SAOrig = null;
         this.hz41SA = false;
         this.hz41SAP = {};
         if(this.hz41SA_mc != null)
         {
            while(this.hz41SA_mc.numChildren > 0) { this.hz41SA_mc.removeChildAt(0); }
            this.hz41SA_mc.visible = false;
            if(this.hz41SA_mc.parent != null) { this.hz41SA_mc.parent.removeChild(this.hz41SA_mc); }
         }
      }
      private function hz41SAReset() : void
      {
         this.hz40Reset(true);
         for each(var pn:String in HZ41_SA_PANELS) { this.hz41SABuild(pn); }
         this.hz41SALayout();
         this.hzArrDraw();
      }
      private function hz41SAOn(pn:String) : Boolean
      {
         if(pn == "Vitals") { return this.hz41B(this.hz40Val("HideMainHudWhileScanning")) && this.hz41VitSt(false).length > 0; }   // r2: never shown in game without the hide
         if(pn == "Social") { return true; }   // r5: the person strip has no show key (it shows whenever a person is picked)
         return this.hz41B(this.hz40Val("ScanShow" + pn));
      }
      private function hz41SACmp(pn:String) : Boolean
      {
         if(pn == "Vitals") { return this.hz41B(this.hz40Val("ScanVitalsCompact")); }
         if(HZ41_SA_CMP.indexOf(pn) < 0) { return false; }
         var v:int = int(this.hz40Val("Scan" + pn + "Compact"));
         if(v == 0 || v == 1) { return v == 1; }
         var a:int = int(this.hz40Val("ScanCompactAll"));
         if(a == 0 || a == 1) { return a == 1; }
         return this.hzCompact;
      }
      private function hz41SAK(pn:String) : Number
      {
         if(pn == "Vitals") { return HZ_SCALE * this.hzHudScale; }
         var v:Number = Number(this.hz40Val("Scan" + pn + "Scale"));
         if(pn == "Social" && (isNaN(v) || v <= 0)) { v = Number(this.hz40Val("ScanTraitsScale")); }   // r5: -1 = the traits card's size
         if(isNaN(v) || v <= 0) { v = this.hzHudScale; }
         return HZ_SCALE * Math.max(0.6,v);
      }
      // the mock panel (1080p units, scaled like the scanner draws it)
      private function hz41SABuild(pn:String) : void
      {
         var old:Sprite = this.hz41SAP[pn] as Sprite;
         if(old != null && old.parent != null) { old.parent.removeChild(old); }
         delete this.hz41SAP[pn];
         if(!this.hz41SAOn(pn)) { return; }
         var p:Sprite = new Sprite();
         p.name = "hz41SA_" + pn;
         var cmp:Boolean = this.hz41SACmp(pn);
         var wh:Array;
         if(pn == "Vitals")
         {
            var st:Array = this.hz41VitSt(false);
            wh = this.hz41VitDraw(p,st,{"hp":0.82,"o2":0.46,"bo":1},cmp,int(this.hz40Val("ScanVitalsLayout")) == 1);
         }
         else if(pn == "Social") { wh = this.hz41SASocialMock(p); }   // r5
         else
         {
            var bioH:Number = Math.max(44,Math.round(44 + (Math.max(1,this.hzTextScale) - 1) * 40));
            var sz:Object = {"Planet":[400,cmp ? 44 : 338],"Bioscan":[400,cmp ? bioH : 220],"Signals":[400,cmp ? 44 : 296],"Traits":[400,cmp ? 44 : 250],"Compass":[640,cmp ? 46 : 58],"Mode":[240,32],"Hints":[560,40]};
            wh = sz[pn] as Array;
            var w:Number = Number(wh[0]);
            var h:Number = Number(wh[1]);
            var g:* = p.graphics;
            var small:Boolean = h < 60;
            this.hzSetBox(g,0,0,w,h,HZ_ACCENT,0.55,0x0B1620,0.86,small ? 24 : 36);
            this.hzSText(p,String(HZ41_SA_NAMES[HZ41_SA_PANELS.indexOf(pn)]) + (cmp ? "  ·  COMPACT" : ""),16,small ? h / 2 - 10 : 12,w - 32,13,HZ_ACCENT,"left");
            if(!small)
            {
               var yy:Number = 44;
               var i:int = 0;
               while(yy + 10 < h - 12)
               {
                  g.beginFill(0xFFFFFF,0.08); g.drawRoundRect(16,yy,(w - 32) * (0.5 + ((i * 37) % 10) / 22),8,8,8); g.endFill();
                  yy += 26;
                  i++;
               }
               this.hzSText(p,"sample layout, not a live scan",16,h - 26,w - 32,13,HZ_LABEL,"left","lbl");
            }
         }
         var k:Number = this.hz41SAK(pn);
         p.scaleX = p.scaleY = k;
         p.mouseEnabled = false;
         p.mouseChildren = false;
         this.hz41SAP[pn] = p;
         if(this.hz41SA_mc != null) { this.hz41SA_mc.addChild(p); }
      }
      // default spots = the scanner's hzsPlace (left stack bottom up: bioscan, planet; right: traits, signals; compass, mode,
      // hints at the top center; vitals bottom center), then each panel's own keys
      private function hz41SALayout() : void
      {
         var vr:Rectangle = this.hzVis();
         var M:Number = this.hz41Margin(false);
         var cx:Number = vr.x + vr.width / 2;
         var y:Number = vr.bottom - M;
         var p:Sprite;
         var pt:Point;
         for each(var l:String in ["Bioscan","Planet"])
         {
            p = this.hz41SAP[l] as Sprite;
            if(p == null) { continue; }
            y -= p.height;
            pt = this.hz41Pos(l,p.width,p.height,vr.left + M,y,false); this.hzPlace(p,pt.x,pt.y);
            y -= 14 * p.scaleX;
         }
         y = vr.bottom - M;
         for each(var r:String in ["Traits","Signals"])
         {
            p = this.hz41SAP[r] as Sprite;
            if(p == null) { continue; }
            y -= p.height;
            pt = this.hz41Pos(r,p.width,p.height,vr.right - M - p.width,y,false); this.hzPlace(p,pt.x,pt.y);
            y -= 14 * p.scaleX;
         }
         // r5: the person strip, default = the traits card's slot at the bottom right (the scanner shows it instead of that card)
         p = this.hz41SAP.Social as Sprite;
         if(p != null) { pt = this.hz41Pos("Social",p.width,p.height,vr.right - M - p.width,vr.bottom - M - p.height,false); this.hzPlace(p,pt.x,pt.y); }
         y = vr.top + 36;
         p = this.hz41SAP.Compass as Sprite;
         if(p != null)
         {
            pt = this.hz41Pos("Compass",p.width,p.height,cx - p.width / 2,y,false); this.hzPlace(p,pt.x,pt.y);
            y += p.height + (6 + 28 + 10) * p.scaleX;
         }
         p = this.hz41SAP.Mode as Sprite;
         if(p != null)
         {
            pt = this.hz41Pos("Mode",p.width,p.height,cx - p.width / 2,y,false); this.hzPlace(p,pt.x,pt.y);
            y += p.height + 12 * p.scaleX;
         }
         p = this.hz41SAP.Hints as Sprite;
         if(p != null) { pt = this.hz41Pos("Hints",p.width,p.height,cx - p.width / 2,y,false); this.hzPlace(p,pt.x,pt.y); }
         p = this.hz41SAP.Vitals as Sprite;
         if(p != null) { pt = this.hz41Pos("Vitals",p.width,p.height,cx - p.width / 2,vr.bottom - M - p.height,false); this.hzPlace(p,pt.x,pt.y); }
      }
      private function hz41SAList() : Array
      {
         var r:Array = [];
         var i:int = 0;
         while(i < HZ41_SA_PANELS.length)
         {
            var p:Sprite = this.hz41SAP[HZ41_SA_PANELS[i]] as Sprite;
            if(p != null) { r.push({"k":"S_" + HZ41_SA_PANELS[i],"n":HZ41_SA_NAMES[i],"c":p}); }
            i++;
         }
         return r;
      }
      // a moved panel -> ScanPanelX / ScanPanelY (nearest third: L / C / R and T / C / B), inside the edge distance
      private function hz41SAStore(k:String, c:Sprite) : void
      {
         var pn:String = k.substr(2);
         var vr:Rectangle = this.hzVis();
         var M:Number = this.hz41Margin(false);
         var W:Number = c.width;
         var H:Number = c.height;
         var x:Number = c.x;
         var y:Number = c.y;
         if(vr.right - M - W >= vr.left + M) { x = Math.max(vr.left + M,Math.min(vr.right - M - W,x)); }
         if(vr.bottom - M - H >= vr.top + M) { y = Math.max(vr.top + M,Math.min(vr.bottom - M - H,y)); }
         if(x != c.x || y != c.y) { this.hzPlace(c,x,y); }
         var mx:Number = x + W / 2;
         var my:Number = y + H / 2;
         var sx:String = mx < vr.x + vr.width / 3 ? "L" + Math.round(x - vr.left - M) : (mx > vr.x + vr.width * 2 / 3 ? "R" + Math.round(vr.right - M - x - W) : "C" + Math.round(mx - (vr.x + vr.width / 2)));
         var sy:String = my < vr.y + vr.height / 3 ? "T" + Math.round(y - vr.top - M) : (my > vr.y + vr.height * 2 / 3 ? "B" + Math.round(vr.bottom - M - y - H) : "C" + Math.round(my - (vr.y + vr.height / 2)));
         this.hzSetPend["Scan" + pn + "X"] = sx;
         this.hzSetPend["Scan" + pn + "Y"] = sy;
         if(pn == "Traits") { this.hz41SALayout(); }   // r5: a person strip still on -1 follows the traits card
      }
      // r5: the mock person strip (D1): a few social-skill rows and the bounty line, at the strip's full width
      private function hz41SASocialMock(p:Sprite) : Array
      {
         var w:Number = 400;
         var h:Number = 200;
         var g:* = p.graphics;
         this.hzSetBox(g,0,0,w,h,HZ_ACCENT,0.55,0x0B1620,0.86,36);
         this.hzSText(p,"PERSON  ·  SOCIAL SKILLS + BOUNTY",16,12,w - 32,13,HZ_ACCENT,"left");
         var yy:Number = 46;
         var i:int = 0;
         while(i < 3)
         {
            g.beginFill(0xFFFFFF,0.08); g.drawRoundRect(16,yy,(w - 32) * (0.42 + i * 0.09),8,8,8); g.endFill();
            g.beginFill(0xFFFFFF,0.08); g.drawRoundRect(w - 64,yy,48,8,8,8); g.endFill();
            yy += 26;
            i++;
         }
         g.beginFill(HZ_AMB,0.3); g.drawRoundRect(16,yy + 4,(w - 32) * 0.55,10,10,10); g.endFill();
         this.hzSText(p,"shown instead of TRAITS while a person is picked",16,h - 26,w - 32,13,HZ_LABEL,"left","lbl");
         return [w,h];
      }
      // C (compact) / L (layout, vitals only) / R (reset); true = the key was ARRANGE SCANNER's
      private function hz41SAKey(code:String) : Boolean
      {
         var c:String = code.toLowerCase();
         if(c == "ch:r") { this.hz41SAReset(); return true; }
         if(c != "ch:c" && c != "ch:l") { return false; }
         var pn:String = this.hzArrSel != null ? String(this.hzArrSel).substr(2) : "";
         if(this.hz41SAP[pn] == null) { return true; }
         if(c == "ch:c")
         {
            if(pn == "Vitals") { this.hzSetPend.ScanVitalsCompact = !this.hz41SACmp(pn); }
            else if(HZ41_SA_CMP.indexOf(pn) >= 0) { this.hzSetPend["Scan" + pn + "Compact"] = this.hz41SACmp(pn) ? 0 : 1; }
            else { return true; }
         }
         else
         {
            if(pn != "Vitals") { return true; }
            this.hzSetPend.ScanVitalsLayout = int(this.hz40Val("ScanVitalsLayout")) == 1 ? 0 : 1;
         }
         this.hz41SABuild(pn);
         this.hz41SALayout();
         this.hzArrDraw();
         return true;
      }
      // chips on the selected panel: C COMPACT (panels with a compact form and the vitals), L LAYOUT (vitals)
      private function hz41SAChips(g:*) : void
      {
         var pn:String = this.hzArrSel != null ? String(this.hzArrSel).substr(2) : "";
         var p:Sprite = this.hz41SAP[pn] as Sprite;
         if(p == null) { return; }
         var chips:Array = [];
         if(pn == "Vitals" || HZ41_SA_CMP.indexOf(pn) >= 0) { chips.push(["btn_hz41cmp","C  COMPACT: " + (this.hz41SACmp(pn) ? "ON" : "OFF"),180]); }
         if(pn == "Vitals") { chips.push(["btn_hz41lay","L  LAYOUT: " + (int(this.hz40Val("ScanVitalsLayout")) == 1 ? "HORIZONTAL" : "VERTICAL"),230]); }
         if(chips.length == 0) { return; }
         var vr:Rectangle = this.hzVis();
         var y:Number = p.y - 58;
         if(y < vr.top + 4) { y = p.y + p.height + 10; }
         var x:Number = p.x + p.width + 4;
         for each(var ch:Array in chips) { x -= Number(ch[2]) + 8; }
         x = Math.max(vr.left + 4,Math.min(vr.right - 4,x));
         for each(var c2:Array in chips)
         {
            var cw:Number = Number(c2[2]);
            var hov:Boolean = this.hzArrHover == c2[0];
            this.hzSetBox(g,x,y,cw,26,HZ_ACCENT,hov ? 1 : 0.8,0x0B1620,0.92,13);
            this.hzSText(this.hzArr_mc,String(c2[1]),x,y + 4,cw,13,HZ_ACCENT,"center");
            this.hzArrHits.push({"id":c2[0],"x":x,"y":y,"w":cw,"h":26,"c":null});
            x += cw + 8;
         }
      }
      // =================== end v0.41.0 ===================
      // =================== v0.42.0: main HUD vitals layout ([Cards] VitalsLayout) ===================
      // 0 = vertical (health body above the O2 body, card 330 x 124, unchanged), 1 = horizontal (the O2 body beside health,
      // 8 px gap, card 668 x 58). Every child of the vitals form at y >= 60 (the O2 body, icon, label, value, bar, CO2 tail /
      // text) lives in one row sprite (hz42VRow), moved by (338, -66) in the horizontal layout; nothing else is redrawn.
      // The compact strips ignore it. ARRANGE positions use the real card size (edge anchors keep their edge).
      private var hz42VL:int = 0;
      private var hz42VLOrig:int = -1;
      private var hz42VRow:Sprite = null;
      private function hz42VW() : Number { return this.hz42VL == 1 ? HZ_VN_W * 2 + 8 : HZ_VN_W; }
      private function hz42VH() : Number { return this.hz42VL == 1 ? 58 : 124; }
      private function hz42VLName() : String { return this.hz42VL == 1 ? "HORIZONTAL" : "VERTICAL"; }
      private function hz42VitApply() : void
      {
         if(!this.hzVitNew || !this.HorizonVitals_mc) { return; }
         var p:Sprite = this.hzVitNew;
         if(this.hz42VRow == null)
         {
            this.hz42VRow = new Sprite();
            this.hz42VRow.name = "hz42VRow";
            this.hz42VRow.mouseEnabled = false;
            p.addChild(this.hz42VRow);
         }
         var mv:Array = [];
         var i:int = 0;
         while(i < p.numChildren)
         {
            var ch:DisplayObject = p.getChildAt(i);
            if(ch != this.hz42VRow && ch.y >= 60) { mv.push(ch); }
            i++;
         }
         for each(var d:DisplayObject in mv) { this.hz42VRow.addChild(d); }
         var hz:Boolean = this.hz42VL == 1;
         this.hz42VRow.x = hz ? HZ_VN_W + 8 : 0;
         this.hz42VRow.y = hz ? -66 : 0;
         this.hzSetSz(this.HorizonVitals_mc,this.hz42VW(),this.hz42VH());
      }
      private function hz42SetVL(v:int) : void
      {
         this.hz42VL = v == 1 ? 1 : 0;
         if(this.hzSetPend != null) { this.hzSetPend.VitalsLayout = this.hz42VL; }
         this.hz42VitApply();
         this.hzLaidOut = this.hzLayout();
      }
      // ARRANGE CARDS: L (or the chip) flips the vitals card; SAVE keeps it (pending VitalsLayout), CANCEL restores it
      private function hz42ArrLay() : void
      {
         var ok:Boolean = false;
         for each(var e:Object in this.hzArrList()) { if(e.k == "Vitals") { ok = true; } }
         if(!ok) { return; }
         this.hzArrSel = "Vitals";
         this.hz42SetVL(this.hz42VL == 1 ? 0 : 1);
         this.hzArrDraw();
      }
      private function hz42ArrChip(g:*) : void
      {
         if(this.hzArrSel != "Vitals" || !this.HorizonVitals_mc) { return; }
         var ok:Boolean = false;
         for each(var e:Object in this.hzArrList()) { if(e.k == "Vitals") { ok = true; } }
         if(!ok) { return; }
         var c:Sprite = this.HorizonVitals_mc;
         var vr:Rectangle = this.hzVis();
         var cw:Number = 230;
         var bw:Number = Math.max(40,this.hzCW(c));
         var by:Number = this.hzFadeBase(c);
         var x:Number = c.x + bw + 4 - cw;
         var y:Number = by - 58;
         if(y < vr.top + 4) { y = by + Math.max(24,this.hzCH(c)) + 10; }
         x = Math.max(vr.left + 4,Math.min(vr.right - 4 - cw,x));
         var hov:Boolean = this.hzArrHover == "btn_hz42lay";
         this.hzSetBox(g,x,y,cw,26,HZ_ACCENT,hov ? 1 : 0.8,0x0B1620,0.92,13);
         this.hzSText(this.hzArr_mc,"L  LAYOUT: " + this.hz42VLName(),x,y + 4,cw,13,HZ_ACCENT,"center");
         this.hzArrHits.push({"id":"btn_hz42lay","x":x,"y":y,"w":cw,"h":26,"c":null});
      }
      // =================== end v0.42.0 ===================
      // =================== v0.42.0 r2: Scope hold-breath chip settings ([Scope]) ===================
      // ScopeHoldBreathChip (1 = the Horizon chip in the scope menu), ScopeChipX / ScopeChipY (offset from the game's
      // prompt in 1080p units, X + = right, Y + = up; 0 / 0 = the game's spot = the r1 chip) and ScopeChipScale (0.60 - 1.60,
      // 1 = the r1 size). The scope movie (scopemenu.swf / _lrg) reads them when a scope opens. On the HUD they are edited in
      // F11 > CARDS (on / off, size, RESET) and in ARRANGE CARDS with a proxy chip, only while scope.marker is installed.
      // The proxy home is the game's prompt spot: screen center + 302 (1080p units; the prompt sits 289.6 under the center
      // of the scope movie plus half its height). The proxy draws the chip's look (target icon, label, meter) at its size.
      private static const HZ42_SC_HOMEY:Number = 302;
      private static const HZ42_SC_H:Number = 32;
      // Key field of the scope movie's hzpKeyW (0.42.0.6). The preview cannot call that function; both HUD sizes share this block.
      // HZP_KPAD is the gap after the 30 px icon. HZP_RPAD is the panel pad after the O2 meter. HZP_KHEAD is 1.08.
      private static const HZ42_SC_KPAD:Number = 10;
      private static const HZ42_SC_RPAD:Number = 18;
      private static const HZ42_SC_KHEAD:Number = 1.08;
      private static const HZ42_SC_KMINW:Number = 14;
      private static const HZ42_SC_KEX:Number = 16;     // 0.42.0.9: extra key-text width, same as HZP_KEX. The label slot does not use it.
      private static const HZ42_SC_LABEX:Number = 32;   // 0.42.0.8: extra label slot, same as the scope chip (HZP_LABEX)
      private static const HZ42_SC_KEY:String = "ScopeChip";   // ARRANGE list key of the proxy (saved as [Scope] ScopeChipX / ScopeChipY)
      private var hz42ScOn:Boolean = true;
      private var hz42ScX:Number = 0;
      private var hz42ScY:Number = 0;
      private var hz42ScS:Number = 1;
      private var hz42ScOrig:Object = null;
      private var hz42ScPx:Sprite = null;
      private var hz42ScW:Number = 0;
      private var hz42ScBoxH:Number = 32;
      private var hz42ScSig:String = "";
      private function hz42ScCX(v:*) : Number { var n:Number = Number(v); if(isNaN(n)) { return 0; } return Math.round(Math.max(-900,Math.min(900,n))); }
      private function hz42ScCY(v:*) : Number { var n:Number = Number(v); if(isNaN(n)) { return 0; } return Math.round(Math.max(-500,Math.min(500,n))); }
      private function hz42ScCS(v:*) : Number { var n:Number = Number(v); if(isNaN(n)) { return 1; } return Math.round(Math.max(0.6,Math.min(1.6,n)) * 100) / 100; }
      private function hz42ScAvail() : Boolean { return this.hz30Mod["scope"] === 1 && this.hz42ScOn; }
      // v0.42.0 r3: proxy text size so the text stays 13 px or more after the proxy scale (floor after scaling)
      private function hz42ScFs(n:Number) : Number
      {
         var s:Number = this.hz42ScS;
         if(isNaN(s) || s <= 0) { s = 1; }
         return Math.max(n,Math.ceil(13 / s));
      }
      // v0.42.0 r3 / v0.42.0.4: preset names drop '=' '+' '[' ']' ';' '#' '"' '\' '|' , controls, and DEL.
      // The same set is hzpreset::kPresetNameDrop / CleanPresetName in the DLL. Do not change one without the other.
      private function hz42NmOk(ch:String) : Boolean
      {
         if(ch == null || ch.length != 1) { return false; }
         var c:int = ch.charCodeAt(0);
         if(c < 32 || c == 127) { return false; }
         return "=+[];#\"\\|".indexOf(ch) < 0;
      }
      private function hz42NmSafe(s:String) : String
      {
         if(s == null) { return ""; }
         var o:String = "";
         var i:int = 0;
         while(i < s.length) { if(this.hz42NmOk(s.charAt(i))) { o += s.charAt(i); } i++; }
         return o;
      }
      // v0.42.0.4: four numeric parts, no leading v. Same rule as HzFileVersionOk in the DLL.
      private function hz42FileVerOk(s:String) : Boolean
      {
         if(s == null) { return false; }
         if(s.length < 7 || s.length > 32) { return false; }
         var dots:int = 0;
         var digit:Boolean = false;
         var i:int = 0;
         while(i < s.length)
         {
            var c:int = s.charCodeAt(i);
            if(c >= 48 && c <= 57) { digit = true; }
            else if(c == 46 && digit) { dots++; digit = false; }
            else { return false; }
            i++;
         }
         return digit && dots == 3;
      }
      // v0.42.0.4: HorizonUI.dll passes its file version (from the DLL version resource). Empty and odd strings are ignored.
      public function hzSetDllFileVersion(s:String) : void
      {
         try
         {
            if(s == null) { return; }
            var t:String = String(s);
            while(t.length > 0 && (t.charAt(0) == " " || t.charAt(0) == "\t")) { t = t.substr(1); }
            if(t.length > 0 && (t.charAt(0) == "v" || t.charAt(0) == "V")) { t = t.substr(1); }
            if(!this.hz42FileVerOk(t) || t == this.hzDllFileVer) { return; }
            this.hzDllFileVer = t;
            if(this.hzSetIsOpen) { this.hzSetDraw(); }
         }
         catch(err:Error) { }
      }
      public function hzBuildId() : String
      {
         return HZ_BUILD;
      }
      // ini keys (lower case, any section like the rest of the HUD parser); "0" / "false" = off, like the scope movie
      private function hz42ScIni(k:String, v:String, nv:Number) : Boolean
      {
         if(k == "scopeholdbreathchip") { var lv:String = v == null ? "" : v.toLowerCase(); this.hz42ScOn = !(lv == "0" || lv == "false"); this.hz42ScSig = ""; return true; }
         if(k == "scopechipx") { this.hz42ScX = this.hz42ScCX(nv); return true; }
         if(k == "scopechipy") { this.hz42ScY = this.hz42ScCY(nv); return true; }
         if(k == "scopechipscale") { this.hz42ScS = this.hz42ScCS(nv); this.hz42ScSig = ""; return true; }
         return false;
      }
      private function hz42ScSetCur(o:Object) : void
      {
         o.ScopeHoldBreathChip = this.hz42ScOn;
         o.ScopeChipX = this.hz42ScX;
         o.ScopeChipY = this.hz42ScY;
         o.ScopeChipScale = this.hz42ScS;
      }
      private function hz42ScSetLive(p:Object) : void
      {
         if(p == null) { return; }
         if(p.ScopeHoldBreathChip !== undefined) { this.hz42ScOn = p.ScopeHoldBreathChip === true || Number(p.ScopeHoldBreathChip) >= 0.5; }
         if(p.ScopeChipX !== undefined) { this.hz42ScX = this.hz42ScCX(p.ScopeChipX); }
         if(p.ScopeChipY !== undefined) { this.hz42ScY = this.hz42ScCY(p.ScopeChipY); }
         if(p.ScopeChipScale !== undefined) { this.hz42ScS = this.hz42ScCS(p.ScopeChipScale); }
         this.hz42ScSync();
      }
      // one value set (ARRANGE drag / size / reset / cancel): the live value and the pending F11 value
      private function hz42ScPut(x:*, y:*, s:*) : void
      {
         this.hz42ScX = this.hz42ScCX(x);
         this.hz42ScY = this.hz42ScCY(y);
         this.hz42ScS = this.hz42ScCS(s);
         if(this.hzSetPend != null) { this.hzSetPend.ScopeChipX = this.hz42ScX; this.hzSetPend.ScopeChipY = this.hz42ScY; this.hzSetPend.ScopeChipScale = this.hz42ScS; }
         this.hz42ScSync();
      }
      private function hz42ScNum(v:Number) : String { return String(Math.round(v * 100) / 100); }
      // [Scope] block of the writer (same lines as HorizonUI.default.ini), written with or without the module (the values
      // are the ones read from the file, so a save never loses them)
      private function hz42ScIniLines(a:Array, p:Object) : void
      {
         var on:Boolean = p.ScopeHoldBreathChip !== undefined ? (p.ScopeHoldBreathChip === true || Number(p.ScopeHoldBreathChip) >= 0.5) : this.hz42ScOn;
         a.push("[Scope]");
         a.push("; Horizon Scope module (optional: scopemenu.swf / scopemenu_lrg.swf). Read when a scope opens; set in F11 > CARDS and ARRANGE CARDS.");
         a.push("; 1 = the hold-breath prompt is a Horizon chip (target icon, label, O2 meter; the game's prompt is hidden, never removed),");
         a.push("; 0 = the game's own prompt");
         a.push("ScopeHoldBreathChip=" + (on ? "1" : "0"));
         a.push("; chip spot: offset from the game's prompt in 1080p units (X + = right, Y + = up; -900 - 900 / -500 - 500); 0 / 0 = the game's spot");
         a.push("ScopeChipX=" + this.hz42ScNum(this.hz42ScCX(p.ScopeChipX !== undefined ? p.ScopeChipX : this.hz42ScX)));
         a.push("ScopeChipY=" + this.hz42ScNum(this.hz42ScCY(p.ScopeChipY !== undefined ? p.ScopeChipY : this.hz42ScY)));
         a.push("; chip size 0.60 - 1.60 (1 = the game's prompt size)");
         a.push("ScopeChipScale=" + this.hz42ScNum(this.hz42ScCS(p.ScopeChipScale !== undefined ? p.ScopeChipScale : this.hz42ScS)));
         a.push("");
      }
      // F11 > CARDS: SCOPE rows, only while scope.marker is installed
      private function hz42ScRows(rows:Array) : void
      {
         if(this.hz30Mod["scope"] !== 1) { return; }
         rows.push({"k":"ScopeHoldBreathChip","l":"SCOPE: HOLD-BREATH CHIP","t":"b","h":"SCOPE","note":"Off = the game's own prompt. Move it in ARRANGE CARDS"});
         rows.push({"k":"ScopeChipScale","l":"CHIP SIZE","t":"n","mn":0.6,"mx":1.6,"st":0.05,"sub":true,"note":"1.00 = the game's prompt size. ARRANGE CARDS: - / +"});
         rows.push({"k":"_hz42scrst","l":"CHIP SPOT + SIZE","t":"x","btn":"RESET","sub":true,"note":"Back to the game's spot (X 0, Y 0) and size 1.00"});
      }
      // proxy home = the game's prompt center on the HUD (visible-area center + HZ42_SC_HOMEY)
      private function hz42ScHome() : Point
      {
         var vr:Rectangle = this.hzVis();
         return new Point(vr.x + vr.width / 2,vr.y + vr.height / 2 + HZ42_SC_HOMEY);
      }
      // original target icon (ring, 4 ticks, center dot), drawn in code; same art as the scope chip
      private function hz42Cross(g:*, cx:Number, cy:Number, col:uint, a:Number) : void
      {
         g.lineStyle(2,col,a,true,"none");
         g.drawCircle(cx,cy,6);
         g.moveTo(cx,cy - 8.5); g.lineTo(cx,cy - 3.5);
         g.moveTo(cx,cy + 3.5); g.lineTo(cx,cy + 8.5);
         g.moveTo(cx - 8.5,cy); g.lineTo(cx - 3.5,cy);
         g.moveTo(cx + 3.5,cy); g.lineTo(cx + 8.5,cy);
         g.lineStyle();
         g.beginFill(col,a); g.drawCircle(cx,cy,1.8); g.endFill();
      }
      // Purpose: width of the F11 hold-breath key text, matching the scope movie's field width.
      // Inputs: tw textWidth, ls letterSpacing, len character count. Output: ceil(tw * 1.08 + ls * len) + 8.
      // The keycap adds the 30 px icon and HZ42_SC_KPAD. A bad measurement is treated as 0, then held to 14 px.
      // Scope label slot: semibold tracking is 0.1 of the font size, then the same field width as the key.
      private function hz42ScLblW(t:TextField) : Number
      {
         if(t == null) { return 0; }
         var f:TextFormat = t.getTextFormat();
         var fs:Number = Number(f.size);
         if(isNaN(fs) || fs <= 0) { fs = 14; }
         f.font = this.hzFontName("sb");
         f.letterSpacing = Math.round(fs * 0.1 * 10) / 10;
         t.defaultTextFormat = f;
         t.setTextFormat(f);
         var ls:Number = Number(f.letterSpacing);
         if(isNaN(ls) || ls < 0) { ls = 0; }
         var len:int = t.text != null ? int(t.text.length) : 0;
         return this.hz42ScKeyW(Number(t.textWidth),ls,len);
      }
      private function hz42ScKeyW(tw:Number, ls:Number, len:int, extra:Number = 0) : Number
      {
         if(isNaN(tw) || tw < 0) { tw = 0; }
         if(isNaN(ls) || ls < 0) { ls = 0; }
         if(len < 0) { len = 0; }
         if(isNaN(extra) || extra < 0) { extra = 0; }
         var w:Number = Math.ceil(tw * HZ42_SC_KHEAD + ls * len) + 8 + extra;
         if(w < HZ42_SC_KMINW) { w = HZ42_SC_KMINW; }
         return w;
      }
      private function hz42ScDraw() : void
      {
         var p:Sprite = this.hz42ScPx;
         while(p.numChildren > 0) { p.removeChildAt(0); }
         var g:* = p.graphics;
         g.clear();
         var h:Number = HZ42_SC_H;
         // hzSText multiplies by TextScale (clamped 0.9-1.15). Pass a size that survives that, or the
         // on-screen size is the chip scale times a font that was already shrunk. At chip 0.65 and
         // TextScale 0.9, HOLD BREATH was 11.7 px. Both lines use the same correction. The floor is 13 px
         // after the proxy scale (hz42ScFs) and after TextScale. The label uses the chip's semibold face
         // (hzFontName "sb") and the scope's 0.1 tracking, then the same field width. The key uses bold.
         var ts:Number = this.hzTextScale;
         if(isNaN(ts) || ts <= 0) { ts = 1; }
         ts = Math.max(0.9,Math.min(1.15,ts));
         var lb:int = int(this.hz42ScFs(14));
         var lt:TextField = this.hzSText(p,"HOLD BREATH",0,0,220,int(Math.ceil(lb / ts)),0xF2F7F9,"left");
         // "L-SHIFT" is the wide PC label. Same bold face as the scope key (hzpFace "bd"), same 0.04 tracking,
         // then the same field width. The label uses the chip's semibold weight.
         var want:int = int(this.hz42ScFs(13));
         var kt:TextField = this.hzSText(p,"L-SHIFT",0,0,160,int(Math.ceil(want / ts)),HZ_ACCENT,"left");
         var kf:TextFormat = kt.getTextFormat();
         var kfs:Number = Number(kf.size);
         if(isNaN(kfs) || kfs <= 0) { kfs = 13; }
         kf.font = this.hzFontName("bd");
         kf.letterSpacing = Math.round(kfs * 0.04 * 10) / 10;
         kt.defaultTextFormat = kf;
         kt.setTextFormat(kf);
         var ls:Number = Number(kf.letterSpacing);
         if(isNaN(ls) || ls < 0) { ls = 0; }
         var len:int = kt.text != null ? int(kt.text.length) : 0;
         kt.autoSize = flash.text.TextFieldAutoSize.NONE;
         kt.width = this.hz42ScKeyW(Number(kt.textWidth),ls,len,HZ42_SC_KEX);
         var kAlign:TextFormat = kt.getTextFormat();
         kAlign.align = "center";
         kt.defaultTextFormat = kAlign;
         kt.setTextFormat(kAlign);
         var kw:Number = 30 + kt.width + HZ42_SC_KPAD;
         var x0:Number = 7;
         var lx:Number = x0 + kw + 10;
         // Same width headroom and 0.1 tracking as the scope label. The slot is the widest label (HOLDING BREATH).
         var hold:TextField = this.hzSText(p,"HOLDING BREATH",0,0,400,int(Math.ceil(lb / ts)),0xF2F7F9,"left");
         var outb:TextField = this.hzSText(p,"OUT OF BREATH",0,0,400,int(Math.ceil(lb / ts)),0xF2F7F9,"left");
         var ltw:Number = this.hz42ScLblW(lt);
         var hw:Number = this.hz42ScLblW(hold);
         var ow:Number = this.hz42ScLblW(outb);
         if(hw > ltw) { ltw = hw; }
         if(ow > ltw) { ltw = ow; }
         ltw += HZ42_SC_LABEX;
         if(hold.parent == p) { p.removeChild(hold); }
         if(outb.parent == p) { p.removeChild(outb); }
         var lth:Number = lt.height;
         lt.autoSize = flash.text.TextFieldAutoSize.NONE;
         lt.width = ltw;
         if(lt.height < lth) { lt.height = lth; }
         if(lt.height + 8 > h) { h = Math.round(lt.height + 8); }
         var mx:Number = Math.round(lx + ltw + 16);
         var mw:Number = 120;
         var w:Number = Math.round(mx + mw + HZ42_SC_RPAD);
         g.lineStyle(1,0xFFFFFF,0.18,true,"none");
         g.beginFill(0x0B1218,0.84);
         g.drawRoundRect(0.5,0.5,w - 1,h - 1,Math.max(0,h - 1),Math.max(0,h - 1));
         g.endFill();
         g.lineStyle();
         g.lineStyle(1,HZ_ACCENT,0.95,true,"none");
         g.beginFill(HZ_ACCENT,0.1);
         g.drawRoundRect(x0 + 0.5,6.5,kw - 1,h - 13,8,8);
         g.endFill();
         g.lineStyle();
         this.hz42Cross(g,x0 + 15,h / 2,HZ_ACCENT,1);
         kt.x = Math.round(x0 + 28);
         kt.y = Math.round(h / 2 - (kt.textHeight + 4) / 2);
         lt.x = lx - 2;
         lt.y = Math.round(h / 2 - (lt.textHeight + 4) / 2);
         var my:Number = Math.round(h / 2 - 3);
         var bar:flash.display.Shape = new flash.display.Shape();
         p.addChild(bar);
         var bg:* = bar.graphics;
         bg.beginFill(0xFFFFFF,0.14); bg.drawRoundRect(mx,my,mw,6,6,6); bg.endFill();
         bg.beginFill(0x4DB6FF,1); bg.drawRoundRect(mx,my,Math.round(mw * 0.7),6,6,6); bg.endFill();
         this.hz42ScW = w;
         this.hz42ScBoxH = h;
      }
      // proxy: shown only in ARRANGE CARDS with the module installed and the chip on; placed from the stored offsets
      private function hz42ScSync() : void
      {
         var on:Boolean = this.hzArrange && !this.hz41SA && this.hz42ScAvail();
         if(!on) { if(this.hz42ScPx != null) { this.hz42ScPx.visible = false; } return; }
         if(this.hz42ScPx == null)
         {
            this.hz42ScPx = new Sprite();
            this.hz42ScPx.name = "hz42ScopeProxy";
            this.hz42ScPx.mouseEnabled = false;
            this.hz42ScPx.mouseChildren = false;
            this.hz42ScSig = "";
         }
         if(this.hz42ScPx.parent != this) { addChild(this.hz42ScPx); if(this.hzArr_mc != null && this.hzArr_mc.parent == this) { addChild(this.hzArr_mc); } }
         var sig:String = HZ_ACCENT + "|" + this.hzTextScale + "|" + this.hzFontFace + "|" + this.hz42ScS;   // r3: + size (text floor)
         if(sig != this.hz42ScSig || this.hz42ScW <= 0) { this.hz42ScSig = sig; this.hz42ScDraw(); }
         var sx:Number = this.hz42ScS;
         if(isNaN(sx) || sx == 0) { sx = 1; }
         var boxH:Number = this.hz42ScBoxH > 0 ? this.hz42ScBoxH : HZ42_SC_H;
         var sw:Number = Math.max(1,Math.round(this.hz42ScW * sx));
         var sh:Number = Math.max(1,Math.round(boxH * sx));
         if(this.hz42ScW > 0) { this.hz42ScPx.scaleX = sw / this.hz42ScW; } else { this.hz42ScPx.scaleX = sx; }
         if(boxH > 0) { this.hz42ScPx.scaleY = sh / boxH; } else { this.hz42ScPx.scaleY = sx; }
         var hp:Point = this.hz42ScHome();
         this.hz42ScPx.x = Math.round(hp.x + this.hz42ScX - sw / 2);
         this.hz42ScPx.y = Math.round(hp.y - this.hz42ScY - sh / 2);
         this.hz42ScPx.visible = true;
      }
      // ARRANGE drag / nudge: the proxy center -> offsets from the home spot
      private function hz42ScFromPx(c:Sprite) : void
      {
         var hp:Point = this.hz42ScHome();
         var boxH:Number = this.hz42ScBoxH > 0 ? this.hz42ScBoxH : HZ42_SC_H;
         var cx:Number = c.x + this.hz42ScW * c.scaleX / 2;
         var cy:Number = c.y + boxH * c.scaleY / 2;
         this.hz42ScPut(cx - hp.x,hp.y - cy,this.hz42ScS);
      }
      private function hz42ScStep(dir:int) : void
      {
         if(!this.hz42ScAvail()) { return; }
         this.hzArrSel = "ScopeChip";
         this.hz42ScPut(this.hz42ScX,this.hz42ScY,this.hz42ScS + dir * 0.05);
         this.hzArrDraw();
      }
      // "-  SIZE 1.00  +" chip on the selected proxy (click - / +, or the - / + keys)
      private function hz42ScChip(g:*) : void
      {
         if(this.hzArrSel != "ScopeChip" || this.hz42ScPx == null || !this.hz42ScPx.visible) { return; }
         var c:Sprite = this.hz42ScPx;
         var vr:Rectangle = this.hzVis();
         var cw:Number = 200;
         var bw:Number = Math.max(40,this.hzCW(c));
         var x:Number = c.x + bw / 2 - cw / 2;
         var y:Number = c.y - 58;
         if(y < vr.top + 4) { y = c.y + Math.max(24,this.hzCH(c)) + 10; }
         x = Math.max(vr.left + 4,Math.min(vr.right - 4 - cw,x));
         this.hzSetBox(g,x,y,cw,26,HZ_ACCENT,0.8,0x0B1620,0.92,13);
         var hm:Boolean = this.hzArrHover == "btn_hz42scm";
         var hq:Boolean = this.hzArrHover == "btn_hz42scp";
         this.hzSetBox(g,x + 3,y + 3,34,20,HZ_ACCENT,hm ? 1 : 0.6,0x26343F,hm ? 0.6 : 0.3,10);
         this.hzSetBox(g,x + cw - 37,y + 3,34,20,HZ_ACCENT,hq ? 1 : 0.6,0x26343F,hq ? 0.6 : 0.3,10);
         this.hzSText(this.hzArr_mc,"-",x + 3,y + 4,34,14,HZ_VALUE,"center");
         this.hzSText(this.hzArr_mc,"+",x + cw - 37,y + 4,34,14,HZ_VALUE,"center");
         this.hzSText(this.hzArr_mc,"SIZE " + this.hz42ScS.toFixed(2),x + 40,y + 4,cw - 80,13,HZ_ACCENT,"center");
         this.hzArrHits.push({"id":"btn_hz42scm","x":x + 3,"y":y + 3,"w":34,"h":20,"c":null});
         this.hzArrHits.push({"id":"btn_hz42scp","x":x + cw - 37,"y":y + 3,"w":34,"h":20,"c":null});
      }
      // =================== end v0.42.0 r2 ===================
      // =================== end v0.40 Scanner ===================
      // =================== end Horizon UI (HUD module) ===================
