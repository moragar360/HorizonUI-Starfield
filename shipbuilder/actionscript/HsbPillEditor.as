package
{
   import flash.display.Graphics;
   import flash.text.TextField;

   // Purpose: the pill editor from gold mockup 2: name, up to eight rules, match all or any,
   //    which tabs, whether the pill sits in the pill row, and a live "Matches N parts" count.
   // Inputs: the pill to edit (null for a new one); the browser's parts, makers, sizes and stat
   //    names for the current tab; pointer, keys and typed characters routed by the builder.
   // Outputs: Save writes the pill list through the DLL (PROFILE WRITE, which keeps a .bak);
   //    Delete asks first. Nothing changes until Save or a confirmed Delete.
   // Dependencies: HsbPillModel (rules, limits, test), HsbBrowser (countMatches, makerNames,
   //    sizeNames, statChoices, statNames, tabKeyNow, tabLabel, afterPills), HsbDialog (menus,
   //    confirm), HorizonShipBuilder (popups, text input, savePills).
   // Backend limits shown in the editor: "Fits reactor" and "On my ship" have no game data, so
   //    they are listed but cannot be picked; a rule already holding one says it is skipped.
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbPillEditor extends HsbBox
   {
      private static const CLASSES:Array = ["A","B","C","M"];
      private static const MAX_VALUES:int = 16;
      private static const MAX_NUMBER_CHARS:int = 10;

      private var hsb:HorizonShipBuilder;
      private var browser:HsbBrowser;
      private var orig:Object;
      private var draft:Object;
      private var tabId:String;
      private var tabName:String;
      private var editing:String = "";
      private var editText:String = "";
      private var nameBefore:String = "";
      private var problem:String = "";

      public function HsbPillEditor(param1:HsbKit, param2:HorizonShipBuilder, param3:HsbBrowser, param4:Object)
      {
         super(param1,"HsbPillEditor");
         this.hsb = param2;
         this.browser = param3;
         this.orig = param4;
         this.tabId = param3.tabKeyNow();
         this.tabName = param3.tabLabel();
         this.draft = param4 != null ? HsbPillModel.clean(param4) : null;
         if(this.draft == null) { this.draft = {"id":"","name":"","tabs":[this.tabId],"match":"all","inRow":true,"rules":[],"columns":null}; }
         if(this.draft.rules == null) { this.draft.rules = []; }
         this.paint();
         if(param4 == null) { this.startName(); }
      }

      private function rules():Array
      {
         return this.draft.rules as Array;
      }

      // ---- paint ---------------------------------------------------------------------------

      internal function paint():void
      {
         this.wipe();
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var w:Number = k.u(626);
         var pad:Number = 28;
         var y:Number = 24;
         var title:TextField = k.label(this,pad,y,this.orig == null ? "NEW PILL" : "EDIT PILL",18,HsbKit.TEXT,true,3);
         k.label(this,pad + title.width + 10,y + (title.height - k.u(20)) / 2 + 1,(this.tabName + " list").toUpperCase(),13,HsbKit.MUTED,false,2,k.u(240));
         var capW:Number = k.keycap(this,w - pad - k.u(40),y - 2,"ESC",HsbKit.LABEL,k.u(24));
         this.hit(w - pad - capW - 4,y - 6,capW + 8,k.u(32),"close");
         y = 80;
         k.label(this,pad,y,"NAME",13,k.accent,true,2);
         y += k.u(22);
         var fh:Number = k.u(35);
         var nameOn:Boolean = this.editing == "name";
         k.fill(g,pad,y,w - pad * 2,fh,8,HsbKit.FIELD,1);
         k.outline(g,pad,y,w - pad * 2,fh,8,nameOn ? k.accent : HsbKit.EDGE_HI,1);
         k.icon(g,"diamond",pad + 12,y + (fh - 12) / 2,12,k.accent,1);
         var name:String = nameOn ? this.editText : String(this.draft.name);
         var nt:TextField = k.text(15,name.length > 0 ? HsbKit.TEXT : HsbKit.MUTED,true);
         k.put(nt,name.length > 0 ? name + (nameOn ? "|" : "") : (nameOn ? "|" : "Name this pill"));
         k.fit(nt,w - pad * 2 - 120);
         this.add(nt,pad + 32,y + (fh - nt.height) / 2);
         var cnt:TextField = k.text(13,HsbKit.LABEL,false,0,"right");
         k.put(cnt,name.length + " / " + HsbPillModel.MAX_NAME);
         cnt.width = 80;
         this.add(cnt,w - pad - 14 - 80,y + (fh - cnt.height) / 2);
         this.hit(pad,y,w - pad * 2,fh,"name");
         y += fh + 30;
         var rl:TextField = k.label(this,pad,y,"RULES",13,k.accent,true,2);
         k.label(this,pad + rl.width + 12,y,this.rules().length + " of " + HsbPillModel.MAX_RULES,13,HsbKit.LABEL);
         var segW:Number = this.kit.segmentsWidth(["MATCH ALL","MATCH ANY"]);
         k.segments(this,w - pad - segW,y - 6,["MATCH ALL","MATCH ANY"],String(this.draft.match) == "any" ? 1 : 0,"match",k.u(28));
         y += k.u(27);
         k.label(this,pad,y,String(this.draft.match) == "any" ? "A part shows up if it passes any rule." : "A part shows up only if it passes every rule.",13,HsbKit.LABEL,false,0,w - pad * 2);
         y += k.u(28);
         var rowH:Number = k.u(44);
         var i:int = 0;
         while(i < this.rules().length)
         {
            this.paintRule(i,22,y,w - 44,rowH);
            y += rowH + 8;
            i++;
         }
         y += 4;
         var full:Boolean = this.rules().length >= HsbPillModel.MAX_RULES;
         var add:TextField = k.text(13,full ? HsbKit.DIM : HsbKit.TEXT,true,1.5);
         k.put(add,"ADD RULE");
         k.fit(add);
         var aw:Number = 34 + add.width + 14;
         var ah:Number = k.u(30);
         k.dashed(g,pad,y,aw,ah,ah / 2,full ? HsbKit.EDGE : HsbKit.LABEL,1);
         k.icon(g,"plus",pad + 12,y + (ah - 14) / 2,14,full ? HsbKit.DIM : HsbKit.TEXT,1);
         this.add(add,pad + 30,y + (ah - add.height) / 2);
         if(!full) { this.hit(pad,y,aw,ah,"addrule"); }
         var help:TextField = k.text(13,HsbKit.LABEL);
         help.multiline = true;
         help.wordWrap = true;
         help.width = w - pad * 2 - aw - 14;
         k.put(help,full ? "Eight rules is the most a pill can hold." : "Maker, Size, Class, Can afford, Fits reactor, On my ship, a stat minimum or maximum, Value");
         help.height = help.textHeight + 6;
         this.add(help,pad + aw + 14,y - 2);
         y += Math.max(ah,help.height) + 16;
         k.hline(g,pad,y,w - pad * 2,HsbKit.EDGE,1);
         y += 16;
         k.label(this,pad,y + 4,"APPLIES TO",13,k.accent,true,2);
         var tabs:Array = this.draft.tabs as Array;
         var applies:int = tabs != null && tabs.indexOf("*") >= 0 ? 1 : (tabs != null && tabs.length == 1 && String(tabs[0]) == this.tabId ? 0 : -1);
         var aLabels:Array = ["THIS TAB (" + this.tabName.toUpperCase() + ")","ALL TABS"];
         var aW:Number = this.kit.segmentsWidth(aLabels);
         k.segments(this,w - pad - aW,y,aLabels,applies,"applies",k.u(28));
         if(applies < 0)
         {
            var names:Array = [];
            var t:int = 0;
            while(tabs != null && t < tabs.length && t < 3) { names.push(this.browser.tabNameFor(String(tabs[t]))); t++; }
            k.label(this,pad + k.u(120),y + 6,"Now: " + names.join(", "),12,HsbKit.MUTED,false,0,w - pad * 2 - aW - k.u(130));
         }
         y += k.u(40);
         k.label(this,pad,y + 2,"SHOW IN PILL ROW",13,k.accent,true,2);
         var inRow:Boolean = this.draft.inRow != false;
         var tw:Number = k.u(38);
         var onT:TextField = k.text(13,HsbKit.LABEL,true,1,"right");
         k.put(onT,inRow ? "ON" : "OFF");
         onT.width = 40;
         this.add(onT,w - pad - tw - 10 - 40,y + 1);
         k.toggle(g,w - pad - tw,y + 2,inRow);
         this.hit(w - pad - tw - 60,y - 4,tw + 64,k.u(28),"inrow");
         y += k.u(30);
         k.hline(g,pad,y,w - pad * 2,HsbKit.EDGE,1);
         y += 16;
         var bh:Number = k.u(30);
         if(this.problem.length > 0)
         {
            var pt:TextField = k.text(13,HsbKit.RED,true);
            k.put(pt,this.problem);
            k.fit(pt,w - pad * 2 - k.u(300));
            k.fill(g,pad,y,pt.width + 34,bh,bh / 2,HsbKit.RED_BG,1);
            k.icon(g,"warn",pad + 10,y + (bh - 14) / 2,14,HsbKit.RED,1);
            this.add(pt,pad + 28,y + (bh - pt.height) / 2);
         }
         else
         {
            var n:int = this.browser.countMatches(this.draft);
            var mt:TextField = k.text(13,HsbKit.GREEN,true);
            k.put(mt,"Matches " + n + (n == 1 ? " part" : " parts"));
            k.fit(mt);
            k.fill(g,pad,y,mt.width + 34,bh,bh / 2,HsbKit.GREEN_BG,1);
            k.outline(g,pad,y,mt.width + 34,bh,bh / 2,HsbKit.mix(HsbKit.GREEN,HsbKit.FILL,0.5),1);
            k.icon(g,"dot",pad + 8,y + (bh - 14) / 2,14,HsbKit.GREEN,1);
            this.add(mt,pad + 24,y + (bh - mt.height) / 2);
         }
         var sx:Number = w - pad - k.u(72);
         k.button(this,sx,y,"SAVE","accent","save",null,bh,k.u(72));
         var cx:Number = sx - 10 - k.u(90);
         k.button(this,cx,y,"CANCEL","outline","cancel",null,bh,k.u(90));
         if(this.orig != null) { k.button(this,cx - 10 - k.u(90),y,"DELETE","red","delete",null,bh,k.u(90)); }
         y += bh + 20;
         k.card(this.graphics,0,0,w,y,14);
         this.boxW = w;
         this.boxH = y;
         this.drawFocus();
      }

      // One rule row: field, operator, value (chips, number or switch), remove.
      private function paintRule(param1:int, param2:Number, param3:Number, param4:Number, param5:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var rule:Object = this.rules()[param1];
         var field:String = String(rule.field);
         var live:Boolean = HsbPillModel.hasBackend(field);
         k.fill(g,param2,param3,param4,param5,8,HsbKit.ROW,1);
         var dh:Number = k.u(26);
         var dy:Number = param3 + (param5 - dh) / 2;
         var x:Number = param2 + 10;
         this.dropdown(x,dy,k.u(128),dh,HsbPillModel.fieldLabel(field,this.browser.statNames()),"field",param1);
         x += k.u(128) + 12;
         var op:String = String(rule.op);
         var right:Number = param2 + param4 - 36;
         if(!live)
         {
            k.toggle(g,x,param3 + (param5 - k.u(18)) / 2,rule.value != false,false);
            k.label(this,x + k.u(38) + 10,param3 + (param5 - k.u(20)) / 2,"No game data \u00B7 this rule is skipped",13,HsbKit.ORANGE,false,0,right - x - k.u(48) - 10);
         }
         else if(op == "is")
         {
            var yes:Boolean = rule.value != false;
            k.toggle(g,x,param3 + (param5 - k.u(18)) / 2,yes);
            this.hit(x - 4,param3,k.u(38) + 8,param5,"bool",param1);
            k.label(this,x + k.u(38) + 10,param3 + (param5 - k.u(22)) / 2,yes ? "Only parts I can pay for now" : "Only parts I can't pay for now",14,HsbKit.LABEL,false,0,right - x - k.u(48) - 10);
         }
         else
         {
            var ops:Array = HsbPillModel.opsFor(field);
            this.dropdown(x,dy,k.u(100),dh,HsbPillModel.opLabel(op),ops.length > 1 ? "op" : "",param1);
            x += k.u(100) + 14;
            if(op == "anyOf") { this.paintChips(param1,rule,x,dy,right - 8,dh); }
            else
            {
               var numOn:Boolean = this.editing == "num" + param1;
               var text:String = numOn ? this.editText + "|" : HsbKit.num(rule.value,2);
               var nv:TextField = k.text(14,HsbKit.TEXT,true);
               k.put(nv,text);
               k.fit(nv);
               var nw:Number = Math.max(k.u(66),nv.width + 20);
               k.fill(g,x,dy,nw,dh,5,HsbKit.FIELD,1);
               k.outline(g,x,dy,nw,dh,5,numOn ? k.accent : HsbKit.EDGE_HI,1);
               this.add(nv,x + 10,dy + (dh - nv.height) / 2);
               this.hit(x,dy,nw,dh,"num",param1);
            }
         }
         var rs:Number = k.u(22);
         var rx:Number = param2 + param4 - 12 - rs;
         var ry:Number = param3 + (param5 - rs) / 2;
         k.fill(g,rx,ry,rs,rs,rs / 2,0x262D33,1);
         k.outline(g,rx,ry,rs,rs,rs / 2,HsbKit.EDGE_HI,1);
         k.icon(g,"x",rx + 4,ry + 4,rs - 8,HsbKit.TEXT,1);
         this.hit(rx - 4,ry - 4,rs + 8,rs + 8,"rmrule",param1);
      }

      private function dropdown(param1:Number, param2:Number, param3:Number, param4:Number, param5:String, param6:String, param7:int):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         k.fill(g,param1,param2,param3,param4,5,HsbKit.FIELD,1);
         k.outline(g,param1,param2,param3,param4,5,HsbKit.EDGE_HI,1);
         // Mockup 2 fits "Crew stations" in the field box; a name that would be cut at 14 is set at 13.
         var probe:TextField = k.text(14,HsbKit.TEXT);
         k.put(probe,param5);
         var size:int = probe.textWidth + 6 > param3 - 30 ? 13 : 14;
         k.label(this,param1 + 8,param2 + (param4 - k.u(size == 14 ? 22 : 20)) / 2,param5,size,HsbKit.TEXT,false,0,param3 - 30);
         if(param6.length > 0)
         {
            k.icon(g,"chevD",param1 + param3 - 20,param2 + (param4 - 13) / 2,13,HsbKit.LABEL,1);
            this.hit(param1,param2,param3,param4,param6,param7);
         }
      }

      // Value chips with a remove cross; chips that do not fit become "+N"; "+" adds.
      private function paintChips(param1:int, param2:Object, param3:Number, param4:Number, param5:Number, param6:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var values:Array = param2.values as Array;
         if(values == null) { values = []; }
         var x:Number = param3;
         var addW:Number = param6;
         var i:int = 0;
         while(i < values.length)
         {
            var t:TextField = k.text(13,HsbKit.TEXT,true);
            k.put(t,String(values[i]));
            k.fit(t);
            var cw:Number = 10 + t.width + 4 + 14 + 6;
            var room:Number = param5 - addW - 8;
            if(x + cw > room)
            {
               var more:int = values.length - i;
               var mt:TextField = k.text(13,k.accent,true);
               k.put(mt,"+" + more);
               k.fit(mt);
               var mw:Number = mt.width + 16;
               k.outline(g,x,param4,mw,param6,param6 / 2,k.accent,0.7);
               this.add(mt,x + 8,param4 + (param6 - mt.height) / 2);
               this.hit(x,param4,mw,param6,"chipadd",param1);
               x += mw + 6;
               break;
            }
            k.fill(g,x,param4,cw,param6,param6 / 2,k.accentDim(0.2),1);
            k.outline(g,x,param4,cw,param6,param6 / 2,k.accent,0.8);
            this.add(t,x + 10,param4 + (param6 - t.height) / 2);
            k.icon(g,"x",x + cw - 20,param4 + (param6 - 12) / 2,12,HsbKit.TEXT,1);
            this.hit(x + cw - 24,param4,24,param6,"chipx",{"r":param1,"v":String(values[i])});
            x += cw + 6;
            i++;
         }
         if(values.length < MAX_VALUES)
         {
            k.outline(g,x,param4,addW,param6,param6 / 2,HsbKit.EDGE_HI,1);
            k.icon(g,"plus",x + (addW - 12) / 2,param4 + (param6 - 12) / 2,12,HsbKit.TEXT,1);
            this.hit(x,param4,addW,param6,"chipadd",param1);
         }
         if(values.length == 0) { k.label(this,x + addW + 8,param4 + (param6 - k.u(20)) / 2,"Pick at least one",12,HsbKit.MUTED); }
      }

      // ---- text input ----------------------------------------------------------------------

      private function startName():void
      {
         this.stopEditing(true);
         this.editing = "name";
         this.nameBefore = String(this.draft.name);
         this.editText = this.nameBefore;
         this.hsb.beginText(this);
         this.paint();
      }

      private function startNumber(param1:int):void
      {
         this.stopEditing(true);
         var rule:Object = this.rules()[param1];
         if(rule == null) { return; }
         this.editing = "num" + param1;
         var v:Number = Number(rule.value);
         this.editText = isNaN(v) || v == 0 ? "" : String(v);
         this.hsb.beginText(this);
         this.paint();
      }

      // Keep: true writes the typed text into the draft; false puts the old value back.
      private function stopEditing(param1:Boolean):void
      {
         if(this.editing.length == 0) { return; }
         if(this.editing == "name")
         {
            this.draft.name = param1 ? HsbPillModel.trim(this.editText) : this.nameBefore;
         }
         else if(param1)
         {
            var rule:Object = this.rules()[int(this.editing.substring(3))];
            var n:Number = Number(this.editText);
            if(rule != null && this.editText.length > 0 && !isNaN(n)) { rule.value = n; }
         }
         this.editing = "";
         this.editText = "";
         this.hsb.endText(this);
      }

      override internal function onChar(param1:int):void
      {
         if(this.editing.length == 0 || param1 < 32 || param1 == 127) { return; }
         var c:String = String.fromCharCode(param1);
         if(this.editing == "name")
         {
            if(this.editText.length >= HsbPillModel.MAX_NAME) { return; }
            this.editText += c;
         }
         else
         {
            if(this.editText.length >= MAX_NUMBER_CHARS) { return; }
            if((c < "0" || c > "9") && !(c == "." && this.editText.indexOf(".") < 0)) { return; }
            this.editText += c;
         }
         this.problem = "";
         this.paint();
      }

      override internal function onKey(param1:String):Boolean
      {
         if(this.editing.length > 0)
         {
            if(param1 == "bksp")
            {
               this.editText = this.editText.substring(0,Math.max(0,this.editText.length - 1));
               this.paint();
               return true;
            }
            if(param1 == "ok" || param1 == "tab" || param1 == "tabprev")
            {
               this.stopEditing(true);
               this.paint();
               return true;
            }
            if(param1 == "cancel")
            {
               this.stopEditing(false);
               this.paint();
               return true;
            }
            return true;
         }
         if(param1 == "cancel") { return false; }
         if(param1 == "ok" && this.focusedHit() == null)
         {
            this.save();
            return true;
         }
         return this.navKey(param1);
      }

      // ---- actions -------------------------------------------------------------------------

      override internal function onAct(param1:String, param2:*):void
      {
         if(param1 != "name" && param1 != "num") { this.stopEditing(true); }
         this.problem = "";
         var rule:Object = param2 is int || param2 is Number ? this.rules()[int(param2)] : null;
         switch(param1)
         {
            case "close":
            case "cancel":
               this.stopEditing(false);
               this.hsb.closePop(this,false);
               return;
            case "name": this.startName(); return;
            case "num": this.startNumber(int(param2)); return;
            case "match": this.draft.match = int(param2) == 1 ? "any" : "all"; break;
            case "applies": this.draft.tabs = int(param2) == 1 ? ["*"] : [this.tabId]; break;
            case "inrow": this.draft.inRow = this.draft.inRow == false; break;
            case "bool": if(rule != null) { rule.value = rule.value == false; } break;
            case "rmrule": if(rule != null) { this.rules().splice(int(param2),1); } break;
            case "chipx":
               var r2:Object = this.rules()[int(param2.r)];
               if(r2 != null && r2.values is Array)
               {
                  var at:int = (r2.values as Array).indexOf(String(param2.v));
                  if(at >= 0) { (r2.values as Array).splice(at,1); }
               }
               break;
            case "field": this.openFieldMenu(int(param2),this.hitFor("field",int(param2))); return;
            case "op": this.openOpMenu(int(param2)); return;
            case "chipadd": this.openValueMenu(int(param2)); return;
            case "addrule": this.openFieldMenu(-1,this.hitFor("addrule")); return;
            case "save": this.save(); return;
            case "delete": this.askDelete(); return;
         }
         this.paint();
      }

      private function fieldItems(param1:String):Array
      {
         var items:Array = [];
         var base:Array = [["maker","Maker"],["size","Size"],["class","Class"],["value","Value"],["canAfford","Can afford"]];
         var i:int = 0;
         while(i < base.length)
         {
            items.push({"label":base[i][1],"id":"field","data":base[i][0],"on":param1 == base[i][0]});
            i++;
         }
         var stats:Array = this.browser.statChoices();
         i = 0;
         while(i < stats.length)
         {
            items.push({"label":stats[i].label,"id":"field","data":stats[i].id,"on":param1 == String(stats[i].id)});
            i++;
         }
         items.push({"label":"Fits reactor","id":"field","data":"fitsReactor","dim":true,"note":"No game data"});
         items.push({"label":"On my ship","id":"field","data":"onMyShip","dim":true,"note":"No game data"});
         return items;
      }

      // Rule -1 adds a new rule with the picked field.
      private function openFieldMenu(param1:int, param2:Object):void
      {
         var self:HsbPillEditor = this;
         var current:String = param1 >= 0 && this.rules()[param1] != null ? String(this.rules()[param1].field) : "";
         var menu:HsbDialog = HsbDialog.menu(this.kit,this.hsb,param1 < 0 ? "ADD RULE" : "FIELD",this.fieldItems(current),function(param3:String, param4:*):void
         {
            var field:String = String(param4);
            var ops:Array = HsbPillModel.opsFor(field);
            var fresh:Object = {"field":field,"op":String(ops[0])};
            if(fresh.op == "anyOf") { fresh.values = []; }
            else if(fresh.op == "is") { fresh.value = true; }
            else { fresh.value = 0; }
            if(param1 < 0)
            {
               if(self.rules().length < HsbPillModel.MAX_RULES) { self.rules().push(fresh); }
            }
            else if(String(self.rules()[param1].field) != field) { self.rules()[param1] = fresh; }
            self.paint();
         });
         this.anchorUnder(menu,param2);
         this.hsb.openPop(menu);
      }

      private function openOpMenu(param1:int):void
      {
         var rule:Object = this.rules()[param1];
         if(rule == null) { return; }
         var ops:Array = HsbPillModel.opsFor(String(rule.field));
         var items:Array = [];
         var i:int = 0;
         while(i < ops.length)
         {
            items.push({"label":HsbPillModel.opLabel(String(ops[i])),"id":"op","data":String(ops[i]),"on":String(rule.op) == String(ops[i])});
            i++;
         }
         var self:HsbPillEditor = this;
         var menu:HsbDialog = HsbDialog.menu(this.kit,this.hsb,"",items,function(param2:String, param3:*):void
         {
            rule.op = String(param3);
            self.paint();
         });
         this.anchorUnder(menu,this.hitFor("op",param1));
         this.hsb.openPop(menu);
      }

      // Values for maker, size and class rules. A pick toggles the value in or out.
      private function openValueMenu(param1:int):void
      {
         var rule:Object = this.rules()[param1];
         if(rule == null) { return; }
         var field:String = String(rule.field);
         var choices:Array = field == "maker" ? this.browser.makerNames() : (field == "size" ? this.browser.sizeNames() : CLASSES.slice());
         var values:Array = rule.values as Array;
         if(values == null)
         {
            values = [];
            rule.values = values;
         }
         var i:int = 0;
         while(i < values.length)
         {
            if(choices.indexOf(String(values[i])) < 0) { choices.push(String(values[i])); }
            i++;
         }
         var items:Array = [];
         i = 0;
         while(i < choices.length && items.length < 24)
         {
            items.push({"label":String(choices[i]),"id":"val","data":String(choices[i]),"on":values.indexOf(String(choices[i])) >= 0});
            i++;
         }
         var self:HsbPillEditor = this;
         var menu:HsbDialog = HsbDialog.menu(this.kit,this.hsb,HsbPillModel.fieldLabel(field),items,function(param2:String, param3:*):void
         {
            var at:int = values.indexOf(String(param3));
            if(at >= 0) { values.splice(at,1); }
            else if(values.length < MAX_VALUES) { values.push(String(param3)); }
            self.paint();
         });
         this.anchorUnder(menu,this.hitFor("chipadd",param1));
         this.hsb.openPop(menu);
      }

      private function save():void
      {
         this.stopEditing(true);
         var model:HsbPillModel = this.hsb.pills;
         var name:String = HsbPillModel.trim(String(this.draft.name));
         var same:Object = model.byName(name);
         if(name.length == 0) { this.problem = "Give the pill a name"; }
         else if(same != null && (this.orig == null || String(same.id) != String(this.orig.id))) { this.problem = "Another pill already has this name"; }
         else if(this.rules().length == 0) { this.problem = "Add at least one rule"; }
         else if(this.orig == null && model.pills.length >= HsbPillModel.MAX_PILLS) { this.problem = "20 pills is the most; remove one first"; }
         else { this.problem = this.emptyRule(); }
         if(this.problem.length > 0)
         {
            this.paint();
            return;
         }
         this.draft.name = name;
         var clean:Object = HsbPillModel.clean(this.draft);
         if(this.orig == null)
         {
            clean.id = model.newId();
            model.pills.push(clean);
            model.on[String(clean.id)] = true;
         }
         else
         {
            clean.id = String(this.orig.id);
            var at:int = model.pills.indexOf(this.orig);
            if(at < 0) { at = model.pills.indexOf(model.byId(String(this.orig.id))); }
            if(at >= 0) { model.pills[at] = clean; }
            else { model.pills.push(clean); }
         }
         this.hsb.savePills();
         this.browser.afterPills();
         this.hsb.note("PILLS edit saved n=" + model.pills.length);
         this.hsb.closePop(this,true);
      }

      private function emptyRule():String
      {
         var i:int = 0;
         while(i < this.rules().length)
         {
            var r:Object = this.rules()[i];
            if(String(r.op) == "anyOf" && (!(r.values is Array) || (r.values as Array).length == 0))
            {
               return "Pick a value for " + HsbPillModel.fieldLabel(String(r.field),this.browser.statNames());
            }
            i++;
         }
         return "";
      }

      // Mockup 16. The profile write keeps the previous file as a .bak, except in a visit that
      // started without a loaded profile: the DLL then keeps the older .bak (pillsBakKept).
      // Pill files are never deleted.
      private function askDelete():void
      {
         var self:HsbPillEditor = this;
         var target:Object = this.orig;
         var bakLine:String = this.hsb.pillsBakKept ? "An earlier list may be kept as a .bak backup." : "Your previous list is kept as a .bak backup.";
         HsbDialog.confirm(this.kit,this.hsb,"Remove pill from list?",String(target.name),["This removes the pill from your list.",bakLine,"Horizon never deletes pill files you exported or imported."],"Yes",function(param1:Boolean):void
         {
            if(!param1) { return; }
            var model:HsbPillModel = self.hsb.pills;
            var at:int = model.pills.indexOf(target);
            if(at < 0) { at = model.pills.indexOf(model.byId(String(target.id))); }
            if(at >= 0) { model.pills.splice(at,1); }
            delete model.on[String(target.id)];
            self.hsb.savePills();
            self.browser.afterPills();
            self.hsb.note("PILLS removed n=" + model.pills.length);
            self.hsb.closePop(self,true);
         });
      }

      override internal function onClose(param1:Boolean):void
      {
         if(this.editing.length > 0)
         {
            this.editing = "";
            this.hsb.endText(this);
         }
      }
   }
}
