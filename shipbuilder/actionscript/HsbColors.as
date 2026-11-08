package
{
   import flash.display.Graphics;
   import flash.text.TextField;

   // Purpose: the Colors panel from gold mockups 6 and 7, in the browser's slot while the game's
   //    colour mode is open: the current colour of each slot, a slider editor per slot, colour
   //    schemes (starter, yours, imported) with preview, accept, cancel, save, import and export.
   // Inputs: ColorInitializationData (slot tabs), ColorSelectionData (selected slot, control
   //    and its hue, saturation and brightness), ColorSwatchesHue/Saturation/Brightness (the
   //    game's own slider gradients), ColorSwatchesRecentUI; scheme files via the DLL.
   // Outputs: the vanilla picker's own events: ShipEditor_OnColorPickerTabChanged {tabIndex},
   //    ShipEditor_OnColorPickerControlChanged {control}, ShipEditor_OnColorSliderMouseInput
   //    {sliderValue 0..1}, ShipEditor_OnRecentColorSwatchClicked {swatchIndex}; Accept goes
   //    through the game's hint (ShipEditor_OnHintButtonActivated). Scheme files are written to
   //    Data\Interface\HorizonUI\shipbuilder\schemes\user\ by the DLL, each as a new file.
   // Dependencies: HorizonShipBuilder (send, fileOp, writeShare, keyName, hintEvent, text
   //    input), HsbKit.
   // Backend limits shown in the panel: the game has no "apply to" choice (colours go to the
   //    parts selected before colour mode) and no "take from a part"; hex values are worked
   //    out from hue, saturation and brightness (marked with ~). Applying a scheme steps the
   //    picker through its slots one frame at a time, waits for the game to confirm each slot
   //    switch, then returns to the slot and control the player had, also when the walk starts
   //    while another is still running.
   // Author: Moragar. Last modified: 2026-11-08.
   public class HsbColors extends HsbBox
   {
      private static const HUE:int = 0;
      private static const SATURATION:int = 1;
      private static const BRIGHTNESS:int = 2;
      private static const RECENT:int = 3;
      private static const TAB_WAIT_FRAMES:int = 20;
      private static const SCHEME_FOLDER:String = "Data\\Interface\\HorizonUI\\shipbuilder\\schemes\\user\\";
      private static const NAME_MAX:int = 32;
      private static const STARTERS:Array = [["Frontier blue",[0x2E5E8C,0xE4E8EC,0x2B3036]],["Militia red",[0xA8322D,0xD9D4CC,0x2B2B2E]],["Stealth black",[0x1E2124,0x3A3D33,0x7A7F85]],["Corporate white",[0xF0F2F4,0x9EA4AA,0xC9A43A]]];

      private var hsb:HorizonShipBuilder;
      private var tabs:Array;
      private var sel:Object;
      private var slots:Object;
      private var recent:Array;
      private var grads:Object;
      private var schemes:Array;
      private var chosen:int = -1;
      internal var previewing:Boolean = false;
      private var before:Object;
      private var exported:Object;
      private var steps:Array;
      private var waitTab:int = -1;
      private var waitUntil:int = 0;
      // The slot and control the player had when the running walk began. While a walk runs, sel
      // shows the slot the walk is on, so a walk started then must not take its way home from sel.
      private var walkHome:int = 0;
      private var walkCtl:int = HUE;
      private var openSlot:int = -1;
      private var naming:Boolean = false;
      private var nameText:String = "";
      private var listed:Boolean = false;
      private var note1:String = "";
      private var scroll:int = 0;
      private var rowsShown:int = 0;
      private var sliderKind:int = -1;
      private var sliderX:Number = 0;
      private var sliderW:Number = 0;
      private var pendingValue:Number = -1;
      private var wasOn:Boolean = false;

      public function HsbColors(param1:HsbKit, param2:HorizonShipBuilder)
      {
         super(param1,"HsbColors");
         this.hsb = param2;
         this.tabs = [];
         this.slots = {};
         this.recent = [];
         this.grads = {};
         this.steps = [];
         this.schemes = [];
         var i:int = 0;
         while(i < STARTERS.length)
         {
            var cols:Array = STARTERS[i][1] as Array;
            this.schemes.push({"name":String(STARTERS[i][0]),"source":"starter","author":"","file":"","slots":[HsbKit.toHsb(uint(cols[0])),HsbKit.toHsb(uint(cols[1])),HsbKit.toHsb(uint(cols[2]))]});
            i++;
         }
         this.boxW = param1.lrg ? 560 : 501;
         this.boxH = 400;
      }

      // ---- game data -----------------------------------------------------------------------

      internal function onInit(param1:Object):void
      {
         var list:Array = param1.aTabs as Array;
         this.tabs = [];
         var i:int = 0;
         while(list != null && i < list.length)
         {
            var t:TextField = this.kit.text(13,0);
            this.kit.put(t,list[i].sText);
            this.tabs.push({"text":t.text,"enabled":list[i].bEnabled != false});
            i++;
         }
         var start:Object = param1.aSelection;
         if(start != null) { this.onSelection(start); }
         if(Boolean(param1.bVisible) || this.tabs.length > 0) { this.discover(); }
      }

      internal function onSelection(param1:Object):void
      {
         this.sel = param1;
         var tab:int = int(param1.iSelectedTab);
         // ColorInitializationData.aSelection carries only the tab and control (vanilla reads
         // nothing else), so a slot colour is kept only when all three values are numbers.
         var hsbNow:Array = [Number(param1.fHue),Number(param1.fSaturation),Number(param1.fBrightness)];
         if(!isNaN(hsbNow[0]) && !isNaN(hsbNow[1]) && !isNaN(hsbNow[2])) { this.slots[tab] = hsbNow; }
         if(this.waitTab >= 0 && tab == this.waitTab) { this.waitTab = -1; }
      }

      internal function onRecent(param1:Array):void
      {
         this.recent = param1 != null ? param1 : [];
      }

      internal function onGradient(param1:int, param2:Array):void
      {
         this.grads[param1] = param2;
      }

      // Learn every slot's colour once: visit each slot, then return to the one in use.
      private function discover():void
      {
         if(this.tabs.length == 0) { return; }
         if(!this.walking()) { this.walkHome = this.sel != null ? int(this.sel.iSelectedTab) : 0; }
         var home:int = this.walkHome;
         this.steps = [];
         var i:int = 0;
         while(i < this.tabs.length)
         {
            if(i != home && this.tabs[i].enabled == true && this.slots[i] == null) { this.steps.push({"kind":"tab","v":i}); }
            i++;
         }
         if(this.steps.length > 0) { this.steps.push({"kind":"tab","v":home}); }
         if(!this.listed) { this.loadSchemes(); }
      }

      private function walking():Boolean
      {
         return this.steps.length > 0 || this.waitTab >= 0;
      }

      // One queued step per frame; a slot switch waits for the game's confirmation.
      internal function tick():void
      {
         var on:Boolean = this.visible;
         if(!on && this.wasOn) { this.closed(); }
         this.wasOn = on;
         if(this.pendingValue >= 0)
         {
            this.hsb.send("ShipEditor_OnColorSliderMouseInput",{"sliderValue":this.pendingValue});
            this.pendingValue = -1;
         }
         if(this.waitTab >= 0)
         {
            if(this.hsb.frame() < this.waitUntil) { return; }
            this.hsb.note("COLORS slot wait timeout");
            this.waitTab = -1;
         }
         if(this.steps.length == 0) { return; }
         var s:Object = this.steps.shift();
         if(s.kind == "tab")
         {
            this.hsb.send("ShipEditor_OnColorPickerTabChanged",{"tabIndex":int(s.v)});
            if(this.sel == null || int(this.sel.iSelectedTab) != int(s.v))
            {
               this.waitTab = int(s.v);
               this.waitUntil = this.hsb.frame() + TAB_WAIT_FRAMES;
            }
         }
         else if(s.kind == "ctl") { this.hsb.send("ShipEditor_OnColorPickerControlChanged",{"control":int(s.v)}); }
         else if(s.kind == "val") { this.hsb.send("ShipEditor_OnColorSliderMouseInput",{"sliderValue":Number(s.v)}); }
         if(this.steps.length == 0) { this.hsb.mark("Colors"); }
      }

      private function closed():void
      {
         this.previewing = false;
         this.steps = [];
         this.waitTab = -1;
         this.openSlot = -1;
         this.naming = false;
         this.exported = null;
         this.slots = {};
         if(this.hsb.textActive(this)) { this.hsb.endText(this); }
      }

      // ---- schemes -------------------------------------------------------------------------

      private function loadSchemes():void
      {
         this.listed = true;
         var self:HsbColors = this;
         this.hsb.fileOp("SCHEMES",["LIST"],"",function(param1:Boolean, param2:String):void
         {
            if(!param1) { self.note1 = "Could not read the schemes folder"; self.hsb.mark("Colors"); return; }
            var rows:Array = param2.length > 0 ? param2.split("\n") : [];
            var i:int = 0;
            while(i < rows.length && i < 40)
            {
               var bits:Array = String(rows[i]).split("\t");
               if(bits.length >= 2) { self.readScheme(String(bits[0]),String(bits[1])); }
               i++;
            }
            self.hsb.note("SCHEMES list n=" + Math.min(rows.length,40));
         });
      }

      private function readScheme(param1:String, param2:String):void
      {
         var self:HsbColors = this;
         this.hsb.fileOp("SCHEMES",["READ",param1,param2],"",function(param3:Boolean, param4:String):void
         {
            var s:Object = param3 ? parseScheme(param4) : null;
            if(s == null) { return; }
            s.source = param1 == "user" ? "user" : "pack";
            s.file = param2;
            var at:int = self.schemeByName(String(s.name));
            if(at >= 0 && String(self.schemes[at].source) != "starter") { self.schemes[at] = s; }
            else if(at < 0) { self.schemes.push(s); }
            self.hsb.mark("Colors");
         });
      }

      private function schemeByName(param1:String):int
      {
         var i:int = 0;
         while(i < this.schemes.length)
         {
            if(String(this.schemes[i].name).toLowerCase() == param1.toLowerCase()) { return i; }
            i++;
         }
         return -1;
      }

      // [Scheme] Name=..., Author=..., Slot1..Slot3=hue,saturation,brightness (0..1 each).
      internal static function parseScheme(param1:String):Object
      {
         if(param1 == null || param1.length == 0 || param1.length > 4000) { return null; }
         var lines:Array = param1.split("\r").join("").split("\n");
         var out:Object = {"name":"","author":"","slots":[]};
         var i:int = 0;
         while(i < lines.length)
         {
            var line:String = HsbPillModel.trim(String(lines[i]));
            var eq:int = line.indexOf("=");
            if(eq > 0 && line.charAt(0) != ";" && line.charAt(0) != "#")
            {
               var key:String = HsbPillModel.trim(line.substring(0,eq)).toLowerCase();
               var val:String = HsbPillModel.trim(line.substring(eq + 1));
               if(key == "name") { out.name = val.substring(0,NAME_MAX); }
               else if(key == "author") { out.author = val.substring(0,32); }
               else if(key.indexOf("slot") == 0)
               {
                  var n:int = int(key.substring(4)) - 1;
                  var parts:Array = val.split(",");
                  if(n >= 0 && n < 3 && parts.length == 3)
                  {
                     var hsb3:Array = [Number(parts[0]),Number(parts[1]),Number(parts[2])];
                     if(!isNaN(hsb3[0]) && !isNaN(hsb3[1]) && !isNaN(hsb3[2])) { (out.slots as Array)[n] = [clamp01(hsb3[0]),clamp01(hsb3[1]),clamp01(hsb3[2])]; }
                  }
               }
            }
            i++;
         }
         var slots:Array = out.slots as Array;
         if(String(out.name).length == 0 || slots.length == 0 || slots[0] == null) { return null; }
         return out;
      }

      internal static function schemeText(param1:Object):String
      {
         var out:String = "[Scheme]\nName=" + String(param1.name) + "\n";
         if(String(param1.author).length > 0) { out += "Author=" + String(param1.author) + "\n"; }
         var slots:Array = param1.slots as Array;
         var i:int = 0;
         while(i < slots.length)
         {
            if(slots[i] != null) { out += "Slot" + (i + 1) + "=" + Number(slots[i][0]).toFixed(4) + "," + Number(slots[i][1]).toFixed(4) + "," + Number(slots[i][2]).toFixed(4) + "\n"; }
            i++;
         }
         return out;
      }

      private static function clamp01(param1:Number):Number
      {
         if(isNaN(param1)) { return 0; }
         return param1 < 0 ? 0 : (param1 > 1 ? 1 : param1);
      }

      private function currentSlots():Array
      {
         var out:Array = [];
         var i:int = 0;
         while(i < Math.max(1,this.tabs.length) && i < 3)
         {
            out.push(this.slots[i] != null ? (this.slots[i] as Array).slice() : null);
            i++;
         }
         return out;
      }

      // Queue the vanilla picker inputs that set every slot of a scheme, then return to the slot
      // and control the player had.
      private function applySlots(param1:Array):void
      {
         if(!this.walking())
         {
            this.walkHome = this.sel != null ? int(this.sel.iSelectedTab) : 0;
            this.walkCtl = this.sel != null ? int(this.sel.iSelectedControl) : HUE;
         }
         var home:int = this.walkHome;
         var ctl:int = this.walkCtl;
         this.steps = [];
         var i:int = 0;
         while(i < param1.length && i < this.tabs.length)
         {
            var c:Array = param1[i] as Array;
            if(c != null && this.tabs[i].enabled == true)
            {
               this.steps.push({"kind":"tab","v":i});
               var k:int = 0;
               while(k < 3)
               {
                  this.steps.push({"kind":"ctl","v":k});
                  this.steps.push({"kind":"val","v":clamp01(Number(c[k]))});
                  k++;
               }
            }
            i++;
         }
         this.steps.push({"kind":"tab","v":home});
         this.steps.push({"kind":"ctl","v":ctl});
      }

      private function preview(param1:int):void
      {
         var s:Object = this.schemes[param1];
         if(s == null) { return; }
         if(!this.previewing) { this.before = {"slots":this.currentSlots()}; }
         this.previewing = true;
         this.chosen = param1;
         this.exported = null;
         this.applySlots(s.slots as Array);
         this.hsb.note("COLORS preview scheme=" + param1);
      }

      private function cancelPreview():void
      {
         if(this.previewing && this.before != null) { this.applySlots(this.before.slots as Array); }
         this.previewing = false;
         this.before = null;
         this.hsb.note("COLORS preview cancel");
      }

      private function acceptPreview():void
      {
         var ev:String = this.hsb.hintEvent(["Accept","ConfirmColor","Confirm"]);
         this.previewing = false;
         this.before = null;
         if(ev.length > 0) { this.hsb.sendHint(ev); }
         this.hsb.note("COLORS accept hint=" + (ev.length > 0 ? 1 : 0));
      }

      private function saveScheme(param1:String):void
      {
         var name:String = HsbPillModel.trim(param1).substring(0,NAME_MAX);
         if(name.length == 0) { return; }
         var s:Object = {"name":name,"source":"user","author":"","file":"","slots":this.currentSlots()};
         this.writeScheme(s,true);
      }

      // Purpose: write a scheme to schemes\user as a new file (HorizonShipBuilder.writeShare).
      // Inputs: the scheme; whether the list keeps it as one of the player's own. Outputs: the
      //    exported box (mockup 7) or a failure note.
      // Rule: a scheme file is never replaced. A name already taken gets the next number, in
      //    the file and the scheme alike (Name=Desert 2 in Desert 2.ini), and a scheme the list
      //    keeps also skips the names already in the list.
      private function writeScheme(param1:Object, param2:Boolean):void
      {
         var self:HsbColors = this;
         var base:String = String(param1.name);
         var nameFor:Function = function(param3:int):String { return HorizonShipBuilder.numberedName(base,param3,NAME_MAX); };
         var first:int = 1;
         while(param2 && first < HorizonShipBuilder.SHARE_TRIES && this.schemeByName(nameFor(first)) >= 0) { first++; }
         this.hsb.writeShare("SCHEMES",".ini",first,function(param3:int):String { return HsbDialog.safeFileName(nameFor(param3)); },
            function(param3:int):String { return schemeText({"name":nameFor(param3),"author":param1.author,"slots":param1.slots}); },
            function(param3:Boolean, param4:String, param5:int):void
         {
            if(!param3)
            {
               self.note1 = param5 < 0 ? "Not saved: " + HorizonShipBuilder.SHARE_TRIES + " scheme files already use this name" : "Could not save the scheme file";
               self.hsb.mark("Colors");
               self.hsb.note("SCHEMES write failed" + (param5 < 0 ? ", every name taken" : ""));
               return;
            }
            var written:String = nameFor(param5);
            if(param2)
            {
               param1.name = written;
               param1.file = param4;
               var at:int = self.schemeByName(written);
               if(at >= 0 && String(self.schemes[at].source) != "starter") { self.schemes[at] = param1; }
               else { self.schemes.push(param1); at = self.schemes.length - 1; }
               self.chosen = at;
            }
            self.exported = {"name":written,"file":param4};
            self.note1 = "";
            self.hsb.mark("Colors");
            self.hsb.note("SCHEMES write ok" + (param5 > 1 ? " numbered" : ""));
         });
      }

      // ---- paint ---------------------------------------------------------------------------

      internal function paint():void
      {
         this.wipe();
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var w:Number = k.lrg ? 560 : 501;
         var h:Number = this.hsb.browser != null ? this.hsb.browser.fitHeight() : 846;
         var pad:Number = 18;
         var y:Number = 18;
         k.label(this,pad,y,"COLORS",17,HsbKit.TEXT,true,3);
         if(this.previewing)
         {
            var pv:TextField = k.text(13,HsbKit.ORANGE,true,1.5);
            k.put(pv,"PREVIEW");
            k.fit(pv);
            var pw:Number = 26 + pv.width + 10;
            var ph:Number = k.u(24);
            k.fill(g,w - pad - pw,y,pw,ph,ph / 2,HsbKit.ORANGE_BG,1);
            k.outline(g,w - pad - pw,y,pw,ph,ph / 2,HsbKit.ORANGE,1);
            k.icon(g,"dot",w - pad - pw + 7,y + (ph - 14) / 2,14,HsbKit.ORANGE,1);
            this.add(pv,w - pad - pw + 24,y + (ph - pv.height) / 2);
         }
         else if(this.hsb.dModule != null)
         {
            var part:TextField = k.text(13,HsbKit.LABEL,false,0,"right");
            k.put(part,this.hsb.dModule.sModuleName);
            part.width = w - pad * 2 - k.u(120);
            this.add(part,w - pad - part.width,y + 4);
         }
         y += k.u(42);
         var applyL:TextField = k.label(this,pad,y + 4,"APPLY TO",13,k.accent,true,2);
         // The segments must clear the label (mockup 6); the short set is for long translations
         // and the large movie.
         var room:Number = w - pad * 2 - applyL.width - 12;
         var labels:Array = ["SELECTED PART","ALL OF TYPE","WHOLE SHIP"];
         var segPad:Number = 20;
         var segSpace:Number = 1.2;
         if(this.kit.segmentsWidth(labels) > room) { segPad = 16; segSpace = 0.6; }
         if(this.kit.segmentsWidth(labels,segPad,segSpace) > room) { labels = ["PART","TYPE","SHIP"]; segPad = 20; segSpace = 1.2; }
         var segW:Number = this.kit.segmentsWidth(labels,segPad,segSpace);
         k.segments(this,w - pad - segW,y,labels,-1,"applyto",k.u(26),false,segPad,segSpace);
         y += k.u(30);
         k.label(this,pad,y,"Not in the game: colors go to the parts you selected before Colors",12,HsbKit.ORANGE,false,0,w - pad * 2);
         y += k.u(24);
         k.label(this,pad,y,"CURRENT COLORS",13,k.accent,true,2);
         var hint:TextField = k.text(13,HsbKit.LABEL,false,0,"right");
         k.put(hint,"Click a color to change it");
         hint.width = 240;
         this.add(hint,w - pad - 240,y);
         y += k.u(22);
         y = this.paintSlots(pad,y,w - pad * 2);
         if(this.openSlot >= 0) { y = this.paintEditor(pad,y,w - pad * 2); }
         y += 10;
         if(this.naming)
         {
            var fw:Number = w - pad * 2 - k.u(170);
            var fh:Number = k.u(28);
            k.fill(g,pad,y,fw,fh,6,HsbKit.FIELD,1);
            k.outline(g,pad,y,fw,fh,6,k.accent,1);
            k.label(this,pad + 10,y + (fh - k.u(22)) / 2,this.nameText.length > 0 ? this.nameText + "|" : "|",14,HsbKit.TEXT,false,0,fw - 20);
            var nx:Number = pad + fw + 8;
            nx += k.button(this,nx,y,"SAVE","accent","namesave",null,fh) + 6;
            k.button(this,nx,y,"CANCEL","outline","namecancel",null,fh);
            y += fh + 14;
         }
         else
         {
            var bx:Number = pad;
            var known:Boolean = this.allKnown();
            bx += this.iconButton(bx,y,"save","SAVE AS SCHEME",known ? "save" : "") + 10;
            var tw:Number = this.iconButton(bx,y,"dropper","TAKE FROM A PART","");
            var gap:TextField = k.label(this,bx + tw + 8,y + 6,"No game data",12,HsbKit.ORANGE);
            var below:Boolean = gap.x + gap.width > w - pad;
            // The gap marker goes under its button when it would cross the card's edge.
            if(below) { gap.x = bx; gap.y = y + k.u(26) + 4; }
            y += k.u(26) + 16 + (below ? gap.height + 2 : 0);
         }
         k.hline(g,pad,y,w - pad * 2,HsbKit.EDGE,1);
         y += 14;
         var sl:TextField = k.label(this,pad,y + 4,"SCHEMES",13,k.accent,true,2);
         k.label(this,pad + sl.width + 10,y + 4,String(this.schemes.length),13,HsbKit.LABEL);
         var ex:Number = w - pad - this.iconButtonWidth("EXPORT");
         this.iconButton(ex,y,"export","EXPORT","export");
         this.iconButton(ex - 10 - this.iconButtonWidth("IMPORT"),y,"import","IMPORT","import");
         y += k.u(26) + 14;
         var boxH:Number = this.previewing || this.exported != null || this.note1.length > 0 ? k.u(132) : 0;
         var listBottom:Number = h - 16 - boxH;
         var rowH:Number = k.u(52);
         this.rowsShown = Math.max(1,int((listBottom - y) / rowH));
         this.scroll = HorizonShipBuilder.clampInt(this.scroll,0,Math.max(0,this.schemes.length - this.rowsShown));
         var i:int = this.scroll;
         var drawn:int = 0;
         while(i < this.schemes.length && drawn < this.rowsShown)
         {
            this.paintScheme(i,10,y,w - 20,rowH - 4);
            y += rowH;
            drawn++;
            i++;
         }
         if(this.schemes.length > this.rowsShown)
         {
            var more:TextField = k.text(12,HsbKit.MUTED,false,0,"right");
            k.put(more,(this.scroll + 1) + "\u2013" + (this.scroll + drawn) + " of " + this.schemes.length + " \u00B7 scroll");
            more.width = 200;
            this.add(more,w - pad - 200,listBottom - k.u(18));
         }
         if(boxH > 0) { this.paintBox(10,h - 12 - boxH,w - 20,boxH); }
         k.card(this.graphics,0,0,w,h);
         this.boxW = w;
         this.boxH = h;
         this.drawFocus();
      }

      private function allKnown():Boolean
      {
         if(this.tabs.length == 0) { return false; }
         var i:int = 0;
         while(i < this.tabs.length && i < 3)
         {
            if(this.tabs[i].enabled == true && this.slots[i] == null) { return false; }
            i++;
         }
         return true;
      }

      // The width iconButton draws for a label: inset, icon, gap, caps text at 1.5 letter
      // spacing, inset. Used to right-align EXPORT and IMPORT before they are drawn.
      private function iconButtonWidth(param1:String):Number
      {
         var t:TextField = this.kit.text(13,0,true,1.5);
         this.kit.put(t,param1);
         return 12 + 16 + 8 + Math.max(4,t.textWidth + 6) + 12;
      }

      // Accent-outlined caps button with an icon; an empty id draws it unavailable.
      private function iconButton(param1:Number, param2:Number, param3:String, param4:String, param5:String):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var live:Boolean = param5.length > 0;
         var bw:Number = this.iconButtonWidth(param4);
         var bh:Number = k.u(26);
         k.fill(g,param1,param2,bw,bh,bh / 2,0x14191E,1);
         k.outline(g,param1,param2,bw,bh,bh / 2,live ? k.accent : HsbKit.EDGE_HI,1);
         k.icon(g,param3,param1 + 12,param2 + (bh - 16) / 2,16,live ? k.accent : HsbKit.DIM,1);
         k.label(this,param1 + 36,param2 + (bh - k.u(20)) / 2,param4,13,live ? HsbKit.TEXT : HsbKit.DIM,true,1.5);
         if(live) { this.hit(param1,param2,bw,bh,param5); }
         return bw;
      }

      private function slotColor(param1:int):int
      {
         var c:Array = this.slots[param1] as Array;
         return c == null ? -1 : int(HsbKit.hsb(Number(c[0]),Number(c[1]),Number(c[2])));
      }

      private function paintSlots(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var n:int = Math.min(3,Math.max(1,this.tabs.length));
         var gap:Number = 12;
         var cw:Number = (param3 - gap * (n - 1)) / n;
         var ch:Number = k.u(62);
         var current:int = this.sel != null ? int(this.sel.iSelectedTab) : -1;
         var i:int = 0;
         while(i < n)
         {
            var x:Number = param1 + i * (cw + gap);
            var tab:Object = this.tabs.length > i ? this.tabs[i] : {"text":"\u2014","enabled":false};
            var open:Boolean = i == this.openSlot;
            k.fill(g,x,param2,cw,ch,8,open ? HsbKit.SELECT : 0x13181D,1);
            k.outline(g,x,param2,cw,ch,8,open ? k.accent : (i == current ? HsbKit.EDGE_HI : HsbKit.EDGE),1);
            var color:int = this.slotColor(i);
            if(color >= 0) { k.fill(g,x + 8,param2 + 9,28,ch - 18,6,uint(color),1); }
            else { k.dashed(g,x + 8,param2 + 9,28,ch - 18,6,HsbKit.DIM,1); }
            k.outline(g,x + 8,param2 + 9,28,ch - 18,6,0x000000,0.35);
            k.label(this,x + 46,param2 + 10,String(tab.text),15,tab.enabled == true ? HsbKit.TEXT : HsbKit.DIM,false,0,cw - 52);
            k.label(this,x + 46,param2 + 10 + k.u(22),color >= 0 ? "~#" + HsbKit.hex6(uint(color)) : "Reading\u2026",13,HsbKit.MUTED,false,0,cw - 52);
            if(tab.enabled == true && this.tabs.length > i) { this.hit(x,param2,cw,ch,"slot",i); }
            i++;
         }
         return param2 + ch;
      }

      // The open slot's three sliders on the game's own gradients, then the recent swatches.
      private function paintEditor(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var y:Number = param2 + 12;
         var names:Array = [["$HUE","HUE"],["$SATURATION","SATURATION"],["$BRIGHTNESS","BRIGHTNESS"]];
         var c:Array = this.slots[this.openSlot] as Array;
         var labelW:Number = k.u(100);
         var tx:Number = param1 + labelW;
         var tw:Number = param3 - labelW - 8;
         var th:Number = k.u(12);
         var rowH:Number = k.u(28);
         this.sliderX = tx;
         this.sliderW = tw;
         var i:int = 0;
         while(i < 3)
         {
            var active:Boolean = this.sel != null && int(this.sel.iSelectedControl) == i;
            var lab:TextField = k.text(12,active ? k.accent : HsbKit.LABEL,true,1.5);
            k.putCaps(lab,String(names[i][0]),String(names[i][1]));
            k.fit(lab,labelW - 8);
            this.add(lab,param1,y + (rowH - lab.height) / 2);
            var ty:Number = y + (rowH - th) / 2;
            this.gradient(g,tx,ty,tw,th,i,c);
            k.outline(g,tx,ty,tw,th,th / 2,active ? k.accent : HsbKit.EDGE_HI,1);
            if(c != null)
            {
               var vx:Number = tx + tw * clamp01(Number(c[i]));
               k.fill(g,vx - 3,ty - 4,6,th + 8,3,HsbKit.TEXT,1);
               k.outline(g,vx - 3,ty - 4,6,th + 8,3,0x000000,0.6);
            }
            this.hit(tx - 6,y,tw + 12,rowH,"slider",i);
            y += rowH;
            i++;
         }
         if(this.recent.length > 0)
         {
            var rl:TextField = k.text(12,this.sel != null && int(this.sel.iSelectedControl) == RECENT ? k.accent : HsbKit.LABEL,true,1.5);
            k.putCaps(rl,"$RECENT","RECENT");
            k.fit(rl,labelW - 8);
            this.add(rl,param1,y + (rowH - rl.height) / 2);
            var s:Number = k.u(18);
            var rx:Number = tx;
            var r:int = 0;
            while(r < this.recent.length && rx + s <= tx + tw)
            {
               k.fill(g,rx,y + (rowH - s) / 2,s,s,4,uint(this.recent[r]),1);
               k.outline(g,rx,y + (rowH - s) / 2,s,s,4,HsbKit.EDGE_HI,1);
               this.hit(rx - 2,y,s + 4,rowH,"recent",r);
               rx += s + 6;
               r++;
            }
            y += rowH;
         }
         return y;
      }

      // The game's gradient when it sent one; otherwise drawn from the slot's own values.
      private function gradient(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:Number, param6:int, param7:Array):void
      {
         var stops:Array = this.grads[param6] as Array;
         var n:int = stops != null && stops.length > 1 ? stops.length : 24;
         var bw:Number = param4 / n;
         var i:int = 0;
         while(i < n)
         {
            var color:uint;
            if(stops != null && stops.length > 1) { color = uint(stops[i]); }
            else
            {
               var f:Number = i / (n - 1);
               var hh:Number = param7 != null ? Number(param7[0]) : 0;
               var ss:Number = param7 != null ? Number(param7[1]) : 1;
               var bb:Number = param7 != null ? Number(param7[2]) : 1;
               if(param6 == HUE) { color = HsbKit.hsb(f,1,1); }
               else if(param6 == SATURATION) { color = HsbKit.hsb(hh,f,bb); }
               else { color = HsbKit.hsb(hh,ss,f); }
            }
            param1.beginFill(color,1);
            param1.drawRect(param2 + i * bw,param3 + 1,Math.ceil(bw) + 0.5,param5 - 2);
            param1.endFill();
            i++;
         }
      }

      private function paintScheme(param1:int, param2:Number, param3:Number, param4:Number, param5:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var s:Object = this.schemes[param1];
         var sel:Boolean = param1 == this.chosen && (this.previewing || this.exported != null);
         if(sel)
         {
            k.fill(g,param2,param3,param4,param5,8,HsbKit.SELECT,1);
            k.fill(g,param2 - 6,param3 + 12,3,param5 - 24,1.5,k.accent,1);
         }
         var slots:Array = s.slots as Array;
         var q:Number = k.u(18);
         var i:int = 0;
         while(i < 3)
         {
            var c:Array = slots[i] as Array;
            var sx:Number = param2 + 16 + i * (q + 3);
            var sy:Number = param3 + (param5 - q) / 2;
            if(c != null) { k.fill(g,sx,sy,q,q,4,HsbKit.hsb(Number(c[0]),Number(c[1]),Number(c[2])),1); }
            k.outline(g,sx,sy,q,q,4,HsbKit.EDGE_HI,1);
            i++;
         }
         var src:String = String(s.source) == "starter" ? "Starter" : (String(s.source) == "user" ? "Yours" : "Imported" + (String(s.author).length > 0 ? " \u00B7 by " + String(s.author) : ""));
         k.label(this,param2 + 88,param3 + 4,String(s.name),15,HsbKit.TEXT,true,0,param4 - 88 - 130);
         k.label(this,param2 + 88,param3 + 4 + k.u(21),src,13,HsbKit.MUTED,false,0,param4 - 88 - 130);
         if(sel)
         {
            var tag:TextField = k.text(13,this.previewing ? k.accent : HsbKit.GREEN,true,1.5,"right");
            k.put(tag,this.previewing ? "PREVIEWING" : "EXPORTED");
            tag.width = 130;
            this.add(tag,param2 + param4 - 12 - 130,param3 + (param5 - tag.height) / 2);
         }
         if(this.allKnown() || this.tabs.length > 0) { this.hit(param2,param3,param4,param5,"scheme",param1); }
      }

      // Mockup 6 (preview), mockup 7 (exported) or a failure note.
      private function paintBox(param1:Number, param2:Number, param3:Number, param4:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var pad:Number = 16;
         if(this.previewing && this.chosen >= 0)
         {
            k.fill(g,param1,param2,param3,param4,10,0x14181C,1);
            k.outline(g,param1,param2,param3,param4,10,k.accentDim(0.55),1);
            k.label(this,param1 + pad,param2 + 14,String(this.schemes[this.chosen].name) + " on the selected parts",15,HsbKit.TEXT,true,0,param3 - pad * 2);
            k.label(this,param1 + pad,param2 + 14 + k.u(24),"Nothing changes until you accept.",13,HsbKit.LABEL);
            k.label(this,param1 + pad,param2 + 14 + k.u(42),"Other parts keep their colors.",13,HsbKit.LABEL);
            var bh:Number = k.u(30);
            var by:Number = param2 + param4 - bh - 12;
            var aw:Number = this.capButton(param1 + param3 - pad,by,this.hsb.keyName("Accept"),"ACCEPT","accept",true);
            this.capButton(param1 + param3 - pad - aw - 10,by,this.hsb.keyName("Cancel"),"CANCEL","pvcancel",false);
            return;
         }
         if(this.exported != null)
         {
            k.fill(g,param1,param2,param3,param4,10,HsbKit.GREEN_BG,0.7);
            k.outline(g,param1,param2,param3,param4,10,HsbKit.mix(HsbKit.GREEN,HsbKit.FILL,0.6),1);
            k.icon(g,"checkCircle",param1 + 12,param2 + 13,20,HsbKit.GREEN,1);
            k.label(this,param1 + 40,param2 + 12,"Exported \u201C" + String(this.exported.name) + "\u201D",15,HsbKit.GREEN,true,0,param3 - 52);
            k.label(this,param1 + 40,param2 + 12 + k.u(24),SCHEME_FOLDER,13,HsbKit.LABEL,false,0,param3 - 52);
            k.label(this,param1 + 40,param2 + 12 + k.u(42),String(this.exported.file),13,HsbKit.TEXT,true,0,param3 - 52);
            k.label(this,param1 + 40,param2 + 12 + k.u(64),"Share this file. Others put it in the same folder",13,HsbKit.MUTED,false,0,param3 - 52);
            k.label(this,param1 + 40,param2 + 12 + k.u(82),"and pick it from IMPORT.",13,HsbKit.MUTED,false,0,param3 - 52);
            this.hit(param1,param2,param3,param4,"boxclose");
            return;
         }
         k.fill(g,param1,param2,param3,param4,10,HsbKit.RED_BG,0.7);
         k.outline(g,param1,param2,param3,param4,10,HsbKit.RED,0.8);
         k.label(this,param1 + pad,param2 + 14,this.note1,14,HsbKit.RED,true,0,param3 - pad * 2);
         this.hit(param1,param2,param3,param4,"boxclose");
      }

      // Pill button with the live key cap, right-aligned at param1. Returns its width.
      private function capButton(param1:Number, param2:Number, param3:String, param4:String, param5:String, param6:Boolean):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var t:TextField = k.text(13,param6 ? HsbKit.INK_ON_ACCENT : HsbKit.TEXT,true,1.5);
         k.put(t,param4);
         k.fit(t);
         var bh:Number = k.u(30);
         var cap:Number = param3.length > 0 ? k.u(22) + 8 : 0;
         var bw:Number = 12 + cap + t.width + 14;
         var x:Number = param1 - bw;
         k.fill(g,x,param2,bw,bh,bh / 2,param6 ? k.accent : 0x262D33,1);
         if(param3.length > 0)
         {
            var cs:Number = k.u(22);
            k.fill(g,x + 8,param2 + (bh - cs) / 2,cs,cs,cs / 2,param6 ? HsbKit.mix(k.accent,0x000000,0.75) : 0x3A4148,1);
            var ct:TextField = k.text(12,param6 ? HsbKit.INK_ON_ACCENT : HsbKit.TEXT,true);
            k.put(ct,param3);
            k.fit(ct,cs + 20);
            this.add(ct,x + 8 + (cs - ct.width) / 2,param2 + (bh - ct.height) / 2);
         }
         this.add(t,x + 12 + cap,param2 + (bh - t.height) / 2);
         this.hit(x,param2,bw,bh,param5);
         return bw;
      }

      // ---- input ---------------------------------------------------------------------------

      override internal function onPress(param1:Object, param2:Number, param3:Number):Boolean
      {
         if(param1 == null || String(param1.id) != "slider") { return false; }
         this.sliderKind = int(param1.data);
         this.walkCtl = this.sliderKind;
         this.hsb.send("ShipEditor_OnColorPickerControlChanged",{"control":this.sliderKind});
         this.onMove(param2,param3);
         return true;
      }

      // Slider moves go out at most once per frame (tick sends the latest value).
      override internal function onMove(param1:Number, param2:Number):void
      {
         if(this.sliderKind < 0 || this.sliderW <= 0) { return; }
         var v:Number = clamp01((this.localX(param1) - this.sliderX) / this.sliderW);
         this.pendingValue = v;
         var c:Array = this.slots[this.openSlot] as Array;
         if(c != null)
         {
            c[this.sliderKind] = v;
            this.paint();
         }
      }

      override internal function onRelease(param1:Number, param2:Number):void
      {
         this.sliderKind = -1;
      }

      override internal function onWheel(param1:Number, param2:Number, param3:Number):void
      {
         this.scroll = HorizonShipBuilder.clampInt(this.scroll - int(param1),0,Math.max(0,this.schemes.length - this.rowsShown));
         this.paint();
      }

      override internal function onChar(param1:int):void
      {
         if(!this.naming || param1 < 32 || param1 == 127 || this.nameText.length >= 32) { return; }
         this.nameText += String.fromCharCode(param1);
         this.paint();
      }

      override internal function onKey(param1:String):Boolean
      {
         if(!this.naming) { return false; }
         if(param1 == "bksp") { this.nameText = this.nameText.substring(0,Math.max(0,this.nameText.length - 1)); }
         else if(param1 == "ok") { this.onAct("namesave",null); return true; }
         else if(param1 == "cancel") { this.onAct("namecancel",null); return true; }
         this.paint();
         return true;
      }

      override internal function onAct(param1:String, param2:*):void
      {
         switch(param1)
         {
            case "slot":
               var at:int = int(param2);
               this.openSlot = this.openSlot == at ? -1 : at;
               if(this.openSlot >= 0)
               {
                  if(!this.walking()) { this.walkCtl = this.sel != null ? int(this.sel.iSelectedControl) : HUE; }
                  this.walkHome = at;
                  this.steps.push({"kind":"tab","v":at});
               }
               break;
            case "recent":
               this.hsb.send("ShipEditor_OnColorPickerControlChanged",{"control":RECENT});
               this.hsb.send("ShipEditor_OnRecentColorSwatchClicked",{"swatchIndex":int(param2)});
               break;
            case "scheme":
               if(!this.allKnown()) { this.note1 = "Reading the current colors \u00B7 try again in a moment"; break; }
               this.preview(int(param2));
               break;
            case "accept": this.acceptPreview(); break;
            case "pvcancel": this.cancelPreview(); break;
            case "save":
               this.naming = true;
               this.nameText = "";
               this.hsb.beginText(this);
               break;
            case "namesave":
               var name:String = this.nameText;
               this.naming = false;
               this.hsb.endText(this);
               this.saveScheme(name);
               break;
            case "namecancel":
               this.naming = false;
               this.hsb.endText(this);
               break;
            case "export":
               // Exporting writes the file only (mockup 7): a running preview ends first, so the
               // ship goes back to its own colors and the result box is what shows. A scheme of
               // the player's own already is its file in schemes\user, which the box names.
               if(this.previewing) { this.cancelPreview(); }
               var s:Object = this.chosen >= 0 ? this.schemes[this.chosen] : null;
               if(s == null && this.allKnown()) { s = {"name":"My ship colors","source":"user","author":"","file":"","slots":this.currentSlots()}; }
               if(s != null && String(s.source) == "user" && String(s.file).length > 0)
               {
                  this.exported = {"name":String(s.name),"file":String(s.file)};
                  this.note1 = "";
                  this.hsb.note("SCHEMES export own file");
               }
               else if(s != null) { this.writeScheme(s,String(s.source) == "user"); }
               break;
            case "import":
               this.loadSchemes();
               this.note1 = "";
               break;
            case "boxclose":
               this.exported = null;
               this.note1 = "";
               break;
         }
         this.paint();
      }
   }
}
