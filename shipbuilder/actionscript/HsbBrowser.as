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
      private var pending:int = 0;
      private var gridFocus:int = -1;
      private var lastPaint:int = -1;
      private var columnPreview:Array = null;

      public function HsbBrowser(param1:HsbKit, param2:HorizonShipBuilder)
      {
         super(param1,"HsbBrowser");
         this.hsb = param2;
         this.rows = [];
         this.cats = {};
         this.seen = {};
         this.statLabels = {};
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
         if(!Boolean(param1.bShowWidget)) { this.invalidate(); return; }
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
      internal function learn(param1:Object):void
      {
         var id:String = this.previewId.length > 0 ? this.previewId : this.nativeSel;
         if(id.length == 0) { return; }
         var row:Object = this.seen[id];
         if(row == null) { row = {"stats":{}}; this.seen[id] = row; }
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
                  row.stats[sid] = Number(s.fValue);
                  if(this.statLabels[sid] == null) { this.statLabels[sid] = this.cleanText(raw); }
               }
            }
            i++;
         }
         var r:Object = this.rowById(id);
         if(r != null) { this.fill(r); }
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
         return param1 == "*" ? "All tabs" : param1;
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
         var map:Object = {"value":"Value","mass":"Mass","variants":"Variants","maker":"Maker","size":"Size","class":"Class"};
         if(map[param1] != null) { return String(map[param1]); }
         if(this.statLabels[param1] != null)
         {
            var s:String = String(this.statLabels[param1]);
            return s.charAt(0).toUpperCase() + s.substring(1).toLowerCase();
         }
         return param1;
      }

      internal function cellValue(param1:Object, param2:String):*
      {
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
         var per:int = this.perPage();
         if(at < this.scroll) { this.scroll = at; }
         else if(at >= this.scroll + per) { this.scroll = at - per + 1; }
      }

      private function perPage():int
      {
         return Math.max(1,int(this.listH / this.pitch));
      }

      // ---- categories ----------------------------------------------------------------------

      private function changeCategory(param1:int):void
      {
         if(param1 == 0 || this.upgrade) { return; }
         this.hsb.send("ShipEditor_ChangeModuleCategory",{"iCategoryOffset":param1});
      }

      // Jumps to a category. If the game moves only one step per event, the remaining steps are
      // sent as each new category arrives.
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
         this.changeCategory(offset);
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
            this.pick(int(keys[this.gridFocus]));
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
         var max:int = Math.max(0,this.flat.length - this.perPage());
         this.scroll = HorizonShipBuilder.clampInt(this.scroll - int(param1) * 3,0,max);
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
         if(this.sortCol == param1) { this.sortDesc = !this.sortDesc; }
         else
         {
            this.sortCol = param1;
            this.sortDesc = param1 == "value" || param1 == "mass" || param1 == this.statId;
         }
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
            if(String(param2) == "") { self.sortCol = ""; self.sortDesc = false; self.afterFilter(); }
            else if(String(param2) == "name") { self.sortCol = "name"; self.sortDesc = false; self.afterFilter(); }
            else { self.sortBy(String(param2)); }
         });
         this.popBelow(menu,"sort");
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
         this.hsb.openPop(pop);
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
            param1.anchorX = this.x + Number(at.x) * this.scaleX;
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
         if(this.hsb.bannerWanted()) { y = this.paintBanner(w,pad,y); }
         if(this.grid) { y = this.paintGridTop(w,pad,y); }
         else { y = this.paintStrip(w,pad,y); }
         if(this.readOnly) { y = this.paintNoteLine(w,pad,y,"Flight Check is open \u00B7 the list is read-only"); }
         this.pitch = this.hsb.density == "detailed" || this.grid || this.readOnly ? k.u(50) : k.u(37);
         var footH:Number = k.u(30);
         this.listTop = y;
         this.listH = h - y - footH - 8;
         if(this.grid || this.readOnly) { this.paintSimpleList(w,pad,y); }
         else { this.paintList(w,pad,y); }
         var foot:TextField = k.text(13,HsbKit.MUTED);
         var footText:String = "Group rows show ranges \u00B7 open one for single values";
         if(this.unchecked > 0) { footText = this.unchecked + " parts not checked yet \u00B7 preview a part to check it"; }
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

      internal function fitHeight():Number
      {
         var r:Object = this.hsb.viewRect();
         var room:Number = r.height - (this.hsb.margin + 3) - 190;
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

      // Mockup 11.
      private function paintBanner(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var w:Number = param1 - param2 * 2;
         var h:Number = k.u(96);
         k.fill(this.gfx,param2,param3,w,h,8,HsbKit.ORANGE_BG,1);
         k.outline(this.gfx,param2,param3,w,h,8,HsbKit.ORANGE,1);
         k.icon(this.gfx,"warn",param2 + 12,param3 + 12,18,HsbKit.ORANGE,1);
         var tag:TextField = k.text(12,HsbKit.ORANGE,true,1.5);
         k.put(tag,"WARNING");
         k.fit(tag);
         this.add(tag,param2 + 38,param3 + 12);
         var t1:TextField = k.text(14,HsbKit.TEXT,true);
         k.put(t1,"StarUI Ship Builder files found");
         k.fit(t1,w - 50);
         this.add(t1,param2 + 38,param3 + 30);
         var t2:TextField = k.text(13,HsbKit.LABEL);
         k.put(t2,"Horizon is active. If the builder looks wrong, disable one mod and restart.");
         k.fit(t2,w - 50);
         this.add(t2,param2 + 38,param3 + 50);
         var bx:Number = param2 + 38;
         bx += this.button(bx,param3 + h - k.u(28) - 8,"Dismiss","banner.dismiss",false) + 8;
         this.button(bx,param3 + h - k.u(28) - 8,"Don't show","banner.never",false);
         return param3 + h + 10;
      }

      private function button(param1:Number, param2:Number, param3:String, param4:String, param5:Boolean, param6:* = null):Number
      {
         return this.kit.button(this,param1,param2,param3,param5 ? "accent" : "outline",param4,param6);
      }

      private function paintNoteLine(param1:Number, param2:Number, param3:Number, param4:String):Number
      {
         var t:TextField = this.kit.text(13,HsbKit.ORANGE);
         this.kit.put(t,param4);
         this.kit.fit(t,param1 - param2 * 2);
         this.add(t,param2,param3);
         return param3 + t.height + 6;
      }

      // Mockup 1: LB, previous / current / next, RB; pager; title and find; pills; status;
      // sort, columns, by maker, density; column headers.
      private function paintStrip(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var y:Number = param3;
         var d:Object = this.data != null ? this.data : {};
         var capH:Number = k.u(24);
         if(!this.upgrade)
         {
            var lb:String = this.hsb.keyName("PrevCategory");
            var rb:String = this.hsb.keyName("NextCategory");
            k.keycap(this,param2,y,lb.length > 0 ? lb : "LB",HsbKit.LABEL,capH);
            var rbw:Number = Math.max(capH,k.u(28));
            k.keycap(this,param1 - param2 - rbw,y,rb.length > 0 ? rb : "RB",HsbKit.LABEL,capH);
            this.hit(param2 - 4,y - 4,capH + 12,capH + 8,"tab",-1);
            this.hit(param1 - param2 - rbw - 4,y - 4,rbw + 8,capH + 8,"tab",1);
            var names:Array = [this.cleanText(d.sPrevCategoryName),this.tabName,this.cleanText(d.sNextCategoryName)];
            var tx:Number = param2 + capH + 18;
            var t:int = 0;
            while(t < 3)
            {
               var tab:TextField = k.text(14,t == 1 ? k.accent : HsbKit.LABEL,t == 1,2);
               k.put(tab,String(names[t]).toUpperCase());
               k.fit(tab,(param1 - param2 * 2 - capH * 2 - 40) / 3);
               this.add(tab,tx,y + (capH - tab.height) / 2);
               if(t == 1) { k.fill(g,tx,y + capH + 4,tab.width - 4,2,0,k.accent,1); }
               this.hit(tx - 4,y - 4,tab.width + 8,capH + 8,"tab",t - 1);
               tx += tab.width + 18;
               t++;
            }
            y += capH + 14;
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
            y += 16;
         }
         var title:TextField = k.text(20,HsbKit.TEXT,true,3);
         k.put(title,this.tabName.toUpperCase());
         k.fit(title,k.u(150));
         this.add(title,param2 + 2,y + (k.u(32) - title.height) / 2);
         if(!this.upgrade) { this.hit(param2,y,title.width + 6,k.u(32),"grid"); }
         var fx:Number = param2 + Math.max(k.u(92),title.width + 16);
         var collapseW:Number = k.u(30);
         var fw:Number = param1 - param2 - fx - collapseW - 6;
         this.findBox(fx,y,fw,k.u(32),this.tabName.length > 0 ? "Find " + this.tabName.toLowerCase() : "Find parts");
         var cb:Number = k.u(22);
         k.fill(g,param1 - param2 - cb,y + (k.u(32) - cb) / 2,cb,cb,5,0x1A2128,1);
         k.outline(g,param1 - param2 - cb,y + (k.u(32) - cb) / 2,cb,cb,5,HsbKit.EDGE_HI,1);
         k.icon(g,"dockR",param1 - param2 - cb + 3,y + (k.u(32) - cb) / 2 + 3,cb - 6,HsbKit.LABEL,1);
         this.hit(param1 - param2 - cb - 4,y,cb + 8,k.u(32),"collapse");
         y += k.u(32) + 12;
         y = this.paintPills(param1,param2,y);
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
         y += k.u(30);
         this.ctrlY = y;
         var sl:TextField = k.text(13,HsbKit.LABEL,false,1.5);
         k.put(sl,"SORT");
         k.fit(sl);
         this.add(sl,param2,y + (k.u(28) - sl.height) / 2);
         var sx:Number = param2 + sl.width + 8;
         var sortT:TextField = k.text(13,HsbKit.TEXT);
         k.put(sortT,this.sortCol.length > 0 ? this.columnLabel(this.sortCol) : "Game order");
         k.fit(sortT);
         var sw:Number = sortT.width + k.u(42);
         this.fieldBox(sx,y,sw,k.u(28));
         this.add(sortT,sx + 10,y + (k.u(28) - sortT.height) / 2);
         if(this.sortCol.length > 0) { k.icon(g,this.sortDesc ? "sortDown" : "sortUp",sx + 10 + sortT.width + 2,y + (k.u(28) - 10) / 2,10,k.accent,1); }
         k.icon(g,"chevD",sx + sw - 18,y + (k.u(28) - 12) / 2,12,HsbKit.LABEL,1);
         this.hit(sx,y,sw,k.u(28),"sort");
         var cx:Number = sx + sw + 12;
         var colT:TextField = k.text(13,HsbKit.TEXT,true,1.5);
         k.put(colT,"COLUMNS");
         k.fit(colT);
         var colN:TextField = k.text(13,k.accent,true);
         k.put(colN,String(this.columns().length));
         k.fit(colN);
         var cw:Number = 12 + 14 + 6 + colT.width + 6 + colN.width + 10;
         this.fieldBox(cx,y,cw,k.u(28));
         k.icon(g,"columns",cx + 10,y + (k.u(28) - 14) / 2,14,HsbKit.TEXT,1);
         this.add(colT,cx + 30,y + (k.u(28) - colT.height) / 2);
         this.add(colN,cx + 30 + colT.width + 6,y + (k.u(28) - colN.height) / 2);
         this.hit(cx,y,cw,k.u(28),"columns");
         var dx:Number = param1 - param2 - k.u(56);
         var bm:TextField = k.text(13,HsbKit.LABEL,false,1.5);
         k.put(bm,"BY MAKER");
         k.fit(bm);
         var tgx:Number = dx - 10 - k.u(38);
         this.add(bm,tgx - 8 - bm.width,y + (k.u(28) - bm.height) / 2);
         k.toggle(g,tgx,y + (k.u(28) - k.u(18)) / 2,this.hsb.byMaker);
         this.hit(tgx - 8 - bm.width,y,bm.width + 16 + k.u(38),k.u(28),"bymaker");
         var dens:Array = [["compact","rows"],["detailed","compact"]];
         var dd:int = 0;
         while(dd < 2)
         {
            var on2:Boolean = this.hsb.density == String(dens[dd][0]);
            var bx:Number = dx + dd * k.u(28);
            var bs:Number = k.u(26);
            if(on2) { k.fill(g,bx,y + 1,bs,bs,5,k.accent,1); }
            else { k.outline(g,bx,y + 1,bs,bs,5,HsbKit.EDGE_HI,1); }
            k.icon(g,dd == 0 ? "rows" : "compact",bx + 4,y + 5,bs - 8,on2 ? HsbKit.INK_ON_ACCENT : HsbKit.TEXT,1);
            this.hit(bx,y,bs,k.u(28),"density",String(dens[dd][0]));
            dd++;
         }
         y += k.u(28) + 10;
         k.hline(g,param2,y,param1 - param2 * 2,0x1D2328,1);
         y += 10;
         return this.paintHeader(param1,param2,y);
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
         k.fill(g,param1,param2,param3,param4,8,HsbKit.FIELD,1);
         k.outline(g,param1,param2,param3,param4,8,this.findOn ? k.accent : HsbKit.EDGE_HI,1);
         k.icon(g,"search",param1 + 10,param2 + (param4 - 16) / 2,16,HsbKit.LABEL,1);
         var t:TextField = k.text(14,this.findText.length > 0 ? HsbKit.TEXT : HsbKit.MUTED);
         k.put(t,this.findText.length > 0 ? this.findText + (this.findOn ? "|" : "") : (this.findOn ? "|" : param5));
         k.fit(t,param3 - 80);
         this.add(t,param1 + 34,param2 + (param4 - t.height) / 2);
         var key:String = this.hsb.keyFind.length > 0 && this.hsb.keyFind != "0" ? this.hsb.keyFind : "";
         if(key.length > 0) { k.keycap(this,param1 + param3 - 10 - k.u(26),param2 + (param4 - k.u(22)) / 2,key,HsbKit.LABEL); }
         this.hit(param1,param2,param3,param4,"find");
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
         var newW:Number = this.pillWidth("+ New pill");
         this.overflow = [];
         i = 0;
         while(i < row.length)
         {
            var p:Object = row[i];
            var on:Boolean = this.hsb.pills.isOn(String(p.id));
            var label:String = (on ? "\u2713 " : "") + String(p.name);
            var pw:Number = this.pillWidth(label) + 16;
            var moreW:Number = this.pillWidth("+ " + (more + row.length - i) + " More");
            if(x + pw + 8 + moreW + 8 + newW > limit)
            {
               var r:int = i;
               while(r < row.length) { this.overflow.push(String(row[r].id)); r++; }
               more += row.length - i;
               break;
            }
            var ok:Boolean = HsbPillModel.usable(p);
            if(on) { k.fill(g,x,param3,pw,ph,ph / 2,k.accent,1); }
            else { k.dashed(g,x,param3,pw,ph,ph / 2,ok ? k.accent : HsbKit.DIM,1); }
            var lx:Number = x + 12;
            if(on)
            {
               k.icon(g,"check",lx,param3 + (ph - 12) / 2,12,HsbKit.INK_ON_ACCENT,1);
               lx += 16;
            }
            k.icon(g,"diamond",lx,param3 + (ph - 10) / 2,10,on ? HsbKit.INK_ON_ACCENT : (ok ? k.accent : HsbKit.DIM),1);
            lx += 14;
            var t:TextField = k.text(13,on ? HsbKit.INK_ON_ACCENT : (ok ? HsbKit.TEXT : HsbKit.DIM),true);
            k.put(t,String(p.name));
            k.fit(t);
            this.add(t,lx,param3 + (ph - t.height) / 2);
            if(ok) { this.hit(x,param3,pw,ph,"pill",String(p.id)); }
            x += pw + 8;
            i++;
         }
         if(more > 0)
         {
            var mw:Number = this.pillWidth("+ " + more + " More");
            k.fill(g,x,param3,mw,ph,ph / 2,0x1A2128,1);
            k.outline(g,x,param3,mw,ph,ph / 2,HsbKit.EDGE_HI,1);
            k.icon(g,"plus",x + 8,param3 + (ph - 12) / 2,12,HsbKit.TEXT,1);
            var mt:TextField = k.text(13,HsbKit.TEXT,true);
            k.put(mt,more + " More");
            k.fit(mt);
            this.add(mt,x + 24,param3 + (ph - mt.height) / 2);
            this.hit(x,param3,mw,ph,"more");
            x += mw + 8;
         }
         else
         {
            this.hit(x,param3,0,0,"more");
         }
         k.dashed(g,x,param3,newW,ph,ph / 2,HsbKit.LABEL,1);
         k.icon(g,"plus",x + 8,param3 + (ph - 12) / 2,12,HsbKit.TEXT,1);
         var nt:TextField = k.text(13,HsbKit.TEXT,true);
         k.put(nt,"New pill");
         k.fit(nt);
         this.add(nt,x + 24,param3 + (ph - nt.height) / 2);
         this.hit(x,param3,newW,ph,"newpill");
         return param3 + ph + 10;
      }

      private function pillWidth(param1:String):Number
      {
         var t:TextField = this.kit.text(13,0,true);
         this.kit.put(t,param1);
         return t.textWidth + 40;
      }

      private function colX(param1:Number, param2:Number, param3:int, param4:int):Number
      {
         var nameW:Number = (param1 - param2 * 2) * (param4 >= 4 ? 0.34 : 0.42);
         var rest:Number = param1 - param2 * 2 - nameW - 10;
         return param2 + nameW + rest * (param3 + 1) / param4;
      }

      private function paintHeader(param1:Number, param2:Number, param3:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var hh:Number = k.u(32);
         k.fill(g,param2,param3,param1 - param2 * 2,hh,6,HsbKit.HEAD,1);
         var nt:TextField = k.text(13,HsbKit.LABEL);
         k.put(nt,"Name");
         k.fit(nt);
         this.add(nt,param2 + 14,param3 + (hh - nt.height) / 2);
         this.hit(param2,param3,nt.width + 30,hh,"head","name");
         var cols:Array = this.columns();
         var i:int = 0;
         while(i < cols.length)
         {
            var id:String = String(cols[i]);
            var right:Number = this.colX(param1,param2,i,cols.length);
            var sorted:Boolean = this.sortCol == id;
            var t:TextField = k.text(13,sorted ? k.accent : HsbKit.LABEL,sorted,0,"right");
            k.put(t,this.columnLabel(id));
            t.width = 110;
            var shift:Number = sorted ? 14 : 0;
            this.add(t,right - 110 - shift,param3 + (hh - t.height) / 2);
            if(sorted)
            {
               k.icon(g,this.sortDesc ? "sortDown" : "sortUp",right - 12,param3 + (hh - 10) / 2,10,k.accent,1);
               k.fill(g,right - shift - Math.min(110,t.textWidth) - 2,param3 + hh - 6,Math.min(110,t.textWidth) + shift + 2,2,0,k.accent,1);
            }
            this.hit(right - 90,param3,90,hh,"head",id);
            i++;
         }
         return param3 + hh + 6;
      }

      private function cellText(param1:*, param2:String):String
      {
         if(param1 == null) { return "\u2014"; }
         if(param1 is String) { return String(param1); }
         return HsbKit.num(param1);
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
         return HsbKit.range(lo,hi);
      }

      private function paintList(param1:Number, param2:Number, param3:Number):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var cols:Array = this.columns();
         var per:int = this.perPage();
         var max:int = Math.max(0,this.flat.length - per);
         if(this.scroll > max) { this.scroll = max; }
         var y:Number = param3;
         var rowH:Number = this.pitch - 4;
         var detailed:Boolean = this.hsb.density == "detailed";
         if(this.flat.length == 0)
         {
            var none:TextField = k.text(14,HsbKit.LABEL);
            k.put(none,this.rows.length == 0 ? "No parts in this tab" : "No parts match \u00B7 CLEAR ALL shows every part");
            k.fit(none,param1 - param2 * 2);
            this.add(none,param2 + 14,y + 12);
            return;
         }
         var i:int = this.scroll;
         while(i < this.flat.length && i < this.scroll + per)
         {
            var item:Object = this.flat[i];
            var indent:Number = int(item.depth) * k.u(20);
            var x0:Number = param2;
            var wRow:Number = param1 - param2 * 2;
            if(item.type == "group" || item.type == "sub")
            {
               var isGroup:Boolean = item.type == "group";
               if(isGroup) { k.fill(g,x0,y,wRow,rowH,6,item.open ? HsbKit.ROW_OPEN : HsbKit.ROW,1); }
               k.icon(g,item.open ? "chevD" : "chevR",x0 + 12 + indent,y + (rowH - 14) / 2,14,item.open && isGroup ? k.accent : HsbKit.TEXT,1);
               var gl:TextField = k.text(isGroup ? 13 : 14,item.open && isGroup ? k.accent : HsbKit.TEXT,true,isGroup ? 2 : 0);
               k.put(gl,isGroup ? String(item.label).toUpperCase() : String(item.label));
               k.fit(gl,this.colX(param1,param2,-1,cols.length) - x0 - 70 - indent);
               this.add(gl,x0 + 32 + indent,y + (rowH - gl.height) / 2);
               var chipText:String = isGroup ? String((item.rows as Array).length) : (item.rows as Array).length + " variants";
               k.countChip(this,x0 + 32 + indent + gl.width + 6,y + (rowH - k.u(20)) / 2,chipText,isGroup && item.open);
               var c:int = 0;
               while(c < cols.length)
               {
                  var rt:TextField = k.text(13,0xB8BEC2,false,0,"right");
                  k.put(rt,this.rangeText(item.rows as Array,String(cols[c])));
                  rt.width = 120;
                  this.add(rt,this.colX(param1,param2,c,cols.length) - 120,y + (rowH - rt.height) / 2);
                  c++;
               }
               this.hit(x0,y,wRow,rowH,"group",item.key);
            }
            else
            {
               var row:Object = item.row;
               var sel:Boolean = String(row.id) == this.selId;
               if(sel)
               {
                  k.fill(g,x0,y,wRow,rowH,6,HsbKit.SELECT,1);
                  k.fill(g,x0 + 12 + indent,y + 8,3,rowH - 16,0,k.accent,1);
               }
               var color:uint = Boolean(row.disabled) ? HsbKit.DIM : HsbKit.TEXT;
               var nl:TextField = k.text(14,color,sel);
               k.put(nl,String(item.short));
               k.fit(nl,this.colX(param1,param2,-1,cols.length) - x0 - 40 - indent);
               var ny:Number = detailed ? y + 4 : y + (rowH - nl.height) / 2;
               this.add(nl,x0 + 24 + indent,ny);
               if(int(row.variants) > 1)
               {
                  k.countChip(this,x0 + 24 + indent + nl.width + 6,ny + (nl.height - k.u(20)) / 2,"\u25C6 " + int(row.variants),false);
               }
               if(detailed)
               {
                  var sub:TextField = k.text(12,HsbKit.MUTED);
                  var line:Array = [String(row.maker)];
                  if(String(row.size).length > 0) { line.push(String(row.size)); }
                  if(sel && this.variantLine().length > 0) { line.push(this.variantLine()); }
                  k.put(sub,line.join(" \u00B7 "));
                  k.fit(sub,this.colX(param1,param2,-1,cols.length) - x0 - 40 - indent);
                  this.add(sub,x0 + 24 + indent,ny + nl.height - 2);
               }
               var cc:int = 0;
               while(cc < cols.length)
               {
                  var v:* = this.cellValue(row,String(cols[cc]));
                  var vt:TextField = k.text(14,v == null ? HsbKit.DIM : color,sel || String(cols[cc]) == this.sortCol,0,"right");
                  k.put(vt,this.cellText(v,String(cols[cc])));
                  vt.width = 110;
                  this.add(vt,this.colX(param1,param2,cc,cols.length) - 110,y + (rowH - vt.height) / 2);
                  cc++;
               }
               this.hit(x0,y,wRow,rowH,"leaf",String(row.id));
            }
            y += this.pitch;
            i++;
         }
         this.scrollBar(param1,param2,param3,per);
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
         y += capH + 16;
         this.findBox(param2,y,param1 - param2 * 2,k.u(32),"Find parts");
         y += k.u(32) + 14;
         var x:Number = param2;
         var chipH:Number = k.u(34);
         var i:int = 0;
         while(i < keys.length)
         {
            var cat:Object = this.cats[keys[i]];
            var name:String = String(cat.name).toUpperCase();
            var t:TextField = k.text(13,HsbKit.TEXT,true,1.5);
            k.put(t,name);
            k.fit(t);
            var n:TextField = k.text(12,HsbKit.LABEL,true);
            k.put(n,int(cat.count) >= 0 ? String(cat.count) : "\u00B7");
            k.fit(n);
            var cw:Number = 12 + 20 + 8 + t.width + 8 + Math.max(k.u(24),n.width + 12) + 10;
            if(x + cw > param1 - param2) { x = param2; y += chipH + 8; }
            var active:Boolean = int(keys[i]) == this.catIndex;
            var empty:Boolean = int(cat.count) == 0;
            var focus:Boolean = i == this.gridFocus;
            if(active) { k.fill(g,x,y,cw,chipH,chipH / 2,k.accent,1); }
            else { k.fill(g,x,y,cw,chipH,chipH / 2,0x161C22,empty ? 0.6 : 1); k.outline(g,x,y,cw,chipH,chipH / 2,focus ? HsbKit.TEXT : HsbKit.EDGE_HI,1,focus ? 2 : 1); }
            var ink:uint = active ? HsbKit.INK_ON_ACCENT : (empty ? HsbKit.DIM : HsbKit.TEXT);
            k.icon(g,this.catIcon(String(cat.name)),x + 12,y + (chipH - 18) / 2,18,ink,1);
            k.put(t,name,ink);
            this.add(t,x + 40,y + (chipH - t.height) / 2);
            var nw:Number = Math.max(k.u(24),n.width + 12);
            k.fill(g,x + 40 + t.width + 8,y + (chipH - k.u(20)) / 2,nw,k.u(20),5,active ? HsbKit.mix(HsbKit.INK_ON_ACCENT,k.accent,0.2) : 0x262D33,1);
            k.put(n,n.text,active ? k.accent : HsbKit.LABEL);
            this.add(n,x + 40 + t.width + 8 + (nw - n.width) / 2,y + (chipH - n.height) / 2);
            if(!empty) { this.hit(x,y,cw,chipH,"cat",int(keys[i])); }
            x += cw + 8;
            i++;
         }
         y += chipH + 14;
         k.hline(g,param2,y,param1 - param2 * 2);
         y += 12;
         var ml:TextField = k.text(13,HsbKit.LABEL,false,1.5);
         k.put(ml,"MAKER");
         k.fit(ml);
         this.add(ml,param2,y + (k.u(28) - ml.height) / 2);
         var mx:Number = param2 + ml.width + 12;
         var makers:Array = ["All"].concat(this.makerNames());
         var m:int = 0;
         while(m < makers.length && mx < param1 - param2 - 60)
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
            var picked:Boolean = (this.makerChip == "" && mname == "All") || this.makerChip == mname;
            k.fill(g,mx,y,mw,k.u(28),k.u(14),0x161C22,1);
            k.outline(g,mx,y,mw,k.u(28),k.u(14),picked ? k.accent : HsbKit.EDGE_HI,1);
            this.add(mt,mx + 12,y + (k.u(28) - mt.height) / 2);
            k.countChip(this,mx + 12 + mt.width + 6,y + (k.u(28) - k.u(20)) / 2,String(cnt),picked);
            this.hit(mx,y,mw,k.u(28),"maker",mname == "All" ? "" : mname);
            mx += mw + 8;
            m++;
         }
         y += k.u(28) + 12;
         var av:TextField = k.text(14,HsbKit.TEXT,true);
         k.put(av,this.tabName.toUpperCase() + " \u00B7 " + this.availableCount() + " available");
         k.fit(av);
         this.add(av,param2,y);
         y += av.height + 4;
         k.icon(g,"gear",param2,y + 2,14,k.accent,1);
         var note:TextField = k.text(13,HsbKit.LABEL);
         k.put(note,"Change this in Settings (gear icon)");
         k.fit(note);
         this.add(note,param2 + 20,y);
         y += note.height + 10;
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
