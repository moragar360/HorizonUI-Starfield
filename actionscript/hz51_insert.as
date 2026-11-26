      // ===================== Settings 2.0 (F11 rebuild) =====================
      // Purpose: five-tab settings shell (CARDS / APPEARANCE / SCANNER / COMMS / SYSTEM)
      // with one shared sidebar, table-boxed rows, dropdowns, header search, and live
      // Diagnostics. Runs only while F11 is open: the search index is built on open
      // and dropped on close. No HUD-frame polling. Author: Moragar. Last modified: 2026-11-26.
      private var hzSetPage:int = 0;
      private var hzSetDrop:int = -1;
      private var hzSetDropHi:int = 0;
      private var hzSetFindOn:Boolean = false;
      private var hzSetFind:String = "";
      private var hzSetFindHi:int = 0;
      private var hzSetIdx:Array = null;
      private var hzSetGlowK:String = "";
      private var hzSetGlowT:Number = 0;
      private var hzSetHexK:String = "";
      private var hzSetHexBuf:String = "";
      private var hzSetHexPrev:int = -1;
      private var hzSetSideHits:Array = [];
      private static const HZ51_ROW:Number = 54;
      private static const HZ51_SIDE_W:Number = 168;
      private static const HZ51_PREV_W:Number = 196;
      private static const HZ51_FOOT:Number = 100;
      private static const HZ51_PERF_NAMES:Array = ["BASELINE","HOVER SKIP","FIXTURE","FULL PIPELINE","SAME TARGET","RAPID TARGETS","SCANNER","BACKGROUND HUD"];

      private function hz51Side(tab:int) : Array
      {
         if(tab == 0) { return [{"g":"HUD CARDS","items":[{"id":"gen","l":"GENERAL","s":"Compact strips · HUD scale"},{"id":"sta","l":"STATUS","s":"Vitals · Jetpack · Afflictions"},{"id":"com","l":"COMBAT","s":"Equipment · Enemy · Scope"},{"id":"nav","l":"NAVIGATION","s":"Compass · Quests · Planet"},{"id":"chr","l":"CHARACTER & WATCH","s":"Character · Watch"}]},{"g":"WORLD","items":[{"id":"int","l":"INTERACTION","s":"Target · Container · Vehicle"}]},{"g":"MENUS & ALERTS","items":[{"id":"qm","l":"QUICK MENU / FAVORITES MENU","s":"Horizon style · Extended"},{"id":"ntf","l":"NOTIFICATIONS","s":"XP toast"}]}]; }
         if(tab == 1) { return [{"g":"LOOK","items":[{"id":"col","l":"COLORS","s":"Accent · Card background"},{"id":"pan","l":"PANELS","s":"Opacity · Background % · Shadow"},{"id":"typ","l":"TYPOGRAPHY","s":"Font · Size · Tone"}]},{"g":"PLACE","items":[{"id":"siz","l":"SIZE & PLACEMENT","s":"HUD scale · Margin · Pixel snap"}]},{"g":"MOTION","items":[{"id":"mot","l":"MOTION & FADING","s":"Smooth bars · Fade · Combat dim"}]},{"g":"CLOCKS","items":[{"id":"clk","l":"CLOCKS & UNITS","s":"Planet time · 12/24 · Temperature"}]}]; }
         if(tab == 2) { return [{"g":"SCANNER","items":[{"id":"ov","l":"OVERVIEW","s":"Module · Layout · Reach"},{"id":"hud","l":"HUD","s":"What stays while you scan"},{"id":"tl","l":"TOOLS","s":"Mode pill · Hints · Outlines"}]},{"g":"FINDINGS","items":[{"id":"sig","l":"SIGNALS","s":"Signals · Compass · World tags"},{"id":"sv","l":"SURVEY","s":"Planet · Bioscan · Traits"}]},{"g":"LOOK","items":[{"id":"pop","l":"POPUPS","s":"Quest and trait popups"},{"id":"ap","l":"APPEARANCE","s":"Colors · Font · Distance"}]}]; }
         if(tab == 3) { return [{"g":"CONVERSATION","items":[{"id":"dlg","l":"DIALOGUE","s":"Layout and look"},{"id":"sub","l":"SUBTITLES","s":"Lines · Speaker · Card"}]},{"g":"ALERTS","items":[{"id":"mst","l":"MISSION TOASTS & REACTIONS","s":"Quest banner and companion lines"}]},{"g":"MODULE","items":[{"id":"cmp","l":"COMPATIBILITY","s":"When another add-on is in the way"}]}]; }
         return [{"g":"SETUP","items":[{"id":"pr","l":"PRESETS","s":"Select · Apply · Save"},{"id":"mod","l":"MODULES","s":"Enabled · Paused · Missing"}]},{"g":"DATA","items":[{"id":"ml","l":"MESSAGE LOG","s":"Record · History · Open"}]},{"g":"SESSION","items":[{"id":"ctl","l":"CONTROLS & WINDOW","s":"Menu key · Opacity"},{"id":"bak","l":"BACKUP & RESET","s":"Backup · scoped resets"},{"id":"dg","l":"DIAGNOSTICS","s":"Debug overlay"}]}];
      }
      private function hz51Pages(tab:int) : Array
      {
         var out:Array = [];
         var g:int = 0;
         var groups:Array = this.hz51Side(tab);
         while(g < groups.length)
         {
            var items:Array = groups[g].items as Array;
            var i:int = 0;
            while(i < items.length) { out.push(items[i]); i++; }
            g++;
         }
         return out;
      }
      private function hz51PageClamp(tab:int) : int
      {
         var n:int = this.hz51Pages(tab).length;
         if(n <= 0) { return 0; }
         if(this.hzSetPage < 0) { return 0; }
         if(this.hzSetPage >= n) { return n - 1; }
         return this.hzSetPage;
      }
      private function hz51PageId(tab:int) : String
      {
         var p:Array = this.hz51Pages(tab);
         var i:int = this.hz51PageClamp(tab);
         if(i < 0 || i >= p.length) { return ""; }
         return String(p[i].id);
      }
      private function hz51Crumb(tab:int, page:int) : String
      {
         var tabs:Array = HZ_SET_TABS;
         var t:String = tab >= 0 && tab < tabs.length ? String(tabs[tab]) : "";
         var pages:Array = this.hz51Pages(tab);
         var lab:String = page >= 0 && page < pages.length ? String(pages[page].l) : "";
         var gid:String = page >= 0 && page < pages.length ? String(pages[page].id) : "";
         var gname:String = "";
         var groups:Array = this.hz51Side(tab);
         var g:int = 0;
         while(g < groups.length)
         {
            var items:Array = groups[g].items as Array;
            var i:int = 0;
            while(i < items.length)
            {
               if(String(items[i].id) == gid) { gname = String(groups[g].g); }
               i++;
            }
            g++;
         }
         if(lab.length == 0) { return t; }
         if(gname.length > 0 && gname != lab) { return t + " > " + gname + " > " + lab; }
         return t + " > " + lab;
      }
      private function hz51Copy(r:Object) : Object
      {
         var o:Object = {};
         for(var k:String in r) { o[k] = r[k]; }
         return o;
      }
      private function hz51ByKey(rows:Array) : Object
      {
         var m:Object = {};
         var i:int = 0;
         while(i < rows.length) { if(rows[i] != null && rows[i].k != null) { m[String(rows[i].k)] = rows[i]; } i++; }
         return m;
      }
      private function hz51Pick(src:Array, keys:Array) : Array
      {
         var m:Object = this.hz51ByKey(src);
         var out:Array = [];
         var i:int = 0;
         while(i < keys.length)
         {
            var k:String = String(keys[i]);
            if(m[k] != undefined) { out.push(this.hz51Copy(m[k])); }
            i++;
         }
         return out;
      }
      private function hz51HelpOf(k:String, r:Object) : String
      {
         var h:String = this.hz51Help(k);
         if(h != null && h.length > 0) { return h; }
         if(r != null && r.inote != undefined) { return String(r.inote); }
         if(r != null && r.info != undefined) { return String(r.info); }
         if(r != null && r.note != undefined) { return String(r.note); }
         var lab:String = r != null && r.l != undefined ? String(r.l) : k;
         return "Changes " + lab.toLowerCase() + " on your HUD.";
      }
      // Short line under the row label. Diagnostics wording is from the live overlay / timing / dump paths.
      private function hz51Line(k:String, r:Object) : String
      {
         switch(k)
         {
            case "Debug": return "Shows extra on-screen info about the scanner and compass to help track down a problem.";
            case "PerfDiag": return "Measures how long the HUD takes to update and saves it so a problem can be found.";
            case "PerfMode": return "Switches which HUD test runs. Ordinary play uses Baseline.";
            case "PerfDump": return "Saves one performance report the next time you apply settings.";
            case "_diagoff": return "These stay off while you play. Turn them on only if something needs checking.";
            default: break;
         }
         var h:String = this.hz51HelpOf(k, r);
         var d:int = h.indexOf(". ");
         if(d > 16 && d < 148) { return h.substr(0, d + 1); }
         if(h.length > 118) { return h.substr(0, 115) + "..."; }
         return h;
      }
      private function hz51Help(k:String) : String
      {
         switch(k)
         {
            case "Debug": return "Shows extra yellow text on the HUD about the crosshair, the weapon in your hands, what the compass sees, and environment keys. Compass icons also get small numbers. You see this on screen as soon as it is on. Turn it on only while you are tracking down a HUD problem, then turn it off so the extra text does not stay.";
            case "PerfDiag": return "Measures how long the HUD takes to update and keeps those timings so a slowdown can be found. You will not see a new panel on screen; the numbers are stored for a report. Ordinary play should leave this off. Turn it on only when you need a timing report, then turn it off. Saved looks do not change this.";
            case "PerfMode": return "Switches which HUD test runs while Advanced Performance Timing is on. Baseline is ordinary play and is the one to use unless you were asked to try a specific test. Hover Skip turns off Horizon hover cards and scanner drawing (the game's own hover can still show). Fixture shows a test stand-in instead of live loot, people, or ships. Full Pipeline, Same Target, Rapid Targets, Scanner, and Background HUD each isolate a different part of the HUD. These tests can hide cards or drawing on purpose.";
            case "PerfDump": return "Saves one performance report the next time you press OK. Leave this off for ordinary play. Turn it on, press OK, play for a short while, then turn it off again. Nothing is saved until you apply settings. Needs Advanced Performance Timing to be on.";
            case "_diagoff": return "Debug Overlay, Advanced Performance Timing, Perf Mode, and Arm Perf Dump stay off during ordinary play. Support can turn them on if something needs checking.";
            case "Compact": return "Turns the jetpack, health, and oxygen into slim strips. Mouse and keyboard only; this switch stays in the header so it is always in reach.";
            case "CompactScale": return "Size of the slim jetpack, health, and oxygen strips when Compact Mode is on. Follow HUD uses the overall HUD size. Custom sets a size just for those strips.";
            case "ShowVitals": return "Turns the health and oxygen card on or off. When it is on, Show when still decides the moments it appears, so an On switch with a Show when rule is not broken.";
            case "VitalsRule": return "When the vitals card appears. Always keeps it visible. HP or O2 below full shows it only when health or oxygen is not full. It can also show only in combat, or hide while you are in your ship.";
            case "VitalsLayout": return "Vertical stacks health above oxygen. Horizontal puts oxygen beside health on one row.";
            case "VitalsBars": return "Full keeps separate health and oxygen cards. Compact uses the same slim boost, health, and oxygen card as Compact Mode. If either Compact Mode or this Compact choice is on, that merged card shows.";
            case "AutoCenterVitals": return "When the equipment card is hidden, the vitals card slides to the exact center. After you move vitals in Arrange Cards, this is ignored.";
            case "RegenSliver": return "A green sliver ahead of the health bar while health is coming back.";
            case "ShowJetpack": return "Turns the boost card on or off. Show when still decides the moments it appears.";
            case "JetpackRule": return "When the boost card appears. In use / not full shows it while you are boosting or boost is not full.";
            case "ShowAfflictions": return "Turns the afflictions card on or off.";
            case "AfflictionsRule": return "When the afflictions card appears. Only when afflicted shows it while you have an injury or effect.";
            case "AfflictionLayout": return "How affliction chips are arranged: a column, a row, or icons only.";
            case "HazardStatus": return "A small card that turns red while a hazard is hurting you and green while suit protection is restoring.";
            case "EdgePulse": return "A soft pulse at the edges of the screen when health or oxygen is very low. The center of the view stays clear.";
            case "ShowAmmo": return "Turns the equipment card (weapon, ammo, grenades, Starborn power) on or off.";
            case "AmmoRule": return "Crosshair off? Set this to ALWAYS or COMBAT ONLY.";
            case "EquipmentExtras": return "Shows grenade count and the selected Starborn power on the equipment card.";
            case "EnemyBar": return "Enemy health at the top center. Turns off the game's own enemy bar while this is on.";
            case "StealthMeter": return "A stealth pill above the crosshair while you sneak. Turns off the game's own stealth meter while this is on.";
            case "CrosshairRule": return "When the center aiming reticle shows. Always is the default. When weapon drawn shows it only with a weapon out. Off hides the reticle only; prompts, target cards, hit markers, the kill X, the damage ring, and the stealth pill stay.";
            case "CrosshairStyle": return "Look of the reticle while you look at something you can use: the game's ring, a Horizon dot, a Horizon cross, or none.";
            case "HitMarkers": return "A hit mark and a kill X at the crosshair. Turns off the game's own markers while this is on.";
            case "DamageNumbers": return "Floating damage numbers. Turns off the game's own numbers while this is on.";
            case "DirectionRing": return "A ring around the crosshair that shows where damage came from. Turns off the game's own arcs while this is on.";
            case "ScopeHoldBreathChip": return "While you aim down a scope, the hold-breath prompt is a Horizon chip with an oxygen meter. Off uses the game's own prompt.";
            case "ScopeChipScale": return "Size of the hold-breath chip. 1.00 matches the game's prompt. Use plus and minus for a precise size.";
            case "_hz42scrst": return "Puts the hold-breath chip back at the game's spot and size.";
            case "ShowCompass": return "Turns the Horizon compass on or off.";
            case "CompassRule": return "When the compass appears.";
            case "CompassMarkers": return "Master switch for markers on the Horizon compass. Quest objectives still show while this is on.";
            case "ShowFollowers": return "Markers for your follower and companions on the compass.";
            case "FollowerColor": return "Color of follower and companion markers on the compass.";
            case "ShowLocations": return "Location, point-of-interest, and outpost markers on the compass.";
            case "ShowShip": return "Your ship and vehicle on the compass.";
            case "ShowEnemies": return "Enemy markers on the compass.";
            case "ShowPlayerMarker": return "Your custom map marker on the compass.";
            case "ShowQuests": return "Turns the quest tracker on or off.";
            case "QuestsRule": return "When the quest tracker appears.";
            case "QuestsWidth": return "How wide the quest tracker is. Font size stays the same. A narrower card wraps the objective onto more lines.";
            case "QuestsMaxHeight": return "How tall the quest tracker may grow. Extra lines stop at this height.";
            case "QuestsWrap": return "When on, long quest text starts a new line instead of ending in an ellipsis.";
            case "ShowPlanet": return "Turns the planet card on or off.";
            case "PlanetRule": return "When the planet card appears.";
            case "PlanetDetails": return "Adds a gravity and air line under the planet name.";
            case "HazardAlert": return "While exposure to heat, cold, radiation, or other hazards builds up, the planet card gets a pulsing amber outline.";
            case "ShowCharacter": return "Turns the character card (level, XP, credits, mass) on or off.";
            case "CharacterRule": return "When the character card appears. Event choices show it for a few seconds after XP, a level up, credits, or a skill point, and can also show when you are overweight.";
            case "CharacterShowSeconds": return "How many seconds the character card stays up after an event. This is used only when Show when is an event choice. It does nothing when Show when is Always.";
            case "WatchStyle": return "Wrist watch in the lower left: Off, the game's watch, the game's watch with Horizon colors, Horizon digital, or Horizon analog.";
            case "ShowTarget": return "Horizon's card for the activate prompt and item hover. Off uses the game's prompt.";
            case "NameHover": return "Compact is one line: icon, name, and key. Full is the taller card.";
            case "HoverScale": return "Size of activate prompts, loose-item cards, compare cards, and enemy tags.";
            case "TargetAnchor": return "Where hover cards sit. Crosshair keeps them by the reticle. Follow target sits them next to the object on screen.";
            case "TargetShowValue": return "Shows value and weight on the item hover card and on the selected container row.";
            case "ContainerScale": return "Size of the full container item list.";
            case "ContainerOpacity": return "How solid the container list and crosshair item cards are. This is separate from HUD card opacity.";
            case "ObjectRing": return "The ring and line the game draws around the object you look at. Off never shows it. Containers only shows it on a container list. Vanilla is the game's own drawing.";
            case "VehicleExitPill": return "While you are in a vehicle, the hold-to-exit prompt is a Horizon pill. Off uses the game's prompt. Move it in Arrange Cards.";
            case "QuickMenuHorizon": return "The favorites menu draws each slot as a Horizon card in your colors and font. Off uses the game's own look.";
            case "QuickMenuExtended": return "Adds extra slots beyond the game's twelve. Off is the game's twelve-slot layout. On shows up to twenty-four. Slots 1-12 still use the game's own favorite keys.";
            case "QuickMenuSlotCount": return "How many slots show when Extended Mode is on, from 12 to 24. Lowering the count only hides extra tiles; keys and items are kept.";
            case "QuickMenuSlotsPerRow": return "How many extra slots sit in each row: 4, 6, or 8.";
            case "QuickMenuExtendedLayout": return "Cross + Bars keeps the game's T for slots 1-12 and puts extra slots in bars under it. Bars draws every slot in rows.";
            case "_qmkeys": return "Keys for extra slots 13 and up. Press a chip, then press a key. Esc cancels. Backspace or Delete clears. An orange warning appears if that key is already used. Slots 1-12 use the game's own favorite keys.";
            case "_qmclear": return "Clears every extra-slot key. The slots still work from the menu.";
            case "XpToast": return "A short +XP note beside the character card. With Horizon messages installed, the game's own +XP popup is hidden while this is on.";
            case "MissionToast": return "Replaces the game's quest banner with a Horizon toast. Move it in Arrange Cards.";
            case "MissionToastTime": return "How many seconds each mission toast stays on screen.";
            case "MissionToastMax": return "How many mission toasts may stack at once.";
            case "MissionToastScale": return "Size of the mission toast. Follow HUD uses the overall HUD size.";
            case "MissionToastSound": return "The quest sound comes from the game's banner and always plays. It cannot be turned off here.";
            case "ReactionCard": return "Restyles companion 'liked that' lines as a Horizon card. English game text only for now; other lines stay the game's.";
            case "GameCardTitle": return "Small label above the game's other notices. None shows just the message. Data or Misc adds that label. Applies from the next message.";
            case "AccentColor": return "Color of highlights, switches, and this window. Custom lets you type a six-digit color. An invalid color keeps the last good one. The whole settings screen follows this color.";
            case "CardColor": return "Fill color of HUD cards and this window. Custom lets you type a six-digit color. Light fills switch the text to dark.";
            case "CardOpacity": return "How solid HUD cards are. Values above 1.00 stay fully solid and then push the fill darker or brighter. This is not the same as Card background.";
            case "CardBgOpacity": return "How see-through the card fill is, from clear at 0 to solid at 100. This is direct transparency and is separate from Card opacity, which can go above 1.00.";
            case "CardShadow": return "Strength of the shadow under HUD cards. 0 is none. 12 is the built-in look. 100 is a strong shadow.";
            case "SettingsOpacity": return "How see-through this settings window is. 30 is the lightest. 100 is solid.";
            case "FontFace": return "Font for Horizon text. Exo 2 is the default. If a Horizon font is not installed, the game font is used and your choice is kept.";
            case "TextScale": return "Size of Horizon text, on top of HUD scale.";
            case "TextTone": return "Auto uses dark text on light card colors. Light and Dark force one tone.";
            case "HeaderStyle": return "Card titles in spaced capital letters, or in title case with tight spacing.";
            case "TextShadow": return "A soft drop shadow under HUD text. Helps on bright scenery; off is sharpest.";
            case "HudScale": return "Size of every Horizon card that follows the HUD. A card with its own Custom size no longer follows this.";
            case "Margin": return "Gap between the screen edge and the cards. Cards you moved in Arrange Cards keep their distance from this line.";
            case "ScreenHeight": return "Your vertical resolution so crosshair cards land on whole pixels and stay sharp. Off skips snapping.";
            case "SmoothBars": return "Horizon bars glide to a new value instead of jumping. Health bars also keep a short fading ghost of what you just lost.";
            case "FadeCards": return "Cards fade and slide when they appear or hide, instead of popping.";
            case "CombatDim": return "Out of combat (and not at low health) HUD cards fade toward Dim opacity.";
            case "DimOpacity": return "How far cards fade out of combat. Lower is fainter.";
            case "TimeDisplay": return "Time on the planet card: off, local planet time, your PC clock, or both.";
            case "ClockFormat": return "12-hour or 24-hour clock for local, game, and PC time.";
            case "TempUnit": return "Celsius or Fahrenheit on the planet card and scanner.";
            case "StartupIntro": return "Plays a short HORIZON UI welcome after you load a save. It never pauses the game and never takes input.";
            case "SettingsKey": return "The key that opens this window. A new key takes effect after you restart the game.";
            case "Record": return "When on, new HUD messages are stored in the log. When off, nothing new is stored. Messages still show on screen.";
            case "Persist": return "When on, the log is saved on disk. Turning this off only stops writing; existing files are not deleted.";
            case "HistorySize": return "How many messages to keep per character.";
            case "_mlfolder": return "Folder on disk where saved logs are kept, when Save to disk is on.";
            case "_mlold": return "Logs from earlier characters. Open one from here; search and pins stay inside the log window.";
            case "_msglog": return "Opens the message log. Type filters, search, pins, and clear stay inside that window.";
            case "ScanReach": return "Changes how far the scanner can outline and scan things. Vanilla leaves the game as it is. 2x, 3x, and 5x multiply that distance, never past 500 meters. A long reach can cost frame rate in busy areas. Applies the next time you open the scanner.";
            case "ScanHighlightArea": return "How far from the screen center the scanner picks up and outlines things. This does not change how far away you can scan (that is Scan reach). Small is about half the game's circle. Vanilla is the game's own. Large reaches the top and bottom. Wide reaches the left and right. Full screen covers the corners too. Applies the next time you open the scanner.";
            case "ScanOutlineThickness": return "How thick scanner outlines are. Vanilla keeps the game's own look. Thick is one and a half times. Thicker is twice. Applies the next time you open the scanner.";
            case "HideMainHudWhileScanning": return "Hides ordinary Horizon HUD cards while the hand scanner is open. Item cards, the container list, the activate prompt, and combat feedback always stay.";
            case "HideWatchWhileScanning": return "Hides the watch while the hand scanner is open. Shared clocks on the planet card are unchanged.";
            case "HideQuestPopupsWhileScanning": return "Hides quest popups and the mission toast while you scan. This belongs with messages and works even when the scanner add-on is not installed.";
            case "DimTraitPopupDuringBioscan": return "Dims the trait popup while you scan. This belongs with messages and works even when the scanner add-on is not installed.";
            case "TraitPopupDim": return "How dim the trait popup is while you scan.";
            case "_hz41arrscan": return "Opens a mock scanner on the HUD so you can drag panels and the kept vitals, then save.";
            case "_hz40rstlay": return "Puts scanner panel spots, sizes, and compact forms back to their defaults. Other Horizon settings are kept.";
            case "_hz40rstall": return "Puts every scanner setting back to its default. Cards, look, and message settings are kept.";
            case "_goto_hudscale": return "Opens Size and Placement so you can change the shared HUD scale.";
            case "_goto_margin": return "Opens Size and Placement so you can change the shared screen margin.";
            case "_goto_clocks": return "Opens Clocks and Units, which the watch and planet card also use.";
            case "_goto_scanwatch": return "Opens Scanner HUD for hiding the watch while you scan.";
            case "_arrange": return "Drag HUD cards on screen. Save keeps the new spots.";
            default: return "";
         }
      }
      private function hz51Finish(rows:Array) : Array
      {
         // Compact Mode lives in the header, not as a list row. Every list row keeps a
         // short help line (note) and longer Setting Details (inote).
         var out:Array = [];
         var i:int = 0;
         while(i < rows.length)
         {
            var r:Object = this.hz51Copy(rows[i]);
            var k:String = String(r.k);
            var help:String = this.hz51HelpOf(k, r);
            r.inote = help;
            if(r.dis)
            {
               if(r.note == undefined || String(r.note).length == 0) { r.note = help; }
               r.n13 = true;
            }
            else { r.note = this.hz51Line(k, r); }
            if(k.length >= 7 && k.substr(k.length - 7) == "Compact" && r.opts == undefined)
            {
               r.t = "r";
               r.opts = ["GLOBAL","ON","OFF"];
               r.ids = [-1,1,0];
            }
            if(r.t == "a" && r.names != undefined)
            {
               var names:Array = (r.names as Array).concat();
               if(names.length == 0 || String(names[names.length - 1]) != "CUSTOM") { names.push("CUSTOM"); r.names = names; }
               if(r.pal != undefined)
               {
                  var pal:Array = (r.pal as Array).concat();
                  if(pal.length < names.length) { pal.push(pal.length > 0 ? pal[pal.length - 1] : HZ_ACCENT); r.pal = pal; }
               }
            }
            out.push(r);
            i++;
         }
         return this.hz51Mute(out);
      }
      private function hz51On(k:String) : Boolean
      {
         if(this.hzSetPend == null) { return true; }
         var v:* = this.hzSetPend[k];
         if(v === undefined) { return true; }
         if(v is Boolean) { return Boolean(v); }
         return Number(v) >= 0.5;
      }
      private function hz51Mute(rows:Array) : Array
      {
         var i:int = 0;
         var parentOn:Boolean = true;
         var extOn:Boolean = this.hz51On("QuickMenuExtended") && this.hz51On("QuickMenuHorizon");
         var hideHud:Boolean = this.hz51On("HideMainHudWhileScanning");
         var charRule:int = this.hzSetPend != null ? int(this.hzSetPend.CharacterRule) : 0;
         while(i < rows.length)
         {
            var r:Object = rows[i];
            var k:String = String(r.k);
            if(r.t == "b" && k.indexOf("Show") == 0) { parentOn = this.hz51On(k); }
            if(k == "HazardStatus" || k == "EnemyBar" || k == "StealthMeter" || k == "XpToast" || k == "MissionToast" || k == "Subtitles" || k == "Dialogue" || k == "QuickMenuHorizon" || k == "QuickMenuExtended" || k == "Record" || k == "Persist") { parentOn = this.hz51On(k); }
            if(r.sub && !parentOn && !r.dis)
            {
               r.dis = true;
               if(r.dv === undefined) { r.dv = this.hzSetPend != null ? this.hzSetPend[k] : 0; }
            }
            if(k == "CharacterShowSeconds")
            {
               var eventRule:Boolean = charRule == 7 || charRule == 8 || charRule == 9;
               if(!eventRule)
               {
                  r.dis = true;
                  r.dv = this.hzSetPend != null ? this.hzSetPend.CharacterShowSeconds : 8;
                  r.note = "Used only when Show when is an event choice. Your saved time is kept.";
                  r.n13 = true;
               }
            }
            if((k.indexOf("QuickMenuKey") == 0 || k == "QuickMenuSlotCount" || k == "QuickMenuSlotsPerRow" || k == "QuickMenuExtendedLayout" || k == "_qmkeys" || k == "_qmclear") && !extOn && !r.dis)
            {
               r.dis = true;
               r.note = "Turn on Extended Mode to bind keys. Saved keys are kept.";
               r.n13 = true;
            }
            if(k.indexOf("ScanShowVitals") == 0 || k == "ScanVitalsCompact" || k == "ScanVitalsLayout")
            {
               if(!hideHud && !r.dis)
               {
                  r.dis = true;
                  r.dv = this.hzSetPend != null ? this.hzSetPend[k] : 0;
                  r.note = "Only used while Hide Horizon HUD while scanning is on.";
                  r.n13 = true;
               }
            }
            if((k == "PerfMode" || k == "PerfDump") && !this.hz51On("PerfDiag") && !r.dis)
            {
               r.dis = true;
               r.dv = this.hzSetPend != null ? this.hzSetPend[k] : 0;
               r.note = "Turn on Advanced Performance Timing first. Your saved choice is kept.";
               r.n13 = true;
            }
            i++;
         }
         return rows;
      }
      private function hz51RuleRow(key:String, ids:Array) : Object
      {
         var opts:Array = [];
         var i:int = 0;
         while(i < ids.length)
         {
            var id:int = int(ids[i]);
            if(key == "CrosshairRule")
            {
               if(id == 0) { opts.push("ALWAYS"); }
               else if(id == 1) { opts.push("WHEN WEAPON DRAWN"); }
               else { opts.push("OFF"); }
            }
            else { opts.push(String(HZ_RULE_NAMES[Math.max(0,Math.min(HZ_RULE_NAMES.length - 1,id))])); }
            i++;
         }
         var t:String = key == "CrosshairRule" ? "r" : "q";
         var r:Object = {"k":key,"l":"SHOW WHEN","t":t,"ids":ids,"opts":opts,"sub":true};
         if(key == "CrosshairRule") { r.t = "r"; }
         return r;
      }
      private function hz51Card(onKey:String, onLab:String, section:String, ruleKey:String, ruleIds:Array, scaleKey:String, compactKey:String, extra:Array) : Array
      {
         var rows:Array = [{"k":onKey,"l":onLab,"t":"b","h":section}];
         if(ruleKey != null && ruleKey.length > 0) { rows.push(this.hz51RuleRow(ruleKey, ruleIds)); }
         if(scaleKey != null && scaleKey.length > 0) { rows.push({"k":scaleKey,"l":"SIZE","t":"z","sub":true}); }
         if(compactKey != null && compactKey.length > 0) { rows.push({"k":compactKey,"l":"COMPACT FORM","t":"r","opts":["GLOBAL","ON","OFF"],"ids":[-1,1,0],"sub":true}); }
         var i:int = 0;
         while(extra != null && i < extra.length) { rows.push(extra[i]); i++; }
         return rows;
      }
      private function hz51Goto(id:String, lab:String, tab:int, page:int, key:String, section:String) : Object
      {
         return {"k":id,"l":lab,"t":"x","btn":"OPEN","h":section,"goT":tab,"goP":page,"goK":key};
      }
      private function hz51ModState(id:String) : Object
      {
         var st:Object = {"id":id,"on":false,"inst":false,"paused":false,"why":"","act":""};
         if(id == "core") { st.inst = true; st.on = true; return st; }
         if(id == "font") { st.inst = this.hz30FontAvail(); st.on = st.inst; if(!st.inst) { st.why = "Install it from the Horizon UI installer."; } return st; }
         if(id == "quickmenu")
         {
            st.inst = this.hz30Mod["quickmenu"] === 1;
            st.on = st.inst && this.hzQmOn !== false;
            st.paused = st.inst && this.hzQmConflict;
            if(!st.inst) { st.why = "Install it from the Horizon UI installer."; }
            else if(st.paused) { st.why = "Extended Mode is paused because another favorites add-on is installed."; st.act = "Horizon style still works. Extended slots stay off until the other add-on is removed."; }
            return st;
         }
         if(id == "comms")
         {
            st.inst = this.hz30Mod["comms"] === 1;
            st.on = st.inst;
            st.paused = st.inst && ((this.hz31SubForeign().length > 0 && Boolean(this.hz31Val("SubAutoPause"))) || (this.hz31On("comms_dialogue") && this.hz31DlgForeign() && Boolean(this.hz31Val("DlgAutoPause"))));
            if(!st.inst) { st.why = "Install it from the Horizon UI installer."; }
            else if(st.paused) { st.why = "Horizon subtitles or dialogue are paused because another add-on was found."; st.act = "Use Horizon to turn Horizon's own menus back on."; }
            return st;
         }
         if(id == "scanner")
         {
            st.inst = this.hz30Mod["scanner"] === 1;
            st.on = st.inst;
            if(!st.inst) { st.why = "Install it from the Horizon UI installer."; }
            return st;
         }
         if(id == "scope")
         {
            st.inst = this.hz30Mod["scope"] === 1;
            st.on = st.inst;
            if(!st.inst) { st.why = "Install it from the Horizon UI installer."; }
            return st;
         }
         st.inst = this.hzMsglogModule() == 1;
         st.on = st.inst;
         if(!st.inst) { st.why = "Install it from the Horizon UI installer."; }
         return st;
      }
      private function hz51Unavail(rows:Array, why:String) : Array
      {
         var i:int = 0;
         while(i < rows.length)
         {
            if(!rows[i].pill)
            {
               rows[i].dis = true;
               if(rows[i].dv === undefined && this.hzSetPend != null) { rows[i].dv = this.hzSetPend[String(rows[i].k)]; }
               rows[i].note = why;
               rows[i].n13 = true;
            }
            i++;
         }
         rows.unshift({"k":"_unavail","l":"UNAVAILABLE","t":"w","dis":true});
         return rows;
      }
      private function hz51Rows(tab:int, page:int) : Array
      {
         var id:String = "";
         var pages:Array = this.hz51Pages(tab);
         if(page >= 0 && page < pages.length) { id = String(pages[page].id); }
         var rows:Array = [];
         if(tab == 0) { rows = this.hz51Cards(id); }
         else if(tab == 1) { rows = this.hz51Appear(id); }
         else if(tab == 2) { rows = this.hz51Scan(id); }
         else if(tab == 3) { rows = this.hz51Comms(id); }
         else { rows = this.hz51System(id); }
         return this.hz51Finish(rows);
      }
      private function hz51Cards(id:String) : Array
      {
         var all:Array = this.hz34CardRows();
         var m:Object = this.hz51ByKey(all);
         var rows:Array = [];
         if(id == "gen")
         {
            if(m["CompactScale"] != undefined) { var cs:Object = this.hz51Copy(m["CompactScale"]); cs.h = "COMPACT STRIPS"; cs.l = "COMPACT STRIPS: SIZE"; rows.push(cs); }
            rows.push(this.hz51Goto("_goto_hudscale","HUD SCALE",1,3,"HudScale","RELATED APPEARANCE SETTINGS"));
            rows.push(this.hz51Goto("_goto_margin","SCREEN MARGIN",1,3,"Margin",""));
            rows.push({"k":"_arrange","l":"ARRANGE CARDS","t":"x","btn":"ARRANGE"});
            return rows;
         }
         if(id == "sta")
         {
            rows = rows.concat(this.hz51Card("ShowVitals","VITALS","VITALS","VitalsRule",[0,5,1,2],"VitalsScale","", [
               this.hz51Copy(m["VitalsLayout"] != undefined ? m["VitalsLayout"] : {"k":"VitalsLayout","l":"LAYOUT","t":"r","opts":["VERTICAL","HORIZONTAL"],"ids":[0,1],"sub":true}),
               this.hz51Copy(m["VitalsBars"] != undefined ? m["VitalsBars"] : {"k":"VitalsBars","l":"HEALTH AND O2 BARS","t":"r","opts":["FULL","COMPACT"],"ids":[0,1],"sub":true}),
               {"k":"AutoCenterVitals","l":"AUTO-CENTER WHEN EQUIPMENT HIDDEN","t":"b","sub":true},
               {"k":"RegenSliver","l":"HEALING REGEN SLIVER","t":"b","sub":true}
            ]));
            rows = rows.concat(this.hz51Card("ShowJetpack","JETPACK","JETPACK","JetpackRule",[0,4,1,2],"JetpackScale","", []));
            rows = rows.concat(this.hz51Card("ShowAfflictions","AFFLICTIONS","AFFLICTIONS","AfflictionsRule",[0,6,1,2],"AfflictionsScale","", [
               {"k":"AfflictionLayout","l":"LAYOUT","t":"r","opts":HZ_AFLAY_NAMES,"sub":true}
            ]));
            rows = rows.concat(this.hz51Card("HazardStatus","HAZARD STATUS","HAZARD STATUS","","", "HazardScale","HazardCompact", []));
            rows.push({"k":"EdgePulse","l":"LOW HEALTH / O2 SCREEN-EDGE PULSE","t":"b","h":"WARNINGS"});
            return rows;
         }
         if(id == "com")
         {
            rows = rows.concat(this.hz51Card("ShowAmmo","EQUIPMENT","EQUIPMENT","AmmoRule",[0,3,1,2],"EquipmentScale","EquipmentCompact", [
               {"k":"EquipmentExtras","l":"GRENADES + STARBORN POWER","t":"b","sub":true}
            ]));
            rows = rows.concat(this.hz51Card("EnemyBar","ENEMY HEALTH","ENEMY HEALTH","","","EnemyScale","", []));
            rows = rows.concat(this.hz51Card("StealthMeter","STEALTH","STEALTH","","","StealthScale","", []));
            rows.push({"k":"CrosshairRule","l":"SHOW WHEN","t":"r","opts":["ALWAYS","WHEN WEAPON DRAWN","OFF"],"ids":[0,1,2],"h":"CROSSHAIR"});
            rows.push({"k":"CrosshairStyle","l":"INTERACTION STYLE","t":"r","opts":HZ_XH_NAMES,"sub":true});
            rows.push({"k":"HitMarkers","l":"HIT MARKER / KILL X","t":"b","h":"COMBAT FEEDBACK"});
            rows.push({"k":"DamageNumbers","l":"DAMAGE NUMBERS","t":"b"});
            rows.push({"k":"DirectionRing","l":"DAMAGE DIRECTION RING","t":"b"});
            try { this.hz42ScRows(rows); } catch(eSc:Error) { }
            return rows;
         }
         if(id == "nav")
         {
            rows = rows.concat(this.hz51Card("ShowCompass","COMPASS","COMPASS","CompassRule",[0,1,2],"CompassScale","CompassCompact", [
               {"k":"CompassMarkers","l":"MARKERS","t":"b","sub":true},
               {"k":"ShowFollowers","l":"FOLLOWERS / COMPANIONS","t":"b","sub":true},
               {"k":"FollowerColor","l":"MARKER COLOR","t":"a","pal":HZ_FOL_PAL,"names":HZ_FOL_NAMES,"sub":true},
               {"k":"ShowLocations","l":"LOCATIONS / POIS / OUTPOSTS","t":"b","sub":true},
               {"k":"ShowShip","l":"SHIP / VEHICLE","t":"b","sub":true},
               {"k":"ShowEnemies","l":"ENEMIES","t":"b","sub":true},
               {"k":"ShowPlayerMarker","l":"CUSTOM MAP MARKER","t":"b","sub":true}
            ]));
            rows = rows.concat(this.hz51Card("ShowQuests","QUEST TRACKER","QUEST TRACKER","QuestsRule",[0,1,2],"QuestsScale","QuestsCompact", [
               {"k":"QuestsWidth","l":"WIDTH","t":"n","mn":380,"mx":660,"st":20,"sub":true},
               {"k":"QuestsMaxHeight","l":"MAX HEIGHT","t":"n","mn":100,"mx":300,"st":10,"sub":true},
               {"k":"QuestsWrap","l":"TEXT WRAPPING","t":"b","sub":true}
            ]));
            rows = rows.concat(this.hz51Card("ShowPlanet","PLANET","PLANET","PlanetRule",[0,1,2],"PlanetScale","PlanetCompact", [
               {"k":"PlanetDetails","l":"DETAILS LINE","t":"b","sub":true},
               {"k":"HazardAlert","l":"HAZARD ALERT","t":"b","sub":true}
            ]));
            return rows;
         }
         if(id == "chr")
         {
            rows = rows.concat(this.hz51Card("ShowCharacter","CHARACTER","CHARACTER","CharacterRule",[0,7,8,9,1,2],"CharacterScale","CharacterCompact", [
               {"k":"CharacterShowSeconds","l":"SHOW FOR (SECONDS)","t":"n","mn":2,"mx":60,"st":1,"sub":true}
            ]));
            rows.push({"k":"WatchStyle","l":"WATCH","t":"r","h":"WATCH","opts":["OFF","VANILLA","VANILLA + HORIZON","HORIZON DIGITAL","HORIZON ANALOG"],"ids":[0,1,2,3,4]});
            if(m["WatchScale"] != undefined) { var ws:Object = this.hz51Copy(m["WatchScale"]); ws.l = "SIZE"; ws.sub = true; rows.push(ws); }
            rows.push(this.hz51Goto("_goto_clocks","CLOCKS & UNITS",1,5,"TimeDisplay","LINKS"));
            rows.push(this.hz51Goto("_goto_scanwatch","HIDE WATCH WHILE SCANNING",2,1,"HideWatchWhileScanning",""));
            return rows;
         }
         if(id == "int")
         {
            rows = rows.concat(this.hz51Card("ShowTarget","TARGET CARD","TARGET & HOVER","","","", "", [
               this.hz51Copy(m["NameHover"] != undefined ? m["NameHover"] : {"k":"NameHover","l":"NAME HOVER","t":"r","opts":["COMPACT","FULL"],"ids":[0,1],"sub":true}),
               {"k":"HoverScale","l":"HOVER SIZE","t":"z","sub":true},
               {"k":"TargetAnchor","l":"ANCHOR","t":"r","opts":HZ_TGANCHOR_NAMES,"sub":true},
               {"k":"TargetShowValue","l":"ITEM VALUE / WEIGHT","t":"b","sub":true}
            ]));
            rows.push({"k":"ContainerScale","l":"LIST SIZE","t":"z","h":"CONTAINER"});
            rows.push({"k":"ContainerOpacity","l":"CONTAINER / CROSSHAIR CARD OPACITY","t":"n","mn":0.2,"mx":1.6,"st":0.05,"sub":true});
            rows.push({"k":"ObjectRing","l":"OBJECT RING / LEADER LINE","t":"r","opts":HZ_RING_NAMES,"h":"OBJECT HIGHLIGHT"});
            rows.push({"k":"VehicleExitPill","l":"HORIZON EXIT PILL","t":"b","h":"VEHICLE"});
            return rows;
         }
         if(id == "qm") { return this.hz51Quick(); }
         var xp:Object = m["XpToastScale"] != undefined ? this.hz51Copy(m["XpToastScale"]) : {"k":"XpToastScale","l":"SIZE","t":"z"};
         xp.h = "XP TOAST";
         rows.push({"k":"XpToast","l":"XP TOAST","t":"b","h":"XP TOAST"});
         rows.push(xp);
         return rows;
      }
      private function hz51Quick() : Array
      {
         var rows:Array = [{"k":"QuickMenuHorizon","l":"HORIZON STYLE","t":"b","h":"QUICK MENU"},
            {"k":"QuickMenuExtended","l":"EXTENDED MODE","t":"b"},
            {"k":"QuickMenuSlotCount","l":"SLOT COUNT","t":"n","mn":12,"mx":24,"st":1},
            {"k":"QuickMenuSlotsPerRow","l":"SLOTS PER ROW","t":"r","opts":["4","6","8"],"ids":[4,6,8]},
            {"k":"QuickMenuExtendedLayout","l":"EXTENDED LAYOUT","t":"r","opts":["CROSS + BARS","BARS"],"ids":[0,1]},
            {"k":"_qmkeys","l":"EXTENDED SLOT KEYS","t":"kg","h":"EXTENDED SLOT KEYS"},
            {"k":"_qmclear","l":"CLEAR ALL KEYS","t":"x","btn":"CLEAR"}];
         var qmOff:Boolean = this.hz30Mod["quickmenu"] !== 1;
         var qmConf:Boolean = this.hzQmConflict;
         if(qmOff) { return this.hz51Unavail(rows, "Install it from the Horizon UI installer. Saved settings are kept."); }
         if(qmConf)
         {
            var i:int = 0;
            while(i < rows.length)
            {
               if(String(rows[i].k) != "QuickMenuHorizon")
               {
                  rows[i].dis = true;
                  rows[i].note = "Extended Mode is paused because another favorites add-on is installed. Saved keys are kept.";
                  rows[i].n13 = true;
               }
               i++;
            }
            rows.unshift({"k":"_qmconf","l":"EXTENDED MODE PAUSED","t":"w","dis":true});
         }
         return rows;
      }
      private function hz51Appear(id:String) : Array
      {
         if(id == "col")
         {
            return [{"k":"AccentColor","l":"ACCENT COLOR","t":"a","pal":this.hzAccPal(),"names":this.hzAccNames(),"h":"ACCENT"},
               {"k":"AccentHex","l":"CUSTOM ACCENT","t":"h","hex":"AccentHex","sub":true},
               {"k":"CardColor","l":"CARD BACKGROUND","t":"a","pal":this.hzCardPal(),"names":this.hzCardNames(),"h":"BACKGROUND"},
               {"k":"CardHex","l":"CUSTOM BACKGROUND","t":"h","hex":"CardHex","sub":true}];
         }
         if(id == "pan")
         {
            return [{"k":"CardOpacity","l":"HUD CARD OPACITY","t":"n","mn":0.2,"mx":1.6,"st":0.05,"h":"PANELS"},
               {"k":"CardBgOpacity","l":"CARD BACKGROUND %","t":"n","mn":0,"mx":100,"st":1,"pct":1},
               {"k":"CardShadow","l":"CARD SHADOW %","t":"n","mn":0,"mx":100,"st":1,"pct":1}];
         }
         if(id == "typ")
         {
            return this.hz30FontRows([{"k":"FontFace","l":"FONT","t":"r","opts":HZ_FONT_NAMES,"ids":HZ_FONT_IDS,"h":"TYPE"},
               {"k":"TextScale","l":"TEXT SIZE","t":"n","mn":0.8,"mx":1.3,"st":0.05},
               {"k":"TextTone","l":"TEXT TONE","t":"r","opts":HZ_TONE_NAMES},
               {"k":"HeaderStyle","l":"HEADER STYLE","t":"r","opts":HZ_HDRSTYLE_NAMES},
               {"k":"TextShadow","l":"TEXT SHADOW","t":"b"}]);
         }
         if(id == "siz")
         {
            return [{"k":"HudScale","l":"HUD SCALE","t":"n","mn":0.7,"mx":1.4,"st":0.05,"h":"SIZE & PLACEMENT"},
               {"k":"Margin","l":"SCREEN MARGIN","t":"n","mn":20,"mx":200,"st":10},
               {"k":"ScreenHeight","l":"SCREEN HEIGHT (PIXEL SNAP)","t":"l","vals":HZ_SET_SCRH,"names":HZ_SET_SCRH_N}];
         }
         if(id == "mot")
         {
            return [{"k":"SmoothBars","l":"SMOOTH BARS","t":"b","h":"MOTION"},
               {"k":"FadeCards","l":"FADE CARDS","t":"b"},
               {"k":"CombatDim","l":"DIM OUT OF COMBAT","t":"b"},
               {"k":"DimOpacity","l":"DIM OPACITY","t":"n","mn":0.2,"mx":1,"st":0.05}];
         }
         return [{"k":"TimeDisplay","l":"PLANET TIME","t":"r","opts":HZ_TIME_NAMES,"h":"CLOCKS"},
            {"k":"ClockFormat","l":"CLOCK FORMAT","t":"r","opts":HZ_CLOCK_NAMES},
            {"k":"TempUnit","l":"TEMPERATURE UNITS","t":"r","opts":HZ_TEMP_NAMES}];
      }
      private function hz51Scan(id:String) : Array
      {
         var scanOn:Boolean = this.hz30Mod["scanner"] === 1;
         var commsOn:Boolean = this.hz30Mod["comms"] === 1;
         if(id == "pop")
         {
            var pop:Array = this.hz40PopupRows();
            var i:int = 0;
            while(i < pop.length) { if(String(pop[i].k) == "HideQuestPopupsWhileScanning") { pop[i].h = "POPUPS"; } i++; }
            return pop;
         }
         if(!scanOn)
         {
            if(id == "ap" || id == "hud" || id == "tl" || id == "sig" || id == "sv" || id == "ov")
            {
               return this.hz51Unavail([{"k":"_scanmiss","l":"SCANNER","t":"b","dis":true,"dv":false,"h":"SCANNER"}], "Install it from the Horizon UI installer.");
            }
         }
         var src:Array = this.hz40ScanRows();
         var m:Object = this.hz51ByKey(src);
         var keys:Array = [];
         if(id == "ov") { keys = ["_hz41arrscan","ScanCompactAll","ScanHighlightArea","ScanReach","_hz40rstlay","_hz40rstall"]; }
         else if(id == "hud") { keys = ["HideMainHudWhileScanning","ScanShowVitalsHealth","ScanShowVitalsO2","ScanShowVitalsBoost","ScanVitalsCompact","ScanVitalsLayout","HideWatchWhileScanning"]; }
         else if(id == "tl") { keys = ["ScanShowMode","ScanModeScale","ScanShowHints","ScanHintsScale","ScanHighlightArea","ScanOutlineThickness"]; }
         else if(id == "sig") { keys = ["ScanShowSignals","ScanSignalsScale","ScanSignalsCompact","ScanMaxSignals","ScanShowShip","ScanNearestUnscanned","ScanShowCompass","ScanCompassScale","ScanCompassCompact","ScanShowWorldTags","ScanWorldTagScale","ScanWorldMarkers"]; }
         else if(id == "sv") { keys = ["ScanShowPlanet","ScanPlanetScale","ScanPlanetCompact","ScanShowBodyType","ScanHazardWarn","ScanHazardCrit","ScanShowBioscan","ScanBioscanScale","ScanBioscanCompact","ScanHideBioscanDone","ScanCompleteFlash","ScanLeftToFind","ScanShowTraits","ScanTraitsScale","ScanTraitsCompact","ScanMinRarity"]; }
         else { keys = ["ScanOpacity","ScanAccIdx","ScanTextCase","ScanFont","ScanMargin","ScanUnits"]; }
         var rows:Array = this.hz51Pick(src, keys);
         if(id == "ov" && m["_hz30m_scanner"] != undefined) { rows.unshift(this.hz51Copy(m["_hz30m_scanner"])); }
         if(id == "ap") { rows.push(this.hz51Goto("_goto_temp","TEMPERATURE UNITS",1,5,"TempUnit","SHORTCUT")); }
         return rows;
      }
      private function hz51Comms(id:String) : Array
      {
         var on:Boolean = this.hz30Mod["comms"] === 1;
         if(id == "mst")
         {
            var alerts:Array = [{"k":"MissionToast","l":"MISSION TOAST","t":"b","h":"MISSION TOASTS"},
               {"k":"MissionToastScale","l":"SIZE","t":"z","sub":true},
               {"k":"MissionToastTime","l":"SECONDS ON SCREEN","t":"n","mn":2,"mx":15,"st":1,"sub":true},
               {"k":"MissionToastMax","l":"MAX STACKED","t":"n","mn":1,"mx":5,"st":1,"sub":true},
               {"k":"MissionToastSound","l":"GAME QUEST SOUND","t":"b","dis":true,"dv":true},
               {"k":"ReactionCard","l":"COMPANION REACTION CARD","t":"b","h":"REACTIONS"},
               {"k":"GameCardTitle","l":"NOTICE LABEL","t":"r","opts":["NONE","DATA","MISC"],"ids":[0,1,2]}];
            if(!on) { return this.hz51Unavail(alerts, "Install it from the Horizon UI installer. Saved settings are kept."); }
            return alerts;
         }
         if(!on)
         {
            return this.hz51Unavail([{"k":"Subtitles","l":"HORIZON SUBTITLES","t":"b","h":"SUBTITLES"}], "Install it from the Horizon UI installer. Saved settings are kept.");
         }
         var saved:int = this.hz31Page;
         this.hz31Page = id == "dlg" ? 1 : 0;
         var full:Array = this.hz31CommsRows();
         this.hz31Page = saved;
         var skip:Object = {"_hz30m_comms":1,"_hz31page":1,"MissionToast":1,"MissionToastTime":1,"MissionToastMax":1,"MissionToastScale":1,"MissionToastSound":1,"ReactionCard":1,"GameCardTitle":1,"_hz40goscan":1};
         var rows:Array = [];
         var i:int = 0;
         while(i < full.length)
         {
            var k:String = String(full[i].k);
            if(skip[k] == 1) { i++; continue; }
            if(id == "cmp")
            {
               if(k == "_hz31usesub" || k == "_hz31usedlg") { rows.push(this.hz51Copy(full[i])); }
            }
            else if(id == "sub")
            {
               if(k == "_hz31usesub") { i++; continue; }
               if(k.indexOf("Dlg") == 0 || k == "Dialogue") { i++; continue; }
               rows.push(this.hz51Copy(full[i]));
            }
            else
            {
               if(k == "_hz31usedlg") { i++; continue; }
               if(k == "Subtitles" || k.indexOf("Sub") == 0 || k == "ShowSpeaker" || k == "SpkColIdx" || k == "TxtColIdx" || k == "KeepInDialogue" || k == "FixedInDialogue") { i++; continue; }
               rows.push(this.hz51Copy(full[i]));
            }
            i++;
         }
         if(id == "cmp" && rows.length == 0)
         {
            rows.push({"k":"_cmpok","l":"NO CONFLICT","t":"x","btn":"OK","dis":true,"dv":true,"h":"COMPATIBILITY","note":"Horizon is drawing its own subtitles and dialogue."});
         }
         return rows;
      }
      private function hz51System(id:String) : Array
      {
         if(id == "pr")
         {
            var pr:Array = this.hz37Rows();
            var keep:Array = [];
            var i:int = 0;
            while(i < pr.length)
            {
               var k:String = String(pr[i].k);
               if(k == "_hz37bak") { i++; continue; }
               keep.push(pr[i]);
               i++;
            }
            return keep;
         }
         if(id == "mod") { return this.hz51Modules(); }
         if(id == "ml") { return this.hz51Msglog(); }
         if(id == "ctl")
         {
            return [{"k":"SettingsKey","l":"SETTINGS MENU KEY","t":"c","h":"CONTROLS"},
               {"k":"SettingsOpacity","l":"SETTINGS WINDOW %","t":"n","mn":30,"mx":100,"st":1,"pct":1,"h":"WINDOW"},
               {"k":"StartupIntro","l":"WELCOME INTRO","t":"b","h":"WELCOME","note":"Plays HORIZON UI on save load","n13":true}];
         }
         if(id == "bak")
         {
            var bak:Array = [];
            var src:Array = this.hz37Rows();
            var j:int = 0;
            while(j < src.length) { if(String(src[j].k) == "_hz37bak") { bak.push(src[j]); } j++; }
            bak.push({"k":"_hz40rstlay","l":"RESET SCANNER LAYOUT","t":"x","btn":"RESET","h":"SCOPED RESETS"});
            bak.push({"k":"_hz40rstall","l":"RESET ALL SCANNER SETTINGS","t":"x","btn":"RESET"});
            bak.push({"k":"_hz42scrst","l":"RESET SCOPE CHIP","t":"x","btn":"RESET"});
            return bak;
         }
         return [{"k":"Debug","l":"DEBUG OVERLAY","t":"b","h":"DEBUG"},
            {"k":"PerfDiag","l":"ADVANCED PERFORMANCE TIMING","t":"b","h":"PERFORMANCE"},
            {"k":"PerfMode","l":"PERF MODE","t":"r","opts":HZ51_PERF_NAMES,"ids":[0,1,2,3,4,5,6,7]},
            {"k":"PerfDump","l":"ARM PERF DUMP","t":"b"},
            {"k":"_diagoff","l":"LEAVE THESE OFF","t":"x","btn":"KEEP OFF","h":"NOTE","dis":true,"dv":true}];
      }
      private function hz51Modules() : Array
      {
         var list:Array = [
            {"id":"core","l":"CORE HUD"},
            {"id":"font","l":"HORIZON FONT"},
            {"id":"quickmenu","l":"QUICK MENU"},
            {"id":"comms","l":"COMMS AND DIALOGUE"},
            {"id":"scanner","l":"SCANNER"},
            {"id":"scope","l":"SCOPE"},
            {"id":"msglog","l":"MESSAGE LOG"}
         ];
         var rows:Array = [];
         var i:int = 0;
         while(i < list.length)
         {
            var st:Object = this.hz51ModState(String(list[i].id));
            var badge:String = !st.inst ? "NOT INSTALLED" : (st.paused ? "PAUSED" : (st.on ? "ENABLED" : "DISABLED"));
            var r:Object = {"k":"_mod_" + list[i].id,"l":String(list[i].l),"t":"md","badge":badge,"h": i == 0 ? "MODULES" : "","modid":list[i].id};
            if(!st.inst) { r.note = st.why; r.n13 = true; r.dis = true; r.dv = 0; }
            else if(st.paused) { r.note = String(st.why) + (st.act.length > 0 ? " " + st.act : ""); r.n13 = true; }
            rows.push(r);
            i++;
         }
         return rows;
      }
      private function hz51Msglog() : Array
      {
         var rows:Array = [{"k":"Record","l":"RECORD MESSAGES","t":"b","h":"MESSAGE LOG"},
            {"k":"Persist","l":"SAVE TO DISK","t":"b"},
            {"k":"HistorySize","l":"HISTORY LENGTH","t":"n","mn":100,"mx":1000,"st":100},
            {"k":"_mlfolder","l":"FOLDER","t":"x","btn":"SHOW"},
            {"k":"_mlold","l":"OLD CHARACTERS","t":"x","btn":"OPEN"},
            {"k":"_msglog","l":"OPEN LOG","t":"x","btn":"OPEN"}];
         if(this.hzMsglogModule() == 0) { return this.hz51Unavail(rows, "Install it from the Horizon UI installer. Saved settings are kept."); }
         return rows;
      }
      private function hz51IndexBuild() : void
      {
         var idx:Array = [];
         var tab:int = 0;
         var savedPage:int = this.hzSetPage;
         while(tab < HZ_SET_TABS.length)
         {
            var pages:Array = this.hz51Pages(tab);
            var p:int = 0;
            while(p < pages.length)
            {
               var rows:Array = this.hz51Rows(tab, p);
               var r:int = 0;
               while(r < rows.length)
               {
                  var row:Object = rows[r];
                  if(row == null || row.pill || row.t == "m" || row.t == "g" || row.t == "w") { r++; continue; }
                  var lab:String = String(row.l != undefined ? row.l : "");
                  if(lab.length == 0) { r++; continue; }
                  var help:String = this.hz51HelpOf(String(row.k), row);
                  var hay:String = (lab + " " + help + " " + this.hz51Crumb(tab, p)).toLowerCase();
                  idx.push({"k":String(row.k),"l":lab,"tab":tab,"page":p,"row":r,"crumb":this.hz51Crumb(tab, p),"hay":hay});
                  r++;
               }
               p++;
            }
            tab++;
         }
         this.hzSetPage = savedPage;
         this.hzSetIdx = idx;
      }
      private function hz51FindHits() : Array
      {
         var q:String = this.hzSetFind.toLowerCase();
         var out:Array = [];
         if(this.hzSetIdx == null || q.length == 0) { return out; }
         var i:int = 0;
         while(i < this.hzSetIdx.length)
         {
            if(String(this.hzSetIdx[i].hay).indexOf(q) >= 0) { out.push(this.hzSetIdx[i]); }
            i++;
         }
         return out;
      }
      private function hz51GotoHit(h:Object) : void
      {
         if(h == null) { return; }
         this.hzSetFindOn = false;
         this.hzSetTab = int(h.tab);
         this.hzSetPage = int(h.page);
         this.hzSetGlowK = String(h.k);
         this.hzSetGlowT = new Date().getTime() + 1800;
         var rows:Array = this.hzSetRows(this.hzSetTab);
         var i:int = 0;
         while(i < rows.length)
         {
            if(String(rows[i].k) == String(h.k)) { this.hzSetRow = i; break; }
            i++;
         }
         this.hzSetScroll = 0;
         this.hzSetFollow(rows);
      }
      private function hz51Jump(tab:int, page:int, key:String) : void
      {
         this.hzSetTab = tab;
         this.hzSetPage = page;
         this.hzSetRow = 0;
         this.hzSetScroll = 0;
         this.hzSetDrop = -1;
         if(key != null && key.length > 0)
         {
            var rows:Array = this.hzSetRows(tab);
            var i:int = 0;
            while(i < rows.length) { if(String(rows[i].k) == key) { this.hzSetRow = i; break; } i++; }
            this.hzSetGlowK = key;
            this.hzSetGlowT = new Date().getTime() + 1800;
            this.hzSetFollow(rows);
         }
      }
      private function hz51DropOpts(r:Object) : Array
      {
         if(r == null) { return []; }
         if(r.t == "r" || r.t == "l") { return r.opts != undefined ? r.opts as Array : (r.names as Array); }
         if(r.t == "q")
         {
            var ids:Array = r.ids as Array;
            var o:Array = [];
            var i:int = 0;
            while(ids != null && i < ids.length)
            {
               var id:int = int(ids[i]);
               o.push(String(HZ_RULE_NAMES[Math.max(0,Math.min(HZ_RULE_NAMES.length - 1,id))]));
               i++;
            }
            if(r.opts != undefined) { return r.opts as Array; }
            return o;
         }
         if(r.t == "a") { return r.names as Array; }
         if(r.t == "c") { return HZ_SET_KEYS; }
         return [];
      }
      private function hz51DropPick(r:Object, idx:int) : void
      {
         if(r == null || this.hzSetPend == null) { return; }
         var k:String = String(r.k);
         if(r.t == "r" && r.ids != undefined) { this.hzSetPend[k] = int((r.ids as Array)[idx]); }
         else if(r.t == "r") { this.hzSetPend[k] = idx; }
         else if(r.t == "q") { this.hzSetPend[k] = int((r.ids as Array)[idx]); }
         else if(r.t == "l") { this.hzSetPend[k] = (r.vals as Array)[idx]; }
         else if(r.t == "a") { this.hzSetPend[k] = idx; }
         else if(r.t == "c") { this.hzSetPend[k] = HZ_SET_KEYS[idx]; }
         this.hzSetLive(this.hzSetPend);
      }
      private function hz51HexCommit() : void
      {
         if(this.hzSetHexK.length == 0 || this.hzSetPend == null) { return; }
         var n:int = this.hzParseHex(this.hzSetHexBuf);
         if(n < 0)
         {
            this.hzSetHexBuf = this.hzSetHexPrev >= 0 ? this.hzHex(this.hzSetHexPrev).substr(1) : this.hzSetHexBuf;
            return;
         }
         this.hzSetPend[this.hzSetHexK] = this.hzHex(n);
         if(this.hzSetHexK == "AccentHex") { this.hzAccentHex = n; this.hzSetPend.AccentColor = this.hzAccPal().length - 1; }
         else if(this.hzSetHexK == "CardHex") { this.hzCardHex = n; this.hzSetPend.CardColor = this.hzCardPal().length - 1; }
         else if(this.hzSetHexK == "ScanAccentHex") { this.hzSetPend.ScanAccIdx = this.hz40AccPal().length - 1; }
         this.hzSetLive(this.hzSetPend);
      }
      private function hz51QmClear() : void
      {
         if(this.hzSetPend == null) { return; }
         var n:int = 13;
         while(n <= 24) { this.hzSetPend["QuickMenuKey" + n] = ""; n++; }
         this.hzSetLive(this.hzSetPend);
      }
