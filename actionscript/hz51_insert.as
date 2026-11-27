      // ===================== Settings 2.0 (F11 rebuild) =====================
      // Purpose: five-tab settings shell (CARDS / APPEARANCE / SCANNER / COMMS / SYSTEM)
      // with one shared sidebar, table-boxed rows, dropdowns, header search, and live
      // Diagnostics. Runs only while F11 is open: the search index is built on open
      // and dropped on close. No HUD-frame polling. Author: Moragar. Last modified: 2026-11-27.
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
      private var hz51Pad:Boolean = false;        // last F11 input was gamepad (hzpad / D-pad / A/B / LB/RB / stick); mouse/letters clear it
      private var hzSetDropBox:Object = null;     // last drawn dropdown control {x,y,w,h} for menu anchoring
      private var hzSetDropMenu:Object = null;    // open menu rect {x,y,w,h}; clicks inside never fall through
      private var hzSetDropScroll:int = 0;        // first visible option when the menu is taller than the gap
      private var hzSetDropVis:int = 0;           // how many options the open menu can show
      private var hzSetOver:Sprite = null;        // dropdown / find layer above row text (body.graphics sits behind children)
      private var hz51FbSeen:Object = null;       // tag:page already logged this F11 open (hz51Rows runs every draw)
      private var hz51FbDbg:String = "";          // Debug Overlay lines so a fallback never looks like success
      private var hz51OpenFolder:String = "";     // one-shot folder request for the DLL (Message Log SHOW)
      private var hzSetWinMask:Sprite = null;     // rounded clip for the settings window body
      // Compact shell: old F11 was 1000x660. Height stays 726. Width 1260 gives the
      // header, extended key grid, and right-aligned controls room without covering
      // HUD side cards at 1080p or 1440p (hz51Fit never grows past this cap).
      // Style (filled 1px bars, accent, Exo 2) matches the mockup; type and rows are scaled to fit.
      private static const HZ51_WIN_W:Number = 1260;    // width cap; height stays 726
      private static const HZ51_ROW:Number = 48;        // scaled from mockup 58
      private static const HZ51_HEAD:Number = 52;       // scaled from mockup 62
      private static const HZ51_TABS:Number = 38;       // scaled from mockup 46
      private static const HZ51_SIDE_W:Number = 248;    // one-line labels at 11px; slimming further does not shrink the window
      private static const HZ51_PREV_W:Number = 196;    // scaled from mockup 292
      private static const HZ51_FOOT:Number = 46;       // one hint row
      private static const HZ51_SEC:Number = 36;        // section title + rule + gap before the first row
      private static const HZ51_FIND_W:Number = 176;    // header search slot
      private static const HZ51_FIND_H:Number = 30;     // header control height
      private static const HZ51_DD_H:Number = 28;       // dropdown box height
      private static const HZ51_CTRL_W:Number = 148;    // dropdown / button min width; all controls share right edge R
      private static const HZ51_SW_W:Number = 42;       // mock toggle track
      private static const HZ51_SW_H:Number = 22;
      private static const HZ51_BTN_H:Number = 22;      // OPEN / RESET / SHOW on 48px rows
      private static const HZ51_INFO_R:Number = 6;      // 12px (i) disc, smaller than the old 16px
      private static const HZ51_PVC_H:Number = 120;     // live preview card
      private static const HZ51_WIN_R:Number = 10;
      private static const HZ51_BOX_R:Number = 6;
      private static const HZ51_DROP_ITEM:Number = 24;  // one option row in an open menu
      private static const HZ51_TITLE_PX:Number = 12;
      private static const HZ51_HELP_PX:Number = 11;
      private static const HZ51_SH_PX:Number = 10;
      private static const HZ51_DIV_A:Number = 0.08;    // .row border-bottom txt 8%
      private static const HZ51_BOX_A:Number = 0.18;    // .box border acc 18%
      private static const HZ51_SH_A:Number = 0.28;     // .sh:after acc 28%
      private static const HZ51_SEL_A:Number = 0.10;    // .row.sel acc 10%
      private static const HZ51_WIN_EA:Number = 0.28;   // .win border acc 28%
      private static const HZ51_QM_TH:Number = 84;      // tile tall enough for SLOT n + Empty + clipped chip
      private static const HZ51_QM_HEAD:Number = 36;    // one-line hint + CLEAR ALL KEYS
      private static const HZ51_QM_LOCK:Number = 24;
      private static const HZ51_QM_GAP:Number = 8;
      private static const HZ51_QM_WARN:Number = 44;
      private static const HZ51_QM_CLASH:uint = 0xF2A03A;
      private static const HZ51_MOD_GAP:Number = 10;    // space under a module banner / between module cards
      private static const HZ51_PERF_NAMES:Array = ["BASELINE","HOVER SKIP","FIXTURE","FULL PIPELINE","SAME TARGET","RAPID TARGETS","SCANNER","BACKGROUND HUD"];

      // Purpose: size the F11 window. Height stays 726. Width caps at 1260 so HUD
      // side cards stay visible at 1080p (330px each side) and 1440p. Never grow
      // past the cap; shrinks on a 720p HUD so the window still fits. Called on
      // open and on each draw while F11 is open.
      // Inputs: Extensions.visibleRect. Outputs: HZ_SET_W / HZ_SET_H.
      private function hz51Fit() : void
      {
         var W:Number = HZ51_WIN_W;
         var H:Number = 726;
         try
         {
            var vr:Rectangle = Extensions.visibleRect;
            if(vr != null && this.stage != null)
            {
               var tl:Point = this.globalToLocal(new Point(vr.left, vr.top));
               var br:Point = this.globalToLocal(new Point(vr.right, vr.bottom));
               var vw:Number = br.x - tl.x;
               var vh:Number = br.y - tl.y;
               if(vw >= 400 && vh >= 300)
               {
                  W = Math.round(Math.max(1000, Math.min(HZ51_WIN_W, vw - 80)));
                  H = Math.round(Math.max(560, Math.min(726, vh - 80)));
               }
            }
         }
         catch(eFit:Error) { }
         this.HZ_SET_W = W;
         this.HZ_SET_H = H;
      }
      // Purpose: 1px stroke as four filled bars, each its own beginFill/endFill,
      // strictly inside [x,y,w,h]. Scaleform even-odd (outer roundRect minus inner)
      // joined the two subpaths with a diagonal and filled a teal wedge from the
      // control, past the row and scrollbar, into the preview. r is kept so call
      // sites stay the same; corners stay sharp. Never lineStyle.
      // Inputs: graphics, box, color, alpha, unused radius. Outputs: 1px frame.
      private function hz51Stroke(g:*, x:Number, y:Number, w:Number, h:Number, col:uint, a:Number, r:Number = 0) : void
      {
         x = Math.round(x); y = Math.round(y); w = Math.round(w); h = Math.round(h);
         if(g == null || w < 2 || h < 2 || a <= 0) { return; }
         g.beginFill(col, a);
         g.drawRect(x, y, w, 1);
         g.endFill();
         g.beginFill(col, a);
         g.drawRect(x, y + h - 1, w, 1);
         g.endFill();
         if(h > 2)
         {
            g.beginFill(col, a);
            g.drawRect(x, y + 1, 1, h - 2);
            g.endFill();
            g.beginFill(col, a);
            g.drawRect(x + w - 1, y + 1, 1, h - 2);
            g.endFill();
         }
      }
      // Purpose: Settings 2.0 text at the intended pixel size. hzWT floors at 13px
      // unless minPx is passed, which made 11–12px labels jump and overlap.
      private function hz51T(b:Sprite, txt:String, x:Number, y:Number, w:Number, fs:Number, face:String, col:uint, ls:Number = 0, align:String = "left") : TextField
      {
         return this.hzWT(b, txt, x, y, w, fs, face, col, ls, align, int(Math.round(fs)));
      }
      // Purpose: whole-pixel filled hairline (row divider, section rule, column rule).
      private function hz51Hair(g:*, x:Number, y:Number, w:Number, h:Number, col:uint, a:Number) : void
      {
         if(g == null || a <= 0) { return; }
         g.beginFill(col, a);
         g.drawRect(Math.round(x), Math.round(y), Math.max(1, Math.round(w)), Math.max(1, Math.round(h)));
         g.endFill();
      }
      // Purpose: place a dropdown flush with its box (same left and right edges).
      // Prefer 4px below; flip above if the leftover below is smaller. Height is
      // clipped to the leftover so a 15-item list near the bottom stays inside
      // the window; the draw path then scrolls. Never right-aligns to a wider menu.
      // Inputs: control rect, requested menu size, window. Outputs: {x,y,w,h,vis}.
      private function hz51DropRect(ctrlX:Number, ctrlY:Number, ctrlW:Number, ctrlH:Number, menuW:Number, menuH:Number, winW:Number, winH:Number, foot:Number, top:Number) : Object
      {
         var w:Number = Math.round(ctrlW > 8 ? ctrlW : menuW);
         var x:Number = Math.round(ctrlX);
         if(x < 8) { x = 8; }
         if(x + w > winW - 8) { x = Math.round(Math.max(8, winW - 8 - w)); }
         var gap:Number = 4;
         var maxY:Number = winH - foot - 4;
         var below:Number = maxY - (ctrlY + ctrlH + gap);
         var above:Number = ctrlY - gap - top;
         var need:Number = Math.max(HZ51_DROP_ITEM + 8, menuH);
         var y:Number;
         var h:Number;
         if(below >= Math.min(need, 3 * HZ51_DROP_ITEM + 8) || below >= above)
         {
            y = Math.round(ctrlY + ctrlH + gap);
            h = Math.round(Math.max(HZ51_DROP_ITEM + 8, Math.min(need, Math.max(HZ51_DROP_ITEM + 8, below))));
         }
         else
         {
            h = Math.round(Math.max(HZ51_DROP_ITEM + 8, Math.min(need, Math.max(HZ51_DROP_ITEM + 8, above))));
            y = Math.round(ctrlY - gap - h);
            if(y < top) { y = Math.round(top); h = Math.round(Math.max(HZ51_DROP_ITEM + 8, ctrlY - gap - y)); }
         }
         var vis:int = Math.max(1, int(Math.floor((h - 8) / HZ51_DROP_ITEM)));
         return {"x":x,"y":y,"w":w,"h":h,"vis":vis};
      }
      // Purpose: header compact / search / arrange as three fixed slots from the
      // right, never overlapping the title cluster. Laid out from constants (not
      // per-frame text measurement). Outputs: pixel rects for each control.
      private function hz51HeadSlots() : Object
      {
         var W:Number = this.HZ_SET_W;
         var fy:Number = Math.round((HZ51_HEAD - HZ51_FIND_H) / 2);
         var h:Number = HZ51_FIND_H;
         var gap:Number = 8;
         var titleR:Number = 340;
         var arrW:Number = this.hzSetTab == 4 ? 0 : (this.hzSetTab == 2 ? 150 : 132);
         var ax:Number = W - 16 - arrW;
         var findW:Number = HZ51_FIND_W;
         var fx:Number = ax - (arrW > 0 ? gap : 0) - findW;
         var compactW:Number = 268;         // COMPACT MODE (STRIPS) + ON/OFF word + 42px switch
         var cx:Number = fx - gap - compactW;
         if(cx < titleR)
         {
            compactW = Math.max(128, fx - gap - titleR);
            cx = fx - gap - compactW;
         }
         if(cx < titleR) { cx = titleR; compactW = Math.max(96, fx - gap - cx); }
         return {"titleR":titleR,"cx":cx,"cw":compactW,"fx":fx,"findW":findW,"ax":ax,"arrW":arrW,"fy":fy,"h":h,"W":W,"gap":gap};
      }
      // Purpose: one typed character from QueueKey. Letters arrive as the pair
      // ch:v then bind:V (FlushInputToHud calls hzSettingsKey for each). Find and
      // hex append only ch:; bind: is capture-only and must not type a second char.
      private function hz51TypeChar(code:String) : String
      {
         if(code == null) { return ""; }
         if(code.indexOf("ch:") == 0 && code.length >= 4) { return code.substr(3, 1); }
         return "";
      }
      private function hz51NotePad(code:String) : void
      {
         if(code == "hzpad" || code == "padx" || code == "pady" || code == "tabprev" || code == "tabnext") { this.hz51Pad = true; }
         else if(this.hzVehPad == 1 && (code == "up" || code == "down" || code == "left" || code == "right" || code == "ok" || code == "cancel")) { this.hz51Pad = true; }
         else if(this.hz51TypeChar(code).length > 0) { this.hz51Pad = false; }
      }

      private function hz51Side(tab:int) : Array
      {
         if(tab == 0) { return [{"g":"HUD CARDS","items":[{"id":"gen","l":"GENERAL","s":"Compact strips size · HUD scale · Margin"},{"id":"sta","l":"STATUS","s":"Vitals · Jetpack · Afflictions · Hazard Status"},{"id":"com","l":"COMBAT","s":"Equipment · Enemy Health · Stealth · Scope"},{"id":"nav","l":"NAVIGATION","s":"Compass · Quest Tracker · Planet"},{"id":"chr","l":"CHARACTER & WATCH","s":"Character · Watch"}]},{"g":"WORLD","items":[{"id":"int","l":"INTERACTION","s":"Target & Hover · Container · Vehicle Exit"}]},{"g":"MENUS & ALERTS","items":[{"id":"qm","l":"QUICK MENU / FAVORITES MENU","s":"Horizon style · Extended slots"},{"id":"ntf","l":"NOTIFICATIONS","s":"XP toast"}]}]; }
         if(tab == 1) { return [{"g":"LOOK","items":[{"id":"col","l":"COLORS","s":"Accent · Card background"},{"id":"pan","l":"PANELS","s":"Opacity · Background % · Shadow"},{"id":"typ","l":"TYPOGRAPHY","s":"Font · Size · Tone"}]},{"g":"PLACE","items":[{"id":"siz","l":"SIZE & PLACEMENT","s":"HUD scale · Margin · Pixel snap"}]},{"g":"MOTION","items":[{"id":"mot","l":"MOTION & FADING","s":"Smooth bars · Fade · Combat dim"}]},{"g":"CLOCKS","items":[{"id":"clk","l":"CLOCKS & UNITS","s":"Planet time · 12/24 · Temperature"}]}]; }
         if(tab == 2) { return [{"g":"SCANNER","items":[{"id":"ov","l":"OVERVIEW","s":"Module · Layout · Reach"},{"id":"hud","l":"HUD","s":"What stays while you scan"},{"id":"tl","l":"TOOLS","s":"Mode pill · Hints · Outlines"}]},{"g":"FINDINGS","items":[{"id":"sig","l":"SIGNALS","s":"Signals · Compass · World tags"},{"id":"sv","l":"SURVEY","s":"Planet · Bioscan · Traits"}]},{"g":"LOOK","items":[{"id":"pop","l":"POPUPS","s":"Quest and trait popups"},{"id":"ap","l":"APPEARANCE","s":"Colors · Font · Distance"}]}]; }
         if(tab == 3) { return [{"g":"CONVERSATION","items":[{"id":"sub","l":"SUBTITLES","s":"Lines · Size · Card"},{"id":"spk","l":"SPEAKER","s":"Name · Color · Card"},{"id":"dly","l":"DIALOGUE LAYOUT","s":"List · Size · Offset"},{"id":"dlap","l":"DIALOGUE APPEARANCE","s":"Font · Colors · Panel"},{"id":"prs","l":"CHOICES & PERSUASION","s":"Already-said · Tags · Meter"},{"id":"inp","l":"INPUT & HINTS","s":"Keys · Wheel · Bar"}]},{"g":"ALERTS","items":[{"id":"mst","l":"MISSION TOASTS & REACTIONS","s":"Quest banner and companion lines"}]},{"g":"MODULE","items":[{"id":"cmp","l":"COMPATIBILITY","s":"Auto-pause · Conflicts · Use Horizon"}]}]; }
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
      private function hz51PageIndex(tab:int, id:String) : int
      {
         var p:Array = this.hz51Pages(tab);
         var i:int = 0;
         while(i < p.length) { if(String(p[i].id) == id) { return i; } i++; }
         return 0;
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
         if(r == null) { return o; }
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
            case "_qmkeys": return "Click a key chip to bind. Esc cancels. Backspace or Delete clears. A clash (another slot, the settings key, or a game control) is warned and ignored. Tiles are slots 13 through Slot Count, wrapped by Slots per Row. Slots 1-12 keep the game's own favorite keys. If Extended Mode is off or paused, the grid is grayed and saved keys are kept.";
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
            case "AmmoRule": return "Drawn follows a weapon reticle (rifle, pistol, shotgun, laser, cutter). The HUD crosshair can be off.";
            case "EquipmentExtras": return "Shows grenade count and the selected Starborn power on the equipment card. Off hides those extras and also hides the game's leftover grenade and power clips so no stray line stays on the HUD.";
            case "EnemyBar": return "Enemy health at the top center. Turns off the game's own enemy bar while this is on.";
            case "StealthMeter": return "A stealth pill above the crosshair while you sneak. Turns off the game's own stealth meter while this is on.";
            case "CrosshairRule": return "When the center aiming reticle shows. Always is the default. When weapon drawn shows it only with a weapon out. Off hides the reticle only; prompts, target cards, hit markers, the kill X, the damage ring, and the stealth pill stay.";
            case "CrosshairStyle": return "Look of the reticle while you look at something you can use: the game's ring, a Horizon dot, a Horizon cross, or none.";
            case "HitMarkers": return "A hit mark and a kill X at the crosshair. Turns off the game's own markers while this is on.";
            case "DamageNumbers": return "Floating damage numbers. Turns off the game's own numbers while this is on.";
            case "DirectionRing": return "A ring around the crosshair that shows where damage came from. Turns off the game's own arcs while this is on.";
            case "ScopeHoldBreathChip": return "While you aim down a scope, the hold-breath prompt is a Horizon chip with an oxygen meter. Off uses the game's own prompt. Needs the Scope module. If Scope is not installed, this row stays locked and the game's prompt is used. Saved preference is kept.";
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
            case "ShowCharacter": return "Turns the character card (level, XP, credits, mass) on or off. When it is on, Show when still decides the moments it appears. Off hides the card completely, including after XP or a level up.";
            case "CharacterRule": return "When the character card appears. Event choices show it for a few seconds after XP, a level up, credits, or a skill point, and can also show when you are overweight.";
            case "CharacterShowSeconds": return "How many seconds the character card stays up after an event. This is used only when Show when is an event choice. It does nothing when Show when is Always.";
            case "WatchStyle": return "Wrist watch in the lower left. Off hides it. Vanilla is the game's watch. Vanilla + Horizon keeps the game's watch and paints it with Horizon colors. Horizon digital is a number readout. Horizon analog is a clock face. Use Off if you never look at it. Use Horizon digital if you want a clear time at a glance.";
            case "ShowTarget": return "Horizon's card for the activate prompt and item hover (name, keys, value). Off uses the game's prompt exactly, including the game's name bar and key boxes. Turn this off if you want the original look. Turn it on for Horizon's target card.";
            case "NameHover": return "Compact is one line: icon, name, and key. Full is the taller card.";
            case "HoverScale": return "Size of activate prompts, loose-item cards, compare cards, and enemy tags.";
            case "TargetAnchor": return "Where hover cards sit. Crosshair keeps them by the reticle. Follow target sits them next to the object on screen.";
            case "TargetShowValue": return "Shows value and weight on the item hover card and on the selected container row.";
            case "ContainerScale": return "Size of the full container item list.";
            case "ContainerOpacity": return "How solid the container list and crosshair item cards are. This is separate from HUD card opacity.";
            case "ObjectRing": return "The ring and line the game draws around the object you look at. Off never shows it. Containers only shows it on a container list. Vanilla is the game's own drawing.";
            case "VehicleExitPill": return "While you are in a vehicle, the hold-to-exit prompt is a Horizon pill. Off uses the game's prompt. Move it in Arrange Cards.";
            case "QuickMenuHorizon": return "The game's quick menu (favorites cross) as Horizon cards in your colors and font. Off is the game's look. This switch is the enable. Turn it on if you want the Horizon favorites menu. Turn it off to keep the original cross. Extended Mode stays muted until this is on.";
            case "QuickMenuExtended": return "Off is the game's 12-slot T. On is up to 24 slots. Paused if another favorites add-on is installed; saved On/Off is kept. Slots 1-12 still use the game's own favorite keys. Turn this on after Horizon Style if you want extra slots and key chips.";
            case "QuickMenuSlotCount": return "How many slots show when Extended Mode is on, 12-24. The key grid shows slots 13 through this number. Default 24. Lowering the count only hides extra tiles; keys and items are kept.";
            case "QuickMenuSlotsPerRow": return "4, 6, or 8. Default 6. The key grid wraps to this many tiles per row. Use 4 on a small screen, 8 if you want fewer rows to scroll.";
            case "QuickMenuExtendedLayout": return "Cross + Bars keeps the vanilla T for slots 1-12 and puts Horizon slots in bars underneath. Bars draws every slot in rows. Use Cross + Bars if you still want the familiar T. Use Bars for a simple grid.";
            case "QuickMenuExtEmptySlots": return "SHOW = unused extras appear as empty squares with a faint plus. HIDE = leave them off until assigned. Occupied extras always show, and inventory assign still shows empties so you can pick one.";
            case "QuickMenuExtPanelOpacity": return "How solid the extra window is. It does not change other HUD cards. Applies the next time you open the Quick Menu.";
            case "QuickMenuExtSlotScale": return "Extra slot size compared with slots 1-12; 1.0 is the same size. Applies the next time you open the Quick Menu.";
            case "_qmclear": return "Clears every extra-slot key. The slots still work from the menu.";
            case "XpToast": return "A short +XP note beside the character card. With Horizon messages installed, the game's own +XP popup is hidden while this is on. Off keeps the game's popup (or none, if the game would not show one).";
            case "MissionToast": return "Replaces the game's quest banner with a Horizon toast. Move it in Arrange Cards.";
            case "MissionToastTime": return "How many seconds each mission toast stays on screen.";
            case "MissionToastMax": return "How many mission toasts may stack at once.";
            case "MissionToastScale": return "Size of the mission toast. Follow HUD uses the overall HUD size.";
            case "MissionToastSound": return "The quest sound comes from the game's banner and always plays. It cannot be turned off here.";
            case "ReactionCard": return "Restyles companion 'liked that' lines as a Horizon card. English game text only for now; other lines stay the game's.";
            case "GameCardTitle": return "Small label above the game's other notices. None shows just the message. Data or Misc adds that label. Applies from the next message.";
            case "AccentColor": return "Color of highlights, switches, selected rows, and this window. Pick a named color for a ready-made look, or Custom to mix your own. The whole settings screen follows this color as soon as you change it. Use a brighter accent if cards feel hard to see, or a calmer one for long play sessions.";
            case "AccentHex": return "Your own accent color as six digits (red, green, then blue). Type them after the hash. An incomplete or invalid color keeps the last good one. Use this when none of the named colors match what you want. This is not a file name and not a setting key — it is only the color.";
            case "CardColor": return "Fill color of HUD cards and this window. Pick a named color, or Custom to mix your own. Light fills switch the text to dark so labels stay readable. Use a dark fill for night scenes and a light fill if you want a paper look.";
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
            case "_mlfolder": return "Opens the Message Log folder in Explorer (the same folder the game writes when Save to disk is on). The path is shown in Setting Details after you press SHOW. The folder is not created if Save to disk has never been on. Use this to copy or back up log files.";
            case "_mlold": return "Opens the Message Log folder in Explorer so you can see log files from other characters. Each character is a separate file in that folder. Search and pins still live inside the in-game log window. This does not switch the character you are playing.";
            case "_msglog": return "Opens the in-game message log. Type filters, search, pins, and clear stay inside that window. This is not the disk folder — use Folder SHOW for Explorer.";
            case "ScanReach": return "Changes how far the scanner can outline and scan things. Vanilla leaves the game as it is. 2x, 3x, and 5x multiply that distance, never past 500 meters. A long reach can cost frame rate in busy areas. Applies the next time you open the scanner.";
            case "ScanHighlightArea": return "How far from the screen center the scanner picks up and outlines things. This does not change how far away you can scan (that is Scan reach). Small is about half the game's circle. Vanilla leaves the game's cone: Horizon writes nothing, so the game or another highlight-radius mod stays. Large reaches the top and bottom. Wide reaches the left and right. Full screen covers the corners too. Applies the next time you open the scanner.";
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
            case "_arrange": return "Drag HUD cards on screen. Save keeps the new spots. Arrange is always in the header, including while you search, so you can jump to layout without leaving the finder.";
            case "ScanShowSignals": return "Turns the scanner's nearby-signal list on or off. On shows what the scanner has found around you (flora, fauna, resources, and similar pings). Off hides that list so the scanner view is quieter. Saved preference is kept if the Scanner module is not installed.";
            case "ScanSignalsScale": return "Size of the signal list. Follow HUD uses the shared HUD scale. Custom sets a size just for this list. Use Custom when the list is hard to read or covers too much of the view.";
            case "ScanMaxSignals": return "How many signals the list may show at once. A lower number keeps the list short in busy areas. A higher number shows more finds before older ones drop off. This does not change how far the scanner can see.";
            case "ScanShowShip": return "Shows your ship and vehicle on the scanner so you can find them while you scan. Off hides those markers if you want a cleaner scan view.";
            case "ScanShowCompass": return "Shows a small compass while the scanner is open so you can keep your heading. Off hides it. The main HUD compass is a separate switch under Cards.";
            case "ScanCompassScale": return "Size of the scanner compass. Follow HUD uses the shared HUD scale. Custom is only for this compass.";
            case "ScanShowWorldTags": return "Shows place names on the scanner (settlements, outposts, and similar labels). Off hides those names so the view is only outlines and signals.";
            case "ScanSignalsCompact": return "Internal compact form for the signal list. Kept in the settings file; not shown here because Compact-all already covers it.";
            case "ScanCompassCompact": return "Internal compact form for the scanner compass. Kept in the settings file; not shown here because Compact-all already covers it.";
            case "ScanWorldTagScale": return "Internal size for place-name tags. Kept in the settings file; move scanner panels in Arrange Scanner instead.";
            case "ScanNearestUnscanned": return "Internal highlight for the nearest unscanned find. Kept in the settings file; not shown here.";
            case "ScanWorldMarkers": return "Internal world-marker drawing while you scan. Kept in the settings file; not shown here.";
            case "DlgSaidStyle": return "How dialogue options the game has already used are shown. Dimmed: they stay in the list, faded. Hidden: they leave the list (numbers 1-9 and the count only include what is still shown; if every option was said, all come back). Tagged: they stay, faded, with a SAID chip. Persuasion lists never hide options. Use Dimmed if you still want to pick an old line. Use Hidden for a shorter list. Use Tagged if you want a clear SAID mark.";
            case "DlgPersuadeStyle": return "How persuasion options are marked. Chip: a small tag beside the line. Colored text: the line itself uses the persuasion color. None: no extra mark (the game's own look). Use Chip if you want a quick scan of which lines are persuasion. Use Colored text if you dislike extra tags. Use None to stay close to the game.";
            case "DlgPersuadeColor": return "Color of the persuasion mark when the tag is a chip or colored text. Pick a named color so persuasion lines stand out from ordinary choices. Ignored when Persuasion tag is None.";
            case "DlgPersuasionMeter": return "On: Horizon draws the persuasion score, the highlighted reply, and remaining turns in place of the game's bars. Off: the game's own meter is used. Turn this on for a meter that matches Horizon dialogue. Turn it off if you prefer the original bars.";
            case "DlgMarkers": return "Experimental question and advance markers on dialogue options. This game version has no marker data, so the switch stays off and does nothing. Your saved choice is kept for a later game update.";
            case "SubAutoPause": return "When on, Horizon pauses its own subtitles if another subtitle add-on is installed, so the two do not overlap. This is the default. Turn it off (or press Use Horizon) only if you want Horizon's subtitles on top of that other add-on. Saved preference is kept.";
            case "DlgAutoPause": return "When on, Horizon pauses its own dialogue list if another dialogue add-on is installed, so the two do not overlap. This is the default. Turn it off (or press Use Horizon) only if you want Horizon's list from the next conversation. Saved preference is kept.";
            case "_hz31usesub": return "Horizon found another subtitle add-on (such as Enhanced Subtitles) and paused Horizon subtitles so the two do not overlap. Use Horizon turns auto-pause off (SubAutoPause=0) so Horizon's subtitles show again. This only works if Horizon's HUD messages file is the one installed.";
            case "_hz31usedlg": return "Horizon found another dialogue add-on (such as Enhanced Dialogue Interface) and paused Horizon's dialogue list. Use Horizon turns auto-pause off (DlgAutoPause=0). The change applies from the next conversation.";
            case "_ownsub": return "Whether Horizon is drawing subtitles right now. Active means Horizon's subtitles are on. Paused means another subtitle add-on was found and auto-pause is on.";
            case "_owndlg": return "Whether Horizon is drawing the dialogue list right now. Active means Horizon's list is on. Paused means another dialogue add-on was found and auto-pause is on.";
            case "_mod_core": return "Core HUD is always installed with Horizon. It draws the vitals, compass, quest tracker, and the other HUD cards. There is nothing to add or remove here.";
            case "_mod_font": return "The Horizon font pack (Exo 2 and friends). Installed: Horizon text uses the font you pick under Appearance. Not installed: the game font is used and your font choice is kept.";
            case "_mod_quickmenu": return "Quick Menu restyles the favorites cross and can add extra slots. Installed: the Quick Menu page is live. Not installed: the game's favorites menu is used. Installed - disabled: Horizon Style is off. Paused - conflict: another favorites add-on is in the way of Extended Mode.";
            case "_mod_comms": return "Comms and Dialogue restyles subtitles, the dialogue list, mission toasts, and companion reaction cards. Installed: those pages are live. Not installed: the game's own look is used and your saved choices are kept. Paused - conflict: another subtitle or dialogue add-on was found and auto-pause is on.";
            case "_mod_scanner": return "Scanner restyles the hand scanner. Installed: Scanner pages are live. Not installed: the game's scanner is used and your saved choices are kept.";
            case "_mod_scope": return "Scope restyles the hold-breath prompt while you aim down a scope. Installed: Combat > Scope is live. Not installed: the game's prompt is used and your saved choice is kept.";
            case "_mod_msglog": return "Notifications records HUD messages into the Message Log. Installed: Message Log pages are live. Not installed: nothing is written to disk from this menu.";
            case "_dirinst": return "Installed means the add-on's files are in this load order. Enabled means you turned that add-on's own switch on (for example Horizon Style). Visible means a card is allowed to appear by its Show when rule. A module can be installed and still look off because a switch or a Show when rule is hiding it.";
            case "_goto_showwhen": return "Opens Cards > Status so you can set when vitals and other cards appear. Show when is per card: Always, only in combat, only when not full, and similar rules.";
            case "_goto_mst": return "Opens Mission Toasts and Reaction Cards, which also need the Comms module.";
            default: return this.hz51HelpMore(k);
         }
      }
      // Purpose: extra Setting Details copy so every remaining key has what it does,
      // what each option means, and when to use it. Empty still falls through to the row note.
      private function hz51HelpMore(k:String) : String
      {
         if(k == "Subtitles") { return "Turns Horizon subtitles on or off. On draws spoken lines as a Horizon card. Off uses the game's subtitles (or another add-on's). Use On for Horizon's look. Use Off if you already have a subtitle add-on you prefer."; }
         if(k == "Dialogue") { return "Turns the Horizon dialogue list on or off. On draws replies as Horizon cards. Off uses the game's dialogue menu (or another add-on's). Applies from the next conversation."; }
         if(k == "ShowSpeaker") { return "Shows the speaker's name above the subtitle. Off is the line only. Use On in busy scenes so you know who is talking."; }
         if(k == "SpeakerCard") { return "Gives the speaker name its own small card in dialogue. Off draws the name as plain text. Use On to match other Horizon cards."; }
         if(k == "SubSize") { return "Size of subtitle text. About 1.00 is the usual size. Raise it if lines are hard to read. Lower it if the card covers too much of the scene."; }
         if(k == "SubWidth") { return "How wide the subtitle card is, as a percent of the screen. Wider wraps less often. Narrower keeps more of the scene visible."; }
         if(k == "SubCard") { return "On draws a panel behind the subtitle. Off is text only, with a soft dark outline. Use Off for a quieter picture. Use On for contrast on bright worlds."; }
         if(k == "DlgLayout") { return "Shape of the reply list. Card list is Horizon's stacked cards. Compact is a tighter stack. Classic centered is closer to the game's centered list. Use Compact on smaller screens."; }
         if(k == "DlgVisible") { return "How many replies show at once. All fits every option on the card. A number caps the list and can show an N more hint. Use a cap if a long list covers the speaker."; }
         if(k == "DlgButtonBar") { return "Key hints under the dialogue card. Horizon is a restyled strip. Game bar is the original. Hidden draws no strip (the keys still work). Use Hidden if you already know the keys."; }
         if(k == "MissionToast") { return "Replaces the game's quest banner with a Horizon toast. Off uses the game's banner. Move the toast in Arrange Cards. Needs the Comms module."; }
         if(k == "ReactionCard") { return "Restyles companion 'liked that' lines as a Horizon card. English game text only for now; other languages stay the game's. Needs the Comms module."; }
         if(k.indexOf("_modban_") == 0) { return "This add-on is listed in the Horizon UI installer. Installed means its files are loaded. Not installed means the game's own look is used. Paused - conflict means another add-on was found and Horizon stepped aside. Saved choices are kept either way. You can add the add-on from the Horizon UI installer."; }
         if(k == "_cmpok") { return "No other subtitle or dialogue add-on was found. Horizon is drawing its own subtitles and dialogue."; }
         return "";
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
            if(this.hz37Cf == k && k.indexOf("_hz37") != 0) { r.note = this.hz37Note(k, String(r.note)); }
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
         if(v === true || v === false) { return Boolean(v); }
         return Number(v) >= 0.5;
      }
      // Purpose: enable or mute dependent rows from the current pending parent
      // values on every draw. A parent toggle (MARKERS, Show Compass, Horizon
      // Style, and every other master) mutes children by setting dis=true.
      // Never assigns dis=false: hz51Finish recopies builder rows every draw, so
      // FOLLOWERS unlocks when the parent is on, and builder locks (DlgMarkers,
      // MissionToastSound, KEEP OFF, STATUS DIRECTORY) always survive.
      // Unavail/module-lock (chip) is never cleared. No per-frame work.
      private function hz51Mute(rows:Array) : Array
      {
         var i:int = 0;
         var parentOn:Boolean = true;
         var markersOn:Boolean = true;
         var extOn:Boolean = this.hz51On("QuickMenuExtended") && this.hz51On("QuickMenuHorizon");
         var hideHud:Boolean = this.hz51On("HideMainHudWhileScanning");
         var charRule:int = this.hzSetPend != null ? int(this.hzSetPend.CharacterRule) : 0;
         while(i < rows.length)
         {
            var r:Object = rows[i];
            var k:String = String(r.k);
            var locked:Boolean = r.chip == "unavail";
            if(r.h) { parentOn = true; markersOn = true; }
            var mute:Boolean = Boolean(r.sub) && !parentOn;
            if(k == "ShowFollowers" || k == "FollowerColor" || k == "ShowLocations" || k == "ShowShip" || k == "ShowEnemies" || k == "ShowPlayerMarker")
            {
               if(!markersOn) { mute = true; }
            }
            if(k == "FollowerColor" && !this.hz51On("ShowFollowers")) { mute = true; }
            if(r.t == "b" && k.indexOf("Show") == 0 && k != "ShowFollowers" && k != "ShowLocations" && k != "ShowShip" && k != "ShowEnemies" && k != "ShowPlayerMarker") { parentOn = this.hz51On(k); }
            if(k == "HazardStatus" || k == "EnemyBar" || k == "StealthMeter" || k == "XpToast" || k == "MissionToast" || k == "Subtitles" || k == "Dialogue" || k == "QuickMenuHorizon" || k == "QuickMenuExtended" || k == "Record" || k == "Persist") { parentOn = this.hz51On(k); }
            if(k == "CompassMarkers") { markersOn = parentOn && this.hz51On("CompassMarkers"); }
            if(k == "CharacterShowSeconds")
            {
               var eventRule:Boolean = charRule == 7 || charRule == 8 || charRule == 9;
               if(!eventRule)
               {
                  mute = true;
                  r.note = "Used only when Show when is an event choice. Your saved time is kept.";
                  r.n13 = true;
               }
            }
            if(k == "QuickMenuExtended" && !this.hz51On("QuickMenuHorizon"))
            {
               mute = true;
               r.note = "Turn on Horizon Style first. Extended Mode stays off until the Horizon look is on. Saved preference is kept.";
               r.n13 = true;
            }
            if(k.indexOf("QuickMenuKey") == 0 || k == "QuickMenuSlotCount" || k == "QuickMenuSlotsPerRow" || k == "QuickMenuExtendedLayout" || k == "QuickMenuExtEmptySlots" || k == "QuickMenuExtPanelOpacity" || k == "QuickMenuExtSlotScale" || k == "_qmkeys" || k == "_qmclear")
            {
               if(!extOn)
               {
                  mute = true;
                  r.note = "Turn on Extended Mode to bind keys. Saved keys are kept.";
                  r.n13 = true;
               }
            }
            if(k.indexOf("ScanShowVitals") == 0 || k == "ScanVitalsCompact" || k == "ScanVitalsLayout")
            {
               if(!hideHud)
               {
                  mute = true;
                  r.note = "Only used while Hide Horizon HUD while scanning is on.";
                  r.n13 = true;
               }
            }
            if((k == "PerfMode" || k == "PerfDump") && !this.hz51On("PerfDiag"))
            {
               mute = true;
               r.note = "Turn on Advanced Performance Timing first. Your saved choice is kept.";
               r.n13 = true;
            }
            if(!locked && mute)
            {
               r.dis = true;
               if(r.dv === undefined) { r.dv = this.hzSetPend != null ? this.hzSetPend[k] : 0; }
            }
            i++;
         }
         return rows;
      }
      private function hz51RuleRow(key:String, ids:Array) : Object
      {
         var opts:Array = [];
         var i:int = 0;
         if(ids == null) { ids = []; }
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
         var r:Object = {"k":key,"l":"SHOW WHEN","t":t,"ids":ids != null ? ids : [],"opts":opts,"sub":true};
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
         while(extra != null && i < extra.length) { if(extra[i] != null) { rows.push(extra[i]); } i++; }
         return rows;
      }
      // Purpose: one HorizonUI.log line per fallback catch per F11 open. hz51Rows
      // runs every draw, so the same throw must not queue or rebuild the overlay
      // again. Inputs: catch tag, page or section id, Error. Outputs: hzWlPush
      // once; Debug Overlay text when hzDebug is on. No HUD-frame work.
      private function hz51FbLog(tag:String, page:String, err:Error) : void
      {
         if(this.hz51FbSeen == null) { this.hz51FbSeen = {}; }
         var key:String = String(tag) + ":" + String(page);
         if(this.hz51FbSeen[key] === true) { return; }
         this.hz51FbSeen[key] = true;
         var msg:String = "";
         if(err != null) { try { msg = String(err.message); } catch(eMsg:Error) { msg = "error"; } }
         var line:String = "hz51 fallback " + tag + " page=" + page + " err=" + msg;
         if(this.hzWlOn) { this.hzWlPush(line); }
         if(this.hz51FbDbg == null) { this.hz51FbDbg = ""; }
         if(this.hz51FbDbg.length > 0) { this.hz51FbDbg += "\n"; }
         this.hz51FbDbg += line;
         if(this.hzDebug) { this.hzDbgShow(); }
      }
      // Purpose: append one card's rows. A throw in extras (null copy, missing
      // name table) must not wipe the rest of STATUS / COMBAT / INTERACTION.
      private function hz51AddCard(rows:Array, onKey:String, onLab:String, section:String, ruleKey:String, ruleIds:Array, scaleKey:String, compactKey:String, extra:Array) : void
      {
         try
         {
            var more:Array = this.hz51Card(onKey, onLab, section, ruleKey, ruleIds, scaleKey, compactKey, extra);
            var i:int = 0;
            while(i < more.length) { rows.push(more[i]); i++; }
         }
         catch(eAdd:Error)
         {
            this.hz51FbLog("eAdd", section, eAdd);
            rows.push({"k":onKey,"l":onLab,"t":"b","h":section});
            if(ruleKey != null && ruleKey.length > 0)
            {
               try { rows.push(this.hz51RuleRow(ruleKey, ruleIds)); } catch(eAddRule:Error) { }
            }
         }
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
            st.on = st.inst && this.hz51On("Subtitles");
            st.paused = st.inst && this.hz31SubForeign().length > 0 && Boolean(this.hz31Val("SubAutoPause"));
            if(!st.inst) { st.why = "Install it from the Horizon UI installer."; }
            else if(st.paused) { st.why = "Horizon subtitles are paused because another add-on was found."; st.act = "Use Horizon to turn Horizon's own menus back on."; }
            return st;
         }
         if(id == "comms_dialogue")
         {
            st.inst = this.hz30Mod["comms"] === 1;
            st.on = st.inst && this.hz51On("Dialogue");
            st.paused = st.inst && this.hz31DlgForeign() && Boolean(this.hz31Val("DlgAutoPause"));
            if(!st.inst) { st.why = "Install it from the Horizon UI installer."; }
            else if(st.paused) { st.why = "Horizon dialogue is paused because another add-on was found."; st.act = "Use Horizon to turn Horizon's own menus back on."; }
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
            if(!rows[i].pill && rows[i].t != "m" && rows[i].t != "mb" && rows[i].t != "mc")
            {
               rows[i].dis = true;
               rows[i].chip = "unavail";
               if(rows[i].dv === undefined && this.hzSetPend != null) { rows[i].dv = this.hzSetPend[String(rows[i].k)]; }
               var note:String = String(rows[i].note != undefined ? rows[i].note : why);
               if(note.indexOf("Saved preference is kept.") < 0) { note = (note.length > 0 ? note + " " : "") + "Saved preference is kept."; }
               rows[i].note = note;
               rows[i].n13 = true;
            }
            i++;
         }
         return rows;
      }
      // Purpose: module banner row (installed / not installed / paused). Inputs: module id, optional body.
      private function hz51ModRow(mod:String, body:String, st:String) : Object
      {
         var r:Object = {"k":"_modban_" + mod,"l":"","t": body != null && body.length > 0 ? "mb" : "m","mod":mod,"dis":true};
         if(body != null && body.length > 0) { r.body = body; }
         if(st != null && st.length > 0) { r.st = st; }
         return r;
      }
      // Purpose: installed banner, or not-installed banner plus dimmed rows. Saved values stay on the row.
      private function hz51WrapMod(rows:Array, mod:String, miss:String) : Array
      {
         var st:Object = this.hz51ModState(mod);
         if(!st.inst)
         {
            rows.unshift(this.hz51ModRow(mod, miss, "off"));
            return this.hz51Unavail(rows, miss);
         }
         if(st.paused)
         {
            var why:String = String(st.why != undefined ? st.why : "");
            if(st.act != undefined && String(st.act).length > 0) { why = why + " " + String(st.act); }
            rows.unshift(this.hz51ModRow(mod, why, "paused"));
            return rows;
         }
         rows.unshift(this.hz51ModRow(mod, "", "on"));
         return rows;
      }
      private function hz51Rows(tab:int, page:int) : Array
      {
         var id:String = "";
         var pages:Array = this.hz51Pages(tab);
         if(page >= 0 && page < pages.length) { id = String(pages[page].id); }
         var rows:Array = [];
         // A throw in one sidebar builder (STATUS used to abort here) must not
         // leave F11 with an empty body: fall through to the placeholder row.
         try
         {
            if(tab == 0) { rows = this.hz51Cards(id); }
            else if(tab == 1) { rows = this.hz51Appear(id); }
            else if(tab == 2) { rows = this.hz51Scan(id); }
            else if(tab == 3) { rows = this.hz51Comms(id); }
            else { rows = this.hz51System(id); }
         }
         catch(eRows:Error)
         {
            // Keep any rows already built; only a total miss uses the placeholder.
            this.hz51FbLog("eRows", id, eRows);
            try { rows = this.hz51Fallback(tab, id); } catch(eFb:Error) { this.hz51FbLog("eFb", id, eFb); if(rows == null) { rows = []; } }
         }
         var done:Array = this.hz51Finish(rows);
         if(done == null || done.length == 0)
         {
            // Never leave a sidebar page blank: show a row so the pane is never an empty card.
            done = this.hz51Finish([{"k":"_empty","l":"NO SETTINGS IN THIS SECTION","t":"x","btn":"—","h":"THIS SECTION","dis":true}]);
         }
         return done;
      }
      // Purpose: rebuild a CARDS page from hz34CardRows when the pretty builder
      // throws, so STATUS / COMBAT / INTERACTION never draw empty.
      // Inputs: tab, sidebar id. Outputs: row array (may be empty for other pages).
      private function hz51Fallback(tab:int, id:String) : Array
      {
         if(tab != 0) { return []; }
         var keys:Array = [];
         if(id == "sta") { keys = ["ShowVitals","VitalsRule","VitalsScale","VitalsLayout","VitalsBars","AutoCenterVitals","RegenSliver","ShowJetpack","JetpackRule","JetpackScale","ShowAfflictions","AfflictionsRule","AfflictionsScale","AfflictionLayout","HazardStatus","HazardScale","HazardCompact","EdgePulse"]; }
         else if(id == "com") { keys = ["ShowAmmo","AmmoRule","EquipmentScale","EquipmentCompact","EquipmentExtras","EnemyBar","EnemyScale","StealthMeter","StealthScale"]; }
         else if(id == "int") { keys = ["ShowTarget","NameHover","HoverScale","TargetAnchor","TargetShowValue","ContainerScale","ContainerOpacity","ObjectRing","VehicleExitPill"]; }
         else { return []; }
         var picked:Array = [];
         try { picked = this.hz51Pick(this.hz34CardRows(), keys); } catch(ePick:Error) { this.hz51FbLog("ePick", id, ePick); picked = []; }
         if(id == "sta")
         {
            picked.push({"k":"EdgePulse","l":"LOW HEALTH / O2 SCREEN-EDGE PULSE","t":"b","h":"WARNINGS"});
            picked.push({"k":"AfflictionLayout","l":"LAYOUT","t":"r","opts":["COLUMN","ROW","ICONS ONLY"],"ids":[0,1,2],"sub":true});
            picked.push({"k":"AutoCenterVitals","l":"AUTO-CENTER WHEN EQUIPMENT HIDDEN","t":"b","sub":true});
            picked.push({"k":"RegenSliver","l":"HEALING REGEN SLIVER","t":"b","sub":true});
            // SHOW WHEN lives on the old RULES tab, not hz34CardRows; pick cannot restore it.
            var haveSta:Object = this.hz51ByKey(picked);
            if(haveSta["VitalsRule"] == undefined) { picked.push(this.hz51RuleRow("VitalsRule",[0,5,1,2])); }
            if(haveSta["JetpackRule"] == undefined) { picked.push(this.hz51RuleRow("JetpackRule",[0,4,1,2])); }
            if(haveSta["AfflictionsRule"] == undefined) { picked.push(this.hz51RuleRow("AfflictionsRule",[0,6,1,2])); }
         }
         if(id == "com")
         {
            picked.push({"k":"CrosshairRule","l":"SHOW WHEN","t":"r","opts":["ALWAYS","WHEN WEAPON DRAWN","OFF"],"ids":[0,1,2],"h":"CROSSHAIR"});
            picked.push({"k":"CrosshairStyle","l":"INTERACTION STYLE","t":"r","opts":["VANILLA","HORIZON DOT","HORIZON CROSS","NONE"],"sub":true});
            picked.push({"k":"HitMarkers","l":"HIT MARKER / KILL X","t":"b","h":"COMBAT FEEDBACK"});
            picked.push({"k":"DamageNumbers","l":"DAMAGE NUMBERS","t":"b"});
            picked.push({"k":"DirectionRing","l":"DAMAGE DIRECTION RING","t":"b"});
            try { this.hz42ScRows(picked); } catch(eScFb:Error) { this.hz51FbLog("eSc", id, eScFb); }
         }
         return picked;
      }
      private function hz51Cards(id:String) : Array
      {
         var all:Array = [];
         try { all = this.hz34CardRows(); } catch(eAll:Error) { all = []; }
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
            // Literals only: copying hz34CardRows objects (or HZ_AFLAY_NAMES in a
            // nested extra) threw on STATUS and the outer try left the page empty.
            this.hz51AddCard(rows,"ShowVitals","VITALS","VITALS","VitalsRule",[0,5,1,2],"VitalsScale","", [
               {"k":"VitalsLayout","l":"LAYOUT","t":"r","opts":["VERTICAL","HORIZONTAL"],"ids":[0,1],"sub":true},
               {"k":"VitalsBars","l":"HEALTH AND O2 BARS","t":"r","opts":["FULL","COMPACT"],"ids":[0,1],"sub":true},
               {"k":"AutoCenterVitals","l":"AUTO-CENTER WHEN EQUIPMENT HIDDEN","t":"b","sub":true},
               {"k":"RegenSliver","l":"HEALING REGEN SLIVER","t":"b","sub":true}
            ]);
            this.hz51AddCard(rows,"ShowJetpack","JETPACK","JETPACK","JetpackRule",[0,4,1,2],"JetpackScale","", []);
            this.hz51AddCard(rows,"ShowAfflictions","AFFLICTIONS","AFFLICTIONS","AfflictionsRule",[0,6,1,2],"AfflictionsScale","", [
               {"k":"AfflictionLayout","l":"LAYOUT","t":"r","opts":["COLUMN","ROW","ICONS ONLY"],"ids":[0,1,2],"sub":true}
            ]);
            this.hz51AddCard(rows,"HazardStatus","HAZARD STATUS","HAZARD STATUS","",null,"HazardScale","HazardCompact", []);
            rows.push({"k":"EdgePulse","l":"LOW HEALTH / O2 SCREEN-EDGE PULSE","t":"b","h":"WARNINGS"});
            return rows;
         }
         if(id == "com")
         {
            this.hz51AddCard(rows,"ShowAmmo","EQUIPMENT","EQUIPMENT","AmmoRule",[0,3,1,2],"EquipmentScale","EquipmentCompact", [
               {"k":"EquipmentExtras","l":"GRENADES + STARBORN POWER","t":"b","sub":true}
            ]);
            this.hz51AddCard(rows,"EnemyBar","ENEMY HEALTH","ENEMY HEALTH","",null,"EnemyScale","", []);
            this.hz51AddCard(rows,"StealthMeter","STEALTH","STEALTH","",null,"StealthScale","", []);
            rows.push({"k":"CrosshairRule","l":"SHOW WHEN","t":"r","opts":["ALWAYS","WHEN WEAPON DRAWN","OFF"],"ids":[0,1,2],"h":"CROSSHAIR"});
            rows.push({"k":"CrosshairStyle","l":"INTERACTION STYLE","t":"r","opts":["VANILLA","HORIZON DOT","HORIZON CROSS","NONE"],"sub":true});
            rows.push({"k":"HitMarkers","l":"HIT MARKER / KILL X","t":"b","h":"COMBAT FEEDBACK"});
            rows.push({"k":"DamageNumbers","l":"DAMAGE NUMBERS","t":"b"});
            rows.push({"k":"DirectionRing","l":"DAMAGE DIRECTION RING","t":"b"});
            try { this.hz42ScRows(rows); } catch(eSc:Error) { this.hz51FbLog("eSc", id, eSc); }
            if(this.hz30Mod["scope"] !== 1)
            {
               var haveSc:Object = this.hz51ByKey(rows);
               if(haveSc["ScopeHoldBreathChip"] == undefined)
               {
                  rows.push({"k":"ScopeHoldBreathChip","l":"SCOPE: HOLD-BREATH CHIP","t":"b","h":"SCOPE"});
                  rows.push({"k":"ScopeChipScale","l":"CHIP SIZE","t":"n","mn":0.6,"mx":1.6,"st":0.05,"sub":true});
                  rows.push({"k":"_hz42scrst","l":"CHIP SPOT + SIZE","t":"x","btn":"RESET","sub":true});
               }
               var missSc:String = "Scope is not installed. The hold-breath chip is unavailable. You can add Scope from the Horizon UI installer. Saved choices are kept.";
               var si:int = 0;
               var inserted:Boolean = false;
               while(si < rows.length)
               {
                  var sk:String = String(rows[si].k);
                  if(sk == "ScopeHoldBreathChip" || sk == "ScopeChipScale" || sk == "_hz42scrst")
                  {
                     if(!inserted)
                     {
                        rows.splice(si, 0, this.hz51ModRow("scope", missSc, "off"));
                        inserted = true;
                        si++;
                     }
                     rows[si].dis = true;
                     rows[si].chip = "unavail";
                     rows[si].note = missSc;
                     rows[si].n13 = true;
                     if(rows[si].dv === undefined && this.hzSetPend != null) { rows[si].dv = this.hzSetPend[sk]; }
                  }
                  si++;
               }
            }
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
            rows.push({"k":"WatchScale","l":"SIZE","t":"z","sub":true});
            rows.push(this.hz51Goto("_goto_clocks","CLOCKS & UNITS",1,5,"TimeDisplay","LINKS"));
            rows.push(this.hz51Goto("_goto_scanwatch","HIDE WATCH WHILE SCANNING",2,1,"HideWatchWhileScanning",""));
            return rows;
         }
         if(id == "int")
         {
            this.hz51AddCard(rows,"ShowTarget","TARGET CARD","TARGET & HOVER","",null,"","", [
               {"k":"NameHover","l":"NAME HOVER","t":"r","opts":["COMPACT","FULL"],"ids":[0,1],"sub":true},
               {"k":"HoverScale","l":"HOVER SIZE","t":"z","sub":true},
               {"k":"TargetAnchor","l":"ANCHOR","t":"r","opts":["CROSSHAIR","FOLLOW TARGET"],"sub":true},
               {"k":"TargetShowValue","l":"ITEM VALUE / WEIGHT","t":"b","sub":true}
            ]);
            rows.push({"k":"ContainerScale","l":"LIST SIZE","t":"z","h":"CONTAINER"});
            rows.push({"k":"ContainerOpacity","l":"CONTAINER / CROSSHAIR CARD OPACITY","t":"n","mn":0.2,"mx":1.6,"st":0.05,"sub":true});
            rows.push({"k":"ObjectRing","l":"OBJECT RING / LEADER LINE","t":"r","opts":["OFF","CONTAINERS ONLY","VANILLA"],"h":"OBJECT HIGHLIGHT"});
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
         var rows:Array = [{"k":"QuickMenuHorizon","l":"HORIZON STYLE","t":"b","h":"QUICK MENU / FAVORITES MENU"},
            {"k":"QuickMenuExtended","l":"EXTENDED MODE","t":"b"},
            {"k":"QuickMenuSlotCount","l":"SLOT COUNT","t":"n","mn":12,"mx":24,"st":1},
            {"k":"QuickMenuSlotsPerRow","l":"SLOTS PER ROW","t":"r","opts":["4","6","8"],"ids":[4,6,8]},
            {"k":"QuickMenuExtendedLayout","l":"EXTENDED LAYOUT","t":"r","opts":["CROSS + BARS","BARS"],"ids":[0,1]},
            {"k":"QuickMenuExtEmptySlots","l":"EMPTY SLOTS","t":"r","opts":["SHOW","HIDE"],"ids":[1,0],"h":"EXTENDED LOOK"},
            {"k":"QuickMenuExtPanelOpacity","l":"PANEL OPACITY","t":"n","mn":0,"mx":100,"st":1,"pct":1,"n13":true},
            {"k":"QuickMenuExtSlotScale","l":"SLOT SCALE","t":"n","mn":0.7,"mx":1.4,"st":0.05},
            {"k":"_qmkeys","l":"EXTENDED SLOT KEYS","t":"kg","h":"EXTENDED SLOT KEYS"}];
         var qmOff:Boolean = this.hz30Mod["quickmenu"] !== 1;
         var qmConf:Boolean = this.hzQmConflict;
         var miss:String = "Quick Menu is not installed. The favorites cross stays the game's. You can add Quick Menu from the Horizon UI installer. Saved choices are kept.";
         if(qmOff)
         {
            rows.unshift(this.hz51ModRow("quickmenu", miss, "off"));
            return this.hz51Unavail(rows, "Quick Menu module not installed. Reinstall Horizon UI and pick Quick Menu in the installer to use these settings.");
         }
         rows.unshift(this.hz51ModRow("quickmenu", "", "on"));
         if(qmConf)
         {
            var i:int = 0;
            while(i < rows.length)
            {
               if(String(rows[i].k) != "QuickMenuHorizon" && String(rows[i].t) != "m" && String(rows[i].t) != "mb")
               {
                  rows[i].dis = true;
                  rows[i].note = "Extended Mode is paused because another favorites add-on is installed. Saved keys are kept.";
                  rows[i].n13 = true;
               }
               i++;
            }
            rows.splice(1, 0, this.hz51ModRow("quickmenu", "Another favorites add-on is installed. Horizon Style still works. Extended slots stay off until that add-on is removed.", "paused"));
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
         if(id == "pop")
         {
            var pop:Array = [];
            try { pop = this.hz40PopupRows(); } catch(ePop:Error) { pop = []; }
            var i:int = 0;
            while(i < pop.length) { if(String(pop[i].k) == "HideQuestPopupsWhileScanning") { pop[i].h = "POPUPS"; } i++; }
            if(pop.length == 0)
            {
               pop = [{"k":"HideQuestPopupsWhileScanning","l":"HIDE QUEST POPUPS WHILE SCANNING","t":"b","h":"POPUPS"},
                  {"k":"DimTraitPopupDuringBioscan","l":"DIM TRAIT POPUP WHILE SCANNING","t":"b"},
                  {"k":"TraitPopupDim","l":"TRAIT POPUP DIM","t":"n","mn":0.1,"mx":0.9,"st":0.05,"sub":true}];
            }
            return pop;
         }
         var src:Array = [];
         try { src = this.hz40ScanRows(); } catch(eScan:Error) { src = []; }
         var m:Object = this.hz51ByKey(src);
         var keys:Array = [];
         var rows:Array = [];
         if(id == "ov") { keys = ["_hz41arrscan","ScanCompactAll","ScanHighlightArea","ScanReach","_hz40rstlay","_hz40rstall"]; }
         else if(id == "hud")
         {
            try { var hud:Array = this.hz41TopRows(); if(hud != null && hud.length > 0) { rows = hud; } } catch(eHud:Error) { }
            if(rows.length == 0)
            {
               rows = [{"k":"HideMainHudWhileScanning","l":"HIDE HORIZON HUD WHILE SCANNING","t":"b","h":"MAIN HUD"},
                  {"k":"ScanShowVitalsHealth","l":"KEEP HEALTH","t":"b","sub":true},
                  {"k":"ScanShowVitalsO2","l":"KEEP O2","t":"b","sub":true},
                  {"k":"ScanShowVitalsBoost","l":"KEEP BOOST","t":"b","sub":true},
                  {"k":"ScanVitalsCompact","l":"COMPACT VITALS","t":"b","sub":true},
                  {"k":"ScanVitalsLayout","l":"VITALS LAYOUT","t":"r","opts":["VERTICAL","HORIZONTAL"],"ids":[0,1],"sub":true},
                  {"k":"HideWatchWhileScanning","l":"HIDE WATCH WHILE SCANNING","t":"b"}];
            }
         }
         else if(id == "tl") { keys = ["ScanShowMode","ScanModeScale","ScanShowHints","ScanHintsScale","ScanOutlineThickness"]; }
         else if(id == "sig") { keys = ["ScanShowSignals","ScanSignalsScale","ScanMaxSignals","ScanShowShip","ScanShowCompass","ScanCompassScale","ScanShowWorldTags"]; }
         else if(id == "sv") { keys = ["ScanShowPlanet","ScanPlanetScale","ScanPlanetCompact","ScanShowBodyType","ScanHazardWarn","ScanHazardCrit","ScanShowBioscan","ScanBioscanScale","ScanBioscanCompact","ScanHideBioscanDone","ScanCompleteFlash","ScanLeftToFind","ScanShowTraits","ScanTraitsScale","ScanTraitsCompact","ScanMinRarity"]; }
         else { keys = ["ScanOpacity","ScanAccIdx","ScanTextCase","ScanFont","ScanMargin","ScanUnits"]; }
         if(rows.length == 0)
         {
            rows = this.hz51Pick(src, keys);
            var have:Object = this.hz51ByKey(rows);
            var ki:int = 0;
            while(ki < keys.length)
            {
               var kk:String = String(keys[ki]);
               if(have[kk] == undefined)
               {
                  if(kk.indexOf("Scale") > 0) { rows.push({"k":kk,"l":"SIZE","t":"z","sub":true}); }
                  else if(kk.indexOf("Compact") > 0) { rows.push({"k":kk,"l":"COMPACT FORM","t":"r","opts":["GLOBAL","ON","OFF"],"ids":[-1,1,0],"sub":true}); }
                  else { rows.push({"k":kk,"l":kk,"t":"b"}); }
               }
               ki++;
            }
         }
         if(id == "sig")
         {
            var labs:Object = {"ScanShowSignals":"SIGNALS","ScanSignalsScale":"SIZE","ScanMaxSignals":"HOW MANY SIGNALS","ScanShowShip":"YOUR SHIP AND VEHICLE","ScanShowCompass":"SCANNER COMPASS","ScanCompassScale":"COMPASS SIZE","ScanShowWorldTags":"PLACE NAMES"};
            var ri:int = 0;
            while(ri < rows.length)
            {
               var lk:String = String(rows[ri].k);
               if(labs[lk] != undefined) { rows[ri].l = String(labs[lk]); }
               if(lk == "ScanShowSignals") { rows[ri].h = "SIGNALS"; }
               if(lk == "ScanShowCompass") { rows[ri].h = "COMPASS"; }
               if(lk == "ScanShowWorldTags") { rows[ri].h = "PLACE NAMES"; }
               ri++;
            }
         }
         if(id == "ov" && m["_hz30m_scanner"] != undefined) { /* banner comes from hz51WrapMod */ }
         if(id == "ap") { rows.push(this.hz51Goto("_goto_temp","TEMPERATURE UNITS",1,this.hz51PageIndex(1,"clk"),"TempUnit","SHORTCUT")); }
         return this.hz51WrapMod(rows, "scanner", "Scanner is not installed. Scanner panels and signals are unavailable. You can add Scanner from the Horizon UI installer. Saved choices are kept.");
      }
      private function hz51CommsMap() : Object
      {
         var m:Object = {};
         var saved:int = this.hz31Page;
         var pg:int = 0;
         while(pg < 2)
         {
            this.hz31Page = pg;
            var full:Array = [];
            try { full = this.hz31CommsRows(); } catch(eCom:Error) { full = []; }
            var i:int = 0;
            while(i < full.length)
            {
               if(full[i] != null && full[i].k != null) { m[String(full[i].k)] = this.hz51Copy(full[i]); }
               i++;
            }
            pg++;
         }
         this.hz31Page = saved;
         return m;
      }
      private function hz51Comms(id:String) : Array
      {
         var miss:String = "Comms is not installed. Mission toasts and reaction cards are unavailable. You can add Comms from the Horizon UI installer. Saved choices are kept.";
         var src:Object = this.hz51CommsMap();
         var keys:Array = [];
         var rows:Array = [];
         if(id == "mst")
         {
            rows = [{"k":"MissionToast","l":"MISSION TOAST","t":"b","h":"MISSION TOASTS"},
               {"k":"MissionToastScale","l":"SIZE","t":"z","sub":true},
               {"k":"MissionToastTime","l":"SECONDS ON SCREEN","t":"n","mn":2,"mx":15,"st":1,"sub":true},
               {"k":"MissionToastMax","l":"MAX STACKED","t":"n","mn":1,"mx":5,"st":1,"sub":true},
               {"k":"MissionToastSound","l":"GAME QUEST SOUND","t":"b","dis":true,"dv":true},
               {"k":"ReactionCard","l":"COMPANION REACTION CARD","t":"b","h":"REACTIONS"},
               {"k":"GameCardTitle","l":"NOTICE LABEL","t":"r","opts":["NONE","DATA","MISC"],"ids":[0,1,2]}];
            return this.hz51WrapMod(rows, "comms", miss);
         }
         if(id == "cmp")
         {
            var subF:Boolean = this.hz31SubForeign().length > 0;
            var dlgF:Boolean = this.hz31DlgForeign();
            var subPause:Boolean = subF && Boolean(this.hz31Val("SubAutoPause"));
            var dlgPause:Boolean = dlgF && this.hz31On("comms_dialogue") && Boolean(this.hz31Val("DlgAutoPause"));
            if(subF)
            {
               rows.push({"k":"_hz31usesub","l":"ANOTHER SUBTITLE MOD DETECTED: HORIZON SUBTITLES PAUSED","t":"x","btn":"USE HORIZON","h":"CONFLICTS"});
            }
            if(dlgF)
            {
               rows.push({"k":"_hz31usedlg","l":"ANOTHER DIALOGUE MOD DETECTED: HORIZON DIALOGUE PAUSED","t":"x","btn":"USE HORIZON","h": subF ? "" : "CONFLICTS"});
            }
            if(!subF && !dlgF)
            {
               rows.push({"k":"_cmpok","l":"NO CONFLICT","t":"x","btn":"OK","dis":true,"dv":true,"h":"CONFLICTS","note":"Horizon is drawing its own subtitles and dialogue."});
            }
            rows.push({"k":"SubAutoPause","l":"SUBTITLE CONFLICT AUTO-PAUSE","t":"b","h":"AUTO-PAUSE"});
            rows.push({"k":"DlgAutoPause","l":"DIALOGUE CONFLICT AUTO-PAUSE","t":"b"});
            rows.push({"k":"_ownsub","l":"SUBTITLES","t":"md","badge": subPause ? "PAUSED" : "ACTIVE","h":"OWNERSHIP","dis":true});
            rows.push({"k":"_owndlg","l":"DIALOGUE","t":"md","badge": dlgPause ? "PAUSED" : "ACTIVE","dis":true});
            rows.push(this.hz51Goto("_goto_mst","MISSION TOASTS & REACTION CARDS",3,this.hz51PageIndex(3,"mst"),"MissionToast","RELATED"));
            var stC:Object = this.hz51ModState("comms");
            if(!stC.inst) { return this.hz51WrapMod(rows, "comms", miss); }
            if(stC.paused)
            {
               rows.unshift(this.hz51ModRow("comms", "Another subtitle / dialogue mod is installed (Enhanced Subtitles or Enhanced Dialogue Interface). Horizon Comms is paused so the two do not overlap.", "paused"));
               return rows;
            }
            rows.unshift(this.hz51ModRow("comms", "", "on"));
            return rows;
         }
         if(id == "prs")
         {
            // Same persuasion keys as the old F11 DIALOGUE page (OPTION TAGS), listed here
            // so CHOICES & PERSUASION does not depend on copying that catalog.
            rows = [{"k":"DlgSaidStyle","l":"ALREADY-SAID STYLE","t":"r","opts":["DIMMED","HIDDEN","TAGGED"],"h":"CHOICES & PERSUASION"},
               {"k":"DlgPersuadeStyle","l":"PERSUASION TAG","t":"r","opts":["CHIP","COLORED TEXT","NONE"]},
               {"k":"DlgPersuadeColor","l":"PERSUASION TAG COLOR","t":"a","pal":HZ_ACCENTS,"names":HZ_SET_ACCNAMES},
               {"k":"DlgPersuasionMeter","l":"PERSUASION METER","t":"b"},
               {"k":"DlgMarkers","l":"QUESTION / ADVANCE MARKERS","t":"b","dis":true,"dv":false}];
            return this.hz51WrapMod(rows, "comms", miss);
         }
         if(id == "sub") { keys = ["Subtitles","SubSize","SubWidth","SubBgOpacity","SubPosition","SubOffsetY","SubOffsetX","SubAlign","SubCard","TxtColIdx","KeepInDialogue","FixedInDialogue","SubMaxLines","SubFont"]; }
         else if(id == "spk") { keys = ["ShowSpeaker","SpkColIdx","SpeakerCard"]; }
         else if(id == "dly") { keys = ["Dialogue","DlgLayout","DlgVisible","DlgMoreHint","DlgScale","DlgOffsetX","DlgOffsetY"]; }
         else if(id == "dlap") { keys = ["DlgTextSize","DlgFont","DlgCard","DlgBgColor","DlgBgOpacity","DlgTxtIdx","DlgAnim"]; }
         else { keys = ["DlgNumberKeys","DlgWheel","DlgHoverScroll","DlgInputDelay","DlgRolloverSound","DlgButtonBar","DlgQuickPickHint","DlgSelectHint"]; }
         var ki:int = 0;
         while(ki < keys.length)
         {
            var kk:String = String(keys[ki]);
            if(src[kk] != undefined) { rows.push(this.hz51Copy(src[kk])); }
            else { rows.push({"k":kk,"l":kk,"t":"b"}); }
            ki++;
         }
         if(id == "sub" && rows.length > 0) { rows[0].h = "SUBTITLES"; }
         if(id == "spk" && rows.length > 0) { rows[0].h = "SPEAKER"; }
         if(id == "dly" && rows.length > 0) { rows[0].h = "DIALOGUE LAYOUT"; }
         if(id == "dlap" && rows.length > 0) { rows[0].h = "DIALOGUE APPEARANCE"; }
         if(id == "inp" && rows.length > 0) { rows[0].h = "INPUT & HINTS"; }
         return this.hz51WrapMod(rows, "comms", miss);
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
      private function hz51ModBadge(st:Object, id:String) : String
      {
         if(!st.inst) { return "NOT INSTALLED"; }
         if(st.paused) { return "PAUSED - CONFLICT"; }
         if(id == "quickmenu" && !this.hz51On("QuickMenuHorizon")) { return "INSTALLED - DISABLED"; }
         if((id == "comms" || id == "comms_dialogue") && st.inst && !st.paused && !st.on) { return "INSTALLED - DISABLED"; }
         if(st.on) { return "INSTALLED"; }
         return "INSTALLED - DISABLED";
      }
      private function hz51Modules() : Array
      {
         // Runtime-disableable modules get swk (an existing INI key). Install-only
         // modules are status. No new INI keys. Author: Moragar. Last modified: 2026-11-27.
         var list:Array = [
            {"id":"core","l":"CORE HUD","d":"Vitals, compass, quest tracker, and the other HUD cards."},
            {"id":"font","l":"HORIZON FONT","d":"Exo 2 and the other Horizon typefaces. Face is chosen under Appearance."},
            {"id":"quickmenu","l":"QUICK MENU","d":"Horizon favorites cross and extra slots 13-24. Off hands the menu back to the game.","swk":"QuickMenuHorizon"},
            {"id":"comms","l":"COMMS","d":"Horizon subtitle lines. Off leaves the game's subtitles.","swk":"Subtitles"},
            {"id":"comms_dialogue","l":"COMMS DIALOGUE","d":"Horizon dialogue list. Off leaves the game's dialogue menu.","swk":"Dialogue"},
            {"id":"scanner","l":"SCANNER","d":"Horizon hand scanner panels, signals, and survey."},
            {"id":"scope","l":"SCOPE","d":"Hold-breath chip while you aim down a scope."},
            {"id":"msglog","l":"NOTIFICATIONS","d":"Message Log recording. Record on/off lives on the Message Log page."}
         ];
         var rows:Array = [{"k":"_dirinst","l":"INSTALLED, ENABLED, AND VISIBLE","t":"x","btn":"—","h":"STATUS DIRECTORY","dis":true,"dv":true}];
         rows.push(this.hz51Goto("_goto_showwhen","SHOW WHEN",0,this.hz51PageIndex(0,"sta"),"VitalsRule","RELATED"));
         var i:int = 0;
         while(i < list.length)
         {
            var id:String = String(list[i].id);
            var st:Object = this.hz51ModState(id);
            var badge:String = this.hz51ModBadge(st, id);
            var r:Object = {"k":"_mod_" + id,"l":String(list[i].l),"t":"mc","badge":badge,"h": i == 0 ? "MODULES" : "","modid":id,"body":String(list[i].d)};
            r.t = "mc";
            if(list[i].swk != undefined) { r.swk = String(list[i].swk); }
            if(!st.inst) { r.note = String(st.why); r.n13 = true; r.dis = true; r.dv = 0; r.chip = "unavail"; }
            else if(st.paused) { r.note = String(st.why) + (st.act.length > 0 ? " " + String(st.act) : ""); r.n13 = true; r.warn = true; }
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
            {"k":"_mlold","l":"OLD CHARACTER LOGS","t":"x","btn":"OPEN"},
            {"k":"_msglog","l":"OPEN LOG","t":"x","btn":"OPEN"}];
         if(this.hzMsglogModule() == 0) { return this.hz51WrapMod(rows, "msglog", "Notifications is not installed. The Message Log is unavailable. You can add it from the Horizon UI installer. Saved choices are kept."); }
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
               try
               {
                  var rows:Array = this.hz51Rows(tab, p);
                  var r:int = 0;
                  while(r < rows.length)
                  {
                     var row:Object = rows[r];
                     if(row == null || row.pill || row.t == "m" || row.t == "mb" || row.t == "mc" || row.t == "g" || row.t == "w" || String(row.k) == "_empty") { r++; continue; }
                     var lab:String = String(row.l != undefined ? row.l : "");
                     var note:String = row.note != undefined ? String(row.note) : "";
                     if(lab.length == 0) { r++; continue; }
                     var help:String = this.hz51HelpOf(String(row.k), row);
                     var hay:String = (lab + " " + note + " " + help + " " + String(row.k) + " " + this.hz51Crumb(tab, p)).toLowerCase();
                     idx.push({"k":String(row.k),"l":lab,"tab":tab,"page":p,"row":r,"crumb":this.hz51Crumb(tab, p),"hay":hay});
                     r++;
                  }
               }
               catch(eIdxP:Error) { }
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
         this.hz51FindClose();
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
         if(r.t == "p") { return this.hz51PresetNames(); }
         return [];
      }
      // Purpose: names for the PRESET dropdown from the last DLL scan
      // (hz37Ps). Save-as-new-name must appear here without reopening F11.
      private function hz51PresetNames() : Array
      {
         var o:Array = [];
         var i:int = 0;
         var ps:Array = this.hz37Ps;
         if(ps == null) { return o; }
         while(i < ps.length)
         {
            var p:Object = ps[i];
            if(p != null && p.n != undefined && String(p.n).length > 0) { o.push(String(p.n)); }
            i++;
         }
         return o;
      }
      private function hz51DropPick(r:Object, idx:int) : void
      {
         if(r == null || this.hzSetPend == null) { return; }
         var opts:Array = this.hz51DropOpts(r);
         if(idx < 0 || opts == null || idx >= opts.length) { return; }
         var k:String = String(r.k);
         if(r.t == "p")
         {
            if(this.hz37Ps != null && idx < this.hz37Ps.length)
            {
               this.hz37Sel = idx;
               this.hz37SelId = String(this.hz37Ps[idx].id);
            }
            return;
         }
         if(r.t == "r" && r.ids != undefined) { this.hzSetPend[k] = int((r.ids as Array)[idx]); }
         else if(r.t == "r") { this.hzSetPend[k] = idx; }
         else if(r.t == "q") { this.hzSetPend[k] = int((r.ids as Array)[idx]); }
         else if(r.t == "l") { this.hzSetPend[k] = (r.vals as Array)[idx]; }
         else if(r.t == "a") { this.hzSetPend[k] = idx; }
         else if(r.t == "c") { this.hzSetPend[k] = HZ_SET_KEYS[idx]; }
         this.hzSetLive(this.hzSetPend);
      }
      // Purpose: topmost hit under the cursor. An open dropdown owns the click:
      // dopt rows and the menu rect win. A SIZE slider under the list used to
      // break the walk on "bar" before dopt was seen, so every option after the
      // first applied to the row below. Scroll and upward menus use the same
      // dopt rects the draw path paints (visible slot y, option index in the id).
      // Inputs: mouse in HorizonSettings_mc space. Outputs: hit or null.
      private function hz51HitAt(mx:Number, my:Number) : Object
      {
         var hits:Array = this.hzSetHits;
         if(hits == null) { return null; }
         var i:int;
         var h:Object;
         if(this.hzSetDrop >= 0)
         {
            i = hits.length - 1;
            while(i >= 0)
            {
               h = hits[i];
               if(h != null && mx >= Number(h.x) && mx <= Number(h.x) + Number(h.w) && my >= Number(h.y) && my <= Number(h.y) + Number(h.h) && String(h.id).indexOf("dopt") == 0)
               {
                  return h;
               }
               i--;
            }
            var box:Object = this.hzSetDropMenu;
            if(box != null && mx >= Number(box.x) && mx <= Number(box.x) + Number(box.w) && my >= Number(box.y) && my <= Number(box.y) + Number(box.h))
            {
               return {"id":"dropbg","x":box.x,"y":box.y,"w":box.w,"h":box.h};
            }
            return {"id":"dropout","x":mx,"y":my,"w":1,"h":1};
         }
         i = hits.length - 1;
         while(i >= 0)
         {
            h = hits[i];
            if(h != null && mx >= Number(h.x) && mx <= Number(h.x) + Number(h.w) && my >= Number(h.y) && my <= Number(h.y) + Number(h.h))
            {
               return h;
            }
            i--;
         }
         return null;
      }
      // Purpose: filled disc from lineTo segments so Scaleform anti-aliases a
      // circle at 12px (drawCircle plus hz51Stroke's four bars looked square).
      private function hz51Disk(g:*, cx:Number, cy:Number, r:Number, col:uint, a:Number) : void
      {
         if(g == null || r < 2 || a <= 0) { return; }
         cx = Math.round(cx);
         cy = Math.round(cy);
         r = Math.round(r);
         var n:int = 16;
         var i:int = 0;
         g.beginFill(col, a);
         while(i <= n)
         {
            var ang:Number = i * Math.PI * 2 / n;
            var px:Number = cx + Math.cos(ang) * r;
            var py:Number = cy + Math.sin(ang) * r;
            if(i == 0) { g.moveTo(px, py); }
            else { g.lineTo(px, py); }
            i++;
         }
         g.endFill();
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
      // Purpose: search is "open" while the box is focused or still has text
      // (GotoHit used to clear focus but leave the query, so Esc closed F11).
      private function hz51FindOpen() : Boolean
      {
         return this.hzSetFindOn || this.hzSetFind.length > 0;
      }
      // Purpose: Esc / B / RMB / the search X close results and return to the page.
      // Inputs: none. Outputs: findOn, find, findHi, focus, glow cleared.
      private function hz51FindClose() : void
      {
         this.hzSetFindOn = false;
         this.hzSetFind = "";
         this.hzSetFindHi = 0;
         this.hzSetFocus = 0;
         this.hzSetGlowK = "";
      }
      // Purpose: 22px row button (OPEN / RESET / SHOW / ARRANGE) matching 48px
      // rows and 11px labels. hzSetBtn stays 28px for the footer OK / CANCEL.
      // Inputs: label, right edge R, row center. Outputs: width, hit id.
      private function hz51Btn(b:Sprite, g:*, R:Number, cy:Number, lab:String, hov:Boolean, T:Object, id:String) : Number
      {
         var acc:uint = uint(T.acc);
         var fs:Number = 11;
         var t:TextField = this.hz51T(b,lab,0,cy - 8,220,fs,"sb",uint(T.txt),1.2);
         var tw:Number = Math.ceil(this.hzTW(t) + 8);
         var w:Number = Math.round(Math.max(HZ51_CTRL_W > 88 ? 88 : HZ51_CTRL_W, tw + 20));
         if(w < 88) { w = 88; }
         var h:Number = HZ51_BTN_H;
         var x:Number = Math.round(R - w);
         var y:Number = Math.round(cy - h / 2);
         b.removeChild(t);
         g.beginFill(uint(T.mut),hov ? 0.32 : 0.16);
         g.drawRoundRect(x,y,w,h,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,x,y,w,h,HZ51_BOX_R,hov ? acc : uint(T.txt),hov ? 0.85 : 0.28,1);
         this.hz51T(b,lab,x + w / 2,y + 4,w,fs,"sb",uint(T.txt),1.2,"center");
         this.hzSetHits.push({"id":id,"x":x,"y":y,"w":w,"h":h});
         return w;
      }
      // Purpose: scanner / comms / quick menu / scope module banner inside the
      // Settings 2.0 content column. Inputs: list box x/width and the row (mod, st, body).
      // Outputs: 40px installed chip or 88px not-installed / paused card.
      private function hz51ModBanner(b:Sprite, g:*, y:Number, x0:Number, boxW:Number, T:Object, r:Object, sel:Boolean, idx:int) : Number
      {
         var mod:String = r != null && r.mod != undefined ? String(r.mod) : "";
         var live:* = this.hz30Mod != null ? this.hz30Mod[mod] : 0;
         if(mod == "msglog") { live = this.hzMsglogModule(); }
         if(mod == "font") { live = this.hz30FontAvail() ? 1 : 0; }
         if(mod == "core") { live = 1; }
         var kind:String = r != null && r.st != undefined ? String(r.st) : (live === 1 ? "on" : "off");
         var on:Boolean = kind == "on";
         var paused:Boolean = kind == "paused";
         var acc:uint = uint(T.acc);
         var warn:uint = 0xE8B84A;
         var body:String = r != null && r.body != undefined ? String(r.body) : "";
         var h:Number = body.length > 0 ? 88 : 40;
         var y0:Number = Math.round(y);
         var w:Number = Math.max(80, boxW);
         var edge:uint = paused ? warn : (on ? acc : uint(T.line));
         g.beginFill(uint(T.tile),Number(T.tia)); g.drawRoundRect(x0,y0,w,h,HZ51_BOX_R,HZ51_BOX_R); g.endFill();
         if(on) { g.beginFill(acc,0.08); g.drawRoundRect(x0,y0,w,h,HZ51_BOX_R,HZ51_BOX_R); g.endFill(); }
         if(paused) { g.beginFill(warn,0.08); g.drawRoundRect(x0,y0,w,h,HZ51_BOX_R,HZ51_BOX_R); g.endFill(); }
         if(sel || this.hzSetHover == "row" + idx) { g.beginFill(acc,sel ? 0.10 : 0.05); g.drawRoundRect(x0,y0,w,h,HZ51_BOX_R,HZ51_BOX_R); g.endFill(); }
         this.hz34Ring(b,x0,y0,w,h,HZ51_BOX_R,edge,on || paused ? 0.70 : 0.28,1);
         var ccx:Number = x0 + 20;
         var ccy:Number = y0 + 20;
         g.beginFill(on ? acc : (paused ? warn : uint(T.line)),on ? 0.16 : 0.1); g.drawCircle(ccx,ccy,10); g.endFill();
         if(on) { this.hz30Check(g,ccx,ccy,9,acc); }
         else if(paused) { this.hz51T(b,"!",ccx,ccy - 7,16,11,"bd",warn,0,"center"); }
         else { this.hz30Lock(g,ccx,ccy + 1,10,uint(T.mut),1,uint(T.fill)); }
         var names:Object = {"scanner":"SCANNER MODULE","comms":"COMMS MODULE","comms_dialogue":"COMMS DIALOGUE","quickmenu":"QUICK MENU MODULE","scope":"SCOPE MODULE","font":"HORIZON FONT","core":"CORE HUD","msglog":"NOTIFICATIONS MODULE"};
         var title:String = names[mod] != undefined ? String(names[mod]) : (mod.toUpperCase() + " MODULE");
         var stx:String = on ? "INSTALLED" : (paused ? "PAUSED - CONFLICT" : (live !== 0 && live !== 1 && kind != "off" ? "CHECKING..." : "NOT INSTALLED"));
         this.hz51T(b,"MODULE",x0 + 38,y0 + 6,70,8,"sb",uint(T.mut),1.2);
         this.hz51T(b,title,x0 + 38,y0 + 18,Math.max(80,w * 0.55),11,"bd",uint(T.txt),1.4);
         this.hz51T(b,stx,x0 + w - 16,y0 + 16,150,11,"sb",paused ? warn : (on ? acc : uint(T.lab)),1.2,"right");
         if(body.length > 0)
         {
            var bt:TextField = this.hz51T(b,body,x0 + 16,y0 + 40,w - 32,10,"rg",uint(T.lab),0.1);
            bt.wordWrap = true; bt.multiline = true; bt.width = w - 32;
            this.hzMsglogWrap(bt,w - 32,40);
         }
         if(idx >= 0) { this.hzSetHits.push({"id":"row" + idx,"x":x0,"y":y0,"w":w,"h":h}); }
         return h;
      }
      // Purpose: 12px round (i) disc with a centered letter, not a square stroke.
      // hz51Stroke is four 1px bars (the teal-wedge fix) and boxed the old disc
      // at 1080p and 1440p. Fill is a 16-gon; the ring is hz34Ring (quarter
      // curves). The 'i' is a pixel-fitted TextField so it stays centered.
      private function hz51InfoIcon(b:Sprite, g:*, cx:Number, cy:Number, acc:uint, T:Object, on:Boolean, i:int) : void
      {
         var r:Number = HZ51_INFO_R;
         cx = Math.round(cx);
         cy = Math.round(cy);
         this.hz51Disk(g,cx,cy,r,acc,on ? 0.32 : 0.14);
         this.hz34Ring(b,cx - r,cy - r,r * 2,r * 2,r,acc,on ? 1 : 0.7,1);
         this.hz51T(b,"i",cx,cy - r + 2,r * 2,8,"bd",on ? uint(T.txt) : acc,0,"center");
         this.hzSetHits.push({"id":"inf" + i,"x":cx - 10,"y":cy - 10,"w":20,"h":20});
      }
