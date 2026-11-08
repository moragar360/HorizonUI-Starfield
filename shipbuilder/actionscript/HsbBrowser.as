package
{
   import flash.display.DisplayObjectContainer;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.text.TextField;

   // Purpose: the Parts Browser from gold mockups 1, 4, 5, 8, 11, 12, 13 and 14: category tabs
   //    and the category grid, find, pills, sort, columns, group by maker, density, collapse.
   // Inputs: PartEntries / UpgradeEntries rows (name, iStat1 named by sStatName1, iVariants,
   //    bDisabled, uFormID); ModuleInfo for the previewed part (value, mass, class and card
   //    stats, cached per part); pointer and keys routed by HorizonShipBuilder.
   // Outputs: the game's own list is re-fed in Horizon's filtered and sorted order, so arrow
   //    keys, the controller and Enter move and place exactly what is shown. Hover previews a
   //    part through the list's selection (vanilla's ShipEditor_PreviewShipPart path); a click
   //    places it through ModulePalette.onListEntrySelected (ShipEditor_SelectedShipPart).
   // Dependencies: the vanilla ModulePalette_mc and its BSScrollingContainer ModuleEntries_mc;
   //    HsbPillModel; HsbKit.
   // Backend limits shown in the interface: maker and size come from part names; value, mass,
   //    class and card stats are known only after a part was previewed; categories are learned
   //    by stepping through them; "on ship" and "hidden by level" have no game data.
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbBrowser extends HsbBox
   {
      private static const KNOWN_MAKERS:Array = [["Nova Galactic","Nova Galactic"],["Taiyo Astroneering","Taiyo Astroneering"],["Taiyo","Taiyo Astroneering"],["Stroud-Eklund","Stroud-Eklund"],["Stroud","Stroud-Eklund"],["HopeTech","HopeTech"],["Deimos","Deimos"],["Amun Dunn","Amun Dunn"],["Slayton Aerospace","Slayton Aerospace"],["White Dwarf","White Dwarf"],["Protectorate Systems","Protectorate Systems"],["Light Scan","Light Scan"]];
      private static const DWELL_FRAMES:int = 5;
      // Mockup 1: the controls sit 16 in from the card edge, the list rows only 10.
      private static const LIST_PAD:Number = 10;
      // Maker rows are taller than part rows in the compact list (41 against 37 in mockup 1).
      private static const GROUP_EXTRA:Number = 4;
      // Mockup 1 gaps under the tab row, the pager and the title row.
      private static const TAB_ROW_GAP:Number = 16;
      private static const PAGER_GAP:Number = 20;
      private static const TITLE_ROW_GAP:Number = 14;
      private static const PILL_ON:int = 0;
      private static const PILL_OFF:int = 1;
      private static const PILL_BUTTON:int = 2;

      private var hsb:HorizonShipBuilder;
      internal var collapsed:Boolean = false;
      internal var readOnly:Boolean = false;
      private var data:Object;
      private var rows:Array;
      private var tabName:String = "";
      private var tabId:String = "Tab";
      private var statName:String = "";
      private var statId:String = "stat1";
      private var upgrade:Boolean = false;
      private var cats:Object;
      private var catIndex:int = -1;
      private var catTotal:int = -1;
      private var seen:Object;
      private var statLabels:Object;
      // Stat ids the game marks bPercentage: cached and compared in percent, shown with "%".
      private var statPct:Object;
      private var previewId:String = "";
      private var selId:String = "";
      private var nativeSel:String = "";
      private var flat:Array;
      private var shownRows:Array;
      private var leaves:Array;
      private var scroll:int = 0;
      private var open:Object;
      private var grid:Boolean = false;
      private var findText:String = "";
      private var findOn:Boolean = false;
      private var colsPop:HsbColumns;
      private var sortCol:String = "";
      private var sortDesc:Boolean = false;
      private var makerChip:String = "";
      private var dirty:Boolean = true;
      private var fedSig:String = "";
      private var fedEmpty:Boolean = false;
      private var hoverId:String = "";
      private var hoverAt:int = 0;
      private var listTop:Number = 0;
      private var listH:Number = 0;
      private var pitch:Number = 37;
      private var unchecked:int = 0;
      private var discover:Object;
      // The category a jump is heading for; -1 when no jump is under way.
      private var pending:int = -1;
      private var gridFocus:int = -1;
      private var lastPaint:int = -1;
      private var columnPreview:Array = null;
      private var makerRest:Array = [];

      public function HsbBrowser(param1:HsbKit, param2:HorizonShipBuilder)
      {
         super(param1,"HsbBrowser");
         this.hsb = param2;
         this.rows = [];
         this.cats = {};
         this.seen = {};
         this.statLabels = {};
         this.statPct = {};
         this.flat = [];
         this.shownRows = [];
         this.leaves = [];
         this.open = {};
         this.boxW = param1.lrg ? 560 : 501;
         this.boxH = 846;
      }

      internal function invalidate():void
      {
         this.dirty = true;
      }

      // ---- data ----------------------------------------------------------------------------

      internal function onParts(param1:Object):void
      {
         this.data = param1;
         if(!Boolean(param1.bShowWidget))
         {
            this.previewId = "";
            this.nativeSel = "";
            this.invalidate();
            return;
         }
         this.upgrade = Boolean(param1.bIsUpgradeMode);
         var raw:String = String(param1.sCategoryName);
         var t:TextField = this.kit.text(13,0);
         this.kit.put(t,raw);
         this.tabName = t.text;
         this.tabId = HsbPillModel.tabKey(raw);
         this.kit.put(t,param1.sStatName1);
         this.statName = t.text;
         this.statId = HsbPillModel.columnId(String(param1.sStatName1)).toLowerCase();
         if(this.statId.length == 0) { this.statId = "stat1"; }
         var list:Array = param1.aPartList as Array;
         var built:Array = [];
         var i:int = 0;
         while(list != null && i < list.length)
         {
            var e:Object = list[i];
            if(e != null && e.uFormID != null)
            {
               var name:String = String(e.text);
               built.push({"id":String(e.uFormID),"name":name,"raw":e,"stat1":Number(e.iStat1),"variants":int(e.iVariants),"disabled":Boolean(e.bDisabled),"order":i});
            }
            i++;
         }
         this.rows = built;
         this.assignMakers();
         if(!this.upgrade)
         {
            this.catIndex = int(param1.iCategoryIndex);
            this.learnCat(this.catIndex,this.tabName,built.length,raw);
            this.learnCat(this.catIndex - 1,this.cleanText(param1.sPrevCategoryName),-1,String(param1.sPrevCategoryName));
            this.learnCat(this.catIndex + 1,this.cleanText(param1.sNextCategoryName),-1,String(param1.sNextCategoryName));
         }
         this.applyColumnDefaults();
         var start:int = int(param1.iStartingIndex);
         var startRow:Object = list != null && start >= 0 && start < list.length ? list[start] : null;
         this.previewId = startRow != null && startRow.uFormID != null ? String(startRow.uFormID) : "";
         this.selId = this.previewId;
         this.nativeSel = this.previewId;
         this.fedSig = "";
         this.scroll = 0;
         this.rebuild();
         this.refeed();
         this.ensureVisible(this.selId);
         this.invalidate();
         this.stepDiscovery();
         this.stepPending();
      }

      private function cleanText(param1:*):String
      {
         var t:TextField = this.kit.text(13,0);
         this.kit.put(t,param1);
         return t.text;
      }

      private function learnCat(param1:int, param2:String, param3:int, param4:String):void
      {
         if(param2 == null || param2.length == 0) { return; }
         var idx:int = param1;
         if(this.catTotal > 0) { idx = (idx % this.catTotal + this.catTotal) % this.catTotal; }
         if(idx < 0) { return; }
         var have:Object = this.cats[idx];
         if(have == null) { have = {"name":param2,"count":-1,"raw":param4}; this.cats[idx] = have; }
         have.name = param2;
         have.raw = param4;
         if(param3 >= 0) { have.count = param3; }
      }

      // ModuleInfo describes the part the game previews; cache its numbers for columns and pills.
      // Purpose: cache the numbers the game's card shows (ModuleInfo) under the previewed row,
      //    so the list can show and sort Value, Mass and stat columns for parts already seen.
      // Rules: ModuleInfo also arrives for modules picked on the ship while the palette is closed,
      //    and a late one can describe the previous preview, so it is kept only while the palette
      //    and the card are shown and only when its name is the previewed row's name. A part
      //    with no match keeps a dash rather than another part's numbers.
      internal function learn(param1:Object):void
      {
         if(param1 == null || !Boolean(param1.bShowWidget)) { return; }
         if(this.data == null || !Boolean(this.data.bShowWidget)) { return; }
         var id:String = this.previewId.length > 0 ? this.previewId : this.nativeSel;
         if(id.length == 0) { return; }
         var r:Object = this.rowById(id);
         if(r == null) { return; }
         if(this.cleanText(param1.sModuleName).toLowerCase() != this.cleanText(r.name).toLowerCase()) { return; }
         var row:Object = this.seen[id];
         if(row == null) { row = {}; this.seen[id] = row; }
         row.stats = {};
         row.value = param1.iModuleCost != null ? Number(param1.iModuleCost) : null;
         row.mass = param1.iModuleMass != null ? Number(param1.iModuleMass) : null;
         var stats:Array = param1.aStats as Array;
         var i:int = 0;
         while(stats != null && i < stats.length)
         {
            var s:Object = stats[i];
            var raw:String = String(s.text);
            if(raw == "$CLASS") { row.cls = String.fromCharCode(s.fValue); }
            else
            {
               var sid:String = HsbPillModel.columnId(raw).toLowerCase();
               if(sid.length > 0)
               {
                  var pct:Boolean = Boolean(s.bPercentage);
                  row.stats[sid] = pct ? Number(s.fValue) * 100 : Number(s.fValue);
                  if(pct) { this.statPct[sid] = true; }
                  if(this.statLabels[sid] == null) { this.statLabels[sid] = this.cleanText(raw); }
               }
            }
            i++;
         }
         this.fill(r);
         this.rebuild();
         this.invalidate();
      }

      private function fill(param1:Object):void
      {
         var c:Object = this.seen[param1.id];
         if(c == null) { return; }
         param1.value = c.value;
         param1.mass = c.mass;
         param1.cls = c.cls;
         param1.stats = c.stats;
      }

      private function rowById(param1:String):Object
      {
         var i:int = 0;
         while(i < this.rows.length)
         {
            if(String(this.rows[i].id) == param1) { return this.rows[i]; }
            i++;
         }
         return null;
      }

      internal static function makerOf(param1:String):String
      {
         var i:int = 0;
         while(i < KNOWN_MAKERS.length)
         {
            var p:String = String(KNOWN_MAKERS[i][0]);
            if(param1.indexOf(p) == 0 && (param1.length == p.length || param1.charAt(p.length) == " ")) { return String(KNOWN_MAKERS[i][1]); }
            i++;
         }
         return "";
      }

      private static function makerPrefix(param1:String):String
      {
         var i:int = 0;
         while(i < KNOWN_MAKERS.length)
         {
            var p:String = String(KNOWN_MAKERS[i][0]);
            if(param1.indexOf(p) == 0 && (param1.length == p.length || param1.charAt(p.length) == " ")) { return p; }
            i++;
         }
         return "";
      }

      internal static function sizeOf(param1:String):String
      {
         var m:Array = param1.match(/(\d+)\s*x\s*(\d+)(\s*x\s*(\d+))?/);
         if(m == null) { return ""; }
         return String(m[0]).split(" ").join("");
      }

      // Known brands first; otherwise the first word, when two or more parts on this tab start
      // with it. Everything else groups under "Other".
      private function assignMakers():void
      {
         var counts:Object = {};
         var i:int = 0;
         while(i < this.rows.length)
         {
            var first:String = String(this.rows[i].name).split(" ")[0];
            counts[first] = int(counts[first]) + 1;
            i++;
         }
         var sized:int = 0;
         i = 0;
         while(i < this.rows.length)
         {
            var r:Object = this.rows[i];
            var name:String = String(r.name);
            var maker:String = makerOf(name);
            var prefix:String = makerPrefix(name);
            if(maker.length == 0)
            {
               var w:String = name.split(" ")[0];
               if(int(counts[w]) >= 2 && w.length > 1 && w.charAt(0) == w.charAt(0).toUpperCase() && sizeOf(w).length == 0) { maker = w; prefix = w; }
            }
            r.maker = maker.length > 0 ? maker : "Other";
            r.prefix = prefix;
            r.size = sizeOf(name);
            if(String(r.size).length > 0) { sized++; }
            this.fill(r);
            i++;
         }
         this.sizesOnTab = sized * 2 >= this.rows.length && this.rows.length > 0;
      }

      private var sizesOnTab:Boolean = false;

      internal function makerFor(param1:String):String
      {
         var r:Object = this.rowByName(param1);
         if(r != null && String(r.maker) != "Other") { return String(r.maker); }
         return makerOf(param1);
      }

      private function rowByName(param1:String):Object
      {
         var i:int = 0;
         while(i < this.rows.length)
         {
            if(String(this.rows[i].name) == param1) { return this.rows[i]; }
            i++;
         }
         return null;
      }

      internal function variantLine():String
      {
         var r:Object = this.rowById(this.selId);
         if(r == null || int(r.variants) <= 1) { return ""; }
         var v:Object = this.hsb.dVariant;
         var at:int = v != null ? int(v.iVariantDirection) : -1;
         if(at >= 0 && at < int(r.variants)) { return "variant " + (at + 1) + " of " + int(r.variants); }
         return int(r.variants) + " variants";
      }

      // ---- columns -------------------------------------------------------------------------

      // A pill that is on and brings columns wins; otherwise the tab's own set.
      internal function columns():Array
      {
         var pill:Object = this.pillColumns();
         if(pill != null) { return (pill.columns as Array).slice(0,HsbPillModel.MAX_COLUMNS); }
         return this.tabColumns();
      }

      // The column chooser shows its changes live; null ends the preview.
      internal function previewColumns(param1:Array):void
      {
         this.columnPreview = param1;
         this.rebuild();
         this.invalidate();
      }

      internal function defaultColumns():Array
      {
         return [this.statId,"mass","value"];
      }

      internal function sortInfo():Object
      {
         return {"col":this.sortCol,"desc":this.sortDesc};
      }

      // Display name of a tab key, from the categories learned so far.
      internal function tabNameFor(param1:String):String
      {
         var key:String;
         for(key in this.cats)
         {
            var cat:Object = this.cats[key];
            if(cat != null && HsbPillModel.tabKey(String(cat.raw)) == param1) { return String(cat.name); }
         }
         // A tab the builder has not visited yet reads from its key: "GravDrives" as "Grav Drives".
         return param1 == "*" ? "All tabs" : HsbPillModel.words(param1,true);
      }

      internal function tabColumns():Array
      {
         if(this.columnPreview != null) { return this.columnPreview.slice(); }
         var raw:String = this.hsb.columnSets[this.tabId] != null ? String(this.hsb.columnSets[this.tabId]) : "";
         if(raw.length > 0)
         {
            var out:Array = [];
            var bits:Array = raw.split(",");
            var k:int = 0;
            while(k < bits.length && out.length < HsbPillModel.MAX_COLUMNS)
            {
               var id:String = HsbPillModel.columnId(String(bits[k]));
               if(id.length > 0 && id != "name") { out.push(id); }
               k++;
            }
            if(out.length > 0) { return out; }
         }
         return this.defaultColumns();
      }

      internal function pillColumns():Object
      {
         var on:Array = this.hsb.pills.onFor(this.tabId);
         var i:int = 0;
         while(i < on.length)
         {
            if(on[i].columns is Array && (on[i].columns as Array).length > 0) { return on[i]; }
            i++;
         }
         return null;
      }

      internal function availableColumns():Array
      {
         var out:Array = [this.statId,"value","mass","variants","maker"];
         if(this.sizesOnTab) { out.push("size"); }
         out.push("class");
         var sid:String;
         for(sid in this.statLabels)
         {
            if(out.indexOf(sid) < 0 && sid != this.statId) { out.push(sid); }
         }
         return out;
      }

      internal function columnLabel(param1:String):String
      {
         if(param1 == this.statId) { return this.statName.length > 0 ? this.statName : "Stat"; }
         var map:Object = {"name":"Name","value":"Value","mass":"Mass","variants":"Variants","maker":"Maker","size":"Size","class":"Class"};
         if(map[param1] != null) { return String(map[param1]); }
         if(this.statLabels[param1] != null)
         {
            var s:String = String(this.statLabels[param1]);
            return s.charAt(0).toUpperCase() + s.substring(1).toLowerCase();
         }
         return HsbPillModel.spokenName(param1);
      }

      internal function cellValue(param1:Object, param2:String):*
      {
         if(param2 == "name") { return String(param1.name); }
         if(param2 == this.statId) { return isNaN(Number(param1.stat1)) ? null : Number(param1.stat1); }
         if(param2 == "value") { return param1.value; }
         if(param2 == "mass") { return param1.mass; }
         if(param2 == "variants") { return int(param1.variants); }
         if(param2 == "maker") { return param1.maker; }
         if(param2 == "size") { return String(param1.size).length > 0 ? param1.size : null; }
         if(param2 == "class") { return param1.cls; }
         return param1.stats != null ? param1.stats[param2] : null;
      }

      internal function tabKeyNow():String
      {
         return this.tabId;
      }

      internal function tabLabel():String
      {
         return this.tabName;
      }

      internal function saveColumns(param1:Array):void
      {
         this.hsb.columnSets[this.tabId] = param1.join(",");
         this.hsb.setSetting("Columns",this.tabId,param1.join(","));
         this.hsb.saveSettings();
         this.rebuild();
         this.invalidate();
      }

      internal function resetColumns():void
      {
         delete this.hsb.columnSets[this.tabId];
         this.hsb.setSetting("Columns",this.tabId,"");
         this.hsb.saveSettings();
         this.rebuild();
         this.invalidate();
      }

      private function applyColumnDefaults():void
      {
         var raw:String = this.hsb.columnSets[this.tabId + "Sort"] != null ? String(this.hsb.columnSets[this.tabId + "Sort"]) : "";
         if(raw.length > 0)
         {
            this.sortDesc = raw.charAt(raw.length - 1) == "-";
            this.sortCol = HsbPillModel.columnId(raw);
         }
      }

      // ---- model ---------------------------------------------------------------------------

      private function ctx():Object
      {
         return {"credits":this.hsb.partCredits(),"sizes":this.sizesOnTab,"statIds":this.availableColumns()};
      }

      private function passes(param1:Object, param2:Object):Boolean
      {
         var on:Array = this.hsb.pills.onFor(this.tabId);
         var i:int = 0;
         var unknown:Boolean = false;
         while(i < on.length)
         {
            var t:int = HsbPillModel.test(on[i],param1,param2);
            if(t == 0) { return false; }
            if(t == 2) { unknown = true; }
            i++;
         }
         if(this.findText.length > 0)
         {
            var needle:String = this.findText.toLowerCase();
            if(String(param1.name).toLowerCase().indexOf(needle) < 0 && String(param1.maker).toLowerCase().indexOf(needle) < 0) { return false; }
         }
         if(this.grid && this.makerChip.length > 0 && String(param1.maker) != this.makerChip) { return false; }
         if(unknown) { this.unchecked++; }
         return true;
      }

      private function compare(param1:Object, param2:Object):int
      {
         if(this.sortCol.length == 0) { return int(param1.order) - int(param2.order); }
         var a:* = this.cellValue(param1,this.sortCol);
         var b:* = this.cellValue(param2,this.sortCol);
         if(a == null && b == null) { return int(param1.order) - int(param2.order); }
         if(a == null) { return 1; }
         if(b == null) { return -1; }
         var out:int = 0;
         if(a is String || b is String)
         {
            var sa:String = String(a).toLowerCase();
            var sb:String = String(b).toLowerCase();
            out = sa < sb ? -1 : (sa > sb ? 1 : 0);
         }
         else { out = Number(a) < Number(b) ? -1 : (Number(a) > Number(b) ? 1 : 0); }
         if(out == 0) { return int(param1.order) - int(param2.order); }
         return this.sortDesc ? -out : out;
      }

      // Builds the display list (groups, size sub-groups, parts) and the order the game's list
      // is fed in (every matching part, even inside closed groups, so arrows reach them).
      private function rebuild():void
      {
         this.unchecked = 0;
         var c:Object = this.ctx();
         var shown:Array = [];
         var i:int = 0;
         while(i < this.rows.length)
         {
            if(this.passes(this.rows[i],c)) { shown.push(this.rows[i]); }
            i++;
         }
         var self:HsbBrowser = this;
         shown.sort(function(a:Object, b:Object):int { return self.compare(a,b); });
         this.shownRows = shown;
         var out:Array = [];
         var order:Array = [];
         if(this.hsb.byMaker && !this.grid && !this.readOnly)
         {
            var makers:Array = [];
            var groups:Object = {};
            i = 0;
            while(i < shown.length)
            {
               var m:String = String(shown[i].maker);
               if(groups[m] == null) { groups[m] = []; makers.push(m); }
               (groups[m] as Array).push(shown[i]);
               i++;
            }
            makers.sort(function(a:String, b:String):int
            {
               if(a == "Other") { return 1; }
               if(b == "Other") { return -1; }
               return a.toLowerCase() < b.toLowerCase() ? -1 : (a.toLowerCase() > b.toLowerCase() ? 1 : 0);
            });
            var g:int = 0;
            while(g < makers.length)
            {
               var maker:String = String(makers[g]);
               var parts:Array = groups[maker] as Array;
               var openG:Boolean = this.open["m:" + maker] == true;
               out.push({"type":"group","key":"m:" + maker,"label":maker,"rows":parts,"open":openG,"depth":0});
               var subs:Array = this.subGroups(parts);
               var s:int = 0;
               while(s < subs.length)
               {
                  var sg:Object = subs[s];
                  if(sg.rows.length >= 2 && this.sizesOnTab)
                  {
                     var key:String = "s:" + maker + "|" + sg.size;
                     var openS:Boolean = this.open[key] == true;
                     if(openG) { out.push({"type":"sub","key":key,"label":this.subLabel(sg.size),"rows":sg.rows,"open":openS,"depth":1}); }
                     var r:int = 0;
                     while(r < sg.rows.length)
                     {
                        order.push(sg.rows[r]);
                        if(openG && openS) { out.push({"type":"leaf","row":sg.rows[r],"depth":2,"short":this.shortName(sg.rows[r],true)}); }
                        r++;
                     }
                  }
                  else
                  {
                     var q:int = 0;
                     while(q < sg.rows.length)
                     {
                        order.push(sg.rows[q]);
                        if(openG) { out.push({"type":"leaf","row":sg.rows[q],"depth":1,"short":this.shortName(sg.rows[q],false)}); }
                        q++;
                     }
                  }
                  s++;
               }
               g++;
            }
         }
         else
         {
            i = 0;
            while(i < shown.length)
            {
               out.push({"type":"leaf","row":shown[i],"depth":0,"short":String(shown[i].name)});
               order.push(shown[i]);
               i++;
            }
         }
         this.flat = out;
         this.leaves = order;
      }

      private function subGroups(param1:Array):Array
      {
         var out:Array = [];
         var by:Object = {};
         var i:int = 0;
         while(i < param1.length)
         {
            var size:String = String(param1[i].size);
            var key:String = size.length > 0 ? size : "-";
            if(by[key] == null)
            {
               by[key] = {"size":size,"rows":[]};
               out.push(by[key]);
            }
            by[key].rows.push(param1[i]);
            i++;
         }
         return out;
      }

      private function subLabel(param1:String):String
      {
         var word:String = this.tabName;
         if(word.length > 3 && word.charAt(word.length - 1).toLowerCase() == "s") { word = word.substring(0,word.length - 1); }
         word = word.charAt(0).toUpperCase() + word.substring(1).toLowerCase();
         return word + " " + param1;
      }

      private function shortName(param1:Object, param2:Boolean):String
      {
         var name:String = String(param1.name);
         var prefix:String = String(param1.prefix);
         if(prefix.length > 0 && name.indexOf(prefix) == 0) { name = name.substring(prefix.length); }
         if(param2 && String(param1.size).length > 0) { name = name.split(String(param1.size)).join(""); }
         name = HsbPillModel.trim(name.split("  ").join(" "));
         return name.length > 0 ? name : String(param1.name);
      }

      // ---- the game's list -----------------------------------------------------------------

      private function palette():Object
      {
         var p:Object = null;
         try { p = this.hsb.kit != null ? this.hostObj()["ModulePalette_mc"] : null; } catch(err:Error) { p = null; }
         return p;
      }

      private function hostObj():Object
      {
         return this.hsb.hostClip();
      }

      private function nativeList():Object
      {
         var p:Object = this.palette();
         if(p == null) { return null; }
         var l:Object = null;
         try { l = p["ModuleEntries_mc"]; } catch(err:Error) { l = null; }
         return l;
      }

      // Feeds the game's list in Horizon's order. The list's own visible flag is false for the
      // duration: vanilla's onListSelectionChanged returns early then, so the re-feed sends no
      // preview of its own. Never feeds an empty list (vanilla's handlers dereference the
      // selected entry); input is paused instead while nothing matches.
      private function refeed():void
      {
         var list:Object = this.nativeList();
         if(list == null || this.readOnly) { return; }
         var ids:Array = [];
         var entries:Array = [];
         var i:int = 0;
         while(i < this.leaves.length)
         {
            ids.push(String(this.leaves[i].id));
            entries.push(this.leaves[i].raw);
            i++;
         }
         try
         {
            if(entries.length == 0)
            {
               list.disableInput = true;
               this.fedEmpty = true;
               this.fedSig = "empty";
               return;
            }
            if(this.fedEmpty) { list.disableInput = false; this.fedEmpty = false; }
            var current:String = "";
            var se:Object = list.selectedEntry;
            if(se != null && se.uFormID != null) { current = String(se.uFormID); }
            var want:String = ids.indexOf(this.selId) >= 0 ? this.selId : (ids.indexOf(current) >= 0 ? current : String(ids[0]));
            var j:int = ids.indexOf(want);
            var was:Boolean = Boolean(list.visible);
            list.visible = false;
            list.InitializeEntries(entries);
            list.selectedIndex = j;
            list.visible = was;
            this.fedSig = this.sigOf(ids);
            this.selId = want;
            this.nativeSel = want;
            if(want != this.previewId && was)
            {
               this.previewId = want;
               this.palette().onListSelectionChanged();
            }
         }
         catch(err:Error)
         {
            this.hsb.note("REFEED fault " + err.errorID);
         }
      }

      private function sigOf(param1:Array):String
      {
         if(param1.length == 0) { return "empty"; }
         return param1.length + ":" + param1[0] + ":" + param1[param1.length - 1];
      }

      private function nativeSig():String
      {
         var list:Object = this.nativeList();
         if(list == null) { return ""; }
         try
         {
            var n:int = int(list.entryCount);
            if(n == 0) { return "empty"; }
            return n + ":" + String(list.GetDataForEntry(0).uFormID) + ":" + String(list.GetDataForEntry(n - 1).uFormID);
         }
         catch(err:Error)
         {
         }
         return "";
      }

      // Hover and click both go through the game's list, so the preview, the sound and the
      // controller state are the game's own.
      private function selectPart(param1:String):void
      {
         var list:Object = this.nativeList();
         if(list == null || this.readOnly) { return; }
         var j:int = -1;
         var i:int = 0;
         while(i < this.leaves.length)
         {
            if(String(this.leaves[i].id) == param1) { j = i; break; }
            i++;
         }
         if(j < 0) { return; }
         try
         {
            if(int(list.selectedIndex) != j) { list.selectedIndex = j; }
            this.selId = param1;
            this.nativeSel = param1;
            this.previewId = param1;
         }
         catch(err:Error)
         {
            this.hsb.note("SELECT fault " + err.errorID);
         }
         this.invalidate();
      }

      private function placePart(param1:String):void
      {
         if(this.readOnly) { return; }
         this.selectPart(param1);
         try { this.palette().onListEntrySelected(); }
         catch(err:Error) { this.hsb.note("PLACE fault " + err.errorID); }
      }

      internal function tick():void
      {
         if(!this.visible || this.data == null)
         {
            if(this.dirty && this.visible) { this.paint(); }
            return;
         }
         var list:Object = this.nativeList();
         if(list != null && !this.readOnly)
         {
            try
            {
               var se:Object = list.selectedEntry;
               var id:String = se != null && se.uFormID != null ? String(se.uFormID) : "";
               if(id.length > 0 && id != this.nativeSel)
               {
                  this.nativeSel = id;
                  this.selId = id;
                  this.previewId = id;
                  this.ensureVisible(id);
                  this.invalidate();
               }
            }
            catch(err:Error)
            {
            }
            if(this.hsb.frame() % 15 == 0 && this.fedSig.length > 0 && this.fedSig != "empty")
            {
               var now:String = this.nativeSig();
               if(now.length > 0 && now != this.fedSig) { this.refeed(); }
            }
         }
         if(this.hoverId.length > 0 && this.hsb.frame() - this.hoverAt == DWELL_FRAMES && this.hoverId != this.selId) { this.selectPart(this.hoverId); }
         if(this.dirty) { this.paint(); }
      }

      private function ensureVisible(param1:String):void
      {
         var i:int = 0;
         while(i < this.leaves.length)
         {
            var r:Object = this.leaves[i];
            if(String(r.id) == param1)
            {
               if(this.hsb.byMaker && !this.grid)
               {
                  var key:String = "m:" + String(r.maker);
                  if(this.open[key] != true) { this.open[key] = true; this.rebuild(); }
                  var sk:String = "s:" + String(r.maker) + "|" + String(r.size);
                  if(this.open[sk] != true && this.sizesOnTab) { this.open[sk] = true; this.rebuild(); }
               }
               break;
            }
            i++;
         }
         var at:int = -1;
         var f:int = 0;
         while(f < this.flat.length)
         {
            if(this.flat[f].type == "leaf" && String(this.flat[f].row.id) == param1) { at = f; break; }
            f++;
         }
         if(at < 0) { return; }
         if(at < this.scroll) { this.scroll = at; }
         else { while(this.scroll < at && !this.fits(this.scroll,at)) { this.scroll++; } }
      }

      private function perPage():int
      {
         return Math.max(1,int(this.listH / this.pitch));
      }

      private function rowPitch(param1:Object):Number
      {
         var tall:Boolean = param1 != null && param1.type == "group" && this.hsb.density != "detailed" && !this.grid && !this.readOnly;
         return tall ? this.pitch + this.kit.u(GROUP_EXTRA) : this.pitch;
      }

      // True when rows from..to of the tree all show at once.
      private function fits(param1:int, param2:int):Boolean
      {
         var used:Number = 0;
         var i:int = param1;
         while(i <= param2 && i < this.flat.length)
         {
            used += this.rowPitch(this.flat[i]);
            i++;
         }
         return used <= this.listH;
      }

      // The highest scroll position that still fills the list: the last row shows at the bottom.
      private function lastStart():int
      {
         var room:Number = this.listH;
         var i:int = this.flat.length - 1;
         while(i >= 0)
         {
            room -= this.rowPitch(this.flat[i]);
            if(room < 0) { break; }
            i--;
         }
         return Math.max(0,i + 1);
      }

      // ---- categories ----------------------------------------------------------------------

      private function changeCategory(param1:int):void
      {
         if(param1 == 0 || this.upgrade) { return; }
         this.hsb.send("ShipEditor_ChangeModuleCategory",{"iCategoryOffset":param1});
      }

      // Jumps to a category one step at a time, the way the vanilla LB and RB move (offset -1 or
      // +1; the game's handling of larger offsets is not known). stepPending sends the next
      // step as each new category arrives, the short way round the ring.
      private function goCategory(param1:int):void
      {
         if(param1 == this.catIndex) { return; }
         var offset:int = param1 - this.catIndex;
         if(this.catTotal > 0)
         {
            var fwd:int = ((param1 - this.catIndex) % this.catTotal + this.catTotal) % this.catTotal;
            offset = fwd <= this.catTotal / 2 ? fwd : fwd - this.catTotal;
         }
         this.pending = param1;
         this.pendingTries = 0;
         this.changeCategory(offset > 0 ? 1 : -1);
      }

      private var pendingTries:int = 0;

      private function stepPending():void
      {
         if(this.pending < 0 || this.discover != null) { return; }
         if(this.catIndex == this.pending || this.pendingTries > 64)
         {
            this.pending = -1;
            return;
         }
         this.pendingTries++;
         var dir:int = this.pending > this.catIndex ? 1 : -1;
         if(this.catTotal > 0)
         {
            var fwd:int = ((this.pending - this.catIndex) % this.catTotal + this.catTotal) % this.catTotal;
            dir = fwd <= this.catTotal / 2 ? 1 : -1;
         }
         this.changeCategory(dir);
      }

      // The game sends one category at a time. Opening the grid steps once around the ring so
      // every name and count is known; the ring ends where it started.
      private function startDiscovery():void
      {
         if(this.upgrade || this.discover != null || this.catTotal > 0 || this.catIndex < 0) { return; }
         this.discover = {"start":this.catIndex,"startName":this.tabName,"steps":0};
         this.hsb.note("CATEGORIES read start");
         this.changeCategory(1);
      }

      private function stepDiscovery():void
      {
         if(this.discover == null) { return; }
         this.discover.steps = int(this.discover.steps) + 1;
         var back:Boolean = this.catIndex == int(this.discover.start) && this.tabName == String(this.discover.startName);
         if(back || int(this.discover.steps) > 64)
         {
            this.catTotal = back ? int(this.discover.steps) : -1;
            if(back)
            {
               var fixed:Object = {};
               var key:String;
               for(key in this.cats)
               {
                  var n:int = int(key);
                  if(n >= 0 && n < this.catTotal) { fixed[n] = this.cats[key]; }
               }
               this.cats = fixed;
            }
            this.hsb.note("CATEGORIES read total=" + this.catTotal);
            this.discover = null;
            this.invalidate();
            return;
         }
         if(this.catIndex == 0 && int(this.discover.steps) > 1 && this.cats[this.discover.steps] == null)
         {
            this.catTotal = -1;
         }
         this.changeCategory(1);
      }

      private function catIcon(param1:String):String
      {
         var n:String = param1.toLowerCase();
         var map:Array = [["weapon","cat:weapons"],["engine","cat:engines"],["reactor","cat:reactors"],["grav","cat:gravdrives"],["shield","cat:shields"],["fuel","cat:fueltanks"],["cargo","cat:cargo"],["cockpit","cat:cockpits"],["hab","cat:habs"],["bay","cat:bays"],["dock","cat:dockers"],["gear","cat:gear"],["struct","cat:structural"],["equip","cat:equipment"]];
         var i:int = 0;
         while(i < map.length)
         {
            if(n.indexOf(String(map[i][0])) >= 0) { return String(map[i][1]); }
            i++;
         }
         return "cat:other";
      }

      // ---- find ----------------------------------------------------------------------------

      internal function startFind():void
      {
         if(this.readOnly) { return; }
         this.findOn = true;
         this.hsb.beginText(this);
         this.invalidate();
      }

      private function stopFind():void
      {
         this.findOn = false;
         this.hsb.endText(this);
         this.invalidate();
      }

      // Ends typing and keeps the text as a filter, as ENTER does. Find holds the keyboard and,
      // through capture, every press on screen, so the hub ends it whenever the field leaves the
      // screen, a popup opens or the player presses outside the browser.
      internal function endFind():void
      {
         if(this.findOn) { this.stopFind(); }
      }

      override internal function onKey(param1:String):Boolean
      {
         if(!this.findOn)
         {
            if(this.grid) { return this.gridKey(param1); }
            return false;
         }
         if(param1 == "cancel")
         {
            this.findText = "";
            this.stopFind();
            this.afterFilter();
            return true;
         }
         if(param1 == "ok" || param1 == "tab") { this.stopFind(); return true; }
         if(param1 == "bksp" && this.findText.length > 0)
         {
            this.findText = this.findText.substring(0,this.findText.length - 1);
            this.afterFilter();
            return true;
         }
         if(param1 == "del") { this.findText = ""; this.afterFilter(); return true; }
         return true;
      }

      override internal function onChar(param1:int):void
      {
         if(!this.findOn || param1 < 32 || this.findText.length >= 32) { return; }
         this.findText += String.fromCharCode(param1);
         this.afterFilter();
      }

      private function gridKey(param1:String):Boolean
      {
         var keys:Array = this.catKeys();
         if(keys.length == 0) { return false; }
         if(this.gridFocus < 0) { this.gridFocus = keys.indexOf(this.catIndex); }
         if(param1 == "left" || param1 == "up") { this.gridFocus = Math.max(0,this.gridFocus - 1); this.invalidate(); return true; }
         if(param1 == "right" || param1 == "down") { this.gridFocus = Math.min(keys.length - 1,this.gridFocus + 1); this.invalidate(); return true; }
         if(param1 == "ok" && this.gridFocus >= 0)
         {
            if(this.discover == null) { this.pick(int(keys[this.gridFocus])); }
            return true;
         }
         return false;
      }

      private function afterFilter():void
      {
         this.rebuild();
         this.scroll = 0;
         this.refeed();
         this.invalidate();
      }

      internal function afterPills():void
      {
         this.afterFilter();
      }

      // ---- input ---------------------------------------------------------------------------

      override internal function onHover(param1:Number, param2:Number):void
      {
         if(param1 < 0)
         {
            this.hoverId = "";
            return;
         }
         var hit:Object = this.hitAt(param1,param2);
         var id:String = hit != null && String(hit.id) == "leaf" ? String(hit.data) : "";
         if(id != this.hoverId)
         {
            this.hoverId = id;
            this.hoverAt = this.hsb.frame();
         }
      }

      override internal function onWheel(param1:Number, param2:Number, param3:Number):void
      {
         this.scroll = HorizonShipBuilder.clampInt(this.scroll - int(param1) * 3,0,this.lastStart());
         this.invalidate();
      }

      override internal function onAct(param1:String, param2:*):void
      {
         if(this.discover != null && param1 != "collapse") { return; }
         switch(param1)
         {
            case "expand": this.hsb.setCollapsed("Browser",false); break;
            case "collapse": this.hsb.setCollapsed("Browser",true); break;
            case "tab": this.changeCategory(int(param2)); break;
            case "grid":
               this.grid = !this.grid;
               this.makerChip = "";
               this.gridFocus = -1;
               if(this.grid) { this.startDiscovery(); }
               this.afterFilter();
               break;
            case "cat": this.pick(int(param2)); break;
            case "maker":
               this.makerChip = String(param2);
               this.afterFilter();
               break;
            case "makermore": this.openMakers(); break;
            case "find": this.startFind(); break;
            case "pill":
               this.hsb.pills.toggle(String(param2));
               this.afterPills();
               break;
            case "more": this.openMore(); break;
            case "newpill": this.openEditor(null); break;
            case "clear":
               this.hsb.pills.clearTab(this.tabId);
               this.findText = "";
               this.afterPills();
               break;
            case "sort": this.openSort(); break;
            case "head": this.sortBy(String(param2)); break;
            case "columns": this.openColumns(); break;
            case "bymaker":
               this.hsb.byMaker = !this.hsb.byMaker;
               this.hsb.setSetting("Layout","GroupByMaker",this.hsb.byMaker ? "1" : "0");
               this.hsb.saveSettings();
               this.afterFilter();
               this.ensureVisible(this.selId);
               break;
            case "density":
               this.hsb.density = String(param2);
               this.hsb.setSetting("Layout","Density",this.hsb.density);
               this.hsb.saveSettings();
               this.invalidate();
               break;
            case "group":
               this.open[String(param2)] = this.open[String(param2)] != true;
               this.rebuild();
               this.invalidate();
               break;
            case "leaf": this.placePart(String(param2)); break;
            case "banner.dismiss": this.hsb.dismissBanner(false); break;
            case "banner.never": this.hsb.dismissBanner(true); break;
         }
      }

      private function pick(param1:int):void
      {
         this.goCategory(param1);
         this.grid = false;
         this.gridFocus = -1;
         this.invalidate();
      }

      // Purpose: switch the list to Flight Check's read-only view (mockup 13) or back.
      // Inputs: param1, true while Flight Check is open. Outputs: none; repaints on a change.
      // Dependencies: endFind, closeGrid, rebuild, refeed. Typing and the category grid end,
      //    since neither may change the list while Flight Check is reading it. On the way out the
      //    game has already refilled its hidden list in game order (PartEntries, then the
      //    palette's Update) while this list was still read-only, so the rows are rebuilt with
      //    their groups and fed again: a hover or click picks parts by Horizon's order.
      internal function setReadOnly(param1:Boolean):void
      {
         if(this.readOnly == param1) { return; }
         this.readOnly = param1;
         if(param1)
         {
            this.endFind();
            this.closeGrid();
         }
         else
         {
            this.rebuild();
            this.refeed();
            this.ensureVisible(this.selId);
         }
         this.invalidate();
      }

      // The hub treats the open category grid like a popup: it captures keys and the pad, and
      // ESC, B or a press outside the browser closes it without picking a category.
      internal function get gridOpen():Boolean
      {
         return this.grid;
      }

      internal function closeGrid():void
      {
         if(!this.grid) { return; }
         this.grid = false;
         this.gridFocus = -1;
         this.makerChip = "";
         this.afterFilter();
      }

      private function sortBy(param1:String):void
      {
         if(this.sortCol == param1) { this.setSort(param1,!this.sortDesc); }
         else { this.setSort(param1,param1 == "value" || param1 == "mass" || param1 == this.statId); }
      }

      // Purpose: set the tab's sort and remember it. Inputs: param1, a column id, "name", or ""
      //    for game order; param2, high to low. Outputs: none; the list re-sorts.
      // Every way to sort comes through here: each PartEntries re-applies the saved sort, so an
      // unsaved choice would flip back on the game's next update.
      private function setSort(param1:String, param2:Boolean):void
      {
         this.sortCol = param1;
         this.sortDesc = param1.length > 0 && param2;
         this.hsb.columnSets[this.tabId + "Sort"] = this.sortCol + (this.sortDesc ? "-" : "");
         this.hsb.setSetting("Columns",this.tabId + "Sort",this.sortCol.length > 0 ? this.sortCol + (this.sortDesc ? "-" : "") : "");
         this.hsb.saveSettings();
         this.afterFilter();
      }

      private function openSort():void
      {
         var items:Array = [{"label":"Game order","id":"sort","data":"","on":this.sortCol.length == 0}];
         var cols:Array = this.columns();
         var i:int = 0;
         while(i < cols.length)
         {
            items.push({"label":this.columnLabel(String(cols[i])),"id":"sort","data":String(cols[i]),"on":this.sortCol == String(cols[i])});
            i++;
         }
         items.push({"label":"Name","id":"sort","data":"name","on":this.sortCol == "name"});
         var self:HsbBrowser = this;
         var menu:HsbDialog = HsbDialog.menu(this.kit,this.hsb,"SORT",items,function(param1:String, param2:*):void
         {
            if(String(param2) == "" || String(param2) == "name") { self.setSort(String(param2),false); }
            else { self.sortBy(String(param2)); }
         });
         this.popBelow(menu,"sort");
      }

      // The makers that did not fit on the grid's maker row (mockup 4 shows three).
      private function openMakers():void
      {
         var items:Array = [];
         var i:int = 0;
         while(i < this.makerRest.length)
         {
            var mname:String = String(this.makerRest[i]);
            items.push({"label":mname,"id":"maker","data":mname,"on":this.makerChip == mname,"right":String(this.countMaker(mname))});
            i++;
         }
         var self:HsbBrowser = this;
         var menu:HsbDialog = HsbDialog.menu(this.kit,this.hsb,"MAKER",items,function(param1:String, param2:*):void
         {
            self.makerChip = String(param2);
            self.afterFilter();
         });
         this.popBelow(menu,"makermore");
      }

      private function openMore():void
      {
         var items:Array = [];
         var list:Array = this.hsb.pills.forTab(this.tabId);
         var i:int = 0;
         while(i < list.length)
         {
            var p:Object = list[i];
            if(p.inRow != true || this.overflow.indexOf(String(p.id)) >= 0)
            {
               var ok:Boolean = HsbPillModel.usable(p);
               items.push({"label":String(p.name),"id":"pill","data":String(p.id),"on":this.hsb.pills.isOn(String(p.id)),"dim":!ok,"note":ok ? "" : "Not available"});
            }
            i++;
         }
         items.push({"label":"Import pills\u2026","id":"import","accent":true});
         items.push({"label":"Export / Share\u2026","id":"export","accent":true});
         items.push({"label":"Manage pills\u2026","id":"manage","accent":true});
         var self:HsbBrowser = this;
         var menu:HsbDialog = HsbDialog.menu(this.kit,this.hsb,"MORE",items,function(param1:String, param2:*):void
         {
            if(param1 == "pill") { self.hsb.pills.toggle(String(param2)); self.afterPills(); }
            else if(param1 == "import") { HsbPillImport.openFor(self.kit,self.hsb,self); }
            else if(param1 == "export" || param1 == "manage") { self.openManage(param1 == "export"); }
         });
         this.popBelow(menu,"more");
      }

      internal function openManage(param1:Boolean):void
      {
         var items:Array = [];
         var list:Array = this.hsb.pills.pills;
         var i:int = 0;
         while(i < list.length)
         {
            items.push({"label":String(list[i].name),"id":param1 ? "export" : "edit","data":String(list[i].id),"right":param1 ? "EXPORT" : "EDIT"});
            i++;
         }
         var self:HsbBrowser = this;
         var menu:HsbDialog = HsbDialog.menu(this.kit,this.hsb,param1 ? "EXPORT / SHARE" : "MANAGE PILLS",items,function(param2:String, param3:*):void
         {
            var p:Object = self.hsb.pills.byId(String(param3));
            if(p == null) { return; }
            if(param2 == "export") { HsbDialog.exportPill(self.kit,self.hsb,p); }
            else { self.openEditor(p); }
         });
         this.popBelow(menu,"more");
      }

      internal function openEditor(param1:Object):void
      {
         var ed:HsbPillEditor = new HsbPillEditor(this.kit,this.hsb,this,param1);
         // Mockup 2: the editor overlaps the browser, 23 px in from its right edge.
         ed.anchorX = this.x + (this.boxW - 23 - ed.boxW) * this.scaleX;
         ed.anchorY = this.y + 96 * this.scaleY;
         this.hsb.openPop(ed);
      }

      private function openColumns():void
      {
         var pop:HsbColumns = new HsbColumns(this.kit,this.hsb,this);
         // Mockup 8: the chooser hangs left of the browser, its top just under the sort row.
         pop.anchorX = this.x + (226 - pop.boxW) * this.scaleX;
         pop.anchorY = this.y + (this.ctrlY + this.kit.u(28) + 4) * this.scaleY;
         this.colsPop = pop;
         this.hsb.openPop(pop);
         this.invalidate();
      }

      private function popBelow(param1:HsbBox, param2:String):void
      {
         var at:Object = null;
         var i:int = 0;
         while(i < this.hits.length)
         {
            if(String(this.hits[i].id) == param2) { at = this.hits[i]; }
            i++;
         }
         if(at != null)
         {
            // Mockup 14: the menu hangs under its button but stays inside the browser card.
            // Popups take the panels' scale when they open, so the browser's scale applies.
            var left:Number = this.x + Number(at.x) * this.scaleX;
            var right:Number = this.x + (this.boxW - 8 - param1.boxW) * this.scaleX;
            param1.anchorX = Math.max(this.x + 8 * this.scaleX,Math.min(left,right));
            param1.anchorY = this.y + (Number(at.y) + Number(at.h) + 6) * this.scaleY;
         }
         this.hsb.openPop(param1);
      }

      // Counts for the editor's "Matches N parts" line.
      internal function countMatches(param1:Object):int
      {
         var c:Object = this.ctx();
         var n:int = 0;
         var i:int = 0;
         while(i < this.rows.length)
         {
            var t:int = HsbPillModel.test(param1,this.rows[i],c);
            if(t == 1 || t == 2) { n++; }
            i++;
         }
         return n;
      }

      internal function makerNames():Array
      {
         var out:Array = [];
         var i:int = 0;
         while(i < this.rows.length)
         {
            var m:String = String(this.rows[i].maker);
            if(out.indexOf(m) < 0) { out.push(m); }
            i++;
         }
         out.sort();
         return out;
      }

      internal function sizeNames():Array
      {
         var out:Array = [];
         var i:int = 0;
         while(i < this.rows.length)
         {
            var s:String = String(this.rows[i].size);
            if(s.length > 0 && out.indexOf(s) < 0) { out.push(s); }
            i++;
         }
         out.sort();
         out.push("Unsized");
         return out;
      }

      internal function statChoices():Array
      {
         var out:Array = [];
         var cols:Array = this.availableColumns();
         var i:int = 0;
         while(i < cols.length)
         {
            var id:String = String(cols[i]);
            if(id != "value" && id != "mass" && id != "variants" && id != "maker" && id != "size" && id != "class") { out.push({"id":"stat:" + id,"label":this.columnLabel(id)}); }
            i++;
         }
         return out;
      }

      internal function statNames():Object
      {
         var out:Object = {};
         out[this.statId] = this.statName;
         var sid:String;
         for(sid in this.statLabels) { out[sid] = this.columnLabel(sid); }
         return out;
      }

      // ---- paint ---------------------------------------------------------------------------

      private var overflow:Array = [];
      private var ctrlY:Number = 0;

      internal function paint():void
      {
         this.dirty = false;
         this.wipe();
         if(!this.visible) { return; }
         var k:HsbKit = this.kit;
         var w:Number = k.lrg ? 560 : 501;
         if(this.collapsed)
         {
            this.paintTab(w);
            return;
         }
         var g:Graphics = this.gfx;
         var h:Number = this.fitHeight();
         k.card(this.graphics,0,0,w,h);
         var pad:Number = 16;
         var y:Number = 14;
         if(this.grid) { y = this.paintGridTop(w,pad,y); }
         else
         {
            // The notice yields while Find is typing so the field stays in view.
            var banner:Boolean = this.hsb.bannerWanted() && !this.findOn;
            if(banner) { y = this.paintBanner(w,pad,y,this.stripTopHeight()); }
            else { y = this.paintStripTop(w,pad,y); }
            // Mockup 13: while Flight Check reads the list there are no pills, sort or columns.
            if(!this.readOnly) { y = this.paintStrip(w,pad,y); }
         }
         if(this.readOnly) { y = this.paintNoteLine(w,pad,y,"Read-only while Flight Check is open",HsbKit.MUTED); }
         var pillsWarn:String = this.hsb.pillsWarning();
         if(pillsWarn.length > 0 && !this.grid && !this.readOnly) { y = this.paintNoteLine(w,pad,y,pillsWarn,HsbKit.ORANGE); }
         this.pitch = this.hsb.density == "detailed" || this.grid || this.readOnly ? k.u(50) : k.u(37);
         var footH:Number = k.u(30);
         this.listTop = y;
         this.listH = h - y - footH - 8;
         if(this.grid || this.readOnly) { this.paintSimpleList(w,LIST_PAD,y); }
         else { this.paintList(w,LIST_PAD,y); }
         var foot:TextField = k.text(13,HsbKit.MUTED);
         var footText:String = "Group rows show ranges \u00B7 open one for single values";
         if(this.unchecked > 0 && !this.readOnly) { footText = this.unchecked + " parts not checked yet \u00B7 preview a part to check it"; }
         else if(this.grid || this.readOnly || !this.hsb.byMaker) { footText = this.shownCount() + " of " + this.rows.length + " shown" + (this.flat.length > this.perPage() ? " \u00B7 scroll for more" : ""); }
         k.put(foot,footText);
         k.fit(foot,w - pad * 2);
         this.add(foot,pad,h - footH);
         this.sized(w,h);
         this.lastPaint = this.hsb.frame();
      }

      // The builder places panels by their painted size; a new size needs a new spot.
      private function sized(param1:Number, param2:Number):void
      {
         var moved:Boolean = param1 != this.boxW || param2 != this.boxH;
         this.boxW = param1;
         this.boxH = param2;
         if(moved) { this.hsb.place(); }
      }

      // Purpose: the browser's height, which the Colours card shares. Outputs: 846 (mockup 1) at
      //    most and 420 at least; in between the browser ends 10 px above the hints bar. The
      //    bars' heights come from the hub, so the large movie's taller bars, a wider screen
      //    margin and the UI scale keep that room.
      internal function fitHeight():Number
      {
         var r:Object = this.hsb.viewRect();
         var edge:Number = this.hsb.margin + 3;
         var sc:Number = this.hsb.uiScale > 0 ? this.hsb.uiScale : 1;
         var bars:Number = this.kit.u(HorizonShipBuilder.STATS_HEIGHT) + this.kit.u(HorizonShipBuilder.HINTS_HEIGHT);
         var room:Number = (r.height - edge * 2 - HorizonShipBuilder.BAR_GAP - 10) / sc - bars;
         return Math.max(420,Math.min(846,room));
      }

      private function shownCount():int
      {
         return this.shownRows.length;
      }

      // Mockup 12: the collapsed browser is a slim tab on the right edge.
      private function paintTab(param1:Number):void
      {
         var k:HsbKit = this.kit;
         var tw:Number = k.u(36);
         var label:TextField = k.text(13,HsbKit.TEXT,true,2);
         k.put(label,this.tabName.toUpperCase());
         k.fit(label);
         var count:TextField = k.text(13,HsbKit.LABEL);
         k.put(count," \u00B7 " + this.shownCount() + " of " + this.rows.length);
         k.fit(count);
         var len:Number = label.width + count.width;
         var th:Number = len + k.u(80);
         k.card(this.graphics,0,0,tw,th,10);
         var s:Number = k.u(22);
         k.fill(this.gfx,(tw - s) / 2,10,s,s,5,0x1A2128,1);
         k.outline(this.gfx,(tw - s) / 2,10,s,s,5,HsbKit.EDGE_HI,1);
         k.icon(this.gfx,"chevL",(tw - s) / 2 + 3,13,s - 6,HsbKit.LABEL,1);
         // Measured before turning: a field turned -90 degrees reads upward from its origin, so
         // it spans its line height across and its text width up.
         var lw:Number = label.width;
         var lh:Number = label.height;
         var ch:Number = count.height;
         label.rotation = -90;
         count.rotation = -90;
         this.add(label,(tw - lh) / 2,th - 30);
         this.add(count,(tw - ch) / 2,th - 30 - lw);
         if(this.hsb.pills.onFor(this.tabId).length > 0) { k.icon(this.gfx,"diamond",(tw - 10) / 2,th - 20,10,k.accent,1); }
         this.hit(0,0,tw,th,"expand");
         this.sized(tw,th);
      }

      // Mockup 11: the notice takes the place of the category tabs and the title row while it
      // is up, so the pills and the list keep their mockup 1 places. param4 is the height of
      // the rows it covers; a longer message grows the notice instead of clipping it.
      private function paintBanner(param1:Number, param2:Number, param3:Number, param4:Number):Number
      {
         var k:HsbKit = this.kit;
         var w:Number = param1 - param2 * 2;
         var textX:Number = param2 + 38;
         var btnH:Number = k.u(28);
         var neverW:Number = k.buttonWidth("Don't show");
         var dismissW:Number = k.buttonWidth("Dismiss");
         var neverX:Number = param2 + w - 12 - neverW;
         var dismissX:Number = neverX - 8 - dismissW;
         var tag:TextField = k.text(12,HsbKit.ORANGE,true,1.5);
         k.put(tag,"WARNING");
         k.fit(tag);
         this.add(tag,textX,param3 + 10);
         var t1:TextField = k.text(14,HsbKit.TEXT,true);
         k.put(t1,"StarUI Ship Builder files found");
         k.fit(t1,w - 50);
         this.add(t1,textX,tag.y + tag.height + 2);
         var t2:TextField = k.text(13,HsbKit.LABEL);
         t2.multiline = true;
         t2.wordWrap = true;
         t2.width = dismissX - 12 - textX;
         k.put(t2,"Horizon is active. If the builder looks wrong, disable one mod and restart.");
         t2.height = t2.textHeight + 6;
         this.add(t2,textX,t1.y + t1.height);
         var h:Number = Math.max(param4 - 10,t2.y + t2.height + 8 - param3);
         k.fill(this.gfx,param2,param3,w,h,8,HsbKit.ORANGE_BG,1);
         k.outline(this.gfx,param2,param3,w,h,8,HsbKit.ORANGE,1);
         k.icon(this.gfx,"alert",param2 + 12,param3 + 10,18,HsbKit.ORANGE,1);
         var by:Number = param3 + h - btnH - 10;
         k.button(this,dismissX,by,"Dismiss","outline","banner.dismiss");
         k.button(this,neverX,by,"Don't show","orange","banner.never");
         return param3 + h + 10;
      }

      private function button(param1:Number, param2:Number, param3:String, param4:String, param5:Boolean, param6:* = null):Number
      {
         return this.kit.button(this,param1,param2,param3,param5 ? "accent" : "outline",param4,param6);
      }

      private function paintNoteLine(param1:Number, param2:Number, param3:Number, param4:String, param5:uint):Number
      {
         var t:TextField = this.kit.text(13,param5);
         this.kit.put(t,param4);
         this.kit.fit(t,param1 - param2 * 2);
         this.add(t,param2,param3);
         return param3 + t.height + 6;
      }

      // Height paintStripTop() uses, so the conflict notice can stand in for those rows.
      private function stripTopHeight():Number
      {
         var k:HsbKit = this.kit;
         return (this.upgrade ? 0 : k.u(24) + TAB_ROW_GAP + PAGER_GAP) + k.u(32) + TITLE_ROW_GAP;
      }

      // Mockup 1, top rows: LB, previous / current / next, RB; pager; title and find.
      private function paintStripTop(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var y:Number = param3;
         var d:Object = this.data != null ? this.data : {};
         var capH:Number = k.u(24);
         // Flight Check takes the category keys while it is open (they switch its tabs), so the
         // read-only list shows its categories without live keys or hits.
         var live:Boolean = !this.readOnly;
         var capInk:uint = live ? HsbKit.LABEL : HsbKit.DIM;
         if(!this.upgrade)
         {
            var lb:String = this.hsb.keyName("PrevCategory");
            var rb:String = this.hsb.keyName("NextCategory");
            k.keycap(this,param2,y,lb.length > 0 ? lb : "LB",capInk,capH);
            var rbw:Number = Math.max(capH,k.u(28));
            k.keycap(this,param1 - param2 - rbw,y,rb.length > 0 ? rb : "RB",capInk,capH);
            if(live)
            {
               this.hit(param2 - 4,y - 4,capH + 12,capH + 8,"tab",-1);
               this.hit(param1 - param2 - rbw - 4,y - 4,rbw + 8,capH + 8,"tab",1);
            }
            var names:Array = [this.cleanText(d.sPrevCategoryName),this.tabName,this.cleanText(d.sNextCategoryName)];
            var tx:Number = param2 + capH + 18;
            var t:int = 0;
            while(t < 3)
            {
               var tab:TextField = k.text(14,t == 1 ? k.accent : HsbKit.LABEL,t == 1,2);
               k.put(tab,String(names[t]).toUpperCase());
               k.fit(tab,(param1 - param2 * 2 - capH * 2 - 40) / 3);
               this.add(tab,tx,y + (capH - tab.height) / 2);
               // The underline spans the letters only: the field has a 2 px gutter and the last
               // letter carries its spacing.
               if(t == 1) { k.fill(g,tx + 2,y + capH + 1,Math.min(tab.width - 4,tab.textWidth - 2),2,0,k.accent,1); }
               if(live) { this.hit(tx - 4,y - 4,tab.width + 8,capH + 8,"tab",t - 1); }
               tx += tab.width + 18;
               t++;
            }
            y += capH + TAB_ROW_GAP;
            var segs:int = this.catTotal > 0 ? this.catTotal : 14;
            var segGap:Number = 6;
            var segW:Number = (param1 - param2 * 2 - (segs - 1) * segGap) / segs;
            var s:int = 0;
            while(s < segs)
            {
               var active:Boolean = s == Math.min(segs - 1,this.catIndex);
               k.fill(g,param2 + s * (segW + segGap),y,segW,3,1.5,active ? k.accent : 0x343B41,1);
               s++;
            }
            y += PAGER_GAP;
         }
         var title:TextField = k.text(20,HsbKit.TEXT,true,3);
         k.put(title,this.tabName.toUpperCase());
         k.fit(title,k.u(150));
         this.add(title,param2 + 2,y + (k.u(32) - title.height) / 2);
         if(!this.upgrade && live) { this.hit(param2,y,title.width + 6,k.u(32),"grid"); }
         var fx:Number = param2 + Math.max(k.u(70),title.width + 8);
         var collapseW:Number = k.u(30);
         var fw:Number = param1 - param2 - fx - collapseW - 6;
         this.findBox(fx,y,fw,k.u(32),this.tabName.length > 0 ? "Find " + this.tabName.toLowerCase() : "Find parts");
         var cb:Number = k.u(22);
         k.fill(g,param1 - param2 - cb,y + (k.u(32) - cb) / 2,cb,cb,5,0x1A2128,1);
         k.outline(g,param1 - param2 - cb,y + (k.u(32) - cb) / 2,cb,cb,5,HsbKit.EDGE_HI,1);
         k.icon(g,"dockR",param1 - param2 - cb + 3,y + (k.u(32) - cb) / 2 + 3,cb - 6,HsbKit.LABEL,1);
         this.hit(param1 - param2 - cb - 4,y,cb + 8,k.u(32),"collapse");
         return y + k.u(32) + TITLE_ROW_GAP;
      }

      // Mockup 1, below the title: pills; status; sort, columns, by maker, density; column
      // headers.
      private function paintStrip(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var y:Number = this.paintPills(param1,param2,param3);
         var showing:TextField = k.text(14,HsbKit.TEXT);
         k.put(showing,"Showing " + this.shownCount() + " of " + this.rows.length);
         k.fit(showing);
         this.add(showing,param2,y + 2);
         var on:Array = this.hsb.pills.onFor(this.tabId);
         if(on.length > 0 || this.findText.length > 0)
         {
            var clearW:Number = this.clearButton(param1 - param2,y);
            var what:TextField = k.text(13,k.accent);
            k.put(what,on.length == 1 ? String(on[0].name) + " is on" : (on.length > 1 ? on.length + " pills are on" : "Find is on"));
            k.fit(what,param1 - param2 * 2 - showing.width - clearW - 20);
            this.add(what,param1 - param2 - clearW - 10 - what.width,y + 3);
         }
         y += k.u(35);
         this.ctrlY = y;
         var rh:Number = k.u(28);
         // Laid out from the right edge first (density pair, BY MAKER switch, its label) so the
         // sort and columns boxes take only the room left and can never run into it.
         var dw:Number = k.u(58);
         var dx:Number = param1 - param2 - dw;
         k.outline(g,dx,y,dw,rh,6,HsbKit.EDGE_HI,1);
         var bs:Number = (dw - 6) / 2;
         var dens:Array = ["compact","detailed"];
         var dd:int = 0;
         while(dd < 2)
         {
            var on2:Boolean = this.hsb.density == String(dens[dd]);
            var bx:Number = dx + 2 + dd * (bs + 2);
            if(on2) { k.fill(g,bx,y + 2,bs,rh - 4,5,k.accent,1); }
            k.icon(g,dd == 0 ? "rows" : "compact",bx + (bs - 18) / 2,y + (rh - 18) / 2,18,on2 ? HsbKit.INK_ON_ACCENT : HsbKit.TEXT,1);
            this.hit(bx,y,bs,rh,"density",String(dens[dd]));
            dd++;
         }
         var tgx:Number = dx - 16 - k.u(38);
         k.toggle(g,tgx,y + (rh - k.u(18)) / 2,this.hsb.byMaker);
         var bm:TextField = k.text(13,HsbKit.LABEL,false,1);
         k.put(bm,"BY MAKER");
         k.fit(bm);
         var bmx:Number = tgx - 7 - bm.width;
         this.add(bm,bmx,y + (rh - bm.height) / 2);
         this.hit(bmx - 4,y,tgx + k.u(38) - bmx + 4,rh,"bymaker");
         // Mockup 8: the button stays lit while its chooser is open.
         var colsOpen:Boolean = this.colsPop != null && this.colsPop.parent != null;
         var colT:TextField = k.text(13,colsOpen ? k.accent : HsbKit.TEXT,true,1);
         k.put(colT,"COLUMNS");
         k.fit(colT);
         var colN:TextField = k.text(13,k.accent,true);
         k.put(colN,String(this.columns().length));
         k.fit(colN);
         var cw:Number = k.u(22) + colT.textWidth + 7 + colN.textWidth + 8;
         var sorted:Boolean = this.sortCol.length > 0;
         // Box chrome around the label: 11 in, the direction arrow when sorted, the chevron.
         var chrome:Number = sorted ? k.u(46) : k.u(37);
         var sortT:TextField = k.text(13,HsbKit.TEXT);
         k.put(sortT,sorted ? this.columnLabel(this.sortCol) : "Game order");
         k.fit(sortT);
         var sl:TextField = k.text(13,HsbKit.LABEL,false,1);
         k.put(sl,"SORT");
         k.fit(sl);
         var sx:Number = param2 + sl.textWidth + 7;
         var room:Number = bmx - 9 - cw - 10 - chrome + 6;
         // The SORT caption gives way before the chosen sort is cut short.
         if(sortT.width > room - sx) { sx = param2; }
         else { this.add(sl,param2,y + (rh - sl.height) / 2); }
         k.fit(sortT,Math.max(k.u(30),room - sx));
         var sw:Number = Math.min(sortT.width - 6,sortT.textWidth) + chrome;
         this.fieldBox(sx,y,sw,rh);
         this.add(sortT,sx + 9,y + (rh - sortT.height) / 2);
         if(sorted) { k.icon(g,this.sortDesc ? "sortDown" : "sortUp",sx + 11 + Math.min(sortT.width - 6,sortT.textWidth),y + (rh - 14) / 2,14,k.accent,1); }
         k.icon(g,"chevD",sx + sw - 21,y + (rh - 14) / 2,14,HsbKit.LABEL,1);
         this.hit(sx,y,sw,rh,"sort");
         var cx:Number = sx + sw + 10;
         this.fieldBox(cx,y,cw,rh);
         if(colsOpen) { k.outline(g,cx,y,cw,rh,6,k.accent,1); }
         k.icon(g,"columns",cx + 4,y + (rh - 18) / 2,18,colsOpen ? k.accent : HsbKit.TEXT,1);
         this.add(colT,cx + k.u(22) - 2,y + (rh - colT.height) / 2);
         this.add(colN,cx + k.u(22) + colT.textWidth + 7 - 2,y + (rh - colN.height) / 2);
         this.hit(cx,y,cw,rh,"columns");
         y += rh + 13;
         k.hline(g,LIST_PAD,y,param1 - LIST_PAD * 2,0x1D2328,1);
         y += 12;
         return this.paintHeader(param1,LIST_PAD,y);
      }

      private function fieldBox(param1:Number, param2:Number, param3:Number, param4:Number):void
      {
         this.kit.fill(this.gfx,param1,param2,param3,param4,6,HsbKit.FIELD,1);
         this.kit.outline(this.gfx,param1,param2,param3,param4,6,HsbKit.EDGE_HI,1);
      }

      private function findBox(param1:Number, param2:Number, param3:Number, param4:Number, param5:String):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         // startFind refuses while Flight Check reads the list, so the field is drawn inert then.
         var live:Boolean = !this.readOnly;
         k.fill(g,param1,param2,param3,param4,8,HsbKit.FIELD,1);
         k.outline(g,param1,param2,param3,param4,8,this.findOn ? k.accent : (live ? HsbKit.EDGE_HI : HsbKit.EDGE),1);
         k.icon(g,"search",param1 + 10,param2 + (param4 - 16) / 2,16,live ? HsbKit.LABEL : HsbKit.DIM,1);
         var t:TextField = k.text(14,this.findText.length > 0 ? HsbKit.TEXT : (live ? HsbKit.MUTED : HsbKit.DIM));
         k.put(t,this.findText.length > 0 ? this.findText + (this.findOn ? "|" : "") : (this.findOn ? "|" : param5));
         k.fit(t,param3 - 80);
         this.add(t,param1 + 34,param2 + (param4 - t.height) / 2);
         var key:String = this.hsb.keyFind.length > 0 && this.hsb.keyFind != "0" ? this.hsb.keyFind : "";
         if(key.length > 0 && live) { k.keycap(this,param1 + param3 - 10 - k.u(26),param2 + (param4 - k.u(22)) / 2,key,HsbKit.LABEL); }
         if(live) { this.hit(param1,param2,param3,param4,"find"); }
      }

      private function clearButton(param1:Number, param2:Number):Number
      {
         var k:HsbKit = this.kit;
         var t:TextField = k.text(12,HsbKit.TEXT,true,1.5);
         k.put(t,"CLEAR ALL");
         k.fit(t);
         var bh:Number = k.u(24);
         var bw:Number = 10 + 10 + 6 + t.width + 10;
         var x:Number = param1 - bw;
         k.outline(this.gfx,x,param2,bw,bh,bh / 2,HsbKit.EDGE_HI,1);
         k.icon(this.gfx,"x",x + 8,param2 + (bh - 12) / 2,12,HsbKit.TEXT,1);
         this.add(t,x + 24,param2 + (bh - t.height) / 2);
         this.hit(x,param2,bw,bh,"clear");
         return bw;
      }

      // Pills in the row: on pills solid, off pills dashed, then "+ N More" and "+ New pill".
      private function paintPills(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var ph:Number = k.u(28);
         var list:Array = this.hsb.pills.forTab(this.tabId);
         var row:Array = [];
         var more:int = 0;
         var i:int = 0;
         while(i < list.length)
         {
            if(list[i].inRow == true) { row.push(list[i]); }
            else { more++; }
            i++;
         }
         var x:Number = param2;
         var limit:Number = param1 - param2;
         var gap:Number = 7;
         var newW:Number = this.pillWidth("New pill",PILL_BUTTON);
         this.overflow = [];
         i = 0;
         while(i < row.length)
         {
            var p:Object = row[i];
            var on:Boolean = this.hsb.pills.isOn(String(p.id));
            var pw:Number = this.pillWidth(String(p.name),on ? PILL_ON : PILL_OFF);
            var moreW:Number = this.pillWidth((more + row.length - i) + " More",PILL_BUTTON);
            var last:Boolean = i == row.length - 1 && more == 0;
            if(x + pw + gap + (last ? 0 : moreW + gap) + newW > limit)
            {
               var r:int = i;
               while(r < row.length) { this.overflow.push(String(row[r].id)); r++; }
               more += row.length - i;
               break;
            }
            var ok:Boolean = HsbPillModel.usable(p);
            if(on) { k.fill(g,x,param3,pw,ph,ph / 2,k.accent,1); }
            else { k.dashed(g,x,param3,pw,ph,ph / 2,ok ? k.accent : HsbKit.DIM,1); }
            // Glyph boxes are wider than the glyphs: the check starts 2 px and the diamond
            // 2 px inside their boxes, so the boxes sit 2 px left of where the shapes show.
            var lx:Number = x + 10;
            if(on)
            {
               k.icon(g,"check",lx,param3 + (ph - 12) / 2,12,HsbKit.INK_ON_ACCENT,1);
               lx += 15;
            }
            k.icon(g,"diamond",lx,param3 + (ph - 10) / 2,10,on ? HsbKit.INK_ON_ACCENT : (ok ? k.accent : HsbKit.DIM),1);
            lx += 13;
            var t:TextField = k.text(13,on ? HsbKit.INK_ON_ACCENT : (ok ? HsbKit.TEXT : HsbKit.DIM));
            k.put(t,String(p.name));
            k.fit(t);
            this.add(t,lx,param3 + (ph - t.height) / 2);
            if(ok) { this.hit(x,param3,pw,ph,"pill",String(p.id)); }
            x += pw + gap;
            i++;
         }
         if(more > 0)
         {
            var mw:Number = this.pillWidth(more + " More",PILL_BUTTON);
            k.fill(g,x,param3,mw,ph,ph / 2,0x1A2128,1);
            k.outline(g,x,param3,mw,ph,ph / 2,HsbKit.EDGE_HI,1);
            k.icon(g,"plus",x + 8,param3 + (ph - 12) / 2,12,HsbKit.TEXT,1);
            var mt:TextField = k.text(13,HsbKit.TEXT);
            k.put(mt,more + " More");
            k.fit(mt);
            this.add(mt,x + 24,param3 + (ph - mt.height) / 2);
            this.hit(x,param3,mw,ph,"more");
            x += mw + gap;
         }
         else
         {
            this.hit(x,param3,0,0,"more");
         }
         k.dashed(g,x,param3,newW,ph,ph / 2,HsbKit.MUTED,1);
         k.icon(g,"plus",x + 8,param3 + (ph - 12) / 2,12,HsbKit.TEXT,1);
         var nt:TextField = k.text(13,HsbKit.TEXT);
         k.put(nt,"New pill");
         k.fit(nt);
         this.add(nt,x + 24,param3 + (ph - nt.height) / 2);
         this.hit(x,param3,newW,ph,"newpill");
         return param3 + ph + 10;
      }

      // Mockup 1 pill sizes around the name: on pills hold a check and a diamond, off pills a
      // diamond, the More and New pill buttons a plus.
      private function pillWidth(param1:String, param2:int):Number
      {
         var t:TextField = this.kit.text(13,0);
         this.kit.put(t,param1);
         if(param2 == PILL_ON) { return t.textWidth + 52; }
         if(param2 == PILL_OFF) { return t.textWidth + 36; }
         return t.textWidth + 37;
      }

      // Right edge of column param3 (-1: the end of the name area). Mockup 1 sets columns from
      // the right, leaving room for the sort arrow: Value holds credit ranges and is 110 wide,
      // the others 75. When they would leave the name under 40% of the row they shrink evenly.
      private function colX(param1:Number, param2:Number, param3:int, param4:int):Number
      {
         var cols:Array = this.columns();
         var k:HsbKit = this.kit;
         var right:Number = param1 - param2 - k.u(26);
         var sum:Number = 0;
         var i:int = 0;
         while(i < cols.length)
         {
            sum += k.u(String(cols[i]) == "value" ? 110 : 75);
            i++;
         }
         var room:Number = (param1 - param2 * 2) * 0.6 - k.u(26);
         var scale:Number = sum > room && sum > 0 ? room / sum : 1;
         var x:Number = right;
         i = cols.length - 1;
         while(i > param3 && i >= 0)
         {
            x -= k.u(String(cols[i]) == "value" ? 110 : 75) * scale;
            i--;
         }
         return x;
      }

      private function paintHeader(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var hh:Number = k.u(32);
         k.fill(g,param2,param3,param1 - param2 * 2,hh,6,HsbKit.HEAD,1);
         var byName:Boolean = this.sortCol == "name";
         var nt:TextField = k.text(13,byName ? k.accent : HsbKit.LABEL,byName);
         k.put(nt,"Name");
         k.fit(nt);
         this.add(nt,param2 + 14,param3 + (hh - nt.height) / 2);
         if(byName)
         {
            k.icon(g,this.sortDesc ? "sortDown" : "sortUp",nt.x + nt.width,param3 + (hh - 14) / 2,14,k.accent,1);
            k.fill(g,nt.x + 2,param3 + hh - 5,nt.textWidth,2,0,k.accent,1);
         }
         this.hit(param2,param3,nt.width + 30,hh,"head","name");
         var cols:Array = this.columns();
         var i:int = 0;
         while(i < cols.length)
         {
            var id:String = String(cols[i]);
            var right:Number = this.colX(param1,param2,i,cols.length);
            var left:Number = this.colX(param1,param2,i - 1,cols.length);
            var sorted:Boolean = this.sortCol == id;
            var t:TextField = k.text(13,sorted ? k.accent : HsbKit.LABEL,sorted,0,"right");
            k.put(t,this.columnLabel(id));
            // A label may reach left to the label before it (the first one to "Name"), as
            // "Crew stations" does in mockup 1; a right-aligned field ends its text 2 px in.
            var prevEnd:Number = i == 0 ? nt.x + nt.width + (byName ? 26 : 12) : left + (this.sortCol == String(cols[i - 1]) ? 18 : 10);
            k.fit(t,right - prevEnd + 6);
            this.add(t,right + 2 - t.width,param3 + (hh - t.height) / 2);
            if(sorted)
            {
               var tw:Number = Math.min(t.width - 6,t.textWidth);
               k.icon(g,this.sortDesc ? "sortDown" : "sortUp",right + 2,param3 + (hh - 14) / 2,14,k.accent,1);
               k.fill(g,right - tw,param3 + hh - 5,tw,2,0,k.accent,1);
            }
            this.hit(left,param3,right - left + (i == cols.length - 1 ? k.u(26) : 0),hh,"head",id);
            i++;
         }
         return param3 + hh + 8;
      }

      private function cellText(param1:*, param2:String):String
      {
         if(param1 == null) { return "\u2014"; }
         if(param1 is String) { return String(param1); }
         return HsbKit.num(param1,this.placesOf(param2)) + this.unitOf(param2);
      }

      private function unitOf(param1:String):String
      {
         return param1 != this.statId && this.statPct[param1] === true ? "%" : "";
      }

      // Decimal places for a column, as the part card shows them (statText): up to 2 for a part
      // stat, none for a percentage or for the game's whole numbers (value, mass, variants and
      // the tab's own stat).
      private function placesOf(param1:String):uint
      {
         if(param1 == this.statId || param1 == "value" || param1 == "mass" || param1 == "variants") { return 0; }
         return this.statPct[param1] === true ? 0 : 2;
      }

      private function rangeText(param1:Array, param2:String):String
      {
         var lo:Number = NaN;
         var hi:Number = NaN;
         var text:String = "";
         var i:int = 0;
         while(i < param1.length)
         {
            var v:* = this.cellValue(param1[i],param2);
            if(v != null)
            {
               if(v is String) { text = text.length == 0 ? String(v) : (text == String(v) ? text : "mixed"); }
               else
               {
                  var n:Number = Number(v);
                  if(isNaN(lo) || n < lo) { lo = n; }
                  if(isNaN(hi) || n > hi) { hi = n; }
               }
            }
            i++;
         }
         if(text.length > 0) { return text; }
         return isNaN(lo) ? HsbKit.range(lo,hi) : HsbKit.range(lo,hi,this.placesOf(param2)) + this.unitOf(param2);
      }

      private function paintList(param1:Number, param2:Number, param3:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var cols:Array = this.columns();
         var max:int = this.lastStart();
         if(this.scroll > max) { this.scroll = max; }
         var y:Number = param3;
         var bottom:Number = param3 + this.listH;
         var detailed:Boolean = this.hsb.density == "detailed";
         if(this.flat.length == 0)
         {
            var none:TextField = k.text(14,HsbKit.LABEL);
            k.put(none,this.rows.length == 0 ? "No parts in this tab" : "No parts match \u00B7 CLEAR ALL shows every part");
            k.fit(none,param1 - param2 * 2);
            this.add(none,param2 + 14,y + 12);
            return;
         }
         var x0:Number = param2;
         var wRow:Number = param1 - param2 * 2;
         var shown:int = 0;
         var i:int = this.scroll;
         while(i < this.flat.length)
         {
            var item:Object = this.flat[i];
            var rp:Number = this.rowPitch(item);
            if(shown > 0 && y + rp > bottom) { break; }
            var rowH:Number = rp - 3;
            var depth:int = int(item.depth);
            var indent:Number = depth * k.u(20);
            // Tree guides (mockup 1): one line per open level, running through its children.
            var lv:int = 0;
            while(lv < depth)
            {
               k.vline(g,x0 + 18 + lv * 24,y,rp,0x2A3238,1);
               lv++;
            }
            var cells:Array = this.paintCells(item,cols,param1,param2,y,rowH);
            // Names run up to the first column's text, not to its box, as long names do in
            // mockup 1 ("TAIYO ASTRONEERING" reaches into the Crew stations box).
            var nameEnd:Number = (cells.length > 0 ? this.colX(param1,param2,0,cols.length) - (cells[0] as TextField).textWidth : x0 + wRow) - 14;
            if(item.type == "group" || item.type == "sub")
            {
               var isGroup:Boolean = item.type == "group";
               if(isGroup) { k.fill(g,x0,y,wRow,rowH,6,item.open ? HsbKit.ROW_OPEN : HsbKit.ROW,1); }
               k.icon(g,item.open ? "chevD" : "chevR",x0 + 12 + indent,y + (rowH - 14) / 2,14,item.open && isGroup ? k.accent : HsbKit.TEXT,1);
               var chipText:String = isGroup ? String((item.rows as Array).length) : (item.rows as Array).length + " variants";
               var chipT:TextField = k.text(12,0,true);
               k.put(chipT,chipText);
               var chipW:Number = Math.max(k.u(20),chipT.textWidth + k.u(12));
               var gl:TextField = k.text(isGroup ? 13 : 14,HsbKit.TEXT,true,isGroup ? 2 : 0);
               k.put(gl,isGroup ? String(item.label).toUpperCase() : String(item.label));
               k.fit(gl,Math.max(k.u(40),nameEnd - (x0 + 32 + indent) - 6 - chipW));
               this.add(gl,x0 + 32 + indent,y + (rowH - gl.height) / 2);
               k.countChip(this,x0 + 32 + indent + gl.width + 4,y + (rowH - k.u(20)) / 2,chipText,isGroup && item.open);
               this.hit(x0,y,wRow,rowH,"group",item.key);
            }
            else
            {
               var row:Object = item.row;
               var sel:Boolean = String(row.id) == this.selId;
               // Part names under a size row line up past its chevron; under a maker they start
               // where the size rows' chevrons do.
               var nx:Number = x0 + 14 + indent + (depth >= 2 ? 6 : 0);
               if(sel)
               {
                  var hx:Number = depth > 0 ? nx - 11 : x0;
                  k.fill(g,hx,y,x0 + wRow - hx,rowH,6,HsbKit.SELECT,1);
                  k.fill(g,hx + 2,y + 8,3,rowH - 16,0,k.accent,1);
               }
               var color:uint = Boolean(row.disabled) ? HsbKit.DIM : HsbKit.TEXT;
               var nl:TextField = k.text(14,color,sel);
               k.put(nl,String(item.short));
               k.fit(nl,Math.max(k.u(40),nameEnd - nx));
               var ny:Number = detailed ? y + 4 : y + (rowH - nl.height) / 2;
               this.add(nl,nx,ny);
               if(detailed)
               {
                  var sub:TextField = k.text(12,HsbKit.MUTED);
                  var line:Array = [String(row.maker)];
                  if(String(row.size).length > 0) { line.push(String(row.size)); }
                  if(sel && this.variantLine().length > 0) { line.push(this.variantLine()); }
                  else if(int(row.variants) > 1) { line.push(int(row.variants) + " variants"); }
                  k.put(sub,line.join(" \u00B7 "));
                  k.fit(sub,Math.max(k.u(40),nameEnd - nx));
                  this.add(sub,nx,ny + nl.height - 2);
               }
               this.hit(x0,y,wRow,rowH,"leaf",String(row.id));
            }
            y += rp;
            shown++;
            i++;
         }
         this.scrollBar(param1,param2,param3,shown);
      }

      // The column cells of one tree row, right-aligned to the header labels: ranges on maker
      // and size rows, values on part rows (bold when selected or in the sorted column).
      private function paintCells(param1:Object, param2:Array, param3:Number, param4:Number, param5:Number, param6:Number):Array
      {
         var k:HsbKit = this.kit;
         var out:Array = [];
         var leaf:Boolean = param1.type == "leaf";
         var sel:Boolean = leaf && String(param1.row.id) == this.selId;
         var color:uint = leaf && Boolean(param1.row.disabled) ? HsbKit.DIM : HsbKit.TEXT;
         var c:int = 0;
         while(c < param2.length)
         {
            var id:String = String(param2[c]);
            var tf:TextField;
            if(leaf)
            {
               var v:* = this.cellValue(param1.row,id);
               tf = k.text(14,v == null ? HsbKit.DIM : color,sel || id == this.sortCol,0,"right");
               k.put(tf,this.cellText(v,id));
            }
            else
            {
               tf = k.text(13,0xB8BEC2,false,0,"right");
               k.put(tf,this.rangeText(param1.rows as Array,id));
            }
            tf.width = 120;
            this.add(tf,this.colX(param3,param4,c,param2.length) + 2 - tf.width,param5 + (param6 - tf.height) / 2);
            out.push(tf);
            c++;
         }
         return out;
      }

      private function scrollBar(param1:Number, param2:Number, param3:Number, param4:int):void
      {
         if(this.flat.length <= param4) { return; }
         var k:HsbKit = this.kit;
         var trackH:Number = this.listH;
         var x:Number = param1 - 8;
         k.fill(this.gfx,x,param3,3,trackH,1.5,0x1D2328,1);
         var thumb:Number = Math.max(24,trackH * param4 / this.flat.length);
         var at:Number = (trackH - thumb) * this.scroll / Math.max(1,this.flat.length - param4);
         k.fill(this.gfx,x,param3 + at,3,thumb,1.5,0x59626A,1);
      }

      // Mockup 4 (grid) and mockup 13 (read-only) use two-line rows: name, then maker and the
      // headline stat; value on the right.
      private function paintSimpleList(param1:Number, param2:Number, param3:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var y:Number = param3;
         var hn:TextField = k.text(12,HsbKit.MUTED,false,1.5);
         k.put(hn,"NAME");
         k.fit(hn);
         this.add(hn,param2 + 10,y);
         var hv:TextField = k.text(12,HsbKit.MUTED,false,1.5,"right");
         k.put(hv,"VALUE");
         hv.width = 100;
         this.add(hv,param1 - param2 - 110,y);
         y += hn.height + 8;
         this.listTop = y;
         this.listH = Math.max(40,this.listH - hn.height - 8);
         var per:int = this.perPage();
         var max:int = Math.max(0,this.shownRows.length - per);
         if(this.scroll > max) { this.scroll = max; }
         var rowH:Number = this.pitch - 4;
         var i:int = this.scroll;
         while(i < this.shownRows.length && i < this.scroll + per)
         {
            var row:Object = this.shownRows[i];
            var sel:Boolean = String(row.id) == this.selId;
            if(sel)
            {
               k.fill(g,param2,y,param1 - param2 * 2,rowH,6,HsbKit.SELECT,1);
               k.fill(g,param2,y + 8,3,rowH - 16,0,k.accent,1);
            }
            var nl:TextField = k.text(14,Boolean(row.disabled) ? HsbKit.DIM : HsbKit.TEXT,sel);
            k.put(nl,String(row.name));
            k.fit(nl,param1 - param2 * 2 - 140);
            this.add(nl,param2 + 14,y + 5);
            var sub:TextField = k.text(12,HsbKit.MUTED);
            var bits:Array = [String(row.maker)];
            if(!isNaN(Number(row.stat1)) && this.statName.length > 0) { bits.push(this.statName.toLowerCase() + " " + HsbKit.num(row.stat1)); }
            else if(int(row.variants) > 1) { bits.push(int(row.variants) + " variants"); }
            k.put(sub,bits.join(" \u00B7 "));
            k.fit(sub,param1 - param2 * 2 - 140);
            this.add(sub,param2 + 14,y + 5 + nl.height - 2);
            var vt:TextField = k.text(14,row.value == null ? HsbKit.DIM : HsbKit.TEXT,true,0,"right");
            k.put(vt,row.value == null ? "\u2014" : HsbKit.num(row.value));
            vt.width = 100;
            this.add(vt,param1 - param2 - 110,y + (rowH - vt.height) / 2);
            if(!this.readOnly) { this.hit(param2,y,param1 - param2 * 2,rowH,"leaf",String(row.id)); }
            y += this.pitch;
            i++;
         }
      }

      private function catKeys():Array
      {
         var out:Array = [];
         var key:String;
         for(key in this.cats) { out.push(int(key)); }
         out.sort(Array.NUMERIC);
         return out;
      }

      private function paintGridTop(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var y:Number = param3;
         var capH:Number = k.u(24);
         var lb:String = this.hsb.keyName("PrevCategory");
         var rb:String = this.hsb.keyName("NextCategory");
         k.keycap(this,param2,y,lb.length > 0 ? lb : "LB",HsbKit.LABEL,capH);
         var rbw:Number = Math.max(capH,k.u(28));
         k.keycap(this,param1 - param2 - rbw,y,rb.length > 0 ? rb : "RB",HsbKit.LABEL,capH);
         this.hit(param2 - 4,y - 4,capH + 12,capH + 8,"tab",-1);
         this.hit(param1 - param2 - rbw - 4,y - 4,rbw + 8,capH + 8,"tab",1);
         var title:TextField = k.text(14,k.accent,true,2);
         k.put(title,"CATEGORIES");
         k.fit(title);
         this.add(title,param2 + capH + 18,y + (capH - title.height) / 2);
         this.hit(param2 + capH + 14,y - 4,title.width + 8,capH + 8,"grid");
         var keys:Array = this.catKeys();
         var count:TextField = k.text(14,HsbKit.LABEL);
         k.put(count,this.discover != null ? "reading tabs\u2026 " + keys.length : String(this.catTotal > 0 ? this.catTotal : keys.length));
         k.fit(count);
         this.add(count,param2 + capH + 18 + title.width + 8,y + (capH - count.height) / 2);
         y += capH + 26;
         this.findBox(param2,y,param1 - param2 * 2,k.u(32),"Find parts");
         y += k.u(32) + 18;
         var x:Number = param2;
         // Mockup 4 chip: 30 high, icon, name, count; three to a row at the normal size.
         var chipH:Number = k.u(31);
         var i:int = 0;
         while(i < keys.length)
         {
            var cat:Object = this.cats[keys[i]];
            var name:String = String(cat.name).toUpperCase();
            var t:TextField = k.text(13,HsbKit.TEXT,true,1);
            k.put(t,name);
            k.fit(t);
            var n:TextField = k.text(12,HsbKit.LABEL,true);
            k.put(n,int(cat.count) >= 0 ? String(cat.count) : "\u00B7");
            k.fit(n);
            var nw:Number = Math.max(k.u(28),n.textWidth + 14);
            var cw:Number = 38 + t.textWidth + 10 + nw + 6;
            if(x + cw > param1 - param2) { x = param2; y += chipH + 11; }
            var active:Boolean = int(keys[i]) == this.catIndex;
            var empty:Boolean = int(cat.count) == 0;
            var focus:Boolean = i == this.gridFocus;
            if(active) { k.fill(g,x,y,cw,chipH,chipH / 2,k.accent,1); }
            else { k.fill(g,x,y,cw,chipH,chipH / 2,0x161C22,empty ? 0.6 : 1); k.outline(g,x,y,cw,chipH,chipH / 2,focus ? HsbKit.TEXT : HsbKit.EDGE_HI,1,focus ? 2 : 1); }
            var ink:uint = active ? HsbKit.INK_ON_ACCENT : (empty ? HsbKit.DIM : HsbKit.TEXT);
            k.icon(g,this.catIcon(String(cat.name)),x + 10,y + (chipH - 18) / 2,18,ink,1);
            k.put(t,name,ink);
            this.add(t,x + 36,y + (chipH - t.height) / 2);
            var nx:Number = x + 38 + t.textWidth + 10;
            // On the accent chip the count sits on a dark chip in light ink, as in mockup 4.
            k.fill(g,nx,y + (chipH - k.u(18)) / 2,nw,k.u(18),5,active ? HsbKit.INK_ON_ACCENT : 0x262D33,active ? 0.85 : 1);
            k.put(n,n.text,active ? HsbKit.TEXT : HsbKit.LABEL);
            this.add(n,nx + (nw - n.width) / 2,y + (chipH - n.height) / 2);
            if(!empty) { this.hit(x,y,cw,chipH,"cat",int(keys[i])); }
            x += cw + 8;
            i++;
         }
         y += chipH + 19;
         k.hline(g,param2,y,param1 - param2 * 2);
         y += 10;
         var ml:TextField = k.text(13,HsbKit.LABEL,false,1.5);
         k.put(ml,"MAKER");
         k.fit(ml);
         this.add(ml,param2,y + (k.u(28) - ml.height) / 2);
         var mx:Number = param2 + ml.width + 12;
         var makers:Array = ["All"].concat(this.makerNames());
         var right:Number = param1 - param2;
         var moreW:Number = k.u(48);
         this.makerRest = [];
         var m:int = 0;
         while(m < makers.length)
         {
            var mname:String = String(makers[m]);
            var cnt:int = mname == "All" ? this.rows.length : this.countMaker(mname);
            var mt:TextField = k.text(13,HsbKit.TEXT);
            k.put(mt,mname);
            k.fit(mt);
            var mn:TextField = k.text(12,HsbKit.LABEL,true);
            k.put(mn,String(cnt));
            k.fit(mn);
            var mw:Number = 12 + mt.width + 6 + Math.max(k.u(22),mn.width + 10) + 8;
            // Makers that do not fit go behind a "+N" chip, which lists them in a menu.
            var last:Boolean = m == makers.length - 1;
            if(m > 0 && mx + mw + (last ? 0 : 8 + moreW) > right)
            {
               this.makerRest = makers.slice(m);
               break;
            }
            var picked:Boolean = (this.makerChip == "" && mname == "All") || this.makerChip == mname;
            k.fill(g,mx,y,mw,k.u(28),k.u(14),0x161C22,1);
            k.outline(g,mx,y,mw,k.u(28),k.u(14),picked ? k.accent : HsbKit.EDGE_HI,1);
            this.add(mt,mx + 12,y + (k.u(28) - mt.height) / 2);
            k.countChip(this,mx + 12 + mt.width + 6,y + (k.u(28) - k.u(20)) / 2,String(cnt),picked);
            this.hit(mx,y,mw,k.u(28),"maker",mname == "All" ? "" : mname);
            mx += mw + 8;
            m++;
         }
         if(this.makerRest.length > 0)
         {
            var hidden:Boolean = this.makerRest.indexOf(this.makerChip) >= 0;
            var rt:TextField = k.text(13,HsbKit.TEXT,true);
            k.put(rt,"+" + this.makerRest.length);
            k.fit(rt);
            var rw:Number = Math.max(moreW,rt.width + 20);
            k.fill(g,mx,y,rw,k.u(28),k.u(14),0x161C22,1);
            k.outline(g,mx,y,rw,k.u(28),k.u(14),hidden ? k.accent : HsbKit.EDGE_HI,1);
            this.add(rt,mx + (rw - rt.width) / 2,y + (k.u(28) - rt.height) / 2);
            this.hit(mx,y,rw,k.u(28),"makermore");
         }
         y += k.u(28) + 10;
         var av:TextField = k.text(14,HsbKit.TEXT,true);
         k.put(av,this.tabName.toUpperCase() + " \u00B7 " + this.availableCount() + " available");
         k.fit(av);
         this.add(av,param2,y);
         // Mockup 4 also counts parts "hidden by level or location" with a Settings hint. The game
         // sends only the parts it offers here, so the hidden count has no data; parts it sends
         // flagged as unavailable stay in the list, dimmed, and are counted as locked instead.
         var locked:int = this.rows.length - this.availableCount();
         if(locked > 0)
         {
            var lk:TextField = k.text(13,k.accent);
            k.put(lk,locked + " locked \u00B7 dimmed in the list");
            k.fit(lk,param1 - param2 * 2 - av.width - 12);
            this.add(lk,param2 + av.width + 10,y + (av.height - lk.height) / 2);
         }
         y += av.height + 12;
         return y;
      }

      private function countMaker(param1:String):int
      {
         var n:int = 0;
         var i:int = 0;
         while(i < this.rows.length)
         {
            if(String(this.rows[i].maker) == param1) { n++; }
            i++;
         }
         return n;
      }

      private function availableCount():int
      {
         var n:int = 0;
         var i:int = 0;
         while(i < this.rows.length)
         {
            if(!Boolean(this.rows[i].disabled)) { n++; }
            i++;
         }
         return n;
      }

      internal function frameOf():int
      {
         return this.lastPaint;
      }

      internal function asContainer():DisplayObjectContainer
      {
         return this;
      }
   }
}
