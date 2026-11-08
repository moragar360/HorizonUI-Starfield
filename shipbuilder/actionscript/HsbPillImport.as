package
{
   import flash.display.Graphics;
   import flash.text.TextField;

   // Purpose: the pill import dialog from gold mockup 3. Lists pill and pack files found in
   //    Data\Interface\HorizonUI\shipbuilder\pills\ (packs and user), previews the chosen file,
   //    and adds its pills only after the player confirms.
   // Inputs: the DLL's file job replies (PILLS LIST, PILLS READ); the current pill list; the
   //    browser's parts for "Matches N"; pointer, wheel and keys routed by the builder.
   // Outputs: new or replaced pills in the list, saved through PROFILE WRITE (which keeps a
   //    .bak); optionally the pack's column sets (Columns.<tab> in the user ini).
   // Dependencies: HsbPillModel (readShared, clean, freeName, limits), HsbBrowser
   //    (countMatches, tabNameFor, tabKeyNow, columnLabel, afterPills), HorizonShipBuilder
   //    (fileOp, savePills, setSetting, saveSettings, popups).
   // Limits: at most 40 files are read; a file the DLL refuses or that does not parse is listed
   //    as "Can't read · skipped". Names and text from shared files are shown, never logged.
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbPillImport extends HsbBox
   {
      private static const MAX_FILES:int = 40;
      private static const FOLDER_TEXT:String = "Data\\Interface\\HorizonUI\\shipbuilder\\pills\\";

      private var hsb:HorizonShipBuilder;
      private var browser:HsbBrowser;
      private var entries:Array;
      private var waiting:int = 0;
      private var listed:Boolean = false;
      private var listFailed:Boolean = false;
      private var chosen:int = -1;
      private var choices:Object;
      private var useColumns:Boolean = false;
      private var leftScroll:int = 0;
      private var rightScroll:int = 0;
      private var leftRows:int = 0;
      private var rightRows:int = 0;
      private var paneX:Number = 0;
      private var problem:String = "";

      public function HsbPillImport(param1:HsbKit, param2:HorizonShipBuilder, param3:HsbBrowser)
      {
         super(param1,"HsbPillImport");
         this.hsb = param2;
         this.browser = param3;
         this.entries = [];
         this.choices = {};
      }

      // Purpose: open the dialog over the browser and start reading the pill folders.
      // Inputs: kit, builder, browser. Outputs: the open dialog. Dependencies: fileOp.
      internal static function openFor(param1:HsbKit, param2:HorizonShipBuilder, param3:HsbBrowser):HsbPillImport
      {
         var d:HsbPillImport = new HsbPillImport(param1,param2,param3);
         d.paint();
         d.anchorX = param3.x + (param3.boxW - 13 - d.boxW) * param3.scaleX;
         d.anchorY = param3.y + 126 * param3.scaleY;
         param2.openPop(d);
         d.start();
         return d;
      }

      private function start():void
      {
         var self:HsbPillImport = this;
         this.hsb.fileOp("PILLS",["LIST"],"",function(param1:Boolean, param2:String):void
         {
            self.listed = true;
            if(!param1)
            {
               self.listFailed = true;
               self.paint();
               self.hsb.note("IMPORT list failed");
               return;
            }
            var rows:Array = param2.length > 0 ? param2.split("\n") : [];
            var i:int = 0;
            while(i < rows.length && self.entries.length < MAX_FILES)
            {
               var bits:Array = String(rows[i]).split("\t");
               if(bits.length >= 2 && String(bits[1]).length > 0) { self.readOne(String(bits[0]),String(bits[1])); }
               i++;
            }
            self.hsb.note("IMPORT list n=" + self.entries.length);
            self.paint();
         });
      }

      private function readOne(param1:String, param2:String):void
      {
         var entry:Object = {"folder":param1,"file":param2,"loading":true,"bad":false};
         this.entries.push(entry);
         this.waiting++;
         var self:HsbPillImport = this;
         this.hsb.fileOp("PILLS",["READ",param1,param2],"",function(param3:Boolean, param4:String):void
         {
            self.waiting--;
            entry.loading = false;
            var data:Object = param3 ? HsbPillModel.readShared(param4) : null;
            if(data == null) { entry.bad = true; }
            else
            {
               entry.kind = data.kind;
               entry.name = data.name;
               entry.author = data.author;
               entry.description = data.description;
               entry.pills = data.pills;
               entry.columnSets = data.columnSets;
            }
            if(self.chosen < 0 && !entry.bad) { self.choose(self.entries.indexOf(entry)); }
            if(self.waiting == 0) { self.hsb.note("IMPORT read bad=" + self.badCount()); }
            self.paint();
         });
      }

      private function badCount():int
      {
         var n:int = 0;
         var i:int = 0;
         while(i < this.entries.length)
         {
            if(this.entries[i].bad == true) { n++; }
            i++;
         }
         return n;
      }

      private function choose(param1:int):void
      {
         this.chosen = param1;
         this.choices = {};
         this.useColumns = false;
         this.rightScroll = 0;
         this.problem = "";
      }

      // "added": the same name and rules are already in the list; "clash": the name is taken.
      private function pillState(param1:Object):String
      {
         var have:Object = this.hsb.pills.byName(String(param1.name));
         if(have == null) { return "new"; }
         if(HsbJson.stringify(have.rules) == HsbJson.stringify(param1.rules) && HsbJson.stringify(have.tabs) == HsbJson.stringify(param1.tabs)) { return "added"; }
         return "clash";
      }

      private function choiceFor(param1:int):String
      {
         return this.choices[param1] != null ? String(this.choices[param1]) : "rename";
      }

      // The pills Add will touch, and how many new list places that needs.
      private function plan():Object
      {
         var e:Object = this.chosen >= 0 ? this.entries[this.chosen] : null;
         var out:Object = {"count":0,"places":0};
         if(e == null || e.bad == true || !(e.pills is Array)) { return out; }
         var list:Array = e.pills as Array;
         var i:int = 0;
         while(i < list.length)
         {
            var s:String = this.pillState(list[i]);
            if(s == "new") { out.count++; out.places++; }
            else if(s == "clash")
            {
               var c:String = this.choiceFor(i);
               if(c == "rename") { out.count++; out.places++; }
               else if(c == "replace") { out.count++; }
            }
            i++;
         }
         return out;
      }

      // ---- paint ---------------------------------------------------------------------------

      internal function paint():void
      {
         this.wipe();
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var w:Number = k.u(662);
         var r:Object = this.hsb.viewRect();
         var h:Number = Math.min(k.u(717),Number(r.height) - 40);
         var pad:Number = 22;
         k.label(this,pad,18,"IMPORT PILLS",18,HsbKit.TEXT,true,3);
         var capW:Number = k.keycap(this,w - pad - k.u(40),16,"ESC",HsbKit.LABEL,k.u(24));
         this.hit(w - pad - capW - 4,12,capW + 8,k.u(32),"close");
         k.label(this,pad,50,"Files found in " + FOLDER_TEXT,13,HsbKit.LABEL,false,0,w - pad * 2);
         var top:Number = 50 + k.u(26);
         k.hline(g,pad,top,w - pad * 2,HsbKit.EDGE,1);
         var footH:Number = k.u(62);
         var bodyTop:Number = top + 12;
         var bodyBottom:Number = h - footH;
         var leftW:Number = k.u(242);
         this.paneX = 12 + leftW + 12;
         k.vline(g,this.paneX,bodyTop + 4,bodyBottom - bodyTop - 8,HsbKit.EDGE,1);
         this.paintLeft(12,bodyTop,leftW,bodyBottom - bodyTop);
         this.paintRight(this.paneX + 20,bodyTop,w - this.paneX - 20 - pad,bodyBottom - bodyTop);
         k.hline(g,0,bodyBottom,w,HsbKit.EDGE,1);
         var fy:Number = bodyBottom + (footH - k.u(30)) / 2;
         var p:Object = this.plan();
         var room:int = HsbPillModel.MAX_PILLS - this.hsb.pills.pills.length;
         var msg:String = this.problem.length > 0 ? this.problem : "Previewing only. Nothing is added until you confirm.";
         if(this.problem.length == 0 && int(p.places) > room) { msg = "Room for " + Math.max(0,room) + " more pills \u00B7 remove some first"; }
         var over:Boolean = int(p.places) > room;
         k.label(this,pad,fy + 6,msg,13,over || this.problem.length > 0 ? HsbKit.ORANGE : HsbKit.MUTED,false,0,w - pad * 2 - k.u(260));
         var addLabel:String = "ADD " + int(p.count) + (int(p.count) == 1 ? " PILL" : " PILLS");
         var addOk:Boolean = int(p.count) > 0 && !over;
         var probe:TextField = k.text(13,0,true,1);
         k.put(probe,addLabel);
         var addW:Number = Math.max(k.u(110),probe.textWidth + 34);
         k.button(this,w - pad - addW,fy,addLabel,addOk ? "accent" : "dim","add",null,k.u(30),addW);
         k.button(this,w - pad - addW - 10 - k.u(86),fy,"CANCEL","outline","cancel",null,k.u(30),k.u(86));
         k.card(this.graphics,0,0,w,h,14);
         this.boxW = w;
         this.boxH = h;
         this.drawFocus();
      }

      private function paintLeft(param1:Number, param2:Number, param3:Number, param4:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var packs:Array = [];
         var singles:Array = [];
         var i:int = 0;
         while(i < this.entries.length)
         {
            var e:Object = this.entries[i];
            if(e.kind == "pack") { packs.push(i); }
            else { singles.push(i); }
            i++;
         }
         var rows:Array = [];
         rows.push({"head":"PACKS","n":packs.length});
         i = 0;
         while(i < packs.length) { rows.push({"at":packs[i]}); i++; }
         rows.push({"head":"PILLS","n":singles.length});
         i = 0;
         while(i < singles.length) { rows.push({"at":singles[i]}); i++; }
         var itemH:Number = k.u(50);
         var headH:Number = k.u(30);
         var y:Number = param2 + 4;
         var bottom:Number = param2 + param4;
         var shown:int = 0;
         var skip:int = this.leftScroll;
         i = 0;
         while(i < rows.length)
         {
            var row:Object = rows[i];
            var rh:Number = row.head != null ? headH : itemH;
            if(skip > 0 && row.head == null)
            {
               skip--;
               i++;
               continue;
            }
            if(y + rh > bottom)
            {
               k.label(this,param1 + 10,bottom - k.u(20),"Scroll for more",12,HsbKit.MUTED);
               break;
            }
            if(row.head != null)
            {
               k.label(this,param1 + 10,y + 6,String(row.head),13,k.accent,true,2);
               var n:TextField = k.text(13,HsbKit.LABEL,false,0,"right");
               k.put(n,String(row.n));
               n.width = 40;
               this.add(n,param1 + param3 - 50,y + 6);
            }
            else
            {
               this.paintEntry(int(row.at),param1,y,param3,itemH);
               shown++;
            }
            y += rh;
            i++;
         }
         this.leftRows = shown;
         if(this.entries.length == 0)
         {
            var note:String = !this.listed ? "Reading the folder\u2026" : (this.listFailed ? "Could not read the folder." : "No pill files found.");
            k.label(this,param1 + 10,y + 4,note,13,this.listFailed ? HsbKit.RED : HsbKit.MUTED,false,0,param3 - 20);
         }
      }

      private function paintEntry(param1:int, param2:Number, param3:Number, param4:Number, param5:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var e:Object = this.entries[param1];
         var sel:Boolean = param1 == this.chosen;
         if(sel)
         {
            k.fill(g,param2,param3 + 2,param4,param5 - 4,8,HsbKit.SELECT,1);
            k.fill(g,param2 - 9,param3 + 10,3,param5 - 20,1.5,k.accent,1);
         }
         var ix:Number = param2 + 12;
         var tx:Number = param2 + 38;
         var title:String;
         var sub:String;
         var ink:uint = HsbKit.TEXT;
         var subInk:uint = HsbKit.MUTED;
         if(e.loading == true)
         {
            title = String(e.file);
            sub = "Reading\u2026";
            k.icon(g,"dot",ix,param3 + 10,14,HsbKit.DIM,1);
         }
         else if(e.bad == true)
         {
            title = String(e.file);
            sub = "Can't read \u00B7 skipped";
            ink = HsbKit.RED;
            subInk = HsbKit.RED;
            k.icon(g,"xCircle",ix - 2,param3 + 8,20,HsbKit.RED,1);
         }
         else
         {
            title = String(e.name);
            var list:Array = e.pills as Array;
            if(e.kind == "pack")
            {
               k.icon(g,"pack",ix - 2,param3 + 8,20,k.accent,1);
               sub = list.length + (list.length == 1 ? " pill" : " pills") + (String(e.author).length > 0 ? " \u00B7 by " + String(e.author) : "");
            }
            else
            {
               k.icon(g,"diamond",ix,param3 + 10,14,k.accent,1);
               var state:String = this.pillState(list[0]);
               var tabs:Array = list[0].tabs as Array;
               sub = state == "added" ? "Already added" : this.browser.tabNameFor(tabs != null && tabs.length > 0 ? String(tabs[0]) : "*") + (String(e.author).length > 0 ? " \u00B7 by " + String(e.author) : "");
            }
         }
         k.label(this,tx,param3 + 6,title,14,ink,sel,0,param4 - 48);
         k.label(this,tx,param3 + 6 + k.u(20),sub,13,subInk,false,0,param4 - 48);
         if(e.loading != true && e.bad != true) { this.hit(param2,param3 + 2,param4,param5 - 4,"entry",param1); }
      }

      private function paintRight(param1:Number, param2:Number, param3:Number, param4:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var e:Object = this.chosen >= 0 ? this.entries[this.chosen] : null;
         var y:Number = param2 + 4;
         var bottom:Number = param2 + param4;
         if(e == null || e.bad == true || e.loading == true)
         {
            k.label(this,param1,y + 4,this.entries.length > 0 ? "Pick a file on the left to preview it." : "Put pill or pack files in the folder above, then open this again.",13,HsbKit.MUTED,false,0,param3);
            return;
         }
         var list:Array = e.pills as Array;
         var t:TextField = k.label(this,param1,y,String(e.name),18,HsbKit.TEXT,true,0,param3);
         y += t.height + 2;
         var bits:Array = [];
         if(String(e.author).length > 0) { bits.push("by " + String(e.author)); }
         bits.push(list.length + (list.length == 1 ? " pill" : " pills"));
         var setCount:int = 0;
         var key:String;
         if(e.columnSets != null) { for(key in e.columnSets) { setCount++; } }
         if(setCount > 0) { bits.push(setCount + (setCount == 1 ? " column set" : " column sets")); }
         var by:TextField = k.label(this,param1,y,bits.join(" \u00B7 "),13,HsbKit.LABEL,false,0,param3);
         y += by.height + 4;
         if(String(e.description).length > 0)
         {
            var d:TextField = k.text(14,HsbKit.LABEL);
            d.multiline = true;
            d.wordWrap = true;
            d.width = param3;
            k.put(d,String(e.description));
            d.height = Math.min(d.textHeight + 6,k.u(64));
            this.add(d,param1,y);
            y += d.height + 6;
         }
         k.label(this,param1,y + 4,"PILLS",13,k.accent,true,2);
         y += k.u(26);
         // Mockup 3 fits four pill cards (one with a name clash) above the column sets; a card
         // that does not fit, with room left for the "more" line, waits for the scroll.
         var cardH:Number = k.u(58);
         var colsH:Number = setCount > 0 ? k.u(26) + setCount * k.u(19) + k.u(34) : 0;
         var limit:Number = bottom - colsH;
         var shown:int = 0;
         var i:int = this.rightScroll;
         while(i < list.length)
         {
            var state:String = this.pillState(list[i]);
            var need:Number = cardH + (state == "clash" ? k.u(34) : 0) + 8;
            var moreH:Number = i < list.length - 1 ? k.u(22) : 0;
            if(y + need + moreH > limit && shown > 0)
            {
               k.label(this,param1,y,(list.length - i) + " more \u00B7 scroll",12,HsbKit.MUTED);
               y += k.u(22);
               break;
            }
            this.paintPillCard(i,list[i],state,param1,y,param3,cardH);
            y += need;
            shown++;
            i++;
         }
         this.rightRows = shown;
         if(setCount > 0)
         {
            y += 2;
            k.label(this,param1,y,"COLUMNS",13,k.accent,true,2);
            y += k.u(22);
            for(key in e.columnSets)
            {
               var cols:Array = e.columnSets[key] as Array;
               var names:Array = [];
               var c:int = 0;
               while(c < cols.length) { names.push(this.browser.columnLabel(String(cols[c]))); c++; }
               k.label(this,param1,y,this.browser.tabNameFor(key) + ": " + names.join(", "),13,HsbKit.LABEL,false,0,param3);
               y += k.u(19);
            }
            y += 4;
            k.toggle(g,param1,y + 2,this.useColumns);
            // Mockup 3 says "Your own column sets stay unless you choose to use these."; the switch
            // is that choice, so its label names what turning it on does.
            k.label(this,param1 + k.u(38) + 10,y,"Use these column sets instead of yours",13,this.useColumns ? HsbKit.LABEL : HsbKit.MUTED,false,0,param3 - k.u(48));
            this.hit(param1 - 4,y - 4,param3 + 8,k.u(28),"usecols");
         }
      }

      private function paintPillCard(param1:int, param2:Object, param3:String, param4:Number, param5:Number, param6:Number, param7:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var clash:Boolean = param3 == "clash";
         var totalH:Number = param7 + (clash ? k.u(34) : 0);
         k.fill(g,param4 - 8,param5,param6 + 8,param7,8,HsbKit.ROW,1);
         if(clash)
         {
            k.fill(g,param4 - 8,param5 + param7,param6 + 8,totalH - param7,8,HsbKit.ORANGE_BG,0.6);
            k.outline(g,param4 - 8,param5,param6 + 8,totalH,8,HsbKit.ORANGE,1);
         }
         if(clash)
         {
            // Mockup 3: an orange WARNING tag sits on the clash card's top edge.
            var warn:TextField = k.text(12,HsbKit.ORANGE,true,1.5);
            k.put(warn,"WARNING");
            k.fit(warn);
            var tagH:Number = k.u(22);
            var tagW:Number = 26 + warn.width + 8;
            var tagY:Number = param5 - tagH / 2;
            k.fill(g,param4,tagY,tagW,tagH,tagH / 2,HsbKit.ORANGE_BG,1);
            k.outline(g,param4,tagY,tagW,tagH,tagH / 2,HsbKit.ORANGE,1);
            k.icon(g,"alert",param4 + 7,tagY + (tagH - 13) / 2,13,HsbKit.ORANGE,1);
            this.add(warn,param4 + 24,tagY + (tagH - warn.height) / 2);
         }
         var top:Number = param5 + (clash ? 13 : 9);
         k.icon(g,"diamond",param4 + 2,top + 4,12,k.accent,1);
         var nm:TextField = k.label(this,param4 + 20,top,String(param2.name),14,HsbKit.TEXT,true,0,param6 * 0.5);
         var tabs:Array = param2.tabs as Array;
         var tabKey:String = tabs != null && tabs.length > 0 ? String(tabs[0]) : "*";
         k.label(this,nm.x + nm.width + 4,top + 1,this.browser.tabNameFor(tabKey),13,HsbKit.MUTED,false,0,param6 * 0.3);
         var here:Boolean = tabs == null || tabs.indexOf("*") >= 0 || tabs.indexOf(this.browser.tabKeyNow()) >= 0;
         var mt:TextField = k.text(13,param3 == "added" ? HsbKit.MUTED : HsbKit.GREEN,true,0,"right");
         k.put(mt,param3 == "added" ? "Already added" : (here ? "Matches " + this.browser.countMatches(param2) : "Other tab"));
         mt.width = 140;
         this.add(mt,param4 + param6 - 140 - 8,top + 1);
         k.label(this,param4 + 20,top + k.u(24),HsbPillModel.summary(param2,this.browser.statNames()),13,HsbKit.LABEL,false,0,param6 - 30);
         if(!clash) { return; }
         var ay:Number = param5 + param7 + (k.u(34) - k.u(26)) / 2;
         var opts:Array = ["RENAME","REPLACE","SKIP"];
         var pick:int = opts.indexOf(this.choiceFor(param1).toUpperCase());
         var right:Number = param4 + param6 - 4;
         var note:String = "Name already used";
         var segPad:Number = 20;
         var segSpace:Number = 1.2;
         // The large movie's wider face runs out of room first: tighter segments, then a
         // shorter note, so the choice never leaves the card.
         var probe:TextField = k.text(13,HsbKit.ORANGE,true);
         k.put(probe,note);
         k.fit(probe);
         var room:Number = right - (param4 + 2 + probe.width + 10);
         if(k.segmentsWidth(opts) > room) { segPad = 14; segSpace = 0.6; }
         if(k.segmentsWidth(opts,segPad,segSpace) > room) { note = "Name used"; }
         var tag:TextField = k.label(this,param4 + 2,ay + 4,note,13,HsbKit.ORANGE,true);
         var sw:Number = k.segmentsWidth(opts,segPad,segSpace);
         var sx:Number = Math.max(tag.x + tag.width + 10,right - sw);
         k.segments(this,sx,ay,opts,pick,"choice",k.u(26),true,segPad,segSpace);
         // segments() records each option with its index; the pill index rides in the id.
         var i:int = this.hits.length - 1;
         var n:int = 0;
         while(i >= 0 && n < opts.length)
         {
            if(String(this.hits[i].id) == "choice") { this.hits[i].data = {"pill":param1,"pick":int(this.hits[i].data)}; }
            i--;
            n++;
         }
      }

      // ---- input ---------------------------------------------------------------------------

      override internal function onWheel(param1:Number, param2:Number, param3:Number):void
      {
         var lx:Number = this.localX(param2);
         if(lx < this.paneX)
         {
            this.leftScroll = HorizonShipBuilder.clampInt(this.leftScroll - int(param1),0,Math.max(0,this.entries.length - 1));
         }
         else
         {
            var e:Object = this.chosen >= 0 ? this.entries[this.chosen] : null;
            var n:int = e != null && e.pills is Array ? (e.pills as Array).length : 0;
            this.rightScroll = HorizonShipBuilder.clampInt(this.rightScroll - int(param1),0,Math.max(0,n - 1));
         }
         this.paint();
      }

      override internal function onKey(param1:String):Boolean
      {
         if(param1 == "cancel") { return false; }
         if(param1 == "ok" && this.focusedHit() == null)
         {
            this.addChosen();
            return true;
         }
         if(param1 == "pgdn" || param1 == "pgup")
         {
            this.onWheel(param1 == "pgdn" ? -3 : 3,this.x + this.paneX + 10,this.y);
            return true;
         }
         return this.navKey(param1);
      }

      override internal function onAct(param1:String, param2:*):void
      {
         switch(param1)
         {
            case "close":
            case "cancel":
               this.hsb.closePop(this,false);
               return;
            case "entry":
               this.choose(int(param2));
               break;
            case "choice":
               var opts:Array = ["rename","replace","skip"];
               this.choices[int(param2.pill)] = String(opts[int(param2.pick)]);
               break;
            case "usecols":
               this.useColumns = !this.useColumns;
               break;
            case "add":
               this.addChosen();
               return;
         }
         this.problem = "";
         this.paint();
      }

      private function addChosen():void
      {
         var e:Object = this.chosen >= 0 ? this.entries[this.chosen] : null;
         var p:Object = this.plan();
         var model:HsbPillModel = this.hsb.pills;
         if(e == null || int(p.count) == 0) { return; }
         if(int(p.places) > HsbPillModel.MAX_PILLS - model.pills.length)
         {
            this.paint();
            return;
         }
         var list:Array = e.pills as Array;
         var added:int = 0;
         var replaced:int = 0;
         var i:int = 0;
         while(i < list.length)
         {
            var src:Object = HsbPillModel.clean(list[i]);
            var state:String = this.pillState(list[i]);
            var how:String = state == "clash" ? this.choiceFor(i) : (state == "new" ? "rename" : "skip");
            if(src != null && how == "replace")
            {
               var old:Object = model.byName(String(src.name));
               var at:int = model.pills.indexOf(old);
               src.id = String(old.id);
               if(at >= 0) { model.pills[at] = src; replaced++; }
            }
            else if(src != null && how == "rename")
            {
               src.name = model.freeName(String(src.name));
               src.id = model.newId();
               model.pills.push(src);
               added++;
            }
            i++;
         }
         if(this.useColumns && e.columnSets != null)
         {
            var key:String;
            for(key in e.columnSets)
            {
               var cols:String = (e.columnSets[key] as Array).join(",");
               this.hsb.columnSets[key] = cols;
               this.hsb.setSetting("Columns",key,cols);
            }
            this.hsb.saveSettings();
         }
         this.hsb.savePills();
         this.browser.afterPills();
         this.hsb.note("IMPORT added n=" + added + " replaced=" + replaced + " cols=" + (this.useColumns ? 1 : 0));
         this.hsb.closePop(this,true);
      }
   }
}
