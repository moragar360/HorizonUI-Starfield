package
{
   // Purpose: pills are saved part filters (spec part D). This class holds the pill list, which
   //    pills are on this session, the rule test, and the profile file format.
   // Inputs: the profile text (ShipBuilderPills.json, read by the DLL); part rows from the
   //    browser; the player's credits.
   // Outputs: pass or fail per part; the profile text to save; pill and pack JSON for export.
   // Dependencies: HsbJson. Limits from the spec: 20 pills, 8 rules, 4 columns, 24-character
   //    names. Unknown keys in a pill are kept so a newer version's data survives a save.
   // Backend limits: "fitsReactor" and "onMyShip" have no game data, so those rules are always
   //    "not available"; value, class and card stats are known only for parts already previewed.
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbPillModel
   {
      internal static const MAX_PILLS:int = 20;
      internal static const MAX_RULES:int = 8;
      internal static const MAX_NAME:int = 24;
      internal static const MAX_COLUMNS:int = 4;
      internal static const PROFILE_TYPE:String = "horizon.shipbuilder";
      internal static const PILL_TYPE:String = "horizon.pill";
      internal static const PACK_TYPE:String = "horizon.pillpack";
      internal static const VERSION:int = 2;
      internal static const FIELDS:Array = ["maker","size","class","value","stat","canAfford","fitsReactor","onMyShip"];
      internal static const NO_BACKEND:Array = ["fitsReactor","onMyShip"];
      // load() results below zero. Only LOAD_BAD is a damaged file the DLL may set aside as
      // .bad.json; a file too long to parse or from a newer version is left alone, unsaved.
      internal static const LOAD_BAD:int = -1;
      internal static const LOAD_TOO_BIG:int = -2;
      internal static const LOAD_NEWER:int = -3;
      // Lowercase id -> words of the mixed-case spelling it arrived in (see columnId).
      private static var spoken:Object = {};

      internal var pills:Array;
      internal var on:Object;
      private var keep:Object;

      public function HsbPillModel()
      {
         super();
         this.pills = starters();
         this.on = {};
         this.keep = {};
      }

      // Shipped quick pills (mockup 14). They are ordinary pills the player can edit or remove.
      internal static function starters():Array
      {
         return [
            {"id":"s-afford","name":"Can afford","tabs":["*"],"match":"all","inRow":false,"rules":[{"field":"canAfford","op":"is","value":true}],"columns":null},
            {"id":"s-onship","name":"On my ship","tabs":["*"],"match":"all","inRow":false,"rules":[{"field":"onMyShip","op":"is","value":true}],"columns":null},
            {"id":"s-reactor","name":"Fits reactor","tabs":["*"],"match":"all","inRow":false,"rules":[{"field":"fitsReactor","op":"is","value":true}],"columns":null},
            {"id":"s-class","name":"Class A\u2013C","tabs":["*"],"match":"all","inRow":false,"rules":[{"field":"class","op":"anyOf","values":["A","B","C"]}],"columns":null}
         ];
      }

      internal static function fieldLabel(param1:String, param2:Object = null):String
      {
         if(param1.indexOf("stat:") == 0)
         {
            var sid:String = param1.substring(5);
            return param2 != null && param2[sid] != null ? String(param2[sid]) : spokenName(sid);
         }
         var map:Object = {"maker":"Maker","size":"Size","class":"Class","value":"Value","canAfford":"Can afford","fitsReactor":"Fits reactor","onMyShip":"On my ship"};
         return map[param1] != null ? String(map[param1]) : param1;
      }

      internal static function opsFor(param1:String):Array
      {
         if(param1 == "maker" || param1 == "size" || param1 == "class") { return ["anyOf"]; }
         if(param1 == "value" || param1.indexOf("stat:") == 0) { return ["atLeast","atMost"]; }
         return ["is"];
      }

      internal static function opLabel(param1:String):String
      {
         var map:Object = {"anyOf":"is any of","atLeast":"at least","atMost":"at most","is":"is"};
         return map[param1] != null ? String(map[param1]) : param1;
      }

      internal static function hasBackend(param1:String):Boolean
      {
         return NO_BACKEND.indexOf(param1) < 0;
      }

      // Tab keys must be stable across languages where possible: the raw category string
      // (usually a $ key) with everything but letters and digits removed.
      internal static function tabKey(param1:String):String
      {
         var out:String = "";
         var src:String = param1 == null ? "" : param1;
         var i:int = 0;
         while(i < src.length && out.length < 32)
         {
            var c:String = src.charAt(i);
            if((c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9")) { out += c; }
            i++;
         }
         return out.length > 0 ? out : "Tab";
      }

      internal function forTab(param1:String):Array
      {
         var out:Array = [];
         var i:int = 0;
         while(i < this.pills.length)
         {
            var p:Object = this.pills[i];
            var tabs:Array = p.tabs as Array;
            if(tabs == null || tabs.indexOf("*") >= 0 || tabs.indexOf(param1) >= 0) { out.push(p); }
            i++;
         }
         return out;
      }

      internal function byId(param1:String):Object
      {
         var i:int = 0;
         while(i < this.pills.length)
         {
            if(String(this.pills[i].id) == param1) { return this.pills[i]; }
            i++;
         }
         return null;
      }

      internal function byName(param1:String):Object
      {
         var want:String = param1.toLowerCase();
         var i:int = 0;
         while(i < this.pills.length)
         {
            if(String(this.pills[i].name).toLowerCase() == want) { return this.pills[i]; }
            i++;
         }
         return null;
      }

      internal function isOn(param1:String):Boolean
      {
         return this.on[param1] == true;
      }

      internal function toggle(param1:String):void
      {
         if(this.on[param1] == true) { delete this.on[param1]; }
         else { this.on[param1] = true; }
      }

      internal function onFor(param1:String):Array
      {
         var out:Array = [];
         var list:Array = this.forTab(param1);
         var i:int = 0;
         while(i < list.length)
         {
            if(this.isOn(String(list[i].id))) { out.push(list[i]); }
            i++;
         }
         return out;
      }

      internal function clearTab(param1:String):void
      {
         var list:Array = this.forTab(param1);
         var i:int = 0;
         while(i < list.length) { delete this.on[String(list[i].id)]; i++; }
      }

      internal function newId():String
      {
         var n:int = this.pills.length + 1;
         while(this.byId("p" + n) != null) { n++; }
         return "p" + n;
      }

      // A pill is usable when at least one rule has game data behind it.
      internal static function usable(param1:Object):Boolean
      {
         var rules:Array = param1.rules as Array;
         if(rules == null) { return false; }
         var i:int = 0;
         while(i < rules.length)
         {
            if(hasBackend(String(rules[i].field))) { return true; }
            i++;
         }
         return false;
      }

      // One rule against one part. "skip" means the field has no data on this tab at all;
      // "unknown" means this part's value is not known yet (not previewed).
      internal static function ruleState(param1:Object, param2:Object, param3:Object):String
      {
         var field:String = String(param1.field);
         if(!hasBackend(field)) { return "skip"; }
         var op:String = String(param1.op);
         var want:* = param1.value;
         var values:Array = param1.values as Array;
         var have:* = null;
         if(field == "maker") { have = param2.maker; }
         else if(field == "size")
         {
            if(param3.sizes != true) { return "skip"; }
            have = param2.size != null && String(param2.size).length > 0 ? param2.size : "Unsized";
         }
         else if(field == "class") { have = param2.cls; }
         else if(field == "value") { have = param2.value; }
         else if(field == "canAfford")
         {
            if(param2.value == null || isNaN(Number(param3.credits))) { return "unknown"; }
            var fits:Boolean = Number(param2.value) <= Number(param3.credits);
            return fits == (want != false) ? "pass" : "fail";
         }
         else if(field.indexOf("stat:") == 0)
         {
            var id:String = field.substring(5);
            have = param2.stats != null ? param2.stats[id] : null;
            if(have == null && param3.statIds != null && param3.statIds.indexOf(id) < 0) { return "skip"; }
         }
         if(have == null) { return "unknown"; }
         if(op == "anyOf")
         {
            if(values == null || values.length == 0) { return "pass"; }
            var text:String = String(have).toLowerCase();
            var i:int = 0;
            while(i < values.length)
            {
               if(String(values[i]).toLowerCase() == text) { return "pass"; }
               i++;
            }
            return "fail";
         }
         var n:Number = Number(have);
         var limit:Number = Number(want);
         if(isNaN(n) || isNaN(limit)) { return "unknown"; }
         if(op == "atLeast") { return n >= limit ? "pass" : "fail"; }
         if(op == "atMost") { return n <= limit ? "pass" : "fail"; }
         return "skip";
      }

      // 1 pass, 0 fail, 2 pass with unknown data (counted as "not checked yet"), -1 every rule
      // skipped (the pill is dimmed and filters nothing).
      internal static function test(param1:Object, param2:Object, param3:Object):int
      {
         var rules:Array = param1.rules as Array;
         if(rules == null || rules.length == 0) { return 1; }
         var any:Boolean = String(param1.match) == "any";
         var used:int = 0;
         var unknown:Boolean = false;
         var passed:int = 0;
         var i:int = 0;
         while(i < rules.length)
         {
            var s:String = ruleState(rules[i],param2,param3);
            if(s != "skip")
            {
               used++;
               if(s == "pass") { passed++; }
               else if(s == "unknown") { unknown = true; }
               else if(!any) { return 0; }
            }
            i++;
         }
         if(used == 0) { return -1; }
         if(any)
         {
            if(passed > 0) { return 1; }
            return unknown ? 2 : 0;
         }
         return unknown ? 2 : 1;
      }

      internal static function summary(param1:Object, param2:Object = null):String
      {
         var rules:Array = param1.rules as Array;
         if(rules == null) { return ""; }
         var bits:Array = [];
         var i:int = 0;
         while(i < rules.length && bits.length < 3)
         {
            var r:Object = rules[i];
            var label:String = fieldLabel(String(r.field),param2);
            // Mockup 3 wording: "Grav jump thrust at least 40", "Size 1x1, 2x1", "Can afford".
            if(r.values is Array) { bits.push(label + " " + (r.values as Array).join(", ")); }
            else if(String(r.op) == "is") { bits.push(label); }
            else { bits.push(label + " " + opLabel(String(r.op)) + " " + String(r.value)); }
            i++;
         }
         return bits.join(" \u00B7 ");
      }

      // Validates one pill object from any file. Returns a clean copy or null. Unknown keys are
      // kept only when their value is plain (text, number, true/false or null): a single-pill
      // file's pill sits two levels shallower than the profile stores it, so nested data could
      // push the saved profile past HsbJson.MAX_DEPTH and make it unreadable.
      internal static function clean(param1:Object):Object
      {
         if(param1 == null || typeof param1 != "object") { return null; }
         var name:String = param1.name is String ? trim(String(param1.name)) : "";
         if(name.length == 0) { return null; }
         if(name.length > MAX_NAME) { name = name.substring(0,MAX_NAME); }
         var out:Object = {"id":param1.id is String ? String(param1.id).substring(0,32) : "","name":name};
         var tabs:Array = [];
         if(param1.tabs is Array)
         {
            var t:int = 0;
            while(t < (param1.tabs as Array).length && t < 32)
            {
               if(param1.tabs[t] is String) { tabs.push(String(param1.tabs[t]) == "*" ? "*" : tabKey(String(param1.tabs[t]))); }
               t++;
            }
         }
         out.tabs = tabs.length > 0 ? tabs : ["*"];
         out.match = String(param1.match) == "any" ? "any" : "all";
         out.inRow = param1.inRow != false;
         var rules:Array = [];
         if(param1.rules is Array)
         {
            var r:int = 0;
            while(r < (param1.rules as Array).length && rules.length < MAX_RULES)
            {
               var rule:Object = cleanRule(param1.rules[r]);
               if(rule != null) { rules.push(rule); }
               r++;
            }
         }
         out.rules = rules;
         var cols:Array = null;
         if(param1.columns is Array)
         {
            cols = [];
            var c:int = 0;
            while(c < (param1.columns as Array).length && cols.length < MAX_COLUMNS)
            {
               if(param1.columns[c] is String) { cols.push(columnId(String(param1.columns[c]))); }
               c++;
            }
         }
         out.columns = cols;
         var key:String;
         for(key in param1)
         {
            var extra:* = param1[key];
            var plain:Boolean = extra == null || extra is String || extra is Number || extra is Boolean;
            if(plain && out[key] === undefined && ["id","name","tabs","match","inRow","rules","columns"].indexOf(key) < 0) { out[key] = extra; }
         }
         return out;
      }

      private static function cleanRule(param1:Object):Object
      {
         if(param1 == null || typeof param1 != "object" || !(param1.field is String)) { return null; }
         var field:String = String(param1.field);
         if(field.indexOf("stat:") == 0) { field = "stat:" + columnId(field.substring(5)); }
         else if(FIELDS.indexOf(field) < 0) { return null; }
         var ops:Array = opsFor(field);
         var op:String = ops.indexOf(String(param1.op)) >= 0 ? String(param1.op) : String(ops[0]);
         var out:Object = {"field":field,"op":op};
         if(op == "anyOf")
         {
            var values:Array = [];
            if(param1.values is Array)
            {
               var i:int = 0;
               while(i < (param1.values as Array).length && values.length < 16)
               {
                  values.push(String(param1.values[i]).substring(0,32));
                  i++;
               }
            }
            out.values = values;
         }
         else if(op == "is") { out.value = param1.value != false; }
         else
         {
            var n:Number = Number(param1.value);
            out.value = isNaN(n) ? 0 : n;
         }
         return out;
      }

      // Column and stat ids are lowercase letters and digits: the browser keys learned stats in
      // lowercase, so "Mass" in an ini or a pack must name the same column as "mass". The case
      // an id arrived in is kept as words for display until the game names that stat.
      internal static function columnId(param1:String):String
      {
         var out:String = "";
         var i:int = 0;
         while(i < param1.length && out.length < 32)
         {
            var c:String = param1.charAt(i);
            if((c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9")) { out += c; }
            i++;
         }
         var id:String = out.toLowerCase();
         if(id != out && spoken[id] == null) { spoken[id] = words(out,false); }
         return id;
      }

      // "GravJumpThrust" reads "Grav jump thrust"; with param2 set, "GravDrives" reads
      // "Grav Drives" (tab keys keep their capitals, as category names do).
      internal static function words(param1:String, param2:Boolean):String
      {
         var out:String = "";
         var i:int = 0;
         while(i < param1.length)
         {
            var c:String = param1.charAt(i);
            var prev:String = i > 0 ? param1.charAt(i - 1) : "";
            var upper:Boolean = c >= "A" && c <= "Z";
            var after:Boolean = (prev >= "a" && prev <= "z") || (prev >= "0" && prev <= "9");
            if(upper && after) { out += " "; }
            out += i == 0 || param2 ? c : c.toLowerCase();
            i++;
         }
         return out;
      }

      // The display name for an id the game has not named (yet): its words, or the id itself.
      internal static function spokenName(param1:String):String
      {
         return spoken[param1] != null ? String(spoken[param1]) : param1;
      }

      internal static function trim(param1:String):String
      {
         return param1.replace(/^\s+|\s+$/g,"");
      }

      // Returns the number of pills loaded, or -1 when the file is not a valid profile.
      internal function load(param1:String):int
      {
         if(param1.length > HsbJson.MAX_CHARS) { return LOAD_TOO_BIG; }
         var data:* = HsbJson.parse(param1);
         if(data == null || typeof data != "object" || String(data.type) != PROFILE_TYPE) { return LOAD_BAD; }
         if(Number(data.version) > VERSION) { return LOAD_NEWER; }
         if(!(data.pills is Array)) { return LOAD_BAD; }
         var next:Array = [];
         var i:int = 0;
         while(i < (data.pills as Array).length && next.length < MAX_PILLS)
         {
            var p:Object = clean(data.pills[i]);
            if(p != null)
            {
               if(String(p.id).length == 0 || this.idIn(next,String(p.id))) { p.id = "p" + (next.length + 1) + "x" + i; }
               next.push(p);
            }
            i++;
         }
         this.pills = next;
         this.keep = {};
         var key:String;
         for(key in data)
         {
            if(key != "type" && key != "version" && key != "pills") { this.keep[key] = data[key]; }
         }
         return next.length;
      }

      private function idIn(param1:Array, param2:String):Boolean
      {
         var i:int = 0;
         while(i < param1.length)
         {
            if(String(param1[i].id) == param2) { return true; }
            i++;
         }
         return false;
      }

      internal function save():String
      {
         var out:Object = {"type":PROFILE_TYPE,"version":VERSION,"pills":this.pills};
         var key:String;
         for(key in this.keep) { out[key] = this.keep[key]; }
         return HsbJson.stringify(out);
      }

      internal static function pillFile(param1:Object):String
      {
         var copy:Object = {"type":PILL_TYPE,"version":VERSION};
         var key:String;
         for(key in param1)
         {
            if(key != "id") { copy[key] = param1[key]; }
         }
         return HsbJson.stringify(copy);
      }

      // Reads a shared pill or pack file. Returns {kind, name, author, description, pills,
      // columnSets} or null when the file cannot be used.
      internal static function readShared(param1:String):Object
      {
         var data:* = HsbJson.parse(param1);
         if(data == null || typeof data != "object") { return null; }
         if(Number(data.version) > VERSION) { return null; }
         if(String(data.type) == PILL_TYPE)
         {
            var one:Object = clean(data);
            if(one == null) { return null; }
            return {"kind":"pill","name":one.name,"author":data.author is String ? String(data.author).substring(0,48) : "","description":data.description is String ? String(data.description).substring(0,200) : "","pills":[one],"columnSets":null};
         }
         if(String(data.type) != PACK_TYPE || !(data.pills is Array)) { return null; }
         var list:Array = [];
         var i:int = 0;
         while(i < (data.pills as Array).length && list.length < MAX_PILLS)
         {
            var p:Object = clean(data.pills[i]);
            if(p != null) { list.push(p); }
            i++;
         }
         if(list.length == 0) { return null; }
         var sets:Object = null;
         if(data.columnSets != null && typeof data.columnSets == "object")
         {
            sets = {};
            var tab:String;
            for(tab in data.columnSets)
            {
               if(data.columnSets[tab] is Array)
               {
                  var cols:Array = [];
                  var c:int = 0;
                  while(c < (data.columnSets[tab] as Array).length && cols.length < MAX_COLUMNS)
                  {
                     var id:String = columnId(String(data.columnSets[tab][c]));
                     if(id.length > 0) { cols.push(id); }
                     c++;
                  }
                  sets[tabKey(tab)] = cols;
               }
            }
         }
         return {"kind":"pack","name":data.name is String ? String(data.name).substring(0,48) : "Pack","author":data.author is String ? String(data.author).substring(0,48) : "","description":data.description is String ? String(data.description).substring(0,200) : "","pills":list,"columnSets":sets};
      }

      // " (2)", " (3)"... until the name is free, within the 24-character limit.
      internal function freeName(param1:String):String
      {
         var n:int = 2;
         var base:String = param1;
         var name:String = param1;
         while(this.byName(name) != null && n < 100)
         {
            var tail:String = " (" + n + ")";
            name = base.substring(0,MAX_NAME - tail.length) + tail;
            n++;
         }
         return name;
      }
   }
}
